// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IMelandChainERC1155CID.sol";
import "../common/MelandAccessRoles.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "./IMelandCID.sol";

// Cross-chain NFT of Meland subchains.
// For AMM Convert NFT to CID for storage, then mint when charging to private chain.
contract MelandChainERC1155CID is
    Initializable,
    MelandAccessRoles,
    ERC1155Upgradeable,
    IMelandChainERC1155CID,
    IMelandCID,
    UUPSUpgradeable,
    ERC2771ContextUpgradeable
{
    // set of holders, can be this bridge or other bridges
    mapping(address => bool) public isHolder;
    address[] public holders;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) ERC2771ContextUpgradeable(trustedForwarder) {

    }

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
            super.supportsInterface(interfaceId);
    }

    function addHolder(address holder) public onlyRole(GM_ROLE) {
        isHolder[holder] = true;
        holders.push(holder);
    }

    function callSwapoutWithCID(
        address to,
        uint256 cid,
        uint256 value
    ) external {
        _callSwapoutWithCID(to, cid, value);
    }

    function _callSwapoutWithCID(
        address to,
        uint256 cid,
        uint256 value
    ) internal {
        _burn(msg.sender, cid, value);
        emit SwapoutWithCID(to, cid, value);
    }

    function _MPCPermit2Keccak256(MPCPermit memory signature)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(signature.r, signature.s, signature.v));
    }

    // According to the MPC signature of the main Meland network, mint
    function callSwapinWithCID(
        MPCPermit memory signature,
        SwapinParams memory swapinparams
    ) external {
        // TODO
        // verify signature.
        bytes32 signatureKeccak256 = _MPCPermit2Keccak256(signature);
        _mint(
            swapinparams.to,
            swapinparams.cid,
            swapinparams.value,
            swapinparams.data
        );
        emit SwapinWithCID(
            signatureKeccak256,
            swapinparams.to,
            swapinparams.cid,
            swapinparams.value
        );
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

    function getCidByTokenId(uint256 tokenId) external pure returns (uint256) {
        return tokenId;
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
                _callSwapoutWithCID(to, ids[i], amounts[i]);
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
