pragma solidity 0.8.20;

import "./../src/GasliteMerkleDN.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteMerkleDNScript is Script {
    function run() external {
        console.log("Deploying GasliteMerkleDN...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address gasliteMerkleDNAddress = address(
            new GasliteMerkleDN(
                bytes32(0x000) // CHANGE THIS TO THE MERKLE ROOT OF THE DISTRIBUTION
            )
        );
        console.log("GasliteMerkleDNdeployed at address: %s", gasliteMerkleDNAddress);
        vm.stopBroadcast();
    }
}
