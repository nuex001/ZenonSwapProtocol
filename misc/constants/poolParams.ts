import { BigNumberish } from "ethers"
import { ethers } from "hardhat"

export interface ZenonOnePoolParams {
    jitThresh: number,
    tickSize: number
    feeBps: number,
    knockoutOn: boolean
}

export interface ZenonCrossPoolParams {
    initLiq: BigNumberish
}

export interface ZenonPoolParams {
    universal: ZenonCrossPoolParams
    stdPoolIdx: number
    stdPoolParams: ZenonOnePoolParams
}

const mainnetParams: ZenonPoolParams = {
    universal: {
        initLiq: 10000
    },
    stdPoolIdx: 420,
    stdPoolParams: {
        jitThresh: 30,
        tickSize: 16,
        feeBps: 27,
        knockoutOn: true
    }
}

const goerliDryRunParams = mainnetParams

export const Zenon_POOL_PARAMS = {
    '0x1': mainnetParams,
    '0x5': goerliDryRunParams,
}
