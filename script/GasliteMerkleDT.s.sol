pragma solidity 0.8.20;

import "./../src/GasliteMerkleDT.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteMerkleDTScript is Script {
    function run() external {
        console.log("Deploying GasliteMerkleDT...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address gasliteMerkleDTAddress = address(
            new GasliteMerkleDT(
                address(0x000), // CHANGE THIS TO THE ADDRESS OF THE TOKEN TO BE DISTRIBUTED
                bytes32(0x000) // CHANGE THIS TO THE MERKLE ROOT OF THE DISTRIBUTION
            )
        );
        console.log("GasliteMerkleDT deployed at address: %s", gasliteMerkleDTAddress);
        vm.stopBroadcast();
    }
}
