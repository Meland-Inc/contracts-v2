
const Migrations = artifacts.require("Migrations");
const { getInitializerData } = require('@openzeppelin/truffle-upgrades/dist/utils/initializer-data');
const contractName = "MelandChainERC1155";
const MelandChainERC1155 = artifacts.require(contractName);
const Web3 = require("web3");
const web3 = new Web3();

module.exports = async function (deployer, network, accounts) {
    const MigrationsI = await Migrations.deployed();

    let MelandProxyAddress = await MigrationsI.getProxy(contractName);
    const MelandMarketplaceProxyAddress = await MigrationsI.getProxy("Marketplace");
    const MelandForwarderAddress = await MigrationsI.getProxy("MelandForwarder");

    if (MelandProxyAddress !== "0x0000000000000000000000000000000000000000") {
        console.debug(contractName + " already deployed");
        const melandchain1155i = await MelandChainERC1155.at(MelandProxyAddress);
        await melandchain1155i.addHolder(MelandMarketplaceProxyAddress)
        return;
    }

    const erc1155Bytecode = `${MelandChainERC1155.bytecode}${web3.eth.abi.encodeParameter("address", MelandForwarderAddress).slice(2)}`;

    const initdata = getInitializerData(MelandChainERC1155, [
        accounts[0],
    ]);
    const result = await MigrationsI.deploy(contractName, erc1155Bytecode, initdata);
    MelandProxyAddress = await MigrationsI.getProxy(contractName);
    const melandchain1155i = await MelandChainERC1155.at(MelandProxyAddress);
    await melandchain1155i.addHolder(MelandMarketplaceProxyAddress)
    console.debug(contractName + " deployed", MelandProxyAddress);
}