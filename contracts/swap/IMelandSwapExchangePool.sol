// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMelandSwapExchangePool {
    event LiquidityAdded(
        address indexed provider,
        uint256 erc1155Amount,
        uint256 erc20amount
    );
}
