// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRouter {
    struct route {
        address from;
        address to;
        bool stable;
    }
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,route[] calldata routes,address to,uint deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA,address tokenB,bool stable,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function isPair(address pair) external view returns (bool);
    function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB);
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);
    function getPoolAmountOut(uint amountIn, address tokenIn, address pair) external view returns (uint amount);
}
