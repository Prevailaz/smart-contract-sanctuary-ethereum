// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { IRaffle } from "../interfaces/IRaffle.sol";
import { IWinnerAirnode } from "../interfaces/IWinnerAirnode.sol";
import { IAssetVault } from "../interfaces/IAssetVault.sol";
import { IVaultFactory } from "../interfaces/IVaultFactory.sol";
import { IVaultDepositRouter } from "../interfaces/IVaultDepositRouter.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Events } from "../libraries/Events.sol";
import { Errors } from "../libraries/Errors.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Raffle
 * @author API3 Latam
 *
 * @notice This is the implementation of the Raffle contract.
 * Including the logic to operate an individual Raffle.
 */
contract Raffle is OwnableUpgradeable, IRaffle  {

    using Counters for Counters.Counter;

    // ========== Storage ==========
    Counters.Counter private _participantId;    // The current index of the mapping.
    uint256 public raffleId;                    // The id of this raffle contract.
    address public creatorAddress;              // The address from the creator of the raffle.
    uint256 public winnerNumber;                // The number of winners for this raffle.
    uint256 public startTime;                   // The starting time for the raffle.
    uint256 public endTime;                     // The end time for the raffle.
    DataTypes.RaffleStatus public status;       // The status of the raffle.
    DataTypes.Multihash public metadata;        // The metadata information for this raffle.
    
    address public winnerRequester;             // The address of the requester being use.
    bytes32 public requestId;                   // The id for this raffle airnode request.

    address[] public winners;                   // Winner addresses for this raffle.
    address[] public tokens;                    // Tokens to be set as prize.
    uint256[] public ids;                       // TokenIds to be set as prize.

    address public vaultFactory;                // VaultFactory Proxy address to interact with.
    uint256 public vaultId;                     // Vault Token Id for ownership validation.
    address public vaultRouter;                 // VaultDepositRouter Proxy

    mapping(uint256 => address) public participants; // Id to participants mapping.
    
    // ========== Modifiers ==========
    modifier isOpen() {
        if (status != DataTypes.RaffleStatus.Open) {
            revert Errors.RaffleNotOpen();
        }
        _;
    }

    modifier isAvailable() {
        if (!(status == DataTypes.RaffleStatus.Unintialized ||
                status == DataTypes.RaffleStatus.Open)) {
            revert Errors.RaffleNotAvailable();
        }
        _;
    }

    // ========== Constructor/Initializer ==========
    /**
     * @dev Disables initializers, so contract can only be used trough proxies.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev See { IRaffle-initialize }.
     */
    function initialize (
        address _creatorAddress,
        uint256 _raffleId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _winnerNumber,
        DataTypes.Multihash memory _metadata
    ) external initializer {
        creatorAddress = _creatorAddress;
        status = DataTypes.RaffleStatus.Unintialized;
        raffleId = _raffleId;

        if (_startTime < block.timestamp) {
            revert Errors.WrongInitializationParams(
                "Raffle: Invalid `startTime` parameter."
            );
        }
        startTime = _startTime;

        if (_endTime < _startTime) {
            revert Errors.WrongInitializationParams(
                "Raffle: Invalid `endTime` parameter."
            );
        }
        endTime = _endTime;

        if (_winnerNumber <= 0) {
            revert Errors.WrongInitializationParams(
                "Raffle: Invalid `winnerNumber` parameter."
            );
        }
        winnerNumber = _winnerNumber;
        metadata = _metadata;

        __Ownable_init();
        _transferOwnership(_creatorAddress);
    }

    // ========== Core Functions ==========
    /**
     * @dev See { IRaffle-open }.
     */
    function open (
        address _vaultFactory,
        address _vaultRouter,
        address[] memory _tokens,
        uint256[] memory _ids
    ) external onlyOwner {
        if (startTime < block.timestamp) {
            revert Errors.RaffleNotAvailable();
        }

        if (_tokens.length != winnerNumber) {
            revert Errors.InvalidWinnerNumber();
        }

        vaultFactory = _vaultFactory;
        vaultRouter = _vaultRouter;

        IVaultFactory vFactory = IVaultFactory(vaultFactory);
        IVaultDepositRouter vRouter = IVaultDepositRouter(vaultRouter);

        vaultId = vFactory.create(address(this));
        
        if (_tokens.length != _ids.length) {
            revert Errors.BatchLengthMismatch();
        }
        if (_tokens.length == 1) {
            vRouter.depositERC721(owner(), vaultId, _tokens[0], _ids[0]);
        }
        if (_tokens.length > 1) {
            vRouter.depositERC721Batch(owner(), vaultId, _tokens, _ids);
        }

        status = DataTypes.RaffleStatus.Open;
        tokens = _tokens;
        ids = _ids;
    }

    /**
     * @dev See { IRaffle-enter }.
     */
    function enter (
        address participantAddress
    ) external override isOpen {
        participants[_participantId.current()] = participantAddress;
        _participantId.increment();
    }

    /**
     * @dev See { IRaffle-close }.
     */
    function close ()
     external override onlyOwner isOpen {
        if (winnerRequester == address(0)) revert Errors.ParameterNotSet();

        if (endTime > block.timestamp) revert Errors.EarlyClosing();

        IWinnerAirnode airnode = IWinnerAirnode(winnerRequester);
        bytes32 _requestId; 
        
        if (winnerNumber == 1) {
            _requestId = airnode.requestWinners (
                airnode.getIndividualWinner.selector, 
                winnerNumber, 
                _participantId.current()
            );
        } else {
            _requestId = airnode.requestWinners (
                airnode.getMultipleWinners.selector, 
                winnerNumber, 
                _participantId.current()
            );
        }

        IVaultFactory vFactory = IVaultFactory(vaultFactory);
        IAssetVault vault = IAssetVault(
            vFactory.instanceAt(vaultId)
        );

        vault.enableWithdraw();

        requestId = _requestId;
        status = DataTypes.RaffleStatus.Close;
    }

    /**
     * @dev See { IRaffle-finish }.
     */
    function finish () 
     external override onlyOwner {
        IWinnerAirnode airnode = IWinnerAirnode(winnerRequester);

        if (status != DataTypes.RaffleStatus.Close) {
            revert Errors.RaffleNotClose();
        }

        DataTypes.WinnerReponse memory winnerResults =  airnode.requestResults(requestId);

        for (uint256 i; i < winnerNumber; i++) {
            winners.push(
                participants[winnerResults.winnerIndexes[i]]
            );
        }

        status = DataTypes.RaffleStatus.Finish;

        IVaultFactory vFactory = IVaultFactory(vaultFactory);
        IAssetVault vault = IAssetVault(
            vFactory.instanceAt(vaultId)
        );

        for (uint256 i; i < winners.length; i++) {
            vault.withdrawERC721(
                tokens[i],
                ids[i],
                winners[i]
            );
        }

        emit Events.WinnerPicked(
            raffleId,
            winners
        );
    }

    /**
     * @dev See { IRaffle-cancel }.
     */
    function cancel () 
     external override isAvailable {
        status = DataTypes.RaffleStatus.Canceled;
    }

    // ========== Get/Set Functions ==========
    /**
     * @dev See { IRaffle-setRequester }.
     */
    function setRequester (
        address _requester
    ) external onlyOwner isAvailable {
        if (winnerRequester == _requester) {
            revert Errors.SameValueProvided();
        }

        if (_requester == address(0)) {
            revert Errors.ZeroAddress();
        }

        winnerRequester = _requester;
    }

    /**
     * @dev See { IRaffle-updateWinners }.
     */
    function updateWinners (
        uint256 _winnerNumbers
    ) external override onlyOwner {
        if (status != DataTypes.RaffleStatus.Unintialized) revert Errors.RaffleAlreadyOpen();

        if (_winnerNumbers <= 0) revert Errors.InvalidWinnerNumber();

        winnerNumber = _winnerNumbers;
    }

    /**
     * @dev See { IRaffle-updateMetadata }
     */
    function updateMetadata (
        DataTypes.Multihash memory _metadata
    ) external override onlyOwner isAvailable {
        metadata = _metadata;
    }

    // ========== Upgradability ==========
    /**
     * @dev See { IRaffle-getVersion }.
     */
    function getVersion ()
     external pure returns (
        uint256 version
    ) {
        return 1;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title IAssetVault
 * @author API3 Latam
 *
 * @notice This is the interface for the AssetVault contract,
 * which is utilized for safekeeping of assets during Hub
 * user flows, like 'Raffles'.
 *
 * This contract is based from the arcadexyz repository `v2-contracts`.
 * You can found it at this URL:
 * https://github.com/arcadexyz/v2-contracts/blob/main/contracts/interfaces/IAssetVault.sol
 */
interface IAssetVault {
    // ================ Initialize ================
    /**
     * @notice Initializer for the logic contract trough the minimal clone proxy.
     * @dev In practice, always called by the VaultFactory contract.
     */
    function initialize () external;

    // ========== Core Functions ==========
    /**
     * @notice Enables withdrawals on the vault.
     * @dev Any integration should be aware that a withdraw-enabled vault cannot
     * be transferred (will revert).
     */
    function enableWithdraw () 
     external;

    /**
     * @notice Withdraw entire balance of a given ERC721 token from the vault.
     * The vault must be in a "withdrawEnabled" state (non-transferrable).
     * The specified token must exist and be owned by this contract.
     *
     * @param token The token to withdraw.
     * @param tokenId The ID of the NFT to withdraw.
     * @param to The recipient of the withdrawn token.
     */
    function withdrawERC721 (
        address token,
        uint256 tokenId,
        address to
    ) external;

    // ========== Get/Set Functions ==========
    /**
     * 
     */
    function withdrawEnabled ()
     external view returns (
        bool
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { DataTypes } from '../libraries/DataTypes.sol';

/**
 * @title IRaffle
 * @author API3 Latam
 *
 * @notice This is the interface for the Raffle contract,
 * which is initialized everytime a new raffle is requested.
 */
interface IRaffle {
  // ================ Initialize ================
  /**
   * @notice Initializer function for factory pattern.
   * @dev This replaces the constructor so we can apply the 'cloning'.
   * This is called trough the FairHub.
   *
   * @param _creatorAddress The raffle creator.
   * @param _raffleId The id for this raffle.
   * @param _startTime The starting time for the raffle.
   * @param _endTime The end time for the raffle.
   * @param _winnerNumber The initial number to set as total winners.
   * @param _metadata The `Multihash` information for this raffle metadata.
   */
  function initialize (
    address _creatorAddress,
    uint256 _raffleId,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _winnerNumber,
    DataTypes.Multihash memory _metadata
  ) external;

  // ========== Core Functions ==========
  /**
   * @notice Opens a raffle to the public,
   * and safekeeps the assets in the vault.
   * @dev `_tokens`, `_ids` and `winnerNumber` should match.
   *
   * @param _vaultFactory The VaultFactory proxy address to use.
   * @param _vaultRouter The VauldDepositRouter Proxy to use.
   * @param _tokens The tokens addresses to use for prizes.
   * @param _ids The id for the respective address in the array of `_tokens`.
   */
  function open (
    address _vaultFactory,
    address _vaultRouter,
    address[] memory _tokens,
    uint256[] memory _ids
  ) external;

  /**
    * @notice Enter the raffle.
    * @param participantAddress The participant address.
    */
  function enter (
      address participantAddress
  ) external;

  /**
    * @notice Closes the ongoing raffle.
    * @dev Called by the owner when the raffle is over.
    * This function stops new entries from registering and will
    * call the `WinnerAirnode`.
    */
  function close () external;

  /**
    * @notice Wrap ups a closed raffle.
    * @dev This function updates the winners as result from calling the airnode.
    */
  function finish () external;

  /**
    * @notice Cancel an available raffle.
    */
  function cancel () external;

  // ========== Get/Set Functions ==========
  /**
    * @notice Set address for winnerRequester.
    *
    * @param _requester The address of the requester contract.
    */
  function setRequester (
        address _requester
    ) external;

  /**
    * @notice Update the set number of winners.
    *
    * @param _winnerNumbers The new number of winners for this raffle.
    */
  function updateWinners(
    uint256 _winnerNumbers
  ) external;

  /**
    * @notice Update the metadata for the raffle.
    *
    * @param _metadata The new metadata struct.
    */
  function updateMetadata(
    DataTypes.Multihash memory _metadata
  ) external;

  // ========== Upgradability ==========
  /**
    * @notice Returns the current implementation version for this contract.
    * @dev This version will be manually updated on each new contract version deployed.
    *
    * @return version The current version of the implementation.
    */
  function getVersion ()
    external pure returns (
      uint256 version
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title IVaultDepositRouter.
 * @author API3 Latam.
 *
 * @notice Interface for VaultDepositRouter.
 */
interface IVaultDepositRouter {
    // ================ Initialize ================
    /**
     * @notice Initializer for the logic contract trough the UUPS Proxy.
     *
     * @param _factoryAddress The address to use for the factory interface.
     */
    function initialize (
        address _factoryAddress
    ) external;

    // ========== Upgrade Functions ==========
    /**
     * @notice Updates the VaultFactory implementation address.
     *
     * @param newImplementation The address of the upgraded version of the contract.
     */
    function upgradeFactory (
        address newImplementation
    ) external;

    /**
     * @notice Returns the current implementation version for this contract.
     * @dev This version will be manually updated on each new contract version deployed.
     *
     * @return version The current version of the implementation.
     */
    function getVersion ()
     external pure returns (
        uint256 version
    );

    // ========== Core Functions ==========
    /**
     * @notice Deposit an ERC721 token to a vault.
     *
     * @param owner The address of the current owner of the token.
     * @param vault The vault to deposit to.
     * @param token The tokens to deposit.
     * @param id The ID of the token to deposit.
     */
    function depositERC721 (
        address owner,
        uint256 vault,
        address token,
        uint256 id
    ) external;

    /**
     * @notice Deposit ERC721 tokens in batch to the vault.
     *
     * @param owner The address of the current owner of the token.
     * @param vault The vault to deposit to.
     * @param tokens The token to deposit.
     * @param ids The ID of the token to deposit, for each token.
     */
    function depositERC721Batch (
        address owner,
        uint256 vault,
        address[] calldata tokens,
        uint256[] calldata ids
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IVaultFactory {
    // ================ Initialize ================
    /**
     * @notice Initializer for the logic contract trough the UUPS Proxy.
     *
     * @param _vaultAddress The template to use for the factory cloning of vaults.
     */
    function initialize (
        address _vaultAddress
    ) external;

    // ================ Upgrade Functions ================
    /**
     * @notice Updates the AssetVault logic contract address.
     *
     * @param newImplementation The address of the upgraded version of the contract.
     */
    function upgradeVault (
        address newImplementation
    ) external;

    /**
     * @notice Returns the current implementation version for this contract.
     * @dev This version will be manually updated on each new contract version deployed.
     *
     * @return version The current version of the implementation.
     */
    function getVersion ()
     external pure returns (
        uint256 version
    );

    // ================ Core Functions ================
    /**
     * @notice Creates a new vault contract.
     *
     * @param to The address that will own the new vault.
     *
     * @return vaultId The id of the vault token, derived from the initialized clone address.
     */
    function create (
        address to
    ) external returns (
        uint256 vaultId
    );

    // ================ Get/Set Functions ================
    /**
     * @notice Check if the given address is a vault instance created by this factory.
     *
     * @param instance The address to check.
     *
     * @return validity Whether the address is a valid vault instance.
     */
    function isInstance (
        address instance
    ) external view returns (
        bool validity
    );

    /**
     * @notice Return the address of the instance for the given token ID.
     *
     * @param tokenId The token ID for which to find the instance.
     *
     * @return instance The address of the derived instance.
     */
    function instanceAt (
        uint256 tokenId
    ) external view returns (
        address instance
    );

    /**
     * @notice Return the address of the instance for the given index.
     * Allows for enumeration over all instances.
     *
     * @param index The index for which to find the instance.
     *
     * @return instance The address of the instance, derived from the corresponding
     * token ID at the specified index.
     */
    function instanceAtIndex (
        uint256 index
    ) external view returns (
        address instance
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title IWinnerAirnode
 * @author API3 Latam
 *
 * @notice This is the interface for the Winner Airnode,
 * which is initialized utilized when closing up a raffle.
 */
interface IWinnerAirnode {
    // ========== Core Functions ==========
    /**
     * @notice - The function to request this airnode implementation call.
     *
     * @param callbackSelector - The target endpoint to use as callback.
     * @param winnerNumbers - The number of winners to return
     * @param participantNumbers - The number of participants from the raffle.
     */
    function requestWinners (
        bytes4 callbackSelector,
        uint256 winnerNumbers,
        uint256 participantNumbers
    ) external returns (
        bytes32
    );

    /**
     * @notice Return the results from a given request.
     *
     * @param requestId The request to get results from.
     */
    function requestResults (
        bytes32 requestId
    ) external returns (
        DataTypes.WinnerReponse memory
    );

    // ========== Callback Functions ==========
    /**
     * @notice - Callback function when requesting one winner only.
     * @dev - We suggest to set this as endpointId index `1`.
     *
     * @param requestId - The id for this request.
     * @param data - The response from the API send by the airnode.
     */
    function getIndividualWinner (
        bytes32 requestId,
        bytes calldata data
    ) external;

    /**
     * @notice - Callback function when requesting multiple winners.
     * @dev - We suggest to set this as endpointId index `2`.
     *
     * @param requestId - The id for this request.
     * @param data - The response from the API send by the airnode. 
     */
    function getMultipleWinners (
        bytes32 requestId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title DataTypes
 * @author API3 Latam
 * 
 * @notice A standard library of data types used across the API3 LATAM
 * Fairness Platform.
 */
library DataTypes {
    
    // ========== Enums ==========
    /**
     * @notice An enum containing the different states a raffle can use.
     *
     * @param Unintialized - A raffle is created but yet to be open.
     * @param Canceled - A raffle that is invalidated.
     * @param Open - A raffle where participants can enter.
     * @param Close - A raffle which cannot recieve more participants.
     * @param Finish - A raffle that has been wrapped up.
     */
    enum RaffleStatus {
        Unintialized,
        Canceled,
        Open,
        Close,
        Finish
    }

    // ========== Structs ==========
    /**
     * @notice An enum containing the 
     */

    /**
     * @notice Structure to efficiently save IPFS hashes.
     * @dev To reconstruct full hash insert `hash_function` and `size` before the
     * the `hash` value. So you have `hash_function` + `size` + `hash`.
     * This gives you a hexadecimal representation of the CIDs. You need to parse
     * it to base58 from hex if you want to use it on a traditional IPFS gateway.
     *
     * @param hash - The hexadecimal representation of the CID payload from the hash.
     * @param hash_function - The hexadecimal representation of multihash identifier.
     * IPFS currently defaults to use `sha2` which equals to `0x12`.
     * @param size - The hexadecimal representation of `hash` bytes size.
     * Expecting value of `32` as default which equals to `0x20`. 
     */
    struct Multihash {
        bytes32 hash;
        uint8 hash_function;
        uint8 size;
    }

    /**
     * @notice Information for Airnode endpoints.
     *
     * @param endpointId - The unique identifier for the endpoint this
     * callbacks points to.
     * @param functionSelector - The function selector for this endpoint
     * callback.
     */
    struct Endpoint {
        bytes32 endpointId;
        bytes4 functionSelector;
    }

    /**
     * @notice Metadata information for WinnerAirnode request flow.
     * @dev This should be consume by used in addition to IndividualRaffle struct
     * to return actual winner addresses.
     *
     * @param totalEntries - The number of participants for this raffle.
     * @param totalWinners - The number of winners finally set for this raffle.
     * @param winnerIndexes - The indexes for the winners from raffle entries.
     * @param isFinished - Indicates wether the result has been retrieved or not.
     */
    struct WinnerReponse {
        uint256 totalEntries;
        uint256 totalWinners;
        uint256[] winnerIndexes;
        bool isFinished;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Errors
 * @author API3 Latam
 * 
 * @notice A standard library of error types used across the API3 LATAM
 * Raffle Platform.
 */
library Errors {

    // ========== Core Errors ==========
    error SameValueProvided ();
    error AlreadyInitialized ();
    error InvalidProxyAddress (
        address _proxy
    );
    error ZeroAddress();
    error WrongInitializationParams (
        string errorMessage
    );
    error InvalidParameter();
    error ParameterNotSet();
    error RaffleNotOpen ();             // Raffle
    error RaffleNotAvailable ();        // Raffle
    error RaffleNotClose ();            // Raffle
    error RaffleAlreadyOpen ();         // Raffle
    error EarlyClosing();               // Raffle

    // ========== Base Errors ==========
    error CallerNotOwner (               // Ownable ERC721
        address caller
    );
    error RequestIdNotKnown ();          // AirnodeLogic
    error NoEndpointAdded ();            // AirnodeLogic
    error InvalidEndpointId ();          // AirnodeLogic
    error IncorrectCallback ();          // AirnodeLogic

    // ========== Airnode Module Errors ==========
    error InvalidWinnerNumber ();        // WinnerAirnode
    error ResultRetrieved ();            // WinnerAirnode

    // ========== Vault Module Errors ==========
    error VaultWithdrawsDisabled ();     // AssetVault
    error VaultWithdrawsEnabled ();      // AssetVault
    error TokenIdOutOfBounds (           // VaultFactory
        uint256 tokenId
    );
    error NoTransferWithdrawEnabled (    // VaultFactory
        uint256 tokenId
    );
    error BatchLengthMismatch();         // VaultDepositRouter

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { DataTypes } from "./DataTypes.sol";

/**
 * @title Events
 * @author API3 Latam
 * 
 * @notice A standard library of Events used across the API3 LATAM
 * Raffle Platform.
 */
library Events {

    // ========== Core Events ==========
    /**
     * @dev Emitted when a Raffle is created.
     * 
     * @param _raffleId - The identifier for this specific raffle.
     */
    event RaffleCreated (
        uint256 indexed _raffleId
    );

    /**
     * @dev Emitted when the winners are set from the QRNG provided data.
     *
     * @param _raffleId - The identifier for this specific raffle.
     * @param raffleWinners - The winner address list for this raffle.
     */
    event WinnerPicked (
        uint256 indexed _raffleId,
        address[] raffleWinners
    );

        // ========== Base Events ==========
    /**
     * @dev Emitted when we set the parameters for the airnode.
     *
     * @param airnodeAddress - The Airnode address being use.
     * @param sponsorAddress - The address from sponsor.
     * @param sponsorWallet - The actual sponsored wallet address.
     */
    event SetRequestParameters (
        address airnodeAddress,
        address sponsorAddress,
        address sponsorWallet
    );

    /**
     * @dev Emitted when a new Endpoint is added to an AirnodeLogic instance.
     *
     * @param _index - The current index for the recently added endpoint in the array.
     * @param _newEndpointId - The given endpointId for the addition.
     * @param _newEndpointSelector - The selector for the given endpoint of this addition.
     */
    event SetAirnodeEndpoint (
        uint256 indexed _index,
        bytes32 indexed _newEndpointId,
        string _endpointFunction,
        bytes4 _newEndpointSelector
    );

    // ========== Airnode Module Events ==========
    /**
     * @dev Should be emitted when a request to WinnerAirnode is done.
     *
     * @param requestId - The request id which this event is related to.
     * @param airnodeAddress - The airnode address from which this request was originated.
     */
    event NewWinnerRequest (
        bytes32 indexed requestId,
        address indexed airnodeAddress
    );

    /**
     * @dev Same as `NewRequest` but, emitted at the callback time when
     * a request is successful for flow control.
     *
     * @param requestId - The request id from which this event was emitted.
     * @param airnodeAddress - The airnode address from which this request was originated.
     */
    event SuccessfulRequest (
        bytes32 indexed requestId,
        address indexed airnodeAddress
    );

    // ========== Vault Module Events ==========
    /**
     * @dev Should be emitted when withdrawals are enabled on a vault.
     *
     * @param emitter The address of the vault owner.
     */
    event WithdrawEnabled (
        address emitter
    );
    
    /**
     * @dev Should be emitted when the balance of ERC721s is withdraw
     * from a vault.
     *
     * @param emitter The address of the vault owner.
     * @param recipient The end user to recieve the assets.
     * @param tokenContract The addresses of the assets being transfered.
     * @param tokenId The id of the token being transfered.
     */
    event WithdrawERC721 (
        address indexed emitter,
        address indexed recipient,
        address indexed tokenContract,
        uint256 tokenId
    );

    /**
     * @dev Should be emitted when factory creates a new vault clone.
     *
     * @param vault The address of the new vault.
     * @param to The new owner of the vault.
     */
    event VaultCreated (
        address vault,
        address to
    );
}