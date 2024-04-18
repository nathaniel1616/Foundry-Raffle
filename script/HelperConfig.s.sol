// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mock/LinkToken.sol";

contract HelperConfig is Script {
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

    NetworkConfig public s_activeNetworkConfig;
    uint256 public constant DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            s_activeNetworkConfig = getSepoliaConfig();
        }
        if (block.chainid == 43113) {
            s_activeNetworkConfig = getFugiConfig();
        } else {
            s_activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                enteranceFee: 1e8,
                interval: 200,
                vrfCordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subId: 10882,
                callbackGasLimit: 500000,
                linkTokenAddress: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getFugiConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                enteranceFee: 1e8,
                interval: 500,
                vrfCordinator: 0x2eD832Ba664535e5886b75D64C46EB9a228C2610,
                keyHash: 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61,
                subId: 0,
                callbackGasLimit: 500000,
                linkTokenAddress: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (s_activeNetworkConfig.vrfCordinator != address(0)) {
            return s_activeNetworkConfig;
        }
        // deploying mocks
        else {
            uint96 BASE_FEE = 1e17;
            uint96 GAS_PRICE_LINK = 1e8;

            vm.startBroadcast();
            VRFCoordinatorV2Mock vrfCordinator = new VRFCoordinatorV2Mock(
                BASE_FEE,
                GAS_PRICE_LINK
            );
            LinkToken linkToken = new LinkToken();

            vm.stopBroadcast();

            return
                NetworkConfig({
                    enteranceFee: 1e8,
                    interval: 200,
                    vrfCordinator: address(vrfCordinator),
                    keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                    subId: 0,
                    callbackGasLimit: 500000,
                    linkTokenAddress: address(linkToken),
                    deployerKey: DEFAULT_ANVIL_KEY
                });
        }
    }
}
