// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IMelandChainERC1155CID.sol";
import "../common/MelandAccessRoles.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "./IMelandCID.sol";
import "./ERC1155Upgradeable.sol";
import "../metatx/IMelandForwarder.sol";
import "../swap/IMelandSwapFactory.sol";

// Cross-chain NFT of Meland subchains.
// For AMM Convert NFT to CID for storage, then mint when charging to private chain.
contract MelandChainERC1155CID is
    Initializable,
    MelandAccessRoles,
    ERC1155Upgradeable,
    IMelandChainERC1155CID,
    IMelandCID,
    UUPSUpgradeable,
    EIP712Upgradeable,
    ERC2771ContextUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using AddressUpgradeable for address;

    bytes32 private constant _TYPEHASH =
        keccak256(
            "SwapinParams(address from,address to,uint256 cid,uint256 value,uint256 nonce,bytes data)"
        );
    
    IMelandSwapFactory private immutable _swapFactory;

    // set of holders, can be this bridge or other bridges
    mapping(address => bool) public isHolder;
    address[] public holders;

    mapping(address => uint256) private _nonces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address trustedForwarder,
        IMelandSwapFactory swapFactory
    )
        ERC2771ContextUpgradeable(trustedForwarder)
    {
        _swapFactory = swapFactory;
        require(address(_swapFactory) != address(0), "Swap factory is not set");
    }

    function initialize(address mpc) public initializer {
        __MelandAccessRoles_init(mpc);
        __UUPSUpgradeable_init();
        __EIP712_init("MelandChainERC1155CID", "1");
    }

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
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
            interfaceId == type(IMelandCID).interfaceId ||
            interfaceId == type(IMelandChainERC1155CID).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function addHolder(address holder) public onlyRole(GM_ROLE) {
        if (isHolder[holder]) {
            return;
        }
        isHolder[holder] = true;
        holders.push(holder);
    }

    function callSwapoutWithCID(
        address to,
        uint256 cid,
        uint256 value
    ) external {
        address from = _msgSender();
        _callSwapoutWithCID(from, to, cid, value);
    }

    function _callSwapoutWithCID(
        address from,
        address to,
        uint256 cid,
        uint256 value
    ) internal {
        _burn(from, cid, value);
        emit SwapoutWithCID(to, cid, value);
    }

    function _MPCPermit2Keccak256(bytes calldata signature)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(signature);
    }

    function verify(SwapinParams memory swapinparams, bytes calldata signature)
        public
        view
        returns (bool)
    {
        // TODO
        return true;
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TYPEHASH,
                    swapinparams.from,
                    swapinparams.to,
                    swapinparams.cid,
                    swapinparams.value,
                    swapinparams.nonce,
                    keccak256(swapinparams.data)
                )
            )
        ).recover(signature);
        return
            _nonces[swapinparams.from] == swapinparams.nonce &&
            hasRole(MINTER_ROLE, signer);
    }

    // According to the MPC signature of the main Meland network, mint
    function callSwapinWithCID(
        bytes calldata signature,
        SwapinParams memory swapinparams
    ) external {
        require(
            verify(swapinparams, signature),
            "Meland.ai.MelandChainERC1155#callSwapinWithTokenId: Invalid signature"
        );
        _nonces[swapinparams.from] = swapinparams.nonce + 1;
        bytes32 signatureKeccak256 = _MPCPermit2Keccak256(signature);
        // TODO test
        bool success = true;
        _mint(
            swapinparams.from,
            swapinparams.to,
            swapinparams.cid,
            swapinparams.value,
            swapinparams.data
        );
        if (success) {
            emit SwapinWithCID(
                signatureKeccak256,
                swapinparams.to,
                swapinparams.cid,
                swapinparams.value
            );
        } else {
            emit RefundSwapin(signatureKeccak256);
        }

        address realsender = msg.sender;
        if (
            realsender.isContract() &&
            IERC165Upgradeable(realsender).supportsInterface(
                type(IMelandForwarder).interfaceId
            )
        ) {
            IMelandForwarder(realsender).setExecuted(success);
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

    function getCidByTokenId(uint256 tokenId) external pure returns (uint256) {
        return tokenId;
    }

    // TODO Test
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable) {
        if (hasRole(MINTER_ROLE, from)
            || _swapFactory.isPool(from)
        ) {
             for (uint256 i = 0; i < ids.length; i++) {
                _mintNoCheck(from, from, ids[i], amounts[i], data);
            }
        }
    }

    function _isHolderAddress(address account) internal view returns(bool) {
        return isHolder[account] || _swapFactory.isPool(account);
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable) {
        if (to != address(0) && !_isHolderAddress(to)) {
            for (uint256 i = 0; i < ids.length; i++) {
                _callSwapoutWithCID(to, to, ids[i], amounts[i]);
            }
        }

        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
