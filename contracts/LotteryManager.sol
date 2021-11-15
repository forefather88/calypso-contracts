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

    // Staking
    // stakingUsers нужен для перевода наград юзерам (если маппинг показывает 0 стейка у юзера - награда юзеру не начисляется )
    address[] public stakingUsers;
    mapping(address => uint256) public userToStake;
    uint256 public totalStaked;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function initialize() public initializer {
        stakingUsers.push(address(this));

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
            Lottery(lastLottery).startDraw(totalStaked);

            uint256 totalWin = Lottery(lastLottery).totalWin().mul(
                1000000000000000000
            );
            IERC20(Oracle(oracleAddress).getCalAddress()).approve(
                lastLottery,
                totalWin
            );
            uint256 oldTotalStaked = totalStaked;
            totalStaked = totalStaked.sub(totalWin).add(
                Lottery(lastLottery).totalTickets().mul(1000000000000000000)
            );
            shareStakingReward(oldTotalStaked);
        }

        //Uncomment after testing
        // require(randomResult != 0, "Use getRandomNumber() function first.");
        Lottery lottery = new Lottery(
            msg.sender,
            11234567, //randomResult.mod(10000000).add(10000000),
            address(this),
            _totalPrize
        );

        lotteries.push(address(lottery));
        managerStake(_totalPrize.mul(1000000000000000000));

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

    // Staking
    function stake(uint256 _amount) external returns (bool) {
        require(_amount > 0, "The amount to stake cannot be equal to 0.");
        IERC20(Oracle(oracleAddress).getCalAddress()).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        totalStaked = totalStaked.add(_amount);
        placeStake(_amount);
        return true;
    }

    function managerStake(uint256 _amount) private returns (bool) {
        totalStaked = totalStaked.add(_amount);
        userToStake[address(this)] = userToStake[address(this)].add(_amount);
        return true;
    }

    function placeStake(uint256 _amount) private {
        bool userHasStaked = false;
        for (uint256 i = 0; i < stakingUsers.length; i++) {
            if (stakingUsers[i] == msg.sender) {
                userHasStaked = true;
            }
        }
        if (!userHasStaked) {
            stakingUsers.push(msg.sender);
        }
        userToStake[msg.sender] = userToStake[msg.sender].add(_amount);
    }

    function getUserStake() external view returns (uint256) {
        return userToStake[msg.sender];
    }

    
    function unstake(uint256 _amount) external returns (bool) {
        uint256 usersStake = userToStake[msg.sender];
        require(
            usersStake > 0,
            "This user haven't ever staked in this lottery."
        );
        require(
            _amount <= usersStake,
            "You can't withdraw more then you have staked."
        );

        userToStake[msg.sender] = usersStake.sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        IERC20(Oracle(oracleAddress).getCalAddress()).transfer(
            msg.sender,
            _amount
        );

        return true;
    }

    function shareStakingReward(uint256 _oldTotalStaked)
        private
        returns (bool)
    {
        for (uint256 i = 0; i < stakingUsers.length; i++) {
            address user = stakingUsers[i];
            uint256 stakeAmount = userToStake[user];
            if (stakeAmount > 0) {
                uint256 stakeShare = totalStaked.mul(stakeAmount).div(
                    _oldTotalStaked
                );
                userToStake[user] = stakeShare;
            }
        }

        return true;
    }

    //Remove after testing
    function setStakingToZero() external {
        totalStaked = 0;
        for (uint256 i = 0; i < stakingUsers.length; i++) {
            userToStake[stakingUsers[i]] = 0;
        }
    }
}
