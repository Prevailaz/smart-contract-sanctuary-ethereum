// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "./IStarknetMessaging.sol";
import "contracts/starkware/solidity/libraries/NamedStorage.sol";

/**
  Implements sending messages to L2 by adding them to a pipe and consuming messages from L2 by
  removing them from a different pipe. A deriving contract can handle the former pipe and add items
  to the latter pipe while interacting with L2.
*/
contract StarknetMessaging is IStarknetMessaging {
    /*
      Random slot storage elements and accessors.
    */
    string constant L1L2_MESSAGE_MAP_TAG = "STARKNET_1.0_MSGING_L1TOL2_MAPPPING_V2";
    string constant L2L1_MESSAGE_MAP_TAG = "STARKNET_1.0_MSGING_L2TOL1_MAPPPING";

    string constant L1L2_MESSAGE_NONCE_TAG = "STARKNET_1.0_MSGING_L1TOL2_NONCE";

    string constant L1L2_MESSAGE_CANCELLATION_MAP_TAG = (
        "STARKNET_1.0_MSGING_L1TOL2_CANCELLATION_MAPPPING"
    );

    string constant L1L2_MESSAGE_CANCELLATION_DELAY_TAG = (
        "STARKNET_1.0_MSGING_L1TOL2_CANCELLATION_DELAY"
    );

    function l1ToL2Messages(bytes32 msgHash) external view returns (uint256) {
        return l1ToL2Messages()[msgHash];
    }

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256) {
        return l2ToL1Messages()[msgHash];
    }

    function l1ToL2Messages() internal pure returns (mapping(bytes32 => uint256) storage) {
        return NamedStorage.bytes32ToUint256Mapping(L1L2_MESSAGE_MAP_TAG);
    }

    function l2ToL1Messages() internal pure returns (mapping(bytes32 => uint256) storage) {
        return NamedStorage.bytes32ToUint256Mapping(L2L1_MESSAGE_MAP_TAG);
    }

    function l1ToL2MessageNonce() public view returns (uint256) {
        return NamedStorage.getUintValue(L1L2_MESSAGE_NONCE_TAG);
    }

    function messageCancellationDelay() public view returns (uint256) {
        return NamedStorage.getUintValue(L1L2_MESSAGE_CANCELLATION_DELAY_TAG);
    }

    function messageCancellationDelay(uint256 delayInSeconds) internal {
        NamedStorage.setUintValue(L1L2_MESSAGE_CANCELLATION_DELAY_TAG, delayInSeconds);
    }

    /**
      Returns the timestamp at the time cancelL1ToL2Message was called with a message
      matching 'msgHash'.

      The function returns 0 if cancelL1ToL2Message was never called.
    */
    function l1ToL2MessageCancellations(bytes32 msgHash) external view returns (uint256) {
        return l1ToL2MessageCancellations()[msgHash];
    }

    function l1ToL2MessageCancellations()
        internal
        pure
        returns (mapping(bytes32 => uint256) storage)
    {
        return NamedStorage.bytes32ToUint256Mapping(L1L2_MESSAGE_CANCELLATION_MAP_TAG);
    }

    /**
      Returns the hash of an L1 -> L2 message from msg.sender.
    */
    function getL1ToL2MsgHash(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint256(msg.sender),
                    toAddress,
                    nonce,
                    selector,
                    payload.length,
                    payload
                )
            );
    }

    /**
      Sends a message to an L2 contract.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external override returns (bytes32, uint256) {
        uint256 nonce = l1ToL2MessageNonce();
        NamedStorage.setUintValue(L1L2_MESSAGE_NONCE_TAG, nonce + 1);
        emit LogMessageToL2(msg.sender, toAddress, selector, payload, nonce);
        bytes32 msgHash = getL1ToL2MsgHash(toAddress, selector, payload, nonce);
        l1ToL2Messages()[msgHash] += 1;
        return (msgHash, nonce);
    }

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        override
        returns (bytes32)
    {
        bytes32 msgHash = keccak256(
            abi.encodePacked(fromAddress, uint256(msg.sender), payload.length, payload)
        );

        require(l2ToL1Messages()[msgHash] > 0, "INVALID_MESSAGE_TO_CONSUME");
        emit ConsumedMessageToL1(fromAddress, msg.sender, payload);
        l2ToL1Messages()[msgHash] -= 1;
        return msgHash;
    }

    function startL1ToL2MessageCancellation(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external override returns (bytes32) {
        emit MessageToL2CancellationStarted(msg.sender, toAddress, selector, payload, nonce);
        bytes32 msgHash = getL1ToL2MsgHash(toAddress, selector, payload, nonce);
        uint256 msgCount = l1ToL2Messages()[msgHash];
        require(msgCount > 0, "NO_MESSAGE_TO_CANCEL");
        l1ToL2MessageCancellations()[msgHash] = block.timestamp;
        return msgHash;
    }

    function cancelL1ToL2Message(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external override returns (bytes32) {
        emit MessageToL2Canceled(msg.sender, toAddress, selector, payload, nonce);
        bytes32 msgHash = getL1ToL2MsgHash(toAddress, selector, payload, nonce);
        uint256 msgCount = l1ToL2Messages()[msgHash];
        require(msgCount > 0, "NO_MESSAGE_TO_CANCEL");

        uint256 requestTime = l1ToL2MessageCancellations()[msgHash];
        require(requestTime != 0, "MESSAGE_CANCELLATION_NOT_REQUESTED");

        uint256 cancelAllowedTime = requestTime + messageCancellationDelay();
        require(cancelAllowedTime >= requestTime, "CANCEL_ALLOWED_TIME_OVERFLOW");
        require(block.timestamp >= cancelAllowedTime, "MESSAGE_CANCELLATION_NOT_ALLOWED_YET");

        l1ToL2Messages()[msgHash] = msgCount - 1;
        return msgHash;
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "./IStarknetMessagingEvents.sol";

interface IStarknetMessaging is IStarknetMessagingEvents {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32, uint256);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);

    /**
      Starts the cancellation of an L1 to L2 message.
      A message can be canceled messageCancellationDelay() seconds after this function is called.

      Note: This function may only be called for a message that is currently pending and the caller
      must be the sender of the that message.
    */
    function startL1ToL2MessageCancellation(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external returns (bytes32);

    /**
      Cancels an L1 to L2 message, this function should be called messageCancellationDelay() seconds
      after the call to startL1ToL2MessageCancellation().
    */
    function cancelL1ToL2Message(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/*
  Library to provide basic storage, in storage location out of the low linear address space.

  New types of storage variables should be added here upon need.
*/
library NamedStorage {
    function bytes32ToUint256Mapping(string memory tag_)
        internal
        pure
        returns (mapping(bytes32 => uint256) storage randomVariable)
    {
        bytes32 location = keccak256(abi.encodePacked(tag_));
        assembly {
            randomVariable_slot := location
        }
    }

    function bytes32ToAddressMapping(string memory tag_)
        internal
        pure
        returns (mapping(bytes32 => address) storage randomVariable)
    {
        bytes32 location = keccak256(abi.encodePacked(tag_));
        assembly {
            randomVariable_slot := location
        }
    }

    function uintToAddressMapping(string memory tag_)
        internal
        pure
        returns (mapping(uint256 => address) storage randomVariable)
    {
        bytes32 location = keccak256(abi.encodePacked(tag_));
        assembly {
            randomVariable_slot := location
        }
    }

    function addressToBoolMapping(string memory tag_)
        internal
        pure
        returns (mapping(address => bool) storage randomVariable)
    {
        bytes32 location = keccak256(abi.encodePacked(tag_));
        assembly {
            randomVariable_slot := location
        }
    }

    function getUintValue(string memory tag_) internal view returns (uint256 retVal) {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            retVal := sload(slot)
        }
    }

    function setUintValue(string memory tag_, uint256 value) internal {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            sstore(slot, value)
        }
    }

    function setUintValueOnce(string memory tag_, uint256 value) internal {
        require(getUintValue(tag_) == 0, "ALREADY_SET");
        setUintValue(tag_, value);
    }

    function getAddressValue(string memory tag_) internal view returns (address retVal) {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            retVal := sload(slot)
        }
    }

    function setAddressValue(string memory tag_, address value) internal {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            sstore(slot, value)
        }
    }

    function setAddressValueOnce(string memory tag_, address value) internal {
        require(getAddressValue(tag_) == address(0x0), "ALREADY_SET");
        setAddressValue(tag_, value);
    }

    function getBoolValue(string memory tag_) internal view returns (bool retVal) {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            retVal := sload(slot)
        }
    }

    function setBoolValue(string memory tag_, bool value) internal {
        bytes32 slot = keccak256(abi.encodePacked(tag_));
        assembly {
            sstore(slot, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

interface IStarknetMessagingEvents {
    // This event needs to be compatible with the one defined in Output.sol.
    event LogMessageToL1(uint256 indexed fromAddress, address indexed toAddress, uint256[] payload);

    // An event that is raised when a message is sent from L1 to L2.
    event LogMessageToL2(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L2 to L1 is consumed.
    event ConsumedMessageToL1(
        uint256 indexed fromAddress,
        address indexed toAddress,
        uint256[] payload
    );

    // An event that is raised when a message from L1 to L2 is consumed.
    event ConsumedMessageToL2(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L1 to L2 Cancellation is started.
    event MessageToL2CancellationStarted(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L1 to L2 is canceled.
    event MessageToL2Canceled(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );
}