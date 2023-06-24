// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {AFoundryCourseChallenge} from "Solidity_Tutorials/lesson-4/AFoundryCourseChallenge.sol";
import {AggregatorV3Interface} from "Solidity_Tutorials/lesson-4/AggregatorV3Interface.sol";

contract LessonFour {
    error LessonFour__WrongPrice();

    string private constant LESSON_IMAGE = "ipfs://QmSCoS3N8qFy2D3Tn4vTPKTFAC1TAqSZgg9R4uCb7fZL7Q";
    address private immutable i_priceFeed;

    constructor(address priceFeed) {
        i_priceFeed = priceFeed;
    }

    function getPrice() public  view returns (uint256) {
        (, int256 price,,,) = AggregatorV3Interface(i_priceFeed).latestRoundData();
        return uint256(price);
    }

    function getDecimals() public view returns (uint8) {
        return AggregatorV3Interface(i_priceFeed).decimals();
    }

    function getPriceFeed() external view returns (address) {
        return i_priceFeed;
    }

    // function ans(uint256 ans) public view returns(uint256) {
    //     return ans;
    // }

    /*
     * CALL THIS FUNCTION!
     * 
     * @param priceGuess - Your guess for the price based on the feed. It can be withing a few tokens.
     * @param yourTwitterHandle - Your twitter handle. Can be a blank string.
     */

    uint256 public actualPrice;

    function solveChallenge(uint256 priceGuess) external  returns(uint256){
        actualPrice = getPrice();
        if (getDecimals() == 8) {
            actualPrice = actualPrice * 10e10;
        }
        if (actualPrice + 3e18 > priceGuess && actualPrice - 3e18 < priceGuess) {
            // _updateAndRewardSolver(yourTwitterHandle);
        } else {
            // revert LessonFour__WrongPrice();
            return actualPrice;
        }

        return actualPrice;
    }

    // 188703000000000000000000000000,

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////// The following are functions needed for the NFT, feel free to ignore. ///////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // function description() external pure override returns (string memory) {
    //     return
    //     "Cyfrin Foundry Full Course: Oracles, payments, and some best practices? You've completed the Remix portion of the course!";
    // }

    // function attribute() external pure override returns (string memory) {
    //     return "Remix Pro";
    // }

    // function specialImage() external pure override returns (string memory) {
    //     return LESSON_IMAGE;
    // }
}