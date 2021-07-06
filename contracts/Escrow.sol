// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Oracle.sol";
import "./Staking.sol";
import "./OpenZeppelin/Initializable.sol";

contract Escrow is Initializable {
    using SafeMath for uint256;

    address public owner;
    Oracle public oracle;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
        oracle = Oracle(0xfFB0E212B568133fEf49d60f8d52b4aE4A2fdB72);
    }

    function escrowEth() external payable {
        uint256 ethPrice = oracle.getEthPrice();
        uint256 calNumber = msg.value.mul(ethPrice).div(10**8);
        shareIncome(calNumber);
    }

    function escrowToken(address _tokenAddress, uint256 _amount) external {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);
        uint256 tokenPrice = oracle.getTokenPrice(_tokenAddress);
        uint256 calNumber = _amount.mul(tokenPrice).div(10**8);
        shareIncome(calNumber);
    }

    function shareIncome(uint256 _amount) internal {
        uint256 value = _amount.mul(oracle.getStakePercent()).div(10000);
        IERC20(oracle.getCalAddress()).approve(
            oracle.getStakingAddress(),
            value
        );
        Staking(oracle.getStakingAddress()).shareIncome(value);
    }

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    // Remove in future
    function changeOracle(address _newAddress) external onlyOwner {
        oracle = Oracle(_newAddress);
    }
}
