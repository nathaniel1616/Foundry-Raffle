// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DeployRaffleTest is Test {
    DeployRaffle deployRaffle;

    uint64 subId;

    function setUp() external {
        deployRaffle = new DeployRaffle();
        HelperConfig helperConfig = new HelperConfig();
        (, , , , subId, , , ) = helperConfig.s_activeNetworkConfig();
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function test_CreatesSubscriptionWhenSubIDIsZero() public view skipFork {
        assertEq(subId, 0);
    }
}
