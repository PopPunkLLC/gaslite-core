pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "./../src/GasliteDrop.sol";
import "@solady/src/tokens/ERC20.sol";
import {console} from "forge-std/console.sol";

contract AirdropScript is Script {
    string public constant airdropDataPath = "./script/data/airdropData.json";

    struct AirdropData {
        uint256 amount;
        address recipient;
    }

    function run() external {
        // add your private key to .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // base sepolia: 0xf6c3555139aeA30f4a2be73EBC46ba64BAB8ac12
        // base mainnet: 0x09350f89e2d7b6e96ba730783c2d76137b045fef
        // change to address of GasliteDrop contract on desired network
        GasliteDrop gasliteDrop = GasliteDrop(0xf6c3555139aeA30f4a2be73EBC46ba64BAB8ac12);
        // change to your token
        address token = 0x42df06567a01c48c7Ff30B8946a17A5F20c3B32F;
        // change to number of recipients per transaction
        uint256 airdropSize = 2; 
        // change to total airdrop amount
        uint256 totalAirdropAmount = 6e18;

        // Read airdrop data from file
        string memory data = vm.readFile(airdropDataPath);
        bytes memory jsonData = vm.parseJson(data, ".data");

        // Decode the JSON data into an array of AirdropData structs
        AirdropData[] memory airdropData = abi.decode(jsonData, (AirdropData[]));

        // Approve the GasliteDrop contract to spend the total airdrop amount of the token
        vm.startBroadcast(deployerPrivateKey);
        ERC20(token).approve(address(gasliteDrop), totalAirdropAmount);
        vm.stopBroadcast();

        // Loop through airdropData in chunks of airdropSize and call airdropERC20 for each chunk
        for (uint256 i = 0; i < airdropData.length; i += airdropSize) {
            uint256 chunkSize = (airdropData.length - i > airdropSize) ? airdropSize : airdropData.length - i;
            address[] memory recipients = new address[](chunkSize);
            uint256[] memory amounts = new uint256[](chunkSize);
            uint256 totalAmount = 0;

            // Populate the recipients and amounts arrays for the current chunk
            for (uint256 j = 0; j < chunkSize; j++) {
                recipients[j] = airdropData[i + j].recipient;
                amounts[j] = airdropData[i + j].amount;
                totalAmount += amounts[j];
            }
            vm.startBroadcast(deployerPrivateKey);
            gasliteDrop.airdropERC20(token, recipients, amounts, totalAmount);
            vm.stopBroadcast();
            totalAmount = 0;
        }
    }
}
