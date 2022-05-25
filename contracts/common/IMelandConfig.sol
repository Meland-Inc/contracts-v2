// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMelandConfig {

    // Get Meland owner
    function getOwner() external view returns (address);

    // Get Meland contract deployer address
    function getDeployer() external view returns (address);

    function getGMs() external view returns(address[] memory);
}