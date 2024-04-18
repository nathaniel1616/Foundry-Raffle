// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 *
 * @title  A sample raffle contract
 * @author Nathaniel
 * @notice This contract is for creating a sample raffle
 * @dev  Implements Chainlink VRFv2 and ChainLink automation
 */

// Layout of Contract:
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
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

//  bytes32 keyHash,
//     uint64 subId,
//     uint16 minimumRequestConfirmations,
//     uint32 callbackGasLimit,
//     uint32 numWords
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Raffle__NotEnoughEthSent();
    error Raffle__TransactionFail();
    error Raffle__NotOpen();
    error Raffle__UpKeepNotNeeded(
        uint256 balance,
        uint256 Numplayer,
        uint256 raffleState
    );

    enum RaffleState {
        OPEN,
        CLOSE,
        CALCULATING_WINNER
    }

    uint16 private constant minimumRequestConfirmations = 3;
    uint32 private constant numWords = 1;

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    VRFCoordinatorV2Interface private immutable i_vrfCordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subId;
    uint32 private immutable i_callbackGasLimit;
    address private s_recent_winner;
    RaffleState private s_raffleState;
    uint256 private s_requestId;

    event EnterRaffle(address indexed player);
    event PickedWinner(address winner);
    event ReceivedRequestId(uint256 indexed requestId);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCordinator,
        bytes32 keyHash,
        uint64 subId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCordinator) {
        i_entranceFee = enteranceFee;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
        i_vrfCordinator = VRFCoordinatorV2Interface(vrfCordinator);
        i_keyHash = keyHash;
        i_subId = subId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value <= i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnterRaffle(msg.sender);
    }

    //When is the winner supposed to be picked?

    /**
     * @dev This is the function that the chainlink automation nodes call
     * to see if it's time to perform an upkkep
     * The following should be true for thsi to return true:
     * 1. The time interval has passed between rafffle runs
     * 2. The lottery is in the Open state
     * 3. The contract has eth
     * 4. has players in the contract
     * 5. The subscription is funded with link (--implicit the checkUp Fund with run only in there is link token subscription)
     *
     * @return upkeepNeeded
     *
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /* performData*/) {
        bool hasPassedTime = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasOpenRaffleState = s_raffleState == RaffleState.OPEN;
        bool hasEthInRaffleContract = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = (hasPassedTime &&
            hasOpenRaffleState &&
            hasEthInRaffleContract &&
            hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING_WINNER;
        uint256 requestId = i_vrfCordinator.requestRandomWords(
            i_keyHash,
            i_subId,
            minimumRequestConfirmations,
            i_callbackGasLimit,
            numWords
        );
        s_requestId = requestId;

        //Requested Randomness already emits the requestID,
        emit ReceivedRequestId(s_requestId);
    }

    function fulfillRandomWords(
        uint256,
        /*_requestId */ uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recent_winner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransactionFail();
        }
    }

    // getter Functions

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 _index) public view returns (address) {
        return s_players[_index];
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    /// by nat
    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getTotalPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastTimestamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() public view returns (address) {
        return s_recent_winner;
    }
}
