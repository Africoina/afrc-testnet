// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract AFRCToken is ERC20, ERC20Permit, ERC20Burnable, Ownable, Pausable {

    uint256 public constant MAX_SUPPLY = 300_000_000 * 10**18;
    address public constant BURN_ADDRESS = address(0);
    mapping(address => bool) public isBlacklisted;
    uint256 public pauseActivatedAt;
    uint256 public constant MAX_PAUSE_DURATION = 72 hours;

    event BlacklistUpdated(address indexed account, bool status);
    event FeeBurned(address indexed from, uint256 amount, string feeType);
    event EmergencyPauseActivated(uint256 timestamp, string reason);

    constructor() 
        ERC20("AFR!COIN", "AFRC") 
        ERC20Permit("AFR!COIN") 
        Ownable(msg.sender) 
    {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function burnTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "AFRC: amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "AFRC: insufficient balance");
        _burn(msg.sender, amount);
        emit FeeBurned(msg.sender, amount, "protocol");
    }

    function burnFrom(address from, uint256 amount) public override onlyOwner {
        require(!isBlacklisted[from], "AFRC: account blacklisted");
        require(amount > 0, "AFRC: amount must be > 0");
        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= amount, "AFRC: insufficient allowance");
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        emit FeeBurned(from, amount, "PNP");
    }

    function activateEmergencyPause(string calldata reason) external onlyOwner {
        require(!paused(), "AFRC: already paused");
        _pause();
        pauseActivatedAt = block.timestamp;
        emit EmergencyPauseActivated(block.timestamp, reason);
    }

    function deactivateEmergencyPause() external onlyOwner {
        require(paused(), "AFRC: not paused");
        _unpause();
    }

    function governanceExtendPause() external onlyOwner {
        require(paused(), "AFRC: not paused");
        pauseActivatedAt = block.timestamp;
    }

    function setBlacklist(address account, bool status) external onlyOwner {
        require(account != address(0), "AFRC: zero address");
        require(account != owner(), "AFRC: cannot blacklist owner");
        isBlacklisted[account] = status;
        emit BlacklistUpdated(account, status);
    }

    function _update(address from, address to, uint256 value) internal override {
        require(!paused(), "AFRC: transfers paused");
        require(!isBlacklisted[from], "AFRC: sender blacklisted");
        require(!isBlacklisted[to], "AFRC: recipient blacklisted");
        super._update(from, to, value);
    }

    function pauseTimeRemaining() external view returns (uint256) {
        if (!paused()) return 0;
        uint256 elapsed = block.timestamp - pauseActivatedAt;
        if (elapsed >= MAX_PAUSE_DURATION) return 0;
        return MAX_PAUSE_DURATION - elapsed;
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(BURN_ADDRESS);
    }
}
