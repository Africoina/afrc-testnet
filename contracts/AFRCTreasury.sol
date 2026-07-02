// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AFRCTreasury is Ownable, ReentrancyGuard {

    struct Transaction {
        address destination;
        uint256 amount;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 timestamp;
    }

    IERC20 public afrcToken;
    address[] public signers;
    mapping(address => bool) public isSigner;
    uint256 public required;
    uint256 public constant MIN_TIMELOCK = 48 hours;
    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    event TransactionSubmitted(uint256 indexed txId, address indexed destination, uint256 amount);
    event TransactionConfirmed(uint256 indexed txId, address indexed signer);
    event TransactionExecuted(uint256 indexed txId);

    modifier onlySigner() {
        require(isSigner[msg.sender], "Treasury: not a signer");
        _;
    }

    modifier transactionExists(uint256 txId) {
        require(txId < transactionCount, "Treasury: tx does not exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Treasury: tx already executed");
        _;
    }

    modifier notConfirmed(uint256 txId) {
        require(!confirmations[txId][msg.sender], "Treasury: tx already confirmed");
        _;
    }

    constructor(address _afrcToken, address[] memory _signers, uint256 _required) Ownable(msg.sender) {
        require(_afrcToken != address(0), "Treasury: zero token address");
        require(_signers.length >= 3, "Treasury: need at least 3 signers");
        require(_required <= _signers.length, "Treasury: required > signers");
        require(_required >= 2, "Treasury: required must be >= 2");
        afrcToken = IERC20(_afrcToken);
        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0), "Treasury: zero signer address");
            require(!isSigner[signer], "Treasury: duplicate signer");
            isSigner[signer] = true;
            signers.push(signer);
        }
        required = _required;
    }

    function submitTransaction(address destination, uint256 amount) external onlySigner returns (uint256 txId) {
        require(destination != address(0), "Treasury: zero destination");
        txId = transactionCount;
        transactions[txId] = Transaction({destination: destination, amount: amount, data: "", executed: false, confirmations: 0, timestamp: block.timestamp});
        transactionCount++;
        emit TransactionSubmitted(txId, destination, amount);
    }

    function confirmTransaction(uint256 txId) external onlySigner transactionExists(txId) notExecuted(txId) notConfirmed(txId) {
        confirmations[txId][msg.sender] = true;
        transactions[txId].confirmations++;
        emit TransactionConfirmed(txId, msg.sender);
        if (isConfirmed(txId)) _executeTransaction(txId);
    }

    function _executeTransaction(uint256 txId) internal nonReentrant {
        Transaction storage txn = transactions[txId];
        require(block.timestamp >= txn.timestamp + MIN_TIMELOCK, "Treasury: timelock not over");
        txn.executed = true;
        require(afrcToken.transfer(txn.destination, txn.amount), "Treasury: transfer failed");
        emit TransactionExecuted(txId);
    }

    function isConfirmed(uint256 txId) public view returns (bool) {
        return transactions[txId].confirmations >= required;
    }

    function getSignerCount() external view returns (uint256) {
        return signers.length;
    }
}