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
    function airdropERC721(
        address _nft, 
        address[] calldata _addresses, 
        uint256[] calldata _tokenIds
    ) external payable {
        assembly {
            // Check that the number of addresses matches the number of tokenIds
            if iszero(eq(_tokenIds.length, _addresses.length)) {
                revert(0, 0)
            }
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
                if iszero(call(gas(), _nft, 0, 0x00, 0x64, 0, 0)){
                    revert(0, 0)
                }
                // increment the address offset
                addressOffset := add(addressOffset, 0x20)
                // if addressOffset >= end, break
                if iszero(lt(addressOffset, end)) { break }
            }
        }
    }

    /// @notice Airdrop ERC20 tokens to a list of addresses
    /// @param _token The address of the ERC20 contract
    /// @param _addresses The addresses to airdrop to
    /// @param _amounts The amounts to airdrop
    /// @param _totalAmount The total amount to airdrop
    function airdropERC20(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts,
        uint256 _totalAmount
    ) external payable {
        assembly {
            // Check that the number of addresses matches the number of amounts
            if iszero(eq(_amounts.length, _addresses.length)) {
                revert(0, 0)
            }

            // transferFrom(address from, address to, uint256 amount)
            mstore(0x00, hex"23b872dd")
            // from address
            mstore(0x04, caller())
            // to address (this contract)
            mstore(0x24, address())
            // total amount
            mstore(0x44, _totalAmount)

            // transfer total amount to this contract
            if iszero(call(gas(), _token, 0, 0x00, 0x64, 0, 0)){
                revert(0, 0)
            }

            // transfer(address to, uint256 value)
            mstore(0x00, hex"a9059cbb")

            // end of array
            let end := add(_addresses.offset, shl(5, _addresses.length))
            // diff = _addresses.offset - _amounts.offset
            let diff := sub(_addresses.offset, _amounts.offset)

            // Loop through the addresses
            for { let addressOffset := _addresses.offset } 1 {} {
                // to address
                mstore(0x04, calldataload(addressOffset))
                // amount
                mstore(0x24, calldataload(sub(addressOffset, diff)))
                // transfer the tokens
                if iszero(call(gas(), _token, 0, 0x00, 0x64, 0, 0)){
                    revert(0, 0)
                }
                // increment the address offset
                addressOffset := add(addressOffset, 0x20)
                // if addressOffset >= end, break
                if iszero(lt(addressOffset, end)) { break }
            }
        }
    }

    /// @notice Airdrop ETH to a list of addresses
    /// @param _addresses The addresses to airdrop to
    /// @param _amounts The amounts to airdrop
    function airdropETH(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external payable {
        assembly {
            // Check that the number of addresses matches the number of amounts
            if iszero(eq(_amounts.length, _addresses.length)) {
                revert(0, 0)
            }

            // iterator
            let i := _addresses.offset
            // end of array
            let end := add(i, shl(5, _addresses.length))
            // diff = _addresses.offset - _amounts.offset
            let diff := sub(_amounts.offset, _addresses.offset)

            // Loop through the addresses
            for {} 1 {} {
                // transfer the ETH
                if iszero(
                    call(gas(), calldataload(i), calldataload(add(i, diff)), 0x00, 0x00, 0x00, 0x00)
                ) { revert(0x00, 0x00) }
                // increment the iterator
                i := add(i, 0x20)
                // if i >= end, break
                if eq(end, i) { break }
            }
        }
    }
}