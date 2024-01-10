pragma solidity 0.8.20;

// forgefmt: disable-start
/**
 *                                                           bbbbbbbb                                         dddddddd
 *                                                           b::::::b                                         d::::::d
 *                                                           b::::::b                                         d::::::d
 *                                                           b::::::b                                         d::::::d
 *                                                            b:::::b                                         d:::::d
 *    ggggggggg   ggggg aaaaaaaaaaaaa      ssssssssss         b:::::bbbbbbbbb      aaaaaaaaaaaaa      ddddddddd:::::d
 *   g:::::::::ggg::::g a::::::::::::a   ss::::::::::s        b::::::::::::::bb    a::::::::::::a   dd::::::::::::::d
 *  g:::::::::::::::::g aaaaaaaaa:::::ass:::::::::::::s       b::::::::::::::::b   aaaaaaaaa:::::a d::::::::::::::::d
 * g::::::ggggg::::::gg          a::::as::::::ssss:::::s      b:::::bbbbb:::::::b           a::::ad:::::::ddddd:::::d
 * g:::::g     g:::::g    aaaaaaa:::::a s:::::s  ssssss       b:::::b    b::::::b    aaaaaaa:::::ad::::::d    d:::::d
 * g:::::g     g:::::g  aa::::::::::::a   s::::::s            b:::::b     b:::::b  aa::::::::::::ad:::::d     d:::::d
 * g:::::g     g:::::g a::::aaaa::::::a      s::::::s         b:::::b     b:::::b a::::aaaa::::::ad:::::d     d:::::d
 * g::::::g    g:::::ga::::a    a:::::assssss   s:::::s       b:::::b     b:::::ba::::a    a:::::ad:::::d     d:::::d
 * g:::::::ggggg:::::ga::::a    a:::::as:::::ssss::::::s      b:::::bbbbbb::::::ba::::a    a:::::ad::::::ddddd::::::dd
 *  g::::::::::::::::ga:::::aaaa::::::as::::::::::::::s       b::::::::::::::::b a:::::aaaa::::::a d:::::::::::::::::d
 *   gg::::::::::::::g a::::::::::aa:::as:::::::::::ss        b:::::::::::::::b   a::::::::::aa:::a d:::::::::ddd::::d
 *     gggggggg::::::g  aaaaaaaaaa  aaaa sssssssssss          bbbbbbbbbbbbbbbb     aaaaaaaaaa  aaaa  ddddddddd   ddddd
 *             g:::::g
 * gggggg      g:::::g
 * g:::::gg   gg:::::g
 *  g::::::ggg:::::::g
 *   gg:::::::::::::g
 *     ggg::::::ggg
 *        gggggg
 */
// forgefmt: disable-end

import "@ERC721A/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "solady/src/utils/MerkleProofLib.sol";
import {LibString} from "solady/src/utils/LibString.sol";

