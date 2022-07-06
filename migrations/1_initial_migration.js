const Migrations = artifacts.require("Migrations");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Migrations, accounts[0], { from: accounts[4] });
};