// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    event EnterRaffle(address indexed player);
    event ReceivedRequestId(uint256 indexed requestId);

    Raffle raffle;
    HelperConfig helperConfig;
    // address private constant player1 = address(43523);
    // address private player = makeAddr("player");
    address public PLAYER = makeAddr("playera");
    address public PLAYER2 = makeAddr("player2");

    uint256 constant AMOUNT = 2e18;
    uint256 constant STARTING_BALANCE = 9e40;

    // helperConfig
    uint256 enteranceFee;
    uint256 interval;
    address vrfCordinator;
    bytes32 keyHash;
    uint64 subId;
    uint32 callbackGasLimit;
    address linkTokenAddress;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        vm.deal(PLAYER, STARTING_BALANCE);
        (raffle, helperConfig) = deployRaffle.run();
        (
            enteranceFee,
            interval,
            vrfCordinator,
            keyHash,
            subId,
            callbackGasLimit,
            linkTokenAddress,

        ) = helperConfig.s_activeNetworkConfig();
    }

    /**
     * @dev testing the enterRaffle Functions
     * @notice
     */
    function test_RaffleStateIsOpenWhenInitialized() public view {
        // arrange act assert

        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function test_GetEntranceFee() public view {
        assertEq(raffle.getEntranceFee(), 1e8);
    }

    function test_EnterRaffleRevertWhenNotFundedWithEnoughEth() public {
        // hoax(player1);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);

        raffle.enterRaffle{value: 0}();
    }

    function test_EnterRaffleAcceptsWhenFundedWithEnoughETH() public {
        console.log("starting raffle contract for test: ", address(raffle));
        console.log(
            "starting raffle balance for test: ",
            address(raffle).balance
        );
        vm.prank(PLAYER);

        raffle.enterRaffle{value: AMOUNT}();

        assertEq(PLAYER, raffle.getPlayer(0));
    }

    function test_RaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);

        raffle.enterRaffle{value: AMOUNT}();

        assertEq(PLAYER, raffle.getPlayer(0));
    }

    function test_RaffleEmitsPlayerWhenUserEnterRaffle() public {
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnterRaffle(PLAYER);
        raffle.enterRaffle{value: AMOUNT}();
    }

    modifier fundedRaffle() {
        hoax(PLAYER2);
        raffle.enterRaffle{value: AMOUNT}();
        console.log(unicode"Funding raffle contract with eth..🙌🙌");
        console.log("Raffle has been funded with player 2: ", PLAYER2);
        console.log("Eth Balance of Raffle", address(raffle).balance);
        _;
    }

    function test_CannotEnterRaffleWhenCalculating() public fundedRaffle {
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        raffle.enterRaffle{value: AMOUNT}();
    }

    //////////////////////////////////////
    //////     checkupkeep       ////////
    /////////////////////////////////////

    function test_CheckupKeepReturnFalseWhenThereIsNoBalance() public {
        // arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // assert

        // assert(!upkeepNeeded);  you can write it this way or
        assertEq(upkeepNeeded, false);
    }

    function test_CheckUpKeepReturnsFalseIfRaffleNotOpen() public {
        // arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: AMOUNT}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // assert
        assertEq(upkeepNeeded, false);
    }

    //** by nat */

    function testCheckUpkeepReturnFalseIfEnoughTimeHasntPassed() public {
        // arrange
        // funding the contract
        vm.prank(PLAYER);
        raffle.enterRaffle{value: AMOUNT}();
        vm.warp(block.timestamp);
        vm.roll(block.number);

        // act

        (bool upKeepNeed, ) = raffle.checkUpkeep("");

        // assert

        assertEq(upKeepNeed, false);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        //  arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: AMOUNT}(); //has been funded , has players, isOpen
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // act
        (bool upKeepNeed, ) = raffle.checkUpkeep("");

        // assert
        bool hasPassedTime = (block.timestamp - raffle.getLastTimestamp()) >
            raffle.getInterval();
        bool hasOpenRaffleState = raffle.getRaffleState() ==
            Raffle.RaffleState.OPEN;
        bool hasEthInRaffleContract = address(this).balance != 0;
        bool hasPlayers = raffle.getTotalPlayers() > 0;

        bool testTimepassed = hasPassedTime &&
            hasOpenRaffleState &&
            hasEthInRaffleContract &&
            hasPlayers;

        assertEq(upKeepNeed, testTimepassed);
    }

    ///////////////////////////////////////////////
    //////      performUpKeep             ////////
    /////////////////////////////////////////////
    modifier raffleEnteredandTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: AMOUNT}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function test_PerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: AMOUNT}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // act / assert

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpKeepIsFalse()
        public
        skipForkTest
    {
        // arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );

        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequest() public {
        // arrange, act ,assert
        vm.prank(PLAYER);
        raffle.enterRaffle{value: AMOUNT}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();

        // assertEq(entries.length, 2);
        console.log(uint256(entries[0].topics[1]));

        assert(entries[0].topics[1] > 0);
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 _requestId
    ) public skipForkTest {
        // arrange, act ,assert
        vm.prank(PLAYER);
        raffle.enterRaffle{value: AMOUNT}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.expectRevert("nonexistent request");

        VRFCoordinatorV2Mock(vrfCordinator).fulfillRandomWords(
            _requestId,
            address(raffle)
        );
    }

    function testFulfilledRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEnteredandTimePassed
        skipForkTest
    {
        // arrange

        uint160 ENDING_ADDRESS = 40;
        uint160 STARTING_ADDRESS = 2;
        vm.prank(PLAYER);
        raffle.enterRaffle{value: AMOUNT}();
        for (uint160 i = STARTING_ADDRESS; i < ENDING_ADDRESS; i++) {
            hoax(address(i), STARTING_BALANCE);
            raffle.enterRaffle{value: AMOUNT}();
        }

        console.log("number of players in raffle:  ", raffle.getTotalPlayers());
        console.log(
            "raffle balance before calculating winner ",
            address(raffle).balance
        );

        // act

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // getting emitted event ,, getting requestID from requestRandomness
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 requestId = uint256(entries[1].topics[1]);
        console.log("request id ....", requestId);
        VRFCoordinatorV2Mock(vrfCordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
        console.log("resseting after declaring winner");
        console.log("number of players in raffle:  ", raffle.getTotalPlayers());

        console.log("request id ....", requestId);
        console.log("winner of raffle", raffle.getRecentWinner());

        assert(raffle.getRecentWinner() != address(0));
        assertEq(address(raffle).balance, 0);
        assertEq(raffle.getTotalPlayers(), 0);
        assertEq(uint256(raffle.getRaffleState()), 0);
    }

    modifier skipForkTest() {
        if (block.chainid != 31337) {
            return;
        }

        _;
    }
}
