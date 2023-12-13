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

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

contract GasliteDrop1155 {
    bytes32 private immutable SAFE_TRANSFER_FROM_SELECTOR;

    struct AirdropToken {
        uint256 tokenId;
        AirdropTokenAmount[] airdropAmounts;
    }

    struct AirdropTokenAmount {
        uint256 amount;
        address[] recipients;
    }

    constructor() {
        SAFE_TRANSFER_FROM_SELECTOR = IERC1155.safeTransferFrom.selector;
    }

    function airdropERC1155(address tokenAddress, AirdropToken[] calldata airdropTokens) external {
        bytes32 safeTransferFromSelector = SAFE_TRANSFER_FROM_SELECTOR;
        assembly {
            mstore(0x00, safeTransferFromSelector)
            mstore(0x04, caller())
            mstore(0x84, 0xA0)

            let tokenArrayCalldataOffsetStart := 0x64
            let tokenArrayCalldataOffset := 0x64
            let tokenArrayCalldataOffsetEnd := add(tokenArrayCalldataOffset, shl(5, calldataload(0x44)))

            for {} 1 {} {
                if eq(tokenArrayCalldataOffset, tokenArrayCalldataOffsetEnd) { break }

                let tokenCalldataOffset := add(tokenArrayCalldataOffsetStart, calldataload(tokenArrayCalldataOffset))
                mstore(0x44, calldataload(tokenCalldataOffset))

                let amountArrayCalldataOffsetStart := add(tokenCalldataOffset, 0x60)
                let amountArrayCalldataOffset := amountArrayCalldataOffsetStart
                let amountArrayCalldataOffsetEnd :=
                    add(amountArrayCalldataOffset, shl(5, calldataload(add(tokenCalldataOffset, 0x40))))

                let tmpTokenAddress := tokenAddress

                for {} 1 {} {
                    if eq(amountArrayCalldataOffset, amountArrayCalldataOffsetEnd) { break }

                    let amountCalldataOffset :=
                        add(amountArrayCalldataOffsetStart, calldataload(amountArrayCalldataOffset))
                    mstore(0x64, calldataload(amountCalldataOffset))

                    let recipientArrayCalldataOffset := add(amountCalldataOffset, 0x60)
                    let recipientArrayCalldataOffsetEnd :=
                        add(recipientArrayCalldataOffset, shl(5, calldataload(add(amountCalldataOffset, 0x40))))

                    for {} 1 {} {
                        if eq(recipientArrayCalldataOffset, recipientArrayCalldataOffsetEnd) { break }

                        mstore(0x24, calldataload(recipientArrayCalldataOffset))
                        if iszero(call(gas(), tmpTokenAddress, 0, 0x00, 0xC4, 0, 0)) { revert(0, 0) }

                        recipientArrayCalldataOffset := add(recipientArrayCalldataOffset, 0x20)
                    }

                    amountArrayCalldataOffset := add(amountArrayCalldataOffset, 0x20)
                }

                tokenArrayCalldataOffset := add(tokenArrayCalldataOffset, 0x20)
            }
        }
    }
}
