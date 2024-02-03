pragma solidity 0.8.20;

import "./../src/GasliteMerkleDropToken.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteMerkleDropTokenScript is Script {
    function run() external {
        console.log("Deploying GasliteMerkleDropToken...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address gasliteMerkleDropTokenAddress = address(
            new GasliteMerkleDropToken(
                address(0x000), // CHANGE THIS TO THE ADDRESS OF THE TOKEN TO BE DISTRIBUTED
                bytes32(0x000) // CHANGE THIS TO THE MERKLE ROOT OF THE DISTRIBUTION
            )
        );
        console.log("GasliteMerkleDropToken deployed at address: %s", gasliteMerkleDropTokenAddress);
        vm.stopBroadcast();
    }
}
