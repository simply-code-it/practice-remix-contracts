// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Variables {
    // State variables are stored on the blockchain
    string public text = "hello";
    uint256 public num = 123;

    function doSomething() public view {
        // Local variables are not saved to the blockchain
        uint256 i = 456;

        // Here are some global variables
        uint256 timestamp = block.timestamp;
        address sender = msg.sender;
    }
}