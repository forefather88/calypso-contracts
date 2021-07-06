// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./abdk/ABDKMath64x64.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/Initializable.sol";

interface HistoricAggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 timestamp
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

interface AggregatorInterface is HistoricAggregatorInterface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function getRoundData(uint256 _roundId)
        external
        view
        returns (
            uint256 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint256 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint256 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint256 answeredInRound
        );

    function version() external view returns (uint256);
}

contract Oracle is Initializable {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;

    address public owner;
    mapping(address => uint256) private tokenPrice;
    bool manualInputPrice;
    uint256 ethPrice; // 1e8
    address usdt;
    address cal;
    address staking;
    address escrow;
    address operator;
    address affiliate;
    uint256 stakePercent; // * 10000
    uint256 platformFee; // * 10000
    uint256 affiliatePercent; // * 10000
    address[] supportCurrencies;
    mapping(address => uint256) currencyIndex;
    AggregatorInterface internal ref;
    // Logistic Curve Constants
    int128 upperLimit;
    int128 rateK;
    int128 inflectionPoint;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
        ethPrice = 2150 * (10**8);
        cal = 0xec0A5D38c5C65Ee775d28aBf412ea2C5ffa76728;
        usdt = 0x679D993290D209a2Ccb6cd9F5a42A6302c41B1Ea;
        operator = 0xaeC9bB50Aff0158e86Bfdc1728C540D59edD71AD;
        ref = AggregatorInterface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        staking = 0x07ceDAE01C088b60F12879eAd6726655B6b6759E;
        escrow = 0x8b283930dFe61888EEdadE68cb01938d16216884;
        affiliate = 0x3143aCDC37C8F3028C3feA288ea87C61411a4d28;

        supportCurrencies = [cal, usdt];

        stakePercent = 1000;
        platformFee = 100;
        affiliatePercent = 125;

        changeLogisticCurveSettings(10**6, 90, 50);
    }

    // rateK x1000
    function changeLogisticCurveSettings(
        uint256 _upperLimit,
        uint256 _rateK,
        uint256 _inflectionPoint
    ) public onlyOwner {
        upperLimit = ABDKMath64x64.fromUInt(_upperLimit);
        rateK = ABDKMath64x64.neg(
            ABDKMath64x64.fromUInt(_rateK).div(ABDKMath64x64.fromUInt(1000))
        );
        inflectionPoint = ABDKMath64x64.fromUInt(_inflectionPoint);
    }

    // Max Pool Size =  MaxPoolSize_UpperLimit / (1 + EXP( -Rate_k * (Number_Of_Cal - Inflection_Point))) / token_price
    function getMaxCap(uint256 _depositedCal, address _currency)
        external
        view
        returns (uint256 _maxCap)
    {
        uint256 price;
        if (_currency == address(0)) {
            price = getEthPrice();
        } else {
            price = getTokenPrice(_currency);
        }
        int128 calNum = ABDKMath64x64.fromUInt(_depositedCal.div(10**13)).div(
            ABDKMath64x64.fromUInt(10**5)
        );
        int128 x = rateK.mul(calNum.sub(inflectionPoint));
        int128 exponent = ABDKMath64x64.exp(x);
        int128 max = upperLimit.div(ABDKMath64x64.fromUInt(1).add(exponent));
        // Convert to uint256 and round up to thoundsand number
        uint256 maxInUSD = uint256(ABDKMath64x64.toUInt(max))
        .add(500)
        .div(1000)
        .mul(1000 * 10**18);
        _maxCap = maxInUSD.mul(10**8).div(price);
    }

    function changeAggregator(address _aggregator) public onlyOwner {
        ref = AggregatorInterface(_aggregator);
    }

    function setEthPrice(uint256 newPrice) public onlyOwner {
        require(manualInputPrice, "Getting price automatically");
        ethPrice = newPrice;
    }

    function enableManualInputPrice(bool enabled) public onlyOwner {
        manualInputPrice = enabled;
    }

    function addSupportCurrency(address _newCurrency) external onlyOwner {
        currencyIndex[_newCurrency] = supportCurrencies.length;
        supportCurrencies.push(_newCurrency);
    }

    function removeSupportCurrency(address _oldCurrency) external onlyOwner {
        require(supportCurrencies.length > 0);
        uint256 index = currencyIndex[_oldCurrency];
        require(supportCurrencies[index] == _oldCurrency);
        uint256 lastIndex = supportCurrencies.length - 1;
        supportCurrencies[index] = supportCurrencies[lastIndex];
        supportCurrencies.pop();
    }

    function getSupportCurrencies() external view returns (address[] memory) {
        return supportCurrencies;
    }

    function getEthPrice() public view returns (uint256) {
        if (manualInputPrice) {
            return ethPrice;
        }
        return uint256(ref.latestAnswer());
    }

    function getTokenPrice(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 price = tokenPrice[_tokenAddress];
        return price == 0 ? 10**8 : price;
    }

    function getUsdtAddress() external view returns (address) {
        return usdt;
    }

    function getCalAddress() external view returns (address) {
        return cal;
    }

    function getStakingAddress() external view returns (address) {
        return staking;
    }

    function getEscrowAddress() external view returns (address) {
        return escrow;
    }

    function getOperatorAddress() external view returns (address) {
        return operator;
    }

    function getAffiliateAddress() external view returns (address) {
        return affiliate;
    }

    function getStakePercent() external view returns (uint256) {
        return stakePercent;
    }

    function getPlatformFee() external view returns (uint256) {
        return platformFee;
    }

    function getAffiliatePercent() external view returns (uint256) {
        return affiliatePercent;
    }

    function setTokenPrice(address _tokenAddress, uint256 _price)
        external
        onlyOwner
    {
        require(_price > 0);
        tokenPrice[_tokenAddress] = _price;
    }

    function changeUsdtAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        usdt = _newAddress;
    }

    function changeCalAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        cal = _newAddress;
    }

    function changeStakingAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        staking = _newAddress;
    }

    function changeEscrowAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        escrow = _newAddress;
    }

    function changeOperatorAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        operator = _newAddress;
    }

    function changeAffiliateAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        affiliate = _newAddress;
    }

    function changeStakePercent(uint256 _sharePercent) external onlyOwner {
        require(_sharePercent > 0);
        stakePercent = _sharePercent;
    }

    function changePlatformFee(uint256 _fee) external onlyOwner {
        require(_fee > 0);
        platformFee = _fee;
    }

    function changeAffiliatePercent(uint256 _percent) external onlyOwner {
        require(_percent > 0);
        affiliatePercent = _percent;
    }
}
