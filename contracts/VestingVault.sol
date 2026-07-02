// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VestingVault is Ownable, ReentrancyGuard {

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffDuration1;
        uint256 vestDuration1;
        uint256 cliffDuration2;
        uint256 vestDuration2;
        uint256 cliffDuration3;
        uint256 vestDuration3;
        bool active;
    }

    uint256 public constant TRANCHE1_BPS = 4000;
    uint256 public constant TRANCHE2_BPS = 4000;
    uint256 public constant TRANCHE3_BPS = 2000;

    IERC20 public afrcToken;
    mapping(address => VestingSchedule) public schedules;
    address[] public beneficiaries;
    uint256 public totalAllocated;

    event ScheduleCreated(address indexed beneficiary, uint256 totalAmount, uint256 startTime);
    event TokensClaimed(address indexed beneficiary, uint256 amount);
    event ScheduleRevoked(address indexed beneficiary, uint256 unvestedAmount);

    constructor(address _afrcToken) Ownable(msg.sender) {
        require(_afrcToken != address(0), "VestingVault: zero address");
        afrcToken = IERC20(_afrcToken);
    }

    function createSchedule(address beneficiary, uint256 totalAmount) external onlyOwner {
        require(beneficiary != address(0), "VestingVault: zero address");
        require(!schedules[beneficiary].active, "VestingVault: schedule exists");
        require(totalAmount > 0, "VestingVault: amount must be > 0");

        schedules[beneficiary] = VestingSchedule({
            totalAmount: totalAmount,
            claimedAmount: 0,
            startTime: block.timestamp,
            cliffDuration1: 365 days,
            vestDuration1: 1460 days,
            cliffDuration2: 730 days,
            vestDuration2: 2190 days,
            cliffDuration3: 1460 days,
            vestDuration3: 2920 days,
            active: true
        });

        beneficiaries.push(beneficiary);
        totalAllocated += totalAmount;
        emit ScheduleCreated(beneficiary, totalAmount, block.timestamp);
    }

    function claim() external nonReentrant {
        uint256 claimable = getClaimableAmount(msg.sender);
        require(claimable > 0, "VestingVault: nothing to claim");
        schedules[msg.sender].claimedAmount += claimable;
        require(afrcToken.transfer(msg.sender, claimable), "VestingVault: transfer failed");
        emit TokensClaimed(msg.sender, claimable);
    }

    function getClaimableAmount(address beneficiary) public view returns (uint256 total) {
        VestingSchedule memory s = schedules[beneficiary];
        if (!s.active) return 0;
        uint256 vested = getVestedAmount(beneficiary);
        if (vested <= s.claimedAmount) return 0;
        return vested - s.claimedAmount;
    }

    function getVestedAmount(address beneficiary) public view returns (uint256 total) {
        VestingSchedule memory s = schedules[beneficiary];
        if (!s.active) return 0;
        uint256 elapsed = block.timestamp - s.startTime;
        total += _calculateTranche(s.totalAmount, TRANCHE1_BPS, elapsed, s.cliffDuration1, s.vestDuration1);
        total += _calculateTranche(s.totalAmount, TRANCHE2_BPS, elapsed, s.cliffDuration2, s.vestDuration2);
        total += _calculateTranche(s.totalAmount, TRANCHE3_BPS, elapsed, s.cliffDuration3, s.vestDuration3);
        return total;
    }

    function _calculateTranche(uint256 totalAmount, uint256 bps, uint256 elapsed, uint256 cliff, uint256 vestDuration) internal pure returns (uint256) {
        if (elapsed <= cliff) return 0;
        uint256 trancheAmount = (totalAmount * bps) / 10000;
        uint256 vestingElapsed = elapsed - cliff;
        if (vestingElapsed >= vestDuration) return trancheAmount;
        return (trancheAmount * vestingElapsed) / vestDuration;
    }

    function getSchedule(address beneficiary) external view returns (VestingSchedule memory) {
        return schedules[beneficiary];
    }

    function revokeSchedule(address beneficiary) external onlyOwner {
        VestingSchedule storage s = schedules[beneficiary];
        require(s.active, "VestingVault: schedule not active");
        uint256 vested = getVestedAmount(beneficiary);
        uint256 unvested = s.totalAmount - vested;
        s.active = false;
        s.totalAmount = vested;
        totalAllocated -= unvested;
        emit ScheduleRevoked(beneficiary, unvested);
    }
}