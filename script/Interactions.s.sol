// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mock/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCordinator, , , , , uint256 deployerKey) = helperConfig
            .s_activeNetworkConfig();
        uint64 subId = createSubscription(vrfCordinator, deployerKey);
        return subId;
    }

    function createSubscription(
        address _vrfCoordinator,
        uint256 deployerKey
    ) public returns (uint64) {
        console.log("Creating subscription on ChainId: ", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your sub Id is: ", subId);
        console.log("Please update subscriptionId in helperconfig.s.sol");
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 constant FUND_AMOUNT = 3e18;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCordinator,
            ,
            uint64 subId,
            ,
            address linkTokenAddress,
            uint256 deployerKey
        ) = helperConfig.s_activeNetworkConfig();
        fundSubscription(vrfCordinator, subId, linkTokenAddress, deployerKey);
    }

    function fundSubscription(
        address _vrfCoordinator,
        uint64 _subId,
        address _linkTokenAddress,
        uint256 deployerKey
    ) public {
        console.log("Funding subscription on subId: ", _subId);
        console.log("The chainId is :  ", block.chainid);
        console.log("VrfCoordinator adddess : ", _vrfCoordinator);
        console.log("The link token address: : ", _linkTokenAddress);
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(
                _subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(_linkTokenAddress).transferAndCall(
                _vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(_subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address _raffle_address) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCordinator,
            ,
            uint64 subId,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.s_activeNetworkConfig();
        addConsumer(subId, _raffle_address, vrfCordinator, deployerKey);
    }

    /**
     * 
     @dev the consumer here is the address of the latest raffle contract deployed 
     */

    function addConsumer(
        uint64 _subId,
        address _consumer,
        address _vrfCoordinator,
        uint256 deployerKey
    ) public {
        console.log("adding consumer contract: ", _consumer);
        console.log("Using VRF coordinator : ", _vrfCoordinator);
        console.log("on subscription id: ", _subId);
        console.log("on chainid : ", block.chainid);

        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(_subId, _consumer);
        vm.stopBroadcast();
    }

    function run() external {
        address raffle_address = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle_address);
    }
}
