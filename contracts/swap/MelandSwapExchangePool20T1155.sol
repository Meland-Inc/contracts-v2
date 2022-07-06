// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "./IMelandSwapExchangePool.sol";
import "../nft/IProductManager.sol";

contract MelandSwapExchangePool20T1155 is
    ERC20,
    ERC2771Context,
    IMelandSwapExchangePool,
    ERC1155Receiver
{
    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    // Variables
    IERC1155 public immutable erc1155token;

    IERC20Metadata public immutable erc20token;

    // ERC1155 token id
    uint256 public immutable tokenId;

    address public immutable factory;

    bytes32 public immutable productId;

    uint256 public erc1155LPTotal;
    mapping(address => uint256) erc1155LPByProvider;

    // erc20 token reserve
    uint256 public erc20Reserve;

    // erc1155 token reserve
    uint256 public erc1155FragmentReserves;

    uint256 public erc1155FragmentReservesActivated;

    uint256 public ownerCutPerMillion = 50000;

    uint256 public nftfragments = 10000;

    modifier onlyFactory() {
        require(
            _msgSender() == factory,
            "MelandSwapExchangePool20T1155#onlyFactory: Permission error"
        );
        _;
    }

    constructor(
        IERC1155 _erc1155token,
        IERC20Metadata _erc20token,
        uint256 _tokenId,
        bytes32 _productId,
        address trustedForwarder
    )
        ERC20("Meland20T1155Pool", _poolname(_productId, _erc20token))
        ERC2771Context(trustedForwarder)
    {
        erc1155token = _erc1155token;
        erc20token = _erc20token;
        tokenId = _tokenId;
        factory = _msgSender();
        productId = _productId;
    }

    function _poolname(bytes32 _productId, IERC20Metadata _erc20token)
        internal
        view
        returns (string memory)
    {
        bytes32 buffer = _productId;
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }
        return
            string(abi.encodePacked("0x", converted, "-", _erc20token.name()));
    }

    function totalSupplie() public view returns (uint256) {
        return totalSupply();
    }

    function _mintERC20LP(address to, uint256 amount) internal {
        _mint(to, amount);
    }

    function _burnERC20LP(address from, uint256 amount) internal {
        _burn(from, amount);
    }

    function _mintERC1155LP(address to, uint256 amount) internal {
        erc1155LPTotal = erc1155LPTotal + amount;
        erc1155LPByProvider[to] = erc1155LPByProvider[to] + amount;
    }

    function _burnERC1155LP(address from, uint256 amount) internal {
        erc1155LPTotal = erc1155LPTotal - amount;
        erc1155LPByProvider[from] = erc1155LPByProvider[from] - amount;
    }

    function _toNFTFragments(uint256 amount) internal view returns (uint256) {
        return amount * nftfragments;
    }

    function _toNFT(uint256 fragmentamount, bool round)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 nftamount = fragmentamount / nftfragments;

        if (round && fragmentamount % 100 > 0) {
            nftamount = nftamount + 1;
        }

        return (nftamount, _toNFTFragments(nftamount));
    }

    function _divRound(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a / b;

        if (a % b > 0) {
            result = result + 1;
        }

        return result;
    }

    function _convertNFTFragmentActives(uint256 erc20amount)
        internal
        view
        returns (uint256)
    {
        uint256 erc1155FragmentActivate = (erc20amount *
            erc1155FragmentReservesActivated) / erc20Reserve;
        return erc1155FragmentActivate;
    }

    function _activeNFTFragments(uint256 erc20amount) internal {
        uint256 erc1155FragmentActivate = _convertNFTFragmentActives(
            erc20amount
        );
        erc1155FragmentReservesActivated =
            erc1155FragmentReservesActivated +
            erc1155FragmentActivate;
    }

    function _deactiveNFTFragments(uint256 erc20amount) internal {
        uint256 erc1155FragmentActivate = _convertNFTFragmentActives(
            erc20amount
        );
        erc1155FragmentReservesActivated =
            erc1155FragmentReservesActivated -
            erc1155FragmentActivate;
    }

    function _splitFees(uint256 fees)
        internal
        pure
        returns (uint256 lpFees, uint256 networkFees)
    {
        lpFees = (fees * 80) / 100;
        networkFees = fees - lpFees;
    }

    function init(
        address provider,
        uint256 erc20Amount,
        uint256 erc1155Amount
    ) public onlyFactory {
        address fundsProvider = _msgSender();
        _initLiquidity(provider, fundsProvider, erc20Amount, erc1155Amount);
    }

    // 初始化流动性需要提供双边token.
    function _initLiquidity(
        address provider,
        address fundsProvider,
        uint256 erc20Amount,
        uint256 erc1155Amount
    ) internal {
        require(
            erc20Amount >= 100 * 10**erc20token.decimals(),
            "MelandSwapExchangePool20T1155#initLiquidity: erc20Amount must be greater than 1000"
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
            erc20token.allowance(fundsProvider, address(this)) >= erc20Amount,
            "Meland.Swap.ExchangePool20T1155#initLiquidity: provider does not have enough allowance"
        );

        erc1155FragmentReserves = _toNFTFragments(erc1155Amount);
        erc1155FragmentReservesActivated = _toNFTFragments(erc1155Amount);
        erc20Reserve = erc20Amount;
        erc20token.transferFrom(fundsProvider, address(this), erc20Amount);

        // mint lp token
        _mintERC20LP(provider, erc20Amount);

        // mint nft lp
        _mintERC1155LP(provider, erc1155FragmentReserves);

        // TODO.
        // Mint MF token.

        // emit event
        emit LiquidityAdded(
            provider,
            erc1155Amount,
            erc20Amount,
            erc1155FragmentReserves,
            erc20Amount
        );
    }

    // 获取该池可以质押多少erc20 token
    function getERC20AvailableSpace(uint256 wantStakeAmount)
        public
        view
        returns (uint256, uint256)
    {
        uint256 preActivate1155Reserve = 0;
        if (erc1155FragmentReservesActivated < erc1155FragmentReserves) {
            preActivate1155Reserve =
                erc1155FragmentReserves -
                erc1155FragmentReservesActivated;
        }
        uint256 availableSpace = 0;
        if (erc1155FragmentReservesActivated > 0) {
            availableSpace =
                (preActivate1155Reserve * erc20Reserve) /
                erc1155FragmentReservesActivated;
        }
        uint256 needOpenSpace = 0;

        if (availableSpace < wantStakeAmount) {
            uint256 diffAmount = wantStakeAmount - availableSpace;
            needOpenSpace =
                (diffAmount * erc1155FragmentReservesActivated) /
                erc20Reserve;
        }

        (uint256 nftAmount, ) = _toNFT(needOpenSpace, true);

        return (availableSpace, nftAmount);
    }

    function _addERC20Liquidity(address provider, uint256 erc20Amount)
        internal
    {
        (uint256 availableSpace, ) = getERC20AvailableSpace(0);
        require(
            totalSupplie() > 0,
            "Meland.Swap.ExchangePool20T1155#addERC20Liquidity: not initialized"
        );
        require(
            erc20Amount <= availableSpace,
            "Meland.Swap.ExchangePool20T1155#addERC20Liquidity: not enough space"
        );
        require(
            erc20token.allowance(provider, address(this)) >= erc20Amount,
            "Meland.Swap.ExchangePool20T1155#initLiquidity: provider does not have enough allowance"
        );

        // 添加erc20token时, 计算激活nft的数量。
        _activeNFTFragments(erc20Amount);

        require(
            erc1155FragmentReserves >= erc1155FragmentReservesActivated,
            "Meland.Swap.ExchangePool20T1155#addERC20Liquidity: erc1155ReserveActivated must be less than erc1155Reserve"
        );

        uint256 liquidityToMint = (erc20Amount * totalSupplie()) / erc20Reserve;

        erc20token.transferFrom(provider, address(this), erc20Amount);
        erc20Reserve += erc20Amount;

        // mint lp token
        _mintERC20LP(provider, liquidityToMint);

        // emit event
        emit LiquidityAdded(provider, 0, erc20Amount, 0, liquidityToMint);
    }

    function _addERC1155Liquidity(address provider, uint256 erc1155Amount)
        internal
    {
        require(
            erc1155LPTotal > 0,
            "Meland.Swap.ExchangePool20T1155#addERC20Liquidity: not initialized"
        );
        uint256 fragments = _toNFTFragments(erc1155Amount);

        uint256 liquidityToMint = (fragments * erc1155LPTotal) /
            erc1155FragmentReserves;
        erc1155FragmentReserves += fragments;

        _mintERC1155LP(provider, liquidityToMint);
        // emit event
        emit LiquidityAdded(provider, erc1155Amount, 0, liquidityToMint, 0);
    }

    function addERC20Liquidity(uint256 erc20Amount) public {
        address sender = _msgSender();
        _addERC20Liquidity(sender, erc20Amount);
    }

    function addERC1155Liquidity(uint256 amount) external {
        address provider = _msgSender();
        _addERC1155Liquidity(provider, amount);
    }

    function getSellPrice(uint256 sellFragments)
        public
        view
        returns (
            uint256 toUserPrice,
            uint256 fragmentFees,
            uint256 erc20Fees
        )
    {
        if (sellFragments == 0) {
            return (0, 0, 0);
        }
        fragmentFees = (sellFragments * ownerCutPerMillion) / 2000000;
        uint256 sellWithoutFeeFragments = sellFragments - fragmentFees;
        uint256 numerator = erc20Reserve * sellWithoutFeeFragments;
        uint256 denominator = erc1155FragmentReservesActivated +
            sellWithoutFeeFragments;
        uint256 price = numerator / denominator;
        erc20Fees = (price * ownerCutPerMillion) / 2000000;
        toUserPrice = price - erc20Fees;
    }

    function getBuyPrice(uint256 buyamount)
        public
        view
        returns (
            uint256 fromUserPrice,
            uint256 fragmentFees,
            uint256 erc20Fees
        )
    {
        if (buyamount == 0) {
            return (0, 0, 0);
        }
        uint256 buyFragments = _toNFTFragments(buyamount);
        fragmentFees = (buyFragments * ownerCutPerMillion) / 2000000;
        uint256 buyWithFeeFragments = buyFragments + fragmentFees;

        uint256 numerator = erc20Reserve * buyWithFeeFragments;
        uint256 denominator = erc1155FragmentReservesActivated -
            buyWithFeeFragments;
        uint256 price = numerator / denominator;

        erc20Fees = (price * ownerCutPerMillion) / 2000000;
        fromUserPrice = price - erc20Fees;
    }

    function getWithdrawERC20(address account)
        public
        view
        returns (uint256, uint256)
    {
        uint256 lp = balanceOf(account);
        uint256 canerc20 = (lp * erc20Reserve) / totalSupplie();
        return (canerc20, 0);
    }

    function getWithdrawFragments(address account, bool autoSwap)
        public
        view
        returns (
            uint256 nft,
            uint256 fragmentRemnants,
            uint256 toUserPrice
        )
    {
        uint256 lp = erc1155LPByProvider[account];
        uint256 myLPFragments = (lp * erc1155FragmentReserves) / erc1155LPTotal;

        uint256 fragments = 0;
        (nft, fragments) = _toNFT(myLPFragments, false);

        if (autoSwap) {
            fragmentRemnants = myLPFragments - fragments;
            (toUserPrice, , ) = getSellPrice(fragmentRemnants);
        }
    }

    function withdrawERC20(uint256 withdrawAmount) external {
        address account = _msgSender();
        (uint256 maxWithdrawAmount, uint256 fees) = getWithdrawERC20(account);
        require(
            maxWithdrawAmount >= withdrawAmount,
            "Meland.Swap.ExchangePool20T1155#withdrawERC20: Insufficient balance"
        );

        erc20token.transfer(account, withdrawAmount + fees);
        erc20Reserve -= withdrawAmount;

        _deactiveNFTFragments(withdrawAmount);

        // remove lp
        uint256 liquidityToRemoved = _divRound(
            withdrawAmount * totalSupplie(),
            erc20Reserve
        );
        _burn(account, liquidityToRemoved);

        emit LiquidityRemoved(
            account,
            0,
            withdrawAmount,
            0,
            liquidityToRemoved
        );
    }

    function withdrawERC1155(
        uint256 withdrawAmount,
        uint256 tknRate,
        bool autoSwap
    ) external {
        address account = _msgSender();
        (
            uint256 maxWithdrawAmount,
            uint256 fragmentRemnants,
        ) = getWithdrawFragments(account, autoSwap);
        require(
            maxWithdrawAmount >= withdrawAmount,
            "Meland.Swap.ExchangePool20T1155#withdrawERC1155: Insufficient  balance"
        );

        erc1155token.safeTransferFrom(
            address(this),
            account,
            tokenId,
            withdrawAmount,
            ""
        );
        uint256 withdrawFragments = _toNFTFragments(withdrawAmount);
        withdrawFragments += fragmentRemnants;
        erc1155FragmentReserves -= withdrawFragments;
        uint256 liquidityToRemoved = (withdrawFragments * erc1155LPTotal) /
            erc1155FragmentReserves;

        _burnERC1155LP(account, liquidityToRemoved);

        if (fragmentRemnants > 0) {
            _sell(account, fragmentRemnants, tknRate);
        }

        emit LiquidityRemoved(
            account,
            withdrawAmount,
            0,
            liquidityToRemoved,
            0
        );
    }

    function sell(uint256 sellAmount, uint256 tknRate) external {
        address seller = _msgSender();
        _sell(seller, _toNFTFragments(sellAmount), tknRate);
    }

    function buy(
        uint256 buyamount,
        uint256 tknRate,
        uint256 fromUserPriceFromUI
    ) external {
        address buyer = _msgSender();
        (uint256 fromUserPrice, , ) = getBuyPrice(buyamount);
        require(
            fromUserPrice <= (fromUserPriceFromUI * 10100) / 10000,
            "Meland.Marketplace#autoBuy: The total price is not correct"
        );
        _buy(buyer, buyer, buyamount, tknRate);
    }

    function autoBuy(
        address buyer,
        address fundsProvider,
        uint256 buyamount,
        uint256 tknRate
    ) external onlyFactory {
        _buy(buyer, fundsProvider, buyamount, tknRate);
    }

    function _sell(
        address seller,
        uint256 sellFragments,
        uint256 tknRate
    ) internal {
        (
            uint256 toUserPrice,
            uint256 fragmentFees,
            uint256 erc20Fees
        ) = getSellPrice(sellFragments);
        require(
            erc20Reserve > toUserPrice,
            "Meland.Swap.ExchangePool20T1155#_sell: not initialized"
        );

        (uint256 erc20LPFees, uint256 erc20NetworkFees) = _splitFees(erc20Fees);
        (uint256 fragmentLPFees, uint256 fragmentNetworkFees) = _splitFees(
            fragmentFees
        );

        erc20token.transfer(seller, toUserPrice);
        erc20Reserve -= (toUserPrice + erc20NetworkFees);

        // Automatic compounding
        erc1155FragmentReserves =
            erc1155FragmentReserves +
            (sellFragments - fragmentNetworkFees);
        erc1155FragmentReservesActivated =
            erc1155FragmentReservesActivated +
            (sellFragments - fragmentFees);

        _activeNFTFragments(erc20LPFees);

        emit Sell(
            seller,
            sellFragments,
            toUserPrice,
            erc20LPFees,
            fragmentLPFees,
            tknRate
        );
    }

    function _buy(
        address buyer,
        address funsProvider,
        uint256 buyamount,
        uint256 tknRate
    ) internal {
        uint256 buyfragments = _toNFTFragments(buyamount);
        require(
            erc1155FragmentReservesActivated >= buyfragments,
            "Meland.Swap.ExchangePool20T1155#_buy: Insufficient balance"
        );
        (
            uint256 fromUserPrice,
            uint256 fragmentFees,
            uint256 erc20Fees
        ) = getBuyPrice(buyamount);
        (uint256 erc20LPFees, uint256 erc20NetworkFees) = _splitFees(erc20Fees);
        (uint256 fragmentLPFees, uint256 fragmentNetworkFees) = _splitFees(
            fragmentFees
        );
        erc20token.transferFrom(funsProvider, address(this), fromUserPrice);
        erc20Reserve = erc20Reserve + (fromUserPrice - erc20NetworkFees);

        erc1155token.safeTransferFrom(
            address(this),
            buyer,
            tokenId,
            buyamount,
            ""
        );
        erc1155FragmentReserves =
            erc1155FragmentReserves -
            (buyfragments + fragmentNetworkFees);
        erc1155FragmentReservesActivated =
            erc1155FragmentReservesActivated -
            (buyfragments + fragmentFees);

        _activeNFTFragments(erc20LPFees);

        emit Buy(
            buyer,
            buyfragments,
            fromUserPrice,
            erc20LPFees,
            fragmentLPFees,
            tknRate
        );
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

    bytes4 internal constant LIQUIDITY_SIG = bytes4(keccak256("_addERC1155Liquidity()"));
    bytes4 internal constant SELL_SIG = bytes4(keccak256("_sell(uint256)"));

    function onERC1155BatchReceived(
        address, // _operator,
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes calldata _data
    ) public override returns (bytes4) {
        // This function assumes that the ERC-1155 token contract can
        // only call `onERC1155BatchReceived()` via a valid token transfer.
        // Users must be responsible and only use this Niftyswap exchange
        // contract with ERC-1155 compliant token contracts.
        // Obtain method to call via object signature
        bytes4 functionSignature = bytes4(_data[:4]);
        require(
            functionSignature == LIQUIDITY_SIG || functionSignature == SELL_SIG,
            "Meland.MelandSwapExchangePool20T1155#onERC1155BatchReceived5: Invalid function signature"
        );
        require(
            _ids.length == 1,
            "Meland.MelandSwapExchangePool20T1155#onERC1155BatchReceived5: Invalid token ID"
        );
        uint256 id = _ids[0];
        require(
            id == tokenId,
            "Meland.MelandSwapExchangePool20T1155#onERC1155BatchReceived5: Invalid token ID"
        );
        require(_msgSender() == address(erc1155token), "Meland.MelandSwapExchangePool20T1155#onERC1155BatchReceived5: Invalid sender");
        if (functionSignature == LIQUIDITY_SIG) {
            _addERC1155Liquidity(_from, _amounts[0]);
        } else if (functionSignature == SELL_SIG) {
            uint256 tknRate;
            (tknRate) = abi.decode(
                _data[4:],
                (uint256)
            );
            _sell(_from, _toNFTFragments(_amounts[0]), tknRate);
        }
        return ERC1155_BATCH_RECEIVED_VALUE;
    }

    /**
     * @dev Will pass to onERC115Batch5Received
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bytes4) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = _id;
        amounts[0] = _amount;

        require(
            ERC1155_BATCH_RECEIVED_VALUE ==
                onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
            "Meland.MelandSwapExchangePool20T1155#onERC1155Received: INVALID_ONRECEIVED_MESSAGE"
        );

        return ERC1155_RECEIVED_VALUE;
    }
}
