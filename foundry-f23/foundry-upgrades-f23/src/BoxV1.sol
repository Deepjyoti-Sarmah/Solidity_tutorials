// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


// storage is stored in the proxy, NOT the implemetation 
// Proxy (number = 0) --> implementation (number = 1)
// proxy --> deploy implemetation --> call some "intializer" function

contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable{
  uint256 internal number;

  //@custom:oz-upgrades-unsafe-allow constructor
  constructor () {
    _disableInitializers();
  }

  function initialize() public initializer {
    __Ownable_init(); //sets owner to msg.sender
    __UUPSUpgradeable_init();
  }

  function getNumber() external view returns(uint256){
    return number;
  }

  function version() external pure returns(uint256) {
    return 1;
  }

  function _authorizeUpgrade(address newImplementation) internal override {}

}
