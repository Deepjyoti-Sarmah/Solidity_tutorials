// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {SolveChallenge} from "../src/SolveChallenge.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() external returns (SolveChallenge) {
        vm.startBroadcast();
        SolveChallenge solveChallenge = new SolveChallenge();
        vm.stopBroadcast();

        return solveChallenge;
    }
}
