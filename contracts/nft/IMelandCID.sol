// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMelandCID {
    function getCidByTokenId(uint256 tokenId) external view returns (uint256);
}