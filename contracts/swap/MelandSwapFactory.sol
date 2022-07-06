// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./MelandSwapExchangePool20T1155.sol";
import "../common/MelandAccessRoles.sol";
import "../nft/IProductManager.sol";
import "./IMelandSwapFactory.sol";

contract MelandSwapFactory is
    MelandAccessRoles,
    UUPSUpgradeable,
    IMelandSwapFactory,
    ERC2771ContextUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable xtrustedForwarder;

    IProductManager public productManager;

    mapping(bytes32 => mapping(address => address)) private _poolByProductIdAndTKNAddress;
    mapping(address => bool) private _isPool;

    uint256 internal tokenBanlance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder)
        ERC2771ContextUpgradeable(trustedForwarder)
    {
        xtrustedForwarder = trustedForwarder;
    }

    function initialize(address mpc, IProductManager _pm) public initializer {
        __UUPSUpgradeable_init();
        __MelandAccessRoles_init(mpc);
        productManager = _pm;
    }

    function isPool(address mabyePool) external view returns(bool) {
        return _isPool[mabyePool];
    }

    function createPoolByCommunity(
        IERC1155 erc1155,
        uint256 tokenId,
        IERC20Metadata erc20,
        uint256 erc20Amount,
        uint256 erc1155Amount
    ) external onlyRole(GM_ROLE) {
        address creator = _msgSender();
        MelandSwapExchangePool20T1155 pool = _createPool(erc1155, tokenId, erc20);
        erc20.approve(address(pool), erc20Amount);
        erc20.transferFrom(creator, address(this), erc20Amount);
        pool.init(creator, erc20Amount, erc1155Amount);
    }

    function _createPool(
        IERC1155 erc1155,
        uint256 tokenId,
        IERC20Metadata erc20
    ) internal returns(MelandSwapExchangePool20T1155) {
        bytes32 productId = productManager.getProductId(address(erc1155), tokenId);
        require(_poolByProductIdAndTKNAddress[productId][address(erc20)] == address(0), "MelandSwapFactory#_createPool: Duplicate creation");
        MelandSwapExchangePool20T1155 pool = new MelandSwapExchangePool20T1155(
            erc1155,
            erc20,
            tokenId,
            productId,
            xtrustedForwarder
        );
        _poolByProductIdAndTKNAddress[productId][address(erc20)] = address(pool);
        _isPool[address(pool)] = true;
        emit CreatePool(
            address(pool),
            address(erc20),
            productId
        );
        return pool;
    }

    function getStock(bytes32 productId, IERC20Metadata erc20token) external view returns(uint256) {
        address pooladdress = _poolByProductIdAndTKNAddress[productId][address(erc20token)];
        if (pooladdress == address(0)) {
            return 0;
        }
        MelandSwapExchangePool20T1155 pool = MelandSwapExchangePool20T1155(pooladdress);
        return pool.erc1155FragmentReservesActivated() / pool.nftfragments();
    }

    function getBuyPrice(bytes32 productId, IERC20Metadata erc20token, uint256 buyamount) external view returns(uint256) {
        if (buyamount == 0) {
            return 0;
        }
        address pooladdress = _poolByProductIdAndTKNAddress[productId][address(erc20token)];
        if (pooladdress == address(0)) {
            return 0;
        }
        MelandSwapExchangePool20T1155 pool = MelandSwapExchangePool20T1155(pooladdress);
        (uint256 fromUserPrice,,) = pool.getBuyPrice(buyamount);
        return fromUserPrice;
    }

    function beginBuy(bytes32, IERC20Metadata erc20token) external {
        tokenBanlance = erc20token.balanceOf(address(this));
    }

    function buy(bytes32 productId, IERC20Metadata erc20token, address buyer, uint256 buyamount, uint256 tknRate) external {
        require(buyamount > 0, "MelandSwapFactory#buy: buyamount less 1");
        uint256 newTokenBanlance = erc20token.balanceOf(address(this));
        address pooladdress = _poolByProductIdAndTKNAddress[productId][address(erc20token)];
        require(pooladdress != address(0), "MelandSwapFactory#buy: pool not exists");
        MelandSwapExchangePool20T1155 pool = MelandSwapExchangePool20T1155(pooladdress);
        (uint256 fromUserPrice,,) = pool.getBuyPrice(buyamount);
        uint256 diff = newTokenBanlance - tokenBanlance;
        require(diff == fromUserPrice, "MelandSwapFactory#buy: not enough token");

        erc20token.approve(pooladdress, fromUserPrice);

        pool.autoBuy(buyer, address(this), buyamount, tknRate);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        
    }

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
