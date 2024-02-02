pragma solidity 0.8.20;

import "./../src/GasliteMerkleDrop.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteMerkleDropScript is Script {
    function run() external {
        console.log("Deploying GasliteMerkleDrop...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address gasliteMerkleDropAddress = address(
            new GasliteMerkleDrop(
                address(0x000), // CHANGE THIS TO THE ADDRESS OF THE TOKEN TO BE DISTRIBUTED
                bytes32(0x000) // CHANGE THIS TO THE MERKLE ROOT OF THE DISTRIBUTION
            )
        );
        console.log("GasliteMerkleDrop deployed at address: %s", gasliteMerkleDropAddress);
        vm.stopBroadcast();
    }
}
