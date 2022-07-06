// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/MinimalForwarderUpgradeable.sol";
import "../common/MelandAccessRoles.sol";

interface IMelandForwarder
{
    event Executed(
        address indexed from,
        bool success,
        bytes returndata
    );

    function setExecuted(bool success) external;
}
