// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BEMU is ERC20, Ownable {
    using SafeMath for uint256;

    // Tokenomics
    uint256 public constant TOTAL_SUPPLY = 3_140_000_000 * 10 ** 18;
    uint256 public constant MAX_TRANSACTION_SIZE = TOTAL_SUPPLY * 2 / 100; // 2% of total supply
    uint256 public constant ADDITIONAL_FEE_THRESHOLD = TOTAL_SUPPLY * 5 / 1000; // 0.5% of total supply

    // Fees
    struct FeeStructure {
        uint256 liquidityFee;
        uint256 marketingFee;
        uint256 rewardFee;
    }

    FeeStructure public buyFees = FeeStructure({liquidityFee: 4, marketingFee: 3, rewardFee: 3});
    FeeStructure public sellFees = FeeStructure({liquidityFee: 5, marketingFee: 4, rewardFee: 4});

    uint256 public additionalFee = 2; // Additional fee for large transactions

    address public marketingWallet;
    address public liquidityWallet;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromRewards;

    uint256 private _totalRewards;

    constructor(address _marketingWallet, address _liquidityWallet) ERC20("BEMU", "BEMU") {
        _mint(msg.sender, TOTAL_SUPPLY);
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
        
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromRewards[address(this)] = true;
        isExcludedFromRewards[marketingWallet] = true;
        isExcludedFromRewards[liquidityWallet] = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount <= MAX_TRANSACTION_SIZE, "Exceeds maximum transaction size");

        uint256 fees = 0;

        if (!isExcludedFromFees[sender] && !isExcludedFromFees[recipient]) {
            if (amount > ADDITIONAL_FEE_THRESHOLD) {
                fees = fees.add(amount.mul(additionalFee).div(100));
            }

            if (isSellTransaction(sender, recipient)) {
                fees = fees.add(amount.mul(sellFees.liquidityFee.add(sellFees.marketingFee).add(sellFees.rewardFee)).div(100));
            } else {
                fees = fees.add(amount.mul(buyFees.liquidityFee.add(buyFees.marketingFee).add(buyFees.rewardFee)).div(100));
            }
        }

        if (fees > 0) {
            uint256 liquidityPortion = fees.mul(isSellTransaction(sender, recipient) ? sellFees.liquidityFee : buyFees.liquidityFee).div(100);
            uint256 marketingPortion = fees.mul(isSellTransaction(sender, recipient) ? sellFees.marketingFee : buyFees.marketingFee).div(100);
            uint256 rewardsPortion = fees.sub(liquidityPortion).sub(marketingPortion);

            _transferToLiquidity(liquidityPortion);
            _transferToMarketing(marketingPortion);
            _distributeRewards(rewardsPortion);

            amount = amount.sub(fees);
        }

        super._transfer(sender, recipient, amount);
    }

    function _transferToLiquidity(uint256 amount) private {
        super._transfer(msg.sender, liquidityWallet, amount);
    }

    function _transferToMarketing(uint256 amount) private {
        super._transfer(msg.sender, marketingWallet, amount);
    }

    function _distributeRewards(uint256 amount) private {
        _totalRewards = _totalRewards.add(amount);
    }

    function isSellTransaction(address sender, address recipient) private view returns (bool) {
        return recipient == liquidityWallet;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function excludeFromRewards(address account, bool excluded) external onlyOwner {
        isExcludedFromRewards[account] = excluded;
    }
}
