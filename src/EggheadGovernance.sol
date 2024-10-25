//SPX-License-Identifier: MIT
pragma solidity 0.8.24;

import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {BOOTLOADER_FORMAL_ADDRESS} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from
    "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Governance contract for Egghead
/// @author Jeremy N.
/// @notice You can use this contract for only the most basic simulation
/// @custom:experimental This is an experimental contract.
contract EggheadGovernance is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;

    // Governance Structures
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        address proposer;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public nextProposalId;

    event ProposalCreated(uint256 proposalId, string name, string description, address indexed proposer);
    event Voted(uint256 proposalId, bool support, address indexed voter);
    event ProposalExecuted(uint256 proposalId);

    modifier requireFromBootLoader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert("Not from BootLoader");
        }
        _;
    }

    modifier requireFromBootLoaderOrOwner() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS && msg.sender != owner()) {
            revert("Not from BootLoader or Owner");
        }
        _;
    }

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Create a new proposal
    /// @param title is the name of the proposal
    /// @param description is the description of the proposal
    /// @param votingDuration is the duration of the voting period
    function createProposal(string memory title, string memory description, uint256 votingDuration)
        external
        onlyOwner
    {
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            title: title,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + votingDuration,
            executed: false,
            proposer: msg.sender
        });

        emit ProposalCreated(nextProposalId, title, description, msg.sender);
        nextProposalId++;
    }

    /// @notice Vote on a proposal
    /// @param proposalId is the id of the proposal
    /// @param support is the vote for or against the proposal
    function voteOnProposal(uint256 proposalId, bool support) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 votingPower = 1;
        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        hasVoted[proposalId][msg.sender] = true;
        emit Voted(proposalId, support, msg.sender);
    }

    /// @notice Execute a proposal
    /// @param proposalId is the id of the proposal
    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Logic to execute the proposal
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
}
