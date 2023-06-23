// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//Get funds from user
//withdraw a fund
//set a minimum funding value in usd

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    // uint256 public myValue = 1;
    uint256 public constant MINIMUM_USD = 5e18;
    address[] public funders;
    mapping (address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }
    
    function fund() public payable  {
        //Allow user to send $
        //Have a minimum $ sent $5
        //1. how do we send eth to this contract
        // myValue = myValue+2;
        // require(getConvertionRate(msg.value) >= minimumUSD, "didn't send enough eth"); // 1e18 = 1 ETH = 1 * 10 ** 18 = 1000000000000000000
        // what is a revert?
        //undo any actions that have been done, and send the remaining gas back

        require(msg.value.getConvertionRate() >= MINIMUM_USD, "didn't send enough eth"); // 1e18 = 1 ETH = 1 * 10 ** 18 = 1000000000000000000

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public  onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);
        // actually withdraw the funds

        //transfer
        // payable(msg.sender).transfer(address(this).balance);
        // //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "sender is not owner");
        if(msg.sender != i_owner) {
            revert NotOwner();
        } 
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

}
