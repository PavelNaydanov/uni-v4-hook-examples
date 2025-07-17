// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol"; // TODO: удалить

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "v4-core/src/types/BeforeSwapDelta.sol";

contract SaleHook is BaseHook, Test {
    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false, // TODO: если кто-то задонатит в момент продаж, это не должно повлиять ни на что
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata swapParams, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        console.log("Before swap hook");
        return (BaseHook.beforeSwap.selector, toBeforeSwapDelta(0, 0), uint24(0));
    }

    function _beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        internal
        override
        returns (bytes4)
    {
        console.log("Before add liquidity hook");
        // TODO: научиться останавливать выполнение
        return BaseHook.beforeAddLiquidity.selector;
    }
}