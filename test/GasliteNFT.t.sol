pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {GasliteNFT} from "./../src/GasliteNFT.sol";
import {Merkle} from "@murky/Merkle.sol";

contract GasliteNFTTest is Test {
    GasliteNFT nft;
    Merkle whitelistMerkle;

    bytes32 whitelistRoot;
    bytes32[] whitelistData = new bytes32[](2);

    address whitelistMinter = vm.addr(0x2);
    address publicMinter = vm.addr(0x3);

    function setUp() external {
        whitelistMerkle = new Merkle();
        whitelistData[0] = bytes32(keccak256(abi.encodePacked(whitelistMinter)));
        whitelistRoot = whitelistMerkle.getRoot(whitelistData);

        nft = new GasliteNFT("NFT", "NFT", whitelistRoot, 10000, 0.08 ether, 1, 20, 5, "gaslite.org/");
        nft.toggleLive();
    }

    function test_setup() external {
        assertEq(nft.whitelistRoot(), whitelistRoot);
        assertEq(nft.live(), true);
        assertEq(nft.whitelistOpen(), 1);
        assertEq(nft.whitelistClose(), 20);
        assertEq(nft.price(), 0.08 ether);
        assertEq(nft.MAX_SUPPLY(), 10000);
    }

    function test_whitelistMintSuccess() external {
        uint256 price = nft.price();

        payable(whitelistMinter).transfer(price * 5);

        vm.warp(5);
        vm.startPrank(whitelistMinter);

        bytes32[] memory proof = whitelistMerkle.getProof(whitelistData, 0);
        nft.whitelistMint{value: price * 5}(proof, 5);
    }

    function test_whitelistMintFailure() external {
        uint256 price = nft.price();

        payable(whitelistMinter).transfer(10_000 ether);

        vm.warp(5);
        nft.toggleLive();
        vm.startPrank(whitelistMinter);

        // revert not live
        bytes32[] memory proof = whitelistMerkle.getProof(whitelistData, 0);
        vm.expectRevert(GasliteNFT.MintNotLive.selector);
        nft.whitelistMint{value: price * 5}(proof, 5);

        vm.stopPrank();
        nft.toggleLive();
        vm.startPrank(whitelistMinter);

        // revert whitelist mint exceeded
        nft.whitelistMint{value: price * 5}(proof, 5);
        vm.expectRevert(GasliteNFT.WhitelistMintExceeded.selector);
        nft.whitelistMint{value: price * 1}(proof, 1);

        vm.stopPrank();
        vm.startPrank(whitelistMinter);

        // revert whitelist not live
        vm.warp(50);
        vm.expectRevert(GasliteNFT.WhitelistNotLive.selector);
        nft.whitelistMint{value: price * 5}(proof, 5);

        vm.warp(5);

        vm.stopPrank();
        nft.setMaxWhitelistMint(10000);
        vm.startPrank(whitelistMinter);

        // revert insufficient payment
        vm.expectRevert(GasliteNFT.InsufficientPayment.selector);
        nft.whitelistMint{value: price * 4}(proof, 5);

        vm.stopPrank();

        // revert mint unauthorized
        proof = whitelistMerkle.getProof(whitelistData, 1);
        vm.expectRevert(GasliteNFT.WhitelistMintUnauthorized.selector);
        nft.whitelistMint{value: price * 5}(proof, 5);

        vm.startPrank(whitelistMinter);

        // revert supply exceeded
        proof = whitelistMerkle.getProof(whitelistData, 0);
        nft.whitelistMint{value: price * 9000}(proof, 9000);
        vm.expectRevert(GasliteNFT.SupplyExceeded.selector);
        nft.whitelistMint{value: price * 2000}(proof, 2000);
    }

    function test_publicMintSuccess() external {
        uint256 price = nft.price();

        payable(publicMinter).transfer(price * 5);

        vm.warp(60);
        vm.startPrank(publicMinter);

        nft.publicMint{value: price * 5}(5);
    }

    function test_publicMintFailure() external {
        uint256 price = nft.price();
        payable(publicMinter).transfer(10_000 ether);

        vm.warp(5);
        nft.toggleLive();
        vm.startPrank(publicMinter);

        // revert not live
        vm.expectRevert(GasliteNFT.MintNotLive.selector);
        nft.publicMint{value: price * 5}(5);

        vm.stopPrank();
        nft.toggleLive();
        vm.startPrank(publicMinter);

        // revert public mint not live
        vm.warp(10);
        vm.expectRevert(GasliteNFT.PublicMintNotLive.selector);
        nft.publicMint{value: price * 5}(5);

        // revert insufficient payment
        vm.warp(60);
        vm.expectRevert(GasliteNFT.InsufficientPayment.selector);
        nft.publicMint{value: price * 4}(5);

        // revert supply exceeded
        nft.publicMint{value: price * 10_000}(10_000);
        vm.expectRevert(GasliteNFT.SupplyExceeded.selector);
        nft.publicMint{value: price * 5}(5);
    }

    function test_publicMintWithSetPriceSuccess() external {
        nft.setPrice(0.06 ether);

        uint256 price = nft.price();

        assertEq(price, 0.06 ether);

        payable(publicMinter).transfer(price * 5);

        vm.warp(60);
        vm.startPrank(publicMinter);

        nft.publicMint{value: price * 5}(5);
    }

    function test_setWhitelistMindowSuccess() external {
        nft.setWhitelistMintWindow(10, 20);

        assertEq(nft.whitelistOpen(), 10);
        assertEq(nft.whitelistClose(), 20);
    }

    function test_setWhitelistMindowFailure() external {
        vm.expectRevert(GasliteNFT.InvalidWhitelistWindow.selector);
        nft.setWhitelistMintWindow(20, 10);

        vm.expectRevert(GasliteNFT.InvalidWhitelistWindow.selector);
        nft.setWhitelistMintWindow(0, 10);

        vm.expectRevert(GasliteNFT.InvalidWhitelistWindow.selector);
        nft.setWhitelistMintWindow(10, 0);
    }
}
