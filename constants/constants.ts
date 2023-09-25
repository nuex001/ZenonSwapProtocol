// constants.ts
export const developmentChains: string[] =  ["hardhat", "localhost"];

export interface networkConfigInfo {
    [key: string]: number
  }
  
  export const networkConfig: networkConfigInfo = {
    localhost: 0,
    hardhat: 0,
    kovan:1,
    mainnet:1,
    sepolia:1
  }