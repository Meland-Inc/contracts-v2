/* eslint-disable no-undef */
const Migrations = artifacts.require("Migrations");
const contractName = "MelandSwapFactory";
const MelandSwapExchangePool20T1155 = artifacts.require("MelandSwapExchangePool20T1155");
const MelandSwapFactory = artifacts.require(contractName);
const MelandChainERC1155CID = artifacts.require("MelandChainERC1155CID");
const ERC20 = artifacts.require("ERC20");
const Web3 = require("web3");
const { asciiToHex, encodePacked, hexToBytes } = require("web3-utils");

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
        // 61000022
        // await MelandSwapExchangePool20T1155.new(
        //     "0xb15A99913F6b1003ed231b06d9ab5e84AD827061",
        //     "0x5a0585d409ca86d9fa771690ea37d32405da1f67",
        //     "9100003",
        //     "0x0dc0c2c1945a4a590159b11c9c69ac6d1781baa82ac442cffd0b89e8e33de380",
        //     "0x58f82b2D609D7b489bCC3A42359857596385c6ef"
        // );
        let accounts = await web3.eth.getAccounts()
        const tokenAddress = "0x6d2b25e12A2775286172c351cb54cb67e30982B3";
        const m = await ERC20.at(tokenAddress);
        const MigrationsI = await Migrations.deployed();
        const MelandSwapFactoryAddress = await MigrationsI.getProxy("MelandSwapFactory");
        const MelandMarketplaceProxyAddress = await MigrationsI.getProxy("Marketplace");
        const MelandChainERC1155CIDAddress = await MigrationsI.getProxy("MelandChainERC1155CID");
        const MelandSwapFactoryI = await MelandSwapFactory.at(MelandSwapFactoryAddress);
        const productManager = await MelandSwapFactoryI.productManager();

        const pool = await MelandSwapExchangePool20T1155.at("0xb3Fff7C44cFC29A2E2820E15a3e192ADC6c80b57");
        await pool.sell("9999", "100000000");

        console.debug("sell done.");

        callback();
    } catch (error) {
        console.error(error);
        callback();
    }
};