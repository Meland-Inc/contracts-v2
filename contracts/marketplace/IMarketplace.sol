// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IMarketplace is IERC1155ReceiverUpgradeable {
    struct Order {
        uint256 id;
        address seller;
        uint256 tokenId;
        uint256 amount;
        address nft;
        uint256 priceInWeiForUnit;
        IERC20Upgradeable acceptedToken;
    }

    struct CreateOrderParamsWithERCRecived {
        uint256 priceInWeiForUnit;
        address acceptedToken;
    }

    struct AutoBuyFixStack2deep {
        uint256 poolBuyAmount;
        uint256 poolBuyPrice;
        uint256 totalPrice;
        uint256 index;
    }

    struct AutoBuyFixStack2deepReturns {
        uint256[] execOrderIds;
        uint256[] execOrderAmounts;
        uint256 poolBuyAmount;
        uint256 poolBuyPrice;
        uint256 needTotalPrice;
    }

    event OrderCreated(
        uint256 id,
        bytes32 indexed productId,
        Order order
    );

    event OrderCanceled(uint256 id);

    event OrderUpdated(uint256 id);

    // tknRate USD*10**18
    // the exchange rate is the exchange rate of TKN token to USD at the time of order execution, to avoid attacks, and can only be used for query statistics.
    event OrderSellout(uint256 id, uint256 amount, uint256 tknRate, bool isSellout, address buyer);

    event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);
}
