/* Workflow to transfer control of the newly deployed ZenonSwapDex contract away
 * from the ZenonDeployer to a ZenonPolicy contract under the control of the authority
 * wallet. (Also installs ColdPath as necessary part of the workflow)
 */

import { ColdPath, ZenonDeployer, ZenonPolicy, ZenonSwapDex } from '../../../typechain';
import { BOOT_PROXY_IDX, COLD_PROXY_IDX } from '../../constants/addrs';
import { inflateAddr, initChain, refContract, traceContractTx, traceTxResp } from '../../libs/chain';
import { AbiCoder } from '@ethersproject/abi';

const abi = new AbiCoder()

async function vanityDeploy() {
    let { addrs, chainId, wallet: authority } = initChain()

    const ZenonDeployer = await refContract("ZenonDeployer", addrs.deployer, 
        authority) as ZenonDeployer

    const coldPath = await inflateAddr("ColdPath", addrs.cold, authority) as ColdPath
    addrs.cold = coldPath.address

    const policy = await inflateAddr("ZenonPolicy", addrs.policy, 
        authority, addrs.dex) as ZenonPolicy
    addrs.policy = policy.address

    console.log(`Updated addresses for ${chainId}`, addrs)

    let cmd;

    // Install cold path proxy, so we can transfer ownership
    cmd = abi.encode(["uint8", "address", "uint16"], [21, addrs.cold, COLD_PROXY_IDX])
    await traceContractTx(ZenonDeployer.protocolCmd(addrs.dex, BOOT_PROXY_IDX, cmd, true), 
        "Cold Path Install")

    cmd = abi.encode(["uint8", "address"], [20, policy.address])
    await traceContractTx(ZenonDeployer.protocolCmd(addrs.dex, COLD_PROXY_IDX, cmd, true), 
        "Transfer to Policy Contract")

    console.log(`Updated addresses for ${chainId}`, addrs)
}

vanityDeploy()
