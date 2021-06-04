// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// import "./OpenZeppelin/Initializable.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./Oracle.sol";

contract CalSwap  {
    using SafeMath for uint256;
    
    Oracle public oracle;

    address payable public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    // function initialize() public initializer{
    //     owner = msg.sender;
    //     USDT = IERC20(0x136b9047dD95313ef513fb692b4b3D695A3C57C9);
    //     CAL = IERC20(0x9c16005F5CD011fBe330baE68F319Dc73E116762);
    //     ethPrice = 400;
    // } 

    constructor() {
        owner = payable(msg.sender);
        oracle = Oracle(0xea451D9038e91BdeBc5484B33ba8096EcE07D182);
    }

    receive() external payable {
        uint256 calNumber = msg.value.mul(oracle.getEthPrice()).div(10 ** 8);
        IERC20(oracle.getCalAddress()).transfer(msg.sender, calNumber);
    }

    function swap(uint256 _value) external {
        require(IERC20(oracle.getUsdtAddress()).transferFrom(msg.sender, address(this), _value));
        IERC20(oracle.getCalAddress()).transfer(msg.sender, _value);
    }

    function withdrawCal(uint256 _value) external onlyOwner {
        IERC20(oracle.getCalAddress()).transfer(msg.sender, _value);
    }

    function withdrawUsdt(uint256 _value) external onlyOwner {
        IERC20(oracle.getCalAddress()).transfer(msg.sender, _value);
    }

    function withdrawEth(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // Remove in future
    function changeOracle(address _newAddress) external onlyOwner {
        oracle = Oracle(_newAddress);
    }
}