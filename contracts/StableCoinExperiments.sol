// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
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

contract StableCoinExperiments is Ownable {
    address public TOKEN_FIRST;
    address public TOKEN_SECOND;
    IUniswapV2Router public router;

    constructor(
        address _tokenFirst,
        address _tokenSecond,
        address _router
    ) Ownable(msg.sender) {
        TOKEN_FIRST = _tokenFirst;
        TOKEN_SECOND = _tokenSecond;
        router = IUniswapV2Router(_router);
    }

    function swapTokenFirstToSecond() public onlyOwner {
        swapUniswapV2(TOKEN_FIRST, TOKEN_SECOND);
    }

    function swapTokenSecondToFirst() public onlyOwner {
        swapUniswapV2(TOKEN_SECOND, TOKEN_FIRST);
    }

    function doSwapV2() external onlyOwner {
        uint256 tokenFirstBalance = IERC20(TOKEN_FIRST).balanceOf(
            address(this)
        );
        uint256 tokenSecondBalance = IERC20(TOKEN_SECOND).balanceOf(
            address(this)
        );

        if (tokenSecondBalance > tokenFirstBalance) {
            swapTokenSecondToFirst();
        } else {
            swapTokenFirstToSecond();
        }
    }

    function getPotentialSwapInfoByAmountV2(
        uint256 amountIn,
        bool firstToSecond
    ) external view returns (uint256, uint256, address[] memory) {
        address[] memory path = new address[](2);

        if (firstToSecond) {
            path[0] = TOKEN_FIRST;
            path[1] = TOKEN_SECOND;
        } else {
            path[0] = TOKEN_SECOND;
            path[1] = TOKEN_FIRST;
        }

        if (amountIn == 0) {
            return (0, 0, path);
        }

        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint256 amountOut = amountsOut[1];

        return (amountIn, amountOut, path);
    }

    function getPotentialSwapInfoV2()
        external
        view
        returns (uint256 amountIn, uint256 amountOut, address[] memory path)
    {
        uint256 tokenFirstBalance = IERC20(TOKEN_FIRST).balanceOf(
            address(this)
        );
        uint256 tokenSecondBalance = IERC20(TOKEN_SECOND).balanceOf(
            address(this)
        );

        if (tokenSecondBalance > tokenFirstBalance && tokenSecondBalance > 0) {
            path = new address[](2);
            path[0] = TOKEN_SECOND;
            path[1] = TOKEN_FIRST;

            uint256[] memory amountsOut = router.getAmountsOut(
                tokenSecondBalance,
                path
            );
            amountIn = tokenSecondBalance;
            amountOut = amountsOut[1];
        } else if (tokenFirstBalance > 0) {
            path = new address[](2);
            path[0] = TOKEN_FIRST;
            path[1] = TOKEN_SECOND;

            uint256[] memory amountsOut = router.getAmountsOut(
                tokenFirstBalance,
                path
            );
            amountIn = tokenFirstBalance;
            amountOut = amountsOut[1];
        } else {
            path = new address[](2);
            path[0] = address(0);
            path[1] = address(0);
            amountIn = 0;
            amountOut = 0;
        }
    }

    function swapUniswapV2(address tokenIn, address tokenOut) internal {
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

    function getTokenBalances()
        external
        view
        returns (uint256 tokenFirstBalance, uint256 tokenSecondBalance)
    {
        tokenFirstBalance = IERC20(TOKEN_FIRST).balanceOf(address(this));
        tokenSecondBalance = IERC20(TOKEN_SECOND).balanceOf(address(this));
        return (tokenFirstBalance, tokenSecondBalance);
    }

    function testValue() external pure returns (uint256) {
        return 42;
    }

    function withdrawToken(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );

        bool success = IERC20(token).transfer(to, amount);
        require(success, "Token transfer failed");
    }
}
