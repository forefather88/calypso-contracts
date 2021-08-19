// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Lottery.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract LotteryManager is VRFInitializable, VRFConsumerBase {
    using SafeMath for uint256;

    address[] private lotteries;
    address public owner;
    address public linkAddress;

    //Values for generating a random number with Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal randomResult;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
        linkAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; //0.1 Link

        VRFConsumerBase.initialize(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        );
    }

    function createLottery(uint256 _totalPrize)
        external
        onlyOwner
        returns (address)
    {
        //Uncomment after testing
        //require(randomResult != 0, "Use getRandomNumber() function first.");
        Lottery lottery = new Lottery(
            msg.sender,
            11234567, //randomResult.mod(10000000).add(10000000),
            address(this),
            _totalPrize
        );
        lotteries.push(address(lottery));
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

    function getAllLotteries() external view returns (address[] memory) {
        return lotteries;
    }

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
}
