// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "Ownable.sol";

import "IInstanceServiceFacade.sol";
import "MockRegistry.sol";

contract MockInstance is 
    Ownable,
    IInstanceServiceFacade
{

    struct ComponentInfo {
        uint256 id;
        ComponentType t;
        ComponentState state;
        address token;
    }

    mapping(uint256 componentId => ComponentInfo info) _component;
    mapping(uint256 bundleId => Bundle bundle) _bundle;
    MockRegistry private _registry;


    constructor() Ownable() { 
        _registry = new MockRegistry();
        _registry.setInstanceServiceAddress(address(this));
    }


    function setComponentInfo(
        uint256 componentId,
        ComponentType t,
        ComponentState state,
        address token
    )
        external
        onlyOwner
    {
        ComponentInfo storage info = _component[componentId];
        info.id = componentId;
        info.t = t;
        info.state = state;
        info.token = token;
    }


    function setBundleInfo(
        uint256 bundleId,
        uint256 riskpoolId,
        BundleState state,
        uint256 capital
    )
        external
        onlyOwner
    {
        Bundle storage bundle = _bundle[bundleId];
        bundle.id = bundleId;
        bundle.riskpoolId = riskpoolId;
        bundle.state = state;
        bundle.capital = capital;
        bundle.createdAt = block.timestamp;
    }


    function getRegistry()
        external
        view
        returns(MockRegistry registry)
    {
        return _registry;
    }


    function getChainId() external view returns(uint256 chainId) { 
        return block.chainid;
    }


    function getInstanceId() external view returns(bytes32 instanceId) {
        return keccak256(abi.encodePacked(block.chainid, _registry));
    }


    function getInstanceOperator() external view returns(address instanceOperator) {
        return owner();
    }

    function getComponentType(uint256 componentId) external view returns(ComponentType componentType) {
        require(_component[componentId].id > 0, "ERROR:DIS-010:COMPONENT_UNKNOWN");
        return _component[componentId].t;
    }

    function getComponentState(uint256 componentId) external view returns(ComponentState componentState) {
        return _component[componentId].state;
    }

    function getComponentToken(uint256 componentId) external view returns(IERC20Metadata token) {
        require(_component[componentId].token != address(0), "ERROR:DIS-020:COMPONENT_UNKNOWN");
        return IERC20Metadata(_component[componentId].token);
    }

    function getBundle(uint256 bundleId) external view returns(Bundle memory bundle) {
        require(_bundle[bundleId].createdAt > 0, "ERROR:DIS-030:BUNDLE_DOES_NOT_EXIST");
        return _bundle[bundleId];
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;


import "IERC20Metadata.sol";


// needs to be in sync with definition in IInstanceService
interface IInstanceServiceFacade {

    // needs to be in sync with definition in IComponent
    enum ComponentType {
        Oracle,
        Product,
        Riskpool
    }

    // needs to be in sync with definition in IComponent
    enum ComponentState {
        Created,
        Proposed,
        Declined,
        Active,
        Paused,
        Suspended,
        Archived
    }

    // needs to be in sync with definition in IBundle
    enum BundleState {
        Active,
        Locked,
        Closed,
        Burned
    }

    // needs to be in sync with definition in IBundle
    struct Bundle {
        uint256 id;
        uint256 riskpoolId;
        uint256 tokenId;
        BundleState state;
        bytes filter; // required conditions for applications to be considered for collateralization by this bundle
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function getChainId() external view returns(uint256 chainId);
    function getInstanceId() external view returns(bytes32 instanceId);
    function getInstanceOperator() external view returns(address instanceOperator);

    function getComponentType(uint256 componentId) external view returns(ComponentType componentType);
    function getComponentState(uint256 componentId) external view returns(ComponentState componentState);
    function getComponentToken(uint256 componentId) external view returns(IERC20Metadata token);

    function getBundle(uint256 bundleId) external view returns(Bundle memory bundle);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "IInstanceRegistryFacade.sol";

contract MockRegistry is IInstanceRegistryFacade {

    address private _instanceService;

    function setInstanceServiceAddress(address instanceService) external {
        _instanceService = instanceService;
    }

    function getContract(bytes32 contractName)
        external
        view
        returns (address contractAddress)
    {
        require(contractName == bytes32("InstanceService"), "ERROR:DRG-001:CONTRACT_NOT_REGISTERED");
        return _instanceService;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;


interface IInstanceRegistryFacade {

    function getContract(bytes32 contractName)
        external
        view
        returns (address contractAddress);
        
}