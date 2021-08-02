// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Bet.sol";
import "./PoolManager.sol";
import "./Staking.sol";
import "./Affiliate.sol";
import "./Oracle.sol";
struct Handicap {
    int256 whole; // * 100
    int256 fractional; // * 100
}

struct Game {
    uint256 gameId;
    string gameType; //epl, lol, dota 2, pubg
    uint256 endDate;
}

contract BettingPool {
    using SafeMath for uint256;

    uint256 constant WAIT_TIME_FOR_RESULT = 5 * 60 * 60; // after 5 hours users can withdraw without fee

    // Initialize
    address public owner;
    string public title;
    string public description;
    Game public game;
    uint256 public depositedCal;
    uint256 public maxCap;
    uint256 public poolFee; // * 10000
    uint256 public createdDate;
    address public currency;
    PoolManager public poolManager;
    bool public isPrivate;
    address[] public whitelist;
    mapping(address => uint256) whitelistIndexes;
    uint256 public minBet;
    bool public hasHandicap;
    Handicap public handicap;
    uint256 public minPoolSize;

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
    uint256 refund;
    uint256 public poolFeeAmount;
    uint256 public platformFeeAmount;
    address[] affiliates;
    uint256[] awards;

    // Post Result
    mapping(address => uint256) public claimedAmount; // user -> claim amount
    mapping(address => bool) public claimedUser; // user -> claimed?
    bool claimedDepositAndFee;

    Oracle public oracle;

    constructor(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _gameId,
        string memory _gameType,
        uint256 _endDate,
        address _currency,
        uint256[] memory _currencyDetails,
        address[] memory _whitelist,
        bool _hasHandicap,
        int256[] memory _handicap
    ) {
        owner = _owner;
        title = _title;
        description = _description;
        game = Game(_gameId, _gameType, _endDate);
        currency = _currency;
        poolFee = _currencyDetails[0];
        createdDate = block.timestamp;
        result = 0;
        minBet = _currencyDetails[2];
        hasHandicap = _hasHandicap;
        handicap.whole = _handicap[0];
        handicap.fractional = _handicap[1];
        poolManager = PoolManager(msg.sender);
        depositedCal = _currencyDetails[1];
        maxCap = poolManager.getMaxCap(_currencyDetails[1], _currency);
        require(
            _currencyDetails[3] < maxCap,
            "Min pool size cannot be bigger than max pool size"
        );
        minPoolSize = _currencyDetails[3];
        oracle = Oracle(0xfFB0E212B568133fEf49d60f8d52b4aE4A2fdB72);
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
        require(block.timestamp >= game.endDate, "End date is not reached");
        _;
    }

    modifier onlyHasResult() {
        require(result > 0, "Result was not set");
        _;
    }

    modifier onlyBeforeEndDate() {
        require(block.timestamp < game.endDate, "Only before End date");
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
            Game memory _game,
            address _currency,
            uint256 _poolFee,
            uint256 _depositedCal,
            uint256 _maxCap,
            address _owner,
            bool _isPrivate,
            uint256 _minPoolSize,
            bool _hasHandicap
        )
    {
        _title = title;
        _description = description;
        _game = game;
        _currency = currency;
        _poolFee = poolFee;
        _maxCap = maxCap;
        _owner = owner;
        _isPrivate = isPrivate;
        _depositedCal = depositedCal;
        _minPoolSize = minPoolSize;
        _hasHandicap = hasHandicap;
    }

    function getPoolDetail2()
        external
        view
        returns (
            uint8 _result,
            uint256 _total,
            uint256 _winOutcome,
            uint256 _winTotal,
            uint256 _refund,
            uint256 _poolFeeAmount,
            address[] memory _betUsers,
            uint256 _createdDate,
            address[] memory _whitelist,
            bool _claimedDepositAndFee,
            uint256 _minBet,
            Handicap memory _handicap
        )
    {
        _result = result;
        _total = total;
        _winOutcome = winOutcome;
        _winTotal = winTotal;
        _refund = refund;
        _poolFeeAmount = poolFeeAmount;
        _betUsers = betUsers;
        _createdDate = createdDate;
        _whitelist = whitelist;
        _claimedDepositAndFee = claimedDepositAndFee;
        _minBet = minBet;
        _handicap = handicap;
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

    function isHalf() private view returns (bool) {
        int256 abs = handicap.fractional >= 0
            ? handicap.fractional
            : handicap.fractional * -1;
        return abs == 50;
    }

    function roundResult(int256 _aResult) private view returns (int256) {
        if (handicap.fractional == -25) {
            return _aResult + 25;
        } else if (handicap.fractional == 25) {
            return _aResult - 25;
        } else if (handicap.fractional == -75) {
            return _aResult - 25;
        } else if (handicap.fractional == 75) {
            return _aResult + 25;
        }
    }

    //1- Team A Wins
    //2- Team A Loses
    //3- Draw
    //4- Team A Half Wins
    //5- Team A Half Loses
    function defineResult(int256 _aResult, int256 _bResult)
        private
        view
        returns (uint8)
    {
        _aResult = _aResult - _bResult;
        _bResult = 0;
        _aResult += handicap.whole + handicap.fractional;

        if (_aResult < 0 || _bResult > _aResult) {
            if (
                handicap.fractional != 50 && roundResult(_aResult) == _bResult
            ) {
                return 5;
            }
            return 2;
        } else if (_aResult > _bResult) {
            if (
                handicap.fractional != 50 && roundResult(_aResult) == _bResult
            ) {
                return 4;
            }
            return 1;
        } else if (_aResult == _bResult) {
            return 3;
        }
    }

    function setResult(
        uint8 _sideWin,
        int256 _aResult,
        int256 _bResult
    ) external onlyEndDate returns (bool) {
        require(poolManager.getOperatorAddress() == msg.sender);
        require(_sideWin > 0);
        if (hasHandicap) {
            _sideWin = defineResult(_aResult * 100, _bResult * 100);
        }
        result = _sideWin;
        if (total > 0) {
            if (result > 3) {
                winTotal = sideTotals[result == 4 ? 1 : 2];
            } else {
                winTotal = sideTotals[result];
            }

            // Calculation of winOutcome
            // If there are no winners in the pool the pool creator gets all the bets
            if (winTotal == 0 && !(result == 3 && hasHandicap)) {
                platformFeeAmount = getPlatformFeeAmount();
                winOutcome = total.sub(platformFeeAmount);
            }
            //If there are only winners in the pool
            //or the pool is inactive
            //or Handicap is set to zero and the result of a game is Draw !!!
            //winners get back their bets without paying fees
            else if (
                winTotal == total ||
                total < minPoolSize ||
                (result == 3 && hasHandicap)
            ) {
                winOutcome = total;
                //Half Win / Half Loose
            } else if (result == 4 || result == 5) {
                platformFeeAmount = getPlatformFeeAmount();
                poolFeeAmount = total.mul(poolFee).div(10000);
                uint256 subTotal = (total - sideTotals[result == 4 ? 2 : 1] / 2)
                .sub(poolFeeAmount)
                .sub(platformFeeAmount);
                winOutcome = subTotal;
                refund = sideTotals[result == 4 ? 2 : 1] / 2;
            }
            //Regular case, when there winners and loosers in the pool
            else {
                platformFeeAmount = getPlatformFeeAmount();
                poolFeeAmount = total.mul(poolFee).div(10000);
                winOutcome = total.sub(poolFeeAmount).sub(platformFeeAmount);
            }
            if (platformFeeAmount > 0) {
                forwardPlatformFee();
                forwardAffiliateAward();
            }
        }
        return true;
    }

    function getPlatformFeeAmount() private view returns (uint256) {
        return total.mul(poolManager.getPlatformFee()).div(10000);
    }

    function claimReward() external returns (bool) {
        require(!claimedUser[msg.sender], "You already claimed");
        uint256 amount;
        if (
            (block.timestamp - game.endDate > WAIT_TIME_FOR_RESULT &&
                result == 0) ||
            winOutcome == total ||
            total < minPoolSize
        ) {
            // can withdraw after 5 hours or we have only winners in a pool or the pool is inactive
            amount = userBet[msg.sender];
        } else {
            require(result != 0);
            uint256 winShare;
            if (result <= 3) {
                winShare = userSideBet[msg.sender][result];
            } else {
                winShare = userSideBet[msg.sender][result == 4 ? 1 : 2];
            }
            uint256 preAmount = winTotal != 0 ? getWinAmount(winShare) : 0;
            if (result > 3) {
                uint256 refundShare = refund != 0
                    ? userSideBet[msg.sender][result == 4 ? 2 : 1] / 2
                    : 0;
                preAmount += refundShare;
            }

            amount = preAmount >= winShare ? preAmount : winShare;
        }

        claimedAmount[msg.sender] = amount;
        claimedUser[msg.sender] = true;
        withdraw(payable(msg.sender), amount);
        return true;
    }

    function getWinAmount(uint256 _winShare) private view returns (uint256) {
        return winOutcome.mul(_winShare).div(winTotal);
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
                    block.timestamp - game.endDate > WAIT_TIME_FOR_RESULT)
        );
        require(!claimedDepositAndFee);
        claimedDepositAndFee = true;

        /*if (winTotal == 0) {
            withdraw(payable(owner), winOutcome);
        }*/
        if (poolFeeAmount > 0) {
            withdraw(payable(msg.sender), poolFeeAmount);
        }

        IERC20(poolManager.getCalAddress()).transfer(
            msg.sender,
            depositedCal / 2
        );
        ICal(poolManager.getCalAddress()).burn(depositedCal / 2);
        return true;
    }

    //Staking
    function forwardPlatformFee() internal {
        require(platformFeeAmount > 0);
        address stakingAddress = oracle.getStakingAddress();
        uint256 amount = platformFeeAmount / 2;
        if (currency == address(0)) {
            Staking(stakingAddress).shareIncomeEth{value: amount}();
        } else {
            IERC20 token = IERC20(currency);
            token.approve(stakingAddress, amount);
            Staking(stakingAddress).shareIncome(currency, amount);
        }
    }

    //Affiliate
    function forwardAffiliateAward() internal {
        require(platformFeeAmount > 0);
        address affiliateAddr = poolManager.getAffiliateAddress();
        Affiliate affiliateSC = Affiliate(affiliateAddr);

        uint256 awardTotal = platformFeeAmount / 2;
        for (uint256 i = 0; i < betUsers.length; i++) {
            address _addr = betUsers[i];
            address _affiliate = affiliateSC.getAffiliateOf(_addr);
            if (_affiliate != address(0)) {
                affiliates.push(_affiliate);
            }
        }

        for (uint256 i = 0; i < affiliates.length; i++) {
            uint256 award = awardTotal / affiliates.length;
            awards.push(award);
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
        game.endDate = _newDate;
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

    function changeOracle(address _newAddress) external onlyOwner {
        oracle = Oracle(_newAddress);
    }
}

interface ICal {
    function burn(uint256 _value) external returns (bool);
}
