// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

abstract contract UniswapV3Helper {
    ISwapRouter public routerV3;
    IQuoter public quoterV3;

    constructor(address _routerV3, address _quoterV3) {
        routerV3 = ISwapRouter(_routerV3);
        quoterV3 = IQuoter(_quoterV3);
    }

    function _getPotentialSwapInfoByAmountV3(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        if (amountIn == 0) return 0;

        amountOut = quoterV3.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            0
        );
    }

    function _swapExactTokensForTokensV3(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        require(amountIn > 0, "No input token balance");

        uint256 estimatedAmountOut = _getPotentialSwapInfoByAmountV3(
            tokenIn,
            tokenOut,
            fee,
            amountIn
        );
        require(estimatedAmountOut > amountIn, "No profit: output <= input");

        IERC20(tokenIn).approve(address(routerV3), amountIn);

        amountOut = routerV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: estimatedAmountOut,
                sqrtPriceLimitX96: 0
            })
        );
    }
}
