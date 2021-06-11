// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

struct Bet {
    string id;
    address bettor;
    uint8 side;
    uint256 amount;
    uint256 createdDate;
}
