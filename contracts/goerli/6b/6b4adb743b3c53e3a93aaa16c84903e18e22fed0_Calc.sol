/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Calc {
    int private result;
    
    /**
    function add(int a, int b) public returns (int c) {
        result = a + b;
        c = result;
    }
    */
    
    function add(int a, int b) public returns (int) {
        result = a + b;
        return result;
    }
    
    function min(int a, int b) public returns (int) {
        result = a - b;
        return result;
    }
    
    function mul(int a, int b) public returns (int) {
        result = a * b;
        return result;
    }
    
    function div(int a, int b) public returns (int) {
        result = a / b;
        return result;
    }
    
    function getResult() public view returns (int) {
        return result;
    }
}