/* eslint-disable no-undef */
// 自动更新constanst.ts
const fs = require('fs');
const path = require('path');
const { exit } = require('process');
const Migrations = artifacts.require("Migrations");

const promiseOpen = (filePath, mode = 'w') => {
    return new Promise((resolve, reject) => {
        fs.open(filePath, mode, (error, fd) => {
            if (error) {
                return reject(error);
            }
            return resolve(fd);
        });
    })
};

const networkFilenameMap = {
    'develop': 'local.json',
    'mumbai': 'mumbai.json',
    'matic': 'matic.json'
};

const networkStartBlockMap = {
    'develop': "0",
    'mumbai': "23574402",
    'matic': "23029177",
}

module.exports = async function (_) {
    try {
        let network = config.network;
        const configPath = path.join(process.env.indexerConfigDir || process.cwd(), `${networkFilenameMap[network]}`);
        const MigrationsI = await Migrations.deployed();
        let MELDAddress = '0x48844ddba89799dc40ec31728dac629802d407f3';
    
        if (network == "mumbai") {
            MELDAddress = "0x5a0585d409ca86d9fa771690ea37d32405da1f67";
        }
    
        const fd = await promiseOpen(configPath);
    
        /// 本地开发模拟mumbai链
        const code = `{
    "network": "${network}",
    "Marketplace_address": "${await MigrationsI.getProxy("Marketplace")}",
    "MelandForwarder_address": "${await MigrationsI.getProxy("MelandForwarder")}",
    "MelandChainERC1155_address": "${await MigrationsI.getProxy("MelandChainERC1155")}",
    "MelandChainERC1155CID_address": "${await MigrationsI.getProxy("MelandChainERC1155CID")}",
    "MelandSwapFactory_address": "${await MigrationsI.getProxy("MelandSwapFactory")}",
    "MELD_address": "0x5a0585d409ca86d9fa771690ea37d32405da1f67",
    "MELDRecharge_address": "0x714df076992f95E452A345cD8289882CEc6ab82F",
    "start_block": "27151567"
}`;
    
        await new Promise((resolve) => {
            fs.write(fd, Buffer.from(code), (error) => {
                if (error) {
                    throw error;
                }
    
                resolve();
            });
        });
    
        _();
    } catch(error) {
        console.log(error);
        _();
    }
};