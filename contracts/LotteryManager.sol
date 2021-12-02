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
    address[] public rewardAddresses;
    address[] public stakingUsers;
    mapping(address => uint256) public userToStake;
    uint256 public totalStaked;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function initialize() public initializer {
        stakingUsers.push(address(this));

        rewardAddresses.push(0xaeC9bB50Aff0158e86Bfdc1728C540D59edD71AD);
        rewardAddresses.push(0xFd072083887bFcF8aEb8F37991c11c7743113374);
        rewardAddresses.push(0xD22b134C9eDeB0e32CF16dB4B681461F8563dD34);

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

            //Total prizes paid and ticket sales for the last lottery
            uint256 totalWin = Lottery(lastLottery).totalWin().mul(
                1000000000000000000
            );
            uint256 totalTickets = Lottery(lastLottery).totalTickets().mul(
                1000000000000000000
            );

            IERC20(Oracle(oracleAddress).getCalAddress()).approve(
                lastLottery,
                totalWin
            );

            uint256 oldTotalStaked = totalStaked;
            totalStaked = totalStaked.sub(totalWin);

            //If totalTickets > totalWin, then the last lottery has made profit
            if (totalTickets > totalWin) {
                uint256 profit = totalTickets.mul(5).div(100);
                //95% of ticket sales are shared between stakers
                totalStaked = totalStaked.add(totalTickets.sub(profit));
                shareStakingReward(oldTotalStaked);

                //5% (profit) is shared between stakers and team
                //We need a function that shares profit (uint256 profit) between rewardAddresses and stakers
                //We need to decide if we want to send profit to rewardAddresses straight, or incllude them to stakers array
            } else {
                totalStaked = totalStaked.add(totalTickets);
            }
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
