// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../../src/Lottery.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryTest is Test {
    Lottery lottery;
    HelperConfig helperConfig;

    uint256 entryFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionID;
    uint32 callbackGasLimit;

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
            callbackGasLimit
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
}
