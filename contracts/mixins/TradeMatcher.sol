// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.4;

import '../libraries/Directives.sol';
import '../libraries/PoolSpecs.sol';
import '../libraries/PriceGrid.sol';
import '../libraries/SwapCurve.sol';
import '../libraries/CurveMath.sol';
import '../libraries/CurveRoll.sol';
import '../libraries/TickCluster.sol';
import '../libraries/Chaining.sol';
import './PositionRegistrar.sol';
import './LiquidityCurve.sol';
import './LevelBook.sol';
import './ColdInjector.sol';

import "hardhat/console.sol";

contract TradeMatcher is PositionRegistrar, LiquidityCurve, LevelBook,
    ColdPathInjector {

    using SafeCast for int256;
    using SafeCast for int128;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using TickCluster for int24;
    using TickMath for uint128;
    using PoolSpecs for PoolSpecs.Pool;
    using SwapCurve for CurveMath.CurveState;
    using SwapCurve for CurveMath.SwapAccum;
    using CurveRoll for CurveMath.CurveState;
    using CurveMath for CurveMath.CurveState;
    using Directives for Directives.ConcentratedDirective;
    using Chaining for Chaining.PairFlow;

    function mintAmbient (CurveMath.CurveState memory curve, uint128 liqAdded, 
                          bytes32 poolHash)
        internal returns (int128, int128) {
        mintPosLiq(msg.sender, poolHash, liqAdded, curve.accum_.ambientGrowth_);
        (uint128 base, uint128 quote) = liquidityReceivable(curve, liqAdded);
        return signMintFlow(base, quote);
    }

    function lockAmbient (CurveMath.CurveState memory curve, uint128 liqAdded)
        internal pure returns (int128, int128) {
        (uint128 base, uint128 quote) = liquidityReceivable(curve, liqAdded);
        return signMintFlow(base, quote);        
    }

    function burnAmbient (CurveMath.CurveState memory curve, uint128 liqBurned, 
                          bytes32 poolHash)
        internal returns (int128, int128) {
        burnPosLiq(msg.sender, poolHash, liqBurned, curve.accum_.ambientGrowth_);
        (uint128 base, uint128 quote) = liquidityPayable(curve, liqBurned);
        return signBurnFlow(base, quote);
    }
    
    function mintRange (CurveMath.CurveState memory curve, int24 priceTick,
                        int24 lowTick, int24 highTick, uint128 liquidity,
                        bytes32 poolHash)
        internal returns (int128, int128) {
        uint64 feeMileage = addBookLiq(poolHash, priceTick, lowTick, highTick,
                                       liquidity, curve.accum_.concTokenGrowth_);
        mintPosLiq(msg.sender, poolHash, lowTick, highTick,
                   liquidity, feeMileage);
        (uint128 base, uint128 quote) = liquidityReceivable
            (curve, liquidity, lowTick, highTick);
        return signMintFlow(base, quote);
    }

    function burnRange (CurveMath.CurveState memory curve, int24 priceTick,
                        int24 lowTick, int24 highTick, uint128 liquidity,
                        bytes32 poolHash)
        internal returns (int128, int128) {
        uint64 feeMileage = removeBookLiq(poolHash, priceTick, lowTick, highTick,
                                          liquidity, curve.accum_.concTokenGrowth_);
        uint64 rewards = burnPosLiq(msg.sender, poolHash, lowTick, highTick,
                                    liquidity, feeMileage);
        (uint128 base, uint128 quote) = liquidityPayable(curve, liquidity, rewards,
                                                         lowTick, highTick);
        return signBurnFlow(base, quote);
    }

    function signMintFlow (uint128 base, uint128 quote) private pure
        returns (int128, int128) {
        return (base.toInt128Sign(), quote.toInt128Sign());
    }

    function signBurnFlow (uint128 base, uint128 quote) private pure
        returns (int128, int128){
        return (-(base.toInt128Sign()), -(quote.toInt128Sign()));
    }

    /* @notice Executes the pending swap through the order book, adjusting the
     *         liquidity curve and level book as needed based on the swap's impact.
     *
     * @dev This is probably the most complex single function in the codebase. For
     *      small local moves, which don't cross extant levels in the book, it acts
     *      like a constant-product AMM curve. For large swaps which cross levels,
     *      it iteratively re-adjusts the AMM curve on every level cross, and performs
     *      the necessary book-keeping on each crossed level entry.
     *
     * @param curve The starting liquidity curve state. Any changes created by the 
     *              swap on this struct are updated in memory. But the caller is 
     *              responsible for committing the final state to EVM storage.
     * @param accum The specification for the executable swap. The realized flows
     *              on the swap will be written into the memory-based accumulator
     *              fields of this struct. The caller is responsible for paying and
     *              collecting those flows.
     * @param limitPrice The limit price of the swap. Expressed as the square root of
     *     the price in FixedPoint96. Important to note that this represents the limit
     *     of the final price of the *curve*. NOT the realized VWAP price of the swap.
     *     The swap will only ever execute up the maximum size which would keep the curve
     *     price within this bound, even if the specified quantity is higher. */
    function sweepSwapLiq (Chaining.PairFlow memory accum,
                           CurveMath.CurveState memory curve, int24 midTick,
                           Directives.SwapDirective memory swap,
                           PoolSpecs.PoolCursor memory pool) internal {
        require(swap.isBuy_ == (curve.priceRoot_ < swap.limitPrice_), "SD");
        
        // Keep iteratively executing more quantity until we either reach our limit price
        // or have zero quantity left to execute.
        bool doMore = true;
        while (doMore) {
            // Swap to furthest point we can based on the local bitmap. Don't bother
            // seeking a bump outside the bump, because we're not sure if the swap will
            // exhaust the bitmap.
            (int24 bumpTick, bool spillsOver) = pinTickMap
                (pool.hash_, swap.isBuy_, midTick);
            curve.swapToLimit(accum, swap, pool.head_, bumpTick);
            
            
            // The swap can be in one of three states at this point: 1) qty exhausted,
            // 2) limit price reached, or 3) AMM liquidity bump hit. The former two mean
            // the swap is complete. The latter means that we have adust AMM liquidity,
            // and find the next liquidity bump.
            doMore = hasSwapLeft(curve, swap);
            
            // The swap can be in one of three states at this point: 1) qty exhausted,
            // 2) limit price reached, or 3) AMM liquidity bump hit. The former two mean
            // the swap is complete. The latter means that we have adust AMM liquidity,
            // and find the next liquidity bump.
            if (doMore) {

                // The spills over variable indicates that we reaced the end of the
                // local bitmap, rather than actually hitting a level bump. Therefore
                // we should query the global bitmap, find the next level bitmap, and
                // keep swapping on the constant-product curve until we hit point.
                if (spillsOver) {
                    (int24 liqTick, bool tightSpill) = seekTickSpill
                        (pool.hash_, bumpTick, swap.isBuy_);
                    bumpTick = liqTick;
                    
                    // In some corner cases the local bitmap border also happens to
                    // be the next level bump. In which case we're done. Otherwise,
                    // we keep swapping since we still have some distance on the curve
                    // to cover.
                    if (!tightSpill) {
                        curve.swapToLimit(accum, swap, pool.head_, bumpTick);
                        doMore = hasSwapLeft(curve, swap);
                    }
                }
                
                // Perform book-keeping related to crossing the level bump, update
                // the locally tracked tick of the curve price (rather than wastefully
                // we calculating it since we already know it), then begin the swap
                // loop again.
                if (doMore) {
                    midTick = knockInTick(accum, bumpTick, curve, swap, pool.hash_);
                }
            }
        }
    }

    function hasSwapLeft (CurveMath.CurveState memory curve,
                          Directives.SwapDirective memory swap)
        private pure returns (bool) {
        bool inLimit = swap.isBuy_ ?
            curve.priceRoot_ < swap.limitPrice_ :
            curve.priceRoot_ > swap.limitPrice_;
        return inLimit && (swap.qty_ > 0);
    }

    /* @notice Performs all the necessary book keeping related to crossing an extant 
     *         level bump on the curve. 
     *
     * @dev Note that this function updates the level book data structure directly on
     *      the EVM storage. But it only updates the liquidity curve state *in memory*.
     *      This is for gas efficiency reasons, as the same curve struct may be updated
     *      many times in a single swap. The caller must take responsibility for 
     *      committing the final curve state back to EVM storage. 
     *
     * @params bumpTick The tick index where the bump occurs.
     * @params isBuy The direction the bump happens from. If true, curve's price is 
     *               moving through the bump starting from a lower price and going to a
     *               higher price. If false, the opposite.
     * @params curve The pre-bump state of the local constant-product AMM curve. Updated
     *               to reflect the liquidity added/removed from rolling through the
     *               bump.
     * @return The tick index that the curve and its price are living in after the call
     *         completes. */
    function knockInTick (Chaining.PairFlow memory accum, int24 bumpTick,
                          CurveMath.CurveState memory curve,
                          Directives.SwapDirective memory swap,
                          bytes32 poolHash) private
        returns (int24) {
        if (!Bitmaps.isTickFinite(bumpTick)) { return bumpTick; }
        bumpLiquidity(curve, bumpTick, swap.isBuy_, poolHash);

        (int128 paidBase, int128 paidQuote, uint128 burnSwap) =
            curve.shaveAtBump(swap.inBaseQty_, swap.isBuy_, swap.qty_);
        accum.accumFlow(paidBase, paidQuote);
        swap.qty_ -= burnSwap;

        // When selling down, the next tick leg actually occurs *below* the bump tick
        // because the bump barrier is the first price on a tick. 
        return swap.isBuy_ ? bumpTick : bumpTick - 1; 
    }

    function bumpLiquidity (CurveMath.CurveState memory curve,
                            int24 bumpTick, bool isBuy, bytes32 poolHash) private {
        int128 liqDelta = crossLevel(poolHash, bumpTick, isBuy,
                                     curve.accum_.concTokenGrowth_);
        curve.liq_.concentrated_ = LiquidityMath.addDelta
            (curve.liq_.concentrated_, liqDelta);
    }    
}