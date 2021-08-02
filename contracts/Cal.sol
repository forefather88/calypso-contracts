// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// import "./OpenZeppelin/Initializable.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/Initializable.sol";

contract Cal is IERC20, Initializable {
    using SafeMath for uint256;
    //--- Token configurations ----//
    string public constant name = "CAL";
    string public constant symbol = "CAL";
    uint8 public constant decimals = 18;

    //--- Address -----------------//
    address public owner;
    address payable public ethReceivingWallet;
    address public treasuryWallet;

    //--- Variables ---------------//
    uint256 private _totalsupply;
    uint256 private _currentsupply;
    bool public transferrable;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private locked;

    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event ChangeReceiveWallet(address indexed newAddress);
    event ChangeOwnerShip(address indexed newOwner);
    event ChangeLockStatusFrom(address indexed investor, bool locked);
    event ChangeTokenLockStatus(bool locked);

    function initialize() public initializer {
        owner = msg.sender;
        _totalsupply = 100000000 ether;
        _currentsupply = 100000 ether;
        balances[owner] = _currentsupply;
        transferrable = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    modifier onlyUnlockToken() {
        require(transferrable, "Token locked");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalsupply;
    }

    function currentSupply() public view returns (uint256) {
        return _currentsupply;
    }

    function lockStatusOf(address investor) public view returns (bool) {
        return locked[investor];
    }

    function balanceOf(address investor)
        public
        view
        override
        returns (uint256)
    {
        return balances[investor];
    }

    function approve(address _spender, uint256 _amount)
        public
        override
        onlyUnlockToken
        returns (bool)
    {
        require(_spender != address(0), "Address can not be 0x0");
        require(
            balances[msg.sender] >= _amount,
            "Balance does not have enough tokens"
        );
        require(!locked[msg.sender], "Sender address is locked");
        require(!locked[_spender], "Spender address is locked");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _from, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_from][_spender];
    }

    function transfer(address _to, uint256 _amount)
        public
        override
        onlyUnlockToken
        returns (bool)
    {
        require(_to != address(0), "Receiver can not be 0x0");
        require(!locked[msg.sender], "Sender address is locked");
        require(!locked[_to], "Receiver address is locked");
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override onlyUnlockToken returns (bool) {
        require(_to != address(0), "Receiver can not be 0x0");
        require(!locked[_from], "From address is locked");
        require(!locked[_to], "Receiver address is locked");
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function stopTransferToken() external onlyOwner {
        transferrable = true;
        emit ChangeTokenLockStatus(true);
    }

    function startTransferToken() external onlyOwner {
        transferrable = false;
        emit ChangeTokenLockStatus(false);
    }

    function manualMint(uint256 _value) public onlyOwner {
        mint(owner, owner, _value);
    }

    function mint(
        address _from,
        address _receiver,
        uint256 _value
    ) internal {
        require(_receiver != address(0), "Address can not be 0x0");
        require(_value > 0, "Value should larger than 0");
        require(
            _currentsupply.add(_value) <= _totalsupply,
            "Current supply cannot exceed the total supply"
        );
        balances[_receiver] = balances[_receiver].add(_value);
        _currentsupply = _currentsupply.add(_value);
        emit Mint(_from, _receiver, _value);
        emit Transfer(address(0), _receiver, _value);
    }

    function changeEthReceiveWallet(address payable _newWallet)
        external
        onlyOwner
    {
        require(_newWallet != address(0), "Address can not be 0x0");
        ethReceivingWallet = _newWallet;
        emit ChangeReceiveWallet(_newWallet);
    }

    function assignOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address can not be 0x0");
        owner = _newOwner;
        emit ChangeOwnerShip(_newOwner);
    }

    function forwardFunds() external onlyOwner {
        require(ethReceivingWallet != address(0));
        ethReceivingWallet.transfer(address(this).balance);
    }

    function haltTokenTransferFromAddress(address _investor)
        external
        onlyOwner
    {
        locked[_investor] = true;
        emit ChangeLockStatusFrom(_investor, true);
    }

    function resumeTokenTransferFromAddress(address _investor)
        external
        onlyOwner
    {
        locked[_investor] = false;
        emit ChangeLockStatusFrom(_investor, false);
    }

    function burn(uint256 _value) public returns (bool) {
        require(
            balances[msg.sender] >= _value,
            "Balance does not have enough tokens"
        );
        balances[msg.sender] = (balances[msg.sender]).sub(_value);
        _currentsupply = _currentsupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
}
