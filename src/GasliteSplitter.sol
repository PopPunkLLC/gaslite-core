pragma solidity 0.8.19;

/**
                                                                                                                   
                                                          bbbbbbbb                                         dddddddd
                                                          b::::::b                                         d::::::d
                                                          b::::::b                                         d::::::d
                                                          b::::::b                                         d::::::d
                                                           b:::::b                                         d:::::d 
   ggggggggg   ggggg aaaaaaaaaaaaa      ssssssssss         b:::::bbbbbbbbb      aaaaaaaaaaaaa      ddddddddd:::::d 
  g:::::::::ggg::::g a::::::::::::a   ss::::::::::s        b::::::::::::::bb    a::::::::::::a   dd::::::::::::::d 
 g:::::::::::::::::g aaaaaaaaa:::::ass:::::::::::::s       b::::::::::::::::b   aaaaaaaaa:::::a d::::::::::::::::d 
g::::::ggggg::::::gg          a::::as::::::ssss:::::s      b:::::bbbbb:::::::b           a::::ad:::::::ddddd:::::d 
g:::::g     g:::::g    aaaaaaa:::::a s:::::s  ssssss       b:::::b    b::::::b    aaaaaaa:::::ad::::::d    d:::::d 
g:::::g     g:::::g  aa::::::::::::a   s::::::s            b:::::b     b:::::b  aa::::::::::::ad:::::d     d:::::d 
g:::::g     g:::::g a::::aaaa::::::a      s::::::s         b:::::b     b:::::b a::::aaaa::::::ad:::::d     d:::::d 
g::::::g    g:::::ga::::a    a:::::assssss   s:::::s       b:::::b     b:::::ba::::a    a:::::ad:::::d     d:::::d 
g:::::::ggggg:::::ga::::a    a:::::as:::::ssss::::::s      b:::::bbbbbb::::::ba::::a    a:::::ad::::::ddddd::::::dd
 g::::::::::::::::ga:::::aaaa::::::as::::::::::::::s       b::::::::::::::::b a:::::aaaa::::::a d:::::::::::::::::d
  gg::::::::::::::g a::::::::::aa:::as:::::::::::ss        b:::::::::::::::b   a::::::::::aa:::a d:::::::::ddd::::d
    gggggggg::::::g  aaaaaaaaaa  aaaa sssssssssss          bbbbbbbbbbbbbbbb     aaaaaaaaaa  aaaa  ddddddddd   ddddd
            g:::::g                                                                                                
gggggg      g:::::g                                                                                                
g:::::gg   gg:::::g                                                                                                
 g::::::ggg:::::::g                                                                                                
  gg:::::::::::::g                                                                                                 
    ggg::::::ggg                                                                                                   
       gggggg                                                                                                      
 */

