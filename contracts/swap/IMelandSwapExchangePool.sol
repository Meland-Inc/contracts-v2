// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMelandSwapExchangePool {
    event LiquidityAdded(
        address indexed provider,
        uint256 erc1155Amount,
        uint256 erc20amount,
        uint256 erc1155LPAdded,
        uint256 erc20LPAdded
    );

    event LiquidityRemoved(
        address indexed provider,
        uint256 erc1155Amount,
        uint256 erc20amount,
        uint256 erc1155LPRemoved,
        uint256 erc20LPRemoved
    );

    event Buy(
        address indexed buyer,
        uint256 buyFragments,
        uint256 price,
        uint256 fees,
        uint256 nftfragmentfees,
        uint256 tknRate
    );

    event Sell(
        address indexed seller,
        uint256 sellFragments,
        uint256 price,
        uint256 fees,
        uint256 nftfragmentfees,
        uint256 tknRate
    );

    event Upgraded(
        address newPool
    );
}
