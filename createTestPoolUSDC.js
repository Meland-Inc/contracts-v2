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
    const web3 = new Web3();
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
        const m = await ERC20.at("0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747");
        const MigrationsI = await Migrations.deployed();
        const MelandSwapFactoryAddress = await MigrationsI.getProxy("MelandSwapFactory");
        const MelandMarketplaceProxyAddress = await MigrationsI.getProxy("Marketplace");
        const MelandChainERC1155CIDAddress = await MigrationsI.getProxy("MelandChainERC1155CID");
        const MelandSwapFactoryI = await MelandSwapFactory.at(MelandSwapFactoryAddress);

        // IERC1155 erc1155,
        // uint256 tokenId,
        // IERC20Metadata erc20,
        // uint256 erc20Amount,
        // uint256 erc1155Amount
        // await MelandSwapFactoryI.createPoolByCommunity(
        //     "0xA02E99bc49CB55888e4F4a065B123b8E0011D24f",
        //     "61000022",
        //     "0x5a0585d409ca86d9fa771690ea37d32405da1f67",
        //     "1",
        //     "1"
        // );
        await m.approve("0xecE00E78b821cA1d45AfCd4624D5A76Aca7B926c", "10000000000000000000000000");
        // await c.init(
        //     "10000000000000000000000000",
        //     "10000000"
        // );
        await MelandSwapFactoryI.createPoolByCommunity(
            MelandChainERC1155CIDAddress,
            "71010001",
            "0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747",
            "100000000",
            "100000000"
        );

        callback();
    } catch (error) {
        console.error(error);
        callback();
    }
};