/// @title GasliteNFT
/// @notice Turbo gas optimized NFT contract
/// @author Harrison (@PopPunkOnChain)
/// @author Gaslite (@GasliteGG)
contract GasliteNFT is ERC721A, Ownable2Step {
    bytes32 public whitelistRoot;
    uint256 public immutable MAX_SUPPLY;
    uint120 public price;
    uint120 public whitelistPrice;
    bool public live;
    uint64 public maxWhitelistMint;
    uint64 public maxPublicMint;
    uint64 public whitelistOpen;
    uint64 public whitelistClose;
    string private _baseURIString;

    error MintNotLive();
    error WhitelistNotLive();
    error MintExceeded();
    error PublicMintNotLive();
    error WhitelistMintUnauthorized();
    error SupplyExceeded();
    error InsufficientPayment();
    error InvalidWhitelistWindow();
    error TokenDoesNotExist();

    /// @notice Constructor
    /// @param _name Name of the NFT
    /// @param _ticker Ticker of the NFT
    /// @param _whitelistRoot Merkle root of the whitelist
    /// @param _maxSupply Maximum supply of the NFT
    /// @param _price Price of the NFT
    /// @param _whitelistOpen Timestamp of when the whitelist opens
    /// @param _whitelistClose Timestamp of when the whitelist closes
    /// @param _maxWhitelistMint Max whitelist mint
    /// @param _uri Base URI of the NFT
    constructor(
        string memory _name,
        string memory _ticker,
        bytes32 _whitelistRoot,
        uint256 _maxSupply,
        uint120 _price,
        uint120 _whitelistPrice,
        uint64 _whitelistOpen,
        uint64 _whitelistClose,
        uint64 _maxWhitelistMint,
        uint64 _maxPublicMint,
        string memory _uri
    ) ERC721A(_name, _ticker) Ownable(msg.sender) {
        whitelistRoot = _whitelistRoot;
        MAX_SUPPLY = _maxSupply;
        price = _price;
        whitelistPrice = _whitelistPrice;
        whitelistOpen = _whitelistOpen;
        whitelistClose = _whitelistClose;
        _baseURIString = _uri;
        maxWhitelistMint = _maxWhitelistMint;
        maxPublicMint = _maxPublicMint;
    }

    /// @notice Mint NFTs from the whitelist
    /// @param _proof Merkle proof of the address
    /// @param _amount Amount of NFTs to mint
    function whitelistMint(bytes32[] calldata _proof, uint256 _amount) external payable {
        if (!live) revert MintNotLive();
        if (block.timestamp < whitelistOpen) revert WhitelistNotLive();
        if (block.timestamp > whitelistClose) revert WhitelistNotLive();
        uint256 minted = _numberMinted(msg.sender) + _amount;
        if (minted > maxWhitelistMint) revert MintExceeded();
        if (_totalMinted() + _amount > MAX_SUPPLY) revert SupplyExceeded();
        if (!MerkleProofLib.verify(_proof, whitelistRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert WhitelistMintUnauthorized();
        }
        if (msg.value != _amount * price) revert InsufficientPayment();

        _mint(msg.sender, _amount);
    }

    /// @notice Mint NFTs from the public mint
    /// @param _amount Amount of NFTs to mint
    function publicMint(uint256 _amount) external payable {
        if (!live) revert MintNotLive();
        if (block.timestamp < whitelistClose) revert PublicMintNotLive();
        uint256 minted = _numberMinted(msg.sender) + _amount;
        if (minted > maxPublicMint) revert MintExceeded();
        if (_totalMinted() + _amount > MAX_SUPPLY) revert SupplyExceeded();
        if (msg.value != _amount * price) revert InsufficientPayment();

        _mint(msg.sender, _amount);
    }

    /// @notice Set the prices of each NFT
    /// @dev Only the owner can call this function
    /// @param _price Price of each NFT
    /// @param _whitelistPrice Price of each whitelist NFT
    function setPrices(uint120 _price, uint120 _whitelistPrice) external onlyOwner {
        price = _price;
        whitelistPrice = _whitelistPrice;
    }

    /// @notice Toggle the minting to live or not
    /// @dev Only the owner can call this function
    function toggleLive() external onlyOwner {
        live = !live;
    }

    /// @notice Set the whitelist root
    /// @dev Only the owner can call this function
    /// @param _whitelistRoot Merkle root of the whitelist
    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    /// @notice Set the whitelist minting window
    /// @dev Only the owner can call this function
    /// @param _whitelistOpen Timestamp of when the whitelist opens
    /// @param _whitelistClose Timestamp of when the whitelist closes
    function setWhitelistMintWindow(uint64 _whitelistOpen, uint64 _whitelistClose) external onlyOwner {
        if (_whitelistOpen > _whitelistClose) revert InvalidWhitelistWindow();
        if (_whitelistOpen == 0) revert InvalidWhitelistWindow();
        if (_whitelistClose == 0) revert InvalidWhitelistWindow();

        whitelistOpen = _whitelistOpen;
        whitelistClose = _whitelistClose;
    }

    /// @notice Set the max whitelist mint
    /// @dev Only the owner can call this function
    /// @param _maxWhitelistMint Max whitelist mint
    /// @param _maxPublcMint Max public mint
    function setMaxMints(uint64 _maxWhitelistMint, uint64 _maxPublcMint) external onlyOwner {
        maxWhitelistMint = _maxWhitelistMint;
        maxPublicMint = _maxPublcMint;
    }

    /// @notice Set the base URI
    /// @dev Only the owner can call this function
    /// @param _uri Base URI of the NFT
    function setBaseUri(string calldata _uri) external onlyOwner {
        _baseURIString = _uri;
    }

    /// @notice Get the base URI
    /// @return Base URI of the NFT
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        string memory baseURI = _baseURIString;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, LibString.toString(tokenId))) : "";
    }

    /// @notice Withdraw the contract balance
    /// @dev Only the owner can call this function
    function withdraw() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}
