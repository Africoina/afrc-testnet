// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PNPRegistry is Ownable, ReentrancyGuard {

    struct NameRecord {
        address owner;
        uint256 registeredAt;
        uint256 expiresAt;
        bool exists;
    }

    IERC20 public afrcToken;
    address public treasury;

    mapping(bytes32 => NameRecord) private _records;

    uint256 public constant DEFAULT_DURATION = 365 days;
    uint256 public constant GRACE_PERIOD = 90 days;
    uint256 public shortNameFee = 100 * 10**18;
    uint256 public basicNameFee = 0;

    event NameRegistered(bytes32 indexed nameHash, string name, address indexed owner, uint256 expiresAt);
    event NameRenewed(bytes32 indexed nameHash, uint256 newExpiresAt);
    event NameTransferred(bytes32 indexed nameHash, address indexed from, address indexed to);

    constructor(address _afrcToken, address _treasury) Ownable(msg.sender) {
        require(_afrcToken != address(0), "PNP: zero token address");
        require(_treasury != address(0), "PNP: zero treasury address");
        afrcToken = IERC20(_afrcToken);
        treasury = _treasury;
    }

    function register(string calldata name) external nonReentrant {
        bytes32 nameHash = _hash(name);
        require(!_isActive(nameHash), "PNP: name already registered");
        require(_isValid(name), "PNP: invalid name");

        uint256 fee = _getFee(name);
        if (fee > 0) {
            require(afrcToken.transferFrom(msg.sender, address(this), fee), "PNP: fee transfer failed");
            uint256 burnAmount = fee / 2;
            uint256 treasuryAmount = fee - burnAmount;
            if (burnAmount > 0) afrcToken.transfer(address(0), burnAmount);
            if (treasuryAmount > 0) afrcToken.transfer(treasury, treasuryAmount);
        }

        uint256 expiresAt = block.timestamp + DEFAULT_DURATION;
        _records[nameHash] = NameRecord({owner: msg.sender, registeredAt: block.timestamp, expiresAt: expiresAt, exists: true});
        emit NameRegistered(nameHash, name, msg.sender, expiresAt);
    }

    function ownerOf(string calldata name) external view returns (address) {
        bytes32 nameHash = _hash(name);
        require(_records[nameHash].exists, "PNP: name not registered");
        require(_isActive(nameHash), "PNP: name expired");
        return _records[nameHash].owner;
    }

    function isActive(string calldata name) external view returns (bool) {
        return _isActive(_hash(name));
    }

    function isAvailable(string calldata name) external view returns (bool) {
        return !_isActive(_hash(name));
    }

    function _isActive(bytes32 nameHash) internal view returns (bool) {
        NameRecord storage record = _records[nameHash];
        return record.exists && block.timestamp <= record.expiresAt + GRACE_PERIOD;
    }

    function _getFee(string memory name) internal view returns (uint256) {
        uint256 len = bytes(name).length;
        if (len <= 3) return shortNameFee * 10;
        if (len <= 6) return shortNameFee;
        return basicNameFee;
    }

    function _isValid(string memory name) internal pure returns (bool) {
        uint256 len = bytes(name).length;
        if (len < 3 || len > 64) return false;
        bytes memory b = bytes(name);
        for (uint256 i = 0; i < len; i++) {
            bytes1 char = b[i];
            if ((char >= 0x30 && char <= 0x39) || (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A) || char == 0x2D || char == 0x5F) continue;
            return false;
        }
        return true;
    }

    function _hash(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }
}