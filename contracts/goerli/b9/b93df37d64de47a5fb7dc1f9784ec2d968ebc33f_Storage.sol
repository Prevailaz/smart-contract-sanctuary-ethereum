/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Storage {

    uint256 public number;

    function store(uint256 value) public {
        number = value;
    }

}