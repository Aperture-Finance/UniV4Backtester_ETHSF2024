// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct PoolEvent {
    int amount;
    int amount0; // Positive meaning swapping into pool, negative means swapping out of pool.
    int amount1;
    uint8 eventType; // 0: MintBurn, 1: Swap
    int tickLower;
    int tickUpper;
    uint128 unixTimestamp;
}

struct PoolEvents {
    PoolEvent[] events;
}
