// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 enteranceFee,
            uint256 interval,
            address vrfCordinator,
            bytes32 keyHash,
            uint64 subId,
            uint32 callbackGasLimit,
            address linkTokenAddress,
            uint256 deployerKey
        ) = helperConfig.s_activeNetworkConfig();

        if (subId == 0) {
            // creating subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subId = createSubscription.createSubscription(
                vrfCordinator,
                deployerKey
            );

            // funding subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCordinator,
                subId,
                linkTokenAddress,
                deployerKey
            );
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            enteranceFee,
            interval,
            vrfCordinator,
            keyHash,
            subId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            subId,
            address(raffle),
            vrfCordinator,
            deployerKey
        );
        return (raffle, helperConfig);
    }
}
