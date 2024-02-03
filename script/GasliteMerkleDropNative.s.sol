pragma solidity 0.8.20;

import "./../src/GasliteMerkleDropNative.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteMerkleDropNativeScript is Script {
    function run() external {
        console.log("Deploying GasliteMerkleDropNative...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address gasliteMerkleDropNativeAddress = address(
            new GasliteMerkleDropNative(
                bytes32(0x000) // CHANGE THIS TO THE MERKLE ROOT OF THE DISTRIBUTION
            )
        );
        console.log("GasliteMerkleDropNative deployed at address: %s", gasliteMerkleDropNativeAddress);
        vm.stopBroadcast();
    }
}
