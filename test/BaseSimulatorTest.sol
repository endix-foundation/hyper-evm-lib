// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {PrecompileLib} from "../src/PrecompileLib.sol";
import {CoreWriterLib} from "../src/CoreWriterLib.sol";
import {HLConversions} from "../src/common/HLConversions.sol";
import {HLConstants} from "../src/common/HLConstants.sol";
import {HyperCore} from "./simulation/HyperCore.sol";
import {CoreSimulatorLib} from "./simulation/CoreSimulatorLib.sol";

/**
 * @title BaseSimulatorTest
 * @notice Base test contract that sets up the HyperCore simulation.
 *
 * @dev Supports two modes controlled by environment variables:
 *
 *   OFFLINE MODE (default):
 *     - No fork, pure local simulation
 *     - Zero RPC calls, fast (~500ms for full suite)
 *     - All state is mocked - tests are deterministic and isolated
 *     - Run with: forge test
 *
 *   FORK MODE:
 *     - Forks real Hyperliquid chain state
 *     - Falls back to real chain data for unmocked state
 *     - Useful for integration testing with real token info, prices, etc.
 *     - Run with: FORK_MODE=true forge test
 *
 *   Environment variables:
 *     - FORK_MODE: Set to "true" to enable fork mode (default: offline)
 *     - HYPERLIQUID_RPC: RPC URL for fork mode (default: https://rpc.hyperliquid.xyz/evm)
 *
 *   Examples:
 *     forge test                                              # Offline mode (fast, no RPC)
 *     FORK_MODE=true forge test                               # Fork mode with public RPC
 *     FORK_MODE=true HYPERLIQUID_RPC=https://paid.rpc forge test  # Fork mode with paid RPC
 */
abstract contract BaseSimulatorTest is Test {
    using PrecompileLib for address;
    using HLConversions for *;

    string public constant DEFAULT_RPC = "https://rpc.hyperliquid.xyz/evm";

    HyperCore public hyperCore;

    // Common token addresses
    address public constant USDT0 = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
    address public constant uBTC = 0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463;
    address public constant uETH = 0xBe6727B535545C67d5cAa73dEa54865B92CF7907;
    address public constant uSOL = 0x068f321Fa8Fb9f0D135f290Ef6a3e2813e1c8A29;

    // Common token indices
    uint64 public constant USDC_TOKEN = 0;
    uint64 public constant HYPE_TOKEN = 150;

    address user = makeAddr("user");

    function setUp() public virtual {
        // Check if fork mode is enabled
        bool forkMode = vm.envOr("FORK_MODE", false);

        if (forkMode) {
            // Fork mode: use RPC (custom or default)
            string memory rpcUrl = vm.envOr("HYPERLIQUID_RPC", DEFAULT_RPC);
            vm.createSelectFork(rpcUrl);
            hyperCore = CoreSimulatorLib.init();
            // useRealL1Read stays true - fall back to real chain for unmocked data
        } else {
            // Offline mode: pure simulation, no RPC calls
            hyperCore = CoreSimulatorLib.init();
            hyperCore.setUseRealL1Read(false);
        }

        hyperCore.forceAccountActivation(user);
        hyperCore.forceSpotBalance(user, USDC_TOKEN, 1000e8);
        hyperCore.forcePerpBalance(user, 1000e6);
    }
}
