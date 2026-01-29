// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EGH
 * @author Jeremy N.
 * @notice A basic ERC-20 token implementation with mint, transfer, and approve functionality
 * @dev Transfer and approve are inherited from OpenZeppelin's ERC20 implementation
 */
contract EGH is ERC20, Ownable {
    error EGH__MustBeMoreThanZero();
    error EGH__NotZeroAddress();
    error EGH__MintAmountExceedsMaxSupply();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens

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
     * @dev Inherited from ERC20, available for use
     * @param spender The address to approve
     * @param amount The amount of tokens to approve
     * @return success Returns true if approval was successful
     */
    function approve(address spender, uint256 amount) public override returns (bool success) {
        return super.approve(spender, amount);
    }
}
