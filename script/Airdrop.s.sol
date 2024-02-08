pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "./../src/GasliteDrop.sol";
import "@solady/src/tokens/ERC20.sol";
import {console} from "forge-std/console.sol";

contract AirdropScript is Script {
    string public constant recipientsData = "./script/data/recipients.txt";
    string public constant amountsData = "./script/data/amounts.txt";

    function run() external {
        // load your private key from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // base sepolia: 0xf6c3555139aeA30f4a2be73EBC46ba64BAB8ac12
        // base mainnet: 0x09350f89e2d7b6e96ba730783c2d76137b045fef
        // change to address of GasliteDrop contract on desired network
        GasliteDrop gasliteDrop = GasliteDrop(0xf6c3555139aeA30f4a2be73EBC46ba64BAB8ac12);
        // change to your token
        address token = 0x42df06567a01c48c7Ff30B8946a17A5F20c3B32F;
        // change to your total airdrop size
        uint256 totalAirdropSize = 200000e18;
        // Number of recipients processed per transaction
        uint256 batchSize = 1000;
        // Number of iterations to process all recipients (200,000 / 1000 = 200 iterations)
        uint256 iterations = 200;

        // Approve tokens for the total airdrop size
        vm.startBroadcast(deployerPrivateKey);
        ERC20(token).approve(address(gasliteDrop), totalAirdropSize);
        vm.stopBroadcast();

        for (uint256 j = 0; j < iterations; j++) {
            address[] memory recipients = new address[](batchSize);
            uint256[] memory amounts = new uint256[](batchSize);
            uint256 batchTotalAmount = 0;

            for (uint256 i = 0; i < batchSize; i++) {
                recipients[i] = vm.parseAddress(vm.readLine(recipientsData));
                amounts[i] = vm.parseUint(vm.readLine(amountsData));
                batchTotalAmount += amounts[i];
            }

            // Start a broadcast to execute the airdrop
            vm.startBroadcast(deployerPrivateKey);
            gasliteDrop.airdropERC20(token, recipients, amounts, batchTotalAmount);
            vm.stopBroadcast();
        }
    }
}
