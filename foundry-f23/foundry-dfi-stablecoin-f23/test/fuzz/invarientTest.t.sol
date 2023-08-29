// SPDX-License-Identifier: MIT

// Have our invarient aka properties

//What are our invariants?

// 1. The total supply of DSC should be less than total value of collateral
// 2. Getter view functions should never revert <- evergreen invarient

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract InvariantsTest is StdInvariant, Test {}
