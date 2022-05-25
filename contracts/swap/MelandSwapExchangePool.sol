// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./IMelandSwapExchangePool.sol";
import "../nft/IProductManager.sol";

contract MelandSwapExchangePool20T1155 is
    ERC20,
    ERC2771Context,
    IMelandSwapExchangePool
{
    // Variables
    IERC1155 internal immutable erc1155token;

    IERC20Metadata internal immutable erc20token;

    // ERC1155 token id
    uint256 public immutable tokenId;

    address public immutable factory;

    bytes32 public immutable productId;
    string public category;

    // erc20 token reserve
    uint256 internal erc20Reserve;

    // erc1155 token reserve
    uint256 internal erc1155Reserve;

    uint256 internal erc1155ReserveActivated;

    uint256 internal constant ownerCutPerMillion = 50000;

    constructor(
        IERC1155 _erc1155token,
        IERC20Metadata _erc20token,
        uint256 _tokenId,
        bytes32 _productId,
        string memory _category,
        address trustedForwarder
    )
        ERC20(
            "Meland20T1155Pool",
            string(abi.encodePacked(_erc20token.name(), "-", _productId))
        )
        ERC2771Context(trustedForwarder)
    {
        erc1155token = _erc1155token;
        erc20token = _erc20token;
        tokenId = _tokenId;
        factory = _msgSender();

        productId = _productId;
        category = _category;
    }

    function totalSupplie() public view returns (uint256) {
        return totalSupply();
    }

    // 初始化流动性需要提供双边token.
    function _initLiquidity(
        address provider,
        uint256 erc20Amount,
        uint256 erc1155Amount
    ) internal {
        require(
            erc20Amount > 1000 * 10**erc20token.decimals(),
            "MelandSwapExchangePool20T1155: initLiquidity: erc20Amount must be greater than 1000"
        );
        require(
            erc1155Amount > 0,
            "Meland.Swap.ExchangePool20T1155.initLiquidity: erc1155Amount must be greater than 0"
        );
        require(
            totalSupplie() == 0,
            "Meland.Swap.ExchangePool20T1155#initLiquidity: already initialized"
        );
        require(
            erc20token.allowance(provider, address(this)) >= erc20Amount,
            "Meland.Swap.ExchangePool20T1155#initLiquidity: provider does not have enough allowance"
        );

        erc1155ReserveActivated = erc1155Amount;
        erc1155Reserve = erc1155Amount;
        erc20Reserve = erc20Amount;
        erc20token.transferFrom(provider, address(this), erc20Amount);

        // mint lp token
        _mint(provider, erc20Amount);

        // TODO.
        // Mint MF token.

        // emit event
        emit LiquidityAdded(provider, erc1155Amount, erc20Amount);
    }

    // 获取该池可以质押多少erc20 token
    function getERC20AvailableSpace() public view returns (uint256) {
        uint256 preActivate1155Reserve = erc1155Reserve -
            erc1155ReserveActivated;
        return
            (preActivate1155Reserve * erc20Reserve) / erc1155ReserveActivated;
    }

    function _addERC20Liquidity(address provider, uint256 erc20Amount)
        internal
    {
        require(
            totalSupplie() > 0,
            "Meland.Swap.ExchangePool20T1155#addERC20Liquidity: not initialized"
        );
        require(
            erc20Amount <= getERC20AvailableSpace(),
            "Meland.Swap.ExchangePool20T1155#addERC20Liquidity: not enough space"
        );
        require(
            erc20token.allowance(provider, address(this)) >= erc20Amount,
            "Meland.Swap.ExchangePool20T1155#initLiquidity: provider does not have enough allowance"
        );

        // 添加erc20token时, 计算激活nft的数量。
        uint256 erc1155Activate = (erc20Amount / erc20Reserve) * erc1155ReserveActivated;
        erc1155ReserveActivated += erc1155Activate;

        require(erc1155Reserve >= erc1155ReserveActivated, "Meland.Swap.ExchangePool20T1155#addERC20Liquidity: erc1155ReserveActivated must be less than erc1155Reserve");

        uint256 liquidityToMint = (erc20Amount * totalSupplie()) / erc20Reserve;

        erc20token.transferFrom(provider, address(this), erc20Amount);
        erc20Reserve += erc20Amount;

        // mint lp token
        _mint(provider, liquidityToMint);

        // TODO.
        // Mint MF token.

        // emit event
        emit LiquidityAdded(provider, 0, erc20Amount);
    }

    function _addERC1155Liquidity(address provider, uint256 erc1155Amount)
        internal
    {
        
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }
}
