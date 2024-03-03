pragma solidity 0.8.20;

import "./../src/Bytecode20.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract Bytecode20Script is Script {
    function run() external {
        console.log("Deploying Bytecode20...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        uint256 _totalSupply = 1_000_000;
        uint256 _decimals = 18;
        string memory _name = "NAME";
        string memory _version = "1";
        string memory _symbol = "TICKER";

        address bytecode20Address = address(
            new Bytecode20(
                _totalSupply,
                _decimals,
                _name,
                _version,
                _symbol
            )
        );
        console.log("Bytecode20 deployed at address: %s", bytecode20Address);
        vm.stopBroadcast();
    }
}
