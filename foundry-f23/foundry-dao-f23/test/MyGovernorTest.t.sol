// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract MyGovernorTest is Test {
    MyGovernor governor;
    Box box;
    TimeLock timelock;
    GovToken govToken;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    address[] proposers;
    address[] executors;
    
    uint256[] values;
    bytes[] calldatas;
    address[] targets; 

    uint256 public constant MINT_DELAY = 3600; //1 hour - after a vote passes
    uint256 public constant VOTING_DELAY = 1; // how many blocks till a vote is active 
    uint256 public constant VOTING_PERIOD = 50400;

    function setup() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);
        
        vm.startPrank(USER);
        govToken.delegate(USER);
        timelock = new TimeLock(MINT_DELAY, proposers, executors);
        governor = new MyGovernor(govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timelock));

    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);

    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 888;
        string memory description = "store 1 in Box";
        bytes memory encodedFunctionCalls = abi.encodeWithSignature("store(uint256)", valueToStore);

        values.push(0);
        calldatas.push(encodedFunctionCalls);
        targets.push(address(box));

        //1. propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        //view the state
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY+ 1);     
        vm.roll(block.number + VOTING_DELAY + 1);
        
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        //2. Vote 
        string memory reason = "cuz blue frog is cool";

        uint8 voteWay = 1; //voting yes 
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);


        vm.warp(block.timestamp + VOTING_PERIOD + 1);     
        vm.roll(block.number + VOTING_PERIOD + 1);

        //3. Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MINT_DELAY + 1);     
        vm.roll(block.number + MINT_DELAY + 1);


        //4. Execuute 
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(box.getNumber() == valueToStore);
        console.log("Box Value:", box.getNumber());


    }
}