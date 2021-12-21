// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Oracle.sol";
import "./Interfaces/IBurn.sol";

contract Lottery {
    using SafeMath for uint256;

    address public oracleAddress;
    //The winning number of a lottery
    uint256 private winNumber;
    //Total prize of a lottery
    uint256 public totalPrize;
    address public owner;
    //Was a lottery drawn
    bool public hasDrawn;
    uint256 public createdDate;
    uint256 public endDate;
    //Addresses of players of a lottery. Player is a user that has bought at least one ticket
    address[] public players;
    address public lotteryManagerAddress;

    //Make private before deploying on Mainnet
    //Result
    //Addresses of each part of the total prize, if the address in an array this address can claim its reward
    address[] public firstPrize;
    address[] public secondPrize;
    address[] public thirdPrize;
    address[] public match4;
    address[] public match3;
    address[] public match2;
    address[] public match1;

    //Pool size at the time the lottery was drawn
    uint256 poolSize;

    //Make private before deploying on Mainnet
    // Prizes
    //Total amount of cal to win for each prize
    uint256 public totalWin;
    uint256 public firstPrizeTotal;
    uint256 public secondPrizeTotal;
    uint256 public thirdPrizeTotal;
    uint256 public match4Total;
    uint256 public match3Total;
    uint256 public match2Total;
    uint256 public match1Total;

    // Tickets and prizes
    mapping(address => uint256[]) public userToTickets; //Tickets of a user
    address[] public usersClaimedPrize; //Tickets of a users that have claimed their prize
    uint256 public totalTickets; //Total amount of tickets purchased in a lottery

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    modifier onlyEndDate() {
        require(block.timestamp >= endDate, "End date is not reached");
        _;
    }

    constructor(
        address _owner,
        uint256 _winNumber,
        address _lotteryManagerAddress,
        uint256 _totalPrize
    ) {
        oracleAddress = 0xfFB0E212B568133fEf49d60f8d52b4aE4A2fdB72;
        owner = _owner;
        winNumber = _winNumber;
        lotteryManagerAddress = _lotteryManagerAddress;
        createdDate = block.timestamp;
        endDate = createdDate.add(3600 * 24);
        hasDrawn = false;
        totalPrize = _totalPrize;
        firstPrizeTotal = totalPrize.mul(40).div(100);
        secondPrizeTotal = totalPrize.mul(25).div(100);
        thirdPrizeTotal = totalPrize.mul(15).div(100);
        match4Total = totalPrize.mul(10).div(100);
        match3Total = totalPrize.mul(5).div(100);
        match2Total = totalPrize.mul(3).div(100);
        match1Total = totalPrize.mul(2).div(100);
    }

    function claimPrize() external returns (bool) {
        require(hasDrawn, "Can not claim prize or unstake before draw.");
        require(hasClaimedPrize(msg.sender) == false);
        uint256 amount;
        // 40%
        if (firstPrize.length > 0)
            amount = amount.add(calcPrizeAmount(firstPrize, firstPrizeTotal));
        // 25%
        if (secondPrize.length > 0)
            amount = amount.add(calcPrizeAmount(secondPrize, secondPrizeTotal));
        // 15%
        if (thirdPrize.length > 0)
            amount = amount.add(calcPrizeAmount(thirdPrize, thirdPrizeTotal));
        // 10%
        if (match4.length > 0)
            amount = amount.add(calcPrizeAmount(match4, match4Total));
        // 5%
        if (match3.length > 0)
            amount = amount.add(calcPrizeAmount(match3, match3Total));
        // 3%
        if (match2.length > 0)
            amount = amount.add(calcPrizeAmount(match2, match2Total));
        // 2%
        if (match1.length > 0)
            amount = amount.add(calcPrizeAmount(match1, match1Total));

        IERC20(Oracle(oracleAddress).getCalAddress()).transferFrom(
            lotteryManagerAddress,
            msg.sender,
            amount.mul(1000000000000000000) // 1 CAL
        );

        usersClaimedPrize.push(msg.sender);

        return true;
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

    function startDraw(uint256 _poolSize) external returns (bool) {
        require(
            msg.sender == lotteryManagerAddress,
            "Only Lottery Manager SC can start draw"
        );
        require(!hasDrawn, "Can not draw twice in the same lottery.");

        // Defining winning tickets
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            for (uint256 j = 0; j < userToTickets[player].length; j++) {
                uint256 userNumber = userToTickets[player][j];
                if (userNumber == winNumber) {
                    if (firstPrize.length == 0)
                        totalWin = totalWin.add(firstPrizeTotal);

                    firstPrize.push(player);
                } else if (userNumber.div(10) == winNumber.div(10)) {
                    if (secondPrize.length == 0)
                        totalWin = totalWin.add(secondPrizeTotal);

                    secondPrize.push(player);
                } else if (userNumber.div(100) == winNumber.div(100)) {
                    if (thirdPrize.length == 0)
                        totalWin = totalWin.add(thirdPrizeTotal);

                    thirdPrize.push(player);
                } else if (userNumber.div(1000) == winNumber.div(1000)) {
                    if (match4.length == 0)
                        totalWin = totalWin.add(match4Total);

                    match4.push(player);
                } else if (userNumber.div(10000) == winNumber.div(10000)) {
                    if (match3.length == 0)
                        totalWin = totalWin.add(match3Total);

                    match3.push(player);
                } else if (
                    userNumber.div(100000) == winNumber.div(100000) ||
                    userNumber % 100 == winNumber % 100
                ) {
                    if (match2.length == 0)
                        totalWin = totalWin.add(match2Total);
                    match2.push(player);
                    if (
                        userNumber.div(100000) == winNumber.div(100000) &&
                        userNumber % 100 == winNumber % 100
                    ) {
                        match2.push(player);
                    }
                } else if (
                    userNumber.div(1000000) == winNumber.div(1000000) ||
                    userNumber % 10 == winNumber % 10
                ) {
                    if (match1.length == 0)
                        totalWin = totalWin.add(match1Total);
                    match1.push(player);
                    if (
                        userNumber.div(1000000) == winNumber.div(1000000) &&
                        userNumber % 10 == winNumber % 10
                    ) {
                        match1.push(player);
                    }
                }
            }
        }

        poolSize = _poolSize;
        hasDrawn = true;
        return true;
    }

    //Purchasing tickets by a user
    function getTicketBatch(uint256 _amount, uint256[] memory _numbers)
        external
        returns (bool)
    {
        if (_numbers.length != 0) {
            require(
                _amount == _numbers.length,
                "Enter correct amount of ticket numbers"
            );
        }
        require(
            block.timestamp < endDate - 3600,
            "Cannot purchase tickets after a lottery ends"
        );
        IERC20(Oracle(oracleAddress).getCalAddress()).transferFrom(
            msg.sender,
            lotteryManagerAddress,
            _amount.mul(1000000000000000000) // 1 CAL
        );
        if (userToTickets[msg.sender].length == 0) {
            players.push(msg.sender);
        }

        for (uint256 i = 0; i < _amount; i++) {
            totalTickets = totalTickets.add(1);
            if (_numbers.length == 0) {
                uint256 ticketNumber = random().add(10000000);
                userToTickets[msg.sender].push(ticketNumber);
            } else {
                userToTickets[msg.sender].push(_numbers[i].add(10000000));
            }
        }

        return true;
    }

    function getLotteryDetail()
        external
        view
        returns (
            address _address,
            address _owner,
            bool _hasDrawn,
            uint256 _createdDate,
            uint256 _endDate,
            address _lotteryManagerAddress,
            uint256 _totalTickets,
            uint256 _playersAmount,
            uint256 _totalPrize,
            uint256 _poolSize
        )
    {
        _address = address(this);
        _owner = owner;
        _hasDrawn = hasDrawn;
        _createdDate = createdDate;
        _endDate = endDate;
        _lotteryManagerAddress = lotteryManagerAddress;
        _totalTickets = totalTickets;
        _playersAmount = players.length;
        _totalPrize = totalPrize;
        _poolSize = poolSize;
    }

    function getLotteryDetail2()
        external
        view
        returns (address[] memory _usersClaimedPrize, uint256 _winNumber)
    {
        _usersClaimedPrize = usersClaimedPrize;
        _winNumber = hasDrawn ? winNumber.mod(10000000) : 0;
    }

    //Returns winners' addresses for each prize
    function getWinners()
        external
        view
        returns (
            address[] memory _firstPrize,
            address[] memory _secondPrize,
            address[] memory _thirdPrize,
            address[] memory _match4,
            address[] memory _match3,
            address[] memory _match2,
            address[] memory _match1
        )
    {
        _firstPrize = firstPrize;
        _secondPrize = secondPrize;
        _thirdPrize = thirdPrize;
        _match4 = match4;
        _match3 = match3;
        _match2 = match2;
        _match1 = match1;
    }

    function getTicketsOfPlayer()
        external
        view
        returns (uint256[] memory _tickets)
    {
        _tickets = userToTickets[msg.sender];
    }

    function hasClaimedPrize(address addr) internal view returns (bool) {
        for (uint256 index = 0; index < usersClaimedPrize.length; index++) {
            if (usersClaimedPrize[index] == addr) {
                return true;
            }
        }
        return false;
    }

    //Generates random number for a ticket (user can also choose to input numbers manually)
    function random() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        totalTickets
                    )
                )
            ).mod(10000000);
    }

    function changeOracleAddress(address _address) external {
        oracleAddress = _address;
    }

    // We are planning to burn all prizes in case they were not claimed after a lottery was drawn
    function burnPrizes() external onlyOwner {
        require(
            block.timestamp >= endDate + 3600 * 24 * 30,
            "You can burn prizes only 30 days after draw"
        );
        uint256 totalToBurn = firstPrizeTotal
            .add(secondPrizeTotal)
            .add(thirdPrizeTotal)
            .add(match4Total)
            .add(match3Total)
            .add(match2Total)
            .add(match1Total);
        IBurn(Oracle(oracleAddress).getCalAddress()).burn(
            totalToBurn.mul(1000000000000000000)
        );
    }

    //Remove on PROD:
    function changeEndDate(uint256 _newDate) external {
        endDate = _newDate;
    }
}

//Using this interface so we do not have to deploy LotteryManager code in Lottery SC
interface IShareReward {
    function shareStakingReward(uint256 _value) external returns (bool);
}
