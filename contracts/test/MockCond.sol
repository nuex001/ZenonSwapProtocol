// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/IZenonCondOracle.sol";

contract MockZenonNonceOracle is IZenonNonceOracle,
    IZenonCondOracle{

    address public user_;
    bytes32 public salt_;
    uint32 public nonce_;
    bytes public args_;
    bool public accept_;

    function setAccept (bool accept) public {
        accept_ = accept;
    }

    function checkZenonNonceSet (address user, bytes32 nonceSalt, uint32 nonce,
                                bytes calldata args) public override returns (bool) {
        user_ = user;
        salt_ = nonceSalt;
        nonce_ = nonce;
        args_ = args;
        return accept_;
    }

    function checkZenonCond (address user, 
                            bytes calldata args) public override returns (bool) {
        user_ = user;
        args_ = args;
        return accept_;
    }

}

