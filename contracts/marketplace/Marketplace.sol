// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../common/MelandAccessRoles.sol";
import "../nft/IProductManager.sol";
import "./IMarketplace.sol";
import "../swap/IMelandSwapFactory.sol";

contract Marketplace is
    Initializable,
    IMarketplace,
    MelandAccessRoles,
    UUPSUpgradeable,
    ERC2771ContextUpgradeable,
    ERC1155ReceiverUpgradeable
{
    IMelandSwapFactory public immutable factory;

    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _orderIdCounter;

    IProductManager public productManager;

    uint256 public ownerCutPerMillion;

    mapping(uint256 => Order) public orderById;

    mapping(bytes32 => mapping(address => uint256[]))
        private _orderIdsByProductIdAndERC20Address;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder, IMelandSwapFactory _factory)
        ERC2771ContextUpgradeable(trustedForwarder)
    {
        factory = _factory;
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

    function _addOrderIdsByProductIdAndERC20Address(
        bytes32 productId,
        address token,
        uint256 orderId
    ) private {
        if (_orderIdsByProductIdAndERC20Address[productId][token].length == 0) {
            _orderIdsByProductIdAndERC20Address[productId][token] = [orderId];
        } else {
            _orderIdsByProductIdAndERC20Address[productId][token].push(orderId);
        }
    }

    function _removeOrderIdsByProductIdAndERC20Address(
        bytes32 productId,
        address token,
        uint256 orderId
    ) private {
        uint256 index;
        uint256 length = _orderIdsByProductIdAndERC20Address[productId][token]
            .length;
        for (uint256 i = 0; i < length; i++) {
            if (
                _orderIdsByProductIdAndERC20Address[productId][token][i] ==
                orderId
            ) {
                index = i;
                break;
            }
        }
        require(
            _orderIdsByProductIdAndERC20Address[productId][token][index] ==
                orderId,
            "Meland.Marketplace#_removeOrderIdsByProductIdAndERC20Address:  orderId not found"
        );
        uint256 lastOrderId = _orderIdsByProductIdAndERC20Address[productId][
            token
        ][length - 1];

        _orderIdsByProductIdAndERC20Address[productId][token][
            index
        ] = lastOrderId;

        _orderIdsByProductIdAndERC20Address[productId][token].pop();
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
        }
    }

    function executeOrderPremit(
        uint256 orderId,
        uint256 tknRate,
        uint256 amount,
        uint256 priceInWeiForUnit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        Order memory order = orderById[orderId];
        address buyer = _msgSender();
        uint256 totalPrice = amount * priceInWeiForUnit;
        IERC20PermitUpgradeable(address(order.acceptedToken)).permit(
            buyer,
            address(this),
            totalPrice,
            deadline,
            v,
            r,
            s
        );
        _executeOrder(orderId, tknRate, buyer, amount, priceInWeiForUnit);
    }

    function executeOrder(
        uint256 orderId,
        uint256 tknRate,
        uint256 amount,
        uint256 priceInWeiForUnit
    ) external {
        address buyer = _msgSender();
        _executeOrder(orderId, tknRate, buyer, amount, priceInWeiForUnit);
    }

    function updateOrder(uint256 orderId, uint256 priceInWeiForUnit) external {
        address operator = _msgSender();
        _updateOrder(orderId, priceInWeiForUnit, operator);
    }

    function _updateOrder(
        uint256 orderId,
        uint256 priceInWeiForUnit,
        address operator
    ) internal {
        Order memory order = orderById[orderId];
        require(
            order.seller == operator,
            "Meland.Marketplace#_updateOrder: The operator is not the seller"
        );

        order.priceInWeiForUnit = priceInWeiForUnit;
        orderById[orderId] = order;

        emit OrderUpdated(orderId);
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

    function _removeArrayIndex(uint256[] memory elements, uint256 index)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory newElements = new uint256[](elements.length - 1);
        for (uint256 i = 0; i < newElements.length; i++) {
            if (i != index && i < index) {
                newElements[i] = elements[i];
            } else {
                newElements[i] = elements[i + 1];
            }
        }
        return newElements;
    }

    function autoBuy(
        bytes32 productId,
        uint256 tknRate,
        IERC20Upgradeable erc20token,
        uint256 amount,
        uint256 totalPrice,
        bool usePool
    ) external {
        AutoBuyFixStack2deepReturns memory ret = autoBuyPrice(
            productId,
            address(erc20token),
            amount,
            usePool
        );
        address buyer = _msgSender();
        require(
            ret.needTotalPrice <= (totalPrice * 10100) / 10000,
            "Meland.Marketplace#autoBuy: The total price is not correct"
        );

        uint256 allowance = erc20token.allowance(buyer, address(this));
        require(
            allowance >= ret.needTotalPrice,
            "Meland.Marketplace#autoBuy: The allowance is not enough"
        );

        for (uint256 i = 0; i < ret.execOrderIds.length; i++) {
            uint256 orderId = ret.execOrderIds[i];
            if (orderId > 0) {
                uint256 orderAmount = ret.execOrderAmounts[i];
                uint256 priceInWeiForUnit = orderById[orderId]
                    .priceInWeiForUnit;
                _executeOrder(
                    orderId,
                    tknRate,
                    buyer,
                    orderAmount,
                    priceInWeiForUnit
                );
            }
        }

        if (ret.poolBuyAmount > 0) {
            // bytes32 productId, IERC20Metadata erc20token, address buyer, uint256 buyamount, uint256 tknRate
            factory.beginBuy(productId, IERC20Metadata(address(erc20token)));
            erc20token.transferFrom(buyer, address(factory), ret.poolBuyPrice);
            factory.buy(
                productId,
                IERC20Metadata(address(erc20token)),
                buyer,
                ret.poolBuyAmount,
                tknRate
            );
        }
    }

    function getProductLowestPrice(
        bytes32 productId,
        IERC20Upgradeable erc20token
    ) external view returns (uint256) {
        uint256[] memory orderIds = _orderIdsByProductIdAndERC20Address[
            productId
        ][address(erc20token)];

        if (orderIds.length == 0) {
            return 0;
        }

        if (orderIds.length == 1) {
            return orderById[orderIds[0]].priceInWeiForUnit;
        }

        uint256 lowestPrice = orderById[orderIds[0]].priceInWeiForUnit;
        for (uint256 i = 1; i < orderIds.length; i++) {
            uint256 orderId = orderIds[i];
            if (orderId > 0) {
                uint256 priceInWeiForUnit = orderById[orderId]
                    .priceInWeiForUnit;
                lowestPrice = _min(lowestPrice, priceInWeiForUnit);
            }
        }

        return lowestPrice;
    }

    function _comparePrice(
        Order memory order,
        uint256 poolPrice,
        uint256 poolAmount
    ) internal view returns (bool) {
        if (poolAmount == 0) {
            return true;
        }
        uint256 priceInWeiForUnit = order.priceInWeiForUnit;
        uint256 fees = (priceInWeiForUnit * ownerCutPerMillion) / 1000000;
        priceInWeiForUnit += fees;
        uint256 poolUnitPrice = poolPrice / poolAmount;

        if (priceInWeiForUnit < poolUnitPrice) {
            return true;
        }

        return false;
    }

    // Help users find the cheapest orders
    function autoBuyPrice(
        bytes32 productId,
        address erc20token,
        uint256 neededAmount,
        bool usePool
    ) public view returns (AutoBuyFixStack2deepReturns memory) {
        uint256[] memory orderIds = _orderIdsByProductIdAndERC20Address[
            productId
        ][erc20token];
        uint256 poolStock = factory.getStock(
            productId,
            IERC20Metadata(erc20token)
        );
        AutoBuyFixStack2deep memory params = AutoBuyFixStack2deep(
            _min(neededAmount, poolStock),
            0,
            0,
            0
        );

        if (!usePool) {
            params.poolBuyAmount = 0;
        }

        AutoBuyFixStack2deepReturns memory ret = AutoBuyFixStack2deepReturns(
            new uint256[](orderIds.length),
            new uint256[](orderIds.length),
            params.poolBuyAmount,
            params.poolBuyPrice,
            params.poolBuyPrice
        );
        
        params.poolBuyPrice = factory.getBuyPrice(
            productId,
            IERC20Metadata(erc20token),
            params.poolBuyAmount
        );
        
        if (orderIds.length == 0) {
            if (params.poolBuyAmount < neededAmount) {
                ret.poolBuyAmount = 0;
                ret.poolBuyPrice = 0;
                ret.needTotalPrice = 0;
                return ret;
            }
            ret.poolBuyAmount = params.poolBuyAmount;
            ret.poolBuyPrice = params.poolBuyPrice;
            ret.needTotalPrice = params.poolBuyPrice + params.totalPrice;
            return ret;
        }

        while (neededAmount > 0 && orderIds.length > 0) {
            Order memory order = orderById[orderIds[0]];
            uint256 matchOrderIndex = 0;

            for (uint256 i = 0; i < orderIds.length; i++) {
                Order memory newOrder = orderById[orderIds[i]];
                if (newOrder.amount == 0) {
                    continue;
                }
                if (newOrder.priceInWeiForUnit > 0) {
                    if (newOrder.priceInWeiForUnit < order.priceInWeiForUnit) {
                        order = newOrder;
                        matchOrderIndex = i;
                    }
                }
            }

            // 除非池子数量不足, 否则如果最低的订单价格比池子价格高
            if (
                !_comparePrice(
                    order,
                    params.poolBuyPrice,
                    params.poolBuyAmount
                ) && params.poolBuyAmount >= neededAmount
            ) {
                ret.poolBuyAmount = params.poolBuyAmount;
                ret.poolBuyPrice = params.poolBuyPrice;
                ret.needTotalPrice = params.poolBuyPrice + params.totalPrice;
                return ret;
            }

            uint256 amount = _min(neededAmount, order.amount);

            if (neededAmount == params.poolBuyAmount) {
                if (params.poolBuyAmount >= amount) {
                    params.poolBuyAmount -= amount;
                } else {
                    params.poolBuyAmount = 0;
                }
            }

            neededAmount -= amount;
            
            params.totalPrice =
                params.totalPrice +
                order.priceInWeiForUnit *
                amount;
            params.poolBuyPrice = factory.getBuyPrice(
                productId,
                IERC20Metadata(erc20token),
                params.poolBuyAmount
            );
            ret.execOrderIds[params.index] = order.id;
            ret.execOrderAmounts[params.index] = amount;
            // Remove the order from the list
            orderIds = _removeArrayIndex(orderIds, matchOrderIndex);
            params.index++;
        }

        ret.poolBuyAmount = params.poolBuyAmount;
        ret.poolBuyPrice = params.poolBuyPrice;
        ret.needTotalPrice = params.poolBuyPrice + params.totalPrice;
        return ret;
    }

    // cancel order
    function cancelOrder(uint256 orderId) external {
        address operator = _msgSender();
        Order memory order = orderById[orderId];
        require(
            order.seller == operator,
            "Meland.Marketplace#cancelOrder: The operator is not the seller"
        );
        require(
            order.amount > 0,
            "Meland.Marketplace#cancelOrder: The order is already executed"
        );
        address nft = order.nft;
        uint256 tokenId = order.tokenId;
        bytes32 productId = productManager.getProductId(nft, tokenId);
        _nftTransfer(nft, tokenId, address(this), operator, order.amount);
        order.amount = 0;
        orderById[orderId] = order;
        _removeOrderIdsByProductIdAndERC20Address(
            productId,
            address(order.acceptedToken),
            orderId
        );
        emit OrderCanceled(orderId);
    }

    function _nftTransfer(
        address nft,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount
    ) private {
        ERC165Upgradeable nftDetect = ERC165Upgradeable(nft);

        if (nftDetect.supportsInterface(type(IERC721Upgradeable).interfaceId)) {
            IERC721Upgradeable(nft).safeTransferFrom(from, to, tokenId);
        } else if (
            nftDetect.supportsInterface(type(IERC1155Upgradeable).interfaceId)
        ) {
            IERC1155Upgradeable(nft).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                ""
            );
        } else {
            revert(
                "Meland.Marketplace#_executeOrder: nft must be erc721 or erc1155"
            );
        }
    }

    function _executeOrder(
        uint256 orderId,
        uint256 tknRate,
        address buyer,
        uint256 amount,
        uint256 priceInWeiForUnit
    ) internal {
        Order memory order = orderById[orderId];
        require(
            order.amount > 0,
            "Meland.Marketplace#_executeOrder: The order amount should be greater than 0"
        );
        require(
            order.priceInWeiForUnit > 0,
            "Meland.Marketplace#_executeOrder: The order price should be greater than 0"
        );
        require(
            order.amount >= amount,
            "Meland.Marketplace#_executeOrder: Insufficient remaining quantity "
        );
        uint256 allowance = order.acceptedToken.allowance(buyer, address(this));
        uint256 totalPrice = amount * priceInWeiForUnit;
        require(
            allowance >= totalPrice,
            "Meland.Marketplace#_executeOrder: Insufficient allowance"
        );

        order.amount -= amount;
        orderById[orderId] = order;

        uint256 saleShareAmount = 0;
        if (ownerCutPerMillion > 0) {
            // Calculate sale share
            saleShareAmount = totalPrice.mul(ownerCutPerMillion).div(1000000);

            // TODO
            // Send to meland.ai
            order.acceptedToken.transferFrom(
                buyer,
                address(this),
                saleShareAmount
            );
        }

        require(
            order.acceptedToken.transferFrom(
                buyer,
                order.seller,
                totalPrice.sub(saleShareAmount)
            ),
            "Meland.Marketplace#_executeOrder: Transfering the sale amount to the seller failed"
        );

        address nft = order.nft;
        uint256 tokenId = order.tokenId;

        _nftTransfer(nft, tokenId, address(this), buyer, amount);

        bytes32 productId = productManager.getProductId(nft, tokenId);

        if (order.amount == 0) {
            _removeOrderIdsByProductIdAndERC20Address(
                productId,
                address(order.acceptedToken),
                order.id
            );
        }

        emit OrderSellout(orderId, amount, tknRate, order.amount == 0, buyer);
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

        _addOrderIdsByProductIdAndERC20Address(
            productId,
            address(acceptedToken),
            orderId
        );

        emit OrderCreated(orderId, productId, order);
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

    bytes4 internal constant CREATE_ORDER_SIG =
        bytes4(keccak256("_createOrder(uint256,address)"));

    function onERC1155BatchReceived(
        address, // _operator,
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes calldata _data
    ) public override returns (bytes4) {
        // This function assumes that the ERC-1155 token contract can
        // only call `onERC1155BatchReceived()` via a valid token transfer.
        // Users must be responsible and only use this Niftyswap exchange
        // contract with ERC-1155 compliant token contracts.
        // Obtain method to call via object signature
        bytes4 functionSignature = bytes4(_data[:4]);
        require(
            functionSignature == CREATE_ORDER_SIG,
            "Meland.Marketplace#onERC1155BatchReceived5: Invalid function signature"
        );
        uint256 priceInWeiForUnit;
        address acceptedToken;
        (priceInWeiForUnit, acceptedToken) = abi.decode(
            _data[4:],
            (uint256, address)
        );
        require(
            acceptedToken.isContract(),
            "Meland.Marketplace#onERC1155BatchReceived1: The accepted token is not a contract"
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            _createOrder(
                _msgSender(),
                _from,
                _ids[i],
                _amounts[i],
                _amounts[i],
                priceInWeiForUnit,
                IERC20Upgradeable(acceptedToken)
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
        bytes calldata _data
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
