// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMelandAccessRoles {
    struct MPCPermit {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
