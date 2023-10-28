pragma solidity 0.8.19;

import "./../src/GasliteDrop.sol";
import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GasliteDropScript is Script {
    function run() external {
        console.log("Deploying GasliteDrop...");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        bytes32 deploySalt = keccak256(abi.encodePacked("gaslitedrop"));
        bytes memory gasliteDropCode = abi.encodePacked(type(GasliteDrop).creationCode);

        deploy(gasliteDropCode, deploySalt);
        vm.stopBroadcast();
    }

    /**
     *
     * @param _bytecode full bytecode of the contract to deploy
     * @param _salt salt to use as part of address pre-computation
     * @return address of the deployed contract
     *
     * @dev this function is used to deploy a contract using the CREATE2 opcode
     */
    function deploy(bytes memory _bytecode, bytes32 _salt) internal returns (address) {
        address addr;
        assembly {
            addr := create2(0, add(_bytecode, 0x20), mload(_bytecode), _salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        console.log("Deployed contract at address: ", addr);
        return addr;
    }
}
