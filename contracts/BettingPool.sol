// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Bet.sol";
import "./PoolManager.sol";
import "./Escrow.sol";
import "./Affiliate.sol";

contract BettingPool {
    using SafeMath for uint256;

    uint256 constant WAIT_TIME_FOR_RESULT = 5 * 60 * 60; // after 5 hours users can withdraw without fee

    // Initialize
    address public owner;
    string public title;
    string public description;
    uint256 public gameId;
    string public gameType; //epl, lol, dota 2, pubg
    uint256 public depositedCal;
    uint256 public maxCap;
    uint256 public poolFee; // * 10000
    uint256 public endDate;
    uint256 public createdDate;
    address public currency;
    PoolManager public poolManager;
    bool public isPrivate;
    address[] public whitelist;
    mapping(address => uint256) whitelistIndexes;
    uint256 public minBet;

    // Progress
    uint256 public total;
    Bet[] private bets;
    address[] betUsers; // list bet user
    mapping(string => uint256) private betIdToIndex;
    mapping(address => string[]) private userBetIds;
    mapping(address => mapping(uint8 => uint256)) private userSideBet; // user -> side -> bet amount
    mapping(address => uint256) userBet; // user -> bet amount (use for affiliates, withdraw without result)
    mapping(uint8 => uint256) public sideTotals; // side -> total bet

    // Result
    uint8 public result; //0: not yet, 1: team1, 2: team2, 3: draw
    uint256 public winTotal;
    uint256 public winOutcome;
    uint256 public poolFeeAmount;
    uint256 public platformFeeAmount;
    address[] affiliates;
    uint256[] awards;

    // Post Result
    mapping(address => uint256) public claimedAmount; // user -> claim amount
    mapping(address => bool) public claimedUser; // user -> claimed?
    bool claimedDepositAndFee;
    bool claimedPlatformFee;

    constructor(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _gameId,
        string memory _gameType,
        uint256 _endDate,
        address _currency,
        uint256 _poolFee,
        uint256 _depositedCal,
        address[] memory _whitelist,
        uint256 _minBet
    ) {
        owner = _owner;
        title = _title;
        description = _description;
        gameId = _gameId;
        gameType = _gameType;
        endDate = _endDate;
        currency = _currency;
        poolFee = _poolFee;
        createdDate = block.timestamp;
        result = 0;
        minBet = _minBet;
        poolManager = PoolManager(msg.sender);
        depositedCal = _depositedCal;
        maxCap = poolManager.getMaxCap(_depositedCal, _currency);
        if (_whitelist.length > 0) {
            isPrivate = true;
            for (uint256 i = 0; i < _whitelist.length; i++) {
                address _addr = _whitelist[i];
                whitelistIndexes[_addr] = whitelist.length;
                whitelist.push(_addr);
            }
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    modifier onlyEndDate() {
        require(block.timestamp >= endDate, "End date is not reached");
        _;
    }

    modifier onlyHasResult() {
        require(result > 0, "Result was not set");
        _;
    }

    modifier onlyBeforeEndDate() {
        require(block.timestamp < endDate, "Only before End date");
        _;
    }

    function getBetAmount(uint8 _side) external view returns (uint256) {
        return userSideBet[msg.sender][_side];
    }

    function addMaxCap(uint256 _depositedCal) public onlyOwner returns (bool) {
        require(_depositedCal > 0);
        depositedCal = depositedCal.add(_depositedCal);
        maxCap = poolManager.getMaxCap(depositedCal, currency);
        IERC20(poolManager.getCalAddress()).transferFrom(
            msg.sender,
            address(this),
            _depositedCal
        );
        return true;
    }

    function getPoolDetail()
        external
        view
        returns (
            string memory _title,
            string memory _description,
            uint256 _gameId,
            string memory _gameType,
            uint256 _endDate,
            address _currency,
            uint256 _poolFee,
            uint256 _depositedCal,
            uint256 _maxCap,
            address _owner,
            bool _isPrivate
        )
    {
        _title = title;
        _description = description;
        _gameId = gameId;
        _gameType = gameType;
        _endDate = endDate;
        _currency = currency;
        _poolFee = poolFee;
        _maxCap = maxCap;
        _owner = owner;
        _isPrivate = isPrivate;
        _depositedCal = depositedCal;
    }

    function getPoolDetail2()
        external
        view
        returns (
            uint8 _result,
            uint256 _total,
            uint256 _winOutcome,
            uint256 _winTotal,
            uint256 _poolFeeAmount,
            address[] memory _betUsers,
            uint256 _createdDate,
            address[] memory _whitelist,
            bool _claimedDepositAndFee,
            uint256 _minBet
        )
    {
        _result = result;
        _total = total;
        _winOutcome = winOutcome;
        _winTotal = winTotal;
        _poolFeeAmount = poolFeeAmount;
        _betUsers = betUsers;
        _createdDate = createdDate;
        _whitelist = whitelist;
        _claimedDepositAndFee = claimedDepositAndFee;
        _minBet = minBet;
    }

    function getUserInfo()
        external
        view
        returns (uint256 _reward, bool _claimed)
    {
        _reward = claimedAmount[msg.sender];
        _claimed = claimedUser[msg.sender];
    }

    function isWhiteList(address _addr) public view returns (bool) {
        return whitelist[whitelistIndexes[_addr]] == _addr;
    }

    function betWithEth(uint8 _side, string memory _id)
        external
        payable
        onlyBeforeEndDate
        returns (string memory)
    {
        require(currency == address(0), "The pool is using another currency");
        return placeBet(msg.sender, _side, msg.value, _id);
    }

    function betWithToken(
        uint8 _side,
        uint256 _amount,
        string memory _id
    ) external onlyBeforeEndDate returns (string memory) {
        require(currency != address(0), "This pool is using ETH");
        require(
            IERC20(currency).transferFrom(msg.sender, address(this), _amount),
            "Can not deposit tokens"
        );
        return placeBet(msg.sender, _side, _amount, _id);
    }

    function placeBet(
        address _bettor,
        uint8 _side,
        uint256 _amount,
        string memory _id
    ) internal returns (string memory) {
        require(
            _amount >= minBet,
            "Betting amount should be equal or higher than minimum bet"
        );
        total = total.add(_amount);
        require(total <= maxCap, "Maxcap was hit");
        if (isPrivate) {
            require(isWhiteList(msg.sender));
        }
        if (userBet[_bettor] == 0) {
            betUsers.push(_bettor);
        }
        uint256 timestamp = block.timestamp;
        string memory id = _id;
        bets.push(Bet(id, _bettor, _side, _amount, timestamp));
        userBetIds[_bettor].push(id);
        betIdToIndex[id] = bets.length.sub(1);
        userSideBet[_bettor][_side] = userSideBet[_bettor][_side].add(_amount);
        userBet[_bettor] = userBet[_bettor].add(_amount);
        sideTotals[_side] = sideTotals[_side].add(_amount);
        return id;
    }

    function getBetIdsOf() external view returns (string[] memory _betIds) {
        _betIds = userBetIds[msg.sender];
    }

    function getBet(string memory _betId)
        external
        view
        returns (
            string memory betId,
            address _bettor,
            uint8 _side,
            uint256 _amount,
            uint256 _createdDate
        )
    {
        Bet memory bet = bets[betIdToIndex[_betId]];
        betId = _betId;
        _bettor = bet.bettor;
        _side = bet.side;
        _amount = bet.amount;
        _createdDate = bet.createdDate;
    }

    function addWhitelistAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0) && !isWhiteList(_newAddress));
        whitelistIndexes[_newAddress] = whitelist.length;
        whitelist.push(_newAddress);
    }

    function removeWhitelistAddress(address _oldAddress) external onlyOwner {
        require(_oldAddress != address(0) && isWhiteList(_oldAddress));
        uint256 index = whitelistIndexes[_oldAddress];
        uint256 lastIndex = whitelist.length - 1;
        whitelist[index] = whitelist[lastIndex];
        delete whitelist[lastIndex];
        whitelistIndexes[_oldAddress] = 0;
    }

    function setResult(uint8 _sideWin) external onlyEndDate returns (bool) {
        require(poolManager.getOperatorAddress() == msg.sender);
        require(_sideWin > 0);
        result = _sideWin;
        if (total > 0) {
            winTotal = sideTotals[result];
            // If there are no winners in the pool the pool creator gets all the bets
            if (winTotal == 0) {
                platformFeeAmount = total.mul(poolManager.getPlatformFee()).div(
                    10000
                );
                winOutcome = total.sub(platformFeeAmount);
            }
            //If there are only winners in the pool, winners get back their bets without paying fees
            else if (winTotal == total) {
                winOutcome = total;
            }
            //Regular case, when there winners and loosers in the pool
            else {
                platformFeeAmount = total.mul(poolManager.getPlatformFee()).div(
                    10000
                );
                poolFeeAmount = total.mul(poolFee).div(10000);
                winOutcome = total.sub(poolFeeAmount).sub(platformFeeAmount);
            }
            if (platformFeeAmount > 0) {
                forwardPlatformFee();
            }
            forwardAffiliateAward();
        }
        return true;
    }

    /*uint256 lostTotal = total - winTotal;
                poolFeeAmount = lostTotal.mul(poolFee).div(10000);
                platformFeeAmount = lostTotal
                .mul(poolManager.getPlatformFee())
                .div(10000);
                winOutcome = lostTotal.sub(poolFeeAmount).sub(
                    platformFeeAmount
                ); */

    function claimReward() external returns (bool) {
        require(!claimedUser[msg.sender], "You already claimed");
        uint256 amount;
        if (
            (block.timestamp - endDate > WAIT_TIME_FOR_RESULT && result == 0) ||
            winOutcome == total
        ) {
            // can withdraw after 5 hours or we have only winners in a pool
            amount = userBet[msg.sender];
        } else {
            require(result != 0);
            uint256 winShare = userSideBet[msg.sender][result];
            uint256 preAmount = winTotal != 0
                ? winOutcome.mul(winShare).div(winTotal)
                : 0;
            amount = preAmount >= winShare ? preAmount : winShare;
        }

        claimedAmount[msg.sender] = amount;
        claimedUser[msg.sender] = true;
        withdraw(payable(msg.sender), amount);
        return true;
    }

    function withdraw(address payable receiver, uint256 amount)
        internal
        returns (bool)
    {
        require(amount > 0);
        require(receiver != address(0));
        if (currency == address(0)) {
            receiver.transfer(amount);
        } else {
            IERC20(currency).transfer(receiver, amount);
        }
        return true;
    }

    function withdrawDepositAndFee() external onlyOwner returns (bool) {
        require(
            result != 0 ||
                (result == 0 &&
                    block.timestamp - endDate > WAIT_TIME_FOR_RESULT)
        );
        require(!claimedDepositAndFee);
        claimedDepositAndFee = true;

        if (winTotal == 0) {
            withdraw(payable(owner), winOutcome);
        }
        if (poolFeeAmount > 0) {
            withdraw(payable(msg.sender), poolFeeAmount);
        }
        IERC20(poolManager.getCalAddress()).transfer(msg.sender, depositedCal);
        return true;
    }

    function forwardPlatformFee() internal {
        require(platformFeeAmount > 0);
        require(!claimedPlatformFee);
        claimedPlatformFee = true;
        address escrowAddress = poolManager.getFeeReceiver();
        Escrow escrow = Escrow(escrowAddress);

        if (currency == address(0)) {
            escrow.escrowEth{value: platformFeeAmount}();
        } else {
            IERC20 token = IERC20(currency);
            token.approve(escrowAddress, platformFeeAmount);
            escrow.escrowToken(currency, platformFeeAmount);
        }
    }

    function forwardAffiliateAward() internal {
        address affiliateAddr = poolManager.getAffiliateAddress();
        Affiliate affiliateSC = Affiliate(affiliateAddr);

        uint256 awardTotal;
        for (uint256 i = 0; i < betUsers.length; i++) {
            address _addr = betUsers[i];
            address _affiliate = affiliateSC.getAffiliateOf(_addr);
            if (userBet[_addr] > 0 && _affiliate != address(0)) {
                affiliates.push(_affiliate);
                uint256 award = userBet[_addr]
                .mul(poolManager.getAffiliatePercent())
                .div(10000);
                awards.push(award);
                awardTotal = awardTotal.add(award);
            }
        }
        if (awardTotal > 0) {
            winOutcome = winOutcome.sub(awardTotal);
            if (currency == address(0)) {
                affiliateSC.sendEthAward{value: awardTotal}(affiliates, awards);
            } else {
                IERC20(currency).approve(affiliateAddr, awardTotal);
                affiliateSC.sendTokenAward(affiliates, awards, currency);
            }
        }
    }

    // Remove on Production
    function changeEndDate(uint256 _newDate) external onlyOwner {
        endDate = _newDate;
    }

    function testSetResult(uint8 _sideWin) external onlyEndDate {
        require(poolManager.getOperatorAddress() == msg.sender);
        require(_sideWin > 0);
        result = _sideWin;
        if (total > 0) {
            winTotal = sideTotals[result];
            poolFeeAmount = total.mul(poolFee).div(10000);
            platformFeeAmount = total.mul(poolManager.getPlatformFee()).div(
                10000
            );
            winOutcome = total.sub(poolFeeAmount).sub(platformFeeAmount);
        }
    }

    function testforwardPlatformFee() external onlyHasResult {
        forwardPlatformFee();
    }

    function testforwardAffiliateAward() external onlyHasResult {
        forwardAffiliateAward();
    }
}
