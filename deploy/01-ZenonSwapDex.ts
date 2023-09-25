import { ethers, network } from "hardhat";
import { verify } from "../utils/verify";
import { developmentChains, networkConfig } from "../constants/constants";
import { bytecode } from "../artifacts/contracts/ZenonSwapDex.sol/ZenonSwapDex.json";

import { HardhatRuntimeEnvironment } from "hardhat/types";

module.exports = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId: number = network.config.chainId!

  const ZenonDeploy = await deploy("ZenonDeployer", {
    from: deployer,
    args: [deployer],
    log: true,
    waitConfirmations: networkConfig[network.name] || 0, //if user is in localstorage it's zero, if not it's 1
  })


  const salt = 10; //we need a fixed salt to keep getting the desired address
  // console.log(ZenonDeployer.address, salt);

  // Access and call a function on the deployed contract
  const ZenonDeployerContract = await hre.ethers.getContractAt("ZenonDeployer", ZenonDeploy.address);
  
  const result = await ZenonDeployerContract.deploy(bytecode, salt);
  
  log("________________________________")
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(ZenonDeploy.address, [deployer])
  }
}

// i added dotenv and hardhat deploy, 
// imported .env and used it for etherscan verify