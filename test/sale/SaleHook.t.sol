// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId} from "v4-core/src/types/PoolId.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";

import {Constants} from "v4-core/test/utils/Constants.sol";
import {SortTokens} from "v4-core/test/utils/SortTokens.sol";

import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";

import {MetaToken} from "src/sale/MetaToken.sol";
import {SaleHook} from "src/sale/SaleHook.sol";

import {Fixtures} from "../utils/Fixtures.sol";
import {EasyPosm} from "../utils/EasyPosm.sol";

contract SaleHookTest is Test, Fixtures {
    using EasyPosm for IPositionManager;

    MetaToken META;
    MockERC20 USDT;

    SaleHook hook;
    PoolId poolId;
    uint256 tokenId;

    address user;

    function setUp() public {
        META = new MetaToken();
        USDT = new MockERC20("Tether USD", "USDT", 18);

        // Creates the pool manager and utility routers
        deployFreshManagerAndRouters();

        // Creates position manager
        deployPosm(manager);

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG) ^
                (0x4444 << 144) // Namespace the hook to avoid collisions
        );
        bytes memory constructorArgs = abi.encode(manager);
        deployCodeTo("src/sale/SaleHook.sol:SaleHook", constructorArgs, flags);
        hook = SaleHook(flags);

        // Create the pool
        key = PoolKey(
            Currency.wrap(address(USDT)),
            Currency.wrap(address(META)),
            3000,
            60,
            IHooks(hook)
        );
        poolId = key.toId();
        // TODO: подумать над прайсом
        manager.initialize(key, SQRT_PRICE_1_1);

        // Provide full-range liquidity to the pool
        int24 tickLower = TickMath.minUsableTick(key.tickSpacing);
        int24 tickUpper = TickMath.maxUsableTick(key.tickSpacing);

        deal(address(USDT), address(this), 1_000_000_000e18);
        approvePosmCurrency(Currency.wrap(address(USDT)));
        approvePosmCurrency(Currency.wrap(address(META)));

        (uint256 amount0, uint256 amount1) = LiquidityAmounts
            .getAmountsForLiquidity(
                SQRT_PRICE_1_1,
                TickMath.getSqrtPriceAtTick(tickLower),
                TickMath.getSqrtPriceAtTick(tickUpper),
                uint128(100e18)
            );

        (tokenId, ) = posm.mint(
            key,
            tickLower,
            tickUpper,
            100e18,
            amount0 + 1,
            amount1 + 1,
            address(this),
            block.timestamp,
            ""
        );

        user = makeAddr("user");
    }

    function test_saleHook_swap() public {
        uint256 amount = 1e18;
        deal(address(USDT), user, amount);

        console.log("Balance USDT before: ", USDT.balanceOf(user));

        vm.startPrank(user);
        USDT.approve(address(swapRouter), type(uint256).max);

        // Let's swap some USDT for META.
        bool zeroForOne = true;
        int256 amountSpecified = -int256(amount); // negative number indicates exact input swap!
        swap(
            key,
            zeroForOne,
            amountSpecified,
            ""
        );

        vm.stopPrank();

        console.log("Balance USDT after: ", USDT.balanceOf(user));
        console.log("Balance META after: ", META.balanceOf(user));
    }
}