// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Lottery.sol";
import "./Link/VRFConsumerBase.sol";
import "./Oracle.sol";
import "./OpenZeppelin/Initializable.sol";

contract LotteryManager is Initializable, VRFConsumerBase {
    using SafeMath for uint256;

    address[] private lotteries;
    address public owner;
    address public linkAddress;
    address public oracleAddress;

    //Values for generating a random number with Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal randomResult;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function initialize() public initializer {
        oracleAddress = 0xfFB0E212B568133fEf49d60f8d52b4aE4A2fdB72;

        owner = msg.sender;
        linkAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; //0.1 Link

        VRFConsumerBase.initialize(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            linkAddress
        );
    }

    function createLottery(uint256 _totalPrize) external returns (address) {
        if (lotteries.length > 0) {
            address lastLottery = lotteries[lotteries.length - 1];
            Lottery(lastLottery).startDraw();
        }

        //Uncomment after testing
        //require(randomResult != 0, "Use getRandomNumber() function first.");
        Lottery lottery = new Lottery(
            msg.sender,
            11234567, //randomResult.mod(10000000).add(10000000),
            address(this),
            _totalPrize
        );
        lotteries.push(address(lottery));
        IERC20(Oracle(oracleAddress).getCalAddress()).approve(
            address(lottery),
            _totalPrize.mul(1000000000000000000)
        );
        Lottery(address(lottery)).stake(_totalPrize);

        randomResult = 0;
        return address(lottery);
    }

    function getLotteriesAmount() external view returns (uint256) {
        return lotteries.length;
    }

    function withdrawLink() external onlyOwner returns (bool) {
        IERC20(linkAddress).transfer(
            owner,
            IERC20(linkAddress).balanceOf(address(this))
        );
        return true;
    }

    function withdrawCal() external onlyOwner returns (bool) {
        IERC20(Oracle(oracleAddress).getCalAddress()).transfer(
            owner,
            IERC20(Oracle(oracleAddress).getCalAddress()).balanceOf(
                address(this)
            )
        );
        return true;
    }

    function getAllLotteries() public view returns (address[] memory) {
        return lotteries;
    }

    /*function contribute() external onlyOwner returns (bool) {
        address lastLotteryAddr = lotteries[lotteries.length - 1];
        Lottery lastLottery = Lottery(lastLotteryAddr);
        require(
            lastLottery.originalTotalStaked() < lastLottery.totalPrize() &&
                block.timestamp >= lastLottery.endDate() - 3600 * 4 &&
                block.timestamp < lastLottery.endDate(),
            "Cannot contribute."
        );
        uint256 difference = lastLottery.totalPrize() -
            lastLottery.originalTotalStaked();
        IERC20(Oracle(oracleAddress).getCalAddress()).approve(
            lastLotteryAddr,
            difference.mul(1000000000000000000)
        );
        lastLottery.stake(difference);

        return true;
    }*/

    function getRandomNumber() external returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
    }

    function changeLinkAddress(address _address) external {
        linkAddress = _address;
    }

    function changeOracleAddress(address _address) external {
        oracleAddress = _address;
    }
}
