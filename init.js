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
        await melandchain1155i.addHolder(MelandMarketplaceProxyAddress);

        callback();
    } catch (error) {
        console.error(error);
        callback();
    }
};