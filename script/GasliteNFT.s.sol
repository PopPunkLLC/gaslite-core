pragma solidity 0.8.20;

import "./../src/GasliteNFT.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteNFTScript is Script {
    function run() external {
        console.log("Deploying GasliteNFT...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address gasliteNFTAddress = address(
            new GasliteNFT(
                "NAME",
                "TICKER",
                0x000,
                10000,
                0.02 ether,
                0.01 ether,
                1705597895,
                1705601495,
                1,
                5,
                "ipfs://your-ipfs-hash/"
            )
        );
        console.log("GasliteNFT deployed at address: %s", gasliteNFTAddress);
        vm.stopBroadcast();
    }
}
