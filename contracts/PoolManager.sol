// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./BettingPool.sol";
import "./Oracle.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/Initializable.sol";

contract PoolManager is Initializable {
    using SafeMath for uint256;

    address public owner;
    address[] private pools;
    Oracle public oracle;

    // Looks like poolToType is obsolete, cant find any use of it
    mapping(address => uint8) private poolToType; //betting, baccarat
    // Betting pools inside of a PoolManager. getOwnPools returns an array of betting pools that belongs to a msg.sender
    mapping(address => mapping(uint256 => address[])) private ownPools;
    //Also looks obsolete
    mapping(uint8 => address[]) private typeToPools; //betting, baccarat

    // Both absolete, probably we should remove from this SC for optimisation
    uint8 constant betting = 0;
    uint8 constant baccarat = 1;

    function initialize() public initializer {
        owner = msg.sender;
        oracle = Oracle(0xfFB0E212B568133fEf49d60f8d52b4aE4A2fdB72);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function createBettingPool(
        string memory _title,
        string memory _description,
        uint256 _gameId,
        string memory _gameType,
        uint256 _endDate,
        address _currency,
        /*Since solidity has a limit of params that we can pass to a function call, we pass some params in the _currencyDetails array
        uint256 _poolFee, = _currencyDetails[0]
        uint256 _depositedCal, = _currencyDetails[1]
        uint256 _minBet, = _currencyDetails[2]
        uint256 _minPoolSize, = _currencyDetails[3]*/
        uint256[] memory _currencyDetails,
        address[] memory _whitelist,
        //_handicapWhole, =_handicap[0] * 100
        //_handicapFractional =_handicap[1] * 100
        //bool _hasHandicap, = _bools[0]
        //bool _isUnlimited = _bools[1]
        bool[] memory _bools,
        int256[] memory _handicap
    ) external returns (address) {
        require(
            _currencyDetails[0] <= 9500,
            "Pool Fee should not be bigger then 95%"
        );
        require(_endDate > block.timestamp, "End date should be in future");
        require(_currencyDetails[1] > 0, "Max cap should larger than 0");
        BettingPool pool = new BettingPool(
            msg.sender,
            _title,
            _description,
            _gameId,
            _gameType,
            _endDate,
            _currency,
            _currencyDetails,
            _whitelist,
            _bools,
            _handicap
        );
        require(
            IERC20(oracle.getCalAddress()).transferFrom(
                msg.sender,
                address(pool),
                _currencyDetails[1]
            ),
            "Unable to deposit CAL"
        );
        pools.push(address(pool));
        ownPools[msg.sender][betting].push(address(pool));
        typeToPools[betting].push(address(pool));
        poolToType[address(pool)] = betting;
        return address(pool);
    }

    function getMaxCap(uint256 _depositedCal, address _currency)
        external
        view
        returns (uint256 _maxCap)
    {
        _maxCap = oracle.getMaxCap(_depositedCal, _currency);
    }

    function getAllPool() external view returns (address[] memory) {
        return pools;
    }

    function getOwnPools(uint8 _poolType)
        external
        view
        returns (address[] memory)
    {
        return ownPools[msg.sender][_poolType];
    }

    function getLastOwnPool(uint8 _poolType) external view returns (address) {
        address[] memory myPools = ownPools[msg.sender][_poolType];
        return myPools.length > 0 ? myPools[myPools.length - 1] : address(0);
    }

    function getPoolsWithType(uint8 _poolType)
        external
        view
        returns (address[] memory)
    {
        return typeToPools[_poolType];
    }

    function getEthPrice() external view returns (uint256) {
        return oracle.getEthPrice();
    }

    function getTokenPrice(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        return oracle.getTokenPrice(_tokenAddress);
    }

    function getCalAddress() external view returns (address) {
        return oracle.getCalAddress();
    }

    function getOperatorAddress() external view returns (address) {
        return oracle.getOperatorAddress();
    }

    function getPlatformFee() external view returns (uint256) {
        return oracle.getPlatformFee();
    }

    function getAffiliateAddress() external view returns (address) {
        return oracle.getAffiliateAddress();
    }

    function getAffiliatePercent() external view returns (uint256) {
        return oracle.getAffiliatePercent();
    }

    function changeOracle(address _newAddress) external onlyOwner {
        oracle = Oracle(_newAddress);
    }
}
