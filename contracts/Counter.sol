// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Counter{
    int256 private _number;

    event Incremented(int256);
    event Decremented(int256);

    function inc() external  {
        ++_number;
        
        emit Incremented(_number);
    }

    function getNumber() external view returns(int256) {
        return _number;
    }

    function dec() external {
        --_number;

        emit Decremented(_number);
    }
}