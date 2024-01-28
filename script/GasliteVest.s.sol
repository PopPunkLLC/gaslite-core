pragma solidity 0.8.20;

import "./../src/GasliteVest.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteVestScript is Script {
    function run() external {
        console.log("Deploying GasliteVest...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address gasliteVestAddress = address(new GasliteVest());

        console.log("GasliteVest deployed at address: %s", gasliteVestAddress);
        vm.stopBroadcast();
    }
}