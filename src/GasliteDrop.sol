pragma solidity 0.8.19;

// forgefmt: disable-start
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
// forgefmt: disable-end

/// @title GasliteDrop
/// @notice Turbo gas optimized bulk transfers of ERC20, ERC721, and ETH
/// @author Harrison (@PopPunkOnChain)
/// @author Gaslite (@GasliteGG)
/// @author Pop Punk LLC (@PopPunkLLC)
contract GasliteDrop {
    /// @notice Airdrop ERC721 tokens to a list of addresses
    /// @param _nft The address of the ERC721 contract
    /// @param _addresses The addresses to airdrop to
    /// @param _tokenIds The tokenIds to airdrop
    function airdropERC721(address _nft, address[] calldata _addresses, uint256[] calldata _tokenIds)
        external
        payable
    {
        assembly {
            // Check that the number of addresses matches the number of tokenIds
            if iszero(eq(_tokenIds.length, _addresses.length)) { revert(0, 0) }
            // transferFrom(address from, address to, uint256 tokenId)
            mstore(0x00, hex"23b872dd")
            // from address
            mstore(0x04, caller())

            // end of array
            let end := add(_addresses.offset, shl(5, _addresses.length))
            // diff = _addresses.offset - _tokenIds.offset
            let diff := sub(_addresses.offset, _tokenIds.offset)

            // Loop through the addresses
            for { let addressOffset := _addresses.offset } 1 {} {
                // to address
                mstore(0x24, calldataload(addressOffset))
                // tokenId
                mstore(0x44, calldataload(sub(addressOffset, diff)))
                // transfer the token
                if iszero(call(gas(), _nft, 0, 0x00, 0x64, 0, 0)) { revert(0, 0) }
                // increment the address offset
                addressOffset := add(addressOffset, 0x20)
                // if addressOffset >= end, break
                if iszero(lt(addressOffset, end)) { break }
            }
        }
    }

    /// @notice Airdrop ERC20 tokens to a list of addresses
    /// @param _token The address of the ERC20 contract
    /// @param _packedRecipients Recipient address packed with 96-bit amount (recipient ++ amount)
    /// @param _totalAmount The total amount to airdrop
    function airdropERC20(address _token, bytes32[] calldata _packedRecipients, uint256 _totalAmount)
        external
        payable
    {
        assembly {
            // Puts selector of `transferFrom(address from, address to, uint256 amount)` in memory
            // together with the default value for the "no error" flag (true i.e. `1`).
            mstore(0x00, 0x0100000000000000000000000000000000000000000000000000000023b872dd)

            // from address
            mstore(0x20, caller())
            // to address (this contract)
            mstore(0x40, address())
            // total amount
            mstore(0x60, _totalAmount)

            // transfer total amount to this contract
            mstore8(call(gas(), _token, 0, 0x1c, 0x64, 0, 0), 0)

            // end of array
            let end := add(_packedRecipients.offset, shl(5, _packedRecipients.length))

            // Puts selector of `transfer(address to, uint256 amount)` in memory with touching the
            // "no error" flag.
            mstore(0x01, 0xa9059cbb00)

            // Loop through the addresses
            for { let recipientsOffset := _packedRecipients.offset } 1 {} {
                let packedRecipient := calldataload(recipientsOffset)
                // to address (shifted left by 12 bytes)
                mstore(0x2c, packedRecipient)
                // amount
                mstore(0x40, and(0xffffffffffffffffffffffff, packedRecipient))
                // transfer the tokens
                mstore8(call(gas(), _token, 0, 0x1c, 0x44, 0, 0), 0)
                // increment the address offset
                recipientsOffset := add(recipientsOffset, 0x20)
                // if addressOffset >= end, break
                if iszero(lt(recipientsOffset, end)) { break }
            }

            // Check final error flag.
            if iszero(byte(0, mload(0))) { revert(0, 0) }
        }
    }

    /// @notice Airdrop ETH to a list of addresses
    /// @param _packedRecipients Recipient address packed with 96-bit amount (amount ++ recipient)
    function airdropETH(bytes32[] calldata _packedRecipients) external payable {
        assembly {
            // Assumes byte 0 in memory is 0 (default) i.e. scratch space untouched so far.

            // iterator
            let offset := _packedRecipients.offset
            // end of array
            let end := add(offset, shl(5, _packedRecipients.length))

            // Loop through the addresses
            for {} 1 {} {
                let packedRecipient := calldataload(offset)
                // transfer the ETH, byte 0 is error flag (0 = no error, 1 = error)
                mstore8(call(gas(), packedRecipient, shr(160, packedRecipient), 0x00, 0x00, 0x00, 0x00), 1)
                // increment the iterator
                offset := add(offset, 0x20)
                // if i >= end, break
                if eq(end, offset) { break }
            }

            // Check error flag.
            if byte(0, mload(0x00)) { revert(0x0, 0x0) }
        }
    }
}
