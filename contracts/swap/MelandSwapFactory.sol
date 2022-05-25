// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../common/MelandAccessRoles.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "../nft/IProductManager.sol";

contract MelandSwapFactory is
    MelandAccessRoles,
    UUPSUpgradeable,
    ERC2771ContextUpgradeable
{
    IProductManager public productManager;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder)
        ERC2771ContextUpgradeable(trustedForwarder)
    {
        
    }

    function initialize(address mpc, IProductManager _pm) public initializer {
        __UUPSUpgradeable_init();
        __MelandAccessRoles_init(mpc);
        productManager = _pm;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }
}
