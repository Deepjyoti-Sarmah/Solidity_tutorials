// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubsription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint64 subscriptionId,
            bytes32 gasLane, // keyHash
            uint256 interval,
            uint256 entranceFee,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            address link
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            // we are gooing to need to create a subscription
            CreateSubsription createSubscription = new CreateSubsription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinatorV2
            );

            //Fund it!
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            subscriptionId,
            gasLane, // keyHash
            interval,
            entranceFee,
            callbackGasLimit,
            vrfCoordinatorV2
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
