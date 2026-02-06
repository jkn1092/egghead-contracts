// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EGH
 * @author Jeremy N.
 * @notice A complete ERC-20 token implementation with mint, transfer, approve, transferFrom, and allowance
 * functionality
 * @dev All ERC-20 standard functions are implemented. Transfer and Approval events are emitted automatically.
 */
contract EGH is ERC20, Ownable {
    error EGH__MustBeMoreThanZero();
    error EGH__NotZeroAddress();
    error EGH__MintAmountExceedsMaxSupply();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens
    uint8 public constant DECIMALS = 18; // Standard ERC-20 decimals

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when tokens are minted
     * @param to The address that received the minted tokens
     * @param amount The amount of tokens minted
     */
    event TokensMinted(address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert EGH__MustBeMoreThanZero();
        }
        _;
    }

    modifier notZeroAddress(address account) {
        if (account == address(0)) {
            revert EGH__NotZeroAddress();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) { }

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns the number of decimals used to get its user representation
     * @dev ERC-20 standard function. Returns 18 by default.
     * @return The number of decimals
     */
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @notice Returns the amount of tokens that an owner allowed to a spender
     * @dev ERC-20 standard function
     * @param owner The address which owns the funds
     * @param spender The address which will spend the funds
     * @return The amount of tokens still available for the spender
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return super.allowance(owner, spender);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Mints tokens to a specified address
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     * @return success Returns true if minting was successful
     */
    function mint(
        address to,
        uint256 amount
    )
        external
        onlyOwner
        moreThanZero(amount)
        notZeroAddress(to)
        returns (bool success)
    {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert EGH__MintAmountExceedsMaxSupply();
        }
        _mint(to, amount);
        emit TokensMinted(to, amount);
        return true;
    }

    /**
     * @notice Transfer tokens from the caller to a recipient
     * @dev Inherited from ERC20, available for use
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @return success Returns true if transfer was successful
     */
    function transfer(address to, uint256 amount) public override returns (bool success) {
        return super.transfer(to, amount);
    }

    /**
     * @notice Approve a spender to transfer tokens on behalf of the caller
     * @dev ERC-20 standard function. Emits an Approval event.
     * @param spender The address to approve
     * @param amount The amount of tokens to approve
     * @return success Returns true if approval was successful
     */
    function approve(address spender, uint256 amount) public override returns (bool success) {
        return super.approve(spender, amount);
    }

    /**
     * @notice Transfer tokens from one address to another using an allowance
     * @dev ERC-20 standard function. The caller must have sufficient allowance.
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @return success Returns true if transfer was successful
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool success) {
        return super.transferFrom(from, to, amount);
    }
}
