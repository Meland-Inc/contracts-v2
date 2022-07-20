/* eslint-disable no-undef */
const Migrations = artifacts.require("Migrations");
const contractName = "MelandSwapExchangePool20T1155";
const MelandSwapExchangePool20T1155 = artifacts.require(contractName);
const ERC20 = artifacts.require("TestToken");
const Web3 = require("web3");
const { BigNumber } = require('ethers');
const { asciiToHex, encodePacked, hexToBytes } = require("web3-utils");

module.exports = async function (callback, accounts) {
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

        const instance = await ERC20.new("Meland.ai", "MELD");
        await instance.initialize();
        await instance.mint(BigNumber.from(2000000000).mul(BigNumber.from(10).pow(18)));
        console.debug(instance.address);

        callback();
    } catch (error) {
        console.error(error);
        callback();
    }
};