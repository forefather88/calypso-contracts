// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Oracle.sol";
import "./Interfaces/IBurn.sol";

contract Lottery {
    using SafeMath for uint256;

    address public oracleAddress;
    uint256 private winNumber;
    uint256 public totalPrize;
    address public owner;
    bool public hasDrawn;
    uint256 public createdDate;
    uint256 public endDate;
    address[] public players;
    address public lotteryManagerAddress;
    bool private isRolledOver;

    //Make private after deploying on Mainnet--------------------
    //Result
    address[] public firstPrize;
    address[] public secondPrize;
    address[] public thirdPrize;
    address[] public match4;
    address[] public match3;
    address[] public match2;
    address[] public match1;

    // Prizes
    uint256 public firstPrizeTotal;
    uint256 public secondPrizeTotal;
    uint256 public thirdPrizeTotal;
    uint256 public match4Total;
    uint256 public match3Total;
    uint256 public match2Total;
    uint256 public match1Total;

    //-----------------------------------------

    // Tickets and prizes
    mapping(address => uint256[]) public userToTickets;
    address[] public usersClaimedPrize;
    uint256 public totalTickets;

    // Staking
    address[] public stakersAddresses;
    uint256[] public stakingAmounts;
    mapping(address => uint256) public stAddrsToIndex;
    address[] public usersClaimedStake;
    //If totalStaked > totalPrize, the pool becomes active
    uint256 public totalStaked;
    // We need this to calculate stake percent in unstake()
    uint256 public originalTotalStaked;

    modifier isCapReached() {
        require(totalStaked >= totalPrize, "Cap is not reached.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed2");
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
        endDate = createdDate.add(3600 * 4); // +2 Hours for testing
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

        IERC20(Oracle(oracleAddress).getCalAddress()).transfer(
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

    function startDraw() external isCapReached returns (bool) {
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
        require(
            block.timestamp < endDate,
            "Cannot purchase tickets after a lottery ends"
        );
        IERC20(Oracle(oracleAddress).getCalAddress()).transferFrom(
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
            block.timestamp < endDate,
            "Cannot purchase tickets after a lottery ends"
        );
        IERC20(Oracle(oracleAddress).getCalAddress()).transferFrom(
            msg.sender,
            address(this),
            _amount.mul(1000000000000000000) // 1 CAL
        );
        if (userToTickets[msg.sender].length == 0) {
            players.push(msg.sender);
        }

        for (uint256 i = 0; i < _amount; i++) {
            totalTickets = totalTickets.add(
                1000000000000000000 /* 1 CAL*/
            );
            if (_numbers.length == 0) {
                uint256 ticketNumber = random().add(10000000);
                userToTickets[msg.sender].push(ticketNumber);
            } else {
                userToTickets[msg.sender].push(_numbers[i].add(10000000));
            }
        }

        return true;
    }

    function stake(uint256 _amount) external returns (bool) {
        require(_amount > 0, "The amount to stake cannot be equal to 0.");
        IERC20(Oracle(oracleAddress).getCalAddress()).transferFrom(
            msg.sender,
            address(this),
            _amount.mul(1000000000000000000) // 1 CAL
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
        // First stake in a Lottery
        else {
            stakersAddresses.push(_addr);
            stakingAmounts.push(_amount);
            stAddrsToIndex[_addr] = stakersAddresses.length.sub(1);
        }
    }

    function getUsersStake(address _addr) private view returns (uint256) {
        return stakingAmounts[stAddrsToIndex[_addr]];
    }

    function unstake() external returns (bool) {
        require(hasDrawn, "Can not claim prize or unstake before draw.");
        require(hasClaimedStake(msg.sender) == false);
        require(!isRolledOver, "This lottery has already made rollover.");
        uint256 usersStake = getUsersStake(msg.sender);
        require(
            usersStake > 0,
            "This user haven't ever staked in this lottery."
        );
        // msg.senders percent of total stake
        uint256 percentStake = usersStake.mul(100).div(originalTotalStaked);
        if (totalStaked > 0) {
            uint256 usersStakeToReturn = totalStaked.mul(percentStake).div(100);
            usersStakeToReturn = usersStakeToReturn.mul(1000000000000000000); /* 1 CAL*/
            IERC20(Oracle(oracleAddress).getCalAddress()).transfer(
                msg.sender,
                usersStakeToReturn.add(totalTickets.mul(percentStake).div(100))
            );
        } else {
            IERC20(Oracle(oracleAddress).getCalAddress()).transfer(
                msg.sender,
                totalTickets.mul(percentStake).div(100)
            );
        }

        usersClaimedStake.push(msg.sender);
        return true;
    }

    function rolloverStakes(address _address) external onlyOwner {
        // require(block.timestamp >= endDate + 3600 * 6, "Cannot rollover yet.");
        require(hasDrawn, "Can not claim prize or unstake before draw.");
        require(!isRolledOver, "This lottery has already made rollover.");

        IERC20(Oracle(oracleAddress).getCalAddress()).transfer(
            _address,
            totalStaked.mul(1000000000000000000)
        );
        Lottery(_address).reciveRollover(
            totalStaked,
            stakersAddresses,
            stakingAmounts,
            usersClaimedStake
        );
        totalStaked = 0;
        isRolledOver = true;
    }

    function reciveRollover(
        uint256 _totalStaked,
        address[] memory _stakersAddresses,
        uint256[] memory _stakingAmounts,
        address[] memory _usersClaimedStake
    ) external {
        totalStaked = totalStaked.add(_totalStaked);
        originalTotalStaked = originalTotalStaked.add(_totalStaked);
        for (uint256 i = 0; i < _stakersAddresses.length; i++) {
            bool hasClaimed = false;
            for (uint256 j = 0; j < _usersClaimedStake.length; j++) {
                if (_usersClaimedStake[j] == _stakersAddresses[i]) {
                    hasClaimed = true;
                }
            }
            if (!hasClaimed) {
                placeStake(_stakersAddresses[i], _stakingAmounts[i]);
            }
        }
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
            uint256[] memory _stakingAmounts,
            uint256 _winNumber
        )
    {
        _usersClaimedPrize = usersClaimedPrize;
        _usersClaimedStake = usersClaimedStake;
        _stakersAddresses = stakersAddresses;
        _stakingAmounts = stakingAmounts;
        _winNumber = hasDrawn ? winNumber.mod(10000000) : 0;
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

    function hasClaimedStake(address addr) internal view returns (bool) {
        for (uint256 index = 0; index < usersClaimedStake.length; index++) {
            if (usersClaimedPrize[index] == addr) {
                return true;
            }
        }
        return false;
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

    function changeOracleAddress(address _address) external {
        oracleAddress = _address;
    }

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
