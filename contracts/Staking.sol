// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Oracle.sol";

contract Staking {
    using SafeMath for uint256;

    address public owner;
    address[] public accounts;
    uint256 public total;
    Oracle public oracle;
    
    mapping(address => uint256) public stakeAmount;
    mapping(address => uint256) public stakeIncome;
    mapping(address => uint256) public accountIndex;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function getCurrentState(address _address) external view returns (
        uint256 _total,
        uint256 _stakeAmount,
        uint256 _stakeIncome
    ) {
        _total = total;
        _stakeAmount = stakeAmount[_address];
        _stakeIncome = stakeIncome[_address];
    }
    
    constructor() {
        owner = msg.sender;
        accounts.push(address(0));
        oracle = Oracle(0xea451D9038e91BdeBc5484B33ba8096EcE07D182);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0);
        require(IERC20(oracle.getCalAddress()).transferFrom(msg.sender, address(this), _amount));
        stakeAmount[msg.sender] = stakeAmount[msg.sender].add(_amount);
        total = total.add(_amount);
        if (accountIndex[msg.sender] == 0) {
            accountIndex[msg.sender] = accounts.length;
            accounts.push(msg.sender);
        }
    }
    
    function shareIncome(uint256 _amount) external {
        IERC20(oracle.getCalAddress()).transferFrom(msg.sender, address(this), _amount);
        if (total > 0) {
            for (uint256 i=1; i < accounts.length; i++) {
                uint256 stakeShare = _amount.mul(stakeAmount[accounts[i]]).div(total);
                stakeIncome[accounts[i]] = stakeIncome[accounts[i]].add(stakeShare);
            }
        }
    }
    
    function claimTokens() external {
        require(stakeAmount[msg.sender] > 0);
        uint256 totalIncome = stakeAmount[msg.sender].add(stakeIncome[msg.sender]);
        total = total.sub(stakeAmount[msg.sender]);
        stakeAmount[msg.sender] = 0;
        stakeIncome[msg.sender] = 0;
        uint256 index = accountIndex[msg.sender];
        if (accounts.length > 2) {
            delete accounts[index];
            if (index < accounts.length - 1) {
                accounts[index] = accounts[accounts.length - 1];
                delete accounts[accounts.length - 1];
            }
        }
        
        IERC20(oracle.getCalAddress()).transfer(msg.sender, totalIncome);
    }

    function withdrawCal() external onlyOwner {
        IERC20 Cal = IERC20(oracle.getCalAddress());
        uint256 balance = Cal.balanceOf(address(this));
        Cal.transfer(msg.sender, balance);
    }
    
    // Remove in future
    function changeOracle(address _newAddress) external onlyOwner {
        oracle = Oracle(_newAddress);
    }
}