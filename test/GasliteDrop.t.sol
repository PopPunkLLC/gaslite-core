pragma solidity 0.8.20;

import {GasliteDrop} from "./../src/GasliteDrop.sol";
import {NFT} from "./../test/utils/NFT.sol";
import {Token} from "./../test/utils/Token.sol";
import "forge-std/Test.sol";

contract GasliteDropTest is Test {
    GasliteDrop gasliteDrop;
    NFT nft;
    Token token;
    address user = vm.addr(0x1);
    uint256 quantity = 1000;
    uint256 value = quantity * 0.001 ether;

    function setUp() public {
        nft = new NFT();
        token = new Token();
        token.transfer(user, quantity);
        gasliteDrop = new GasliteDrop();
    }

    function test_airdropERC721() public {
        vm.startPrank(user);
        nft.batchMint(address(user), quantity);

        uint256[] memory tokenIds = new uint256[](quantity);
        address[] memory recipients = new address[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = i;
            recipients[i] = vm.addr(2);
        }

        nft.setApprovalForAll(address(gasliteDrop), true);
        gasliteDrop.airdropERC721(address(nft), recipients, tokenIds);

        vm.stopPrank();
    }

    function test_airdropERC20() public {
        vm.startPrank(user);
        token.approve(address(gasliteDrop), quantity);

        address[] memory recipients = new address[](quantity);
        uint256[] memory amounts = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            recipients[i] = vm.addr(2);
            amounts[i] = 1;
        }
        gasliteDrop.airdropERC20(address(token), recipients, amounts, quantity);
        vm.stopPrank();
    }

    function test_airdropETH() public {
        payable(user).transfer(value);
        vm.startPrank(user);

        address[] memory recipients = new address[](quantity);
        uint256[] memory amounts = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            recipients[i] = vm.addr(2);
            amounts[i] = 0.001 ether;
        }

        gasliteDrop.airdropETH{value: value}(recipients, amounts);
        vm.stopPrank();
    }
}
