// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

abstract contract UniswapV2Helper {
    IUniswapV2Router public router;

    constructor(address _router) {
        router = IUniswapV2Router(_router);
    }

    function _doSwapV2(address tokenFirst, address tokenSecond) internal {
        uint256 tokenFirstBalance = IERC20(tokenFirst).balanceOf(address(this));
        uint256 tokenSecondBalance = IERC20(tokenSecond).balanceOf(
            address(this)
        );

        if (tokenSecondBalance > tokenFirstBalance) {
            _swapExactTokensForTokens(tokenSecond, tokenFirst);
        } else {
            _swapExactTokensForTokens(tokenFirst, tokenSecond);
        }
    }

    function _getPotentialSwapInfoByAmountV2(
        address tokenFirst,
        address tokenSecond,
        uint256 amountIn,
        bool firstToSecond
    ) internal view returns (uint256, uint256, address[] memory) {
        address[] memory path = new address[](2);
        if (firstToSecond) {
            path[0] = tokenFirst;
            path[1] = tokenSecond;
        } else {
            path[0] = tokenSecond;
            path[1] = tokenFirst;
        }

        if (amountIn == 0) {
            return (0, 0, path);
        }

        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint256 amountOut = amountsOut[1];

        return (amountIn, amountOut, path);
    }

    function _getPotentialSwapInfoV2(
        address tokenFirst,
        address tokenSecond
    )
        internal
        view
        returns (uint256 amountIn, uint256 amountOut, address[] memory path)
    {
        uint256 balanceFirst = IERC20(tokenFirst).balanceOf(address(this));
        uint256 balanceSecond = IERC20(tokenSecond).balanceOf(address(this));

        if (balanceSecond > balanceFirst && balanceSecond > 0) {
            path = new address[](2);
            path[0] = tokenSecond;
            path[1] = tokenFirst;

            uint256[] memory amountsOut = router.getAmountsOut(
                balanceSecond,
                path
            );
            return (balanceSecond, amountsOut[1], path);
        } else if (balanceFirst > 0) {
            path = new address[](2);
            path[0] = tokenFirst;
            path[1] = tokenSecond;

            uint256[] memory amountsOut = router.getAmountsOut(
                balanceFirst,
                path
            );
            return (balanceFirst, amountsOut[1], path);
        } else {
            path = new address[](2);
            path[0] = address(0);
            path[1] = address(0);
            return (0, 0, path);
        }
    }

    function _swapExactTokensForTokens(
        address tokenIn,
        address tokenOut
    ) internal {
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        require(amountIn > 0, "No input token balance");

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint256 amountOut = amountsOut[1];

        require(amountOut > amountIn, "No profit: output <= input");

        IERC20(tokenIn).approve(address(router), amountIn);

        router.swapExactTokensForTokens(
            amountIn,
            amountOut,
            path,
            address(this),
            block.timestamp + 300
        );
    }
}
