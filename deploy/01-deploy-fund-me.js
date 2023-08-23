/* function deployFunc(hre) {
    console.log("Hi!")
}
module.exports.default = deployFunc */

// module.exports = async (hre) => {
//    const { getNamedAccounts, deployments } = hre }

// const helperConfig = require("../helper-hardhat-config") |
// const networkConfig = helperConfig.networkConfig         | dif syntax
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { network } = require("hardhat")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log, get } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    // if chainId is X use address Y
    // if chainId is Z use address A
    // const ethUshPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    let ethUshPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await get("MockV3Aggregator")
        ethUshPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUshPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }
    // if the price feed contract doesn't exist, we deploy a mock, which is a minimal version of it

    // well what happens when we want to change chains?
    // when going for localhost or hardhat network we want to use a mock
    const args = [ethUshPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // put price feed address here
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, args)
    }

    log("------------------------------------------------------------------")
}
module.exports.tags = ["all", "fundme"]
