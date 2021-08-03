// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/Initializable.sol";
import "./Lottery.sol";

contract LotteryManager is Initializable {
    using SafeMath for uint256;

    address[] public lotteries;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
    }

    function createLottery(uint256 _winNumber)
        external
        onlyOwner
        returns (address)
    {
        Lottery lottery = new Lottery(msg.sender, _winNumber);
        lotteries.push(address(lottery));
        return address(lottery);
    }
}
