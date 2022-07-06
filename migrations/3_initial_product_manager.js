
const Migrations = artifacts.require("Migrations");
const { getInitializerData } = require('@openzeppelin/truffle-upgrades/dist/utils/initializer-data');
const contractName = "ProductManager";
const ProductManager = artifacts.require(contractName);

module.exports = async function (deployer, network, accounts) {
    const MigrationsI = await Migrations.deployed();

    let MelandProxyAddress = await MigrationsI.getProxy(contractName);

    if (MelandProxyAddress !== "0x0000000000000000000000000000000000000000") {
        console.debug(contractName + " already deployed");
        return;
    }

    const initdata = getInitializerData(ProductManager, [accounts[0]]);
    const result = await MigrationsI.deploy(contractName, ProductManager.bytecode, initdata);
    MelandProxyAddress = await MigrationsI.getProxy(contractName);
    console.debug(contractName + " deployed", MelandProxyAddress);
}