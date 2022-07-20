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
        const tokenAddress = "0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747";
        const m = await ERC20.at(tokenAddress);
        const MigrationsI = await Migrations.deployed();
        const MelandSwapFactoryAddress = await MigrationsI.getProxy("MelandSwapFactory");
        const MelandMarketplaceProxyAddress = await MigrationsI.getProxy("Marketplace");
        const MelandChainERC1155CIDAddress = await MigrationsI.getProxy("MelandChainERC1155CID");
        const MelandSwapFactoryI = await MelandSwapFactory.at(MelandSwapFactoryAddress);

        const productManager = await MelandSwapFactoryI.productManager();
        console.debug(productManager, MelandChainERC1155CIDAddress, "MelandChainERC1155CIDAddress");
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
        console.debug("start approve");
        let allowance = await m.allowance(accounts[0], MelandSwapFactoryAddress);
        await m.approve(MelandSwapFactoryAddress, "1100000000000000000000");
        allowance = await m.allowance(accounts[0], MelandSwapFactoryAddress);
        // await c.init(
        //     "10000000000000000000000000",
        //     "10000000"
        // );
        // 71010001
        console.debug(allowance.toString(), "allowance");
        console.debug("end approve");
        await MelandSwapFactoryI.createPoolByCommunity(
            MelandChainERC1155CIDAddress,
            "71010001",
            tokenAddress,
            "100000000",
            "100"
        );
        // const poolAddress = await MelandSwapFactoryI.getPool(
        //     MelandChainERC1155CIDAddress,
        //     "61000020",
        //     tokenAddress,
        // );
        // console.debug("create pool done.", poolAddress);

        callback();
    } catch (error) {
        console.error(error);
        callback();
    }
};