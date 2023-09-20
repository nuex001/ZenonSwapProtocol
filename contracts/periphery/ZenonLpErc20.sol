// SPDX-License-Identifier: GPL-3

pragma solidity 0.8.19;

import "../libraries/PoolSpecs.sol";
import "../interfaces/IZenonLpConduit.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract ZenonLpErc20 is ERC20, IZenonLpConduit {

    bytes32 public immutable poolHash;
    address public immutable baseToken;
    address public immutable quoteToken;
    uint256 public immutable poolType;
    
    constructor (address base, address quote, uint256 poolIdx)
        ERC20 ("Zenon Ambient LP ERC20 Token", "LP-ZenonAmb", 18) {

        // ZenonSwap protocol uses 0x0 for native ETH, so it's possible that base
        // token could be 0x0, which means the pair is against native ETH. quote
        // will never be 0x0 because native ETH will always be the base side of
        // the pair.
        require(quote != address(0) && base != quote && quote > base, "Invalid Token Pair");

        baseToken = base;
        quoteToken = quote;
        poolType = poolIdx;
        poolHash = PoolSpecs.encodeKey(base, quote, poolIdx);
    }
    
    function depositZenonLiq (address sender, bytes32 pool,
                             int24 lowerTick, int24 upperTick, uint128 seeds,
                             uint64) public override returns (bool) {
        require(pool == poolHash, "Wrong pool");
        require(lowerTick == 0 && upperTick == 0, "Non-Ambient LP Deposit");
        _mint(sender, seeds);
        return true;
    }

    function withdrawZenonLiq (address sender, bytes32 pool,
                              int24 lowerTick, int24 upperTick, uint128 seeds,
                              uint64) public override returns (bool) {
        require(pool == poolHash, "Wrong pool");
        require(lowerTick == 0 && upperTick == 0, "Non-Ambient LP Deposit");
        _burn(sender, seeds);
        return true;
    }

}
