// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OpenZeppelin/SafeMath.sol";
import "./Oracle.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/Initializable.sol";

contract Affiliate is Initializable {
    using SafeMath for uint256;

    address public owner;
    Oracle public oracle;

    mapping(address => address) affiliateOf;
    mapping(address => address[]) referralsOf;
    mapping(address => mapping(address => uint256)) indexOfReferral;
    mapping(address => uint256) maxNumberOf;
    mapping(address => mapping(address => uint256)) awardsOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
        oracle = Oracle(0xCaEE4A7E30a4780530266138e8facF292FC5353b);
    }

    function getAffiliateOf(address _addr) external view returns (address) {
        return affiliateOf[_addr];
    }

    function increaseNumberAddress(uint256 _numberAddress) external {
        require(_numberAddress > 0);
        IERC20(oracle.getCalAddress()).transferFrom(
            msg.sender,
            address(this),
            _numberAddress.mul(1 ether)
        );
        maxNumberOf[msg.sender] = maxNumberOf[msg.sender].add(_numberAddress);
    }

    function sendTokenAward(
        address[] memory _affiliates,
        uint256[] memory _awards,
        address _currency
    ) external {
        uint256 totalAward = saveAward(_affiliates, _awards, _currency);
        IERC20(_currency).transferFrom(msg.sender, address(this), totalAward);
    }

    function sendEthAward(
        address[] memory _affiliates,
        uint256[] memory _awards
    ) external payable {
        uint256 totalAward = saveAward(_affiliates, _awards, address(0));
        require(totalAward == msg.value);
    }

    function saveAward(
        address[] memory _affiliates,
        uint256[] memory _awards,
        address _currency
    ) internal returns (uint256 _total) {
        uint256 totalAward;
        for (uint256 i = 0; i < _affiliates.length; i++) {
            address _affiliate = _affiliates[i];
            uint256 _award = _awards[i];
            totalAward = totalAward.add(_award);
            awardsOf[_affiliate][_currency] = awardsOf[_affiliate][_currency]
                .add(_award);
        }
        return totalAward;
    }

    function unStake() external {
        uint256 numberAddr = maxNumberOf[msg.sender];
        require(numberAddr > 0);
        maxNumberOf[msg.sender] = 0;
        for (uint256 i = 0; i < referralsOf[msg.sender].length; i++) {
            address addr = referralsOf[msg.sender][i];
            affiliateOf[addr] = address(0);
        }
        delete referralsOf[msg.sender];
        IERC20(oracle.getCalAddress()).transfer(
            msg.sender,
            numberAddr.mul(1 ether)
        );
        address[] memory supportCurrencies = oracle.getSupportCurrencies();
        for (uint256 i = 0; i < supportCurrencies.length; i++) {
            address currency = supportCurrencies[i];
            uint256 award = awardsOf[msg.sender][currency];
            if (award > 0) {
                awardsOf[msg.sender][currency] = 0;
                IERC20(currency).transfer(msg.sender, award);
            }
        }
        uint256 ethAward = awardsOf[msg.sender][address(0)];
        if (ethAward > 0) {
            awardsOf[msg.sender][address(0)] = 0;
            payable(msg.sender).transfer(ethAward);
        }
    }

    function getReward(address _currency) external view returns (uint256) {
        return awardsOf[msg.sender][_currency];
    }

    function saveMultiAddrs(
        address[] memory _addAddrs,
        address[] memory _removeAddrs
    ) external {
        for (uint256 i = 0; i < _addAddrs.length; i++) {
            address _addr = _addAddrs[i];
            addAddress(_addr);
        }

        for (uint256 i = 0; i < _removeAddrs.length; i++) {
            address _addr = _removeAddrs[i];
            remove(msg.sender, _addr);
        }
    }

    function getAffiliateStatus(address[] memory _currencies)
        external
        view
        returns (
            uint256 _maxNumber,
            address[] memory _referrals,
            address _affiliate,
            uint256[] memory _awards
        )
    {
        _maxNumber = maxNumberOf[msg.sender];
        _referrals = referralsOf[msg.sender];
        _affiliate = affiliateOf[msg.sender];
        uint256[] memory _tempAwards = new uint256[](_currencies.length);
        for (uint256 i = 0; i < _currencies.length; i++) {
            address _currency = _currencies[i];
            _tempAwards[i] = awardsOf[msg.sender][_currency];
        }
        _awards = _tempAwards;
    }

    function addAddress(address _addr) public {
        require(affiliateOf[_addr] == address(0), "This address has affiliate");
        require(msg.sender != _addr, "Can not add yourself");
        affiliateOf[_addr] = msg.sender;
        indexOfReferral[msg.sender][_addr] = referralsOf[msg.sender].length;
        referralsOf[msg.sender].push(_addr);
        require(
            referralsOf[msg.sender].length <= maxNumberOf[msg.sender],
            "Over your max referrals."
        );
    }

    function removeAddress(address _addr) external {
        remove(msg.sender, _addr);
    }

    function removeAffiliate() external {
        address _affiliate = affiliateOf[msg.sender];
        require(_affiliate != address(0));
        remove(_affiliate, msg.sender);
    }

    function remove(address _affiliate, address _addr) internal {
        require(
            _affiliate == affiliateOf[_addr] &&
                referralsOf[_affiliate].length > 0
        );
        affiliateOf[_addr] = address(0);
        uint256 index = indexOfReferral[_affiliate][_addr];
        uint256 lastIndex = referralsOf[_affiliate].length - 1;
        address lastAddr = referralsOf[_affiliate][lastIndex];
        referralsOf[_affiliate][index] = lastAddr;
        indexOfReferral[_affiliate][lastAddr] = index;
        referralsOf[_affiliate].pop();
    }

    function changeOracle(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        oracle = Oracle(_newAddress);
    }
}
