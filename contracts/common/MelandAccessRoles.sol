// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IMelandAccessRoles.sol";

contract MelandAccessRoles is AccessControlUpgradeable, IMelandAccessRoles {
    bytes32 public constant GM_ROLE = keccak256("GM_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public DOMAIN_SEPARATOR;

    function __MelandAccessRoles_init(address _mpc) internal {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _mpc);
        _grantRole(GM_ROLE, _mpc);
        _grantRole(MINTER_ROLE, _mpc);
        _grantRole(UPGRADER_ROLE, msg.sender);

        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("meland")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function verifyEIP712(
        address target,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }

    function verifyPersonalSign(
        address target,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = prefixed(hashStruct);
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    DOMAIN_SEPARATOR,
                    hash
                )
            );
    }
}
