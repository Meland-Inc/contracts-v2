
const Migrations = artifacts.require("Migrations");
const { getInitializerData } = require('@openzeppelin/truffle-upgrades/dist/utils/initializer-data');
const contractName = "Marketplace";
const Marketplace = artifacts.require(contractName);
const Web3 = require("web3");
const web3 = new Web3();

module.exports = async function (deployer, network, accounts) {
    const MigrationsI = await Migrations.deployed();

    let MelandProxyAddress = await MigrationsI.getProxy(contractName);
    const MelandForwarderAddress = await MigrationsI.getProxy("MelandForwarder");
    const MelandSwapFactoryAddress = await MigrationsI.getProxy("MelandSwapFactory");
    const ProductManagerAddress = await MigrationsI.getProxy("ProductManager");

    if (MelandProxyAddress !== "0x0000000000000000000000000000000000000000") {
        console.debug(contractName + " already deployed", MelandProxyAddress);
        return;
    }

    const marketplaceBytecode = `${Marketplace.bytecode}${web3.eth.abi.encodeParameter("address", MelandForwarderAddress).slice(2)}${web3.eth.abi.encodeParameter("address", MelandSwapFactoryAddress).slice(2)}`;

    const initdata = getInitializerData(Marketplace, [
        accounts[0],
        ProductManagerAddress,
    ]);
    const result = await MigrationsI.deploy(contractName, marketplaceBytecode, initdata);
    MelandProxyAddress = await MigrationsI.getProxy(contractName);
    console.debug(contractName + " deployed", MelandProxyAddress);
}