// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";

contract Lottery {
    using SafeMath for uint256;

    address owner;
    bool public hasDrawn;
    uint256 public winNumber;
    uint256 public createdDate;
    uint256 public endDate;
    //If liquidityPool > 2M CAL, the pool becomes active
    uint256 public liquidityPool;
    address[] public players;
    uint256 totalPrize;

    //Result
    address[] public firstPrize;
    address[] public secondPrize;
    address[] public thirdPrize;
    address[] public match4;
    address[] public match3;
    address[] public match2;
    address[] public match1;

    // Tickets and prizes
    mapping(address => uint256[]) public userToTickets;
    mapping(address => uint256) public userToTicketAmount;
    mapping(address => bool) public userToHasClaimedPrize;

    // Staking
    mapping(address => bool) public userToHasClaimedStake;
    mapping(address => uint256) public userToStake;
    uint256 stakersAmount;
    uint256 totalStaked;
    uint256 stakersFee;

    modifier isCapReached() {
        require(liquidityPool >= 2000000, "2M CAL cap is not reached.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    modifier onlyEndDate() {
        require(block.timestamp >= endDate, "End date is not reached");
        _;
    }

    constructor(address _owner, uint256 _winNumber) {
        owner = _owner;
        winNumber = _winNumber;
        createdDate = block.timestamp;
        endDate = createdDate; // + 7200; // +2 Hours for testing
        hasDrawn = false;
        totalPrize = 2000000;
    }

    function claimPrize() external view returns (uint256) {
        require(hasDrawn, "Can not claim prize or unstake before draw.");
        require(userToHasClaimedPrize[msg.sender] == false);
        uint256 amount;
        // 40%
        if (firstPrize.length > 0)
            amount = amount.add(
                calcPrizeAmount(firstPrize, totalPrize.mul(40).div(100))
            );
        // 25%
        if (secondPrize.length > 0)
            amount = amount.add(
                calcPrizeAmount(secondPrize, totalPrize.mul(25).div(100))
            );
        // 15%
        if (thirdPrize.length > 0)
            amount = amount.add(
                calcPrizeAmount(thirdPrize, totalPrize.mul(15).div(100))
            );
        // 10%
        if (match4.length > 0)
            amount = amount.add(
                calcPrizeAmount(match4, totalPrize.mul(10).div(100))
            );
        // 5%
        if (match3.length > 0)
            amount = amount.add(
                calcPrizeAmount(match3, totalPrize.mul(5).div(100))
            );
        // 3%
        if (match2.length > 0)
            amount = amount.add(
                calcPrizeAmount(match2, totalPrize.mul(3).div(100))
            );
        // 2%
        if (match1.length > 0)
            amount = amount.add(
                calcPrizeAmount(match1, totalPrize.mul(2).div(100))
            );

        //Remove after testing
        //userToHasClaimedPrize[msg.sender] = true;

        return amount;
    }

    function calcPrizeAmount(address[] memory prizeAddresses, uint256 total)
        private
        view
        returns (uint256)
    {
        uint256 winTicketsAmount;
        for (uint256 index = 0; index < prizeAddresses.length; index++) {
            if (prizeAddresses[index] == msg.sender) {
                winTicketsAmount = winTicketsAmount.add(1);
            }
        }

        return (winTicketsAmount * total) / prizeAddresses.length;
    }

    function startDraw()
        external
        isCapReached
        onlyEndDate
        onlyOwner
        returns (bool)
    {
        require(!hasDrawn, "Can not draw twice in the same lottery.");
        // Defining winnin tickets
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            for (uint256 j = 0; j < userToTickets[player].length; j++) {
                uint256 userNumber = userToTickets[player][j];
                if (userNumber == winNumber) {
                    firstPrize.push(player);
                } else if (userNumber / 10 == winNumber / 10) {
                    secondPrize.push(player);
                } else if (userNumber / 100 == winNumber / 100) {
                    thirdPrize.push(player);
                } else if (userNumber / 1000 == winNumber / 1000) {
                    match4.push(player);
                } else if (userNumber / 10000 == winNumber / 10000) {
                    match3.push(player);
                } else if (
                    userNumber / 100000 == winNumber / 100000 ||
                    userNumber % 100 == winNumber % 100
                ) {
                    match2.push(player);
                    if (
                        userNumber / 100000 == winNumber / 100000 &&
                        userNumber % 100 == winNumber % 100
                    ) {
                        match2.push(player);
                    }
                } else if (
                    userNumber / 1000000 == winNumber / 1000000 ||
                    userNumber % 10 == winNumber % 10
                ) {
                    match1.push(player);
                    if (
                        userNumber / 1000000 == winNumber / 1000000 &&
                        userNumber % 10 == winNumber % 10
                    ) {
                        match1.push(player);
                    }
                }
            }
        }

        stakersFee = totalPrize.mul(3).div(100);
        if (stakersFee > 0) totalPrize = totalPrize.sub(stakersFee);

        hasDrawn = true;
        return true;
    }

    function getTicket(uint256 _ticket) external returns (bool) {
        if (userToTickets[msg.sender].length == 0) {
            players.push(msg.sender);
        }
        userToTickets[msg.sender].push(_ticket);
        userToTicketAmount[msg.sender] = userToTicketAmount[msg.sender].add(1);
        liquidityPool = liquidityPool.add(1);

        return true;
    }

    function stake(uint256 _amount) external returns (bool) {
        require(_amount > 0, "The amount to stake cannot be equal to 0.");
        liquidityPool = liquidityPool.add(_amount);
        totalStaked = totalStaked.add(_amount);
        userToStake[msg.sender] = userToStake[msg.sender].add(_amount);
        stakersAmount = stakersAmount.add(1);
        return true;
    }

    function unstake() external view returns (uint256) {
        require(hasDrawn, "Can not claim prize or unstake before draw.");
        uint256 usersStake = userToStake[msg.sender];
        // msg.senders percent of total stake
        uint256 percentStake = usersStake.mul(100).div(totalStaked);
        // Uncomment after testing
        //userToHasClaimedStake[msg.sender] = true;

        return usersStake.add(stakersFee.mul(percentStake).div(100));
    }

    //Remove on PROD:
    function changeEndDate(uint256 _newDate) external {
        endDate = _newDate;
    }
}
