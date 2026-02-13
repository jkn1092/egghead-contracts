// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EGHNFT
 * @author Jeremy N.
 * @notice A complete ERC-721 NFT implementation with mint, transfer, approval, and tokenURI
 * functionality
 * @dev All ERC-721 standard functions are implemented. Transfer and Approval events are emitted automatically.
 */
contract EGHNFT is ERC721, Ownable {
    error EGHNFT__NotZeroAddress();
    error EGHNFT__TokenDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private s_tokenCounter;
    mapping(uint256 => string) private s_tokenURIs;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when a new token is minted
     * @param to The address that received the minted token
     * @param tokenId The ID of the minted token
     */
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier notZeroAddress(address account) {
        if (account == address(0)) {
            revert EGHNFT__NotZeroAddress();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        s_tokenCounter = 0;
    }

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns the total number of tokens minted
     * @return The current token counter
     */
    function totalSupply() public view returns (uint256) {
        return s_tokenCounter;
    }

    /**
     * @notice Returns the token URI for a given token ID
     * @param tokenId The ID of the token
     * @return The token URI string
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ownerOf(tokenId); // This will revert if token doesn't exist
        return s_tokenURIs[tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Mints a new NFT token to a specified address
     * @param to The address to mint the token to
     * @param tokenURI_ The URI for the token metadata
     * @return tokenId The ID of the newly minted token
     */
    function mint(address to, string memory tokenURI_) external onlyOwner notZeroAddress(to) returns (uint256) {
        uint256 tokenId = s_tokenCounter;
        s_tokenCounter++;
        _safeMint(to, tokenId);
        s_tokenURIs[tokenId] = tokenURI_;
        emit TokenMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @notice Transfers a token from the caller to a recipient
     * @param to The address to transfer the token to
     * @param tokenId The ID of the token to transfer
     */
    function transfer(address to, uint256 tokenId) external notZeroAddress(to) {
        transferFrom(msg.sender, to, tokenId);
    }

    /**
     * @notice Transfers a token from one address to another (requires approval)
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param tokenId The ID of the token to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) notZeroAddress(to) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Approves an address to transfer a specific token
     * @param to The address to approve
     * @param tokenId The ID of the token to approve
     */
    function approve(address to, uint256 tokenId) public override(ERC721) {
        super.approve(to, tokenId);
    }

    /**
     * @notice Approves or revokes approval for an operator to manage all tokens of the caller
     * @param operator The address of the operator
     * @param approved True to approve, false to revoke
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Sets the token URI for a given token ID (only owner)
     * @param tokenId The ID of the token
     * @param tokenURI_ The new URI for the token
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI_) external onlyOwner {
        ownerOf(tokenId); // This will revert if token doesn't exist
        s_tokenURIs[tokenId] = tokenURI_;
    }
}
