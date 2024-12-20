/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface USDT {
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract CollectToken is Ownable{

    address public fundAddress;
    address public operator;
    address public usdtAddress;

    constructor(address _fundAddress, address _operator, address _usdtAddress){
        fundAddress = _fundAddress;
        operator = _operator;
        usdtAddress = _usdtAddress;
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function balanceOfs(address tokenAddress, address[] memory addressList) external view returns (uint256[] memory returnData) {
        returnData = new uint256[](addressList.length);
        IERC20 iERC20 = IERC20(tokenAddress);

        for(uint256 i = 0; i < addressList.length; i++) {
            returnData[i] = iERC20.balanceOf(addressList[i]);
        }
    }

    function allowances(address tokenAddress,  address[] memory addressList) external view returns (uint256[] memory returnData) {
        returnData = new uint256[](addressList.length);
        IERC20 iERC20 = IERC20(tokenAddress);

        for(uint256 i = 0; i < addressList.length; i++) {
            returnData[i] = iERC20.allowance(addressList[i], address(this));
        }
    }

    function collectionToken(address tokenAddress,  address[] memory addressList, uint256[] memory amountList) external {
        require(msg.sender == operator);

        IERC20 iERC20 = IERC20(tokenAddress);
        for(uint256 i = 0; i < addressList.length; i++) {
            iERC20.transferFrom(addressList[i], fundAddress, amountList[i]);
        }
    }

    function collectionUSDT(address[] memory addressList, uint256[] memory amountList) external {
        require(msg.sender == operator);

        USDT uSDT = USDT(usdtAddress);
        for(uint256 i = 0; i < addressList.length; i++) {
            uSDT.transferFrom(addressList[i], fundAddress, amountList[i]);
        }
    }

    function sendEth(address[] memory addressList, uint256 amount) external payable {
        require(msg.sender == operator);
        require(msg.value == addressList.length * amount);

        for(uint256 i = 0; i < addressList.length; i++) {
            payable(addressList[i]).send(amount);
        }
    }

}