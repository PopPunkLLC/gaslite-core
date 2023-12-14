pragma solidity 0.8.19;

import {GasliteSplitter} from "./GasliteSplitter.sol";

contract GasliteSplitterFactory {
    error DeploymentFailed();

    /**
     *  @notice Computes the deployment address for a GasliteSplitter based on the
     *          constructor arguments and deployment salt.
     *  @param recipients The addresses to split to
     *  @param shares The shares for each address
     *  @param releaseRoyalty Optional flag to give 0.1% to caller of release()
     *  @param salt Salt value for CREATE2 to change the deployment address
     *  @return deploymentAddress The address that the contract will be deployed to
     */
    function findDeploymentAddress(
        address[] calldata recipients,
        uint256[] calldata shares,
        bool releaseRoyalty,
        bytes32 salt
    ) public view returns (address deploymentAddress) {
        bytes memory creationCode = getCreationCode(recipients, shares, releaseRoyalty);

        deploymentAddress = address(
            uint160( // downcast to match the address type.
                uint256( // convert to uint to truncate upper digits.
                    keccak256( // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            hex"ff", // start with 0xff to distinguish from RLP.
                            address(this), // this contract will be the caller.
                            salt, // pass in the supplied salt value.
                            keccak256( // pass in the hash of initialization code.
                            abi.encodePacked(creationCode))
                        )
                    )
                )
            )
        );
    }

    /**
     *  @notice Deploys a GasliteSplitter contract
     *  @param recipients The addresses to split to
     *  @param shares The shares for each address
     *  @param releaseRoyalty Optional flag to give 0.1% to caller of release()
     *  @param salt Salt value for CREATE2 to change the deployment address
     */
    function deployContract(address[] calldata recipients, uint256[] calldata shares, bool releaseRoyalty, bytes32 salt)
        public
        returns (address deploymentAddress)
    {
        bytes memory creationCode = getCreationCode(recipients, shares, releaseRoyalty);
        assembly {
            deploymentAddress := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }

        if (deploymentAddress == address(0)) {
            revert DeploymentFailed();
        }
    }

    /**
     *  @notice Gets the contract creation code for a GasliteSplitter contract
     *  @param recipients The addresses to split to
     *  @param shares The shares for each address
     *  @param releaseRoyalty Optional flag to give 0.1% to caller of release()
     */
    function getCreationCode(address[] calldata recipients, uint256[] calldata shares, bool releaseRoyalty)
        public
        pure
        returns (bytes memory creationCode)
    {
        creationCode = type(GasliteSplitter).creationCode;
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := add(add(creationCode, 0x20), mload(creationCode))
            let length := add(0x20, mul(0x20, recipients.length))
            mstore(ptr, 0x60)
            mstore(add(ptr, 0x20), add(0x60, length))
            mstore(add(ptr, 0x40), releaseRoyalty)
            calldatacopy(add(ptr, 0x60), sub(recipients.offset, 0x20), mul(length, 0x02))
            mstore(creationCode, add(mload(creationCode), add(0x60, mul(length, 0x02))))
            mstore(0x40, add(0x20, add(creationCode, mload(creationCode))))
        }
    }
}
