// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../src/UniswapV3TestManager.sol";
import "forge-std/console.sol";

contract UniswapV3PositionManagerTest is Test {
    using SafeERC20 for IERC20;

    UniswapV3PositionManager positionManagerTest;

    address constant POSITION_MANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address constant POOL_WETH_USDC =
        0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address public USER = makeAddr("user");
    IERC20 public weth;
    IERC20 public usdt;

    function setUp() public {
        weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        positionManagerTest = new UniswapV3PositionManager(POSITION_MANAGER);

        vm.label(POSITION_MANAGER, "PositionManager");
        vm.label(address(weth), "WETH");
        vm.label(address(usdt), "USDT");
        vm.label(POOL_WETH_USDC, "PoolWETH/USDC");

        // Fund the user with WETH and USDC
        deal(address(weth), USER, 20 ether);
        deal(address(usdt), USER, 20_000 * 1e6);
    }

    // function testRevertsInvalidPool() public {
    //     vm.startPrank(USER);

    //     uint256 amount0Desired = 1 ether;

    //     uint256 amount1Desired = 2_000 * 1e6;
    //     uint256 width = 1000;

    //     IERC20(address(weth)).forceApprove(address(positionManagerTest), amount0Desired);
    //     IERC20(address(usdt)).forceApprove(address(positionManagerTest), amount1Desired);

    //     vm.expectRevert("Invalid pool address");
    //     positionManagerTest.provideLiquidity(
    //         address(0),
    //         amount0Desired,
    //         amount1Desired,
    //         width
    //     );

    //     vm.stopPrank();
    // }

    function testProvideLiquidity() public {
        vm.startPrank(USER);

        uint256 amount0Desired = 1 ether;
        uint256 amount1Desired = 2_000 * 1e6;
        uint256 width = 1000;

        IERC20(address(weth)).forceApprove(POSITION_MANAGER, amount0Desired);
        IERC20(address(usdt)).forceApprove(POSITION_MANAGER, amount1Desired);

        console.log("Position Manager address:", address(positionManagerTest));
        console.log(
            "balanceOf positionManagerTest:",
            IERC20(address(weth)).balanceOf(address(this))
        );

        // uint256 wethAllowance = IERC20(address(weth)).allowance(
        //     address(this),
        //     POSITION_MANAGER
        // );
        // uint256 usdtAllowance = IERC20(address(usdt)).allowance(
        //     address(this),
        //     POSITION_MANAGER
        // );

        positionManagerTest.provideLiquidity(
            POOL_WETH_USDC,
            amount0Desired,
            amount1Desired,
            width
        );

        uint256 wethBalance = IERC20(address(weth)).balanceOf(USER);
        uint256 usdtBalance = IERC20(address(usdt)).balanceOf(USER);

        assertEq(
            wethBalance,
            19 ether,
            "Incorrect WETH balance after liquidity"
        );
        assertEq(
            usdtBalance,
            18_000 * 1e6,
            "Incorrect USDT balance after liquidity"
        );

        vm.stopPrank();
    }

    // function testRevertsInvalidWidth() public {
    //     vm.startPrank(USER);

    //     uint256 amount0Desired = 1 ether;
    //     uint256 amount1Desired = 2_000 * 1e6;

    //     // Approve tokens
    //     IERC20(address(weth)).forceApprove(address(positionManager), amount0Desired);
    //     IERC20(address(usdt)).forceApprove(address(positionManager), amount1Desired);

    //     // Expect revert for invalid width
    //     vm.expectRevert("Invalid width");
    //     positionManager.provideLiquidity(
    //         POOL_WETH_USDC,
    //         amount0Desired,
    //         amount1Desired,
    //         0
    //     );

    //     vm.stopPrank();
    // }

    // function testRevertsInsufficientLiquidity() public {
    //     vm.startPrank(USER);

    //     uint256 amount0Desired = 1 ether;
    //     uint256 amount1Desired = 20_000 * 1e6; // Exceeds balance
    //     uint256 width = 1000;

    //     // Approve tokens
    //     IERC20(address(weth)).forceApprove(address(positionManager), amount0Desired);
    //     IERC20(address(usdt)).forceApprove(address(positionManager), amount1Desired);

    //     // Expect revert due to insufficient balance
    //     vm.expectRevert();
    //     positionManager.provideLiquidity(
    //         POOL_WETH_USDC,
    //         amount0Desired,
    //         amount1Desired,
    //         width
    //     );

    //     vm.stopPrank();
    // }
}
