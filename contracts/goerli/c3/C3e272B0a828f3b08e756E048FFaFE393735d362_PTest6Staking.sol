/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// Sources flattened with hardhat v2.10.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/PochiInuNFT6.sol

// SPDX-License-Identifier: MIT

/// @author zscarabsz
/// @title Pochi Inu Staking

pragma solidity >=0.8.11;
contract PTest6Staking is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    
    IERC20 public token = IERC20 (0x324c0C29E116DC06B31010Da6857425BC8700B13);
    address public nftContract = address (0x11A6E6DfB475b3ad952fd98ffB38Ce840d71D01F);

    /* @dev team wallet should be a multi-sig wallet, used to transfer 
    ETH out of the contract for a migration, or EOL of the contract */
    address public teamWallet = (0x6c1C870bEea8c23607Ce340662F86C01cf42fF12);
	address public deadWallet = address (0xdead);

    // global flag to set staking and depositing active
    bool public isActive;

    // flag to turn off only deposits
    bool public depositsActive;
	
	struct Feed{
		uint256 nftId;
        uint256 timeIn;
        uint256 amt;
		address ownerAddress;
		uint256 timeOut;
    }

    struct UserLock {
        uint256 tokenAmount; 				// total amount they currently have locked
        uint256 claimedAmount; 				// total amount they have withdrawn
		uint256 burnAmount; 				// total amount they have burned
        uint256 startTime; 					// start of the lock
		uint	nftCount;					// count of NFTs under stake
		mapping(uint => Feed) _feeds;		// users NFT feeds
    }
    mapping(address => UserLock) public userLocks;

    event Locked(address indexed account, uint256 tokenAmount, uint256[] nftIds);
    event WithdrawTokens(address indexed account, uint256 amount);
	event TokensBurned(uint256 burnAmount, address deadWallet);  

    constructor (
        IERC20 _token,
        address _nftContract,
        address  _teamWallet ) 
	{     
        token = _token;
        nftContract = _nftContract;
        teamWallet = _teamWallet;
    }

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function setDepositsActive(bool _depositsActive) public onlyOwner {
        depositsActive = _depositsActive;
    }

    function setNftContract( address _nftContract ) public onlyOwner {
        nftContract = _nftContract;      
    }

	// Stake Tokens, to age your Pochi NFT
	// 	_amount = amount of Pochi Tokens
	// 	_nftIds = nft ids to stake against eg.  (comma delimted id numbers:  5,49,271)
	//
	//  case 1:  pass tokens, one nft - tokens staked against the single nft 
	//  case 2:  pass tokens, multiple nfts - tokens are split evenly between the nfts
	//  case 3:  pass tokens, zero nfts - staked tokens go into holding
	//  case 4:  zero tokens, one or multiple nfts - tokens in holding are split between passed nfts, or all to one
	//
    function lock(uint256 _amount, uint256[] memory _nftIds) public nonReentrant {
        require(isActive && depositsActive, 'Not active');
		require(_amount > 0 || (_amount == 0 && _nftIds.length > 0 && userLocks[msg.sender].tokenAmount > 0), 'Amount must be greater than Zero');
        require(token.balanceOf(msg.sender) >= _amount, 'Not enough tokens in Wallet');
		require(token.allowance(address(msg.sender), address(this)) >= _amount, 'Not enough tokens Approved');
		
		iPNFTNft pochiContract = iPNFTNft(nftContract);
		for (uint i = 0; i < _nftIds.length; i++) {
			require(pochiContract.ownerOf(_nftIds[i]) == msg.sender, 'Not owner of NFT');
        }
		
		userLocks[msg.sender].tokenAmount = userLocks[msg.sender].tokenAmount + _amount;
        userLocks[msg.sender].startTime = (userLocks[msg.sender].startTime > 0)? userLocks[msg.sender].startTime : block.timestamp;
		
		if (_amount > 0) {
			// move the tokens
			token.safeTransferFrom(address(msg.sender), address(this), _amount);
		}
		else if (_nftIds.length > 0)
		{
			uint256 usedTokens = 0;
			for (uint i = 0; i < userLocks[msg.sender].nftCount; i++) {
				usedTokens += userLocks[msg.sender]._feeds[i].amt;
			}
			_amount = userLocks[msg.sender].tokenAmount - usedTokens;
		}
		
		if (_nftIds.length == 0) {
			if (userLocks[msg.sender].nftCount > 0) {
				for (uint i = 0; i < userLocks[msg.sender].nftCount; i++) {
					_nftIds[i] = userLocks[msg.sender]._feeds[i].nftId;
				}
			}
		}
		
		if (_amount > 0 && _nftIds.length > 0) {
			uint256 tokensPerNFT = _amount / _nftIds.length;
			uint256 tokensLeft = _amount;
			
			for (uint i = 0; i < _nftIds.length; i++) {
				uint256 nftId = _nftIds[i];
				Feed memory updateFeed;
				uint indexFeed = 0;
				bool foundFeed = false;
				
				for (indexFeed = 0; indexFeed < userLocks[msg.sender].nftCount; indexFeed++) {
					if (nftId == userLocks[msg.sender]._feeds[indexFeed].nftId) {
						updateFeed = userLocks[msg.sender]._feeds[indexFeed];
						foundFeed = true;
						break;
					}
				}
				
				uint256 timeIn = (updateFeed.timeIn > 0)? updateFeed.timeIn : block.timestamp;
				uint256 amt = updateFeed.amt + ((tokensPerNFT <= tokensLeft)? tokensPerNFT : tokensLeft);
				address ownerAddress = address(msg.sender);
				uint256 timeOut = updateFeed.timeOut;
				
				if (foundFeed == true) {
					userLocks[msg.sender]._feeds[indexFeed] = Feed(nftId, timeIn, amt, ownerAddress, timeOut);
					updateFeed = userLocks[msg.sender]._feeds[indexFeed];
				}
				else {
					userLocks[msg.sender]._feeds[userLocks[msg.sender].nftCount] = Feed(nftId, timeIn, amt, ownerAddress, timeOut);
					updateFeed = userLocks[msg.sender]._feeds[userLocks[msg.sender].nftCount];
					userLocks[msg.sender].nftCount++;
				}
				
				pochiContract.giveFeed(nftId, updateFeed.amt, address(msg.sender));
				tokensLeft -= tokensPerNFT;
			}
		}
		
        emit Locked(msg.sender, _amount, _nftIds);
    }

    function claimLock(uint256 _amount, uint256[] memory _nftIds) public nonReentrant {
        require(isActive, 'Not active');
		require(_amount > 0, 'Token amount is zero');
        require(userLocks[msg.sender].tokenAmount > 0 && userLocks[msg.sender].tokenAmount >= _amount, 'Not enough tokens Locked');
		
		if (_nftIds.length > 0) {
			uint256 tokensLocks = 0;
			for (uint i = 0; i < _nftIds.length; i++) {
				bool foundNft = false;
				for (uint j = 0; j < userLocks[msg.sender].nftCount; j++) {
					if (_nftIds[i] == userLocks[msg.sender]._feeds[j].nftId) {
						foundNft = true;
						tokensLocks += userLocks[msg.sender]._feeds[j].amt;
						break;
					}
				}
				require(foundNft == true, 'Nft Id passed not being staked by you');
			}
			require(tokensLocks >= _amount, 'Nft Id(s) combined do not contain enough staked to withdraw');
		}
		else {
			for (uint i = 0; i < userLocks[msg.sender].nftCount; i++) {
				_nftIds[i] = userLocks[msg.sender]._feeds[i].nftId;
			}
		}

        userLocks[msg.sender].tokenAmount -= _amount;
		userLocks[msg.sender].claimedAmount += _amount;

        // move the tokens
        token.safeTransfer(address(msg.sender), _amount);
		
		if (_nftIds.length > 0) {
			iPNFTNft pochiContract = iPNFTNft(nftContract);
			
			if (userLocks[msg.sender].tokenAmount == 0) {
				for (uint i = 0; i < userLocks[msg.sender].nftCount; i++) {
					userLocks[msg.sender]._feeds[i].amt = 0;
					userLocks[msg.sender]._feeds[i].timeOut = block.timestamp;
					pochiContract.takeFeedAll(userLocks[msg.sender]._feeds[i].nftId);
				}
			}
			else {
				uint256 tokensPerNFT = _amount / _nftIds.length;
				uint256 tokensLeft = _amount;
				
				for (uint i = 0; i < _nftIds.length; i++) {
					for (uint j = 0; j < userLocks[msg.sender].nftCount; j++) {
						if (_nftIds[i] == userLocks[msg.sender]._feeds[j].nftId) {
							uint256 removeTokens = (tokensPerNFT < tokensLeft)? tokensPerNFT : tokensLeft;
							userLocks[msg.sender]._feeds[i].amt -= removeTokens;
							userLocks[msg.sender]._feeds[i].timeOut = block.timestamp;
							pochiContract.takeFeed(userLocks[msg.sender]._feeds[i].nftId, removeTokens);
							tokensLeft -= removeTokens;
							break;
						}
					}
				}	
			}
		}
		
        emit WithdrawTokens(msg.sender, _amount);  
    }
	
	function burnTokensForNft(uint256 _nftId) public nonReentrant {
        require(userLocks[msg.sender].tokenAmount > 0, 'Not enough tokens Locked');
		
		iPNFTNft pochiContract = iPNFTNft(nftContract);
		require(!pochiContract.isBurnedToAdult(_nftId), 'Already Burned to Adulthood');
		require(pochiContract.ownerOf(_nftId) == msg.sender, 'Not owner of NFT');
		
		uint256 burnAmount = pochiContract.getBurnAmount(_nftId);
		require(userLocks[msg.sender].tokenAmount >= burnAmount, 'Not enough staked to Burn');
		
		uint256 tokensRemoved = 0;
		uint256 tokensToRedist = 0;
		
		// remove first from staked nft
		for (uint i = 0; i < userLocks[msg.sender].nftCount; i++) {
			if (_nftId == userLocks[msg.sender]._feeds[i].nftId) {
				tokensRemoved += (userLocks[msg.sender]._feeds[i].amt <= burnAmount)? userLocks[msg.sender]._feeds[i].amt : burnAmount;
				tokensToRedist += userLocks[msg.sender]._feeds[i].amt - burnAmount;
				userLocks[msg.sender]._feeds[i].amt = 0;
				userLocks[msg.sender]._feeds[i].timeOut = block.timestamp;
				pochiContract.takeFeedAll(_nftId);
				pochiContract.burnToAdulthood(_nftId);
				break;
			}
		}
		// if tokensRemoved == burnAmount return
		
		uint nftsStaked = 0;
		uint256 tokensStaked = 0;
		for (uint i = 0; i < userLocks[msg.sender].nftCount; i++) {
			tokensStaked += userLocks[msg.sender]._feeds[i].amt;
			if (userLocks[msg.sender]._feeds[i].amt > 0) {
				nftsStaked++;
			}
		}
		
		// remove second any remainder from staked but not attributed to nft
		if (tokensRemoved < burnAmount && tokensStaked < userLocks[msg.sender].tokenAmount) {
			tokensRemoved += ((userLocks[msg.sender].tokenAmount - tokensStaked) < (burnAmount - tokensRemoved))? (userLocks[msg.sender].tokenAmount - tokensStaked) : (burnAmount - tokensRemoved);
		}
		
		// remove third from other staked nfts
		if (tokensRemoved < burnAmount) {
			for (uint i = 0; i < userLocks[msg.sender].nftCount; i++) {
				if (tokensRemoved >= burnAmount) {
					break;
				}
				if (_nftId != userLocks[msg.sender]._feeds[i].nftId) {
					uint256 amountToRemove = (userLocks[msg.sender]._feeds[i].amt <= (burnAmount - tokensRemoved))? userLocks[msg.sender]._feeds[i].amt : (burnAmount - tokensRemoved);
					tokensRemoved += amountToRemove;
					userLocks[msg.sender]._feeds[i].amt -= amountToRemove;
					userLocks[msg.sender]._feeds[i].timeOut = block.timestamp;
					pochiContract.takeFeed(_nftId, amountToRemove);
				}
			}
		}
		
		// redistribute leftover tokens from burned NFT
		if (tokensToRedist > 0 && nftsStaked > 0) {
			uint256 tokensPerNFT = tokensToRedist / nftsStaked;
			uint256 tokensLeft = tokensToRedist;
					
			for (uint i = 0; i < userLocks[msg.sender].nftCount; i++) {
				if (userLocks[msg.sender]._feeds[i].amt > 0) {
					uint256 amt = (tokensPerNFT <= tokensLeft)? tokensPerNFT : tokensLeft;
					userLocks[msg.sender]._feeds[i].amt += amt;
					pochiContract.giveFeed(userLocks[msg.sender]._feeds[i].nftId, userLocks[msg.sender]._feeds[i].amt, msg.sender);
					tokensLeft -= amt;
				}
			}
		}
		
		userLocks[msg.sender].tokenAmount -= burnAmount;
		userLocks[msg.sender].burnAmount += burnAmount;
		
		token.safeTransfer(deadWallet, burnAmount);
		emit TokensBurned(burnAmount, address(0xdead));  
	}

    // gets Locks of an address
	//
	// retuns:
	// 		tokenAmount
	// 		claimedAmount
	// 		burnAmount
	// 		startTime
	// 		nftCount
	//
    function getLocked(address _addr) public view returns(uint256, uint256, uint256, uint256, uint) {
        return (userLocks[_addr].tokenAmount, userLocks[_addr].claimedAmount, userLocks[_addr].burnAmount, userLocks[_addr].startTime, userLocks[_addr].nftCount);
    }

    // gets Feeds of an address
	// _count is the nftCount (minus 1, as solidity counts start at zero) - from function getLocked
	//		eg.  if the returned nftCount=2, you can pass 0 or 1 to this function for that address
	//
	// retuns:
	// 		nftId
	// 		timeIn
	// 		amt
	// 		ownerAddress
	// 		timeOut
	//
	function getFeed(address _addr, uint _count) public view returns(uint256, uint256, uint256, address, uint256) {
		return (userLocks[_addr]._feeds[_count].nftId, userLocks[_addr]._feeds[_count].timeIn ,userLocks[_addr]._feeds[_count].amt ,userLocks[_addr]._feeds[_count].ownerAddress ,userLocks[_addr]._feeds[_count].timeOut);
	}

    event TeamWalletChange(address oldTeamWallet, address newTeamWallet);
    function setTeamWallet(address _teamWallet) public {
        require(msg.sender == teamWallet,'Not allowed');

        address prevWallet = teamWallet;
        teamWallet = _teamWallet;

        emit TeamWalletChange(prevWallet, _teamWallet);
    }

    // pull ETH out of the contract to the owner, needed for migrations/emergencies/EOL 
    // the team wallet should be set to a multi-sig wallet
    event AdminEthWithdraw(address account, uint256 amount);
    function withdrawETH() public {
        require(msg.sender == teamWallet, 'Not allowed');
        uint256 amount = address(this).balance;
         (bool sent,) =address(owner()).call{value: (amount)}("");

        require(sent,"withdraw failed");
        emit AdminEthWithdraw(msg.sender, amount);
    }
	
    // pull Tokens out of the contract to the owner, needed for migrations/emergencies/EOL 
    // the team wallet should be set to a multi-sig wallet
	event AdminTokenWithdraw(address account, uint256 amount);
    function withdrawToken() public {
        require(msg.sender == teamWallet, 'Not allowed');
		uint256 amount = token.balanceOf(address(this));
		token.safeTransfer(address(owner()), amount);

        emit AdminTokenWithdraw(msg.sender, amount);
    }

    function onERC721Received(address operator, address, uint256, bytes calldata) external view returns(bytes4) {
        require(operator == address(this), "can not directly transfer");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

interface iPNFTNft {
	function giveFeed(uint256 tokenId, uint256 feedAmt, address tokenOwner) external ;
	function takeFeed(uint256 tokenId, uint256 feedAmt) external ;
	function takeFeedAll(uint256 tokenId) external ;
	function burnToAdulthood(uint256 tokenId) external ;
	function getBurnAmount(uint256 tokenId) external returns(uint256);
	function isBurnedToAdult(uint256 tokenId) external returns(bool);
	function ownerOf(uint256 tokenId) external returns (address);
}