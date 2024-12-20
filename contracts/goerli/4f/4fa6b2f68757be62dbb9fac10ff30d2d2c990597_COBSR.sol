// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cigar Old Baby Club-SR
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    // File: @openzeppelin/contracts/utils/Context.sol                                                                          //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//    abstract contract Context {                                                                                                 //
//        function _msgSender() internal view virtual returns (address) {                                                         //
//            return msg.sender;                                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _msgData() internal view virtual returns (bytes calldata) {                                                    //
//            return msg.data;                                                                                                    //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: @openzeppelin/contracts/utils/Address.sol                                                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//    library Address {                                                                                                           //
//                                                                                                                                //
//        function isContract(address account) internal view returns (bool) {                                                     //
//            // This method relies on extcodesize, which returns 0 for contracts in                                              //
//            // construction, since the code is only stored at the end of the                                                    //
//            // constructor execution.                                                                                           //
//                                                                                                                                //
//            uint256 size;                                                                                                       //
//            assembly {                                                                                                          //
//                size := extcodesize(account)                                                                                    //
//            }                                                                                                                   //
//            return size > 0;                                                                                                    //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function sendValue(address payable recipient, uint256 amount) internal {                                                //
//            require(address(this).balance >= amount, "Address: insufficient balance");                                          //
//                                                                                                                                //
//            (bool success, ) = recipient.call{value: amount}("");                                                               //
//            require(success, "Address: unable to send value, recipient may have reverted");                                     //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function functionCall(address target, bytes memory data) internal returns (bytes memory) {                              //
//            return functionCall(target, data, "Address: low-level call failed");                                                //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function functionCall(                                                                                                  //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            string memory errorMessage                                                                                          //
//        ) internal returns (bytes memory) {                                                                                     //
//            return functionCallWithValue(target, data, 0, errorMessage);                                                        //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function functionCallWithValue(                                                                                         //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            uint256 value                                                                                                       //
//        ) internal returns (bytes memory) {                                                                                     //
//            return functionCallWithValue(target, data, value, "Address: low-level call with value failed");                     //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function functionCallWithValue(                                                                                         //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            uint256 value,                                                                                                      //
//            string memory errorMessage                                                                                          //
//        ) internal returns (bytes memory) {                                                                                     //
//            require(address(this).balance >= value, "Address: insufficient balance for call");                                  //
//            require(isContract(target), "Address: call to non-contract");                                                       //
//                                                                                                                                //
//            (bool success, bytes memory returndata) = target.call{value: value}(data);                                          //
//            return verifyCallResult(success, returndata, errorMessage);                                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {                   //
//            return functionStaticCall(target, data, "Address: low-level static call failed");                                   //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function functionStaticCall(                                                                                            //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            string memory errorMessage                                                                                          //
//        ) internal view returns (bytes memory) {                                                                                //
//            require(isContract(target), "Address: static call to non-contract");                                                //
//                                                                                                                                //
//            (bool success, bytes memory returndata) = target.staticcall(data);                                                  //
//            return verifyCallResult(success, returndata, errorMessage);                                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {                      //
//            return functionDelegateCall(target, data, "Address: low-level delegate call failed");                               //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function functionDelegateCall(                                                                                          //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            string memory errorMessage                                                                                          //
//        ) internal returns (bytes memory) {                                                                                     //
//            require(isContract(target), "Address: delegate call to non-contract");                                              //
//                                                                                                                                //
//            (bool success, bytes memory returndata) = target.delegatecall(data);                                                //
//            return verifyCallResult(success, returndata, errorMessage);                                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function verifyCallResult(                                                                                              //
//            bool success,                                                                                                       //
//            bytes memory returndata,                                                                                            //
//            string memory errorMessage                                                                                          //
//        ) internal pure returns (bytes memory) {                                                                                //
//            if (success) {                                                                                                      //
//                return returndata;                                                                                              //
//            } else {                                                                                                            //
//                // Look for revert reason and bubble it up if present                                                           //
//                if (returndata.length > 0) {                                                                                    //
//                    // The easiest way to bubble the revert reason is using memory via assembly                                 //
//                                                                                                                                //
//                    assembly {                                                                                                  //
//                        let returndata_size := mload(returndata)                                                                //
//                        revert(add(32, returndata), returndata_size)                                                            //
//                    }                                                                                                           //
//                } else {                                                                                                        //
//                    revert(errorMessage);                                                                                       //
//                }                                                                                                               //
//            }                                                                                                                   //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: @openzeppelin/contracts/token/ERC20/IERC20.sol                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//    interface IERC20 {                                                                                                          //
//                                                                                                                                //
//        function totalSupply() external view returns (uint256);                                                                 //
//                                                                                                                                //
//                                                                                                                                //
//        function balanceOf(address account) external view returns (uint256);                                                    //
//                                                                                                                                //
//                                                                                                                                //
//        function transfer(address recipient, uint256 amount) external returns (bool);                                           //
//                                                                                                                                //
//                                                                                                                                //
//        function allowance(address owner, address spender) external view returns (uint256);                                     //
//                                                                                                                                //
//                                                                                                                                //
//        function approve(address spender, uint256 amount) external returns (bool);                                              //
//                                                                                                                                //
//                                                                                                                                //
//        function transferFrom(                                                                                                  //
//            address sender,                                                                                                     //
//            address recipient,                                                                                                  //
//            uint256 amount                                                                                                      //
//        ) external returns (bool);                                                                                              //
//                                                                                                                                //
//                                                                                                                                //
//        event Transfer(address indexed from, address indexed to, uint256 value);                                                //
//                                                                                                                                //
//                                                                                                                                //
//        event Approval(address indexed owner, address indexed spender, uint256 value);                                          //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol                                                            //
//                                                                                                                                //
//                                                                                                                                //
//    // OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)                                                          //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    library SafeERC20 {                                                                                                         //
//        using Address for address;                                                                                              //
//                                                                                                                                //
//        function safeTransfer(                                                                                                  //
//            IERC20 token,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 value                                                                                                       //
//        ) internal {                                                                                                            //
//            _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));                             //
//        }                                                                                                                       //
//                                                                                                                                //
//        function safeTransferFrom(                                                                                              //
//            IERC20 token,                                                                                                       //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 value                                                                                                       //
//        ) internal {                                                                                                            //
//            _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));                   //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function safeApprove(                                                                                                   //
//            IERC20 token,                                                                                                       //
//            address spender,                                                                                                    //
//            uint256 value                                                                                                       //
//        ) internal {                                                                                                            //
//            // safeApprove should only be called when setting an initial allowance,                                             //
//            // or when resetting it to zero. To increase and decrease it, use                                                   //
//            // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'                                                              //
//            require(                                                                                                            //
//                (value == 0) || (token.allowance(address(this), spender) == 0),                                                 //
//                "SafeERC20: approve from non-zero to non-zero allowance"                                                        //
//            );                                                                                                                  //
//            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));                         //
//        }                                                                                                                       //
//                                                                                                                                //
//        function safeIncreaseAllowance(                                                                                         //
//            IERC20 token,                                                                                                       //
//            address spender,                                                                                                    //
//            uint256 value                                                                                                       //
//        ) internal {                                                                                                            //
//            uint256 newAllowance = token.allowance(address(this), spender) + value;                                             //
//            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        function safeDecreaseAllowance(                                                                                         //
//            IERC20 token,                                                                                                       //
//            address spender,                                                                                                    //
//            uint256 value                                                                                                       //
//        ) internal {                                                                                                            //
//            unchecked {                                                                                                         //
//                uint256 oldAllowance = token.allowance(address(this), spender);                                                 //
//                require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");                                    //
//                uint256 newAllowance = oldAllowance - value;                                                                    //
//                _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));              //
//            }                                                                                                                   //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function _callOptionalReturn(IERC20 token, bytes memory data) private {                                                 //
//            // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since        //
//            // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that         //
//            // the target address contains contract code and also asserts for success in the low-level call.                    //
//                                                                                                                                //
//            bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");                    //
//            if (returndata.length > 0) {                                                                                        //
//                // Return data is optional                                                                                      //
//                require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");                          //
//            }                                                                                                                   //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: @openzeppelin/contracts/finance/PaymentSplitter.sol                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    // OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)                                                              //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//    contract PaymentSplitter is Context {                                                                                       //
//        event PayeeAdded(address account, uint256 shares);                                                                      //
//        event PaymentReleased(address to, uint256 amount);                                                                      //
//        event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);                                           //
//        event PaymentReceived(address from, uint256 amount);                                                                    //
//                                                                                                                                //
//        uint256 private _totalShares;                                                                                           //
//        uint256 private _totalReleased;                                                                                         //
//                                                                                                                                //
//        mapping(address => uint256) private _shares;                                                                            //
//        mapping(address => uint256) private _released;                                                                          //
//        address[] private _payees;                                                                                              //
//                                                                                                                                //
//        mapping(IERC20 => uint256) private _erc20TotalReleased;                                                                 //
//        mapping(IERC20 => mapping(address => uint256)) private _erc20Released;                                                  //
//                                                                                                                                //
//                                                                                                                                //
//        constructor(address[] memory payees, uint256[] memory shares_) payable {                                                //
//            require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");                     //
//            require(payees.length > 0, "PaymentSplitter: no payees");                                                           //
//                                                                                                                                //
//            for (uint256 i = 0; i < payees.length; i++) {                                                                       //
//                _addPayee(payees[i], shares_[i]);                                                                               //
//            }                                                                                                                   //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        receive() external payable virtual {                                                                                    //
//            emit PaymentReceived(_msgSender(), msg.value);                                                                      //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function totalShares() public view returns (uint256) {                                                                  //
//            return _totalShares;                                                                                                //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function totalReleased() public view returns (uint256) {                                                                //
//            return _totalReleased;                                                                                              //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function totalReleased(IERC20 token) public view returns (uint256) {                                                    //
//            return _erc20TotalReleased[token];                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function shares(address account) public view returns (uint256) {                                                        //
//            return _shares[account];                                                                                            //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function released(address account) public view returns (uint256) {                                                      //
//            return _released[account];                                                                                          //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function released(IERC20 token, address account) public view returns (uint256) {                                        //
//            return _erc20Released[token][account];                                                                              //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function payee(uint256 index) public view returns (address) {                                                           //
//            return _payees[index];                                                                                              //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function release(address payable account) public virtual {                                                              //
//            require(_shares[account] > 0, "PaymentSplitter: account has no shares");                                            //
//                                                                                                                                //
//            uint256 totalReceived = address(this).balance + totalReleased();                                                    //
//            uint256 payment = _pendingPayment(account, totalReceived, released(account));                                       //
//                                                                                                                                //
//            require(payment != 0, "PaymentSplitter: account is not due payment");                                               //
//                                                                                                                                //
//            _released[account] += payment;                                                                                      //
//            _totalReleased += payment;                                                                                          //
//                                                                                                                                //
//            Address.sendValue(account, payment);                                                                                //
//            emit PaymentReleased(account, payment);                                                                             //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function release(IERC20 token, address account) public virtual {                                                        //
//            require(_shares[account] > 0, "PaymentSplitter: account has no shares");                                            //
//                                                                                                                                //
//            uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);                                      //
//            uint256 payment = _pendingPayment(account, totalReceived, released(token, account));                                //
//                                                                                                                                //
//            require(payment != 0, "PaymentSplitter: account is not due payment");                                               //
//                                                                                                                                //
//            _erc20Released[token][account] += payment;                                                                          //
//            _erc20TotalReleased[token] += payment;                                                                              //
//                                                                                                                                //
//            SafeERC20.safeTransfer(token, account, payment);                                                                    //
//            emit ERC20PaymentReleased(token, account, payment);                                                                 //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function _pendingPayment(                                                                                               //
//            address account,                                                                                                    //
//            uint256 totalReceived,                                                                                              //
//            uint256 alreadyReleased                                                                                             //
//        ) private view returns (uint256) {                                                                                      //
//            return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function _addPayee(address account, uint256 shares_) private {                                                          //
//            require(account != address(0), "PaymentSplitter: account is the zero address");                                     //
//            require(shares_ > 0, "PaymentSplitter: shares are 0");                                                              //
//            require(_shares[account] == 0, "PaymentSplitter: account already has shares");                                      //
//                                                                                                                                //
//            _payees.push(account);                                                                                              //
//            _shares[account] = shares_;                                                                                         //
//            _totalShares = _totalShares + shares_;                                                                              //
//            emit PayeeAdded(account, shares_);                                                                                  //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol                                                         //
//                                                                                                                                //
//                                                                                                                                //
//    // OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)                                                       //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//    library MerkleProof {                                                                                                       //
//                                                                                                                                //
//        function verify(                                                                                                        //
//            bytes32[] memory proof,                                                                                             //
//            bytes32 root,                                                                                                       //
//            bytes32 leaf                                                                                                        //
//        ) internal pure returns (bool) {                                                                                        //
//            return processProof(proof, leaf) == root;                                                                           //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {                           //
//            bytes32 computedHash = leaf;                                                                                        //
//            for (uint256 i = 0; i < proof.length; i++) {                                                                        //
//                bytes32 proofElement = proof[i];                                                                                //
//                if (computedHash <= proofElement) {                                                                             //
//                    // Hash(current computed hash + current element of the proof)                                               //
//                    computedHash = keccak256(abi.encodePacked(computedHash, proofElement));                                     //
//                } else {                                                                                                        //
//                    // Hash(current element of the proof + current computed hash)                                               //
//                    computedHash = keccak256(abi.encodePacked(proofElement, computedHash));                                     //
//                }                                                                                                               //
//            }                                                                                                                   //
//            return computedHash;                                                                                                //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: @openzeppelin/contracts/utils/Strings.sol                                                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//    library Strings {                                                                                                           //
//        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";                                                             //
//                                                                                                                                //
//                                                                                                                                //
//        function toString(uint256 value) internal pure returns (string memory) {                                                //
//            // Inspired by OraclizeAPI's implementation - MIT licence                                                           //
//            // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol    //
//                                                                                                                                //
//            if (value == 0) {                                                                                                   //
//                return "0";                                                                                                     //
//            }                                                                                                                   //
//            uint256 temp = value;                                                                                               //
//            uint256 digits;                                                                                                     //
//            while (temp != 0) {                                                                                                 //
//                digits++;                                                                                                       //
//                temp /= 10;                                                                                                     //
//            }                                                                                                                   //
//            bytes memory buffer = new bytes(digits);                                                                            //
//            while (value != 0) {                                                                                                //
//                digits -= 1;                                                                                                    //
//                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));                                                       //
//                value /= 10;                                                                                                    //
//            }                                                                                                                   //
//            return string(buffer);                                                                                              //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function toHexString(uint256 value) internal pure returns (string memory) {                                             //
//            if (value == 0) {                                                                                                   //
//                return "0x00";                                                                                                  //
//            }                                                                                                                   //
//            uint256 temp = value;                                                                                               //
//            uint256 length = 0;                                                                                                 //
//            while (temp != 0) {                                                                                                 //
//                length++;                                                                                                       //
//                temp >>= 8;                                                                                                     //
//            }                                                                                                                   //
//            return toHexString(value, length);                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//        function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {                             //
//            bytes memory buffer = new bytes(2 * length + 2);                                                                    //
//            buffer[0] = "0";                                                                                                    //
//            buffer[1] = "x";                                                                                                    //
//            for (uint256 i = 2 * length + 1; i > 1; --i) {                                                                      //
//                buffer[i] = _HEX_SYMBOLS[value & 0xf];                                                                          //
//                value >>= 4;                                                                                                    //
//            }                                                                                                                   //
//            require(value == 0, "Strings: hex length insufficient");                                                            //
//            return string(buffer);                                                                                              //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//    // File: contracts/ERC721.sol                                                                                               //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity >=0.8.0;                                                                                                    //
//                                                                                                                                //
//    abstract contract ERC721 {                                                                                                  //
//                                                                                                                                //
//                                                                                                                                //
//        event Transfer(address indexed from, address indexed to, uint256 indexed id);                                           //
//                                                                                                                                //
//        event Approval(address indexed owner, address indexed spender, uint256 indexed id);                                     //
//                                                                                                                                //
//        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);                                   //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract COBSR is ERC721Creator {
    constructor() ERC721Creator("Cigar Old Baby Club-SR", "COBSR") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}