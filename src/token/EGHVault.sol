// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/**
 * @title EGHVault
 * @author Jeremy N.
 * @notice Minimal ERC-4626 tokenized vault for a single underlying ERC-20 asset
 * @dev Users deposit assets and receive vault shares. Shares can be redeemed for assets.
 *      Uses OpenZeppelin ERC4626 base with virtual shares/assets for inflation attack protection.
 */
contract EGHVault is ERC4626 {
    constructor(IERC20 asset_, string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        ERC4626(asset_)
    { }
}
