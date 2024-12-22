// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV3PositionManager {
    using SafeERC20 for IERC20;

    address public positionManager;

    constructor(address _positionManager) {
        require(
            _positionManager != address(0),
            "Invalid position manager address"
        );
        positionManager = _positionManager;
    }

    function provideLiquidity(
        address pool,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 width
    ) external {
        require(pool != address(0), "Invalid pool address");
        require(width > 0, "Invalid width");

        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);

        address token0 = uniswapPool.token0();
        address token1 = uniswapPool.token1();

        IERC20(token0).safeTransferFrom(
            msg.sender,
            address(this),
            amount0Desired
        );
        IERC20(token1).safeTransferFrom(
            msg.sender,
            address(this),
            amount1Desired
        );

        IERC20(token0).forceApprove(positionManager, amount0Desired);
        IERC20(token1).forceApprove(positionManager, amount1Desired);

        (uint160 sqrtPriceX96, , , , , , ) = uniswapPool.slot0();
        uint256 currentPrice = (uint256(sqrtPriceX96) *
            uint256(sqrtPriceX96)) >> (96 * 2);

        uint256 lowerPrice = currentPrice - ((currentPrice * width) / 20000);
        uint256 upperPrice = currentPrice + ((currentPrice * width) / 20000);

        int24 lowerTick = calculateTickFromPrice(lowerPrice);
        int24 upperTick = calculateTickFromPrice(upperPrice);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: uniswapPool.fee(),
                tickLower: lowerTick,
                tickUpper: upperTick,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp + 300
            });

        INonfungiblePositionManager(positionManager).mint(params);
    }

    function calculateTickFromPrice(
        uint256 price
    ) internal pure returns (int24 tick) {
        require(price > 0, "Invalid price");
        uint256 scaledPrice = price / 1000;
        require(
            scaledPrice <= uint256(uint24(type(int24).max)),
            "Tick overflow"
        );
        tick = int24(int256(scaledPrice)); 
    }
}
