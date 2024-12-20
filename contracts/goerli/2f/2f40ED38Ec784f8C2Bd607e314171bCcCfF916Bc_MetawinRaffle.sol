// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MetawinRaffle {
    using SafeMath for uint256;

    enum RaffleStatus {
        ONGOING,
        PENDING_COMPLETION,
        COMPLETE
    }

    //NFT raffle struct
    struct NftRaffle {
        address creator;
        address nftContractAddress;
        uint256 nftId;
        uint256 ticketPrice;
        uint256 totalPrice;
        uint256 maxEntries;
        uint256 period;
        address winner;
        uint256 createdAt;
        RaffleStatus status;
        address[] tickets;
    }

    //Eth Raffle struct
    struct EthRaffle {
        address creator;
        uint256 rewardEth;
        uint256 ticketPrice;
        uint256 totalPrice;
        uint256 maxEntries;
        uint256 period;
        uint256 numWinner;
        uint256 createdAt;
        RaffleStatus status;
        address[] winners;
        address[] tickets;
    }

    //Contract owner address
    address public owner;

    uint16 public numNftRaffles;
    uint16 public numEthRaffles;

    //NFT Raffles
    NftRaffle[] public nftRaffles;
    //Eth Raffles
    EthRaffle[] public ethRaffles;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    //Create a new NFT raffle
    //nftContract.approve should be called before this function
    function createNftRaffle(
        IERC721 _nftContract,
        uint256 _nftId,
        uint256 _ticketPrice,
        uint256 _numTickets,
        uint256 _rafflePeriod
    ) onlyOwner public returns (uint256) {
        //transfer the NFT from the raffle creator to this contract
        _nftContract.transferFrom(
            msg.sender,
            address(this),
            _nftId
        );

         //init tickets
        address[] memory _tickets;
        //create raffle
        NftRaffle memory _raffle = NftRaffle(
            msg.sender,
            address(_nftContract),
            _nftId,
            _ticketPrice,
            0,
            _numTickets,
            _rafflePeriod,
            address(0),
            block.timestamp,
            RaffleStatus.ONGOING,
            _tickets
        );

        //store raffel in state
        nftRaffles.push(_raffle);

        //increase nft raffle number
        numNftRaffles++;

        //emit event
        emit NftRaffleCreated(nftRaffles.length - 1, address(_nftContract), _nftId, _ticketPrice, _numTickets, _rafflePeriod);

        return nftRaffles.length;
    }

    //Cancel NFT Raffle
    function cancelNftRaffle(
        uint256 _raffleId
    ) onlyOwner public {
        require(
            block.timestamp > nftRaffles[_raffleId].createdAt + nftRaffles[_raffleId].period,
            "Raffle is not ended yet"
        );

        require(
            nftRaffles[_raffleId].totalPrice == 0, "The winner was chosen" 
        );

        //transfer the NFT from the contract to the raffle creator
        IERC721(nftRaffles[_raffleId].nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            nftRaffles[_raffleId].nftId
        );

        nftRaffles[_raffleId].status = RaffleStatus.COMPLETE;

        emit NftRaffleCanceled(_raffleId);
    }

    //Create a new Eth Raffle
    function createEthRaffle(
        uint256 _rewardEth,
        uint256 _ticketPrice,
        uint256 _numTickets,
        uint256 _numWinner,
        uint256 _rafflePeriod
    ) onlyOwner public payable returns (uint256) {
        require(msg.value == _rewardEth, "Raffle reward is not set exactly");

        address[] memory _tickets;
        address[] memory _winners;

        EthRaffle memory _raffle = EthRaffle(
            msg.sender,
            _rewardEth,
            _ticketPrice,
            0,
            _numTickets,
            _rafflePeriod,
            _numWinner,
            block.timestamp,
            RaffleStatus.ONGOING,
            _winners,
            _tickets
        );

        ethRaffles.push(_raffle);

        //increase eth raffle number
        numEthRaffles++;

        emit EthRaffleCreated(ethRaffles.length - 1, _rewardEth, _ticketPrice, _numTickets, _numWinner, _rafflePeriod);

        return ethRaffles.length;
    }

    //Cancel Eth raffle
    function cancelEthRaffle(uint256 _raffleId) onlyOwner public {
        require(
            block.timestamp > ethRaffles[_raffleId].createdAt + ethRaffles[_raffleId].period,
            "Raffle is not ended yet" 
        );

        require(
            ethRaffles[_raffleId].totalPrice == 0, "The winner was chosen" 
        );

        (bool sent, ) = ethRaffles[_raffleId].creator.call{value: ethRaffles[_raffleId].rewardEth}("");
            require(sent, "Failed to send Ether");

        ethRaffles[_raffleId].status = RaffleStatus.COMPLETE;

        emit EthRaffleCanceled(_raffleId);
    }

    //enter a user in the draw for a given NFT raffle
    function enterNftRaffle(uint256 _raffleId, uint256 _tickets) public payable {
        require(
            uint256(nftRaffles[_raffleId].status) == uint256(RaffleStatus.ONGOING),
            "NFT Raffle no longer active"
        );

        require(block.timestamp < (nftRaffles[_raffleId].createdAt + nftRaffles[_raffleId].period), "Raffle period is over");

        require(
            _tickets.add(nftRaffles[_raffleId].tickets.length) <= nftRaffles[_raffleId].maxEntries,
            "Not enough tickets available"
        );

        require(_tickets > 0, "Not enough _tickets purchased");

        if(_tickets == 1) {
            require(msg.value == nftRaffles[_raffleId].ticketPrice, "Ticket price not paid");
        } else if(_tickets == 15) {
            require(msg.value == nftRaffles[_raffleId].ticketPrice.mul(5), "Ticket price not paid");
        } else if(_tickets == 35) {
            require(msg.value == nftRaffles[_raffleId].ticketPrice.mul(10), "Ticket price not paid");
        } else if(_tickets == 75) {
            require(msg.value == nftRaffles[_raffleId].ticketPrice.mul(20), "Ticket price not paid");
        } else if(_tickets == 155) {
            require(msg.value == nftRaffles[_raffleId].ticketPrice.mul(40), "Ticket price not paid");
        } else {
            require(msg.value == _tickets.mul(nftRaffles[_raffleId].ticketPrice), "Ticket price not paid");
        }

        //add _tickets
        for (uint256 i = 0; i < _tickets; i++) {
            nftRaffles[_raffleId].tickets.push(payable(msg.sender));
        }

        nftRaffles[_raffleId].totalPrice += msg.value;
        
        emit NftTicketPurchased(_raffleId, msg.sender, _tickets, block.timestamp);
    }

    //enter a user in the draw for a given ETH raffle
    function enterEthRaffle(uint256 _raffleId, uint256 _tickets) public payable {
        require(
            uint256(ethRaffles[_raffleId].status) == uint256(RaffleStatus.ONGOING),
            "NFT Raffle no longer active"
        );

        require(
            _tickets.add(ethRaffles[_raffleId].tickets.length) <= ethRaffles[_raffleId].maxEntries,
            "Not enough tickets available"
        );
        
        require(_tickets > 0, "Not enough _tickets purchased");

        for (uint256 i = 0; i < _tickets; i++) {
            ethRaffles[_raffleId].tickets.push(payable(msg.sender));
        }

        if(ethRaffles[_raffleId].maxEntries == 2) {
            require(msg.value == ethRaffles[_raffleId].ticketPrice, "Ticket price not paid");
            if (ethRaffles[_raffleId].tickets.length == 2) {
                chooseEthWinner(_raffleId);
            }
        } else {
            require(block.timestamp < (ethRaffles[_raffleId].createdAt + ethRaffles[_raffleId].period), "Raffle period is over");

            if(_tickets == 1) {
                require(msg.value == ethRaffles[_raffleId].ticketPrice, "Ticket price not paid");
            } else if(_tickets == 15) {
                require(msg.value == ethRaffles[_raffleId].ticketPrice.mul(5), "Ticket price not paid");
            } else if(_tickets == 35) {
                require(msg.value == ethRaffles[_raffleId].ticketPrice.mul(10), "Ticket price not paid");
            } else if(_tickets == 75) {
                require(msg.value == ethRaffles[_raffleId].ticketPrice.mul(20), "Ticket price not paid");
            } else if(_tickets == 155) {
                require(msg.value == ethRaffles[_raffleId].ticketPrice.mul(40), "Ticket price not paid");
            } else {
                require(msg.value == _tickets.mul(nftRaffles[_raffleId].ticketPrice), "Ticket price not paid");
            }
        }

        ethRaffles[_raffleId].totalPrice += msg.value;
        
        emit EthTicketPurchased(_raffleId, msg.sender, _tickets, block.timestamp);
    }

    function chooseNftWinner(uint256 _raffleId) public returns (uint256) {
        NftRaffle storage raffle = nftRaffles[_raffleId];
        require(block.timestamp >= (raffle.createdAt + raffle.period), "Raffle is not ended yet");
        require(raffle.winner == address(0), "Winner is already chosen");
        require(raffle.tickets.length >= 1, "Insufficient participants");

        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender))) % raffle.tickets.length;

        //Input winnerIndex to raffle struct
        raffle.winner = raffle.tickets[winnerIndex];

        //award winner
        IERC721(raffle.nftContractAddress).transferFrom(
            address(this),
            raffle.tickets[winnerIndex],
            raffle.nftId
        );

        //pay raffle creator
        (bool sent, ) = raffle.creator.call{value: (raffle.totalPrice)}("");
        require(sent, "Failed to send Ether");

        raffle.status = RaffleStatus.COMPLETE;

        emit NftRaffleCompleted(
            _raffleId,
            raffle.winner
        );

        return winnerIndex;
    }

    function chooseEthWinner(uint256 _raffleId) public returns (uint256) {
        EthRaffle storage raffle = ethRaffles[_raffleId];

        if (ethRaffles[_raffleId].maxEntries != 2) {
            require(block.timestamp >= (raffle.createdAt + raffle.period), "Raffle is not ended yet");
        }
        require(raffle.winners.length == 0, "Winner is already chosen");
        require(raffle.tickets.length >= raffle.numWinner, "Insufficient participants");

        uint256 winnerIdx;

        for (uint8 i = 0; i < raffle.numWinner; i++) {
            winnerIdx = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender, i))) % raffle.tickets.length;
            raffle.winners.push(raffle.tickets[winnerIdx]);

            (bool sent, ) = raffle.tickets[winnerIdx].call{value: (raffle.rewardEth.div(raffle.numWinner))}("");
            require(sent, "Failed to send Ether");
        }


        if(raffle.totalPrice > raffle.rewardEth) {
            (bool rewardSent, ) = raffle.creator.call{value: (raffle.totalPrice - raffle.rewardEth)}("");
            require(rewardSent, "Failed to send Ether");
        }

        raffle.status = RaffleStatus.COMPLETE;

        emit EthRaffleCompleted(
            _raffleId,
            raffle.winners
        );

        return winnerIdx;
    }

    function getAllNftRaffles() external view returns (NftRaffle[] memory) {
        return nftRaffles;
    }

    function getAllEthRaffles() external view returns (EthRaffle[] memory) {
        return ethRaffles;
    }

    event NftRaffleCreated(
        uint256 id,
        address indexed nftAddress,
        uint256 indexed nftId,
        uint256 ticketPrice,
        uint256 maxEntries,
        uint256 period
    );
    event NftRaffleCanceled(uint256 id);
    event NftTicketPurchased(uint256 raffleId, address indexed buyer, uint256 numTickets, uint256 timestamp);
    event NftRaffleCompleted(uint256 id, address winner);

    event EthRaffleCreated(
        uint256 id,
        uint256 reward,
        uint256 ticketPrice,
        uint256 maxEntries,
        uint256 numWinner,
        uint256 period
    );
    event EthRaffleCanceled(uint256 id);
    event EthTicketPurchased(uint256 raffleId, address indexed buyer, uint256 numTickets, uint256 timestamp);
    event EthRaffleCompleted(uint256 id, address[] winners);
}