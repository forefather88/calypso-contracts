// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Oracle.sol";
import "./OpenZeppelin/Initializable.sol";

contract Staking is Initializable {
    using SafeMath for uint256;

    address public owner;
    address[] public accounts;
    uint256 public total;
    Oracle public oracle;

    mapping(address => uint256) public stakeAmount;

    //CAL staking
    mapping(address => uint256) public stakeIncome;

    //USDT staking
    mapping(address => uint256) public stakeIncomeUsdt;

    //ETH staking
    mapping(address => uint256) public stakeIncomeEth;

    mapping(address => uint256) public accountIndex;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function getCurrentState(address _address)
        external
        view
        returns (
            uint256 _total,
            uint256 _stakeAmount,
            uint256 _stakeIncome,
            uint256 _stakeIncomeUsdt,
            uint256 _stakeIncomeEth
        )
    {
        _total = total;
        _stakeAmount = stakeAmount[_address];
        _stakeIncome = stakeIncome[_address];
        _stakeIncomeUsdt = stakeIncomeUsdt[_address];
        _stakeIncomeEth = stakeIncomeEth[_address];
    }

    function initialize() public initializer {
        owner = msg.sender;
        accounts.push(address(0));
        oracle = Oracle(0xfFB0E212B568133fEf49d60f8d52b4aE4A2fdB72);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0);
        require(
            IERC20(oracle.getCalAddress()).transferFrom(
                msg.sender,
                address(this),
                _amount
            )
        );
        stakeAmount[msg.sender] = stakeAmount[msg.sender].add(_amount);
        total = total.add(_amount);
        if (accountIndex[msg.sender] == 0) {
            accountIndex[msg.sender] = accounts.length;
            accounts.push(msg.sender);
        }
    }

    function shareIncome(address _tokenAddress, uint256 _amount) external {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        if (total > 0) {
            for (uint256 i = 1; i < accounts.length; i++) {
                uint256 stakeShare = _amount.mul(stakeAmount[accounts[i]]).div(
                    total
                );
                if (_tokenAddress == oracle.getCalAddress()) {
                    stakeIncome[accounts[i]] = stakeIncome[accounts[i]].add(
                        stakeShare
                    );
                } else if (_tokenAddress == oracle.getUsdtAddress()) {
                    stakeIncomeUsdt[accounts[i]] = stakeIncomeUsdt[accounts[i]]
                    .add(stakeShare);
                }
            }
        }
    }

    function shareIncomeEth() external payable {
        uint256 _amount = msg.value;
        if (total > 0) {
            for (uint256 i = 1; i < accounts.length; i++) {
                uint256 stakeShare = _amount.mul(stakeAmount[accounts[i]]).div(
                    total
                );
                stakeIncomeEth[accounts[i]] = stakeIncomeEth[accounts[i]].add(
                    stakeShare
                );
            }
        }
    }

    function claimTokens() external {
        require(stakeAmount[msg.sender] > 0);
        uint256 totalIncome = stakeAmount[msg.sender].add(
            stakeIncome[msg.sender]
        );
        uint256 totalIncomeUsdt = stakeIncomeUsdt[msg.sender];
        uint256 totalIncomeEth = stakeIncomeEth[msg.sender];
        total = total.sub(stakeAmount[msg.sender]);
        stakeAmount[msg.sender] = 0;
        stakeIncome[msg.sender] = 0;
        stakeIncomeUsdt[msg.sender] = 0;
        stakeIncomeEth[msg.sender] = 0;
        uint256 index = accountIndex[msg.sender];
        if (accounts.length > 2) {
            delete accounts[index];
            if (index < accounts.length - 1) {
                accounts[index] = accounts[accounts.length - 1];
                delete accounts[accounts.length - 1];
            }
        }

        IERC20(oracle.getCalAddress()).transfer(msg.sender, totalIncome);
        IERC20(oracle.getUsdtAddress()).transfer(msg.sender, totalIncomeUsdt);
        payable(msg.sender).transfer(totalIncomeEth);
    }

    function withdrawCal() external onlyOwner {
        IERC20 Cal = IERC20(oracle.getCalAddress());
        uint256 balance = Cal.balanceOf(address(this));
        Cal.transfer(msg.sender, balance);
    }

    function withdrawUsdt() external onlyOwner {
        IERC20 Usdt = IERC20(oracle.getUsdtAddress());
        uint256 balance = Usdt.balanceOf(address(this));
        Usdt.transfer(msg.sender, balance);
    }

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getAccountIndex(address _address) external view returns (uint256) {
        return accountIndex[_address];
    }

    // Remove in future
    function changeOracle(address _newAddress) external onlyOwner {
        oracle = Oracle(_newAddress);
    }
}
