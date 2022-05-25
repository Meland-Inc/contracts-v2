const MelandForwarder = artifacts.require("MelandForwarder");
const Migrations = artifacts.require("Migrations");
const { getInitializerData } = require('@openzeppelin/truffle-upgrades/dist/utils/initializer-data');

module.exports = async function (deployer, network, accounts) {
    const MigrationsI = await Migrations.deployed();

    const initdata = getInitializerData(MelandForwarder, [accounts[1]]);
    await MigrationsI.deploy("MelandForwarder", MelandForwarder.bytecode, initdata, { from: accounts[1] });
}