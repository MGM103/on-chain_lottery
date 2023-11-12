//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Lottery
 * @author Marcus Marinelli
 * @notice This contract is a lottery contract
 * @dev This contract implements Chainlink VRF v2
 */
contract Lottery is VRFConsumerBaseV2 {
    /** Type Declarations */
    enum LotteryState {
        OPEN,
        IN_PROGRESS
    }

    /** State Variables */
    uint32 private constant NUMBER_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint256 private immutable i_interval; // Duration of lottery in seconds
    uint64 private immutable i_subscriptionID; // Chainlink subscription ID
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_gasLane;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // Chainlink VRF Coordinator

    uint256 private s_entryFee;
    uint256 private s_lastTimeStamp;
    address private s_owner;
    address payable[] private s_participants;
    address private s_lastWinner;
    LotteryState private s_lotteryState;

    /** Events */
    event LotteryEntered(address indexed participant);
    event LotteryWon(address indexed winner);

    /** Errors */
    error Lottery__NotOwner();
    error Lottery__InsufficientFunds();
    error Lottery__InsufficientTimePassed();
    error Lottery__PayoutFailed();
    error Lottery__NotOpen();

    constructor(
        uint256 entryFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionID,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionID = subscriptionID;

        s_entryFee = entryFee;
        s_lastTimeStamp = block.timestamp;
        s_owner = msg.sender;
        s_lotteryState = LotteryState.OPEN;
    }

    /** Modifiers */
    modifier onlyOwner() {
        if (msg.sender != s_owner) revert Lottery__NotOwner();
        _;
    }

    /** Lottery Functions */
    function enterLottery() external payable {
        if (msg.value < s_entryFee) revert Lottery__InsufficientFunds();
        if (s_lotteryState != LotteryState.OPEN) revert Lottery__NotOpen();

        s_participants.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    function selectWinner() external {
        if ((block.timestamp - s_lastTimeStamp) <= i_interval)
            revert Lottery__InsufficientTimePassed();
        s_lotteryState = LotteryState.IN_PROGRESS;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gaslane
            i_subscriptionID,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUMBER_WORDS
        );
    }

    /** Chainlink VRF Functions */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_participants.length;
        address payable winner = s_participants[winnerIndex];
        s_lastWinner = winner;

        s_lotteryState = LotteryState.OPEN;
        s_participants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit LotteryWon(winner);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) revert Lottery__PayoutFailed();
    }

    /** Setter functions */
    function setEntryFee(uint256 newEntryFee) external onlyOwner {
        s_entryFee = newEntryFee;
    }

    /** Getter functions */
    function getEntryFee() public view returns (uint256) {
        return s_entryFee;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }
}
