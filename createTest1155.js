/* eslint-disable no-undef */
const Migrations = artifacts.require("Migrations");
const contractName = "MelandSwapExchangePool20T1155";
const MelandSwapExchangePool20T1155 = artifacts.require(contractName);
const MelandChainERC1155CID = artifacts.require("MelandChainERC1155CID");
const Web3 = require("web3");
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

        const instance = await MelandChainERC1155CID.at(
            "0x5aF1364c82C2397030bd366E2536B83975E86FA1"
        );
        const result = await instance.balanceOf(
            "0x842397419bfc4dbd01f584a6bcdcd055a3eb3138",
            "61000022"
        );

        console.debug(result.toString());

        callback();
    } catch (error) {
        console.error(error);
        callback();
    }
};