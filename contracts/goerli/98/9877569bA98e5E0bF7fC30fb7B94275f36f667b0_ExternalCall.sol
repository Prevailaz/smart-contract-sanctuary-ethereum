// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IoDAO.sol";
import "./interfaces/IExternalCall.sol";
import "./interfaces/ICantoTurnstile.sol";
import "./interfaces/ICSRvault.sol";

contract ExternalCall is IExternalCall {
    uint256 immutable DELAY = 10 * 1 days;

    IoDAO ODAO;

    mapping(uint256 => ExtCall) externalCallById;

    /// id of call => address of dao => lastExecuted
    mapping(uint256 => mapping(address => uint256)) lastExecutedorCreatedAt;

    /// dao nonce
    mapping(address => uint256) nonce;

    constructor(address odao_) {
        ODAO = IoDAO(odao_);
        address CSRvault = IoDAO(ODAO).CSRvault();
        ITurnstile(ICSRvault(CSRvault).turnSaddr()).assign(ICSRvault(CSRvault).CSRtokenID());
    }

    error ExternalCall_UnregisteredDAO();
    error ExternalCall_CallDatasContractsLenMismatch();

    modifier onlyDAO() {
        if (!ODAO.isDAO(msg.sender)) revert ExternalCall_UnregisteredDAO();
        _;
    }

    event NewExternalCall(address indexed CreatedBy, string description, uint256 createdAt);
    event ExternalCallExec(address indexed CalledBy, uint256 indexed WhatCallId, bool SuccessOrLater);

    function createExternalCall(address[] memory contracts_, bytes[] memory callDatas_, string memory description_)
        external
        returns (uint256 idOfNew)
    {
        if (contracts_.length != callDatas_.length) revert ExternalCall_CallDatasContractsLenMismatch();
        ExtCall memory newCall;
        newCall.contractAddressesToCall = contracts_;
        newCall.dataToCallWith = callDatas_;
        newCall.shortDescription = description_;

        idOfNew = uint256(keccak256(abi.encode(newCall))) % 1 ether;
        externalCallById[idOfNew] = newCall;

        emit NewExternalCall(msg.sender, description_, block.timestamp);
    }

    function exeUpdate(uint256 whatExtCallId_) external onlyDAO returns (bool r) {
        r = lastExecutedorCreatedAt[whatExtCallId_][msg.sender] + DELAY <= block.timestamp;
        if (r) {
            delete lastExecutedorCreatedAt[whatExtCallId_][msg.sender];
        } else {
            if (lastExecutedorCreatedAt[whatExtCallId_][msg.sender] == 0) {
                lastExecutedorCreatedAt[whatExtCallId_][msg.sender] = block.timestamp;
            }
        }

        emit ExternalCallExec(msg.sender, whatExtCallId_, r);
    }

    function incrementSelfNonce() external onlyDAO {
        unchecked {
            ++nonce[msg.sender];
        }
    }

    /// @notice at what timestamp the caller executed id_
    function iLastExecuted(uint256 id_) external view returns (uint256) {
        return lastExecutedorCreatedAt[id_][msg.sender];
    }

    function getExternalCallbyID(uint256 id_) external view returns (ExtCall memory) {
        return externalCallById[id_];
    }

    function isValidCall(uint256 id_) external view returns (bool) {
        return externalCallById[id_].contractAddressesToCall.length > 0;
    }

    function getNonceOf(address whom_) external view returns (uint256) {
        return nonce[whom_];
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

/// @notice Implementation of CIP-001 https://github.com/Canto-Improvement-Proposals/CIPs/blob/main/CIP-001.md
/// @dev Every contract is responsible to register itself in the constructor by calling `register(address)`.
///      If contract is using proxy pattern, it's possible to register retroactively, however past fees will be lost.
///      Recipient withdraws fees by calling `withdraw(uint256,address,uint256)`.
interface ICSRvault {
    function CSRtokenID() external returns (uint256);

    function selfRegister() external returns (bool);

    function withdrawBurn(uint256 amt) external returns (bool);

    function turnSaddr() external returns (address);

    function sharesTokenAddr() external view returns (address);
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

/// @notice Implementation of CIP-001 https://github.com/Canto-Improvement-Proposals/CIPs/blob/main/CIP-001.md
/// @dev Every contract is responsible to register itself in the constructor by calling `register(address)`.
///      If contract is using proxy pattern, it's possible to register retroactively, however past fees will be lost.
///      Recipient withdraws fees by calling `withdraw(uint256,address,uint256)`.
interface ITurnstile {
    struct NftData {
        uint256 tokenId;
        bool registered;
    }

    /// @notice Returns current value of counter used to tokenId of new minted NFTs
    /// @return current counter value
    function currentCounterId() external view returns (uint256);
    /// @notice Returns tokenId that collects fees generated by the smart contract
    /// @param _smartContract address of the smart contract
    /// @return tokenId that collects fees generated by the smart contract
    function getTokenId(address _smartContract) external view returns (uint256);

    /// @notice Returns true if smart contract is registered to collect fees
    /// @param _smartContract address of the smart contract
    /// @return true if smart contract is registered to collect fees, false otherwise
    function isRegistered(address _smartContract) external view returns (bool);

    /// @notice Mints ownership NFT that allows the owner to collect fees earned by the smart contract.
    ///         `msg.sender` is assumed to be a smart contract that earns fees. Only smart contract itself
    ///         can register a fee receipient.
    /// @param _recipient recipient of the ownership NFT
    /// @return tokenId of the ownership NFT that collects fees
    function register(address _recipient) external returns (uint256 tokenId);

    /// @notice Assigns smart contract to existing NFT. That NFT will collect fees generated by the smart contract.
    ///         Callable only by smart contract itself.
    /// @param _tokenId tokenId which will collect fees
    /// @return tokenId of the ownership NFT that collects fees
    function assign(uint256 _tokenId) external returns (uint256);

    /// @notice Withdraws earned fees to `_recipient` address. Only callable by NFT owner.
    /// @param _tokenId token Id
    /// @param _recipient recipient of fees
    /// @param _amount amount of fees to withdraw
    /// @return amount of fees withdrawn
    function withdraw(uint256 _tokenId, address payable _recipient, uint256 _amount) external returns (uint256);

    /// @notice Distributes collected fees to the smart contract. Only callable by owner.
    /// @param _tokenId NFT that earned fees
    function distributeFees(uint256 _tokenId) external;

    function balances(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct ExtCall {
    address[] contractAddressesToCall;
    bytes[] dataToCallWith;
    string shortDescription;
}

interface IExternalCall {
    function createExternalCall(address[] memory contracts_, bytes[] memory callDatas_, string memory description_)
        external
        returns (uint256);

    function getExternalCallbyID(uint256 id) external view returns (ExtCall memory);

    function incrementSelfNonce() external;

    function exeUpdate(uint256 whatExtCallId_) external returns (bool);

    function isValidCall(uint256 id_) external view returns (bool);

    function getNonceOf(address whom_) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./structs.sol";

interface IMemberRegistry {
    function makeMember(address who_, uint256 id_) external returns (bool);

    function gCheckBurn(address who_, address DAO_) external returns (bool);

    /// onlyMembrane
    function howManyTotal(uint256 id_) external view returns (uint256);
    function setUri(string memory uri_) external;
    function uri(uint256 id) external view returns (string memory);

    function ODAOaddress() external view returns (address);
    function MembraneRegistryAddress() external view returns (address);
    function ExternalCallAddress() external view returns (address);

    function getRoots(uint256 startAt_) external view returns (address[] memory);
    function getEndpointsOf(address who_) external view returns (address[] memory);

    function getActiveMembershipsOf(address who_) external view returns (address[] memory entities);
    function getUriOf(address who_) external view returns (string memory);
    //// only ODAO

    function pushIsEndpoint(address) external;
    function pushAsRoot(address) external;
    //////////////////////// ERC1155

    ///// only odao
    function pushIsEndpointOf(address dao_, address endpointOwner_) external;

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
     *     @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     *     MUST revert if `_to` is the zero address.
     *     MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
     *     MUST revert on any other error.
     *     MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     *     After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     *     @param _from    Source address
     *     @param _to      Target address
     *     @param _id      ID of the token type
     *     @param _value   Transfer amount
     *     @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
     *     @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     *     MUST revert if `_to` is the zero address.
     *     MUST revert if length of `_ids` is not the same as length of `_values`.
     *     MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
     *     MUST revert on any other error.
     *     MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     *     Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     *     After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     *     @param _from    Source address
     *     @param _to      Target address
     *     @param _ids     IDs of each token type (order and length must match _values array)
     *     @param _values  Transfer amounts per token type (order and length must match _ids array)
     *     @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
     * @notice Get the balance of an account's tokens.
     *     @param _owner  The address of the token holder
     *     @param _id     ID of the token
     *     @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     *     @param _owners The addresses of the token holders
     *     @param _ids    ID of the tokens
     *     @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     *     @dev MUST emit the ApprovalForAll event on success.
     *     @param _operator  Address to add to the set of authorized operators
     *     @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner.
     *     @param _owner     The owner of the tokens
     *     @param _operator  Address of authorized operator
     *     @return           True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMember1155.sol";

interface IoDAO {
    function isDAO(address toCheck) external view returns (bool);

    function createDAO(address BaseTokenAddress_) external returns (address newDAO);

    function createSubDAO(uint256 membraneID_, address parentDAO_) external returns (address subDAOaddr);

    function getParentDAO(address child_) external view returns (address);

    function getDAOsOfToken(address parentToken) external view returns (address[] memory);

    function getDAOfromID(uint256 id_) external view returns (address);

    function getTrickleDownPath(address floor_) external view returns (address[] memory);

    function CSRvault() external view returns (address);
}

struct Membrane {
    address[] tokens;
    uint256[] balances;
    string meta;
}