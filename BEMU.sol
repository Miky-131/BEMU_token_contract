// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Router {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract BEMU is ERC20, Ownable {
    using SafeMath for uint256;

    // Tokenomics
    uint256 public constant TOTAL_SUPPLY = 3_140_000_000 * 10 ** 18;
    uint256 public constant MAX_TRANSACTION_SIZE = (TOTAL_SUPPLY * 2) / 100; // 2% of total supply
    uint256 public constant ADDITIONAL_FEE_THRESHOLD =
        (TOTAL_SUPPLY * 5) / 1000; // 0.5% of total supply

    // Fees
    struct FeeStructure {
        uint256 liquidityFee;
        uint256 marketingFee;
        uint256 rewardFee;
    }

    FeeStructure public buyFees =
        FeeStructure({liquidityFee: 4, marketingFee: 3, rewardFee: 3});
    FeeStructure public sellFees =
        FeeStructure({liquidityFee: 5, marketingFee: 4, rewardFee: 4});

    uint256 public additionalFee = 2; // Additional fee for large transactions

    address public marketingWallet;
    address public liquidityWallet;
    address public sushiSwapRouterAddress;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromRewards;

    uint256 private _totalRewards;
    uint256 private _totalExcluded;

    IUniswapV2Router public sushiSwapRouter;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensAddedToLiquidity
    );

    constructor(
        address _marketingWallet,
        address _liquidityWallet,
        address _sushiSwapRouterAddress
    ) ERC20("BEMU", "BEMU") {
        _mint(msg.sender, TOTAL_SUPPLY);
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
        sushiSwapRouterAddress = _sushiSwapRouterAddress;
        sushiSwapRouter = IUniswapV2Router(_sushiSwapRouterAddress);

        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromRewards[address(this)] = true;
        isExcludedFromRewards[marketingWallet] = true;
        isExcludedFromRewards[liquidityWallet] = true;

        // Approve the SushiSwap router for the entire token supply
        _approve(address(this), address(sushiSwapRouter), type(uint256).max);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(
            amount <= MAX_TRANSACTION_SIZE,
            "Exceeds maximum transaction size"
        );

        uint256 fees = 0;

        if (!isExcludedFromFees[sender] && !isExcludedFromFees[recipient]) {
            if (amount > ADDITIONAL_FEE_THRESHOLD) {
                fees = fees.add(amount.mul(additionalFee).div(100));
            }

            if (isSellTransaction(sender, recipient)) {
                fees = fees.add(
                    amount
                        .mul(
                            sellFees
                                .liquidityFee
                                .add(sellFees.marketingFee)
                                .add(sellFees.rewardFee)
                        )
                        .div(100)
                );
            } else {
                fees = fees.add(
                    amount
                        .mul(
                            buyFees.liquidityFee.add(buyFees.marketingFee).add(
                                buyFees.rewardFee
                            )
                        )
                        .div(100)
                );
            }
        }

        if (fees > 0) {
            uint256 liquidityPortion = fees
                .mul(
                    isSellTransaction(sender, recipient)
                        ? sellFees.liquidityFee
                        : buyFees.liquidityFee
                )
                .div(100);
            uint256 marketingPortion = fees
                .mul(
                    isSellTransaction(sender, recipient)
                        ? sellFees.marketingFee
                        : buyFees.marketingFee
                )
                .div(100);
            uint256 rewardsPortion = fees.sub(liquidityPortion).sub(
                marketingPortion
            );

            _swapAndLiquidify(liquidityPortion);
            _transferToMarketing(marketingPortion);
            _distributeRewards(rewardsPortion);

            amount = amount.sub(fees);
        }

        super._transfer(sender, recipient, amount);
    }

function _swapAndLiquidify(uint256 tokenAmount) private {
    // Split the tokenAmount into halves
    uint256 half = tokenAmount.div(2);
    uint256 otherHalf = tokenAmount.sub(half);

    // Capture the initial ETH balance
    uint256 initialBalance = address(this).balance;

    // Swap half of the tokens for ETH
    address;
    path[0] = address(this);
    path[1] = sushiSwapRouter.WETH();

    sushiSwapRouter.swapExactTokensForETH(
        half,
        0, // Accept any amount of ETH
        path,
        address(this),
        block.timestamp
    );

    // Calculate the amount of ETH swapped
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // Add liquidity to SushiSwap
    sushiSwapRouter.addLiquidityETH{value: newBalance}(
        address(this),
        otherHalf,
        0, // Slippage is ignored
        0, // Slippage is ignored
        liquidityWallet,
        block.timestamp
    );

    emit SwapAndLiquify(half, newBalance, otherHalf);
}

    function _transferToMarketing(uint256 amount) private {
        super._transfer(msg.sender, marketingWallet, amount);
    }

    function _distributeRewards(uint256 rewardAmount) private {
        uint256 totalSupplyForRewards = TOTAL_SUPPLY.sub(_totalExcluded);

        for (uint256 i = 0; i < balanceOf(address(this)); i++) {
            address account = address(this);
            if (!isExcludedFromRewards[account]) {
                uint256 accountBalance = balanceOf(account);
                uint256 reward = rewardAmount.mul(accountBalance).div(
                    totalSupplyForRewards
                );
                _transfer(address(this), account, reward);
            }
        }
    }

    function isSellTransaction(
        address sender,
        address recipient
    ) private view returns (bool) {
        return recipient == liquidityWallet;
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function excludeFromRewards(
        address account,
        bool excluded
    ) external onlyOwner {
        isExcludedFromRewards[account] = excluded;
        if (excluded) {
            _totalExcluded = _totalExcluded.add(balanceOf(account));
        } else {
            _totalExcluded = _totalExcluded.sub(balanceOf(account));
        }
    }

    receive() external payable {}
}
