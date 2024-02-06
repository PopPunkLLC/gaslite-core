pragma solidity 0.8.20;

import "./../src/KingOfTheFrame.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteVestScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address kotf = address(new KingOfTheFrame());

        vm.stopBroadcast();
    }
}
