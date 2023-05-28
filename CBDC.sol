// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CBDC is ERC20 {
    address public controllingParty;
    uint public interestRateBasisPoints = 500;
    mapping(address => bool) public blacklist;
    mapping(address => uint) private stakedTreasuryBond;
    mapping(address => uint) private stakedFromTS;
    event UpdateControllingParty(
        address oldControllingParty,
        address newControllingParty
    );
    event UpdateInterestRate(uint oldInterest, uint newInterestRage);
    event IncreaseMoneySupply(uint oldMoneySupply, uint inflationAmount);
    event UpdateBlacklist(address criminal, bool blocked);
    event StakeTreasuryBonds(address user, uint amount);
    event UnstakeTreasuryBonds(address user, uint amount);
    event ClaimTreasuryBonds(address user, uint amount);

    constructor(
        address _controllingParty,
        uint initialSupply
    ) ERC20("Central Bank Digital Currency", "CBDC") {
        controllingParty = _controllingParty;
        _mint(controllingParty, initialSupply);
    }

    function updateControlParty(address newControllingParty) external {
        require(msg.sender == controllingParty, "Not controlling party");
        controllingParty = newControllingParty;
        _transfer(
            controllingParty,
            newControllingParty,
            balanceOf(controllingParty)
        );
        emit UpdateControllingParty(msg.sender, newControllingParty);
    }

    function updateInterestRate(uint newInterestRateBasisPoints) external {
        require(msg.sender == controllingParty, "Not controlling party");
        uint oldInterestRateBasisPoint = interestRateBasisPoints;
        interestRateBasisPoints = newInterestRateBasisPoints;
        emit UpdateInterestRate(
            oldInterestRateBasisPoint,
            newInterestRateBasisPoints
        );
    }

    function increaseMoneySupply(uint inflationAmount) external {
        require(msg.sender == controllingParty, "Not controlling party");
        uint oldMoneySupply = totalSupply();
        _mint(msg.sender, inflationAmount);
        emit IncreaseMoneySupply(oldMoneySupply, inflationAmount);
    }

    function updateBlacklist(address criminal, bool blacklisted) external {
        require(msg.sender == controllingParty, "Not controlling party");
        blacklist[criminal] = blacklisted;
        emit UpdateBlacklist(criminal, blacklisted);
    }

    function stakeTreasuryBonds(uint amount) external {
        require(amount > 0, "amount is <= 0");
        require(balanceOf(msg.sender) >= amount, "balance is <= amount");
        _transfer(msg.sender, address(this), amount);
        if (stakedTreasuryBond[msg.sender] > 0) claimTreasuryBonds();
        stakedFromTS[msg.sender] = block.timestamp;
        stakedTreasuryBond[msg.sender] += amount;
        emit StakeTreasuryBonds(msg.sender, amount);
    }

    function unstakeTreasuryBonds(uint amount) external {
        require(amount > 0, "amount is <= 0");
        require(stakedTreasuryBond[msg.sender] >= amount, "amount is > staked");
        claimTreasuryBonds();
        stakedTreasuryBond[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
        emit UnstakeTreasuryBonds(msg.sender, amount);
    }

    function claimTreasuryBonds() public {
        require(stakedTreasuryBond[msg.sender] > 0, "stacked is <= 0");
        uint secondsStaked = block.timestamp - stakedFromTS[msg.sender];
        // 3.154e7 is seconds in a year
        uint rewards = (stakedTreasuryBond[msg.sender] *
            secondsStaked *
            interestRateBasisPoints) / (10000 * 3.154e7);
        stakedFromTS[msg.sender] = block.timestamp;
        _mint(msg.sender, rewards);
        emit ClaimTreasuryBonds(msg.sender, rewards);
    }

    function _transfer(
        address from,
        address to,
        uint amount
    ) internal virtual override {
        require(blacklist[from] == false, "Sender address is blacklisted");
        require(blacklist[to] == false, "receipient address is blacklisted");
        super._transfer(from, to, amount);
    }
}
