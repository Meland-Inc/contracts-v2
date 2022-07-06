// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IMelandSwapFactory {
    event CreatePool(
        address indexed pool,
        address erc20,
        bytes32 productId
    );

    function isPool(address) external view returns(bool);

    function getStock(bytes32 productId, IERC20Metadata erc20token) external view returns(uint256);

    function getBuyPrice(bytes32 productId, IERC20Metadata erc20token, uint256 buyamount) external view returns(uint256);

    function beginBuy(bytes32 productId, IERC20Metadata erc20token) external;

    function buy(bytes32 productId, IERC20Metadata erc20token, address buyer, uint256 buyamount, uint256 tknRate) external;
}