// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../common/MelandAccessRoles.sol";
import "./IProductManager.sol";
import "./IProductRepository.sol";

contract ProductManager is Initializable, MelandAccessRoles, UUPSUpgradeable, IProductManager {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    IProductRepository[] private _productRepositories;

    function initialize(address mpc) public initializer {
        __MelandAccessRoles_init(mpc);
        __UUPSUpgradeable_init();
    }

    function addRepository(IProductRepository repository) external onlyRole(GM_ROLE) {
        _productRepositories.push(repository);
    }

    // 根据NFT地址和tokenId
    // 返回商品id.
    // bool -> 表示该地址有没有匹配到商品
    // bytes32 -> 如果匹配到返回的对应的商品id
    function getProductId(address nft, uint256 tokenId) external view returns(bytes32) {
        for (uint256 i = 0; i < _productRepositories.length; i++) {
            bool rmatch;
            bytes32 productId;
            (rmatch, productId) = _productRepositories[i].getProductId(nft, tokenId);
            if (rmatch) {
                return productId;
            }
        }
        revert("Meland.ProductManager#getProductId: no product found");
    }

    // 根据NFT地址和tokenId
    // 返回商品所属的分类
    // bool -> 表示是否匹配到
    function getCategory(address nft, uint256 tokenId) external view returns(string memory) {
        for (uint256 i = 0; i < _productRepositories.length; i++) {
            bool rmatch;
            string memory category;
            (rmatch, category) = _productRepositories[i].getCategory(nft, tokenId);
            if (rmatch) {
                return category;
            }
        }
        revert("Meland.ProductManager#getCategory: no category found");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        
    }
}
