// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMelandSwapFactory {
    event CreatePool(
        address indexed pool,
        bytes32 productId,
        string category
    );
}