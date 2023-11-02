pragma solidity 0.8.19;

// forgefmt: disable-start
/**
 *                                                           bbbbbbbb                                         dddddddd
 *                                                           b::::::b                                         d::::::d
 *                                                           b::::::b                                         d::::::d
 *                                                           b::::::b                                         d::::::d
 *                                                            b:::::b                                         d:::::d
 *    ggggggggg   ggggg aaaaaaaaaaaaa      ssssssssss         b:::::bbbbbbbbb      aaaaaaaaaaaaa      ddddddddd:::::d
 *   g:::::::::ggg::::g a::::::::::::a   ss::::::::::s        b::::::::::::::bb    a::::::::::::a   dd::::::::::::::d
 *  g:::::::::::::::::g aaaaaaaaa:::::ass:::::::::::::s       b::::::::::::::::b   aaaaaaaaa:::::a d::::::::::::::::d
 * g::::::ggggg::::::gg          a::::as::::::ssss:::::s      b:::::bbbbb:::::::b           a::::ad:::::::ddddd:::::d
 * g:::::g     g:::::g    aaaaaaa:::::a s:::::s  ssssss       b:::::b    b::::::b    aaaaaaa:::::ad::::::d    d:::::d
 * g:::::g     g:::::g  aa::::::::::::a   s::::::s            b:::::b     b:::::b  aa::::::::::::ad:::::d     d:::::d
 * g:::::g     g:::::g a::::aaaa::::::a      s::::::s         b:::::b     b:::::b a::::aaaa::::::ad:::::d     d:::::d
 * g::::::g    g:::::ga::::a    a:::::assssss   s:::::s       b:::::b     b:::::ba::::a    a:::::ad:::::d     d:::::d
 * g:::::::ggggg:::::ga::::a    a:::::as:::::ssss::::::s      b:::::bbbbbb::::::ba::::a    a:::::ad::::::ddddd::::::dd
 *  g::::::::::::::::ga:::::aaaa::::::as::::::::::::::s       b::::::::::::::::b a:::::aaaa::::::a d:::::::::::::::::d
 *   gg::::::::::::::g a::::::::::aa:::as:::::::::::ss        b:::::::::::::::b   a::::::::::aa:::a d:::::::::ddd::::d
 *     gggggggg::::::g  aaaaaaaaaa  aaaa sssssssssss          bbbbbbbbbbbbbbbb     aaaaaaaaaa  aaaa  ddddddddd   ddddd
 *             g:::::g
 * gggggg      g:::::g
 * g:::::gg   gg:::::g
 *  g::::::ggg:::::::g
 *   gg:::::::::::::g
 *     ggg::::::ggg
 *        gggggg
 */
// forgefmt: disable-end

/// @title GasliteSplitter
/// @notice Turbo gas optimized payment splitter
/// @author Harrison (@PopPunkOnChain)
/// @author Thomas (@0xjustadev)
/// @author Gaslite (@GasliteGG)

