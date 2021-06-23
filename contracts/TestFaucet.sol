// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./Oracle.sol";
import "./OpenZeppelin/Initializable.sol";

contract TestFaucet is Initializable {
    using SafeMath for uint256;

    address owner;
    Oracle public oracle;
    mapping(address => uint256) receivedUsdtUser;

    function initialize() public initializer {
        owner = msg.sender;
        oracle = Oracle(0xea451D9038e91BdeBc5484B33ba8096EcE07D182);
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function transferUsdt(uint256 _amount) external {
        receivedUsdtUser[msg.sender] = receivedUsdtUser[msg.sender].add(
            _amount
        );
        require(receivedUsdtUser[msg.sender] < 1000 ether, "You are greedy");
        IERC20(oracle.getUsdtAddress()).transfer(msg.sender, _amount);
    }

    function withdrawUsdt() external onlyOwner {
        uint256 balance =
            IERC20(oracle.getUsdtAddress()).balanceOf(address(this));
        IERC20(oracle.getUsdtAddress()).transfer(msg.sender, balance);
    }

    // Remove in future
    function changeOracle(address _newAddress) external onlyOwner {
        oracle = Oracle(_newAddress);
    }
}
