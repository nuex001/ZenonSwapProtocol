// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import '../libraries/CurveCache.sol';

/* @notice Simple interface that define the surface between the ZenonSwapDex
 *         itself and protocol governance and policy. All governance actions are
 *         are executed through the single protocolCmd() method. */
interface IZenonMinion {

    /* @notice Calls a general governance authorized command on the ZenonSwapDex contract.
     *
     * @param proxyPath The proxy callpath sidecar to execute the command within. (Will
     *                  call protocolCmd
     * @param cmd       The underlying command content to pass to the proxy sidecar call.
     *                  Will DELEGATECALL (protocolCmd(cmd) on the sidecar proxy.
     * @param sudo      Set to true for commands that require escalated privilege (e.g. 
     *                  authority transfers or upgrades.) The ability to call with sudo 
     *                  true should be reserved for privileged callpaths in the governance
     *                  controller contract. */
    function protocolCmd (uint16 proxyPath, bytes calldata cmd, bool sudo)
        payable external;
}

/* @notice Interface for a contract that directly governs a ZenonSwap dex contract. */
interface IZenonMaster {
    /* @notice Used to validate governance contract to prevent authority transfer to an
     *         an invalid address or contract. */
    function acceptsZenonAuthority() external returns (bool);
}