// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../common/MelandAccessRoles.sol";
import "../nft/IProductManager.sol";
import "./IMarketplace.sol";

contract Marketplace is
    Initializable,
    IMarketplace,
    MelandAccessRoles,
    UUPSUpgradeable,
    ERC2771ContextUpgradeable,
    ERC1155ReceiverUpgradeable
{
    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _orderIdCounter;

    IProductManager public productManager;

    uint256 public ownerCutPerMillion;

    mapping(uint256 => Order) public orderById;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder)
        ERC2771ContextUpgradeable(trustedForwarder)
    {
    }

    function initialize(address mpc, IProductManager _pm) public initializer {
        __MelandAccessRoles_init(mpc);
        __UUPSUpgradeable_init();
        productManager = _pm;
        _setOwnerCutPerMillion(50000);
    }

    // 50000 = 5%
    // 500000 = 50%
    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion)
        public
        onlyRole(GM_ROLE)
    {
        _setOwnerCutPerMillion(_ownerCutPerMillion);
    }

    function _setOwnerCutPerMillion(uint256 _ownerCutPerMillion) internal {
        require(
            _ownerCutPerMillion < 1000000,
            "Meland.Marketplace#_setOwnerCutPerMillion: The owner cut should be between 0 and 999,999"
        );

        ownerCutPerMillion = _ownerCutPerMillion;
        emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
    }

    function _erc721validate(
        IERC721Upgradeable nft,
        uint256 tokenId,
        uint256 amount,
        address sender
    ) internal view {
        require(
            nft.ownerOf(tokenId) == sender,
            "Meland.Marketplace#erc721validate: The sender is not the owner of the token"
        );

        require(
            nft.getApproved(tokenId) == address(this) ||
                nft.isApprovedForAll(sender, address(this)),
            "Meland.Marketplace#erc721validate: The contract is not authorized to manage the asset"
        );

        require(
            amount == 1,
            "Meland.Marketplace#erc721validate: The amount should be 1"
        );
    }

    function _erc1155validate(
        IERC1155Upgradeable nft,
        uint256 tokenId,
        uint256 amount,
        uint256 erc1155recivedAmount,
        address sender
    ) internal view {
        if (amount != erc1155recivedAmount) {
            require(
                nft.balanceOf(sender, tokenId) > 0,
                "Meland.Marketplace#_erc1155validate: Only the owner can create orders"
            );
            require(
                nft.isApprovedForAll(sender, address(this)),
                "Meland.Marketplace#_erc1155validate: The contract is not authorized to manage the asset"
            );
        } else {
            require(
                nft.balanceOf(address(this), tokenId) >= erc1155recivedAmount,
                "Meland.Marketplace#_erc1155validate: Marketplace amount is not enough"
            );
        }
    }

    function _createOrder(
        address nft,
        address sender,
        uint256 tokenId,
        uint256 amount,
        uint256 erc1155recivedAmount,
        uint256 priceInWeiForUnit,
        IERC20Upgradeable acceptedToken
    ) internal {
        _orderIdCounter.increment();
        require(nft.isContract(), "The nft is not a contract");
        require(priceInWeiForUnit > 0, "Price should be bigger than 0");
        ERC165Upgradeable nftDetect = ERC165Upgradeable(nft);

        if (nftDetect.supportsInterface(type(IERC721Upgradeable).interfaceId)) {
            _erc721validate(IERC721Upgradeable(nft), tokenId, amount, sender);
        } else if (
            nftDetect.supportsInterface(type(IERC1155Upgradeable).interfaceId)
        ) {
            _erc1155validate(
                IERC1155Upgradeable(nft),
                tokenId,
                amount,
                erc1155recivedAmount,
                sender
            );
        } else {
            revert(
                "Meland.Marketplace#_createOrder: nft must be erc721 or erc1155"
            );
        }

        bytes32 productId = productManager.getProductId(nft, tokenId);
        string memory category = productManager.getCategory(nft, tokenId);
        uint256 orderId = _orderIdCounter.current();

        Order memory order = Order(
            orderId,
            sender,
            tokenId,
            amount,
            nft,
            priceInWeiForUnit,
            acceptedToken
        );

        orderById[orderId] = order;

        emit OrderCreated(orderId, productId, category, order);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC1155ReceiverUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            interfaceId == type(ERC1155ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    bytes4 internal constant CREATE_ORDER_SIG = bytes4(
        keccak256("_createOrder(uint256,address)")
    );
    function onERC1155BatchReceived(
        address, // _operator,
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override returns (bytes4) {
        // This function assumes that the ERC-1155 token contract can
        // only call `onERC1155BatchReceived()` via a valid token transfer.
        // Users must be responsible and only use this Niftyswap exchange
        // contract with ERC-1155 compliant token contracts.

        // Obtain method to call via object signature
        bytes4 functionSignature = abi.decode(_data, (bytes4));
        require(functionSignature == CREATE_ORDER_SIG, "Meland.Marketplace#onERC1155BatchReceived: Invalid function signature");
        CreateOrderParamsWithERCRecived memory params;
        (, params) = abi.decode(_data, (bytes4, CreateOrderParamsWithERCRecived));
        require(params.acceptedToken.isContract(), "Meland.Marketplace#onERC1155BatchReceived: The accepted token is not a contract");

        for (uint i = 0; i < _ids.length; i++) {
            _createOrder(
                _msgSender(),
                _from,
                _ids[i],
                _amounts[i],
                _amounts[i],
                params.priceInWeiForUnit,
                IERC20Upgradeable(params.acceptedToken)
            );
        }
        return ERC1155_BATCH_RECEIVED_VALUE;
    }

    /**
     * @dev Will pass to onERC115Batch5Received
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override returns (bytes4) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = _id;
        amounts[0] = _amount;

        require(
            ERC1155_BATCH_RECEIVED_VALUE ==
                onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
            "Meland.Marketplace#onERC1155Received: INVALID_ONRECEIVED_MESSAGE"
        );

        return ERC1155_RECEIVED_VALUE;
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
