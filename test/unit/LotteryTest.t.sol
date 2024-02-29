// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Lottery} from "../../src/Lottery.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract LotteryTest is Test {
    Lottery lottery;
    HelperConfig helperConfig;

    uint256 entryFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionID;
    uint32 callbackGasLimit;
    address link;

    address public PARTICIPANT = makeAddr("participant");
    uint256 public constant START_PARTICIPANT_BALANCE = 10 ether;

    event LotteryEntered(address indexed participant);

    function setUp() external {
        DeployLottery deployLottery = new DeployLottery();
        (lottery, helperConfig) = deployLottery.run();

        (
            entryFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionID,
            callbackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();

        vm.deal(PARTICIPANT, START_PARTICIPANT_BALANCE);
    }

    function testLotteryStartingState() public view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    function testLotteryEntryFee() public view {
        assert(lottery.getEntryFee() == entryFee);
    }

    function testLotteryInterval() public view {
        assert(lottery.getInterval() == interval);
    }

    /** Enter Lottery */
    function testLotterRevertsWithInsufficientEntryFee() public {
        vm.prank(PARTICIPANT);

        vm.expectRevert(Lottery.Lottery__InsufficientFunds.selector);
        lottery.enterLottery();
    }

    function testParticipantRegisteredUponEntry() public {
        vm.prank(PARTICIPANT);

        lottery.enterLottery{value: entryFee}();
        address payable[] memory participantArr = lottery.getParticipants();
        address participant = lottery.getParticipant(0);

        assert(participantArr.length == 1);
        assert(participant == PARTICIPANT);
    }

    function testEmitsEventUponEntry() public {
        vm.prank(PARTICIPANT);
        vm.expectEmit(true, false, false, false, address(lottery));
        emit LotteryEntered(PARTICIPANT);
        lottery.enterLottery{value: entryFee}();
    }

    function testCantEnterLotteryWhenNotOpen() public {
        vm.prank(PARTICIPANT);
        lottery.enterLottery{value: entryFee}();

        /** Trigger checkUpkeep */
        vm.warp(block.timestamp + interval + 1); // Fast forward time the required amount + 1 second
        vm.roll(block.number + 1); // Go to next block
        lottery.performUpkeep("");

        vm.expectRevert(Lottery.Lottery__NotOpen.selector);
        vm.prank(PARTICIPANT);
        lottery.enterLottery{value: entryFee}();
    }

    function testCheckUpkeepMustHaveFunds() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepRequired, ) = lottery.checkUpkeep("");

        assert(!upkeepRequired);
    }

    modifier lotteryEnteredAndTimePassed() {
        vm.prank(PARTICIPANT);
        lottery.enterLottery{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testCheckUpkeepRaffleMustBeOpen()
        public
        lotteryEnteredAndTimePassed
    {
        lottery.performUpkeep("");

        (bool upkeepRequired, ) = lottery.checkUpkeep("");

        assert(!upkeepRequired);
    }

    function testCheckUpkeepMustAllowEnoughTimeToPass() public {
        vm.prank(PARTICIPANT);
        lottery.enterLottery{value: entryFee}();

        (bool upkeepRequired, ) = lottery.checkUpkeep("");

        assert(!upkeepRequired);
    }

    function testCheckUpkeepSucceeds() public lotteryEnteredAndTimePassed {
        (bool upkeepRequired, ) = lottery.checkUpkeep("");

        assert(upkeepRequired);
    }

    function testPerformUpkeepContingentOnCheckUpkeepTrue()
        public
        lotteryEnteredAndTimePassed
    {
        lottery.performUpkeep("");
    }

    function testPerformUpkeepFailsWhenCheckUpkeepIsFalse() public {
        vm.prank(PARTICIPANT);
        lottery.enterLottery{value: entryFee}();

        uint256 currentBalance = address(lottery).balance;
        uint256 numPlayers = 1;
        Lottery.LotteryState lotteryState = lottery.getLotteryState();

        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.Lottery__UpkeepNotRequired.selector,
                currentBalance,
                numPlayers,
                block.timestamp,
                lotteryState
            )
        );
        lottery.performUpkeep("");
    }

    function testEventDataEmittedAndStatePostPerformUpkeep()
        public
        lotteryEnteredAndTimePassed
    {
        vm.recordLogs();
        lottery.performUpkeep("");

        Vm.Log[] memory eventEntries = vm.getRecordedLogs();
        bytes32 requestId = eventEntries[0].topics[2];

        Lottery.LotteryState lotteryState = lottery.getLotteryState();

        assert(uint256(requestId) > 0);
        assert(uint256(lotteryState) == 1);
    }

    /** Chainlink VRF Random Words Test */

    function testFulfillRandomWordsTriggeredOnlyAfterPerformUpkeep(
        uint256 randomRequestId
    ) public lotteryEnteredAndTimePassed {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(lottery)
        );
    }

    function testFulfillRandomWordsDistributesLotteryAndResetsState()
        public
        lotteryEnteredAndTimePassed
    {
        uint256 additionalParticipants = 4;

        for (uint256 i = 0; i <= additionalParticipants; i++) {
            address participant = address(uint160(i));
            hoax(participant, START_PARTICIPANT_BALANCE);
            lottery.enterLottery{value: entryFee}();
        }

        uint256 prize = address(lottery).balance;

        vm.recordLogs();
        lottery.performUpkeep("");

        Vm.Log[] memory eventEntries = vm.getRecordedLogs();
        bytes32 requestId = eventEntries[0].topics[2];

        uint256 previousTimeStamp = lottery.getLastTimeStamp();

        // Mimic co-ordinator
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(lottery)
        );

        assert(uint256(lottery.getLotteryState()) == 0);
        assert(lottery.getLastWinner() != address(0));
        assert(lottery.getNumberOfParticipants() == 0);
        assert(lottery.getLastTimeStamp() > previousTimeStamp);
        assert(
            lottery.getLastWinner().balance ==
                (prize + START_PARTICIPANT_BALANCE - entryFee)
        );
    }
}
