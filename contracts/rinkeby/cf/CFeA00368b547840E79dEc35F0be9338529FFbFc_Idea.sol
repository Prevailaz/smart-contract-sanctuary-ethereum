/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract IdeaFactory {
        address[] deployedIdeas;

        function createIdea (uint minimum) public {
           address newIdea = address(new Idea(minimum, msg.sender));

           deployedIdeas.push(newIdea);
        }

        function getDeployedIdeas() public view returns(address[] memory ) {
            return deployedIdeas;
        }
}


contract Idea {
    struct Request {
        string  description;
        uint    value;
        address payable recipient;
        bool    complete;
        uint    approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address   public manager;
    uint      public minimumContribution;
    uint      public contributersCount;
    mapping(address => bool) public contributers;

    modifier restricted() {
        require(msg.sender == manager);
        _;
            }

    constructor (uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value >= minimumContribution);
        contributers[msg.sender] = true;
        contributersCount++;
    }

    function createRequest (string calldata description, uint value, address recipient)  public restricted {
        Request storage request = requests.push();

            request.description = description;
            request.value = value;
            request.recipient = payable(recipient);
            request.complete = false;
            request.approvalCount = 0;
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(contributers[msg.sender]);        // check if the person has already contributed in the contract
        require(!request.approvals[msg.sender]);  // check if person has NOT approved this request already (shud not be true)

        request.approvals[msg.sender] = true;     //  once the person approves the request, set it to true
        request.approvalCount++;                  //  increment the approval count by 1
    }


    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (contributersCount / 2));
        require(!request.complete);

        request.recipient.transfer(request.value);
        //request.recipient.call{value:request.value}; // to send the funds we can also write this statement instead of
                                                       //transfer, if the recipient address is not marked as 'payable'
        request.complete = true;
    }

    function getSummary() public view returns (
        uint, uint, uint, uint, address
    ) {
        return (
            minimumContribution,
            address(this).balance,
            requests.length,
            contributersCount,
            manager
        );
    }

    function getRequestcount() public view returns (uint) {
        return requests.length;
    }


}