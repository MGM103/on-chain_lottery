// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Link} from "../test/mocks/Link.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64) {
        console.log("Creating Chainlink VRF Subscription");

        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log(
            "Created Chainlink VRF Subscription. Your subID is:",
            subId
        );
        return subId;
    }

    function run() external returns (uint64) {
        console.log("CreateSubscription");
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMT = 2 ether;

    function fundAccountUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            address link
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, link);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subscriptionId,
        address link
    ) public {
        console.log("Funding Chainlink VRF Subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On chain id: ", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            Link(link).transferAndCall(
                vrfCoordinator,
                FUND_AMT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundAccountUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address lottery) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
        ) = helperConfig.activeNetworkConfig();
    }

    function addConsumer(address lottery, address vrfCoordinator, uint64 subscriptionId) public {
        console.log("Adding consumer coordinator contract: ", lottery);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("Adding to subscription: ", subscriptionId);

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionId, lottery);
        vm.stopBroadcast();
    }

    function run() external {
        address lottery = DevOpsTools.get_most_recent_deployment("Lottery", block.chainid);
        addConsumerUsingConfig(lottery);
    }

}
