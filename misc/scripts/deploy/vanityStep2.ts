/* Workflow to deploy a basic ZenonSwapDex contract using a pre-determined
 * create2 vanity salt, then hand off to the ZenonPolicy contract. 
 *
 * Call using:
 * npx hardhat run 
 */

import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';
import { ColdPath, ZenonDeployer, ZenonPolicy, ZenonSwapDex } from '../../../typechain';
import { mapSalt } from '../../constants/salts';
import { Zenon_ADDRS } from '../../constants/addrs';
import { initChain, refContract, traceContractTx, traceTxResp } from '../../libs/chain';
import { RPC_URLS } from '../../constants/rpcs';

async function vanityDeploy() {
    let { addrs, chainId, wallet: authority } = initChain()

    const salt = mapSalt(addrs.deployer)

    console.log("Deploying with the following addresses...")
    console.log("Protocol Authority: ", authority.address)
    console.log("Using CREATE2 salt", salt.toString())

    let ZenonDeployer = await refContract("ZenonDeployer", addrs.deployer, 
        authority) as ZenonDeployer

    const factory = await ethers.getContractFactory("ZenonSwapDex")
    await traceContractTx(ZenonDeployer.deploy(factory.bytecode, salt), "Salted Deploy")
    addrs.dex = await ZenonDeployer.dex_();

    console.log("ZenonSwapDex deployed at: ", addrs.dex)
    console.log(`Updated addresses for ${chainId}`, addrs)
}

vanityDeploy()
