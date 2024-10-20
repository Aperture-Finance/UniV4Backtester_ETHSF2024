// SPDX-License-Identifier: MIT
// $ forge script UniV4Backtester --fork-url https://unichain-sepolia.g.alchemy.com/v2/0123456789ABCDEFGHIJKLMNOPQRSTUV --fork-block-number 2523275
pragma solidity >=0.8.0;

import "./ICreate2Deployer.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

// import {AutoCompound} from "./hooks/AutoCompound.sol";
import {deployCodeTo} from "forge-std/src/StdCheats.sol";
import {Script, console} from "forge-std/Script.sol";
import {NoopHook} from "./hooks/NoopHook.sol";
import {PoolEvent, PoolEventType} from "./SUniV4Backtester.sol";
import {Token1} from "./Token1.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IHooks} from "lib/v4-periphery/lib/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "lib/v4-periphery/lib/v4-core/src/libraries/Hooks.sol";
import {Currency} from "lib/v4-periphery/lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "lib/v4-periphery/lib/v4-core/src/types/PoolKey.sol";
import {IPositionManager} from "lib/v4-periphery/src/interfaces/IPositionManager.sol";
import {PoolManager} from "lib/v4-periphery/lib/v4-core/src/PoolManager.sol";
import {HookMiner} from "lib/v4-template/test/utils/HookMiner.sol";

contract UniV4Backtester is Script {
    // Returns mint/swap/burn events from UniV3 pool since pool creation until endDate.
    function getPoolEvents(
        PoolKey memory poolKey,
        uint128 endDate
    ) internal view returns (PoolEvent[] memory) {
        // TODO @gnarlycow
        // This is a placeholder implementation. Replace it with the actual implementation.
        PoolEvent[] memory poolEvents = new PoolEvent[](5);
        poolEvents[0] = PoolEvent(PoolEventType.MintBurn, 1620000000, 1000000000000000000, -198480, -193500, 0, 0);
        poolEvents[1] = PoolEvent(PoolEventType.MintBurn, 1620000123, 1000000000000000000, -198180, -193200, 0, 0);
        poolEvents[2] = PoolEvent(PoolEventType.Swap, 1620000456, 0, 0, 0, 7890123, -1234567);
        poolEvents[3] = PoolEvent(PoolEventType.Swap, 1620000789, 0, 0, 0, -123456, 987654);
        poolEvents[4] = PoolEvent(PoolEventType.MintBurn, 1620009876, -1000000000000000000, -198480, -193500, 0, 0);
        return poolEvents;
    }

    function run() public {
        address unichainPoolManagerAddress = 0xC81462Fec8B23319F288047f8A03A57682a35C1A; // https://docs.uniswap.org/contracts/v4/deployments
        address unichainCreate2Deployer = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2; // https://github.com/pcaversaccio/create2deployer
        address hookAddress = 0x0000000000000000000000000000000000000000; // Set as 0 to mine a new one

        // Deploy token1
        console.log("Before deploying Token1");
        Token1 token1 = new Token1();
        console.log("After deploying Token1@", address(token1), ", token1.balanceOf(address(this))=", token1.balanceOf(address(this)));

        // Pool Manager
        PoolManager poolManager = PoolManager(0xC81462Fec8B23319F288047f8A03A57682a35C1A);

        // Hook info
        if (hookAddress == address(0)) {
            uint160 flags = 0;
            bytes memory constructorArgs = abi.encode(unichainPoolManagerAddress);
            (address minedHookAddress, bytes32 salt) = HookMiner.find(unichainCreate2Deployer, flags, type(NoopHook).creationCode, constructorArgs);
            hookAddress = minedHookAddress;
            console.log("Finished Mining Hook Address, hookAddress=", hookAddress);
        }
        Create2Deployer create2deployer = Create2Deployer(unichainCreate2Deployer);
        create2deployer.deploy(0, automanSalt, initCode);
        deployCodeTo("NoopHook.sol", abi.encode(unichainPoolManagerAddress), hookAddress);
        console.log("After deploying Hook@", address(hookAddress));
        NoopHook noopHook = NoopHook(hookAddress);

        // console.log("Deployed noopHook@", address(noopHook));

        // Pool info
        // https://sepolia.uniscan.xyz/address/0xC81462Fec8B23319F288047f8A03A57682a35C1A
        Currency currency0 = Currency.wrap(0x0000000000000000000000000000000000000000); // native eth on sepolia.unichain
        Currency currency1 = Currency.wrap(address(token1)); // deployed usdc on sepolia.unichain
        uint24 fee = 3000;
        int24 tickSpacing = 60;
        // PoolKey memory poolKey = PoolKey(currency0, currency1, fee, tickSpacing, IHooks(address(noopHook)));
        // poolManager.initialize(poolKey, 79228162514264337593543950336);

        // // Position info
        // // https://sepolia.uniscan.xyz/address/0xB433cB9BcDF4CfCC5cAB7D34f90d1a7deEfD27b9
        // IPositionManager positionManager = IPositionManager(0xB433cB9BcDF4CfCC5cAB7D34f90d1a7deEfD27b9);
        // uint128 positionStartDate = 1620000001;
        // uint128 positionInitialLiquidity = 123456789;
        // int positionInitialTickLower = -198480;
        // int positionInitialTickUpper = -198480;

        // // Get and loop through pool events
        // PoolEvent[] memory poolEvents = getPoolEvents(poolKey, 1800000000);
        // bool isPositionInitialized = false;
        // for (uint i = 0; i < poolEvents.length; i++) {
        //     PoolEvent memory poolEvent = poolEvents[i];
        //     if (!isPositionInitialized && positionStartDate <= poolEvent.unixTimestamp) {
        //         console.log(string.concat(string.concat(string.concat(string.concat(string.concat(string.concat(string.concat("Initializing position at unixTimestamp=", Strings.toString(poolEvents[i].unixTimestamp), ", positionInitialLiquidity=", Strings.toString(positionInitialLiquidity), ", positionInitialTickLower=", Strings.toStringSigned(positionInitialTickLower), ", positionInitialTickUpper=", Strings.toStringSigned(positionInitialTickUpper)))))))));
        //         isPositionInitialized = true;
        //     }
        //     if (poolEvent.poolEventType == PoolEventType.MintBurn) {
        //         console.log(string.concat(string.concat(string.concat(string.concat(string.concat(string.concat(string.concat((poolEvent.amount >= 0 ? "Mint" : "Burn"), " at unixTimestamp=", Strings.toString(poolEvents[i].unixTimestamp), ", amount=", Strings.toStringSigned(poolEvent.amount), ", positionInitialTickLower=", Strings.toStringSigned(positionInitialTickLower), ", positionInitialTickUpper=", Strings.toStringSigned(positionInitialTickUpper)))))))));
        //     } else if (poolEvent.poolEventType == PoolEventType.Swap) {
        //         console.log(string.concat(string.concat(string.concat(string.concat(string.concat("Swap at unixTimestamp=", Strings.toString(poolEvents[i].unixTimestamp), ", amount0=", Strings.toStringSigned(poolEvent.amount0), ", amount1=", Strings.toStringSigned(poolEvent.amount1)))))));
        //     }
        // }
    }
}
