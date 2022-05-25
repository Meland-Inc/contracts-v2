// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Migrations {
    address public owner = msg.sender;
    address public deployder;
    uint256 public last_completed_migration;

    mapping(bytes32 => address) private _addressBySalt;

    constructor(address _deployder) {
        deployder = _deployder;
    }

    modifier restricted() {
        require(
            msg.sender == owner || msg.sender == deployder,
            "This function is restricted to the contract's owner or deployer"
        );
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }

    function getProxy(string memory name) public view returns (address) {
        return _addressBySalt[name2salt(name)];
    }

    function name2salt(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encode(name));
    }

    function deploy(
        string memory name,
        bytes memory _code,
        bytes memory _data
    ) public restricted returns (ERC1967Proxy) {
        address logicaddr;
        bytes32 salt = keccak256(abi.encode(_code));
        assembly {
            logicaddr := create2(0, add(_code, 0x20), mload(_code), salt)
            if iszero(extcodesize(logicaddr)) {
                revert(0, 0)
            }
        }
        return _createProxy(name, logicaddr, _data);
    }

    function upgrade(string memory name, bytes memory _code)
        public
        restricted
        returns (ERC1967Proxy)
    {
        address proxy = getProxy(name);
        require(proxy != address(0), "Proxy not found");
        address logicaddr;
        bytes32 salt = keccak256(abi.encode(_code));
        assembly {
            logicaddr := create2(0, add(_code, 0x20), mload(_code), salt)
            if iszero(extcodesize(logicaddr)) {
                revert(0, 0)
            }
        }
        (bool success, ) = proxy.call(
            abi.encodeWithSignature("upgradeTo(address)", logicaddr)
        );
        require(success, "Upgrade failed");
        return ERC1967Proxy(payable(proxy));
    }

    function _createProxy(
        string memory name,
        address logic,
        bytes memory initdata
    ) internal returns (ERC1967Proxy) {
        bytes32 salt = name2salt(name);
        require(_addressBySalt[salt] == address(0), "Proxy already exists");
        ERC1967Proxy proxy = new ERC1967Proxy{salt: salt}(logic, initdata);
        _addressBySalt[salt] = address(proxy);
        return proxy;
    }
}
