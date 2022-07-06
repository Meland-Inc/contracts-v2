const MelandForwarder = artifacts.require("MelandForwarder");
const Migrations = artifacts.require("Migrations");
const { getInitializerData } = require('@openzeppelin/truffle-upgrades/dist/utils/initializer-data');

module.exports = async function (deployer, network, accounts) {
    const MigrationsI = await Migrations.deployed();

    let MelandForwarderAddress = await MigrationsI.getProxy("MelandForwarder");

    if (MelandForwarderAddress !== "0x0000000000000000000000000000000000000000") {
        console.debug("MelandForwarder already deployed", MelandForwarderAddress);
        return;
    }

    const initdata = getInitializerData(MelandForwarder, [accounts[0]]);
    const result = await MigrationsI.deploy("MelandForwarder", MelandForwarder.bytecode, initdata);
    MelandForwarderAddress = await MigrationsI.getProxy("MelandForwarder");
    console.debug("MelandForwarder deployed", MelandForwarderAddress);
}