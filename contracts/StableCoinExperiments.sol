// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniswapV2Helper.sol";

contract StableCoinExperiments is Ownable, UniswapV2Helper {
    address public TOKEN_FIRST;
    address public TOKEN_SECOND;

    constructor(
        address _tokenFirst,
        address _tokenSecond,
        address _router
    ) Ownable(msg.sender) UniswapV2Helper(_router) {
        TOKEN_FIRST = _tokenFirst;
        TOKEN_SECOND = _tokenSecond;
    }

    function doSwapV2() external onlyOwner {
        _doSwapV2(TOKEN_FIRST, TOKEN_SECOND);
    }

    function getPotentialSwapInfoByAmountV2(
        uint256 amountIn,
        bool firstToSecond
    ) external view returns (uint256, uint256, address[] memory) {
        return
            _getPotentialSwapInfoByAmountV2(
                TOKEN_FIRST,
                TOKEN_SECOND,
                amountIn,
                firstToSecond
            );
    }

    function getPotentialSwapInfoV2()
        external
        view
        returns (uint256 amountIn, uint256 amountOut, address[] memory path)
    {
        return _getPotentialSwapInfoV2(TOKEN_FIRST, TOKEN_SECOND);
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
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20(token).transfer.selector, to, amount)
        );
        require(success, "Token transfer failed");
    }

    function testValue() external pure returns (uint256) {
        return 42;
    }
}
