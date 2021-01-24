pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./utils/IUniswapV2Router02.sol";

contract SwapModule {

    function swapStablecoin(address recipient, address[] memory path, uint amount) public {
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(routerAddress);
        uint _deadline = block.timestamp + 15;
        uint[] memory _expectedAmounts = uniswapRouter.getAmountsOut(amount, path);
        uint _expectedAmount = _expectedAmounts[1];
        uniswapRouter.swapExactTokensForTokens(
            amount,
            _expectedAmount,
            path,
            recipient,
            _deadline
        );
    }
}