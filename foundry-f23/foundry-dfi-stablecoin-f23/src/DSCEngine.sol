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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEnginr__HealthFactorOK();

    /////////////////////
    // State Variables //
    /////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    ///////////////
    // Events   ///
    ///////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralRedeemed(address indexed user, address indexed token, uint256 indexed amount);


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
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddress, address dscAddress) {
        //USD Price Feeds
        if (tokenAddresses.length != priceFeedAddress.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSame();
        }
        // e.g., ETH/USD, BTC/USD etc
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddress[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    /*
     * 
     * @param tokenCollateralAddress The address of the token to deposite as a collateral 
     * @param amountCollateral the amount of collateral to deposite
     * @param amountToMint the amount of decentralized stablecoin to mint
     * @notic this function will doposit your collateral and mint DSC in one transaction 
     */
    function depositeCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountToMint
    ) external {
        depositeCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountToMint);
    }

    /*
     * @notice Follows CEI
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposite
     */

    function depositeCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);

        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /*
     * @param tokenCollateralAddress The colllateral address to redeem 
     * @param amountCollateral The amount of collateral to redeem
     * @param amountDscToBurn The amount of DSC to burn
     * This function burns DSC and redeems the underlying collateral in one transaction 
     */

    function redemCollateralForDSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) external {
      burnDsc(amountDscToBurn);
      redemCollateral(tokenCollateralAddress, amountCollateral);
      //redemcollateral already checks healthfactor
    }

    // in order to redem collateral :
    // 1. health factor must be over 1 AFTER collateral pulled
    // CEI: Check Effects Ineractions
    function redemCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) nonReentrant {
      s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;
      emit CollateralRedeemed(msg.sender, tokenCollateralAddress, amountCollateral);
      // _calculateHealthFactorAfter()
      bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, amountCollateral);
      if (!success) {
        revert DSCEngine__TransferFailed();
      }
      _revertIfHealthFactorIsBroken(msg.sender);
      
    }

    /*
     * @notice follows CEI 
     * @param amountDscToMint The amount of decentralized stable coin to mint 
     * @notice must have more collatral value than minimum input
     *  
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }
    
    //Do we need to check if this breaks health factor ?
    function burnDsc(uint256 amount) public moreThanZero(amount){
      s_DSCMinted[msg.sender] -= amount;
      bool success = i_dsc.transferFrom(msg.sender, address(this), amount);
      //This condition is hypothitically unreachable
      if(!success) {
        revert DSCEngine__TransferFailed();
      }
      i_dsc.burn(amount);
      _revertIfHealthFactorIsBroken(msg.sender); //I  don't think this would ever hit... 
    }

    // If someone is almost undercollateralized, we will pay you to liquidate them!
    
    /*
     * @param collatral The erc20 collateral address to liqudate from the user
     * @param user The user who has broken the health factor. Their _healthFactor shoulf be below MIN_HEALTH_FACTOR 
     * @param debtToCover The amount to DSC you want to burn to improve the users health factor 
     * 
     * @notic You can partially liquidate a user
     * @notic you will get a liquidation bonus for taking the users funds 
     * @notice: This function working assumes that the protocol will be roughly 150% overcollateralized in order for this to work.
     * @notice: A known bug would be if the protocol was only 100% collateralized, we wouldn't be able to liquidate anyone.
     * For example, if the price of the collateral plummeted before anyone could be liquidated.
     */
    function liquidate(address collatral, address user, uint256 debtToCover) external moreThanZero nonReentrant {
      //Need to check health factor of the user
      uint256 startingUerHealthFactor = _healthFactor(user);
      if(startingUerHealthFactor >= MIN_HEALTH_FACTOR) {
        revert DSCEnginr__HealthFactorOK();
      }
      //we want to burn their DSC "dept"
      //and take their collateral
      uint256 tokenAmountFromDebtCover = getTokenAmountFromUsd(collateral, debtToCover);
      //And give them 10% bonus
    }

    function getHealthFactor() external view {}

    ////////////////////////////////////
    // Private and Internal Functions //
    ////////////////////////////////////
    /*
     * Returns how close to liquidation a user is 
     * if a user goes below 1, then they can get liquidated
     */

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValuedInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValuedInUsd = getAccountCollateralValue(user);
    }

    function _healthFactor(address user) private view returns (uint256) {
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / 100;

        // $1000 ETH / 100 DSC
        // 1000 * 50 = 50000 / 100 = (500 / 100) > 1
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    //1. Check health factor (do they have enough collaterals)
    //2. Revert if they don't
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    ////////////////////////////////////////
    // Public and External View Functions //
    ////////////////////////////////////////
    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
      //price of ETH )token
      AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
      (, int256 price,,,) = priceFeed.latestRoundData();
      return (usdAmountInWei & PRECISION)/ (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }


    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        //loop through each collateral token, get the amount they have deposited, and get it tp price, to get the USD Value
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        //1 ETH = $1000
        // The returned value value from CL will be 1000 * 1e8
        return (uint256(price) * ADDITIONAL_FEED_PRECISION * amount) / PRECISION;
    }
}
