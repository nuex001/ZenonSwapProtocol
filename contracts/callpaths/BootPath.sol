// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import '../libraries/ProtocolCmd.sol';
import '../mixins/StorageLayout.sol';
import '../ZenonEvents.sol';

/* @title Booth path callpath sidecar.
 * 
 * @notice Simple proxy with the sole function of upgrading other proxy contracts. For safety
 *         this proxy cannot upgrade itself, since that would risk permenately locking out the
 *         ability to ever upgrade.
 *         
 * @dev    This is a special proxy sidecar which should only be installed once at construction
 *         time at slot 0 (BOOT_PROXY_IDX). No other proxy contract should include upgrade 
 *         functionality. If both of these conditions are true, this proxy can never be overwritten
 *         and upgrade functionality can never be broken for the life of the main contract. */
contract BootPath is StorageLayout {
    using ProtocolCmd for bytes;

    address private owner;
    uint256 private constant
CMD_LENGTH = 32;
    uint16 private constant BOOT_PROXY_IDX = 0;

    modifier  onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    } 


    /* @notice Consolidated method for protocol control related commands. */
    function protocolCmd (bytes calldata cmd) virtual public onlyOwner {
        require(cmd.length == CMD_LENGTH, "Invalid command length");
        
        uint8 cmdCode = uint8(cmd[31]);
        if (cmdCode == ProtocolCmd.UPGRADE_DEX_CODE) {
            upgradeProxy(cmd);
        } else {
            revert("Invalid command");
        }
    }
    
    function userCmd (bytes calldata) virtual public payable { 
        revert("Invalid command");
    }
    
    /* @notice Upgrades one of the existing proxy sidecar 
     * @dev    Be extremely careful calling this, particularly when upgrading the
     *         cold path contract, since that contains the upgrade code itself.
     * @param proxy The address of the new proxy smart contract
     * @param proxyIdx Determines which proxy is upgraded on this call */
    function upgradeProxy (bytes calldata cmd) private {
        (, address proxy, uint16 proxyIdx) =
            abi.decode(cmd, (uint8, address, uint16));

        require(proxyIdx != BOOT_PROXY_IDX, "Cannot overwrite boot path");
        require(proxy == address(0) || proxy.code.length > 0, "Proxy address is not a contract");
        require(proxyPaths_[proxyIdx] != proxy, "New proxy address is the smae as the current one");
               

        if (proxy != address(0)) {
            bool doesAccept = BootPath(proxy).acceptZenonProxyRole(address(this), proxyIdx);
            require(doesAccept, "Proxy does not accept role");
        }

        emit ZenonEvents.UpgradeProxy(proxy, proxyIdx);
        proxyPaths_[proxyIdx] = proxy;
    }

    /* @notice Conforms to the standard call, but should always reject role because this contract
     *         should only ever be installled once at construction time and never upgraded after */
    function acceptZenonProxyRole (address, uint16) public pure virtual returns (bool) {
        return false;
    }
}

