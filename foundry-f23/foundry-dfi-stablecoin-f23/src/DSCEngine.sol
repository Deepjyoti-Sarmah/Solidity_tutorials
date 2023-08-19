// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title DSCEngine
 * @author Deepjyoti Sarmah
 * The system is designed to be as minimal as posible, and a have the token maintain a 1 token == $1 peg
 * This stablecoin has the properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algoritmically stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH anf WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of all collateral <= the $ backed value of the DSC
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and redeeming DSC, as well as deposting and withdrawing collateral
 * @notice This contract is very loosely based on the MakerDSS (DAI) system.
 */

contract DSCEngine is ReentrancyGuard {
    ///////////////
    // Errors   ///
    ///////////////
    error DSCEngine__NeedMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSame();
    error DSCEngine__NotAllowedToken();

    /////////////////////
    // State Variables //
    /////////////////////
    mapping(address token => address priceFeed) private s_priceFeeds;

    DecentralizedStableCoin private immutable i_dsc;

    ///////////////
    // Modifiers///
    ///////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    ///////////////
    // functions //
    ///////////////
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddress,
        address dscAddress
    ) {
        //USD Price Feeds
        if (tokenAddresses.length != priceFeedAddress.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSame();
        }
        // e.g., ETH/USD, BTC/USD etc
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddress[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    function depositeCollateralAndMintDsc() external {}

    /*
     *
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposite
     */

    function depositeCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {}

    function redemCollateralForDSC() external {}

    function redemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