contract GasliteSplitter {
    /**
     * packed data for split receivers
     * address: bytes 0-19
     * share: bytes 20-31
     *   Example:
     *     [5, 5, 5, 5] -> Each address gets 25% (20 shares total)
     *     [10, 20, 30, 40] -> Address 1 gets 10%, Address 2 gets 20%,
     *                         Address 3 gets 30%, Address 4 gets 40%
     *                         (100 shares total)
     */
    bytes32[] private packedSplits;
    // the total number of shares (calculated in constructor)
    uint256 public immutable totalShares;
    // flag to optionally give 0.1% to caller of release()
    bool public immutable releaseRoyalty;

    // event emitted when a payment is received (OpenZeppelin did this so I guess I have to do it too)
    event PaymentReceived(address from, uint256 amount);

    // event emitted when a split is released
    bytes32 private constant SPLIT_RELEASED_EVENT_SIGNATURE =
        0xa81a1a3f8e5470cb88006c7539ae66f8750a18c49bf0d312ef679e24bac0f014;

    // event emitted when ether is received
    bytes32 private constant PAYMENT_RECEIVED_EVENT_SIGNATURE =
        0x6ef95f06320e7a25a04a175ca677b7052bdd97131872c2192525a629f51be770;

    // hash of slot zero which is expected to be the `packedSplits` array
    bytes32 private constant HASH_OF_ZEROETH_SLOT = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

    event SplitReleased(address[] recipients, uint256[] amounts);

    // error when the balance is zero
    error BalanceZero();

    /// @notice Split payments to a list of addresses
    /// @param _recipients The addresses to split to
    /// @param _shares The shares for each address
    /// @param _releaseRoyalty Optional flag to give 0.1% to caller of release()
    constructor(address[] memory _recipients, uint256[] memory _shares, bool _releaseRoyalty) {
        // running total of sum of _shares array
        uint256 accumulatedShares;
        assembly {
            // cache size of _recipients
            let size := mload(_recipients)
            // revert if _recipients is empty
            //     or if _recipients and _shares are different sizes
            if or(iszero(size), iszero(eq(size, mload(_shares)))) { revert(0, 0) }
            // loop iterator
            let sharesOffset := add(_shares, 0x20)
            let recipientsOffset := sub(_shares, _recipients)

            // end of array
            let end := add(sharesOffset, mul(size, 0x20))

            // store array size to packedSplits slot
            sstore(packedSplits.slot, size)
            // store hash of packedSlits slot to get first storage slot for array data
            let splitsSlot := HASH_OF_ZEROETH_SLOT

            for {} 1 {} {
                // load share and recipient
                let share := mload(sharesOffset)
                let addr := mload(sub(sharesOffset, recipientsOffset))
                // add each share to accumulatedShares
                accumulatedShares := add(accumulatedShares, share)
                // revert if share is zero or share > 2^96-1
                if or(iszero(share), gt(share, 0xFFFFFFFFFFFFFFFFFFFFFFFF)) { revert(0, 0) }
                // store packed data
                sstore(splitsSlot, or(share, shl(96, addr)))
                // increment iterator
                sharesOffset := add(sharesOffset, 0x20)
                // break at end of array
                if eq(end, sharesOffset) { break }
                // increment split slot after end of array check
                splitsSlot := add(splitsSlot, 0x01)
            }
        }
        // release royalty and totalShares are set outside of assembly block
        // because they're immutable to save gas on SLOAD
        releaseRoyalty = _releaseRoyalty;
        totalShares = accumulatedShares;
    }

    /// @notice Release all eth (address(this).balance) to the recipients
    function release() external {
        // cache releaseRoyalty into memory
        bool memReleaseRoyalty = releaseRoyalty;

        // cache totalShares
        uint256 total = totalShares;

        // initiate the arrays in memory
        assembly {
            // cache balance of this contract
            let bal := selfbalance()

            // revert early if address(this).balance is 0
            if iszero(bal) {
                mstore(0x00, hex"836fd8a7")
                revert(0x00, 0x04)
            }

            let size := sload(packedSplits.slot)
            let length := add(0x20, mul(0x20, size))

            // canonical memAddresses array pointer, this returns the offset of the length of memAddresses
            let memAddresses := 0x40

            // canonical amounts array pointer, this returns the offset of the length of amounts
            let amounts := add(memAddresses, length)

            mstore(memAddresses, size)
            mstore(amounts, size)

            // abi encoding value for addresses position
            mstore(sub(memAddresses, 0x40), 0x40)
            // abi encoding value for amounts position
            mstore(sub(memAddresses, 0x20), add(0x40, length))

            // if releaseRoyalty == true
            if memReleaseRoyalty {
                // calculate 0.1% of balance as royalty
                let royalty := div(bal, 1000)
                // subtract royalty from balance
                bal := sub(bal, royalty)
                // transfer royalty to caller
                if iszero(call(gas(), caller(), royalty, 0, 0, 0, 0)) { revert(0, 0) }
            }

            // get first packed slot, memory pointer, offsets, and end
            let splitSlot := HASH_OF_ZEROETH_SLOT
            let amountsOffset := add(amounts, 0x20)
            let addrOffset := sub(amounts, memAddresses)
            let end := add(amountsOffset, mul(mload(amounts), 0x20))

            for {} 1 {} {
                // load packed split data
                let split := sload(splitSlot)
                // calculate amount
                let amount := div(mul(bal, and(split, 0xFFFFFFFFFFFFFFFFFFFFFFFF)), total)
                // retrieve address from packed data
                let addr := shr(96, split)
                // Store the amount and address at the correct offsets
                mstore(amountsOffset, amount)
                mstore(sub(amountsOffset, addrOffset), addr)
                // send ETH, revert if call fails
                if iszero(call(gas(), addr, amount, 0, 0, 0, 0)) { revert(0, 0) }

                // increment pointer
                amountsOffset := add(amountsOffset, 0x20)
                // break at end of array
                if iszero(lt(amountsOffset, end)) { break }
                // increment splitSlot after end of array check
                splitSlot := add(splitSlot, 0x01)
            }
            // emit a bulk event of addresses and amounts
            log1(sub(memAddresses, 0x40), add(0x40, mul(addrOffset, 0x02)), SPLIT_RELEASED_EVENT_SIGNATURE)
            stop()
        }
    }

    /// @notice Release all of given token (IERC20(_token).balanceOf(address(this))) to the recipients
    /// @param _token The address of the token to release
    function release(address _token) external {
        // cache releaseRoyalty into stack
        bool memReleaseRoyalty = releaseRoyalty;

        // cache totalShares
        uint256 total = totalShares;

        // initiate the arrays in memory
        assembly {
            // cache balance of _token in this contract
            mstore(0x00, hex"70a08231")
            mstore(0x04, address())

            // if `_token` has no code deployed to it, returndatacopy would revert since returndata[(offset + length)] is greater than returndata.length
            if iszero(staticcall(gas(), _token, 0x00, 0x24, 0x00, 0x00)) { revert(0x00, 0x00) }
            returndatacopy(0x00, 0x00, 0x20)
            let bal := mload(0x00)

            // revert early if address(this).balance is 0
            if iszero(bal) {
                mstore(0x00, hex"836fd8a7")
                revert(0x00, 0x04)
            }

            let size := sload(packedSplits.slot)
            let length := add(0x20, mul(0x20, size))

            let memAddresses := add(0x40, 0x60)
            let amounts := add(memAddresses, length)

            mstore(memAddresses, size)
            mstore(amounts, size)

            // abi encoding value for addresses position
            mstore(sub(memAddresses, 0x40), 0x40)
            // abi encoding value for amounts position
            mstore(sub(memAddresses, 0x20), add(0x40, length))

            // if releaseRoyalty == true
            if memReleaseRoyalty {
                // calculate 0.1% of balance as royalty
                let royalty := div(bal, 1000)
                // subtract royalty from balance
                bal := sub(bal, royalty)
                // transfer(address to, uint256 value)
                mstore(0x00, hex"a9059cbb")
                // to address
                mstore(0x04, caller())
                // value
                mstore(0x24, royalty)
                // transfer royalty to caller
                if iszero(call(gas(), _token, 0, 0x00, 0x44, 0, 0)) { revert(0, 0) }
            }

            // get first packed slot, memory pointer, offsets, and end
            let splitSlot := HASH_OF_ZEROETH_SLOT
            let amountsOffset := add(amounts, 0x20)
            let addrOffset := sub(amounts, memAddresses)
            let end := add(amountsOffset, mul(mload(amounts), 0x20))

            // transfer(address to, uint256 value)
            mstore(0x00, hex"a9059cbb")

            for {} 1 {} {
                // load packed split data
                let split := sload(splitSlot)
                // calculate amount
                let amount := div(mul(bal, and(split, 0xFFFFFFFFFFFFFFFFFFFFFFFF)), total)
                // retrieve address from packed data
                let addr := shr(96, split)
                // Store the amount and address at the correct offsets
                mstore(amountsOffset, amount)
                mstore(sub(amountsOffset, addrOffset), addr)
                // to address
                mstore(0x04, addr)
                // value
                mstore(0x24, amount)
                // transfer the tokens, revert if call fails
                if iszero(call(gas(), _token, 0, 0x00, 0x44, 0, 0)) { revert(0, 0) }

                // increment pointer
                amountsOffset := add(amountsOffset, 0x20)
                // break at end of array
                if iszero(lt(amountsOffset, end)) { break }
                // increment splitSlot after end of array check
                splitSlot := add(splitSlot, 0x01)
            }
            mstore(0x24, 0x00)
            // emit a bulk event of addresses and amounts
            log1(sub(memAddresses, 0x40), add(0x40, mul(addrOffset, 0x02)), SPLIT_RELEASED_EVENT_SIGNATURE)
            stop()
        }
    }

    /// @notice Retrieve the address for a split recipient at given `index`
    /// @param index The index of the split recipient
    function recipients(uint256 index) external view returns (address recipient) {
        assembly {
            if iszero(lt(index, sload(packedSplits.slot))) { revert(0, 0) }
            recipient := shr(96, sload(add(index, HASH_OF_ZEROETH_SLOT)))
        }
    }

    /// @notice Retrieve an array of split recipients
    function recipients() external view returns (address[] memory _recipients) {
        _recipients = new address[](packedSplits.length);
        assembly {
            let splitSlot := HASH_OF_ZEROETH_SLOT
            let ptr := add(0x20, _recipients)
            let end := add(0x20, mul(0x20, mload(_recipients)))

            for {} 1 {} {
                mstore(ptr, shr(96, sload(splitSlot)))
                ptr := add(0x20, ptr)
                if iszero(lt(ptr, end)) { break }
                splitSlot := add(0x01, splitSlot)
            }
        }
    }

    /// @notice Retrieve the shares for a split recipient at given `index`
    /// @param index The index of the split shares
    function shares(uint256 index) external view returns (uint256 share) {
        assembly {
            if iszero(lt(index, sload(packedSplits.slot))) { revert(0, 0) }
            share := and(0xFFFFFFFFFFFFFFFFFFFFFFFF, sload(add(index, HASH_OF_ZEROETH_SLOT)))
        }
    }

    /// @notice Retrieve an array of split recipients shares
    function shares() external view returns (uint256[] memory _shares) {
        _shares = new uint256[](packedSplits.length);
        assembly {
            let splitSlot := HASH_OF_ZEROETH_SLOT
            let ptr := add(0x20, _shares)
            let end := add(0x20, mul(0x20, mload(_shares)))

            for {} 1 {} {
                mstore(ptr, and(0xFFFFFFFFFFFFFFFFFFFFFFFF, sload(splitSlot)))
                ptr := add(0x20, ptr)
                if iszero(lt(ptr, end)) { break }
                splitSlot := add(0x01, splitSlot)
            }
        }
    }

    // receive function to receive ETH
    receive() external payable {
        // emit event when contract receives ETH
        assembly {
            mstore(0x00, caller())
            mstore(0x20, callvalue())
            log1(0x00, 0x40, PAYMENT_RECEIVED_EVENT_SIGNATURE)
        }
    }
}
