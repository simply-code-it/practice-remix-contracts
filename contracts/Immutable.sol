// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Immutable {
    // Immutable variables are like constants. Values of immutable variables can be set inside the 
    // constructor but cannot be modified afterwards.

    address public immutable myAddr;
    uint256 public immutable myUint;

    constructor(uint256 _myUint) {
        myAddr = msg.sender;
        myUint = _myUint;
    }
}