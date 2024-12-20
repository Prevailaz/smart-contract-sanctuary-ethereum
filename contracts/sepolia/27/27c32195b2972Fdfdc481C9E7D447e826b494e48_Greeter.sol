/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract Greeter {
    event GreeterChange( string indexed greeting);
    string private greeting;
    

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit GreeterChange(_greeting);
    }
}