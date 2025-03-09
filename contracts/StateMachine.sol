// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract OrderStateMachine {
    // Define the possible states
    enum OrderState {
        Created,
        Shipped,
        Delivered,
        Cancelled
    }

    // State variable to track the current state of an order
    OrderState public currentState;

    // Events to log state transitions
    event OrderCreated();
    event OrderShipped();
    event OrderDelivered();
    event OrderCancelled();

    // Modifier to restrict functions to specific states
    modifier onlyInState(OrderState expectedState) {
        require(currentState == expectedState, "Current state does not match the provided state");
        _;
    }


    // Constructor to initialize the order in the "Created state"
    constructor() {
        // Set initial state to Created
        currentState = OrderState.Created;
        emit OrderCreated();
    }

    // Function to transition to the "Shipped" state
    function shipOrder() external onlyInState(OrderState.Created) {
        currentState = OrderState.Shipped;
        emit OrderShipped();
    }

    // Function to transition to the "Delivered" state
    function deliverOrder() external onlyInState(OrderState.Shipped) {
        currentState = OrderState.Delivered;
        emit OrderDelivered();
    }

    // Function to transition to the "Cancelled" state
    function cancelOrder() external onlyInState(OrderState.Created) {
        currentState = OrderState.Cancelled;
        emit OrderCancelled();
    }

    // Function to get the current state of the order 
    function getCurrentState() external view returns(OrderState) {
        return currentState;
    }
}