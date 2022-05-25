// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IMelandChainERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../common/MelandAccessRoles.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "./IMelandCID.sol";

// Cross-chain NFT of Meland subchains.
// Implemented to allow NFTs from the Meland subchain to circulate and be traded on the public chain.
// Allowing a part of contracts, marketplace, AMM exchange to construct it based on user's signature and meland mpc's signature.
// Then when the user buys it, it is charged to the Meland subchain
contract MelandChainERC1155 is
    Initializable,
    MelandAccessRoles,
    ERC1155Upgradeable,
    IMelandChainERC1155,
    IMelandCID,
    UUPSUpgradeable,
    ERC2771ContextUpgradeable
{
    // set of holders, can be this bridge or other bridges
    mapping(address => bool) public isHolder;
    address[] public holders;
    mapping(uint256 => uint256) private cidByTokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder)
        ERC2771ContextUpgradeable(trustedForwarder)
    {}

    function initialize(address mpc) public initializer {
        __MelandAccessRoles_init(mpc);
        __UUPSUpgradeable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC1155Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IMelandChainERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function addHolder(address holder) public onlyRole(GM_ROLE) {
        isHolder[holder] = true;
        holders.push(holder);
    }

    function callSwapoutWithTokenId(
        address to,
        uint256 tokenId,
        uint256 value
    ) external {
        _callSwapoutWithTokenId(to, tokenId, value);
    }

    function _callSwapoutWithTokenId(
        address to,
        uint256 tokenId,
        uint256 value
    ) internal {
        _burn(msg.sender, tokenId, value);
        emit SwapoutWithTokenId(to, tokenId, value);
    }

    function _MPCPermit2Keccak256(MPCPermit memory signature)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked(signature.r, signature.s, signature.v));
    }

    // Test to marketplace
    function test() public {
        
    }

    function callSwapinWithTokenId(
        MPCPermit memory signature,
        SwapinParams memory swapinparams
    ) external {
        bytes32 signatureKeccak256 = _MPCPermit2Keccak256(signature);

        (bool success, ) = address(this).call(
            abi.encodeWithSignature(
                "_mint(address,uint256,uint256,bytes)",
                swapinparams.to,
                swapinparams.tokenId,
                swapinparams.value,
                swapinparams.data
            )
        );

        if (success) {
            cidByTokenId[swapinparams.tokenId] = swapinparams.cid;
            emit SwapinWithTokenId(
                signatureKeccak256,
                swapinparams.to,
                swapinparams.tokenId,
                swapinparams.value
            );
        } else {
            emit RefundSwapin(signatureKeccak256);
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function getCidByTokenId(uint256 tokenId) external view returns (uint256) {
        return cidByTokenId[tokenId];
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable) {
        if (to != address(0) && isHolder[to]) {
            for (uint256 i = 0; i < ids.length; i++) {
                _callSwapoutWithTokenId(to, ids[i], amounts[i]);
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
