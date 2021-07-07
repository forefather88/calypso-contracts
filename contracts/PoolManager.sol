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

    mapping(address => uint8) private poolToType; //betting, baccarat
    mapping(address => mapping(uint256 => address[])) private ownPools;
    mapping(uint8 => address[]) private typeToPools; //betting, baccarat

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
        uint256 _poolFee,
        uint256 _depositedCal,
        uint256 _minBet,
        address[] memory _whitelist
    ) external returns (address) {
        require(_endDate > block.timestamp, "End date should be in future");
        require(_depositedCal > 0, "Max cap should larger than 0");
        BettingPool pool = new BettingPool(
            msg.sender,
            _title,
            _description,
            _gameId,
            _gameType,
            _endDate,
            _currency,
            _poolFee,
            _depositedCal,
            _whitelist,
            _minBet
        );
        require(
            IERC20(oracle.getCalAddress()).transferFrom(
                msg.sender,
                address(pool),
                _depositedCal
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
