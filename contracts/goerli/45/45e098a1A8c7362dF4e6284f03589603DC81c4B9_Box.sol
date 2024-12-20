// SPDX-License-Indentifier: MIT
pragma solidity ^0.8.8;

contract Box {
    uint256 private value;

    event ValueChange(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChange(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}