// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * Ticketrust Middleware contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

import "../utils/Array.sol";

contract TicketrustMiddleware {
    using Array for address[];

    // IOperatorRegistry public operatorsRegistry;
    address public committee;

    // Is operator mapping checker
    mapping(address => bool) public _isOperator;

    address [] public allOperators;

    event OperatorStatusChanged(address operator, bool isMember);

    // Only operator modifier
    modifier onlyOperator {
        require(_isOperator[msg.sender], "Restricted only to operator");
        _;
    }

    // Only committee modifier
    modifier onlyCommittee {
        require(msg.sender == committee, "Restricted only to committee");
        _;
    }

    function initialize(address [] memory _operators, address _committee) public {
        // Register committee
        committee = _committee;

        // Operators initialization
        for(uint i = 0; i < _operators.length; i++) {
            _addOperatorInternal(_operators[i]);
        }
    }

    function isOperator(address _address) external view returns (bool) {
        return _isOperator[_address];
    }

    function isCommittee(address _address) external view returns (bool) {
        return _address == committee;
    }

    function addOperator(address _address) public onlyCommittee {
        _addOperatorInternal(_address);
    }

    function _addOperatorInternal(address _address) internal {
        require(_isOperator[_address] == false, "OperatorsRegistry :: Address is already a operator");

        allOperators.push(_address);
        _isOperator[_address] = true;

        emit OperatorStatusChanged(_address, true);
    }

    function removeOperator(address _operator) external onlyCommittee {
        require(_isOperator[_operator] == true, "OperatorsRegistry :: Address is not a operator");

        uint length = allOperators.length;
        require(length > 1, "Cannot remove last operator.");

        // Use custom array library for removing from array
        allOperators.removeElement(_operator);
        _isOperator[_operator] = false;

        emit OperatorStatusChanged(_operator, false);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0;

/**
 * Array library.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

library Array {
    function removeElement(address[] storage _array, address _element) internal {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}