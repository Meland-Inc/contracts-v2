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
import "./IMelandCID.sol";

contract ProductManager is
    Initializable,
    MelandAccessRoles,
    UUPSUpgradeable,
    IProductManager
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    IProductRepository[] private _productRepositories;

    function initialize(address mpc) public initializer {
        __MelandAccessRoles_init(mpc);
        __UUPSUpgradeable_init();
    }

    // 保持扩展性
    function addRepository(IProductRepository repository)
        external
        onlyRole(GM_ROLE)
    {
        _productRepositories.push(repository);
    }

    // 默认打包行为
    function getDefaultProductId(address nft, uint256 tokenId)
        internal
        view
        returns (bool, bytes32)
    {
        string memory tag = "meland.ai";
        ERC165Upgradeable nftDetect = ERC165Upgradeable(nft);
        if (nftDetect.supportsInterface(type(IMelandCID).interfaceId)) {
            uint256 cid = IMelandCID(nft).getCidByTokenId(tokenId);
            bytes32 productId = keccak256(abi.encodePacked(tag, cid));
            return (true, productId);
        }
        return (false, bytes32(0));
    }

    // 根据NFT地址和tokenId
    // 返回商品id.
    // bool -> 表示该地址有没有匹配到商品
    // bytes32 -> 如果匹配到返回的对应的商品id
    function getProductId(address nft, uint256 tokenId)
        external
        view
        returns (bytes32)
    {
        bool rmatch;
        bytes32 productId;

        (rmatch, productId) = getDefaultProductId(nft, tokenId);

        if (rmatch) {
            return productId;
        }

        for (uint256 i = 0; i < _productRepositories.length; i++) {
            (rmatch, productId) = _productRepositories[i].getProductId(
                nft,
                tokenId
            );
            if (rmatch) {
                return productId;
            }
        }
        revert("Meland.ProductManager#getProductId: no product found");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
