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
}
