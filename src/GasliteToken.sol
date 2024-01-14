// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

/// @title GasliteToken
/// @notice Turbo gas optimized ERC20 token with fees
/// @author Harrison (@PopPunkOnChain)
/// @author 0xjustadev (@0xjustadev)
/// @author Gaslite (@GasliteGG)
contract GasliteToken is Ownable {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public immutable totalSupply;

    address private lpTokenRecipient;
    address private airdropper;
    address public treasuryWallet;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint8 public constant MAX_BUY_FEES = 100;
    uint8 public constant MAX_SELL_FEES = 100;
    uint8 public constant TRADING_DISABLED = 0;
    uint8 public constant TRADING_ENABLED = 1;
    uint8 public buyTotalFees;
    uint8 public sellTotalFees;
    uint8 public tradingStatus = TRADING_DISABLED;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _allowedDuringPause;
    mapping(address => bool) private automatedMarketMakerPairs;

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    error ZeroAddress();
    error InsufficientAllowance();
    error InsufficientBalance();
    error CannotRemoveV2Pair();
    error WithdrawalFailed();
    error InvalidState();
    error FeesExceedMax();
    error TradingDisabled();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _lpTokenRecipient,
        uint8 _buyTotalFees,
        uint8 _sellTotalFees,
        address _treasuryWallet,
        address _airdropper
    ) payable Ownable(_lpTokenRecipient) {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH);
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        lpTokenRecipient = _lpTokenRecipient;
        buyTotalFees = _buyTotalFees;
        sellTotalFees = _sellTotalFees;
        treasuryWallet = _treasuryWallet;
        airdropper = _airdropper;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[treasuryWallet] = true;
        _allowedDuringPause[airdropper] = true;

        uint256 tokenToLP = totalSupply * 25 / 100;
        uint256 tokenToAirdrop = totalSupply - tokenToLP;

        _balances[airdropper] = tokenToAirdrop;
        emit Transfer(address(0), airdropper, tokenToAirdrop);
        _balances[address(this)] = tokenToLP;
        emit Transfer(address(0), address(this), tokenToLP);

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    function startTrading(uint256 tokenPerEth) external payable onlyOwner {
        uint256 ethToLP = address(this).balance;
        uint256 tokenToLP = tokenPerEth * address(this).balance;
        uint256 tokenBalance = _balances[address(this)];
        if (tokenToLP > tokenBalance) {
            tokenToLP = tokenBalance;
            ethToLP = tokenToLP / tokenPerEth;
        }
        uniswapV2Router.addLiquidityETH{value: ethToLP}(
            address(this), tokenToLP, 0, 0, lpTokenRecipient, block.timestamp
        );
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0)) revert ZeroAddress();
        if (spender == address(0)) revert ZeroAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert InsufficientAllowance();
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();

        if (tradingStatus == TRADING_DISABLED) {
            if (from != owner() && from != treasuryWallet && from != address(this) && to != owner()) {
                if (!_allowedDuringPause[from]) {
                    revert TradingDisabled();
                }
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 senderBalance = _balances[from];
        if (senderBalance < amount) revert InsufficientBalance();

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 1000;
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 1000;
            }

            if (fees > 0) {
                unchecked {
                    amount = amount - fees;
                    _balances[from] -= fees;
                    _balances[treasuryWallet] += fees;
                }
                emit Transfer(from, treasuryWallet, fees);
            }
        }
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function setFees(uint8 _buyTotalFees, uint8 _sellTotalFees) external onlyOwner {
        if (_buyTotalFees > MAX_BUY_FEES || _sellTotalFees > MAX_SELL_FEES) revert FeesExceedMax();
        buyTotalFees = _buyTotalFees;
        sellTotalFees = _sellTotalFees;
    }

    function setExcludedFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAllowedDuringPause(address account, bool allowed) public onlyOwner {
        _allowedDuringPause[account] = allowed;
    }

    function enableTrading() public onlyOwner {
        tradingStatus = TRADING_ENABLED;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        if (pair == uniswapV2Pair) revert CannotRemoveV2Pair();
        automatedMarketMakerPairs[pair] = value;
    }

    function updateTreasuryWallet(address newAddress) external onlyOwner {
        if (newAddress == address(0)) revert ZeroAddress();
        treasuryWallet = newAddress;
    }

    function excludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawToken(address token, address to) external onlyOwner {
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(token), to, _contractBalance);
    }

    function withdrawETH(address addr) external onlyOwner {
        if (addr == address(0)) revert ZeroAddress();

        (bool success,) = addr.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
    }
}