/// @title GasliteSplitter
/// @notice Turbo gas optimized payment splitter
/// @author Harrison (@PopPunkOnChain)
/// @author Gaslite (@GasliteGG)
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract GasliteSplitter {
    // the addresses to split to
    address[] public recipients;
    /**
     * the shares for each address  
     *   Example:
     *     [5, 5, 5, 5] -> Each address gets 25% (20 shares total)
     *     [10, 20, 30, 40] -> Address 1 gets 10%, Address 2 gets 20%,
     *                         Address 3 gets 30%, Address 4 gets 40%
     *                         (100 shares total)
     */
    uint256[] public shares;
    // the total number of shares (calculated in constructor)
    uint256 public immutable totalShares;
    // flag to optionally give 0.1% to caller of release()
    bool public releaseRoyalty;

    // event emitted when a payment is received (OpenZeppelin did this so I guess I have to do it too)
    event PaymentReceived(address from, uint256 amount);
    // event emitted when a split is released
    event SplitReleased(address[] recipients, uint256[] amounts);
    // event emitted when the balance is zero

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
            if iszero(size) { revert(0, 0) }
            // revert if _recipients and _shares are different sizes
            if iszero(eq(size, mload(_shares))) { revert(0, 0) }
            // set releaseRoyalty flag if it's true
            if _releaseRoyalty { sstore(releaseRoyalty.slot, 1) }
            // loop iterator
            let i := add(_shares, 0x20)
            // end of array
            let end := add(i, mul(size, 0x20))

            for {} 1 {} {
                // add each share to accumulatedShares
                accumulatedShares := add(accumulatedShares, mload(i))
                // increment iterator
                i := add(i, 0x20)
                // break at end of array
                if eq(end, i) { break }
            }
        }
        // set recipients, shares, totalShares
        recipients = _recipients;
        shares = _shares;
        // totalShares is set outside of assembly block because it's immutable to save gas on SLOAD
        totalShares = accumulatedShares;
    }

    /// @notice Release all eth (address(this).balance) to the recipients
    function release() external {
        // cache shares array into memory
        uint256[] memory memShares = shares;
        // cache size of shares array
        uint256 size = memShares.length;
        // create new array to store amounts that are calculated off shares
        uint256[] memory amounts = new uint256[](size);

        // cache totalShares
        uint256 total = totalShares;
        // cache balance of this contract
        uint256 bal = address(this).balance;

        // revert is balance is zero
        if (bal == 0) revert BalanceZero();

        assembly {
            // if releaseRoyalty == true
            if sload(releaseRoyalty.slot) {
                // calculate 0.1% of balance as royalty
                let royalty := div(bal, 1000)
                // subtract royalty from balance
                bal := sub(bal, royalty)
                // transfer royalty to caller
                if iszero(call(gas(), caller(), royalty, 0, 0, 0, 0)) { revert(0, 0) }
            }

            // get pointer, offset, and end
            let memSharesPtr := add(memShares, 0x20)
            let amountsOffset := sub(amounts, memShares)
            let end := add(memSharesPtr, mul(size, 0x20))

            for {} 1 {} {
                // calculate amount for each address
                let share := mload(memSharesPtr)
                let amount := div(mul(bal, share), total)

                // Store the amount at the correct offset
                mstore(add(memSharesPtr, amountsOffset), amount)
                // increment pointer
                memSharesPtr := add(memSharesPtr, 0x20)
                // break at end of array
                if iszero(lt(memSharesPtr, end)) { break }
            }
        }
        // call split() with recipients, amounts, and address(0) (ETH)
        split(recipients, amounts, address(0));
    }

    /// @notice Release all of given token (IERC20(_token).balanceOf(address(this))) to the recipients
    /// @param _token The address of the token to release
    function release(address _token) external {
        // cache shares array into memory
        uint256[] memory memShares = shares;
        // cache size of shares array
        uint256 size = memShares.length;
        // create new array to store amounts that are calculated off shares
        uint256[] memory amounts = new uint256[](size);

        // cache totalShares
        uint256 total = totalShares;
        // cache balance of _token in this contract
        uint256 bal = IERC20(_token).balanceOf(address(this));

        // revert is balance is zero
        if (bal == 0) revert BalanceZero();

        assembly {
            // if releaseRoyalty == true
            if sload(releaseRoyalty.slot) {
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
            // restore free memory pointer
            mstore(0x24, 0)
            // get pointer, offset, and end
            let memSharesPtr := add(memShares, 0x20)
            let amountsOffset := sub(amounts, memShares)
            let end := add(memSharesPtr, mul(size, 0x20))

            for {} 1 {} {
                // calculate amount for each address
                let share := mload(memSharesPtr)
                let amount := div(mul(bal, share), total)

                // Store the amount at the correct offset
                mstore(add(memSharesPtr, amountsOffset), amount)
                // increment pointer
                memSharesPtr := add(memSharesPtr, 0x20)
                // break at end of array
                if iszero(lt(memSharesPtr, end)) { break }
            }
        }
        // call split() with recipients, amounts, and _token
        split(recipients, amounts, _token);
    }

    /// @notice Split payments to a list of addresses
    /// @param _addresses The addresses to split to
    /// @param _amounts The amounts to send to each address
    /// @param _token The address of the token to send (address(0) for ETH)
    function split(address[] memory _addresses, uint256[] memory _amounts, address _token) internal {
        // cache boolean to determine if we're splitting ETH or a token
        bool isETH = _token == address(0);
        assembly {
            // cache size of _addresses
            let size := mload(_addresses)

            // get pointer, offset, and end
            let addrPtr := add(_addresses, 0x20)
            let amtOffset := sub(_amounts, _addresses)
            let end := add(addrPtr, mul(size, 0x20))

            // switch on isETH (albeit ugly, 2 loops saves runtime gas)
            switch isETH
            // if isETH == true
            case 1 {
                for {} 1 {} {
                    // get address and amount
                    let addressOffset := mload(addrPtr)
                    let amount := mload(add(amtOffset, addrPtr))
                    // transfer amount to address
                    if iszero(call(gas(), addressOffset, amount, 0, 0, 0, 0)) { revert(0, 0) }
                    // increment pointer
                    addrPtr := add(addrPtr, 0x20)
                    // break at end of array
                    if iszero(lt(addrPtr, end)) { break }
                }
            }
            // if isETH == false
            case 0 {
                for {} 1 {} {
                    // get address and amount
                    let addressOffset := mload(addrPtr)
                    let amount := mload(add(amtOffset, addrPtr))
                    // transfer(address to, uint256 value)
                    mstore(0x00, hex"a9059cbb")
                    // to address
                    mstore(0x04, addressOffset)
                    // value
                    mstore(0x24, amount)
                    // transfer the tokens
                    if iszero(call(gas(), _token, 0, 0x00, 0x44, 0, 0)) { revert(0, 0) }
                    // increment pointer
                    addrPtr := add(addrPtr, 0x20)
                    // break at end of array
                    if iszero(lt(addrPtr, end)) { break }
                }
            }
            // restore free memory pointer
            mstore(0x24, 0)
        }
        // emit a bulk event of addresses and amounts
        emit SplitReleased(_addresses, _amounts);
    }

    // receive function to receive ETH
    receive() external payable {
        // emit event when contract receives ETH
        emit PaymentReceived(msg.sender, msg.value);
    }
}
