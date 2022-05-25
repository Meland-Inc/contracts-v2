// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "../common/IMelandAccessRoles.sol";

// Cross-chain NFT of Meland subchains.
// Implemented to allow NFTs from the Meland subchain to circulate and be traded on the public chain.
// Allowing a part of contracts, marketplace, AMM exchange to construct it based on user's signature and meland mpc's signature.
// Then when the user buys it, it is charged to the Meland subchain
interface IMelandChainERC1155CID is IERC165Upgradeable, IMelandAccessRoles {
    struct SwapinParams {
        address to;
        uint256 cid;
        uint256 value;
        bytes data;
    }

    // Converting NFT to Meland Private Chain.
    event SwapoutWithCID(address indexed to, uint256 cid, uint256 value);

    event SwapinWithCID(
        bytes32 indexed signKeccak256,
        address to,
        uint256 cid,
        uint256 value
    );

    // If something goes wrong in the mint process, an event is raised to have the subchain refunded
    event RefundSwapin(
        bytes32 indexed signKeccak256
    );

    function callSwapoutWithCID(
        address to,
        uint256 cid,
        uint256 value
    ) external;

    function callSwapinWithCID(
        MPCPermit memory signature,
        SwapinParams memory swapinparams
    ) external;
}
