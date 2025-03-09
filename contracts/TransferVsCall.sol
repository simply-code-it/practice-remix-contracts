// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
In Solidity, both transfer and call are used to send Ether to an address.
but they have significant differences in terms of gas limits, error handling,
and flexibility.
*/

contract TransferVsCall {
    // Event to log Ether transfers
    event EtherSent(address indexed recipient, uint256 amount, string method);

    // Function to send Ether using transfer
    function sendViaTransfer(address payable recipient) external payable {
        require(msg.value > 0, "No Ether sent");
        require(recipient != address(0), "Recipient cannot be the zero address");
    
        // Send Ether using transfer
        recipient.transfer(msg.value);
        emit EtherSent(recipient, msg.value, "transfer");
    }

    // Function to send Ether using call
    function sendViaCall(address payable recipient) external payable {
        require(msg.value > 0, "No Ether sent");
        require(recipient != address(0), "Recipient cannot be the zero address");

        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "Call failed");

        emit EtherSent(recipient, msg.value, "call");
    }

    receive() external payable {}
}