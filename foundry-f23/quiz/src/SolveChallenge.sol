// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SolveChallenge {
    error LessonSeven__WrongValue();

    string private constant LESSON_IMAGE =
        "ipfs://QmUCK8YsB7Ln5u4Sn6WdsgtD87eEv5fCy1VaG8waMxXq6Q";
    uint256 private constant STARTING_NUMBER = 123;
    uint256 private constant STORAGE_LOCATION = 777;

    constructor() {
        assembly {
            sstore(STORAGE_LOCATION, STARTING_NUMBER)
        }
    }

    /*
     * CALL THIS FUNCTION!
     *
     * @param valueAtStorageLocationSevenSevenSeven - The value at storage location 777.
     * @param yourTwitterHandle - Your twitter handle. Can be a blank string.
     */
    function solveChallenge(
        uint256 valueAtStorageLocationSevenSevenSeven // string memory yourTwitterHandle
    ) external returns (uint256) {
        uint256 value;
        assembly {
            value := sload(STORAGE_LOCATION)
        }
        if (value != valueAtStorageLocationSevenSevenSeven) {
            revert LessonSeven__WrongValue();
        }
        uint256 newValue = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.prevrandao, block.timestamp)
            )
        ) % 1000000;
        assembly {
            sstore(STORAGE_LOCATION, newValue)
        }

        return newValue;
        // _updateAndRewardSolver(yourTwitterHandle);
    }
}
