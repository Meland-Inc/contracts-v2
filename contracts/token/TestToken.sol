// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract TestToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20BurnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    uint256 upgradeDelay;

    PrepareUpgradeImpl prepareUpgradeImpl;
    struct PrepareUpgradeImpl {
        address newImplementation;
        // Ready to upgrade creation time
        uint256 createdAt;
    }

    event NewUpgradeDelay(uint256 deplay);
    event NewPrepareUpgradeImpl(address _newImplementation, uint256 createdAt);

    function initialize() public initializer {
        __ERC20_init("TestERC20.io", "TestToken");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        upgradeDelay = 14 days;

        _mint(msg.sender, getMaxMints());
    }

    function getMaxMints() public view returns (uint256) {
        return 2000000000 * 10**decimals();
    }

    function mint(uint256 amount) public onlyOwner {
        require(
            amount + totalSupply() <= getMaxMints(),
            "Exceeds the maximum number of mintable"
        );
        _mint(msg.sender, amount);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    function setPrepareUpgrade(address _newImplementation) public onlyOwner {
        prepareUpgradeImpl = PrepareUpgradeImpl(
            _newImplementation,
            block.timestamp
        );
        emit NewPrepareUpgradeImpl(_newImplementation, block.timestamp);
    }

    function setUpgradeDelay(uint256 _delay) public onlyOwner {
        require(_delay >= 2 days, "Minimum time is 2 days");
        upgradeDelay = _delay;
        emit NewUpgradeDelay(_delay);
    }

    function _authorizeUpgrade(address _newImplementation)
        internal
        view
        override
        onlyOwner
    {
        require(
            _newImplementation == prepareUpgradeImpl.newImplementation,
            "Upgrade contracts are not in the ready queue"
        );
        require(
            block.timestamp.sub(prepareUpgradeImpl.createdAt) > upgradeDelay,
            "Upgrade contracts must be prepared 2 days in advance"
        );
    }
}
