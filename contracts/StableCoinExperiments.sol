// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniswapV2Helper.sol";
import "./UniswapV3Helper.sol";

contract StableCoinExperiments is Ownable, UniswapV2Helper, UniswapV3Helper {
    address public TOKEN_FIRST;
    address public TOKEN_SECOND;
    address public _quoterRootV3;

    constructor(
        address _tokenFirst,
        address _tokenSecond,
        address _routerV2,
        address _routerV3,
        address _quoterV3
    )
        Ownable(msg.sender)
        UniswapV2Helper(_routerV2)
        UniswapV3Helper(_routerV3, _quoterV3)
    {
        TOKEN_FIRST = _tokenFirst;
        TOKEN_SECOND = _tokenSecond;
        _quoterRootV3 = _quoterV3;
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

    function swapTokenFirstToSecondV3(uint24 fee) external onlyOwner {
        _swapExactTokensForTokensV3(TOKEN_FIRST, TOKEN_SECOND, fee);
    }

    function swapTokenSecondToFirstV3(uint24 fee) external onlyOwner {
        _swapExactTokensForTokensV3(TOKEN_SECOND, TOKEN_FIRST, fee);
    }

    function getPotentialSwapInfoByAmountV3(
        uint256 amountIn,
        bool firstToSecond,
        uint24 fee
    ) external returns (uint256 amountOut) {
        if (firstToSecond) {
            return
                _getPotentialSwapInfoByAmountV3(
                    TOKEN_FIRST,
                    TOKEN_SECOND,
                    fee,
                    amountIn
                );
        } else {
            return
                _getPotentialSwapInfoByAmountV3(
                    TOKEN_SECOND,
                    TOKEN_FIRST,
                    fee,
                    amountIn
                );
        }
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
