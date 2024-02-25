// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployLottery is Script {
    function run() external returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entryFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionID,
            uint32 callbackGasLimit,
            address link
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionID == 0) {
            console.log("Creating subscription programtically...");
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionID = createSubscription.createSubscription(
                vrfCoordinator
            );
        }

        vm.startBroadcast();
        Lottery lottery = new Lottery(
            entryFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionID,
            callbackGasLimit
        );
        vm.stopBroadcast();

        return (lottery, helperConfig);
    }
}
