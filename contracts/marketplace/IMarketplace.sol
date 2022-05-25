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

    event OrderCreated(
        uint256 id,
        bytes32 indexed productId,
        string category,
        Order order
    );

    event OrderCanceled(uint256 id);

    event OrderSellout(uint256 id, uint256 amount, bool isSellout);

    event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);
}
