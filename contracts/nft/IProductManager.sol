// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IProductManager {
    // 根据NFT地址和tokenId
    // 返回商品id.
    // bool -> 表示该地址有没有匹配到商品
    // bytes32 -> 如果匹配到返回的对应的商品id
    function getProductId(address, uint256) external view returns(bytes32);
}