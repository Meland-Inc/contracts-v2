// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/MinimalForwarderUpgradeable.sol";
import "../common/MelandAccessRoles.sol";
import "./IMelandForwarder.sol";

contract MelandForwarder is
    IMelandForwarder,
    MinimalForwarderUpgradeable,
    UUPSUpgradeable,
    MelandAccessRoles
{
    function initialize(address mpc) public initializer {
        __MelandAccessRoles_init(mpc);
        __UUPSUpgradeable_init();
        __MinimalForwarder_init();
    }

    bool private _isSetExecuted;
    bool private _isExecuted;

    function melandExecute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        _isSetExecuted = false;
        _isExecuted = false;
        (bool success, bytes memory returndata) = MinimalForwarderUpgradeable
            .execute(req, signature);

        if (_isSetExecuted) {
            success = _isExecuted;
        }

        emit Executed(req.from, success, returndata);

        return (success, returndata);
    }

    function setExecuted(bool success) external {
        _isSetExecuted = true;
        _isExecuted = success;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            interfaceId == type(IMelandForwarder).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
