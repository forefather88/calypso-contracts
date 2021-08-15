// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";

contract Lottery {
    using SafeMath for uint256;

    uint256 public winNumber;
    uint256 public totalPrize;
    address public owner;
    bool public hasDrawn;
    uint256 public createdDate;
    uint256 public endDate;
    address[] public players;
    address public lotteryManagerAddress;

    //Result
    address[] public firstPrize;
    address[] public secondPrize;
    address[] public thirdPrize;
    address[] public match4;
    address[] public match3;
    address[] public match2;
    address[] public match1;

    // Prizes
    uint256 private firstPrizeTotal;
    uint256 private secondPrizeTotal;
    uint256 private thirdPrizeTotal;
    uint256 private match4Total;
    uint256 private match3Total;
    uint256 private match2Total;
    uint256 private match1Total;

    // Tickets and prizes
    mapping(address => uint256[]) public userToTickets;
    address[] public usersClaimedPrize;
    uint256 public totalTickets;

    // Staking
    address[] public stakersAddresses;
    uint256[] public stakingAmounts;
    mapping(address => uint256) public stAddrsToIndex;
    address[] public usersClaimedStake;
    //If totalStaked > 2M CAL, the pool becomes active
    uint256 public totalStaked;
    // We need this to calculate stake percent in unstake()
    uint256 public originalTotalStaked;

    modifier isCapReached() {
        require(totalStaked >= totalPrize, "2M CAL cap is not reached.");
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

    constructor(
        address _owner,
        uint256 _winNumber,
        address _lotteryManagerAddress,
        uint256 _totalPrize
    ) {
        owner = _owner;
        winNumber = _winNumber;
        lotteryManagerAddress = _lotteryManagerAddress;
        createdDate = block.timestamp;
        endDate = createdDate.add(7200); // +2 Hours for testing
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

        IERC20(0x36DF4070E048A752C5abD7eFD22178ce8ef92535).transfer(
            msg.sender,
            amount * 1000000000000000000 // 1 CAL
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

    function startDraw()
        external
        isCapReached
        onlyEndDate
        onlyOwner
        returns (bool)
    {
        require(!hasDrawn, "Can not draw twice in the same lottery.");
        // Defining winning tickets
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            for (uint256 j = 0; j < userToTickets[player].length; j++) {
                uint256 userNumber = userToTickets[player][j];
                if (userNumber == winNumber) {
                    if (firstPrize.length == 0) {
                        totalStaked = totalStaked.sub(firstPrizeTotal);
                    }
                    firstPrize.push(player);
                } else if (userNumber.div(10) == winNumber.div(10)) {
                    if (secondPrize.length == 0) {
                        totalStaked = totalStaked.sub(secondPrizeTotal);
                    }
                    secondPrize.push(player);
                } else if (userNumber.div(100) == winNumber.div(100)) {
                    if (thirdPrize.length == 0) {
                        totalStaked = totalStaked.sub(thirdPrizeTotal);
                    }
                    thirdPrize.push(player);
                } else if (userNumber.div(1000) == winNumber.div(1000)) {
                    if (match4.length == 0) {
                        totalStaked = totalStaked.sub(match4Total);
                    }
                    match4.push(player);
                } else if (userNumber.div(10000) == winNumber.div(10000)) {
                    if (match3.length == 0) {
                        totalStaked = totalStaked.sub(match3Total);
                    }
                    match3.push(player);
                } else if (
                    userNumber.div(100000) == winNumber.div(100000) ||
                    userNumber % 100 == winNumber % 100
                ) {
                    if (match2.length == 0) {
                        totalStaked = totalStaked.sub(match2Total);
                    }
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
                    if (match1.length == 0) {
                        totalStaked = totalStaked.sub(match1Total);
                    }
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
        // 5%
        if (totalStaked > 0) {
            uint256 stakersFee = totalTickets.mul(5).div(100);
            if (stakersFee > 0) totalTickets = totalTickets.sub(stakersFee);
        }
        hasDrawn = true;
        return true;
    }

    function getTicket(uint256 _ticketNumber) external returns (bool) {
        IERC20(0x36DF4070E048A752C5abD7eFD22178ce8ef92535).transferFrom(
            msg.sender,
            address(this),
            1000000000000000000 // 1 CAL
        );
        if (userToTickets[msg.sender].length == 0) {
            players.push(msg.sender);
        }
        userToTickets[msg.sender].push(_ticketNumber.add(10000000));
        totalTickets = totalTickets.add(
            1000000000000000000 /* 1 CAL*/
        );

        return true;
    }

    function getTicketBatch(uint256 _amount) external returns (bool) {
        IERC20(0x36DF4070E048A752C5abD7eFD22178ce8ef92535).transferFrom(
            msg.sender,
            address(this),
            _amount * 1000000000000000000 // 1 CAL
        );
        if (userToTickets[msg.sender].length == 0) {
            players.push(msg.sender);
        }

        for (uint256 i = 0; i < _amount; i++) {
            totalTickets = totalTickets.add(
                1000000000000000000 /* 1 CAL*/
            );
            uint256 ticketNumber = random().add(10000000);
            userToTickets[msg.sender].push(ticketNumber);
        }

        return true;
    }

    function stake(uint256 _amount) external returns (bool) {
        require(_amount > 0, "The amount to stake cannot be equal to 0.");
        IERC20(0x36DF4070E048A752C5abD7eFD22178ce8ef92535).transferFrom(
            msg.sender,
            address(this),
            _amount * 1000000000000000000 // 1 CAL
        );
        totalStaked = totalStaked.add(_amount);
        originalTotalStaked = originalTotalStaked.add(_amount);
        placeStake(msg.sender, _amount);
        return true;
    }

    function placeStake(address _addr, uint256 _amount) private {
        if (stakersAddresses.length > 0) {
            uint256 index = stAddrsToIndex[_addr];
            uint256 usersStake = stakingAmounts[index];
            if (usersStake > 0) {
                stakingAmounts[index] = stakingAmounts[index].add(_amount);
            } else {
                stakersAddresses.push(_addr);
                stakingAmounts.push(_amount);
                stAddrsToIndex[_addr] = stakersAddresses.length.sub(1);
            }
        }
        // First bet in a Lottery
        else {
            stakersAddresses.push(_addr);
            stakingAmounts.push(_amount);
            stAddrsToIndex[_addr] = stakersAddresses.length.sub(1);
        }
    }

    // Make Private after testing
    function getUsersStake(address _addr) public view returns (uint256) {
        return stakingAmounts[stAddrsToIndex[_addr]];
    }

    function unstake() external returns (bool) {
        require(hasDrawn, "Can not claim prize or unstake before draw.");
        require(hasClaimedStake(msg.sender) == false);
        uint256 usersStake = getUsersStake(msg.sender);
        require(
            usersStake > 0,
            "This user haven't ever staked in this lottery."
        );
        // msg.senders percent of total stake
        uint256 percentStake = usersStake.mul(100).div(originalTotalStaked);
        if (totalStaked > 0) {
            uint256 usersStakeToReturn = totalStaked.mul(percentStake).div(100);
            usersStakeToReturn = usersStakeToReturn * 1000000000000000000; /* 1 CAL*/
            IERC20(0x36DF4070E048A752C5abD7eFD22178ce8ef92535).transfer(
                msg.sender,
                usersStakeToReturn.add(totalTickets.mul(percentStake).div(100))
            );
        } else {
            IERC20(0x36DF4070E048A752C5abD7eFD22178ce8ef92535).transfer(
                msg.sender,
                totalTickets.mul(percentStake).div(100)
            );
        }

        usersClaimedStake.push(msg.sender);
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
            uint256 _originalTotalStaked,
            uint256 _playersAmount,
            uint256 _totalPrize,
            uint256 _totalStaked
        )
    {
        _address = address(this);
        _owner = owner;
        _hasDrawn = hasDrawn;
        _createdDate = createdDate;
        _endDate = endDate;
        _lotteryManagerAddress = lotteryManagerAddress;
        _totalTickets = totalTickets;
        _originalTotalStaked = originalTotalStaked;
        _playersAmount = players.length;
        _totalPrize = totalPrize;
        _totalStaked = totalStaked;
    }

    function getLotteryDetail2()
        external
        view
        returns (
            address[] memory _usersClaimedPrize,
            address[] memory _usersClaimedStake,
            address[] memory _stakersAddresses,
            uint256[] memory _stakingAmounts
        )
    {
        _usersClaimedPrize = usersClaimedPrize;
        _usersClaimedStake = usersClaimedStake;
        _stakersAddresses = stakersAddresses;
        _stakingAmounts = stakingAmounts;
    }

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

    function hasClaimedPrize(address addr) internal view returns (bool) {
        for (uint256 index = 0; index < usersClaimedPrize.length; index++) {
            if (usersClaimedPrize[index] == addr) {
                return true;
            }
        }
        return false;
    }

    function hasClaimedStake(address addr) internal view returns (bool) {
        for (uint256 index = 0; index < usersClaimedStake.length; index++) {
            if (usersClaimedPrize[index] == addr) {
                return true;
            }
        }
        return false;
    }

    function getWinumber() external view returns (uint256 _winNumber) {
        require(
            hasDrawn,
            "Winning number can be visible only after Lottery draws."
        );
        _winNumber = winNumber.mod(10000000);
    }

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

    //Remove on PROD:
    function changeEndDate(uint256 _newDate) external {
        endDate = _newDate;
    }
}
