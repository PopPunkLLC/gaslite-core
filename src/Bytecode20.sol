// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

/// @title Bytecode20
/// @notice Turbo gas optimized ERC20 written in EVM bytecode
/// @author Thomas (@0xjustadev)
contract Bytecode20 {
    // 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // 0xf4d678b8
    error InsufficientBalance();
    // 0x3f726eac
    error InsufficientApproval();
    // 0x1ab7da6b
    error DeadlineExpired();
    // 0x8baa579f
    error InvalidSignature();

    /**
     * STORAGE LAYOUT:
     *      ADDRESS BALANCE:
     *          KEY: 0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00000000000000000000000F
     *          VALUE: BALANCE OF ADDRESS X
     *      APPROVAL AMOUNT:
     *          KEY: 0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXZYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYE
     *                 X AND Y USE LOWEST 126 BITS OF ADDRESS, Z IS OVERLAP
     *                 MATCHING 126 BITS WOULD TAKE THE ENTIRE BITCOIN HASH RATE
     *                 APPX 4B YEARS TO FIND A MATCH AT A COST OF ~11.5M USD / DAY
     *          VALUE: APPROVAL AMOUNT FOR ADDRESS Y TO SPEND OF X'S BALANCE
     *      ADDRESS NONCE:
     *          KEY: 0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00000000000000000000000D
     *          VALUE: NONCE OF ADDRESS X
     */
    constructor(
        uint256 _totalSupply,
        uint256 _decimals,
        string memory _name,
        string memory _version,
        string memory _symbol
    ) payable {
        assembly {
            if gt(_decimals, 0xFF) { revert(0, 0) }

            sstore(or(0x0F, shl(96, caller())), _totalSupply)
            mstore(0x00, _totalSupply)
            log3(0x00, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x00, caller())

            let nameSize := mload(_name)
            let symbolSize := mload(_symbol)

            if gt(symbolSize, 0x20) { revert(0, 0) }
            symbolSize := 0x40

            let nameHash := keccak256(add(_name, 0x20), nameSize)
            let versionHash := keccak256(add(_version, 0x20), mload(_version))

            let nameWords := add(0x01, div(nameSize, 0x20))
            if iszero(iszero(mod(nameSize, 0x20))) { nameWords := add(nameWords, 0x01) }
            nameSize := mul(nameWords, 0x20)

            let offset := mload(0x40)

            mstore(offset, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
            mstore(add(offset, 0x20), nameHash)
            mstore(add(offset, 0x40), versionHash)
            mstore(add(offset, 0x60), chainid())
            mstore(add(offset, 0x80), address())

            let domainHash := keccak256(offset, 0xA0)

            mstore(add(offset, 0x536), 0x5952596000205B60005260206000F35B60043560601B600D17545952596000F3)
            mstore(add(offset, 0x516), 0x595246595230)
            mstore(add(offset, 0x510), versionHash)
            mstore(add(offset, 0x4F0), 0x59527F)
            mstore(add(offset, 0x4ED), nameHash)
            mstore(add(offset, 0x4CD), 0xC69BB8FE3D512ECC4CF759CC79239F7B179B0FFACAA9A75D522B39400F59527F)
            mstore(add(offset, 0x4AD), 0x30141661053C577F8B73C3)
            mstore(add(offset, 0x4A2), address())
            mstore(add(offset, 0x48E), 0x461473)
            mstore(add(offset, 0x48B), chainid())
            mstore(add(offset, 0x46B), 0x7F)
            mstore(add(offset, 0x46A), domainHash)
            mstore(add(offset, 0x44A), 0x5952596000F35B7F)
            mstore(add(offset, 0x442), _decimals)
            mstore(add(offset, 0x441), 0x5939596000F35B60)
            mstore(add(offset, 0x439), add(0x0556, nameSize))
            mstore(add(offset, 0x437), 0x6105565939596000F35B6020595261004061)
            mstore(add(offset, 0x425), nameSize)
            mstore(add(offset, 0x423), 0x5952596000F35B6020595261)
            mstore(add(offset, 0x417), _totalSupply)
            mstore(add(offset, 0x3F7), 0x6011565B60243560821B607E1C60043560821B600E1717545952596000F35B7F)
            mstore(add(offset, 0x3D7), 0x200AC8C7C3B92560206000A360006000F35B631AB7DA6B6011565B638BAA579F)
            mstore(add(offset, 0x3B7), 0x1755826000527F8C5BE1E5EBEC7D5BD14F71427D1E84F3DD0314C0F7B2291E5B)
            mstore(add(offset, 0x397), 0x81151790841415176103F1576001019055828260821B607E1C8260821B600E17)
            mstore(add(offset, 0x377), 0x604260002060005260606084602037602060006080600060015AFA1560005190)
            mstore(add(offset, 0x357), 0x601C80604252826062528360825290600D1780548060A25260C0602220602252)
            mstore(add(offset, 0x337), 0x64845D6126C960225260C25260443560243560601B60601C60043560601B8060)
            mstore(add(offset, 0x317), 0x00526002527F6E71EDAE12B1B97F4D1F60370FEF10105FA2FAAE0126114A169C)
            mstore(add(offset, 0x2F7), 0x5952465952305952596000205B61190160F01B60)
            mstore(add(offset, 0x2E3), versionHash)
            mstore(add(offset, 0x2C3), 0x59527F)
            mstore(add(offset, 0x2C0), nameHash)
            mstore(add(offset, 0x2A0), 0xC69BB8FE3D512ECC4CF759CC79239F7B179B0FFACAA9A75D522B39400F59527F)
            mstore(add(offset, 0x280), 0x30141661030F57507F8B73C3)
            mstore(add(offset, 0x274), address())
            mstore(add(offset, 0x260), 0x461473)
            mstore(add(offset, 0x25D), chainid())
            mstore(add(offset, 0x23D), 0x7F)
            mstore(add(offset, 0x23C), domainHash)
            mstore(add(offset, 0x21C), 0xC8C7C3B9255984A3600181525990F35B5B6064358042116103E8577F)
            mstore(add(offset, 0x200), 0x599259527F8C5BE1E5EBEC7D5BD14F71427D1E84F3DD0314C0F7B2291E5B200A)
            mstore(add(offset, 0x1E0), 0x565B60243560043560601B60601C33828260821B607E1C8260821B600E171755)
            mstore(add(offset, 0x1C0), 0xC4A11628F55A4DF523B3EF596000A36001600052596000F35B633F726EAC6011)
            mstore(add(offset, 0x1A0), 0x805483019055905952837FDDF252AD1BE2C89B69C2B068FC378DAA952BA7F163)
            mstore(add(offset, 0x180), 0x0186565B50505B821061011657808203835560243560601B8060601C90600F17)
            mstore(add(offset, 0x160), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF14610183578083116101D857829003905561)
            mstore(add(offset, 0x140), 0x7E1C8560821B600E17178054807FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(offset, 0x120), 0x60043560601B8060601C90600F17805460443580338514610186573360821B60)
            mstore(add(offset, 0x100), 0x1628F55A4DF523B3EF596000A36001600052596000F35B63F4D678B86011565B)
            mstore(add(offset, 0xE0), 0x83019055905952837FDDF252AD1BE2C89B69C2B068FC378DAA952BA7F163C4A1)
            mstore(add(offset, 0xC0), 0x5460243580821061011657808203835560043560601B8060601C90600F178054)
            mstore(add(offset, 0xA0), 0x45575959FD5B60043560601B600F17545952596000F35B338060601B600F1780)
            mstore(add(offset, 0x80), 0x578063313CE5671461045F5780633644E515146104685780637ECEBE00146105)
            mstore(add(offset, 0x60), 0x806318160DDD1461041557806306FDDE031461043D57806395D89B411461044E)
            mstore(add(offset, 0x40), 0x63095EA7B3146101E1578063D505ACCF14610230578063DD62ED3E146103FA57)
            mstore(add(offset, 0x20), 0x806370A082311460A5578063A9059CBB1460B657806323B872DD1461011f5780)
            mstore(offset, 0x59351559341117600D57601A565B5959FD5B6000526004601CFD5B593560E01C)

            let nameOffset := 0x00
            for {} 1 {} {
                if iszero(lt(nameOffset, nameSize)) { break }
                mstore(add(add(offset, 0x556), nameOffset), mload(add(_name, nameOffset)))
                nameOffset := add(nameOffset, 0x20)
            }
            mstore(add(add(offset, 0x556), nameSize), mload(_symbol))
            mstore(add(add(offset, 0x556), add(nameSize, 0x20)), mload(add(_symbol, 0x20)))

            return(offset, add(0x40, add(0x556, nameSize)))
        }

        // 59351559341117600D57601A565B5959FD5B6000526004601CFD5B
        // 0000: 59 MSIZE (stack: 0)
        // 0001: 35 CALLDATALOAD (stack: first calldata word)
        // 0002: 15 ISZERO (stack: calldataiszero)
        // 0003: 59 MSIZE (stack: 0, calldataiszero)
        // 0004: 34 CALLVALUE (stack: callvalue, 0, calldataiszero)
        // 0005: 11 GT (stack: callvaluegtzero, calldataiszero)
        // 0006: 17 OR (stack: calldatagtzeroORcalldataiszero)
        // 0007: 600d push jump dest if calldata is zero (receive/fallback) (stack: 0x0d, calldatagtzeroORcalldataiszero)
        // 0009: 57 JUMPI dest condition (stack: empty)
        // 000a: 601A push jump dest PC if calldata is nonzero (stack: 0x0D)
        // 000c: 56 JUMP (stack: empty)
        // 000d: 5B JUMPDEST for generic revert (stack: empty)
        // 000e: 5959 MSIZE MSIZE (stack: 0, 0)
        // 0010: FD REVERT
        // 0011: 5B JUMPDEST for error revert, assumes top item on stack is right aligned revert code (stack: revert code, ...)
        // 0012: 6000 (stack: 0, revert code, ...)
        // 0014: 52 MSTORE (stack: ...)
        // 0015: 6004601CFD PUSH1 1C, PUSH1 04 (stack: 0x1C, 0x04, ...), REVERT
        // 001a: 5B JUMPDEST (stack: empty)

        // FUNCTION SELECTOR - balanceOf, transfer, transferFrom, approve, permit, allowance, totalSupply, name, symbol, decimals, DOMAIN_SEPARATOR, nonces

        // 593560E01C
        // 806370A082311460A5578063A9059CBB1460B657806323B872DD1461011f5780
        // 63095EA7B3146101E1578063D505ACCF14610230578063DD62ED3E146103FA57
        // 806318160DDD1461041557806306FDDE031461043D57806395D89B411461044E
        // 578063313CE5671461045F5780633644E515146104685780637ECEBE00146105
        // 45575959FD

        // 001b: 59 MSIZE (stack: 0)
        // 001c: 35 CALLDATALOAD (stack: first calldata word)
        // 001d: 60E0 push 224 to stack for shr (stack: 0xE0, first calldata word)
        // 001f: 1C SHR (stack: selector)

        // 0020: 80 DUP1 selector (stack: selector, selector)
        // 0021: 6370a08231 PUSH4 balanceOf selector (stack: balanceOf, selector, selector)
        // 0026: 14 EQ (stack: isBalanceOf, selector)
        // 0027: 60a5 push jump dest if balanceOf (stack: dest, isBalanceOf, selector)
        // 0029: 57 JUMPI dest condition (stack: selector)

        // 002a: 80 DUP1 selector (stack: selector, selector)
        // 002b: 63a9059cbb PUSH4 transfer selector (stack: transfer, selector, selector)
        // 0030: 14 EQ (stack: isTransfer, selector)
        // 0031: 60b6 push jump dest if transfer (stack: dest, isTransfer, selector)
        // 0033: 57 JUMPI dest condition (stack: selector)

        // 0034: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 6323b872dd PUSH4 transferFrom selector (stack: transferFrom, selector, selector)
        // XXXX: 14 EQ (stack: isTransferFrom, selector)
        // XXXX: 61011f push jump dest if transferFrom (stack: dest, isTransferFrom, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 003f: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 63095ea7b3 PUSH4 approve selector (stack: approve, selector, selector)
        // XXXX: 14 EQ (stack: isApprove, selector)
        // XXXX: 6101e1 push jump dest if approve (stack: dest, isApprove, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 004a: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 63d505accf PUSH4 permit selector (stack: permit, selector, selector)
        // XXXX: 14 EQ (stack: isPermit, selector)
        // XXXX: 610230 push jump dest if permit (stack: dest, isPermit, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 0055: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 63dd62ed3e PUSH4 allowance selector (stack: allowance, selector, selector)
        // XXXX: 14 EQ (stack: isAllowance, selector)
        // XXXX: 6103fa push jump dest if allowance (stack: dest, isAllowance, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 0060: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 6318160ddd PUSH4 totalSupply selector (stack: totalSupply, selector, selector)
        // XXXX: 14 EQ (stack: isTotalSupply, selector)
        // XXXX: 610415 push jump dest if totalSupply (stack: dest, isTotalSupply, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 006b: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 6306fdde03 PUSH4 name selector (stack: name, selector, selector)
        // XXXX: 14 EQ (stack: isName, selector)
        // XXXX: 61043D push jump dest if name (stack: dest, isName, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 0076: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 6395d89b41 PUSH4 symbol selector (stack: symbol, selector, selector)
        // XXXX: 14 EQ (stack: isSymbol, selector)
        // XXXX: 61044E push jump dest if symbol (stack: dest, isSymbol, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 0081: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 63313ce567 PUSH4 decimals selector (stack: decimals, selector, selector)
        // XXXX: 14 EQ (stack: isDecimals, selector)
        // XXXX: 61045F push jump dest if decimals (stack: dest, isDecimals, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 008c: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 633644e515 PUSH4 separator selector (stack: separator, selector, selector)
        // XXXX: 14 EQ (stack: isSeparator, selector)
        // XXXX: 610468 push jump dest if separator (stack: dest, isSeparator, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 0097: 80 DUP1 selector (stack: selector, selector)
        // XXXX: 637ecebe00 PUSH4 nonces selector (stack: nonces, selector, selector)
        // XXXX: 14 EQ (stack: isNonces, selector)
        // XXXX: 610545 push jump dest if nonces (stack: dest, isNonces, selector)
        // XXXX: 57 JUMPI dest condition (stack: selector)

        // 00a2: 5959FD (fallback revert)

        // BALANCE OF FUNCTION

        // 5B60043560601B600F17545952596000F3
        // 00a5: 5B JUMPDEST for balanceOf selector
        // 00a6: 6004 PUSH1 0x04 to stack to load address offset (stack: address offset)
        // 00a8: 35 CALLDATALOAD (stack: address)
        // 00a9: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, address)
        // 00ab: 1B SHL shift address 96 bits left (stack: shifted address)
        // 00ac: 600F PUSH1 0x0F to stack for storage slot offset (stack: 0x0F, shifted address)
        // 00ae: 17 OR combine 0x0F and shifted address for storage slot (stack: balance storage slot)
        // 00af: 54 SLOAD load storage slot to stack (stack: balance)
        // 00b0: 59 MSIZE to put a 0 on stack (stack: 0, balance)
        // 00b1: 52 MSTORE to store balance at mem[00:1F] (stack: empty)
        // 00b2: 596000 MSIZE, PUSH1 0x00 to store memory return range (stack: 0x00, 0x20)
        // 00b5: F3 RETURN

        // TRANSFER FUNCTION

        // 5B338060601B600F178054602435808210610116578082038355
        // 00b6: 5B JUMPDEST for transfer selector
        // 00b7: 33 CALLER (stack: from address)
        // 00b8: 80 DUP1 (stack: from address, from address)
        // 00b9: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, from address, from address)
        // 00bb: 1B SHL shift address 96 bits left (stack: shifted from address, from address)
        // 00bc: 600F PUSH1 0x0F to stack for storage slot offset (stack: 0x0F, shifted from address, from address)
        // 00be: 17 OR combine 0x0F and shifted address for storage slot (stack: from balance storage slot (fbss), from address)
        // 00bf: 80 DUP1 (stack: fbss, fbss, from address)
        // 00c0: 54 SLOAD load storage slot to stack (stack: from balance, fbss, from address)
        // 00c1: 6024 PUSH1 0x24 to stack to load value offset (stack: value offset, from balance, fbss, from address)
        // 00c3: 35 CALLDATALOAD (stack: value, from balance, fbss, from address)
        // 00c4: 80 DUP1 (stack: value, value, from balance, fbss, from address)
        // 00c5: 82 DUP3 (stack: from balance, value, value, from balance, fbss, from address)
        // 00c6: 10 LT (stack: frombalanceLTvalue, value, from balance, fbss, from address)
        // 00c7: 610116 PUSH1 jump destination for from balance less than value (stack: dest, frombalanceLTvalue, value, from balance, fbss, from address)
        // 00ca: 57 JUMPI jump if balance less than value (stack: value, from balance, fbss, from address)
        // 00cb: 80 DUP1 (stack: value, value, from balance, fbss, from address)
        // 00cc: 82 DUP3 (stack: from balance, value, value, from balance, fbss, from address)
        // 00cd: 03 SUB (stack: new from balance, value, from balance, fbss, from address)
        // 00ce: 83 DUP4 (stack: fbss, new from balance, value, from balance, fbss, from address)
        // 00cf: 55 SSTORE (stack: value, from balance, fbss, from address)

        // 60043560601B8060601C90600F178054
        // 00d0: 6004 PUSH1 0x04 to stack to load to address offset (stack: to address offset, value, from balance, fbss, from address)
        // 00d2: 35 CALLDATALOAD (stack: to address, value, from balance, fbss, from address)
        // 00d3: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, to address, value, from balance, fbss, from address)
        // 00d5: 1B SHL shift address 96 bits left (stack: shifted to address, value, from balance, fbss, from address)
        // 00d6: 80 DUP1 (stack: shifted to address, shifted to address, value, from balance, fbss, from address)
        // 00d7: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, shifted to address, shifted to address, value, from balance, fbss, from address)
        // 00d9: 1C SHR shift address 96 bits right (stack: to address, shifted to address, value, from balance, fbss, from address)
        // 00da: 90 SWAP1 (stack: shifted to address, to address, value, from balance, fbss, from address)
        // 00db: 600F PUSH1 0x0F to stack for storage slot offset (stack: 0x0F, shifted to address, to address, value, from balance, fbss, from address)
        // 00dd: 17 OR combine 0x0F and shifted address for storage slot (stack: to balance storage slot (tbss), to address, value, from balance, fbss, from address)
        // 00de: 80 DUP1 (stack: tbss, tbss, to address, value, from balance, fbss, from address)
        // 00df: 54 SLOAD load storage slot to stack (stack: to balance, tbss, to address, value, from balance, fbss, from address)

        // 83019055
        // 00e0: 83 DUP4 (stack: value, to balance, tbss, to address, value, from balance, fbss, from address)
        // 00e1: 01 ADD (stack: new to balance, tbss, to address, value, from balance, fbss, from address)
        // 00e2: 90 SWAP1 (stack: tbss, new to balance, to address, value, from balance, fbss, from address)
        // 00e3: 55 SSTORE (stack: to address, value, from balance, fbss, from address)

        // 905952837FDDF252AD1BE2C89B69C2B068FC378DAA952BA7F163C4A11628F55A4DF523B3EF596000A36001600052596000F3
        // 00e4: 90 SWAP1 (stack: value, to address, from balance, fbss, from address)
        // 00e5: 5952 MSIZE, MSTORE to store value in mem[0x00:0x1f] (stack: to address, from balance, fbss, from address)
        // 00e7: 83 DUP4 (stack: from address, to address, from balance, fbss, from address)
        // 00e8: 7Fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef PUSH32 transfer signature (stack: transfer signature, from address, to address, from balance, fbss, from address)
        // 0109: 596000 MSIZE, PUSH1 0x00 (stack: 0x00, 0x20, transfer signature, from address, to address, from balance, fbss, from address)
        // 010c: A3 LOG3 (stack: from balance, fbss, from address)
        // 010d: 6001600052 PUSH1 0x01, PUSH1 0x00, MSTORE to store 0x01 at mem[0x00:0x1f] (stack: from balance, fbss, from address)
        // 0112: 596000 MSIZE, PUSH1 0x00 (stack: 0x00, 0x20, from balance, fbss, from address)
        // 0115: F3 RETURN

        // 5B63F4D678B8601156
        // 0116: 5B JUMPDEST for balance less than value revert
        // 0117: 63F4D678B8 PUSH4 from balance insufficient error selector (stack: error selector, ...)
        // 011c: 6011 PUSH1 0x11 for revert jump dest (stack: dest, error selector, ...)
        // 011e: 56 JUMP to revert

        // TRANSFER FROM FUNCTION

        // 5B60043560601B8060601C90600F178054
        // 011f: 5B JUMPDEST for transferFrom selector
        // 0120: 6004 PUSH1 0x04 to stack to load to address offset (stack: from address offset)
        // 0122: 35 CALLDATALOAD (stack: from address)
        // 0123: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, from address)
        // 0125: 1B SHL shift address 96 bits left (stack: shifted from address)
        // 0126: 80 DUP1 (stack: shifted from address, shifted from address)
        // 0127: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, shifted from address, shifted from address)
        // 0129: 1C SHR shift address 96 bits right (stack: from address, shifted from address)
        // 012a: 90 SWAP1 (stack: shifted from address, from address)
        // 012b: 600F PUSH1 0x0F to stack for storage slot offset (stack: 0x0F, shifted from address, from address)
        // 012d: 17 OR combine 0x0F and shifted address for storage slot (stack: from balance storage slot (fbss), from address)
        // 012e: 80 DUP1 (stack: fbss, fbss, from address)
        // 012f: 54 SLOAD load storage slot to stack (stack: from balance, fbss, from address)

        // 60443580
        // 0130: 6044 PUSH1 0x44 to stack to load value offset (stack: value offset, from balance, fbss, from address)
        // 0132: 35 CALLDATALOAD (stack: value, from balance, fbss, from address)
        // 0133: 80 DUP1 (stack: value, value, from balance, fbss, from address)

        // 338514610186573360821B607E1C8560821B600E17178054807FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF14610183578083116101D857829003905561018656
        // 0134: 33 CALLER (stack: operator address, value, value, from balance, fbss, from address)
        // 0135: 85 DUP6 copy from address to top of stack (stack: from address, operator address, value, value, from balance, fbss, from address)
        // 0136: 14 EQ check if from address is operator (stack: callerEQfrom, value, value, from balance, fbss, from address)
        // 0137: 610186 PUSH2 dest for if caller is from (stack: dest, callerEQfrom, value, value, from balance, fbss, from address)
        // 013a: 57 JUMPI jump if caller is from (stack: value, value, from balance, fbss, from address)
        // 013b: 33 CALLER (stack: operator address, value, value, from balance, fbss, from address)
        // 013c: 6082 PUSH1 0x82 to stack to shift operator address left 130 bits (stack: 0x82, operator address, value, value, from balance, fbss, from address)
        // 013e: 1B SHL shift operator address left 130 bits (stack: shifted operator address, value, value, from balance, fbss, from address)
        // 013f: 607E PUSH1 0x7E to stack to shift operator address back right 126 bits (stack: 0x7E, shifted operator address, value, value, from balance, fbss, from address)
        // 0141: 1C SHR shift operator address right 126 bits (stack: shifted operator address, value, value, from balance, fbss, from address)
        // 0142: 85 DUP6 copy from address to top of stack (stack: from address, shifted operator address, value, value, from balance, fbss, from address)
        // 0143: 6082 PUSH1 0x82 to stack to shift from address left 130 bits (stack: 0x82, from address, shifted operator address, value, value, from balance, fbss, from address)
        // 0145: 1B SHL shift from address left 130 bits (stack: shifted from address, shifted operator address, value, value, from balance, fbss, from address)
        // 0146: 600E PUSH1 0x0E to stack for approval storage offset (stack: 0x0E, shifted from address, shifted operator address, value, value, from balance, fbss, from address)
        // 0148: 1717 OR x2 to get approval storage slot (stack: approval storage slot, value, value, from balance, fbss, from address)
        // 014a: 80 DUP1 (stack: approval storage slot, approval storage slot, value, value, from balance, fbss, from address)
        // 014b: 54 SLOAD load storage slot to stack (stack: approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 014c: 80 DUP1 (stack: approved amount, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 014d: 7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF PUSH32 uint256 max to stack (stack: -1, approved amount, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 016e: 14 EQ check if approved amount is uint256 max (stack: ismax, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 016f: 610183 PUSH2 dest for approval is uint256 max (stack: dest, ismax, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 0172: 57 JUMPI jump if approval is uint256 max (stack: approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 0173: 80 DUP1 (stack: approved amount, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 0174: 83 DUP4 (stack: value, approved amount, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 0175: 11 GT (stack: valueGTapproved, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 0176: 6101D8 PUSH2 jump dest if value is greater than approved (stack: dest, valueGTapproved, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 0179: 57 JUMPI jump if value is greater than approved (stack: approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 017a: 82 DUP3 (stack: value, approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 017b: 90 SWAP1 (stack: approved amount, value, approval storage slot, value, value, from balance, fbss, from address)
        // 017c: 03 SUB (stack: new approved, approval storage slot, value, value, from balance, fbss, from address)
        // 017d: 90 SWAP1 (stack: approval storage slot, new approved, value, value, from balance, fbss, from address)
        // 017e: 55 SSTORE (stack: value, value, from balance, fbss, from address)
        // 017f: 610186 PUSH2 jump dest for approval amount updated (stack: dest, value, value, from balance, fbss, from address)
        // 0182: 56 JUMP (stack: value, value, from balance, fbss, from address)

        // 5B5050
        // 0183: 5B JUMPDEST destination when approval is uint256 max (stack: approved amount, approval storage slot, value, value, from balance, fbss, from address)
        // 0184: 5050 POP x2 to align stack for transfer (stack: value, value, from balance, fbss, from address)

        // 5B8210610116578082038355
        // 0186: 5B JUMPDEST destination when caller is from, approval amount updated (stack: value, value, from balance, fbss, from address)
        // 0187: 82 DUP3 (stack: from balance, value, value, from balance, fbss, from address)
        // 0188: 10 LT (stack: frombalanceLTvalue, value, from balance, fbss, from address)
        // 0189: 610116 PUSH1 jump destination for from balance less than value (stack: dest, frombalanceLTvalue, value, from balance, fbss, from address)
        // 018c: 57 JUMPI jump if balance less than value (stack: value, from balance, fbss, from address)
        // 018d: 80 DUP1 (stack: value, value, from balance, fbss, from address)
        // 018e: 82 DUP3 (stack: from balance, value, value, from balance, fbss, from address)
        // 018f: 03 SUB (stack: new from balance, value, from balance, fbss, from address)
        // 0190: 83 DUP4 (stack: fbss, new from balance, value, from balance, fbss, from address)
        // 0191: 55 SSTORE (stack: value, from balance, fbss, from address)

        // 60243560601B8060601C90600F17805483019055
        // 0192: 6024 PUSH1 0x24 to stack to load to address offset (stack: to address offset, value, from balance, fbss, from address)
        // 0194: 35 CALLDATALOAD (stack: to address, value, from balance, fbss, from address)
        // 0195: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, to address, value, from balance, fbss, from address)
        // 0197: 1B SHL shift address 96 bits left (stack: shifted to address, value, from balance, fbss, from address)
        // 0198: 80 DUP1 (stack: shifted to address, shifted to address, value, from balance, fbss, from address)
        // 0199: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, shifted to address, shifted to address, value, from balance, fbss, from address)
        // 019b: 1C SHR shift address 96 bits right (stack: to address, shifted to address, value, from balance, fbss, from address)
        // 019c: 90 SWAP1 (stack: shifted to address, to address, value, from balance, fbss, from address)
        // 019d: 600F PUSH1 0x0F to stack for storage slot offset (stack: 0x0F, shifted to address, to address, value, from balance, fbss, from address)
        // 019f: 17 OR combine 0x0F and shifted address for storage slot (stack: to balance storage slot (tbss), to address, value, from balance, fbss, from address)
        // 01a0: 80 DUP1 (stack: tbss, tbss, to address, value, from balance, fbss, from address)
        // 01a1: 54 SLOAD load storage slot to stack (stack: to balance, tbss, to address, value, from balance, fbss, from address)
        // 01a2: 83 DUP4 (stack: value, to balance, tbss, to address, value, from balance, fbss, from address)
        // 01a3: 01 ADD (stack: new to balance, tbss, to address, value, from balance, fbss, from address)
        // 01a4: 90 SWAP1 (stack: tbss, new to balance, to address, value, from balance, fbss, from address)
        // 01a5: 55 SSTORE (stack: to address, value, from balance, fbss, from address)

        // 905952837FDDF252AD1BE2C89B69C2B068FC378DAA952BA7F163C4A11628F55A4DF523B3EF596000A36001600052596000F3
        // 01a6: 90 SWAP1 (stack: value, to address, from balance, fbss, from address)
        // 01a7: 5952 MSIZE, MSTORE to store value in mem[0x00:0x1f] (stack: to address, from balance, fbss, from address)
        // 01a9: 83 DUP4 (stack: from address, to address, from balance, fbss, from address)
        // 01aa: 7Fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef PUSH32 transfer signature (stack: transfer signature, from address, to address, from balance, fbss, from address)
        // 01cb: 596000 MSIZE, PUSH1 0x00 (stack: 0x00, 0x20, transfer signature, from address, to address, from balance, fbss, from address)
        // 01ce: A3 LOG3 (stack: from balance, fbss, from address)
        // 01cf: 6001600052 PUSH1 0x01, PUSH1 0x00, MSTORE to store 0x01 at mem[0x00:0x1f] (stack: from balance, fbss, from address)
        // 01d4: 596000 MSIZE, PUSH1 0x00 (stack: 0x00, 0x20, from balance, fbss, from address)
        // 01d7: F3 RETURN

        // 5B633F726EAC601156
        // 01d8: 5B JUMPDEST for value greater than approval revert
        // 01d9: 633F726EAC PUSH4 from approval insufficient error selector (stack: error selector, ...)
        // 01de: 6011 PUSH1 0x11 for revert jump dest (stack: dest, error selector, ...)
        // 01e0: 56 JUMP to revert

        // APPROVE FUNCTION

        // 5B60243560043560601B60601C33
        // 01e1: 5B JUMPDEST for approve selector
        // 01e2: 6024 PUSH1 0x24 to stack to load value offset (stack: value offset)
        // 01e4: 35 CALLDATALOAD (stack: value)
        // 01e5: 6004 PUSH1 0x04 to stack to load spnder address offset (stack: spender address offset, value)
        // 01e7: 35 CALLDATALOAD (stack: spender address, value)
        // 01e8: 60601B60601C PUSH1 0x60, SHL, PUSH1 0x60 SHR to clean upper bits of spender address (stack: spender address, value)
        // 01ee: 33 CALLER (stack: owner address, spender address, value)

        // 828260821B607E1C8260821B600E171755
        // 01ef: 82 DUP3 (stack: value, owner address, spender address, value)
        // 01f0: 82 DUP3 (stack: spender address, value, owner address, spender address, value)
        // 01f1: 6082 PUSH1 0x82 to stack to shift spender address left 130 bits (stack: 0x82, spender address, value, owner address, spender address, value)
        // 01f3: 1B SHL shift spender address left 130 bits (stack: shifted spender address, value, owner address, spender address, value)
        // 01f4: 607E PUSH1 0x7E to stack to shift spender address back right 126 bits (stack: 0x7E, shifted spender address, value, owner address, spender address, value)
        // 01f6: 1C SHR shift spender address right 126 bits (stack: shifted spender address, value, owner address, spender address, value)
        // 01f7: 82 DUP3 copy owner address to top of stack (stack: owner address, shifted spender address, value, owner address, spender address, value)
        // 01f8: 6082 PUSH1 0x82 to stack to shift owner address left 130 bits (stack: 0x82, owner address, shifted spender address, value, owner address, spender address, value)
        // 01fa: 1B SHL shift owner address left 130 bits (stack: shifted owner address, shifted spender address, value, owner address, spender address, value)
        // 01fb: 600E PUSH1 0x0E to stack for approval storage offset (stack: 0x0E, shifted owner address, shifted spender address, value, owner address, spender address, value)
        // 01fd: 1717 OR x2 to get approval storage slot (stack: approval storage slot, value, owner address, spender address, value)
        // 01ff: 55 SSTORE store new approval value (stack: owner address, spender address, value)

        // 599259527F8C5BE1E5EBEC7D5BD14F71427D1E84F3DD0314C0F7B2291E5B200AC8C7C3B9255984A3600181525990F35B
        // 0200: 5992 MSIZE, SWAP3 (stack: value, owner address, spender address, 0x00)
        // 0202: 5952 MSIZE, MSTORE store value in mem[0x00:0x1f] (stack: owner address, spender address, 0x00)
        // 0204: 7F8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925 PUSH32 approval signature (stack: approval signature, owner address, spender address, 0x00)
        // 0225: 5984 MSIZE, DUP5 (stack: 0x00, 0x20, approval signature, owner address, spender address, 0x00)
        // 0227: A3 LOG3 (stack: 0x00)
        // 0228: 6001 PUSH1 0x01 (stack: 0x01, 0x00)
        // 022a: 8152 DUP2, MSTORE to store 0x01 at mem[0x00:0x1f] (stack: 0x00)
        // 022c: 5990 MSIZE, SWAP1 (stack: 0x00, 0x20)
        // 022e: F3 RETURN
        // 022f: 5B JUMPDEST REMOVE THIS OPCODE (stack: empty)

        // PERMIT FUNCTION

        // 5B6064358042116103E8577FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX4614
        // 73XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX30141661030F57507F8B73C3C69BB8FE3D512ECC4CF759CC79239F7B179B0FFACAA9A75D522B39400F5952
        // 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX59527FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX595246595230595259600020
        // 0230: 5B JUMPDEST for permit selector
        // 0231: 6064 PUSH1 0x64 (stack: 0x64)
        // 0233: 35 CALLDATALOAD (stack: deadline)
        // 0234: 80 DUP1 (stack: deadline, deadline)
        // 0235: 42 TIMESTAMP currentTime (stack: currentTime, deadline, deadline)
        // 0236: 11 GT (stack: currentTimeGTdeadline, deadline)
        // 0237: 6103e8 PUSH2 jump destination if currentTime > deadline (stack: dest, currentTimeGTdeadline, deadline)
        // 023a: 57 JUMPI jump if currentTime > deadline (stack: deadline)
        // 023b: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 cachedDomainSeparator (stack: cachedDomainSeparator, deadline)
        // 025c: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 cachedChainId (stack: cachedChainId, cachedDomainSeparator, deadline)
        // 027d: 46 CHAINID (stack: chainId, cachedChainId, cachedDomainSeparator, deadline)
        // 027e: 14 EQ (stack: chainIdEQcachedChainId, cachedDomainSeparator, deadline)
        // 027f: 73XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH20 cachedAddress (stack: cachedAddress, chainIdEQcachedChainId, cachedDomainSeparator, deadline)
        // 0294: 30 ADDRESS (stack: address, cachedAddress, chainIdEQcachedChainId, cachedDomainSeparator, deadline)
        // 0295: 14 EQ (stack: addressEQcachedAddress, chainIdEQcachedChainId, cachedDomainSeparator, deadline)
        // 0296: 16 AND (stack: useCachedDomainSeparator, cachedDomainSeparator, deadline)
        // 0297: 61030f PUSH2 jump destination for using cached domain separator (stack: dest, useCachedDomainSeparator, cachedDomainSeparator, deadline)
        // 029a: 57 JUMPI jump if using cached domain (stack: cachedDomainSeparator, deadline)
        // 029b: 50 POP remove cachedDomainSeparator from stack (stack: deadline)
        // 029c: 7F8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f PUSH32 (stack: domainTypeHash, deadline)
        // 02bd: 5952 MSIZE, MSTORE to write domain type hash at mem[0x00:0x1f] (stack: deadline)
        // 02bf: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 (stack: cachedNameHash, deadline)
        // 02e0: 5952 MSIZE, MSTORE to write name hash at mem[0x20:0x3f] (stack: deadline)
        // 02e2: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 (stack: cachedVersionHash, deadline)
        // 0303: 5952 MSIZE, MSTORE to write version hash at mem[0x40:0x5f] (stack: deadline)
        // 0305: 46 CHAINID (stack: chainId, deadline)
        // 0306: 5952 MSIZE, MSTORE to write chainId at mem[0x60:0x7f] (stack: deadline)
        // 0308: 30 ADDRESS (stack: address, deadline)
        // 0309: 5952 MSIZE, MSTORE to write address at mem[0x80:0x9f] (stack: deadline)
        // 030b: 596000 MSIZE, PUSH1 0x00 memory offset and length to be hashed (stack: 0x00, 0xA0, deadline)
        // 030e: 20 SHA3 compute hash of memory (stack: domainSeparator, deadline)

        // 5B61190160F01B6000526002527F6E71EDAE12B1B97F4D1F60370FEF10105FA2FAAE0126114A169C64845D6126C960225260C25260443560243560601B60601C60043560601B8060601C80604252826062528360825290600D178054
        // 8060A25260C0602220602252604260002060005260606084602037602060006080600060015AFA156000519081151790841415176103F1576001019055
        // 030f: 5B JUMPDEST destination when we have separator (stack: domainSeparator, deadline)
        // 0310: 611901 PUSH2 message prefix (stack: messagePrefix, domainSeparator, deadline)
        // 0313: 60F01B PUSH1 shift bits, SHL (stack: shiftedMessagePrefix, domainSeparator, deadline)
        // 0316: 600052 PUSH1 0x00, MSTORE to store shifted message prefix in mem[0x00:0x1f] (stack: domain separator, deadline)
        // 0319: 600252 PUSH1 0x02, MSTORE to store domain separator in mem[0x02:0x21] (stack: deadline)
        // 031c: 7F6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9 PUSH32 permit typehash (stack: permitTypeHash, deadline)
        // 033d: 602252 PUSH1 0x22, MSTORE to store permit type hash in mem[0x22:0x41] (stack: deadline)
        // 0340: 60C252 PUSH1 0xC2, MSTORE to store deadline in mem[0xc2:0xe1](stack: empty)
        // 0343: 604435 PUSH1 0x44, CALLDATALOAD to load value (stack: value)
        // 0346: 602435 PUSH1 0x24, CALLDATALOAD to load spender address (stack: spender address, value)
        // 0349: 60601B60601C PUSH1 0x60, SHL, PUSH1 0x60 SHR to clean upper bits of spender address (stack: spender address, value)
        // 034f: 600435 PUSH1 0x04, CALLDATALOAD to load owner address (stack: owner address, spender address, value)
        // 0352: 60601B8060601C PUSH1 0x60, SHL, DUP1, PUSH1 0x60 SHR to clean upper bits of owner address (stack: owner address, shifted owner address, spender address, value)
        // 0359: 80604252 DUP1, PUSH1 0x42, MSTORE to store owner address in mem[0x42:0x61] (stack: owner address, shifted owner address, spender address, value)
        // 035d: 82606252 DUP3, PUSH1 0x62, MSTORE to store spender address in mem[0x62:0x81] (stack: owner address, shifted owner address, spender address, value)
        // 0361: 83608252 DUP4, PUSH1 0x82, MSTORE to store value in mem[0x82:0xa1] (stack: owner address, shifted owner address, spender address, value)
        // 0365: 90 SWAP1 (stack: shifted owner address, owner address, spender address, value)
        // 0366: 600D PUSH1 0x0D to stack for nonce offset (stack: nonce offset, shifted owner address, owner address, spender address, value)
        // 0368: 17 OR combine offset and shifted address to get nonce storage slot (stack: nonceStorageSlot, owner address, spender address, value)
        // 0369: 80 DUP1 duplicate nonceStorageSlot (stack: nonceStorageSlot, nonceStorageSlot, owner address, spender address, value)
        // 036a: 54 SLOAD load nonce (stack: nonce, nonceStorageSlot, owner address, spender address, value)
        // 036b: 8060A252 DUP1, PUSH1 0xA2, MSTORE to store nonce in mem[0xa2:0xc1] (stack: nonce, nonceStorageSlot, owner address, spender address, value)
        // 036f: 60C0602220 PUSH1 0xC0, PUSH1 0x22, SHA3 to calculate hash (stack: permitHash, nonce, nonceStorageSlot, owner address, spender address, value)
        // 0374: 602252 PUSH1 0x22, MSTORE to store permit hash in mem[0x22:0x41] (stack: nonce, nonceStorageSlot, owner address, spender address, value)
        // 0377: 6042600020 PUSH1 0x42, PUSH1 0x00, SHA3 to calculate message hash (stack: messageHash, nonce, nonceStorageSlot, owner address, spender address, value)
        // 037c: 600052 PUSH1 0x00, MSTORE to store message hash to mem[0x00:0x1f] (stack: nonce, nonceStorageSlot, owner address, spender address, value)
        // 037f: 60606084602037 PUSH1 0x60, PUSH1 0x84, PUSH1 0x20 to copy v,r,s to mem[0x20:0x7f] (stack: nonce, nonceStorageSlot, owner address, spender address, value)
        // 0386: 602060006080600060015AFA PUSH1 0x20, PUSH1 0x00, PUSH1 0x80, PUSH1 0x00, PUSH1 0x01, GAS, STATICCALL
        //          calls ecrecover precompile and stores recovered address in mem[0x00:0x1f] (stack: result, nonce, nonceStorageSlot, owner address, spender address, value)
        // 0392: 15 ISZERO flip result to callFailed (stack: callFailed, nonce, nonceStorageSlot, owner address, spender address, value)
        // 0393: 600051 PUSH1 0x00, MLOAD load recovered address to stack (stack: recoveredAddress, callFailed, nonce, nonceStorageSlot, owner address, spender address, value)
        // 0396: 9081 SWAP1, DUP2 (stack: recoveredAddress, callFailed, recoveredAddress, nonce, nonceStorageSlot, owner address, spender address, value)
        // 0398: 15 ISZERO check if recovered address is zero (stack: addressIsZero, callFailed, recoveredAddress, nonce, nonceStorageSlot, owner address, spender address, value)
        // 0399: 17 OR combine addressIsZero and callFailed (stack: addressIsZeroORcallFailed, recoveredAddress, nonce, nonceStorageSlot, owner address, spender address, value)
        // 039a: 9084 SWAP1, DUP5 (stack: owner address, recoveredAddress, addressIsZeroORcallFailed, nonce, nonceStorageSlot, owner address, spender address, value)
        // 039c: 1415 EQ, ISZERO check if owner address matches recovered address (stack: addressMismatch, addressIsZeroORcallFailed, nonce, nonceStorageSlot, owner address, spender address, value)
        // 039e: 17 OR combine failures to check if signature is invalid (stack: signatureInvalid, nonce, nonceStorageSlot, owner address, spender address, value)
        // 039f: 6103f1 PUSH2 jump destination for invalid signature (stack: dest, signatureInvalid, nonce, nonceStorageSlot, owner address, spender address, value)
        // 03a2: 57 JUMPI jump if signature invalid (stack: nonce, nonceStorageSlot, owner address, spender address, value)
        // 03a3: 60010190 PUSH1 0x01, ADD, SWAP1 to increment nonce and flip with storage slot (stack: nonceStorageSlot, incrementedNonce, owner address, spender address, value)
        // 03a7: 55 SSTORE update nonce storage (stack: owner address, spender address, value)

        // 828260821B607E1C8260821B600E171755
        // 03a8: 82 DUP3 (stack: value, owner address, spender address, value)
        // 03a9: 82 DUP3 (stack: spender address, value, owner address, spender address, value)
        // 03aa: 6082 PUSH1 0x82 to stack to shift spender address left 130 bits (stack: 0x82, spender address, value, owner address, spender address, value)
        // 03ac: 1B SHL shift spender address left 130 bits (stack: shifted spender address, value, owner address, spender address, value)
        // 03ad: 607E PUSH1 0x7E to stack to shift spender address back right 126 bits (stack: 0x7E, shifted spender address, value, owner address, spender address, value)
        // 03af: 1C SHR shift spender address right 126 bits (stack: shifted spender address, value, owner address, spender address, value)
        // 03b0: 82 DUP3 copy owner address to top of stack (stack: owner address, shifted spender address, value, owner address, spender address, value)
        // 03b1: 6082 PUSH1 0x82 to stack to shift owner address left 130 bits (stack: 0x82, owner address, shifted spender address, value, owner address, spender address, value)
        // 03b3: 1B SHL shift owner address left 130 bits (stack: shifted owner address, shifted spender address, value, owner address, spender address, value)
        // 03b4: 600E PUSH1 0x0E to stack for approval storage offset (stack: 0x0E, shifted owner address, shifted spender address, value, owner address, spender address, value)
        // 03b6: 1717 OR x2 to get approval storage slot (stack: approval storage slot, value, owner address, spender address, value)
        // 03b8: 55 SSTORE store new approval value (stack: owner address, spender address, value)

        // 826000527F8C5BE1E5EBEC7D5BD14F71427D1E84F3DD0314C0F7B2291E5B200AC8C7C3B92560206000A360006000F3
        // 03b9: 82 DUP3 (stack: value, owner address, spender address, value)
        // 03ba: 600052 PUSH1 0x00, MSTORE to store value in mem[0x00:0x1f] (stack: owner address, spender address, value)
        // 03bd: 7F8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925 PUSH32 approval signature (stack: approval signature, owner address, spender address, value)
        // 03de: 60206000 PUSH1 0x20, PUSH1 0x00 (stack: 0x00, 0x20, approval signature, owner address, spender address, value)
        // 03e2: A3 LOG3 (stack: value)
        // 03e3: 60006000 PUSH1 0x00, PUSH1 0x00 (stack: 0x00, 0x00, value)
        // 03e7: F3 RETURN

        // 5B631AB7DA6B601156
        // 03e8: 5B JUMPDEST for deadline expired revert
        // 03e9: 631AB7DA6B PUSH4 deadline expired error selector (stack: error selector, ...)
        // 03ee: 6011 PUSH1 0x11 for revert jump dest (stack: dest, error selector, ...)
        // 03f0: 56 JUMP to revert

        // 5B638BAA579F601156
        // 03f1: 5B JUMPDEST for invalid signature revert
        // 03f2: 638BAA579F PUSH4 invalid signature error selector (stack: error selector, ...)
        // 03f7: 6011 PUSH1 0x11 for revert jump dest (stack: dest, error selector, ...)
        // 03f9: 56 JUMP to revert

        // ALLOWANCE FUNCTION

        // 5B60243560821B607E1C60043560821B600E1717545952596000F3
        // 03fa: 5B JUMPDEST for allowance function
        // 03fb: 602435 PUSH1 0x24, CALLDATALOAD to load spender to stack (stack: spender address)
        // 03fe: 60821B607E1C PUSH1 0x82, SHL, PUSH1 0x7E, SHR to clean upper bits and position spender address (stack: shifted spender address)
        // 0404: 600435 PUSH1 0x04, CALLDATALOAD to load owner to stack (stack: owner address, shifted spender address)
        // 0407: 60821B PUSH1 0x82, SHL to position owner address (stack: shifted owner address, shifted spender address)
        // 040a: 600E PUSH1 0x0E to push approval storage offset to stack (stack: 0x0E, shifted owner address, shifted spender address)
        // 040c: 1717 OR x2 to combine stack items for approval storage slot (stack: approvalStorageSlot)
        // 040e: 54 SLOAD load approval amount (stack: approvalAmount)
        // 040f: 5952 MSIZE, MSTORE to store approvalAmount in mem[0x00:0x1f] (stack: empty)
        // 0411: 596000 MSIZE, PUSH1 0x00 for return offset and length (stack: 0x00, 0x20)
        // 0414: F3 RETURN

        // TOTAL SUPPLY FUNCTION

        // 5B7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX5952596000F3
        // 0415: 5B JUMPDEST for totalSupply function
        // 0416: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 totalSupply amount (stack: totalSupply)
        // 0437: 5952 MSIZE, MSTORE to store totalSupply in mem[0x00:0x1f] (stack: empty)
        // 0439: 596000 MSIZE, PUSH1 0x00 for return offset and length (stack: 0x00, 0x20)
        // 043c: F3 RETURN

        // NAME FUNCTION

        // 5B6020595261XXXX6105565939596000F3
        // 043d: 5B JUMPDEST for name function
        // 043e: 60205952 PUSH1 0x20, MSIZE, MSTORE to store 0x20 in mem[0x00:0x1f] (stack: empty)
        // 0442: 61XXXX PUSH2 size of name data to copy to memory (stack: nameDataLen)
        // 0445: 610556 PUSH2 name data offset (stack: nameDataOffset, nameDataLen)
        // 0448: 5939 MSIZE, CODECOPY to copy name data to memory
        // 044a: 596000 MSIZE, PUSH1 0x00 for return offset and length (stack: 0x00, memsize)
        // 044d: F3 RETURN

        // SYMBOL FUNCTION

        // 5B6020595261XXXX61XXXX5939596000F3
        // 044e: 5B JUMPDEST for symbol function
        // 044f: 60205952 PUSH1 0x20, MSIZE, MSTORE to store 0x20 in mem[0x00:0x1f] (stack: empty)
        // 0453: 61XXXX PUSH2 size of symbol data to copy to memory (stack: symbolDataLen)
        // 0456: 61XXXX PUSH2 symbol data offset (stack: symbolDataOffset, symbolDataLen)
        // 0459: 5939 MSIZE, CODECOPY to copy symbol data to memory
        // 045b: 596000 MSIZE, PUSH1 0x00 for return offset and length (stack: 0x00, memsize)
        // 045e: F3 RETURN

        // DECIMALS FUNCTION

        // 5B60XX5952596000F3
        // 045f: 5B JUMPDEST for decimals function
        // 0460: 60XX PUSH1 decimals (stack: decimals)
        // 0462: 5952 MSIZE, MSTORE to store decimals in mem[0x00:0x1f] (stack: empty)
        // 0464: 596000 MSIZE, PUSH1 0x00 for return offset and length (stack: 0x00, 0x20)
        // 0467: F3 RETURN

        // DOMAIN_SEPARATOR FUNCTION

        // 5B7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX461473XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        // 30141661053C577F8B73C3C69BB8FE3D512ECC4CF759CC79239F7B179B0FFACAA9A75D522B39400F59527FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX5952
        // 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX5952465952305952596000205B60005260206000F3
        // 0468: 5B JUMPDEST for domain separator selector
        // 0469: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 cachedDomainSeparator (stack: cachedDomainSeparator)
        // 048a: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 cachedChainId (stack: cachedChainId, cachedDomainSeparator)
        // 04ab: 46 CHAINID (stack: chainId, cachedChainId, cachedDomainSeparator)
        // 04ac: 14 EQ (stack: chainIdEQcachedChainId, cachedDomainSeparator)
        // 04ad: 73XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH20 cachedAddress (stack: cachedAddress, chainIdEQcachedChainId, cachedDomainSeparator)
        // 04c2: 30 ADDRESS (stack: address, cachedAddress, chainIdEQcachedChainId, cachedDomainSeparator)
        // 04c3: 14 EQ (stack: addressEQcachedAddress, chainIdEQcachedChainId, cachedDomainSeparator)
        // 04c4: 16 AND (stack: useCachedDomainSeparator, cachedDomainSeparator)
        // 04c5: 61053C PUSH2 jump destination for using cached domain separator (stack: dest, useCachedDomainSeparator, cachedDomainSeparator)
        // 04c8: 57 JUMPI jump if using cached domain (stack: cachedDomainSeparator)
        // 04c9: 7F8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f PUSH32 (stack: domainTypeHash, cachedDomainSeparator)
        // 04ea: 5952 MSIZE, MSTORE to write domain type hash at mem[0x00:0x1f] (stack: cachedDomainSeparator)
        // 04ec: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 (stack: cachedNameHash, cachedDomainSeparator)
        // 050d: 5952 MSIZE, MSTORE to write name hash at mem[0x20:0x3f] (stack: cachedDomainSeparator)
        // 050f: 7FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX PUSH32 (stack: cachedVersionHash, cachedDomainSeparator)
        // 0530: 5952 MSIZE, MSTORE to write version hash at mem[0x40:0x5f] (stack: cachedDomainSeparator)
        // 0532: 46 CHAINID (stack: chainId, cachedDomainSeparator)
        // 0533: 5952 MSIZE, MSTORE to write chainId at mem[0x60:0x7f] (stack: cachedDomainSeparator)
        // 0535: 30 ADDRESS (stack: address, cachedDomainSeparator)
        // 0536: 5952 MSIZE, MSTORE to write address at mem[0x80:0x9f] (stack: cachedDomainSeparator)
        // 0538: 596000 MSIZE, PUSH1 0x00 memory offset and length to be hashed (stack: 0x00, 0xA0, cachedDomainSeparator)
        // 053b: 20 SHA3 compute hash of memory (stack: domainSeparator, cachedDomainSeparator)
        // 053c: 5B JUMPDEST for domainSeparator return (stack: domainSeparatorToReturn, ...)
        // 053d: 600052 PUSH1 0x00, MSTORE to store hash in mem[0x00:0x1f] (stack: empty/...)
        // 0540: 60206000 PUSH1 0x20, PUSH1 0x00 for return offset and length (stack: 0x00, 0x20, ...)
        // 0544: F3 RETURN

        // NONCES FUNCTION

        // 5B60043560601B600D17545952596000F3
        // 0545: 5B JUMPDEST for nonces selector
        // 0546: 6004 PUSH1 0x04 to stack to load address offset (stack: address offset)
        // 0548: 35 CALLDATALOAD (stack: address)
        // 0549: 6060 PUSH1 0x60 to stack for address shift (stack: 0x60, address)
        // 054b: 1B SHL shift address 96 bits left (stack: shifted address)
        // 054c: 600D PUSH1 0x0D to stack for storage slot offset (stack: 0x0D, shifted address)
        // 054e: 17 OR combine 0x0D and shifted address for storage slot (stack: nonce storage slot)
        // 054f: 54 SLOAD load storage slot to stack (stack: nonce)
        // 0550: 59 MSIZE to put a 0 on stack (stack: 0, nonce)
        // 0551: 52 MSTORE to store nonce at mem[00:1F] (stack: empty)
        // 0552: 596000 MSIZE, PUSH1 0x00 to store memory return range (stack: 0x00, 0x20)
        // 0555: F3 RETURN

        // 0556: <<NAME DATA>>
        // 0556+namedatalength: <<SYMBOL DATA>>
    }

    // ERC-20 FUNCTIONS
    function name() public view returns (string memory) {} // 0x06fdde03
    function symbol() public view returns (string memory) {} // 0x95d89b41
    function decimals() public view returns (uint8) {} // 0x313ce567
    function totalSupply() public view returns (uint256) {} // 0x18160ddd
    function balanceOf(address _owner) public view returns (uint256 balance) {} // 0x70a08231
    function transfer(address _to, uint256 _value) public returns (bool success) {} // 0xa9059cbb
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {} // 0x23b872dd
    function approve(address _spender, uint256 _value) public returns (bool success) {} // 0x095ea7b3
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {} // 0xdd62ed3e

    // EIP-2612 FUNCTIONS
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {} // 0xd505accf
    function nonces(address owner) external view returns (uint256) {} // 0x7ecebe00
    function DOMAIN_SEPARATOR() external view returns (bytes32) {} // 0x3644e515
}
