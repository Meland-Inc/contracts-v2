// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/MinimalForwarderUpgradeable.sol";
import "../common/MelandAccessRoles.sol";

contract MelandForwarder is MinimalForwarderUpgradeable, UUPSUpgradeable, MelandAccessRoles {
    function initialize(address mpc) public initializer {
        __MelandAccessRoles_init(mpc);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
