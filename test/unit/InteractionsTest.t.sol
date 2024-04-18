// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {FundSubscription, CreateSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LinkToken} from "../mock/LinkToken.sol";

contract InteractionTest is Test {
    event ConsumerAdded(uint64 indexed subId, address consumer);
    event SubscriptionFunded(
        uint64 indexed subId,
        uint256 oldBalance,
        uint256 newBalance
    );

    uint96 constant FUND_AMOUNT = 3e18;

    CreateSubscription createSubscription;
    FundSubscription fundSubscription;
    HelperConfig helperConfig;
    AddConsumer addConsumer;

    uint64 subid;
    address vrfCordinator;
    uint256 deployerKey;
    LinkToken linkToken;
    address link = address(link);

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() external {
        helperConfig = new HelperConfig();
        linkToken = new LinkToken();
        (, , vrfCordinator, , subid, , , deployerKey) = helperConfig
            .s_activeNetworkConfig();

        createSubscription = new CreateSubscription();
        subid = createSubscription.createSubscription(
            vrfCordinator,
            deployerKey
        );
        fundSubscription = new FundSubscription();
    }

    function test_CreatingSubscriptionUsingConfigFunction() public view {
        assert(subid != 0);
    }

    function test_FundingSubscription() public skipFork {
        vm.expectEmit(true, false, false, true);
        emit SubscriptionFunded(subid, 0, FUND_AMOUNT);
        fundSubscription.fundSubscription(
            vrfCordinator,
            subid,
            link,
            deployerKey
        );
    }

    function test_addingConsumers() public skipFork {
        addConsumer = new AddConsumer();
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );

        // we expected a consumeradded event
        vm.expectEmit(true, false, false, true);
        emit ConsumerAdded(subid, raffle);
        addConsumer.addConsumer(subid, raffle, vrfCordinator, deployerKey);
    }
}
