pragma solidity 0.8.19;

import "./../src/GasliteSplitter.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteSplitterScript is Script {
    function run() external {
        console.log("Deploying GasliteSplitter...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // change all of these
        // refer to GasliteSplitter contract comments for info
        uint256 size = 3;
        address[] memory _recipients = new address[](size);
        uint256[] memory _shares = new uint256[](size);

        _recipients[0] = address(0x0);
        _shares[0] = 1;
        _recipients[1] = address(0x0);
        _shares[1] = 1;
        _recipients[2] = address(0x0);
        _shares[2] = 1;

        // optional release royalty
        bool _releaseRoyalty = false;

        vm.startBroadcast(deployerPrivateKey);
        address splitterAddress = address(new GasliteSplitter(_recipients, _shares, _releaseRoyalty));
        vm.stopBroadcast();

        console.log("Deployed contract at address: ", splitterAddress);
    }
}