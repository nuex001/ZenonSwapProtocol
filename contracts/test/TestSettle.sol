// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.0;
    
import "../mixins/SettleLayer.sol";

contract TestSettleLayer is SettleLayer {

    address private recv_;
    RollingSpend private spend_;
    
    constructor (address recv) {
        recv_ = recv;
    }
    
    function testSettleFlow (int256 flow, address token) public payable {
        testSettle(flow, token, type(int256).max, 0, false);
    }

    function testSettleLimit (int256 flow, address token, int256 limitQty)
        public payable {
        testSettle(flow, token, limitQty, 0, false);
    }

    function testSettleDust (int256 flow, address token, uint256 dustThresh)
        public payable {
        testSettle(flow, token, type(int256).max, dustThresh, false);  
    }

    function testSettleReserves (int256 flow, address token) public payable {
        testSettle(flow, token, type(int256).max, 0, true);
    }

    function testSettle (int256 flow, address token, int256 limitQty,
                         uint256 dustThresh, bool useReserves) public payable {
        Directives.SettlementChannel memory dir = Directives.SettlementChannel
            ({token_: token, limitQty_: limitQty, dustThresh_: dustThresh,
                    useReserves_: useReserves});
        RollingSpend memory spend = spend_;
        settleFlat(recv_, flow, dir, spend);
        spend_ = spend;
    }

    function getMyBalance() public view returns (uint256) {
        return getBalance(address(this));
    }

    function getBalance (address tgt) public view returns (uint256) {
        return tgt.balance;
    }

    function hasSpentEth() public view returns (bool) {
        return spend_.spentMsgVal_;
    }
}