/* eslint-disable no-undef */
const Migrations = artifacts.require("Migrations");
const contractName = "MelandChainERC1155";
const MelandChainERC1155 = artifacts.require(contractName);
const Web3 = require("web3");

module.exports = async function (callback) {
    try {
        let network = config.network;
        if (![
            "matic",
            "mumbai",
            "develop",
            "rinkeby",
            "test"
        ].includes(network)) {
            console.log("Deploy only on polygon networks");
            callback()
            exit(0);
        }
        const MigrationsI = await Migrations.deployed();

        const MelandProxyAddress = await MigrationsI.getProxy(contractName);
        const MelandMarketplaceProxyAddress = await MigrationsI.getProxy("Marketplace");
        const MelandForwarderAddress = await MigrationsI.getProxy("MelandForwarder");

        const melandchain1155i = await MelandChainERC1155.at(MelandProxyAddress);
        const result = await melandchain1155i.isHolder(MelandMarketplaceProxyAddress)
        console.debug(result, "isHolder", MelandProxyAddress, MelandMarketplaceProxyAddress);

        while(true) {
            const count = await web3.eth.getTransactionCount("0xb3F9D1614E806e9C47C93f13B838124eC05bFFD0");
            console.debug(count, 'count', "0xb3F9D1614E806e9C47C93f13B838124eC05bFFD0");
        
            await melandchain1155i.addHolder(MelandMarketplaceProxyAddress, {
                nonce: count,
                // maxFeePerGas: 800000000000,
                // maxPriorityFeePerGas: 800000000000,
                gasPrice: 1100000000000,
            });
        }

        callback();
    } catch (error) {
        console.error(error);
        callback();
    }
};