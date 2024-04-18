// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    HelperConfig helperConfig;

    struct NetworkConfig {
        uint256 enteranceFee;
        uint256 interval;
        address vrfCordinator;
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        address linkTokenAddress;
        uint256 deployerKey;
    }

    function setUp() external {
        helperConfig = new HelperConfig();
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function test_HelperConfigGetSepoliaConfig() public view skipFork {
        address sepoliaVRFCoordinator = helperConfig
            .getSepoliaConfig()
            .vrfCordinator;
        assertEq(
            sepoliaVRFCoordinator,
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
    }

    function test_HelperConfigGetOrCreatesAnvilConfig() public skipFork {
        // test this by comparing default anvil key in the deployer

        uint256 anvil_key = helperConfig.getOrCreateAnvilConfig().deployerKey;

        assertEq(
            anvil_key,
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );
        assertEq(helperConfig.getOrCreateAnvilConfig().subId, 0);
        assert(
            helperConfig.getOrCreateAnvilConfig().linkTokenAddress != address(0)
        );
    }
}
