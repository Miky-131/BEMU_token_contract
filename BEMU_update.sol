// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18; // Standard decimals
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(
            _balances[account] >= amount,
            "ERC20: burn amount exceeds balance"
        );

        _balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract BemuToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private BUY_LIQUIDITY_FEE = 4; // 4%
    uint256 private BUY_MARKETING_FEE = 1; // 1%
    uint256 private BUY_BUYBACK_FEE = 1; // 1%
    uint256 constant MAX_BUY_FEE_TOTAL = 10; //the total buy fee is 10% maximum
    uint256 private SELL_LIQUIDITY_FEE = 6; // 6%
    uint256 private SELL_MARKETING_FEE = 4; // 4%
    uint256 private SELL_BUYBACK_FEE = 2; // 2%
    uint256 constant MAX_SELL_FEE_TOTAL = 15; //the total buy fee is 10% maximum

    event SetFees(
        uint256 BUY_LIQUIDITY_FEE,
        uint256 BUY_MARKETING_FEE,
        uint256 BUY_BUYBACK_FEE,
        uint256 SELL_LIQUIDITY_FEE,
        uint256 SELL_MARKETING_FEE,
        uint256 SELL_BUYBACK_FEE
    );
    event UpdateThresholds(uint256 buybackThreshold, uint256 liquidityThreshold);
    event MaxTransactionAmountUpdated(uint256 maxTransactionAmount);
    event MaxWalletHoldingUpdated(uint256 maxWalletHolding);

    address public marketingWallet;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isPair;

    uint256 public buybackThreshold = 200000000 * 10**18; // Threshold to perform buyback
    uint256 public liquidityThreshold = 100000000 * 10**18; // Threshold to provide liquidity

    bool private inSwapAndLiquify;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    uint256 public buybackPool;
    uint256 public liquidityPool;

    // Anti-whale variables
    uint256 public maxTransactionAmount;
    uint256 public maxWalletHolding;

    IUniswapV2Router02 public uniswapRouter;

    constructor(address _marketingWallet)
        ERC20("BEMU", "BEMU")
    {
        marketingWallet = _marketingWallet;
        _mint(msg.sender, 3_140_000_000 * 10**decimals); // Mint 3.14B tokens

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount <= maxTransactionAmount, "Transfer amount exceeds the max transaction limit");
        require(balanceOf(recipient) + amount <= maxWalletHolding, "Recipient wallet exceeds the max holding limit");
        if (isExcludedFromFees[sender] || isExcludedFromFees[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 totalFee;
        uint256 marketingFee;
        uint256 liquidityFee;
        uint256 buybackFee;

        if (isPair[sender]) {
            // Buy fees
            marketingFee = (amount * BUY_MARKETING_FEE) / 100;
            liquidityFee = (amount * BUY_LIQUIDITY_FEE) / 100;
            buybackFee = (amount * BUY_BUYBACK_FEE) / 100;
        } else if (isPair[recipient]) {
            // Sell fees
            marketingFee = (amount * SELL_MARKETING_FEE) / 100;
            liquidityFee = (amount * SELL_LIQUIDITY_FEE) / 100;
            buybackFee = (amount * SELL_BUYBACK_FEE) / 100;
        }

        totalFee = marketingFee + liquidityFee + buybackFee;

        if (totalFee > 0) {
            // Transfer marketing fee directly to the marketing wallet
            if (marketingFee > 0) {
                super._transfer(sender, marketingWallet, marketingFee);
            }

            // Accumulate liquidity and buyback fees
            liquidityPool += liquidityFee;
            buybackPool += buybackFee;

            // Transfer the remaining fees to the contract
            super._transfer(sender, address(this), totalFee - marketingFee);
        }

        if (
            !inSwapAndLiquify &&
            liquidityPool >= liquidityThreshold &&
            !isPair[sender]
        ) {
            provideLiquidity();
        }
        if (buybackPool >= buybackThreshold) {
            performBuybackAndBurn();
        }
        // Transfer the remaining tokens to the recipient
        super._transfer(sender, recipient, amount - totalFee);
    }

    function provideLiquidity() private lockTheSwap {
        uint256 half = liquidityPool.div(2);
        uint256 otherHalf = liquidityPool.sub(half);

        uint256 initialBalance = address(this).balance;

        // Swap tokens for ETH
        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Add liquidity
        addLiquidity(otherHalf, newBalance);

        liquidityPool = 0; // Reset pool
    }

    function performBuybackAndBurn() private {
        if (liquidityPool == 0) {
            super._burn(address(this), balanceOf(address(this)));
            buybackPool = 0;
        } else {
            super._burn(address(this), buybackPool); // Burn tokens
            buybackPool = 0; // Reset pool
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);

        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Min tokens
            0, // Min ETH
            owner(),
            block.timestamp
        );
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function setFees(
        uint256 _BUY_LIQUIDITY_FEE,
        uint256 _BUY_MARKETING_FEE,
        uint256 _BUY_BUYBACK_FEE,
        uint256 _SELL_LIQUIDITY_FEE,
        uint256 _SELL_MARKETING_FEE,
        uint256 _SELL_BUYBACK_FEE
    ) external onlyOwner {
        require(
            _BUY_LIQUIDITY_FEE + _BUY_MARKETING_FEE + _BUY_BUYBACK_FEE <= MAX_BUY_FEE_TOTAL,
            "Buy total fees exceed the maximum limit of 15%"
        );
        require(
            _SELL_LIQUIDITY_FEE + _SELL_MARKETING_FEE + _SELL_BUYBACK_FEE <= MAX_SELL_FEE_TOTAL,
            "Sell total fees exceed the maximum limit of 15%"
        );
        BUY_LIQUIDITY_FEE = _BUY_LIQUIDITY_FEE;
        BUY_MARKETING_FEE = _BUY_MARKETING_FEE;
        BUY_BUYBACK_FEE = _BUY_BUYBACK_FEE;
        SELL_LIQUIDITY_FEE = _SELL_LIQUIDITY_FEE;
        SELL_MARKETING_FEE = _SELL_MARKETING_FEE;
        SELL_BUYBACK_FEE = _SELL_BUYBACK_FEE;

        //Emit the FeesUpdated event
        emit SetFees(
            _BUY_LIQUIDITY_FEE,
            _BUY_MARKETING_FEE,
            _BUY_BUYBACK_FEE,
            _SELL_LIQUIDITY_FEE,
            _SELL_MARKETING_FEE,
            _SELL_BUYBACK_FEE
        );
    }

    function getFees() external view returns (
            uint256 buyLiquidityFee,
            uint256 buyMarketingFee,
            uint256 buyBuybackFee,
            uint256 sellLiquidityFee,
            uint256 sellMarketingFee,
            uint256 sellBuybackFee
        )
    {
        return (
            BUY_LIQUIDITY_FEE,
            BUY_MARKETING_FEE,
            BUY_BUYBACK_FEE,
            SELL_LIQUIDITY_FEE,
            SELL_MARKETING_FEE,
            SELL_BUYBACK_FEE
        );
    }

    function setUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function setPair(address pair, bool value) external onlyOwner {
        isPair[pair] = value;
    }

    function updateThresholds(
        uint256 _buybackThreshold,
        uint256 _liquidityThreshold
    ) external onlyOwner {
        buybackThreshold = _buybackThreshold;
        liquidityThreshold = _liquidityThreshold;

        emit UpdateThresholds(_buybackThreshold, _liquidityThreshold);
    }

    function updateMaxTransactionAmount(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Percentage must be under 100"); // Ensure the percentage is reasonable (1% to 100%)
        maxTransactionAmount = (totalSupply * percentage) / 100;
        emit MaxTransactionAmountUpdated(maxTransactionAmount);
    }

    function updateMaxWalletHolding(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Percentage must be under 100"); // Ensure the percentage is reasonable (1% to 100%)
        maxWalletHolding = (totalSupply * percentage) / 100;
        emit MaxWalletHoldingUpdated(maxWalletHolding);
    }

    receive() external payable {}
}
