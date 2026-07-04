// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FeeCollector is Ownable, ReentrancyGuard {

    uint256 public constant BURN_BPS = 500;
    uint256 public constant TOTAL_BPS = 10000;
    address public constant BURN_ADDRESS = address(0);
    uint256 public constant MIN_BURN_INTERVAL = 30 days;

    IERC20 public afrcToken;
    address public treasury;
    uint256 public lastBurnTimestamp;
    uint256 public totalBurned;
    uint256 public totalSentToTreasury;

    mapping(address => bool) public isBurnAuthorized;
    uint256 public requiredAuthorizations;
    uint256 public currentAuthorizations;
    mapping(address => bool) public hasAuthorized;

    event FeesCollected(address indexed from, uint256 amount);
    event MonthlyBurn(uint256 totalCollected, uint256 burnedAmount, uint256 treasuryAmount, uint256 burnRateBps, uint256 timestamp);
    event BurnAuthorized(address indexed authorizer, uint256 currentCount, uint256 required);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    constructor(address _afrcToken, address _treasury, address[] memory _authorized, uint256 _required) Ownable(msg.sender) {
        require(_afrcToken != address(0), "FeeCollector: zero token address");
        require(_treasury != address(0), "FeeCollector: zero treasury address");
        require(_authorized.length >= 3, "FeeCollector: need at least 3 authorized");
        require(_required <= _authorized.length, "FeeCollector: required > authorized");
        require(_required >= 2, "FeeCollector: required must be >= 2");
        afrcToken = IERC20(_afrcToken);
        treasury = _treasury;
        requiredAuthorizations = _required;
        lastBurnTimestamp = block.timestamp;
        for (uint256 i = 0; i < _authorized.length; i++) {
            require(_authorized[i] != address(0), "FeeCollector: zero authorized address");
            require(!isBurnAuthorized[_authorized[i]], "FeeCollector: duplicate authorized");
            isBurnAuthorized[_authorized[i]] = true;
        }
    }

    function collectFees(address from, uint256 amount) external nonReentrant {
        require(amount > 0, "FeeCollector: amount must be > 0");
        require(afrcToken.allowance(from, address(this)) >= amount, "FeeCollector: insufficient allowance");
        require(afrcToken.balanceOf(from) >= amount, "FeeCollector: insufficient balance");
        require(afrcToken.transferFrom(from, address(this), amount), "FeeCollector: transfer failed");
        emit FeesCollected(from, amount);
    }

    function authorizeBurn() external {
        require(isBurnAuthorized[msg.sender], "FeeCollector: not authorized");
        require(!hasAuthorized[msg.sender], "FeeCollector: already authorized");
        require(block.timestamp >= lastBurnTimestamp + MIN_BURN_INTERVAL, "FeeCollector: too early for next burn");
        hasAuthorized[msg.sender] = true;
        currentAuthorizations++;
        emit BurnAuthorized(msg.sender, currentAuthorizations, requiredAuthorizations);
        if (currentAuthorizations >= requiredAuthorizations) _executeBurn();
    }

    function _executeBurn() internal {
        uint256 balance = afrcToken.balanceOf(address(this));
        require(balance > 0, "FeeCollector: nothing to burn");

        uint256 totalSupply = afrcToken.totalSupply();
        uint256 maxSupply = 300_000_000 * 10**18;
        uint256 circulatingPercent = (totalSupply * 10000) / maxSupply;
        uint256 burnBps;
        if (circulatingPercent > 5000) burnBps = 500;
        else if (circulatingPercent > 2500) burnBps = 250;
        else if (circulatingPercent > 1000) burnBps = 100;
        else burnBps = 50;

        uint256 burnAmount = (balance * burnBps) / TOTAL_BPS;
        uint256 treasuryAmount = balance - burnAmount;

        if (burnAmount > 0) {
            require(afrcToken.transfer(BURN_ADDRESS, burnAmount), "FeeCollector: burn transfer failed");
            totalBurned += burnAmount;
        }
        if (treasuryAmount > 0) {
            require(afrcToken.transfer(treasury, treasuryAmount), "FeeCollector: treasury transfer failed");
            totalSentToTreasury += treasuryAmount;
        }

        lastBurnTimestamp = block.timestamp;
        currentAuthorizations = 0;
        emit MonthlyBurn(balance, burnAmount, treasuryAmount, burnBps, block.timestamp);
    }

    function forceBurn() external onlyOwner {
        require(block.timestamp >= lastBurnTimestamp + MIN_BURN_INTERVAL, "FeeCollector: too early");
        _executeBurn();
    }

    function getPendingBalance() external view returns (uint256) {
        return afrcToken.balanceOf(address(this));
    }

    function timeUntilNextBurn() external view returns (uint256) {
        uint256 nextBurnTime = lastBurnTimestamp + MIN_BURN_INTERVAL;
        if (block.timestamp >= nextBurnTime) return 0;
        return nextBurnTime - block.timestamp;
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "FeeCollector: zero treasury address");
        address oldTreasury = treasury;
        treasury = _newTreasury;
        emit TreasuryUpdated(oldTreasury, _newTreasury);
    }
}