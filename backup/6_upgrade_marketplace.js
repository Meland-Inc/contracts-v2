
const Migrations = artifacts.require("Migrations");
const { getInitializerData } = require('@openzeppelin/truffle-upgrades/dist/utils/initializer-data');
const contractName = "Marketplace";
const Marketplace = artifacts.require(contractName);
const Web3 = require("web3");
const web3 = new Web3();

module.exports = async function (deployer, network, accounts) {
    const MigrationsI = await Migrations.deployed();

    const MelandProxyAddress = await MigrationsI.getProxy(contractName);
    const MelandForwarderAddress = await MigrationsI.getProxy("MelandForwarder");
    const ProductManagerAddress = await MigrationsI.getProxy("ProductManager");

    const marketplaceBytecode = `${Marketplace.bytecode}${web3.eth.abi.encodeParameter("address", MelandForwarderAddress).slice(2)}`;

    await MigrationsI.upgrade(contractName, marketplaceBytecode);
}