// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// import "./OpenZeppelin/Initializable.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/SafeMath.sol";

contract USDT is IERC20 {
    using SafeMath for uint256;
    //--- Token configurations ----// 
    string public constant name = "USDT";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    address public owner;
    uint256 private _totalsupply;

    event Mint(address indexed from, address indexed to, uint256 amount);

    // function initialize() public initializer{
    //     owner = msg.sender;
    //     _totalsupply = 100000 ether;
    //     balances[owner] = _totalsupply;
    // }

    constructor() {
        owner = msg.sender;
        _totalsupply = 100000 ether;
        balances[owner] = _totalsupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }


    function totalSupply() public view override returns (uint256) {
        return _totalsupply;
    }


    function balanceOf(address investor) public view override returns (uint256) {
        return balances[investor];
    }
    
    function approve(address _spender, uint256 _amount) public override returns (bool)  {
        require( _spender != address(0), "Address can not be 0x0");
        require(balances[msg.sender] >= _amount, "Balance does not have enough tokens");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _from, address _spender) public view override returns (uint256) {
        return allowed[_from][_spender];
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        require( _to != address(0), "Receiver can not be 0x0");
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom( address _from, address _to, uint256 _amount ) public override returns (bool)  {
        require( _to != address(0), "Receiver can not be 0x0");
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function manualMint(uint256 _value) public onlyOwner {
        mint(owner, owner, _value);
    }

    function mint(address _from, address _receiver, uint256 _value) internal {
        require(_receiver != address(0), "Address can not be 0x0");
        require(_value > 0, "Value should larger than 0");
        balances[_receiver] = balances[_receiver].add(_value);
        _totalsupply = _totalsupply.add(_value);
        emit Mint(_from, _receiver, _value);
        emit Transfer(address(0), _receiver, _value);
    }
}