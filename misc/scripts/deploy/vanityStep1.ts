
/* Workflow to deploy a basic ZenonSwapDex contract using a pre-determined
 * create2 vanity salt, then hand off to the ZenonPolicy contract. 
 *
 * Call using:
 * npx hardhat run 
 */

import { inflateAddr, initChain } from '../../libs/chain';

async function deploy() {
    let { addrs, chainId, wallet: authority } = initChain()
    console.log(`Deploying ZenonSwapDeployer Contract to ${chainId}...`)
    console.log("Initial Authority: ")

    let ZenonDeployer = inflateAddr("ZenonDeployer", addrs.deployer, authority, 
        authority.address)
    addrs.deployer = (await ZenonDeployer).address

    console.log("ZenonDeployer: ", addrs.deployer)
    console.log(`Updated addresses for ${chainId}`, addrs)
}

deploy()
