pragma solidity 0.8.19;

import {GasliteDrop1155} from "./../src/GasliteDrop1155.sol";
import {Token1155} from "./../test/utils/Token1155.sol";
import "forge-std/Test.sol";

contract GasliteDrop1155Test is Test {
    GasliteDrop1155 gasliteDrop;
    Token1155 token;

    address user = vm.addr(0x1);
    uint256 size = 2;

    uint256[] tokenIds = new uint256[](size);
    uint256[] amounts = new uint256[](size);
    address[] recipients = new address[](size);

    function setUp() public {
        token = new Token1155();
        for (uint256 i; i < size; i++) {
            tokenIds[i] = i;
            amounts[i] = 5;
            recipients[i] = vm.addr(i + 1);
        }
        token.batchMint(address(user), tokenIds, amounts);
        gasliteDrop = new GasliteDrop1155();
    }

    function test_setup() public {
        assertEq(token.balanceOf(address(user), 0), 5);
        assertEq(token.balanceOf(address(user), 1), 5);
    }

    function test_airdropERC1155() public {
        vm.startPrank(user);

        token.setApprovalForAll(address(gasliteDrop), true);

        GasliteDrop1155.AirdropToken[] memory airdropTokens = new GasliteDrop1155.AirdropToken[](size);

        for (uint256 i; i < size; i++) {
            airdropTokens[i].tokenId = i;
            airdropTokens[i].airdropAmounts = new GasliteDrop1155.AirdropTokenAmount[](size);
            for (uint256 j; j < size; j++) {
                airdropTokens[i].airdropAmounts[j].amount = 1;
                airdropTokens[i].airdropAmounts[j].recipients = new address[](size);
                for (uint256 k; k < size; k++) {
                    airdropTokens[i].airdropAmounts[j].recipients[k] = vm.addr(k + 1);
                }
            }
        }

        gasliteDrop.airdropERC1155(address(token), airdropTokens);
    }
}
