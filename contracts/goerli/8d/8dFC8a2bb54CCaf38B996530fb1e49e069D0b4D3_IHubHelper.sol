// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "./IHubAdminAccess.sol";

/**
 * @notice Access Controls
 * @author Attr: BlockRocket.tech
 */
contract IHubAccessControls is IHubAdminAccess {
    /// @notice Role definitions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SMART_CONTRACT_ROLE = keccak256("SMART_CONTRACT_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice The deployer is automatically given the admin role which will allow them to then grant roles to other addresses
     */
    constructor() public {}

    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasMinterRole(address _address) public view returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the smart contract role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasSmartContractRole(address _address) public view returns (bool) {
        return hasRole(SMART_CONTRACT_ROLE, _address);
    }

    /**
     * @notice Used to check whether an address has the operator role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasOperatorRole(address _address) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the minter role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addMinterRole(address _address) external {
        grantRole(MINTER_ROLE, _address);
    }

    /**
     * @notice Removes the minter role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeMinterRole(address _address) external {
        revokeRole(MINTER_ROLE, _address);
    }

    /**
     * @notice Grants the smart contract role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addSmartContractRole(address _address) external {
        grantRole(SMART_CONTRACT_ROLE, _address);
    }

    /**
     * @notice Removes the smart contract role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeSmartContractRole(address _address) external {
        revokeRole(SMART_CONTRACT_ROLE, _address);
    }

    /**
     * @notice Grants the operator role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addOperatorRole(address _address) external {
        grantRole(OPERATOR_ROLE, _address);
    }

    /**
     * @notice Removes the operator role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeOperatorRole(address _address) external {
        revokeRole(OPERATOR_ROLE, _address);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "../Utils/CloneFactory.sol";
import "./IHubAccessControls.sol";

contract IHubAccessFactory is CloneFactory {
    /// @notice Responsible for access rights to the contract.
    IHubAccessControls public accessControls;

    /// @notice Address of the template for access controls.
    address public accessControlTemplate;

    /// @notice Whether initialized or not.
    bool private initialised;

    /// @notice Minimum fee number.
    uint256 public minimumFee;

    /// @notice Devs address.
    address public devaddr;

    /// @notice AccessControls created using the factory.
    address[] public children;

    /// @notice Tracks if a contract is made by the factory.
    mapping(address => bool) public isChild;

    /// @notice Event emitted when first initializing IHub AccessControl Factory.
    event IHubInitAccessFactory(address sender);

    /// @notice Event emitted when a access is created using template id.
    event AccessControlCreated(address indexed owner, address accessControls, address admin, address accessTemplate);

    /// @notice Event emitted when a access template is added.
    event AccessControlTemplateAdded(address oldAccessControl, address newAccessControl);

    /// @notice Event emitted when a access template is removed.
    event AccessControlTemplateRemoved(address access, uint256 templateId);

    /// @notice Event emitted when a access template is removed.
    event MinimumFeeUpdated(uint oldFee, uint newFee);

    /// @notice Event emitted when a access template is removed.
    event DevAddressUpdated(address oldDev, address newDev);

    constructor() public {}

    /**
     * @notice Single gateway to initialize the IHub AccessControl Factory with proper address and set minimum fee.
     * @dev Can only be initialized once.
     * @param _minimumFee Minimum fee number.
     * @param _accessControls Address of the access controls.
     */
    function initIHubAccessFactory(uint256 _minimumFee, address _accessControls) external {
        require(!initialised);
        initialised = true;
        minimumFee = _minimumFee;
        accessControls = IHubAccessControls(_accessControls);
        emit IHubInitAccessFactory(msg.sender);
    }

    /// @notice Get the total number of children in the factory.
    function numberOfChildren() external view returns (uint256) {
        return children.length;
    }

    /**
     * @notice Creates access corresponding to template id.
     * @dev Initializes access with parameters passed.
     * @param _admin Address of admin access.
     */
    function deployAccessControl(address _admin) external payable returns (address access) {
        require(msg.value >= minimumFee, "Minimum fee needs to be paid.");
        require(accessControlTemplate != address(0), "Access control template does not exist");
        access = createClone(accessControlTemplate);
        isChild[address(access)] = true;
        children.push(address(access));
        IHubAccessControls(access).initAccessControls(_admin);
        emit AccessControlCreated(msg.sender, address(access), _admin, accessControlTemplate);
        if (msg.value > 0) {
            payable(devaddr).transfer(msg.value);
        }
    }

    /**
     * @notice Function to add new contract templates for the factory.
     * @dev Should have operator access.
     * @param _template Template to create new access controls.
     */
    function updateAccessTemplate(address _template) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "IHubAccessFactory.updateAccessTemplate: Sender must be admin"
        );
        require(_template != address(0));
        emit AccessControlTemplateAdded(accessControlTemplate, _template);
        accessControlTemplate = _template;
    }

    /**
     * @notice Sets dev address.
     * @dev Should have operator access.
     * @param _devaddr Devs address.
     */
    function setDev(address _devaddr) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubAccessFactory.setMinimumFee: Sender must be admin");
        emit DevAddressUpdated(devaddr, _devaddr);
        devaddr = _devaddr;
    }

    /**
     * @notice Sets minimum fee.
     * @dev Should have operator access.
     * @param _minimumFee Minimum fee number.
     */
    function setMinimumFee(uint256 _minimumFee) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubAccessFactory.setMinimumFee: Sender must be admin");
        emit MinimumFeeUpdated(minimumFee, _minimumFee);
        minimumFee = _minimumFee;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "../OpenZeppelin/access/AccessControl.sol";

contract IHubAdminAccess is AccessControl {
    /// @dev Whether access is initialised.
    bool private initAccess;

    /// @notice The deployer is automatically given the admin role which will allow them to then grant roles to other addresses.
    constructor() public {}

    /**
     * @notice Initializes access controls.
     * @param _admin Admins address.
     */
    function initAccessControls(address _admin) public {
        require(!initAccess, "Already initialised");
        require(_admin != address(0), "Incorrect input");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        initAccess = true;
    }

    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the admin role.
     * @param _address EOA or contract being checked.
     * @return bool True if the account has the role or false if it does not.
     */
    function hasAdminRole(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the admin role to an address.
     * @dev The sender must have the admin role.
     * @param _address EOA or contract receiving the new role.
     */
    function addAdminRole(address _address) external {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /**
     * @notice Removes the admin role from an address.
     * @dev The sender must have the admin role.
     * @param _address EOA or contract affected.
     */
    function removeAdminRole(address _address) external {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
    }
}

pragma solidity 0.6.12;

import "../OpenZeppelin/math/SafeMath.sol";
import "../Utils/Owned.sol";
import "../Utils/CloneFactory.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPointList.sol";
import "../Utils/SafeTransfer.sol";
import "./IHubAccessControls.sol";

// List Factory
//
// A factory for deploying all sorts of list based contracts
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

contract ListFactory is CloneFactory, SafeTransfer {
    using SafeMath for uint;

    /// @notice Responsible for access rights to the contract.
    IHubAccessControls public accessControls;

    /// @notice Whether market has been initialized or not.
    bool private initialised;

    /// @notice Address of the point list template.
    address public pointListTemplate;

    /// @notice New point list address.
    address public newAddress;

    /// @notice Minimum fee number.
    uint256 public minimumFee;

    /// @notice Tracks if list is made by the factory.
    mapping(address => bool) public isChild;

    /// @notice An array of list addresses.
    address[] public lists;

    /// @notice Any IHub dividends collected are sent here.
    address payable public iHubDiv;

    /// @notice Event emitted when point list is deployed.
    event PointListDeployed(address indexed operator, address indexed addr, address pointList, address owner);

    /// @notice Event emitted when factory is deprecated.
    event FactoryDeprecated(address newAddress);

    /// @notice Event emitted when minimum fee is updated.
    event MinimumFeeUpdated(uint oldFee, uint newFee);

    /// @notice Event emitted when point list factory is initialised.
    event IHubInitListFactory();

    /**
     * @notice Initializes point list factory variables.
     * @param _accessControls Access control contract address.
     * @param _pointListTemplate Point list template address.
     * @param _minimumFee Minimum fee number.
     */
    function initListFactory(address _accessControls, address _pointListTemplate, uint256 _minimumFee) external {
        require(!initialised);
        require(_accessControls != address(0), "Incorrect access controls");
        require(_pointListTemplate != address(0), "Incorrect list template");
        accessControls = IHubAccessControls(_accessControls);
        pointListTemplate = _pointListTemplate;
        minimumFee = _minimumFee;
        initialised = true;
        emit IHubInitListFactory();
    }

    /**
     * @notice Gets the number of point lists created by factory.
     * @return uint Number of point lists.
     */
    function numberOfChildren() external view returns (uint) {
        return lists.length;
    }

    /**
     * @notice Deprecates factory.
     * @param _newAddress Blank address.
     */
    function deprecateFactory(address _newAddress) external {
        require(accessControls.hasAdminRole(msg.sender), "ListFactory: Sender must be admin");
        require(newAddress == address(0));
        emit FactoryDeprecated(_newAddress);
        newAddress = _newAddress;
    }

    /**
     * @notice Sets minimum fee.
     * @param _minimumFee Minimum fee number.
     */
    function setMinimumFee(uint256 _minimumFee) external {
        require(accessControls.hasAdminRole(msg.sender), "ListFactory: Sender must be admin");
        emit MinimumFeeUpdated(minimumFee, _minimumFee);
        minimumFee = _minimumFee;
    }

    /**
     * @notice Sets dividend address.
     * @param _divaddr Dividend address.
     */
    function setDividends(address payable _divaddr) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubTokenFactory: Sender must be Admin");
        iHubDiv = _divaddr;
    }

    /**
     * @notice Deploys new point list.
     * @param _listOwner List owner address.
     * @param _accounts An array of account addresses.
     * @param _amounts An array of corresponding point amounts.
     * @return pointList Point list address.
     */
    function deployPointList(
        address _listOwner,
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external payable returns (address pointList) {
        require(msg.value >= minimumFee);
        pointList = createClone(pointListTemplate);
        if (_accounts.length > 0) {
            IPointList(pointList).initPointList(address(this));
            IPointList(pointList).setPoints(_accounts, _amounts);
            IHubAccessControls(pointList).addAdminRole(_listOwner);
            IHubAccessControls(pointList).removeAdminRole(address(this));
        } else {
            IPointList(pointList).initPointList(_listOwner);
        }
        isChild[address(pointList)] = true;
        lists.push(address(pointList));
        emit PointListDeployed(msg.sender, address(pointList), pointListTemplate, _listOwner);
        if (msg.value > 0) {
            iHubDiv.transfer(msg.value);
        }
    }

    /**
     * @notice Funtion for transfering any ERC20 token.
     * @param _tokenAddress Address to send from.
     * @param _tokens Number of tokens.
     * @return success True.
     */
    function transferAnyERC20Token(address _tokenAddress, uint256 _tokens) external returns (bool success) {
        require(accessControls.hasAdminRole(msg.sender), "ListFactory: Sender must be operator");
        _safeTransfer(_tokenAddress, iHubDiv, _tokens);
        return true;
    }

    receive() external payable {
        revert();
    }
}

pragma solidity 0.6.12;

/**
 * @dev Set an uint max amount for all addresses
 * @dev uint256 public maxPoints;
 * @dev This amount can be changed by an operator
 */

import "../OpenZeppelin/math/SafeMath.sol";
import "./IHubAccessControls.sol";
import "../interfaces/IPointList.sol";

contract MaxList is IPointList, IHubAccessControls {
    using SafeMath for uint;

    /// @notice Maximum amount of points for any address.
    uint256 public maxPoints;

    /// @notice Event emitted when points are updated.
    event PointsUpdated(uint256 oldPoints, uint256 newPoints);

    constructor() public {}

    /**
     * @notice Initializes point list with admin address.
     * @param _admin Admins address.
     */
    function initPointList(address _admin) public override {
        initAccessControls(_admin);
    }

    /**
     * @notice Returns the amount of points of any address.
     * @param _account Account address.
     * @return uint256 maxPoints.
     */
    function points(address _account) public view returns (uint256) {
        return maxPoints;
    }

    /**
     * @notice Returns the maximum amount of points.
     * @param _account Account address.
     * @return bool True or False.
     */
    function isInList(address _account) public view override returns (bool) {
        return true;
    }

    /**
     * @notice Checks if maxPoints is bigger or equal to the number given.
     * @param _account Account address.
     * @param _amount Desired amount of points.
     * @return bool True or False.
     */
    function hasPoints(address _account, uint256 _amount) public view override returns (bool) {
        return maxPoints >= _amount;
    }

    /**
     * @notice Sets maxPoints.
     * @param _accounts An array of accounts. Kept for compatibility with IPointList
     * @param _amounts An array of corresponding amounts. Kept for compatibility with IPointList
     */
    function setPoints(address[] memory _accounts, uint256[] memory _amounts) external override {
        require(hasAdminRole(msg.sender) || hasOperatorRole(msg.sender), "MaxList.setPoints: Sender must be operator");
        require(_amounts.length == 1);
        maxPoints = _amounts[0];
        emit PointsUpdated(maxPoints, _amounts[0]);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

/**
 * @dev GP Make a purplelist but instead of adding and removing, set an uint amount for a address
 * @dev mapping(address => uint256) public points;
 * @dev This amount can be added or removed by an operator
 * @dev There is a total points preserved
 * @dev Can update an array of points
 */

import "../OpenZeppelin/math/SafeMath.sol";
import "./IHubAccessControls.sol";
import "../interfaces/IPointList.sol";


contract PointList is IPointList, IHubAccessControls {
    using SafeMath for uint;

    /// @notice Maping an address to a number fo points.
    mapping(address => uint256) public points;

    /// @notice Number of total points.
    uint256 public totalPoints;

    /// @notice Event emitted when points are updated.
    event PointsUpdated(address indexed account, uint256 oldPoints, uint256 newPoints);


    constructor() public {
    }

    /**
     * @notice Initializes point list with admin address.
     * @param _admin Admins address.
     */
    function initPointList(address _admin) public override {
        initAccessControls(_admin);
    }

    /**
     * @notice Checks if account address is in the list (has any points).
     * @param _account Account address.
     * @return bool True or False.
     */
    function isInList(address _account) public view override returns (bool) {
        return points[_account] > 0 ;
    }

    /**
     * @notice Checks if account has more or equal points as the number given.
     * @param _account Account address.
     * @param _amount Desired amount of points.
     * @return bool True or False.
     */
    function hasPoints(address _account, uint256 _amount) public view override returns (bool) {
        return points[_account] >= _amount ;
    }

    /**
     * @notice Sets points to accounts in one batch.
     * @param _accounts An array of accounts.
     * @param _amounts An array of corresponding amounts.
     */
    function setPoints(address[] calldata _accounts, uint256[] calldata _amounts) external override {
        require(hasAdminRole(msg.sender) || hasOperatorRole(msg.sender), "PointList.setPoints: Sender must be operator");
        require(_accounts.length != 0, "PointList.setPoints: empty array");
        require(_accounts.length == _amounts.length, "PointList.setPoints: incorrect array length");
        uint totalPointsCache = totalPoints;
        for (uint i; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            uint256 previousPoints = points[account];

            if (amount != previousPoints) {
                points[account] = amount;
                totalPointsCache = totalPointsCache.sub(previousPoints).add(amount);
                emit PointsUpdated(account, previousPoints, amount);
            }
        }
        totalPoints = totalPointsCache;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "../interfaces/IPointList.sol";
import "../interfaces/IERC20.sol";

/**
 * @notice TokenPointList - IHub Point List that references a given `token` balance to return approvals.
 */
contract TokenList {
    /// @notice Token contract for point list reference - can be ERC20, ERC721 or other tokens with `balanceOf()` check.
    IERC20 public token;

    /// @notice Whether initialised or not.
    bool private initialised;

    constructor() public {}

    /**
     * @notice Initializes token point list with reference token.
     * @param _token Token address.
     */
    function initPointList(IERC20 _token) public {
        require(!initialised, "Already initialised");
        token = _token;
        initialised = true;
    }

    /**
     * @notice Checks if account address is in the list (has any tokens).
     * @param _account Account address.
     * @return bool True or False.
     */
    function isInList(address _account) public view returns (bool) {
        return token.balanceOf(_account) > 0;
    }

    /**
     * @notice Checks if account has more or equal points (tokens) as the number given.
     * @param _account Account address.
     * @param _amount Desired amount of points.
     * @return bool True or False.
     */
    function hasPoints(address _account, uint256 _amount) public view returns (bool) {
        return token.balanceOf(_account) >= _amount;
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Batch Auction
//
// An auction where contributions are swaped for a batch of tokens pro-rata
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "../OpenZeppelin/utils/ReentrancyGuard.sol";
import "../Access/IHubAccessControls.sol";
import "../Utils/SafeTransfer.sol";
import "../Utils/BoringBatchable.sol";
import "../Utils/BoringMath.sol";
import "../Utils/BoringERC20.sol";
import "../Utils/Documents.sol";
import "../interfaces/IPointList.sol";
import "../interfaces/IIHubMarket.sol";

/// @notice Attribution to delta.financial
/// @notice Attribution to dutchswap.com

contract BatchAuction is IIHubMarket, IHubAccessControls, BoringBatchable, SafeTransfer, Documents, ReentrancyGuard {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using BoringERC20 for IERC20;

    /// @notice IHubMarket template id for the factory contract.
    /// @dev For different marketplace types, this must be incremented.
    uint256 public constant override marketTemplate = 3;

    /// @dev The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Main market variables.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    /// @notice Market dynamic variables.
    struct MarketStatus {
        uint128 commitmentsTotal;
        uint128 minimumCommitmentAmount;
        bool finalized;
        bool usePointList;
    }

    MarketStatus public marketStatus;

    /// @notice The token being sold.
    address public auctionToken;
    /// @notice The currency the BatchAuction accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    // TangleswapPool->fee
    uint24 public fee;
    /// @notice Address that manages auction approvals.
    address public pointList;
    address payable public wallet; // Where the auction funds will get paid

    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /// @notice Event for all auction data. Emmited on deployment.
    event AuctionDeployed(
        address funder,
        address token,
        uint256 totalTokens,
        address paymentCurrency,
        address admin,
        address wallet
    );

    /// @notice Event for updating auction times.  Needs to be before auction starts.
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    /// @notice Event for updating auction prices. Needs to be before auction starts.
    event AuctionPriceUpdated(uint256 minimumCommitmentAmount);
    /// @notice Event for updating auction wallet. Needs to be before auction starts.
    event AuctionWalletUpdated(address wallet);
    /// @notice Event for updating the point list.
    event AuctionPointListUpdated(address pointList, bool enabled);

    /// @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);
    /// @notice Event for token withdrawals.
    event TokensWithdrawn(address token, address to, uint256 amount);

    /// @notice Event for finalization of the auction.
    event AuctionFinalized();
    /// @notice Event for cancellation of the auction.
    event AuctionCancelled();

    /**
     * @notice Initializes main contract variables and transfers funds for the auction.
     * @dev Init function.
     * @param _funder The address that funds the token for BatchAuction.
     * @param _token Address of the token being sold.
     * @param _totalTokens The total number of tokens to sell in auction.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     * @param _paymentCurrency The currency the BatchAuction accepts for payment. Can be ETH or token address.
     * @param _fee The fee amount of Tangleswap pool.
     * @param _minimumCommitmentAmount Minimum amount collected at which the auction will be successful.
     * @param _admin Address that can finalize auction.
     * @param _wallet Address where collected funds will be forwarded to.
     */
    function initAuction(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint24 _fee,
        uint256 _minimumCommitmentAmount,
        address _admin,
        address _pointList,
        address payable _wallet
    ) public {
        require(_endTime < 10000000000, "BatchAuction: enter an unix timestamp in seconds, not miliseconds");
        // solhint-disable-next-line not-rely-on-time
        require(_startTime >= block.timestamp, "BatchAuction: start time is before current time");
        require(_endTime > _startTime, "BatchAuction: end time must be older than start time");
        require(_totalTokens > 0, "BatchAuction: total tokens must be greater than zero");
        require(_admin != address(0), "BatchAuction: admin is the zero address");
        require(_wallet != address(0), "BatchAuction: wallet is the zero address");
        require(IERC20(_token).decimals() == 18, "BatchAuction: Token does not have 18 decimals");
        if (_paymentCurrency != ETH_ADDRESS) {
            require(IERC20(_paymentCurrency).decimals() > 0, "BatchAuction: Payment currency is not ERC20");
        }

        marketStatus.minimumCommitmentAmount = BoringMath.to128(_minimumCommitmentAmount);

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);
        marketInfo.totalTokens = BoringMath.to128(_totalTokens);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        // TangleswapPool->fee
        fee = _fee;
        wallet = _wallet;

        initAccessControls(_admin);

        _setList(_pointList);
        _safeTransferFrom(auctionToken, _funder, _totalTokens);

        emit AuctionDeployed(_funder, _token, _totalTokens, _paymentCurrency, _admin, _wallet);
        emit AuctionTimeUpdated(_startTime, _endTime);
        emit AuctionPriceUpdated(_minimumCommitmentAmount);
    }

    ///--------------------------------------------------------
    /// Commit to buying tokens!
    ///--------------------------------------------------------

    receive() external payable {
        revertBecauseUserDidNotProvideAgreement();
    }

    /**
     * @dev Attribution to the awesome delta.financial contracts
     */
    function marketParticipationAgreement() public pure returns (string memory) {
        return
            "I understand that I am interacting with a smart contract. I understand that tokens commited are subject to the token issuer and local laws where applicable. I have reviewed the code of this smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }

    /**
     * @dev Not using modifiers is a purposeful choice for code readability.
     */
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert("No agreement provided, please review the smart contract before interacting with it");
    }

    /**
     * @notice Commit ETH to buy tokens on auction.
     * @param _beneficiary Auction participant ETH address.
     */
    function commitEth(address payable _beneficiary, bool readAndAgreedToMarketParticipationAgreement) public payable {
        require(paymentCurrency == ETH_ADDRESS, "BatchAuction: payment currency is not ETH");

        require(msg.value > 0, "BatchAuction: Value must be higher than 0");
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        _addCommitment(_beneficiary, msg.value);

        /// @notice Revert if commitmentsTotal exceeds the balance
        require(
            marketStatus.commitmentsTotal <= address(this).balance,
            "BatchAuction: The committed ETH exceeds the balance"
        );
    }

    /**
     * @notice Buy Tokens by commiting approved ERC20 tokens to this contract address.
     * @param _amount Amount of tokens to commit.
     */
    function commitTokens(uint256 _amount, bool readAndAgreedToMarketParticipationAgreement) public {
        commitTokensFrom(msg.sender, _amount, readAndAgreedToMarketParticipationAgreement);
    }

    /**
     * @notice Checks if amount not 0 and makes the transfer and adds commitment.
     * @dev Users must approve contract prior to committing tokens to auction.
     * @param _from User ERC20 address.
     * @param _amount Amount of approved ERC20 tokens.
     */
    function commitTokensFrom(
        address _from,
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) public nonReentrant {
        require(paymentCurrency != ETH_ADDRESS, "BatchAuction: Payment currency is not a token");
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        require(_amount > 0, "BatchAuction: Value must be higher than 0");
        _safeTransferFrom(paymentCurrency, msg.sender, _amount);
        _addCommitment(_from, _amount);
    }

    /// @notice Commits to an amount during an auction
    /**
     * @notice Updates commitment for this address and total commitment of the auction.
     * @param _addr Auction participant address.
     * @param _commitment The amount to commit.
     */
    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= marketInfo.startTime && block.timestamp <= marketInfo.endTime,
            "outside auction hours"
        );

        uint256 newCommitment = commitments[_addr].add(_commitment);
        if (marketStatus.usePointList) {
            require(IPointList(pointList).hasPoints(_addr, newCommitment));
        }
        commitments[_addr] = newCommitment;
        marketStatus.commitmentsTotal = BoringMath.to128(uint256(marketStatus.commitmentsTotal).add(_commitment));
        emit AddedCommitment(_addr, _commitment);
    }

    /**
     * @notice Calculates amount of auction tokens for user to receive.
     * @param amount Amount of tokens to commit.
     * @return Auction token amount.
     */
    function _getTokenAmount(uint256 amount) internal view returns (uint256) {
        if (marketStatus.commitmentsTotal == 0) return 0;
        return amount.mul(1e18).div(tokenPrice());
    }

    /**
     * @notice Calculates the price of each token from all commitments.
     * @return Token price.
     */
    function tokenPrice() public view returns (uint256) {
        return uint256(marketStatus.commitmentsTotal).mul(1e18).div(uint256(marketInfo.totalTokens));
    }

    ///--------------------------------------------------------
    /// Finalize Auction
    ///--------------------------------------------------------

    /// @notice Auction finishes successfully above the reserve
    /// @dev Transfer contract funds to initialized wallet.
    function finalize() public nonReentrant {
        require(
            hasAdminRole(msg.sender) ||
                wallet == msg.sender ||
                hasSmartContractRole(msg.sender) ||
                finalizeTimeExpired(),
            "BatchAuction: Sender must be admin"
        );
        require(!marketStatus.finalized, "BatchAuction: Auction has already finalized");
        require(marketInfo.totalTokens > 0, "Not initialized");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > marketInfo.endTime, "BatchAuction: Auction has not finished yet");
        if (auctionSuccessful()) {
            /// @dev Successful auction
            /// @dev Transfer contributed tokens to wallet.
            _safeTokenPayment(paymentCurrency, wallet, uint256(marketStatus.commitmentsTotal));
        } else {
            /// @dev Failed auction
            /// @dev Return auction tokens back to wallet.
            _safeTokenPayment(auctionToken, wallet, marketInfo.totalTokens);
        }
        marketStatus.finalized = true;
        emit AuctionFinalized();
    }

    /**
     * @notice Cancel Auction
     * @dev Admin can cancel the auction before it starts
     */
    function cancelAuction() public nonReentrant {
        require(hasAdminRole(msg.sender));
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "BatchAuction: already finalized");
        require(uint256(status.commitmentsTotal) == 0, "BatchAuction: Funds already raised");

        _safeTokenPayment(auctionToken, wallet, uint256(marketInfo.totalTokens));

        status.finalized = true;
        emit AuctionCancelled();
    }

    /// @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
    function withdrawTokens() public {
        withdrawTokens(msg.sender);
    }

    /// @notice Withdraw your tokens once the Auction has ended.
    function withdrawTokens(address payable beneficiary) public nonReentrant {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "BatchAuction: not finalized");
            /// @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "BatchAuction: No tokens to claim");
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);

            _safeTokenPayment(auctionToken, beneficiary, tokensToClaim);
        } else {
            /// @dev Auction did not meet reserve price.
            /// @dev Return committed funds back to user.
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp > marketInfo.endTime, "BatchAuction: Auction has not finished yet");
            uint256 fundsCommitted = commitments[beneficiary];
            require(fundsCommitted > 0, "BatchAuction: No funds committed");
            commitments[beneficiary] = 0; // Stop multiple withdrawals and free some gas
            _safeTokenPayment(paymentCurrency, beneficiary, fundsCommitted);
        }
    }

    /**
     * @notice How many tokens the user is able to claim.
     * @param _user Auction participant address.
     * @return  claimerCommitment Tokens left to claim.
     */
    function tokensClaimable(address _user) public view returns (uint256 claimerCommitment) {
        if (commitments[_user] == 0) return 0;
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    /**
     * @notice Checks if raised more than minimum amount.
     * @return True if tokens sold greater than or equals to the minimum commitment amount.
     */
    function auctionSuccessful() public view returns (bool) {
        return
            uint256(marketStatus.commitmentsTotal) >= uint256(marketStatus.minimumCommitmentAmount) &&
            uint256(marketStatus.commitmentsTotal) > 0;
    }

    /**
     * @notice Checks if the auction has ended.
     * @return bool True if current time is greater than auction end time.
     */
    function auctionEnded() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > marketInfo.endTime;
    }

    /**
     * @notice Checks if the auction has been finalised.
     * @return bool True if auction has been finalised.
     */
    function finalized() public view returns (bool) {
        return marketStatus.finalized;
    }

    /// @notice Returns true if 7 days have passed since the end of the auction
    function finalizeTimeExpired() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return uint256(marketInfo.endTime) + 7 days < block.timestamp;
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(string calldata _name, string calldata _data) external {
        require(hasAdminRole(msg.sender));
        _setDocument(_name, _data);
    }

    function setDocuments(string[] calldata _name, string[] calldata _data) external {
        require(hasAdminRole(msg.sender));
        uint256 numDocs = _name.length;
        for (uint256 i = 0; i < numDocs; i++) {
            _setDocument(_name[i], _data[i]);
        }
    }

    function removeDocument(string calldata _name) external {
        require(hasAdminRole(msg.sender));
        _removeDocument(_name);
    }

    //--------------------------------------------------------
    // Point Lists
    //--------------------------------------------------------

    function setList(address _list) external {
        require(hasAdminRole(msg.sender));
        _setList(_list);
    }

    function enableList(bool _status) external {
        require(hasAdminRole(msg.sender));
        marketStatus.usePointList = _status;

        emit AuctionPointListUpdated(pointList, marketStatus.usePointList);
    }

    function _setList(address _pointList) private {
        if (_pointList != address(0)) {
            pointList = _pointList;
            marketStatus.usePointList = true;
        }

        emit AuctionPointListUpdated(_pointList, marketStatus.usePointList);
    }

    //--------------------------------------------------------
    // Setter Functions
    //--------------------------------------------------------

    /**
     * @notice Admin can set start and end time through this function.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     */
    function setAuctionTime(uint256 _startTime, uint256 _endTime) external {
        require(hasAdminRole(msg.sender));
        require(_startTime < 10000000000, "BatchAuction: enter an unix timestamp in seconds, not miliseconds");
        require(_endTime < 10000000000, "BatchAuction: enter an unix timestamp in seconds, not miliseconds");
        // solhint-disable-next-line not-rely-on-time
        require(_startTime >= block.timestamp, "BatchAuction: start time is before current time");
        require(_endTime > _startTime, "BatchAuction: end time must be older than start price");

        require(marketStatus.commitmentsTotal == 0, "BatchAuction: auction cannot have already started");

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);

        emit AuctionTimeUpdated(_startTime, _endTime);
    }

    /**
     * @notice Admin can set start and min price through this function.
     * @param _minimumCommitmentAmount Auction minimum raised target.
     */
    function setAuctionPrice(uint256 _minimumCommitmentAmount) external {
        require(hasAdminRole(msg.sender));

        require(marketStatus.commitmentsTotal == 0, "BatchAuction: auction cannot have already started");

        marketStatus.minimumCommitmentAmount = BoringMath.to128(_minimumCommitmentAmount);

        emit AuctionPriceUpdated(_minimumCommitmentAmount);
    }

    /**
     * @notice Admin can set the auction wallet through this function.
     * @param _wallet Auction wallet is where funds will be sent.
     */
    function setAuctionWallet(address payable _wallet) external {
        require(hasAdminRole(msg.sender), "BatchAuction: sender is not the admin");
        require(_wallet != address(0), "BatchAuction: wallet is the zero address");

        wallet = _wallet;

        emit AuctionWalletUpdated(_wallet);
    }

    //--------------------------------------------------------
    // Market Launchers
    //--------------------------------------------------------

    function init(bytes calldata _data) external payable override {}

    function initMarket(bytes calldata _data) public override {
        (
            address _funder,
            address _token,
            uint256 _totalTokens,
            uint256 _startTime,
            uint256 _endTime,
            address _paymentCurrency,
            uint24 _fee,
            uint256 _minimumCommitmentAmount,
            address _admin,
            address _pointList,
            address payable _wallet
        ) = abi.decode(
                _data,
                (address, address, uint256, uint256, uint256, address, uint24, uint256, address, address, address)
            );
        initAuction(
            _funder,
            _token,
            _totalTokens,
            _startTime,
            _endTime,
            _paymentCurrency,
            _fee,
            _minimumCommitmentAmount,
            _admin,
            _pointList,
            _wallet
        );
    }

    function getBatchAuctionInitData(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint24 _fee,
        uint256 _minimumCommitmentAmount,
        address _admin,
        address _pointList,
        address payable _wallet
    ) external pure returns (bytes memory _data) {
        return
            abi.encode(
                _funder,
                _token,
                _totalTokens,
                _startTime,
                _endTime,
                _paymentCurrency,
                _fee,
                _minimumCommitmentAmount,
                _admin,
                _pointList,
                _wallet
            );
    }

    function getBaseInformation()
        external
        view
        returns (address token, uint64 startTime, uint64 endTime, bool marketFinalized)
    {
        return (auctionToken, marketInfo.startTime, marketInfo.endTime, marketStatus.finalized);
    }

    function getTotalTokens() external view returns (uint256) {
        return uint256(marketInfo.totalTokens);
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Crowdsale
//
// A fixed price token swap contract.
//
// Inspired by the Open Zeppelin crowsdale and delta.financial
// https://github.com/OpenZeppelin/openzeppelin-contracts
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "../OpenZeppelin/utils/ReentrancyGuard.sol";
import "../Access/IHubAccessControls.sol";
import "../Utils/SafeTransfer.sol";
import "../Utils/BoringBatchable.sol";
import "../Utils/BoringERC20.sol";
import "../Utils/BoringMath.sol";
import "../Utils/Documents.sol";
import "../interfaces/IPointList.sol";
import "../interfaces/IIHubMarket.sol";

contract Crowdsale is IIHubMarket, IHubAccessControls, BoringBatchable, SafeTransfer, Documents, ReentrancyGuard {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using BoringERC20 for IERC20;

    /// @notice IHubMarket template id for the factory contract.
    /// @dev For different marketplace types, this must be incremented.
    uint256 public constant override marketTemplate = 1;

    /// @notice The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice The decimals of the auction token.
    uint256 private constant AUCTION_TOKEN_DECIMAL_PLACES = 18;
    uint256 private constant AUCTION_TOKEN_DECIMALS = 10 ** AUCTION_TOKEN_DECIMAL_PLACES;

    /**
     * @notice rate - How many token units a buyer gets per token or wei.
     * The rate is the conversion between wei and the smallest and indivisible token unit.
     * So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
     * 1 wei will give you 1 unit, or 0.001 TOK.
     */
    /// @notice goal - Minimum amount of funds to be raised in weis or tokens.
    struct MarketPrice {
        uint128 rate;
        uint128 goal;
    }
    MarketPrice public marketPrice;

    /// @notice Starting time of crowdsale.
    /// @notice Ending time of crowdsale.
    /// @notice Total number of tokens to sell.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    /// @notice Amount of wei raised.
    /// @notice Whether crowdsale has been initialized or not.
    /// @notice Whether crowdsale has been finalized or not.
    struct MarketStatus {
        uint128 commitmentsTotal;
        bool finalized;
        bool usePointList;
    }
    MarketStatus public marketStatus;

    /// @notice The token being sold.
    address public auctionToken;
    /// @notice Address where funds are collected.
    address payable public wallet;
    /// @notice The currency the crowdsale accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    /// @notice Address that manages auction approvals.
    address public pointList;

    /// @notice The commited amount of accounts.
    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /// @notice Event for all auction data. Emmited on deployment.
    event AuctionDeployed(
        address funder,
        address token,
        address paymentCurrency,
        uint256 totalTokens,
        address admin,
        address wallet
    );

    /// @notice Event for updating auction times.  Needs to be before auction starts.
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    /// @notice Event for updating auction prices. Needs to be before auction starts.
    event AuctionPriceUpdated(uint256 rate, uint256 goal);
    /// @notice Event for updating auction wallet. Needs to be before auction starts.
    event AuctionWalletUpdated(address wallet);
    /// @notice Event for updating the point list.
    event AuctionPointListUpdated(address pointList, bool enabled);

    /// @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);

    /// @notice Event for finalization of the crowdsale
    event AuctionFinalized();
    /// @notice Event for cancellation of the auction.
    event AuctionCancelled();

    /**
     * @notice Initializes main contract variables and transfers funds for the sale.
     * @dev Init function.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _totalTokens The total number of tokens to sell in crowdsale.
     * @param _startTime Crowdsale start time.
     * @param _endTime Crowdsale end time.
     * @param _rate Number of token units a buyer gets per wei or token.
     * @param _goal Minimum amount of funds to be raised in weis or tokens.
     * @param _admin Address that can finalize auction.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     */
    function initCrowdsale(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _admin,
        address _pointList,
        address payable _wallet
    ) public {
        require(_endTime < 10000000000, "in seconds, not miliseconds");
        // solhint-disable-next-line not-rely-on-time
        require(_startTime >= block.timestamp, "start is before current");
        require(_endTime > _startTime, "start is not before end");
        require(_rate > 0, "rate is 0");
        require(_wallet != address(0), "wallet is the zero address");
        require(_admin != address(0), "admin is the zero address");
        require(_totalTokens > 0, "total tokens is 0");
        require(_goal > 0, "goal is 0");
        require(IERC20(_token).decimals() == AUCTION_TOKEN_DECIMAL_PLACES, "Token does not have 18 decimals");
        if (_paymentCurrency != ETH_ADDRESS) {
            require(IERC20(_paymentCurrency).decimals() > 0, "Payment currency is not ERC20");
        }

        marketPrice.rate = BoringMath.to128(_rate);
        marketPrice.goal = BoringMath.to128(_goal);

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);
        marketInfo.totalTokens = BoringMath.to128(_totalTokens);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        wallet = _wallet;

        initAccessControls(_admin);

        _setList(_pointList);

        require(
            _getTokenAmount(_goal) <= _totalTokens,
            "Crowdsale: goal should be equal to or lower than total tokens"
        );

        _safeTransferFrom(_token, _funder, _totalTokens);

        emit AuctionDeployed(_funder, _token, _paymentCurrency, _totalTokens, _admin, _wallet);
        emit AuctionTimeUpdated(_startTime, _endTime);
        emit AuctionPriceUpdated(_rate, _goal);
    }

    ///--------------------------------------------------------
    /// Commit to buying tokens!
    ///--------------------------------------------------------

    receive() external payable {
        revertBecauseUserDidNotProvideAgreement();
    }

    /**
     * @dev Attribution to the awesome delta.financial contracts
     */
    function marketParticipationAgreement() public pure returns (string memory) {
        return
            "I understand that I am interacting with a smart contract. I understand that tokens commited are subject to the token issuer and local laws where applicable. I reviewed code of the smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }

    /**
     * @dev Not using modifiers is a purposeful choice for code readability.
     */
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert("No agreement provided, please review the smart contract before interacting with it");
    }

    /**
     * @notice Checks the amount of ETH to commit and adds the commitment. Refunds the buyer if commit is too high.
     * @dev low level token purchase with ETH ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it should not be called by
     * another `nonReentrant` function.
     * @param _beneficiary Recipient of the token purchase.
     */
    function commitEth(
        address payable _beneficiary,
        bool readAndAgreedToMarketParticipationAgreement
    ) public payable nonReentrant {
        require(paymentCurrency == ETH_ADDRESS, "Crowdsale: Payment currency is not ETH");
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }

        /// @dev Get ETH able to be committed.
        uint256 ethToTransfer = calculateCommitment(msg.value);

        /// @dev Accept ETH Payments.
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            _addCommitment(_beneficiary, ethToTransfer);
        }

        /// @dev Return any ETH to be refunded.
        if (ethToRefund > 0) {
            _beneficiary.transfer(ethToRefund);
        }

        /// @notice Revert if commitmentsTotal exceeds the balance
        require(
            marketStatus.commitmentsTotal <= address(this).balance,
            "CrowdSale: The committed ETH exceeds the balance"
        );
    }

    /**
     * @notice Buy Tokens by commiting approved ERC20 tokens to this contract address.
     * @param _amount Amount of tokens to commit.
     */
    function commitTokens(uint256 _amount, bool readAndAgreedToMarketParticipationAgreement) public {
        commitTokensFrom(msg.sender, _amount, readAndAgreedToMarketParticipationAgreement);
    }

    /**
     * @notice Checks how much is user able to commit and processes that commitment.
     * @dev Users must approve contract prior to committing tokens to auction.
     * @param _from User ERC20 address.
     * @param _amount Amount of approved ERC20 tokens.
     */
    function commitTokensFrom(
        address _from,
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) public nonReentrant {
        require(address(paymentCurrency) != ETH_ADDRESS, "Crowdsale: Payment currency is not a token");
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        uint256 tokensToTransfer = calculateCommitment(_amount);
        if (tokensToTransfer > 0) {
            _safeTransferFrom(paymentCurrency, msg.sender, tokensToTransfer);
            _addCommitment(_from, tokensToTransfer);
        }
    }

    /**
     * @notice Checks if the commitment does not exceed the goal of this sale.
     * @param _commitment Number of tokens to be commited.
     * @return committed The amount able to be purchased during a sale.
     */
    function calculateCommitment(uint256 _commitment) public view returns (uint256 committed) {
        uint256 tokens = _getTokenAmount(_commitment);
        uint256 tokensCommited = _getTokenAmount(uint256(marketStatus.commitmentsTotal));
        if (tokensCommited.add(tokens) > uint256(marketInfo.totalTokens)) {
            return _getTokenPrice(uint256(marketInfo.totalTokens).sub(tokensCommited));
        }
        return _commitment;
    }

    /**
     * @notice Updates commitment of the buyer and the amount raised, emits an event.
     * @param _addr Recipient of the token purchase.
     * @param _commitment Value in wei or token involved in the purchase.
     */
    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= uint256(marketInfo.startTime) && block.timestamp <= uint256(marketInfo.endTime),
            "Crowdsale: outside auction hours"
        );
        require(_addr != address(0), "Crowdsale: beneficiary is the zero address");
        require(!marketStatus.finalized, "CrowdSale: Auction is finalized");
        uint256 newCommitment = commitments[_addr].add(_commitment);
        if (marketStatus.usePointList) {
            require(IPointList(pointList).hasPoints(_addr, newCommitment));
        }

        commitments[_addr] = newCommitment;

        /// @dev Update state.
        marketStatus.commitmentsTotal = BoringMath.to128(uint256(marketStatus.commitmentsTotal).add(_commitment));

        emit AddedCommitment(_addr, _commitment);
    }

    function withdrawTokens() public {
        withdrawTokens(msg.sender);
    }

    /**
     * @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address payable beneficiary) public nonReentrant {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "Crowdsale: not finalized");
            /// @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "Crowdsale: no tokens to claim");
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);
            _safeTokenPayment(auctionToken, beneficiary, tokensToClaim);
        } else {
            /// @dev Auction did not meet reserve price.
            /// @dev Return committed funds back to user.
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp > uint256(marketInfo.endTime), "Crowdsale: auction has not finished yet");
            uint256 accountBalance = commitments[beneficiary];
            commitments[beneficiary] = 0; // Stop multiple withdrawals and free some gas
            _safeTokenPayment(paymentCurrency, beneficiary, accountBalance);
        }
    }

    /**
     * @notice Adjusts users commitment depending on amount already claimed and unclaimed tokens left.
     * @return claimerCommitment How many tokens the user is able to claim.
     */
    function tokensClaimable(address _user) public view returns (uint256 claimerCommitment) {
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    //--------------------------------------------------------
    // Finalize Auction
    //--------------------------------------------------------

    /**
     * @notice Manually finalizes the Crowdsale.
     * @dev Must be called after crowdsale ends, to do some extra finalization work.
     * Calls the contracts finalization function.
     */
    function finalize() public nonReentrant {
        require(
            hasAdminRole(msg.sender) ||
                wallet == msg.sender ||
                hasSmartContractRole(msg.sender) ||
                finalizeTimeExpired(),
            "Crowdsale: sender must be an admin"
        );
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "Crowdsale: already finalized");
        MarketInfo storage info = marketInfo;
        require(info.totalTokens > 0, "Not initialized");
        require(auctionEnded(), "Crowdsale: Has not finished yet");

        if (auctionSuccessful()) {
            /// @dev Successful auction
            /// @dev Transfer contributed tokens to wallet.
            _safeTokenPayment(paymentCurrency, wallet, uint256(status.commitmentsTotal));
            /// @dev Transfer unsold tokens to wallet.
            uint256 soldTokens = _getTokenAmount(uint256(status.commitmentsTotal));
            uint256 unsoldTokens = uint256(info.totalTokens).sub(soldTokens);
            if (unsoldTokens > 0) {
                _safeTokenPayment(auctionToken, wallet, unsoldTokens);
            }
        } else {
            /// @dev Failed auction
            /// @dev Return auction tokens back to wallet.
            _safeTokenPayment(auctionToken, wallet, uint256(info.totalTokens));
        }

        status.finalized = true;

        emit AuctionFinalized();
    }

    /**
     * @notice Cancel Auction
     * @dev Admin can cancel the auction before it starts
     */
    function cancelAuction() public nonReentrant {
        require(hasAdminRole(msg.sender));
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "Crowdsale: already finalized");
        require(uint256(status.commitmentsTotal) == 0, "Crowdsale: Funds already raised");

        _safeTokenPayment(auctionToken, wallet, uint256(marketInfo.totalTokens));

        status.finalized = true;
        emit AuctionCancelled();
    }

    function tokenPrice() public view returns (uint256) {
        return uint256(marketPrice.rate);
    }

    function _getTokenPrice(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(uint256(marketPrice.rate)).div(AUCTION_TOKEN_DECIMALS);
    }

    function getTokenAmount(uint256 _amount) public view returns (uint256) {
        return _getTokenAmount(_amount);
    }

    /**
     * @notice Calculates the number of tokens to purchase.
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _amount Value in wei or token to be converted into tokens.
     * @return tokenAmount Number of tokens that can be purchased with the specified amount.
     */
    function _getTokenAmount(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(AUCTION_TOKEN_DECIMALS).div(uint256(marketPrice.rate));
    }

    /**
     * @notice Checks if the sale is open.
     * @return isOpen True if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= uint256(marketInfo.startTime) && block.timestamp <= uint256(marketInfo.endTime);
    }

    /**
     * @notice Checks if the sale minimum amount was raised.
     * @return auctionSuccessful True if the commitmentsTotal is equal or higher than goal.
     */
    function auctionSuccessful() public view returns (bool) {
        return uint256(marketStatus.commitmentsTotal) >= uint256(marketPrice.goal);
    }

    /**
     * @notice Checks if the sale has ended.
     * @return auctionEnded True if sold out or time has ended.
     */
    function auctionEnded() public view returns (bool) {
        return
            // solhint-disable-next-line not-rely-on-time
            block.timestamp > uint256(marketInfo.endTime) ||
            _getTokenAmount(uint256(marketStatus.commitmentsTotal) + 1) >= uint256(marketInfo.totalTokens);
    }

    /**
     * @notice Checks if the sale has been finalised.
     * @return bool True if sale has been finalised.
     */
    function finalized() public view returns (bool) {
        return marketStatus.finalized;
    }

    /**
     * @return True if 7 days have passed since the end of the auction
     */
    function finalizeTimeExpired() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return uint256(marketInfo.endTime) + 7 days < block.timestamp;
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(string calldata _name, string calldata _data) external {
        require(hasAdminRole(msg.sender));
        _setDocument(_name, _data);
    }

    function setDocuments(string[] calldata _name, string[] calldata _data) external {
        require(hasAdminRole(msg.sender));
        uint256 numDocs = _name.length;
        for (uint256 i = 0; i < numDocs; i++) {
            _setDocument(_name[i], _data[i]);
        }
    }

    function removeDocument(string calldata _name) external {
        require(hasAdminRole(msg.sender));
        _removeDocument(_name);
    }

    //--------------------------------------------------------
    // Point Lists
    //--------------------------------------------------------

    function setList(address _list) external {
        require(hasAdminRole(msg.sender));
        _setList(_list);
    }

    function enableList(bool _status) external {
        require(hasAdminRole(msg.sender));
        marketStatus.usePointList = _status;

        emit AuctionPointListUpdated(pointList, marketStatus.usePointList);
    }

    function _setList(address _pointList) private {
        if (_pointList != address(0)) {
            pointList = _pointList;
            marketStatus.usePointList = true;
        }

        emit AuctionPointListUpdated(pointList, marketStatus.usePointList);
    }

    //--------------------------------------------------------
    // Setter Functions
    //--------------------------------------------------------

    /**
     * @notice Admin can set start and end time through this function.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     */
    function setAuctionTime(uint256 _startTime, uint256 _endTime) external {
        require(hasAdminRole(msg.sender));
        require(_startTime < 10000000000, "Crowdsale: enter an unix timestamp in seconds, not miliseconds");
        require(_endTime < 10000000000, "Crowdsale: enter an unix timestamp in seconds, not miliseconds");
        // solhint-disable-next-line not-rely-on-time
        require(_startTime >= block.timestamp, "Crowdsale: start time is before current time");
        require(_endTime > _startTime, "Crowdsale: end time must be older than start price");

        require(marketStatus.commitmentsTotal == 0, "Crowdsale: auction cannot have already started");

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);

        emit AuctionTimeUpdated(_startTime, _endTime);
    }

    /**
     * @notice Admin can set auction price through this function.
     * @param _rate Price per token.
     * @param _goal Minimum amount raised and goal for the auction.
     */
    function setAuctionPrice(uint256 _rate, uint256 _goal) external {
        require(hasAdminRole(msg.sender));
        require(_goal > 0, "Crowdsale: goal is 0");
        require(_rate > 0, "Crowdsale: rate is 0");
        require(marketStatus.commitmentsTotal == 0, "Crowdsale: auction cannot have already started");
        marketPrice.rate = BoringMath.to128(_rate);
        marketPrice.goal = BoringMath.to128(_goal);
        require(
            _getTokenAmount(_goal) <= uint256(marketInfo.totalTokens),
            "Crowdsale: minimum target exceeds hard cap"
        );

        emit AuctionPriceUpdated(_rate, _goal);
    }

    /**
     * @notice Admin can set the auction wallet through this function.
     * @param _wallet Auction wallet is where funds will be sent.
     */
    function setAuctionWallet(address payable _wallet) external {
        require(hasAdminRole(msg.sender));
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        wallet = _wallet;

        emit AuctionWalletUpdated(_wallet);
    }

    //--------------------------------------------------------
    // Market Launchers
    //--------------------------------------------------------

    function init(bytes calldata _data) external payable override {}

    /**
     * @notice Decodes and hands Crowdsale data to the initCrowdsale function.
     * @param _data Encoded data for initialization.
     */
    function initMarket(bytes calldata _data) public override {
        (
            address _funder,
            address _token,
            address _paymentCurrency,
            uint256 _totalTokens,
            uint256 _startTime,
            uint256 _endTime,
            uint256 _rate,
            uint256 _goal,
            address _admin,
            address _pointList,
            address payable _wallet
        ) = abi.decode(
                _data,
                (address, address, address, uint256, uint256, uint256, uint256, uint256, address, address, address)
            );

        initCrowdsale(
            _funder,
            _token,
            _paymentCurrency,
            _totalTokens,
            _startTime,
            _endTime,
            _rate,
            _goal,
            _admin,
            _pointList,
            _wallet
        );
    }

    /**
     * @notice Collects data to initialize the crowd sale.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _totalTokens The total number of tokens to sell in crowdsale.
     * @param _startTime Crowdsale start time.
     * @param _endTime Crowdsale end time.
     * @param _rate Number of token units a buyer gets per wei or token.
     * @param _goal Minimum amount of funds to be raised in weis or tokens.
     * @param _admin Address that can finalize crowdsale.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     * @return _data All the data in bytes format.
     */
    function getCrowdsaleInitData(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _admin,
        address _pointList,
        address payable _wallet
    ) external pure returns (bytes memory _data) {
        return
            abi.encode(
                _funder,
                _token,
                _paymentCurrency,
                _totalTokens,
                _startTime,
                _endTime,
                _rate,
                _goal,
                _admin,
                _pointList,
                _wallet
            );
    }

    function getBaseInformation() external view returns (address, uint64, uint64, bool) {
        return (auctionToken, marketInfo.startTime, marketInfo.endTime, marketStatus.finalized);
    }

    function getTotalTokens() external view returns (uint256) {
        return uint256(marketInfo.totalTokens);
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Dutch Auction
//
// A declining price auction with fair price discovery.
//
// Inspired by DutchSwap's Dutch Auctions
// https://github.com/deepyr/DutchSwap
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "../OpenZeppelin/utils/ReentrancyGuard.sol";
import "../Access/IHubAccessControls.sol";
import "../Utils/SafeTransfer.sol";
import "../Utils/BoringBatchable.sol";
import "../Utils/BoringMath.sol";
import "../Utils/BoringERC20.sol";
import "../Utils/Documents.sol";
import "../interfaces/IPointList.sol";
import "../interfaces/IIHubMarket.sol";

/// @notice Attribution to delta.financial
/// @notice Attribution to dutchswap.com

contract DutchAuction is IIHubMarket, IHubAccessControls, BoringBatchable, SafeTransfer, Documents, ReentrancyGuard {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using BoringERC20 for IERC20;

    /// @notice IHubMarket template id for the factory contract.
    /// @dev For different marketplace types, this must be incremented.
    uint256 public constant override marketTemplate = 2;
    /// @dev The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Main market variables.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    /// @notice Market price variables.
    struct MarketPrice {
        uint128 startPrice;
        uint128 minimumPrice;
    }
    MarketPrice public marketPrice;

    /// @notice Market dynamic variables.
    struct MarketStatus {
        uint128 commitmentsTotal;
        bool finalized;
        bool usePointList;
    }

    MarketStatus public marketStatus;

    /// @notice The token being sold.
    address public auctionToken;
    /// @notice The currency the auction accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    // TangleswapPool->fee
    uint24 public fee;
    /// @notice Where the auction funds will get paid.
    address payable public wallet;
    /// @notice Address that manages auction approvals.
    address public pointList;

    /// @notice The committed amount of accounts.
    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /// @notice Event for all auction data. Emmited on deployment.
    event AuctionDeployed(
        address funder,
        address token,
        uint256 totalTokens,
        address paymentCurrency,
        address admin,
        address wallet
    );

    /// @notice Event for updating auction times.  Needs to be before auction starts.
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    /// @notice Event for updating auction prices. Needs to be before auction starts.
    event AuctionPriceUpdated(uint256 startPrice, uint256 minimumPrice);
    /// @notice Event for updating auction wallet. Needs to be before auction starts.
    event AuctionWalletUpdated(address wallet);
    /// @notice Event for updating the point list.
    event AuctionPointListUpdated(address pointList, bool enabled);

    /// @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);
    /// @notice Event for token withdrawals.
    event TokensWithdrawn(address token, address to, uint256 amount);

    /// @notice Event for finalization of the auction.
    event AuctionFinalized();
    /// @notice Event for cancellation of the auction.
    event AuctionCancelled();

    /**
     * @notice Initializes main contract variables and transfers funds for the auction.
     * @dev Init function.
     * @param _funder The address that funds the token for DutchAuction.
     * @param _token Address of the token being sold.
     * @param _totalTokens The total number of tokens to sell in auction.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     * @param _paymentCurrency The currency the DutchAuction accepts for payment. Can be ETH or token address.
     * @param _startPrice Starting price of the auction.
     * @param _minimumPrice The minimum auction price.
     * @param _admin Address that can finalize auction.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     */
    function initAuction(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint24 _fee,
        uint256 _startPrice,
        uint256 _minimumPrice,
        address _admin,
        address _pointList,
        address payable _wallet
    ) public {
        require(_endTime < 10000000000, "DutchAuction: enter an unix timestamp in seconds, not miliseconds");
        // solhint-disable-next-line not-rely-on-time
        require(_startTime >= block.timestamp, "DutchAuction: start time is before current time");
        require(_endTime > _startTime, "DutchAuction: end time must be older than start price");
        require(_totalTokens > 0, "DutchAuction: total tokens must be greater than zero");
        require(_startPrice > _minimumPrice, "DutchAuction: start price must be higher than minimum price");
        require(_minimumPrice > 0, "DutchAuction: minimum price must be greater than 0");
        require(_admin != address(0), "DutchAuction: admin is the zero address");
        require(_wallet != address(0), "DutchAuction: wallet is the zero address");
        require(IERC20(_token).decimals() == 18, "DutchAuction: Token does not have 18 decimals");
        if (_paymentCurrency != ETH_ADDRESS) {
            require(IERC20(_paymentCurrency).decimals() > 0, "DutchAuction: Payment currency is not ERC20");
        }

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);
        marketInfo.totalTokens = BoringMath.to128(_totalTokens);

        marketPrice.startPrice = BoringMath.to128(_startPrice);
        marketPrice.minimumPrice = BoringMath.to128(_minimumPrice);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        // TangleswapPool->fee
        fee = _fee;
        wallet = _wallet;

        initAccessControls(_admin);

        _setList(_pointList);
        _safeTransferFrom(_token, _funder, _totalTokens);

        emit AuctionDeployed(_funder, _token, _totalTokens, _paymentCurrency, _admin, _wallet);
        emit AuctionTimeUpdated(_startTime, _endTime);
        emit AuctionPriceUpdated(_startPrice, _minimumPrice);
    }

    /**
     Dutch Auction Price Function
     ============================
     
     Start Price -----
                      \
                       \
                        \
                         \ ------------ Clearing Price
                        / \            = AmountRaised/TokenSupply
         Token Price  --   \
                     /      \
                   --        ----------- Minimum Price
     Amount raised /          End Time
    */

    /**
     * @notice Calculates the average price of each token from all commitments.
     * @return Average token price.
     */
    function tokenPrice() public view returns (uint256) {
        return uint256(marketStatus.commitmentsTotal).mul(1e18).div(uint256(marketInfo.totalTokens));
    }

    /**
     * @notice Returns auction price in any time.
     * @return Fixed start price or minimum price if outside of auction time, otherwise calculated current price.
     */
    function priceFunction() public view returns (uint256) {
        /// @dev Return Auction Price
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp <= uint256(marketInfo.startTime)) {
            return uint256(marketPrice.startPrice);
        }
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= uint256(marketInfo.endTime)) {
            return uint256(marketPrice.minimumPrice);
        }

        return _currentPrice();
    }

    /**
     * @notice The current clearing price of the Dutch auction.
     * @return The bigger from tokenPrice and priceFunction.
     */
    function clearingPrice() public view returns (uint256) {
        /// @dev If auction successful, return tokenPrice
        uint256 _tokenPrice = tokenPrice();
        uint256 _currentPrice = priceFunction();
        return _tokenPrice > _currentPrice ? _tokenPrice : _currentPrice;
    }

    ///--------------------------------------------------------
    /// Commit to buying tokens!
    ///--------------------------------------------------------

    receive() external payable {
        revertBecauseUserDidNotProvideAgreement();
    }

    /**
     * @dev Attribution to the awesome delta.financial contracts
     */
    function marketParticipationAgreement() public pure returns (string memory) {
        return
            "I understand that I'm interacting with a smart contract. I understand that tokens committed are subject to the token issuer and local laws where applicable. I reviewed code of the smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }

    /**
     * @dev Not using modifiers is a purposeful choice for code readability.
     */
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert("No agreement provided, please review the smart contract before interacting with it");
    }

    /**
     * @notice Checks the amount of ETH to commit and adds the commitment. Refunds the buyer if commit is too high.
     * @param _beneficiary Auction participant ETH address.
     */
    function commitEth(address payable _beneficiary, bool readAndAgreedToMarketParticipationAgreement) public payable {
        require(paymentCurrency == ETH_ADDRESS, "DutchAuction: payment currency is not ETH address");
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        // Get ETH able to be committed
        uint256 ethToTransfer = calculateCommitment(msg.value);

        /// @notice Accept ETH Payments.
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            _addCommitment(_beneficiary, ethToTransfer);
        }
        /// @notice Return any ETH to be refunded.
        if (ethToRefund > 0) {
            _beneficiary.transfer(ethToRefund);
        }

        /// @notice Revert if commitmentsTotal exceeds the balance
        require(
            marketStatus.commitmentsTotal <= address(this).balance,
            "DutchAuction: The committed ETH exceeds the balance"
        );
    }

    /**
     * @notice Buy Tokens by commiting approved ERC20 tokens to this contract address.
     * @param _amount Amount of tokens to commit.
     */
    function commitTokens(uint256 _amount, bool readAndAgreedToMarketParticipationAgreement) public {
        commitTokensFrom(msg.sender, _amount, readAndAgreedToMarketParticipationAgreement);
    }

    /**
     * @notice Checks how much is user able to commit and processes that commitment.
     * @dev Users must approve contract prior to committing tokens to auction.
     * @param _from User ERC20 address.
     * @param _amount Amount of approved ERC20 tokens.
     */
    function commitTokensFrom(
        address _from,
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) public nonReentrant {
        require(address(paymentCurrency) != ETH_ADDRESS, "DutchAuction: Payment currency is not a token");
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        uint256 tokensToTransfer = calculateCommitment(_amount);
        if (tokensToTransfer > 0) {
            _safeTransferFrom(paymentCurrency, msg.sender, tokensToTransfer);
            _addCommitment(_from, tokensToTransfer);
        }
    }

    /**
     * @notice Calculates the pricedrop factor.
     * @return Value calculated from auction start and end price difference divided the auction duration.
     */
    function priceDrop() public view returns (uint256) {
        MarketInfo memory _marketInfo = marketInfo;
        MarketPrice memory _marketPrice = marketPrice;

        uint256 numerator = uint256(_marketPrice.startPrice.sub(_marketPrice.minimumPrice));
        uint256 denominator = uint256(_marketInfo.endTime.sub(_marketInfo.startTime));
        return numerator / denominator;
    }

    /**
     * @notice How many tokens the user is able to claim.
     * @param _user Auction participant address.
     * @return claimerCommitment User commitments reduced by already claimed tokens.
     */
    function tokensClaimable(address _user) public view returns (uint256 claimerCommitment) {
        if (commitments[_user] == 0) return 0;
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));

        claimerCommitment = commitments[_user].mul(uint256(marketInfo.totalTokens)).div(
            uint256(marketStatus.commitmentsTotal)
        );
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    /**
     * @notice Calculates total amount of tokens committed at current auction price.
     * @return Number of tokens committed.
     */
    function totalTokensCommitted() public view returns (uint256) {
        return uint256(marketStatus.commitmentsTotal).mul(1e18).div(clearingPrice());
    }

    /**
     * @notice Calculates the amount able to be committed during an auction.
     * @param _commitment Commitment user would like to make.
     * @return committed Amount allowed to commit.
     */
    function calculateCommitment(uint256 _commitment) public view returns (uint256 committed) {
        uint256 maxCommitment = uint256(marketInfo.totalTokens).mul(clearingPrice()).div(1e18);
        if (uint256(marketStatus.commitmentsTotal).add(_commitment) > maxCommitment) {
            return maxCommitment.sub(uint256(marketStatus.commitmentsTotal));
        }
        return _commitment;
    }

    /**
     * @notice Checks if the auction is open.
     * @return True if current time is greater than startTime and less than endTime.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= uint256(marketInfo.startTime) && block.timestamp <= uint256(marketInfo.endTime);
    }

    /**
     * @notice Successful if tokens sold equals totalTokens.
     * @return True if tokenPrice is bigger or equal clearingPrice.
     */
    function auctionSuccessful() public view returns (bool) {
        return tokenPrice() >= clearingPrice();
    }

    /**
     * @notice Checks if the auction has ended.
     * @return True if auction is successful or time has ended.
     */
    function auctionEnded() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return auctionSuccessful() || block.timestamp > uint256(marketInfo.endTime);
    }

    /**
     * @return Returns true if market has been finalized
     */
    function finalized() public view returns (bool) {
        return marketStatus.finalized;
    }

    /**
     * @return Returns true if 7 days have passed since the end of the auction
     */
    function finalizeTimeExpired() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return uint256(marketInfo.endTime) + 7 days < block.timestamp;
    }

    /**
     * @notice Calculates price during the auction.
     * @return Current auction price.
     */
    function _currentPrice() private view returns (uint256) {
        MarketInfo memory _marketInfo = marketInfo;
        MarketPrice memory _marketPrice = marketPrice;
        // solhint-disable-next-line not-rely-on-time
        uint256 priceDiff = block.timestamp.sub(uint256(_marketInfo.startTime)).mul(
            uint256(_marketPrice.startPrice.sub(_marketPrice.minimumPrice))
        ) / uint256(_marketInfo.endTime.sub(_marketInfo.startTime));
        return uint256(_marketPrice.startPrice).sub(priceDiff);
    }

    /**
     * @notice Updates commitment for this address and total commitment of the auction.
     * @param _addr Bidders address.
     * @param _commitment The amount to commit.
     */
    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= uint256(marketInfo.startTime) && block.timestamp <= uint256(marketInfo.endTime),
            "DutchAuction: outside auction hours"
        );
        MarketStatus storage status = marketStatus;

        uint256 newCommitment = commitments[_addr].add(_commitment);
        if (status.usePointList) {
            require(IPointList(pointList).hasPoints(_addr, newCommitment));
        }

        commitments[_addr] = newCommitment;
        status.commitmentsTotal = BoringMath.to128(uint256(status.commitmentsTotal).add(_commitment));
        emit AddedCommitment(_addr, _commitment);
    }

    //--------------------------------------------------------
    // Finalize Auction
    //--------------------------------------------------------

    /**
     * @notice Cancel Auction
     * @dev Admin can cancel the auction before it starts
     */
    function cancelAuction() public nonReentrant {
        require(hasAdminRole(msg.sender));
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "DutchAuction: auction already finalized");
        require(uint256(status.commitmentsTotal) == 0, "DutchAuction: auction already committed");
        _safeTokenPayment(auctionToken, wallet, uint256(marketInfo.totalTokens));
        status.finalized = true;

        emit AuctionCancelled();
    }

    /**
     * @notice Auction finishes successfully above the reserve.
     * @dev Transfer contract funds to initialized wallet.
     */
    function finalize() public nonReentrant {
        require(
            hasAdminRole(msg.sender) ||
                hasSmartContractRole(msg.sender) ||
                wallet == msg.sender ||
                finalizeTimeExpired(),
            "DutchAuction: sender must be an admin"
        );

        require(marketInfo.totalTokens > 0, "Not initialized");

        MarketStatus storage status = marketStatus;

        require(!status.finalized, "DutchAuction: auction already finalized");
        if (auctionSuccessful()) {
            /// @dev Successful auction
            /// @dev Transfer contributed tokens to wallet.
            _safeTokenPayment(paymentCurrency, wallet, uint256(status.commitmentsTotal));
        } else {
            /// @dev Failed auction
            /// @dev Return auction tokens back to wallet.
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp > uint256(marketInfo.endTime), "DutchAuction: auction has not finished yet");
            _safeTokenPayment(auctionToken, wallet, uint256(marketInfo.totalTokens));
        }
        status.finalized = true;
        emit AuctionFinalized();
    }

    /// @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
    function withdrawTokens() public {
        withdrawTokens(msg.sender);
    }

    /**
     * @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
     * @dev Withdraw tokens only after auction ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address payable beneficiary) public nonReentrant {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "DutchAuction: not finalized");
            /// @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "DutchAuction: No tokens to claim");
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);
            _safeTokenPayment(auctionToken, beneficiary, tokensToClaim);
        } else {
            /// @dev Auction did not meet reserve price.
            /// @dev Return committed funds back to user.
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp > uint256(marketInfo.endTime), "DutchAuction: auction has not finished yet");
            uint256 fundsCommitted = commitments[beneficiary];
            commitments[beneficiary] = 0; // Stop multiple withdrawals and free some gas
            _safeTokenPayment(paymentCurrency, beneficiary, fundsCommitted);
        }
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(string calldata _name, string calldata _data) external {
        require(hasAdminRole(msg.sender));
        _setDocument(_name, _data);
    }

    function setDocuments(string[] calldata _name, string[] calldata _data) external {
        require(hasAdminRole(msg.sender));
        uint256 numDocs = _name.length;
        for (uint256 i = 0; i < numDocs; i++) {
            _setDocument(_name[i], _data[i]);
        }
    }

    function removeDocument(string calldata _name) external {
        require(hasAdminRole(msg.sender));
        _removeDocument(_name);
    }

    //--------------------------------------------------------
    // Point Lists
    //--------------------------------------------------------

    function setList(address _list) external {
        require(hasAdminRole(msg.sender));
        _setList(_list);
    }

    function enableList(bool _status) external {
        require(hasAdminRole(msg.sender));
        marketStatus.usePointList = _status;

        emit AuctionPointListUpdated(pointList, marketStatus.usePointList);
    }

    function _setList(address _pointList) private {
        if (_pointList != address(0)) {
            pointList = _pointList;
            marketStatus.usePointList = true;
        }

        emit AuctionPointListUpdated(pointList, marketStatus.usePointList);
    }

    //--------------------------------------------------------
    // Setter Functions
    //--------------------------------------------------------

    /**
     * @notice Admin can set start and end time through this function.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     */
    function setAuctionTime(uint256 _startTime, uint256 _endTime) external {
        require(hasAdminRole(msg.sender));
        require(_startTime < 10000000000, "DutchAuction: enter an unix timestamp in seconds, not miliseconds");
        require(_endTime < 10000000000, "DutchAuction: enter an unix timestamp in seconds, not miliseconds");
        // solhint-disable-next-line not-rely-on-time
        require(_startTime >= block.timestamp, "DutchAuction: start time is before current time");
        require(_endTime > _startTime, "DutchAuction: end time must be older than start time");
        require(marketStatus.commitmentsTotal == 0, "DutchAuction: auction cannot have already started");

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);

        emit AuctionTimeUpdated(_startTime, _endTime);
    }

    /**
     * @notice Admin can set start and min price through this function.
     * @param _startPrice Auction start price.
     * @param _minimumPrice Auction minimum price.
     */
    function setAuctionPrice(uint256 _startPrice, uint256 _minimumPrice) external {
        require(hasAdminRole(msg.sender));
        require(_startPrice > _minimumPrice, "DutchAuction: start price must be higher than minimum price");
        require(_minimumPrice > 0, "DutchAuction: minimum price must be greater than 0");
        require(marketStatus.commitmentsTotal == 0, "DutchAuction: auction cannot have already started");

        marketPrice.startPrice = BoringMath.to128(_startPrice);
        marketPrice.minimumPrice = BoringMath.to128(_minimumPrice);

        emit AuctionPriceUpdated(_startPrice, _minimumPrice);
    }

    /**
     * @notice Admin can set the auction wallet through this function.
     * @param _wallet Auction wallet is where funds will be sent.
     */
    function setAuctionWallet(address payable _wallet) external {
        require(hasAdminRole(msg.sender));
        require(_wallet != address(0), "DutchAuction: wallet is the zero address");

        wallet = _wallet;

        emit AuctionWalletUpdated(_wallet);
    }

    //--------------------------------------------------------
    // Market Launchers
    //--------------------------------------------------------

    /**
     * @notice Decodes and hands auction data to the initAuction function.
     * @param _data Encoded data for initialization.
     */

    function init(bytes calldata _data) external payable override {}

    function initMarket(bytes calldata _data) public override {
        (
            address _funder,
            address _token,
            uint256 _totalTokens,
            uint256 _startTime,
            uint256 _endTime,
            address _paymentCurrency,
            uint24 _fee,
            uint256 _startPrice,
            uint256 _minimumPrice,
            address _admin,
            address _pointList,
            address payable _wallet
        ) = abi.decode(
                _data,
                (
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    uint24,
                    uint256,
                    uint256,
                    address,
                    address,
                    address
                )
            );
        initAuction(
            _funder,
            _token,
            _totalTokens,
            _startTime,
            _endTime,
            _paymentCurrency,
            _fee,
            _startPrice,
            _minimumPrice,
            _admin,
            _pointList,
            _wallet
        );
    }

    /**
     * @notice Collects data to initialize the auction and encodes them.
     * @param _funder The address that funds the token for DutchAuction.
     * @param _token Address of the token being sold.
     * @param _totalTokens The total number of tokens to sell in auction.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     * @param _paymentCurrency The currency the DutchAuction accepts for payment. Can be ETH or token address.
     * @param _startPrice Starting price of the auction.
     * @param _minimumPrice The minimum auction price.
     * @param _admin Address that can finalize auction.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     * @return _data All the data in bytes format.
     */
    function getAuctionInitData(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint24 _fee,
        uint256 _startPrice,
        uint256 _minimumPrice,
        address _admin,
        address _pointList,
        address payable _wallet
    ) external pure returns (bytes memory _data) {
        return
            abi.encode(
                _funder,
                _token,
                _totalTokens,
                _startTime,
                _endTime,
                _paymentCurrency,
                _fee,
                _startPrice,
                _minimumPrice,
                _admin,
                _pointList,
                _wallet
            );
    }

    function getBaseInformation() external view returns (address, uint64, uint64, bool) {
        return (auctionToken, marketInfo.startTime, marketInfo.endTime, marketStatus.finalized);
    }

    function getTotalTokens() external view returns (uint256) {
        return uint256(marketInfo.totalTokens);
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Hyperbolic Auction
// A declining price auction with fair price discovery on a hyperbolic curve.
//
// Inspired by DutchSwap's Dutch Auctions
// https://github.com/deepyr/DutchSwap
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "../OpenZeppelin/utils/ReentrancyGuard.sol";
import "../Access/IHubAccessControls.sol";
import "../Utils/SafeTransfer.sol";
import "../Utils/BoringBatchable.sol";
import "../Utils/BoringERC20.sol";
import "../Utils/BoringMath.sol";
import "../Utils/Documents.sol";
import "../interfaces/IPointList.sol";
import "../interfaces/IIHubMarket.sol";

/// @notice Attribution to delta.financial
/// @notice Attribution to dutchswap.com

contract HyperbolicAuction is
    IIHubMarket,
    IHubAccessControls,
    BoringBatchable,
    SafeTransfer,
    Documents,
    ReentrancyGuard
{
    using BoringERC20 for IERC20;
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;

    // IHubMarket template id.
    /// @dev For different marketplace types, this must be incremented.
    uint256 public constant override marketTemplate = 4;
    /// @dev The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Main market variables.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    /// @notice Market price variables.
    struct MarketPrice {
        uint128 minimumPrice;
        uint128 alpha;
        // GP: Can be added later as exponent factor
        // uint16 factor;
    }
    MarketPrice public marketPrice;

    /// @notice Market dynamic variables.
    struct MarketStatus {
        uint128 commitmentsTotal;
        bool finalized;
        bool usePointList;
    }
    MarketStatus public marketStatus;

    /// @notice The token being sold.
    address public auctionToken;
    /// @notice The currency the auction accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    // TangleswapPool->fee
    uint24 public fee;
    /// @notice Where the auction funds will get paid.
    address payable public wallet;
    /// @notice Address that manages auction approvals.
    address public pointList;

    /// @notice The commited amount of accounts.
    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /// @notice Event for all auction data. Emmited on deployment.
    event AuctionDeployed(
        address funder,
        address token,
        uint256 totalTokens,
        address paymentCurrency,
        address admin,
        address wallet
    );

    /// @notice Event for updating auction times.  Needs to be before auction starts.
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    /// @notice Event for updating auction prices. Needs to be before auction starts.
    event AuctionPriceUpdated(uint256 minimumPrice);
    /// @notice Event for updating auction wallet. Needs to be before auction starts.
    event AuctionWalletUpdated(address wallet);
    /// @notice Event for updating the point list.
    event AuctionPointListUpdated(address pointList, bool enabled);

    /// @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);
    /// @notice Event for token withdrawals.
    event TokensWithdrawn(address token, address to, uint256 amount);

    /// @notice Event for finalization of the auction.
    event AuctionFinalized();
    /// @notice Event for cancellation of the auction.
    event AuctionCancelled();

    /**
     * @notice Initializes main contract variables and transfers funds for the auction.
     * @dev Init function
     * @param _funder The address that funds the token for HyperbolicAuction
     * @param _token Address of the token being sold
     * @param _paymentCurrency The currency the HyperbolicAuction accepts for payment. Can be ETH or token address
     * @param _totalTokens The total number of tokens to sell in auction
     * @param _startTime Auction start time
     * @param _endTime Auction end time
     * @param _factor Inflection point of the auction
     * @param _minimumPrice The minimum auction price
     * @param _admin Address that can finalize auction.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to
     */
    function initAuction(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint24 _fee,
        uint256 _factor,
        uint256 _minimumPrice,
        address _admin,
        address _pointList,
        address payable _wallet
    ) public {
        require(_endTime < 10000000000, "HyperbolicAuction: enter an unix timestamp in seconds, not miliseconds");
        // solhint-disable-next-line not-rely-on-time
        require(_startTime >= block.timestamp, "HyperbolicAuction: start time is before current time");
        require(_totalTokens > 0, "HyperbolicAuction: total tokens must be greater than zero");
        require(_endTime > _startTime, "HyperbolicAuction: end time must be older than start time");
        require(_minimumPrice > 0, "HyperbolicAuction: minimum price must be greater than 0");
        require(_wallet != address(0), "HyperbolicAuction: wallet is the zero address");
        require(_admin != address(0), "HyperbolicAuction: admin is the zero address");
        require(_token != address(0), "HyperbolicAuction: token is the zero address");
        require(IERC20(_token).decimals() == 18, "HyperbolicAuction: Token does not have 18 decimals");
        if (_paymentCurrency != ETH_ADDRESS) {
            require(IERC20(_paymentCurrency).decimals() > 0, "HyperbolicAuction: Payment currency is not ERC20");
        }

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);
        marketInfo.totalTokens = BoringMath.to128(_totalTokens);

        marketPrice.minimumPrice = BoringMath.to128(_minimumPrice);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        // TangleswapPool->fee
        fee = _fee;
        wallet = _wallet;

        initAccessControls(_admin);

        _setList(_pointList);

        // factor = exponent which can later be used to alter the curve
        uint256 _duration = _endTime - _startTime;
        uint256 _alpha = _duration.mul(_minimumPrice);
        marketPrice.alpha = BoringMath.to128(_alpha);

        _safeTransferFrom(_token, _funder, _totalTokens);

        emit AuctionDeployed(_funder, _token, _totalTokens, _paymentCurrency, _admin, _wallet);
        emit AuctionTimeUpdated(_startTime, _endTime);
        emit AuctionPriceUpdated(_minimumPrice);
    }

    ///--------------------------------------------------------
    /// Auction Pricing
    ///--------------------------------------------------------

    /**
     * @notice Calculates the average price of each token from all commitments.
     * @return Average token price.
     */
    function tokenPrice() public view returns (uint256) {
        return uint256(marketStatus.commitmentsTotal).mul(1e18).div(uint256(marketInfo.totalTokens));
    }

    /**
     * @notice Returns auction price in any time.
     * @return Fixed start price or minimum price if outside of auction time, otherwise calculated current price.
     */
    function priceFunction() public view returns (uint256) {
        /// @dev Return Auction Price
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp <= uint256(marketInfo.startTime)) {
            return uint256(-1);
        }
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= uint256(marketInfo.endTime)) {
            return uint256(marketPrice.minimumPrice);
        }
        return _currentPrice();
    }

    /// @notice The current clearing price of the Hyperbolic auction
    function clearingPrice() public view returns (uint256) {
        /// @dev If auction successful, return tokenPrice
        if (tokenPrice() > priceFunction()) {
            return tokenPrice();
        }
        return priceFunction();
    }

    /**
     * @notice Calculates price during the auction.
     * @return Current auction price.
     */
    function _currentPrice() private view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 elapsed = block.timestamp.sub(uint256(marketInfo.startTime));
        uint256 currentPrice = uint256(marketPrice.alpha).div(elapsed);
        return currentPrice;
    }

    ///--------------------------------------------------------
    /// Commit to buying tokens!
    ///--------------------------------------------------------

    /**
     * @notice Buy Tokens by committing ETH to this contract address
     * @dev Needs sufficient gas limit for additional state changes
     */
    receive() external payable {
        revertBecauseUserDidNotProvideAgreement();
    }

    /**
     * @dev Attribution to the awesome delta.financial contracts
     */
    function marketParticipationAgreement() public pure returns (string memory) {
        return
            "I understand that I'm interacting with a smart contract. I understand that tokens commited are subject to the token issuer and local laws where applicable. I reviewed code of the smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }

    /**
     * @dev Not using modifiers is a purposeful choice for code readability.
     */
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert("No agreement provided, please review the smart contract before interacting with it");
    }

    /**
     * @notice Checks the amount of ETH to commit and adds the commitment. Refunds the buyer if commit is too high.
     * @param _beneficiary Auction participant ETH address.
     */
    function commitEth(address payable _beneficiary, bool readAndAgreedToMarketParticipationAgreement) public payable {
        require(paymentCurrency == ETH_ADDRESS, "HyperbolicAuction: payment currency is not ETH address");
        // Get ETH able to be committed
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        require(msg.value > 0, "HyperbolicAuction: Value must be higher than 0");
        uint256 ethToTransfer = calculateCommitment(msg.value);

        /// @notice Accept ETH Payments.
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            _addCommitment(_beneficiary, ethToTransfer);
        }
        /// @notice Return any ETH to be refunded.
        if (ethToRefund > 0) {
            _beneficiary.transfer(ethToRefund);
        }

        /// @notice Revert if commitmentsTotal exceeds the balance
        require(
            marketStatus.commitmentsTotal <= address(this).balance,
            "HyperbolicAuction: The committed ETH exceeds the balance"
        );
    }

    /**
     * @notice Buy Tokens by commiting approved ERC20 tokens to this contract address.
     * @param _amount Amount of tokens to commit.
     */
    function commitTokens(uint256 _amount, bool readAndAgreedToMarketParticipationAgreement) public {
        commitTokensFrom(msg.sender, _amount, readAndAgreedToMarketParticipationAgreement);
    }

    /// @dev Users must approve contract prior to committing tokens to auction
    function commitTokensFrom(
        address _from,
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) public nonReentrant {
        require(paymentCurrency != ETH_ADDRESS, "HyperbolicAuction: payment currency is not a token");
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        uint256 tokensToTransfer = calculateCommitment(_amount);
        if (tokensToTransfer > 0) {
            _safeTransferFrom(paymentCurrency, msg.sender, tokensToTransfer);
            _addCommitment(_from, tokensToTransfer);
        }
    }

    /**
     * @notice Calculates total amount of tokens committed at current auction price.
     * @return Number of tokens commited.
     */
    function totalTokensCommitted() public view returns (uint256) {
        return uint256(marketStatus.commitmentsTotal).mul(1e18).div(clearingPrice());
    }

    /**
     * @notice Calculates the amount able to be committed during an auction.
     * @param _commitment Commitment user would like to make.
     * @return Amount allowed to commit.
     */
    function calculateCommitment(uint256 _commitment) public view returns (uint256) {
        uint256 maxCommitment = uint256(marketInfo.totalTokens).mul(clearingPrice()).div(1e18);
        if (uint256(marketStatus.commitmentsTotal).add(_commitment) > maxCommitment) {
            return maxCommitment.sub(uint256(marketStatus.commitmentsTotal));
        }
        return _commitment;
    }

    /**
     * @notice Updates commitment for this address and total commitment of the auction.
     * @param _addr Bidders address.
     * @param _commitment The amount to commit.
     */
    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= uint256(marketInfo.startTime) && block.timestamp <= uint256(marketInfo.endTime),
            "HyperbolicAuction: outside auction hours"
        );
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "HyperbolicAuction: auction already finalized");

        uint256 newCommitment = commitments[_addr].add(_commitment);
        if (status.usePointList) {
            require(IPointList(pointList).hasPoints(_addr, newCommitment));
        }

        commitments[_addr] = newCommitment;
        status.commitmentsTotal = BoringMath.to128(uint256(status.commitmentsTotal).add(_commitment));
        emit AddedCommitment(_addr, _commitment);
    }

    ///--------------------------------------------------------
    /// Finalize Auction
    ///--------------------------------------------------------

    /**
     * @notice Successful if tokens sold equals totalTokens.
     * @return True if tokenPrice is bigger or equal clearingPrice.
     */
    function auctionSuccessful() public view returns (bool) {
        return tokenPrice() >= clearingPrice();
    }

    /**
     * @notice Checks if the auction has ended.
     * @return True if auction is successful or time has ended.
     */
    function auctionEnded() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return auctionSuccessful() || block.timestamp > uint256(marketInfo.endTime);
    }

    /**
     * @return Returns true if market has been finalized
     */
    function finalized() public view returns (bool) {
        return marketStatus.finalized;
    }

    /**
     * @return Returns true if 7 days have passed since the end of the auction
     */
    function finalizeTimeExpired() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return uint256(marketInfo.endTime) + 7 days < block.timestamp;
    }

    /**
     * @notice Auction finishes successfully above the reserve
     * @dev Transfer contract funds to initialized wallet.
     */
    function finalize() public nonReentrant {
        require(
            hasAdminRole(msg.sender) ||
                wallet == msg.sender ||
                hasSmartContractRole(msg.sender) ||
                finalizeTimeExpired(),
            "HyperbolicAuction: sender must be an admin"
        );
        MarketStatus storage status = marketStatus;
        MarketInfo storage info = marketInfo;
        require(info.totalTokens > 0, "Not initialized");

        require(!status.finalized, "HyperbolicAuction: auction already finalized");
        if (auctionSuccessful()) {
            /// @dev Successful auction
            /// @dev Transfer contributed tokens to wallet.
            _safeTokenPayment(paymentCurrency, wallet, uint256(status.commitmentsTotal));
        } else {
            /// @dev Failed auction
            /// @dev Return auction tokens back to wallet.
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp > uint256(info.endTime), "HyperbolicAuction: auction has not finished yet");
            _safeTokenPayment(auctionToken, wallet, uint256(info.totalTokens));
        }
        status.finalized = true;
        emit AuctionFinalized();
    }

    /**
     * @notice Cancel Auction
     * @dev Admin can cancel the auction before it starts
     */
    function cancelAuction() public nonReentrant {
        require(hasAdminRole(msg.sender));
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "HyperbolicAuction: auction already finalized");
        require(uint256(status.commitmentsTotal) == 0, "HyperbolicAuction: auction already committed");

        _safeTokenPayment(auctionToken, wallet, uint256(marketInfo.totalTokens));

        status.finalized = true;
        emit AuctionCancelled();
    }

    /**
     * @notice How many tokens the user is able to claim.
     * @param _user Auction participant address.
     * @return claimerCommitment User commitments reduced by already claimed tokens.
     */
    function tokensClaimable(address _user) public view returns (uint256 claimerCommitment) {
        if (commitments[_user] == 0) return 0;
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));
        claimerCommitment = commitments[_user].mul(uint256(marketInfo.totalTokens)).div(
            uint256(marketStatus.commitmentsTotal)
        );
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    /// @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
    function withdrawTokens() public {
        withdrawTokens(msg.sender);
    }

    /// @notice Withdraw your tokens once the Auction has ended.
    function withdrawTokens(address payable beneficiary) public nonReentrant {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "HyperbolicAuction: not finalized");
            /// @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "HyperbolicAuction: no tokens to claim");
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);

            _safeTokenPayment(auctionToken, beneficiary, tokensToClaim);
        } else {
            /// @dev Auction did not meet reserve price.
            /// @dev Return committed funds back to user.
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp > uint256(marketInfo.endTime), "HyperbolicAuction: auction has not finished yet");
            uint256 fundsCommitted = commitments[beneficiary];
            commitments[beneficiary] = 0; // Stop multiple withdrawals and free some gas
            _safeTokenPayment(paymentCurrency, beneficiary, fundsCommitted);
        }
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(string calldata _name, string calldata _data) external {
        require(hasAdminRole(msg.sender));
        _setDocument(_name, _data);
    }

    function setDocuments(string[] calldata _name, string[] calldata _data) external {
        require(hasAdminRole(msg.sender));
        uint256 numDocs = _name.length;
        for (uint256 i = 0; i < numDocs; i++) {
            _setDocument(_name[i], _data[i]);
        }
    }

    function removeDocument(string calldata _name) external {
        require(hasAdminRole(msg.sender));
        _removeDocument(_name);
    }

    //--------------------------------------------------------
    // Point Lists
    //--------------------------------------------------------

    function setList(address _list) external {
        require(hasAdminRole(msg.sender));
        _setList(_list);
    }

    function enableList(bool _status) external {
        require(hasAdminRole(msg.sender));
        marketStatus.usePointList = _status;

        emit AuctionPointListUpdated(pointList, marketStatus.usePointList);
    }

    function _setList(address _pointList) private {
        if (_pointList != address(0)) {
            pointList = _pointList;
            marketStatus.usePointList = true;
        }

        emit AuctionPointListUpdated(pointList, marketStatus.usePointList);
    }

    //--------------------------------------------------------
    // Setter Functions
    //--------------------------------------------------------

    /**
     * @notice Admin can set start and end time through this function.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     */
    function setAuctionTime(uint256 _startTime, uint256 _endTime) external {
        require(hasAdminRole(msg.sender));
        require(_startTime < 10000000000, "HyperbolicAuction: enter an unix timestamp in seconds, not miliseconds");
        require(_endTime < 10000000000, "HyperbolicAuction: enter an unix timestamp in seconds, not miliseconds");
        // solhint-disable-next-line not-rely-on-time
        require(_startTime >= block.timestamp, "HyperbolicAuction: start time is before current time");
        require(_endTime > _startTime, "HyperbolicAuction: end time must be older than start price");
        require(marketStatus.commitmentsTotal == 0, "HyperbolicAuction: auction cannot have already started");

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);

        uint64 _duration = marketInfo.endTime - marketInfo.startTime;
        uint256 _alpha = uint256(_duration).mul(uint256(marketPrice.minimumPrice));
        marketPrice.alpha = BoringMath.to128(_alpha);

        emit AuctionTimeUpdated(_startTime, _endTime);
    }

    /**
     * @notice Admin can set start and min price through this function.
     * @param _minimumPrice Auction minimum price.
     */
    function setAuctionPrice(uint256 _minimumPrice) external {
        require(hasAdminRole(msg.sender));
        require(_minimumPrice > 0, "HyperbolicAuction: minimum price must be greater than 0");
        require(marketStatus.commitmentsTotal == 0, "HyperbolicAuction: auction cannot have already started");

        marketPrice.minimumPrice = BoringMath.to128(_minimumPrice);

        uint64 _duration = marketInfo.endTime - marketInfo.startTime;
        uint256 _alpha = uint256(_duration).mul(uint256(marketPrice.minimumPrice));
        marketPrice.alpha = BoringMath.to128(_alpha);

        emit AuctionPriceUpdated(_minimumPrice);
    }

    /**
     * @notice Admin can set the auction wallet through this function.
     * @param _wallet Auction wallet is where funds will be sent.
     */
    function setAuctionWallet(address payable _wallet) external {
        require(hasAdminRole(msg.sender));
        require(_wallet != address(0), "HyperbolicAuction: wallet is the zero address");

        wallet = _wallet;

        emit AuctionWalletUpdated(_wallet);
    }

    ///--------------------------------------------------------
    /// Market Launchers
    ///--------------------------------------------------------

    function init(bytes calldata _data) external payable override {}

    /**
     * @notice Decodes and hands auction data to the initAuction function.
     * @param _data Encoded data for initialization.
     */
    function initMarket(bytes calldata _data) public override {
        (
            address _funder,
            address _token,
            uint256 _totalTokens,
            uint256 _startTime,
            uint256 _endTime,
            address _paymentCurrency,
            uint24 _fee,
            uint256 _factor,
            uint256 _minimumPrice,
            address _admin,
            address _pointList,
            address payable _wallet
        ) = abi.decode(
                _data,
                (
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    uint24,
                    uint256,
                    uint256,
                    address,
                    address,
                    address
                )
            );
        initAuction(
            _funder,
            _token,
            _totalTokens,
            _startTime,
            _endTime,
            _paymentCurrency,
            _fee,
            _factor,
            _minimumPrice,
            _admin,
            _pointList,
            _wallet
        );
    }

    /**
     * @notice Collects data to initialize the auction and encodes them.
     * @param _funder The address that funds the token for HyperbolicAuction.
     * @param _token Address of the token being sold.
     * @param _totalTokens The total number of tokens to sell in auction.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     * @param _paymentCurrency The currency the HyperbolicAuction accepts for payment. Can be ETH or token address.
     * @param _factor Inflection point of the auction.
     * @param _minimumPrice The minimum auction price.
     * @param _wallet Address where collected funds will be forwarded to.
     * @return _data All the data in bytes format.
     */
    function getAuctionInitData(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint24 _fee,
        uint256 _factor,
        uint256 _minimumPrice,
        address _admin,
        address _pointList,
        address payable _wallet
    ) external pure returns (bytes memory _data) {
        return
            abi.encode(
                _funder,
                _token,
                _totalTokens,
                _startTime,
                _endTime,
                _paymentCurrency,
                _fee,
                _factor,
                _minimumPrice,
                _admin,
                _pointList,
                _wallet
            );
    }

    function getBaseInformation() external view returns (address, uint64, uint64, bool) {
        return (auctionToken, marketInfo.startTime, marketInfo.endTime, marketStatus.finalized);
    }

    function getTotalTokens() external view returns (uint256) {
        return uint256(marketInfo.totalTokens);
    }
}

pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";
import "../OpenZeppelin/token/ERC20/SafeERC20.sol";
import "../OpenZeppelin/utils/EnumerableSet.sol";
import "../OpenZeppelin/math/SafeMath.sol";
import "../OpenZeppelin/access/Ownable.sol";

import "../Access/IHubAccessControls.sol";
import "../interfaces/IIHubFarm.sol";
import "../Utils/SafeTransfer.sol";

// MasterCore is the master of Rewards. He can make Rewards and he is a fair guy.
//
// Note that its ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once tokens are sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully its bug-free. God bless.
//
// IHub Update - Removed LP migrator
// IHub Update - Removed minter - Contract holds token
// IHub Update - Dev tips parameterised
// IHub Update - Replaced owner with access controls
// IHub Update - Added SafeTransfer

contract IHubMasterCore is IIHubFarm, IHubAccessControls, SafeTransfer {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Heres what happens:
        //   1. The pools `accRewardsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. Users `amount` gets updated.
        //   4. Users `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 accRewardsPerShare; // Accumulated tokens per share, times 1e12. See below.
    }

    // The rewards token
    IERC20 public rewards;
    // Dev address.
    address public devaddr;
    // Percentage amount to be tipped to devs.
    uint256 public devPercentage;
    // Tips owed to develpers.
    uint256 public tips;
    // uint256 public devPaid;

    // Block number when bonus tokens period ends.
    uint256 public bonusEndBlock;
    // Reward tokens created per block.
    uint256 public rewardsPerBlock;
    // Bonus muliplier for early rewards makers.
    uint256 public bonusMultiplier;
    // Total rewards debt.
    uint256 public totalRewardDebt;

    // IHubFarmFactory template id
    uint256 public constant override farmTemplate = 1;
    // For initial setup
    bool private initialised;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when rewards mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function initFarm(
        address _rewards,
        uint256 _rewardsPerBlock,
        uint256 _startBlock,
        address _devaddr,
        address _admin
    ) public {
        require(!initialised);
        rewards = IERC20(_rewards);
        totalAllocPoint = 0;
        rewardsPerBlock = _rewardsPerBlock;
        startBlock = _startBlock;
        devaddr = _devaddr;
        initAccessControls(_admin);
        initialised = true;
    }

    function initFarm(bytes calldata _data) public override {
        (address _rewards, uint256 _rewardsPerBlock, uint256 _startBlock, address _devaddr, address _admin) = abi
            .decode(_data, (address, uint256, uint256, address, address));
        initFarm(_rewards, _rewardsPerBlock, _startBlock, _devaddr, _admin);
    }

    /**
     * @dev Generates init data for Farm Factory
     * @param _rewards Rewards token address
     * @param _rewardsPerBlock - Rewards per block for the whole farm
     * @param _startBlock - Starting block
     * @param _divaddr Any donations if set are sent here
     * @param _accessControls Gives right to access
     */
    function getInitData(
        address _rewards,
        uint256 _rewardsPerBlock,
        uint256 _startBlock,
        address _divaddr,
        address _accessControls
    ) external pure returns (bytes memory _data) {
        return abi.encode(_rewards, _rewardsPerBlock, _startBlock, _divaddr, _accessControls);
    }

    function setBonus(uint256 _bonusEndBlock, uint256 _bonusMultiplier) public {
        require(hasAdminRole(msg.sender), "MasterCore.setBonus: Sender must be admin");

        bonusEndBlock = _bonusEndBlock;
        bonusMultiplier = _bonusMultiplier;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addToken(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public {
        require(hasAdminRole(msg.sender), "MasterCore.addToken: Sender must be admin");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardsPerShare: 0
            })
        );
    }

    // Update the given pools token allocation point. Can only be called by the operator.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public {
        require(hasOperatorRole(msg.sender), "MasterCore.set: Sender must be admin");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 remaining = blocksRemaining();
        uint multiplier = 0;
        if (remaining == 0) {
            return 0;
        }
        if (_to <= bonusEndBlock) {
            multiplier = _to.sub(_from).mul(bonusMultiplier);
        } else if (_from >= bonusEndBlock) {
            multiplier = _to.sub(_from);
        } else {
            multiplier = bonusEndBlock.sub(_from).mul(bonusMultiplier).add(_to.sub(bonusEndBlock));
        }

        if (multiplier > remaining) {
            multiplier = remaining;
        }
        return multiplier;
    }

    // View function to see pending tokens on frontend.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rewardsAccum = multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardsPerShare = accRewardsPerShare.add(rewardsAccum.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accRewardsPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardsAccum = multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        if (devPercentage > 0) {
            tips = tips.add(rewardsAccum.mul(devPercentage).div(1000));
        }
        totalRewardDebt = totalRewardDebt.add(rewardsAccum);
        pool.accRewardsPerShare = pool.accRewardsPerShare.add(rewardsAccum.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterCore for rewards allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                totalRewardDebt = totalRewardDebt.sub(pending);
                safeRewardsTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterCore.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            totalRewardDebt = totalRewardDebt.sub(pending);
            safeRewardsTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe rewards transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeRewardsTransfer(address _to, uint256 _amount) internal {
        uint256 rewardsBal = rewards.balanceOf(address(this));
        if (_amount > rewardsBal) {
            _safeTransfer(address(rewards), _to, rewardsBal);
        } else {
            _safeTransfer(address(rewards), _to, _amount);
        }
    }

    function tokensRemaining() public view returns (uint256) {
        return rewards.balanceOf(address(this));
    }

    function tokenDebt() public view returns (uint256) {
        return totalRewardDebt.add(tips);
    }

    // Returns the number of blocks remaining with the current rewards balance
    function blocksRemaining() public view returns (uint256) {
        if (tokensRemaining() <= tokenDebt()) {
            return 0;
        }
        uint256 rewardsBal = tokensRemaining().sub(tokenDebt());
        if (rewardsPerBlock > 0) {
            if (devPercentage > 0) {
                rewardsBal = rewardsBal.mul(1000).div(devPercentage.add(1000));
            }
            return rewardsBal / rewardsPerBlock;
        } else {
            return 0;
        }
    }

    // Claims any rewards for the developers, if set
    function claimTips() public {
        require(msg.sender == devaddr, "dev: wut?");
        require(tips > 0, "dev: broke");
        uint256 claimable = tips;
        // devPaid = devPaid.add(claimable);
        tips = 0;
        safeRewardsTransfer(devaddr, claimable);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Update dev percentage.
    function setDevPercentage(uint256 _devPercentage) public {
        require(msg.sender == devaddr, "dev: wut?");
        devPercentage = _devPercentage;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Access/IHubAccessControls.sol";

//==================
//    Documents
//==================

interface IDocument {
    function getDocument(string calldata _name) external view returns (string memory, uint256);

    function getDocumentCount() external view returns (uint256);

    function getDocumentName(uint256 index) external view returns (string memory);
}

contract DocumentHepler {
    struct Document {
        string name;
        string data;
        uint256 lastModified;
    }

    function getDocuments(address _document) public view returns (Document[] memory) {
        IDocument document = IDocument(_document);
        uint256 documentCount = document.getDocumentCount();

        Document[] memory documents = new Document[](documentCount);

        for (uint256 i = 0; i < documentCount; i++) {
            string memory documentName = document.getDocumentName(i);
            (documents[i].data, documents[i].lastModified) = document.getDocument(documentName);
            documents[i].name = documentName;
        }
        return documents;
    }
}

//==================
//     Tokens
//==================

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IIHubTokenFactory {
    function getTokens() external view returns (address[] memory);

    function tokens(uint256) external view returns (address);

    function numberOfTokens() external view returns (uint256);
}

contract TokenHelper {
    struct TokenInfo {
        address addr;
        uint256 decimals;
        string name;
        string symbol;
    }

    function getTokensInfo(address[] memory addresses) public view returns (TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            infos[i] = getTokenInfo(addresses[i]);
        }

        return infos;
    }

    function getTokenInfo(address _address) public view returns (TokenInfo memory) {
        TokenInfo memory info;
        IERC20 token = IERC20(_address);

        info.addr = _address;
        info.name = token.name();
        info.symbol = token.symbol();
        info.decimals = token.decimals();

        return info;
    }

    function allowance(address _token, address _owner, address _spender) public view returns (uint256) {
        return IERC20(_token).allowance(_owner, _spender);
    }
}

//==================
//      Base
//==================

contract BaseHelper {
    IIHubMarketFactory public market;
    IIHubTokenFactory public tokenFactory;
    IIHubFarmFactory public farmFactory;
    address public launcher;

    /// @notice Responsible for access rights to the contract
    IHubAccessControls public accessControls;

    function setContracts(address _tokenFactory, address _market, address _launcher, address _farmFactory) public {
        require(accessControls.hasAdminRole(msg.sender), "IHubHelper: Sender must be Admin");
        if (_market != address(0)) {
            market = IIHubMarketFactory(_market);
        }
        if (_tokenFactory != address(0)) {
            tokenFactory = IIHubTokenFactory(_tokenFactory);
        }
        if (_launcher != address(0)) {
            launcher = _launcher;
        }
        if (_farmFactory != address(0)) {
            farmFactory = IIHubFarmFactory(_farmFactory);
        }
    }
}

//==================
//      Farms
//==================

interface IIHubFarmFactory {
    function getTemplateId(address _farm) external view returns (uint256);

    function numberOfFarms() external view returns (uint256);

    function farms(uint256 _farmId) external view returns (address);
}

interface IFarm {
    function poolInfo(
        uint256 pid
    ) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accRewardsPerShare);

    function rewards() external view returns (address);

    function poolLength() external view returns (uint256);

    function rewardsPerBlock() external view returns (uint256);

    function bonusMultiplier() external view returns (uint256);

    function userInfo(uint256 pid, address _user) external view returns (uint256, uint256);

    function pendingRewards(uint256 _pid, address _user) external view returns (uint256);
}

contract FarmHelper is BaseHelper, TokenHelper {
    struct FarmInfo {
        address addr;
        uint256 templateId;
        uint256 rewardsPerBlock;
        uint256 bonusMultiplier;
        TokenInfo rewardToken;
        PoolInfo[] pools;
    }

    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardsPerShare;
        uint256 totalStaked;
        TokenInfo stakingToken;
    }

    struct UserPoolInfo {
        address farm;
        uint256 pid;
        uint256 totalStaked;
        uint256 lpBalance;
        uint256 lpAllowance;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct UserPoolsInfo {
        address farm;
        uint256[] pids;
        uint256[] totalStaked;
        uint256[] pendingRewards;
    }

    function getPools(address _farm) public view returns (PoolInfo[] memory) {
        IFarm farm = IFarm(_farm);
        uint256 poolLength = farm.poolLength();
        PoolInfo[] memory pools = new PoolInfo[](poolLength);

        for (uint256 i = 0; i < poolLength; i++) {
            (pools[i].lpToken, pools[i].allocPoint, pools[i].lastRewardBlock, pools[i].accRewardsPerShare) = farm
                .poolInfo(i);
            pools[i].totalStaked = IERC20(pools[i].lpToken).balanceOf(_farm);
            pools[i].stakingToken = getTokenInfo(pools[i].lpToken);
        }
        return pools;
    }

    function getFarms() public view returns (FarmInfo[] memory) {
        uint256 numberOfFarms = farmFactory.numberOfFarms();

        FarmInfo[] memory infos = new FarmInfo[](numberOfFarms);

        for (uint256 i = 0; i < numberOfFarms; i++) {
            address farmAddr = farmFactory.farms(i);
            uint256 templateId = farmFactory.getTemplateId(farmAddr);
            infos[i] = _farmInfo(farmAddr);
        }

        return infos;
    }

    function getFarms(uint256 pageSize, uint256 pageNbr, uint256 offset) public view returns (FarmInfo[] memory) {
        uint256 numberOfFarms = farmFactory.numberOfFarms();
        uint256 startIdx = (pageNbr * pageSize) + offset;
        uint256 endIdx = startIdx + pageSize;

        FarmInfo[] memory infos;

        if (endIdx > numberOfFarms) {
            endIdx = numberOfFarms;
        }
        if (endIdx < startIdx) {
            return infos;
        }
        infos = new FarmInfo[](endIdx - startIdx);

        for (uint256 farmIdx = 0; farmIdx + startIdx < endIdx; farmIdx++) {
            address farmAddr = farmFactory.farms(farmIdx + startIdx);
            infos[farmIdx] = _farmInfo(farmAddr);
        }

        return infos;
    }

    function getFarms(uint256 pageSize, uint256 pageNbr) public view returns (FarmInfo[] memory) {
        return getFarms(pageSize, pageNbr, 0);
    }

    function _farmInfo(address _farmAddr) private view returns (FarmInfo memory farmInfo) {
        IFarm farm = IFarm(_farmAddr);

        farmInfo.addr = _farmAddr;
        farmInfo.templateId = farmFactory.getTemplateId(_farmAddr);
        farmInfo.rewardsPerBlock = farm.rewardsPerBlock();
        farmInfo.bonusMultiplier = farm.bonusMultiplier();
        farmInfo.rewardToken = getTokenInfo(farm.rewards());
        farmInfo.pools = getPools(_farmAddr);
    }

    function getFarmDetail(
        address _farm,
        address _user
    ) public view returns (FarmInfo memory farmInfo, UserPoolInfo[] memory userInfos) {
        IFarm farm = IFarm(_farm);
        farmInfo.addr = _farm;
        farmInfo.templateId = farmFactory.getTemplateId(_farm);
        farmInfo.rewardsPerBlock = farm.rewardsPerBlock();
        farmInfo.bonusMultiplier = farm.bonusMultiplier();
        farmInfo.rewardToken = getTokenInfo(farm.rewards());
        farmInfo.pools = getPools(_farm);

        if (_user != address(0)) {
            PoolInfo[] memory pools = farmInfo.pools;
            userInfos = new UserPoolInfo[](pools.length);
            for (uint i = 0; i < pools.length; i++) {
                UserPoolInfo memory userInfo = userInfos[i];
                address stakingToken = pools[i].stakingToken.addr;
                (userInfo.totalStaked, userInfo.rewardDebt) = farm.userInfo(i, _user);
                userInfo.lpBalance = IERC20(stakingToken).balanceOf(_user);
                userInfo.lpAllowance = IERC20(stakingToken).allowance(_user, _farm);
                userInfo.pendingRewards = farm.pendingRewards(i, _user);
                (userInfo.totalStaked, ) = farm.userInfo(i, _user);
                userInfo.farm = _farm;
                userInfo.pid = i;
                userInfos[i] = userInfo;
            }
        }
        return (farmInfo, userInfos);
    }

    function getUserPoolsInfos(address _user) public view returns (UserPoolsInfo[] memory) {
        uint256 numberOfFarms = farmFactory.numberOfFarms();

        UserPoolsInfo[] memory infos = new UserPoolsInfo[](numberOfFarms);

        for (uint256 i = 0; i < numberOfFarms; i++) {
            address farmAddr = farmFactory.farms(i);
            IFarm farm = IFarm(farmAddr);
            uint256 poolLength = farm.poolLength();
            uint256[] memory totalStaked = new uint256[](poolLength);
            uint256[] memory pendingRewards = new uint256[](poolLength);
            uint256[] memory pids = new uint256[](poolLength);

            for (uint256 j = 0; j < poolLength; j++) {
                (address stakingToken, , , ) = farm.poolInfo(j);
                (totalStaked[j], ) = farm.userInfo(j, _user);
                pendingRewards[j] = farm.pendingRewards(j, _user);
                pids[j] = j;
            }
            infos[i].totalStaked = totalStaked;
            infos[i].pendingRewards = pendingRewards;
            infos[i].pids = pids;
            infos[i].farm = farmAddr;
        }
        return infos;
    }
}

//==================
//     Markets
//==================

interface IBaseAuction {
    function getBaseInformation()
        external
        view
        returns (address auctionToken, uint64 startTime, uint64 endTime, bool finalized);
}

interface IIHubMarketFactory {
    function getMarketTemplateId(address _auction) external view returns (uint64);

    function getMarkets() external view returns (address[] memory);

    function numberOfAuctions() external view returns (uint256);

    function auctions(uint256) external view returns (address);
}

interface IIHubMarket {
    function paymentCurrency() external view returns (address);

    function auctionToken() external view returns (address);

    function marketPrice() external view returns (uint128, uint128);

    function marketInfo() external view returns (uint64 startTime, uint64 endTime, uint128 totalTokens);

    function auctionSuccessful() external view returns (bool);

    function commitments(address user) external view returns (uint256);

    function claimed(address user) external view returns (uint256);

    function tokensClaimable(address user) external view returns (uint256);

    function hasAdminRole(address user) external view returns (bool);
}

interface ICrowdsale is IIHubMarket {
    function marketStatus() external view returns (uint128 commitmentsTotal, bool finalized, bool usePointList);
}

interface IDutchAuction is IIHubMarket {
    function marketStatus() external view returns (uint128 commitmentsTotal, bool finalized, bool usePointList);
    // function totalTokensCommitted() external view returns (uint256);
    // function clearingPrice() external view returns (uint256);
}

interface IBatchAuction is IIHubMarket {
    function marketStatus()
        external
        view
        returns (uint256 commitmentsTotal, uint256 minimumCommitmentAmount, bool finalized, bool usePointList);
}

interface IHyperbolicAuction is IIHubMarket {
    function marketStatus() external view returns (uint128 commitmentsTotal, bool finalized, bool usePointList);
}

contract MarketHelper is BaseHelper, TokenHelper, DocumentHepler {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct CrowdsaleInfo {
        address addr;
        address paymentCurrency;
        uint128 commitmentsTotal;
        uint128 totalTokens;
        uint128 rate;
        uint128 goal;
        uint64 startTime;
        uint64 endTime;
        bool finalized;
        bool usePointList;
        bool auctionSuccessful;
        TokenInfo tokenInfo;
        TokenInfo paymentCurrencyInfo;
        Document[] documents;
    }

    struct DutchAuctionInfo {
        address addr;
        address paymentCurrency;
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
        uint128 startPrice;
        uint128 minimumPrice;
        uint128 commitmentsTotal;
        // uint256 totalTokensCommitted;
        bool finalized;
        bool usePointList;
        bool auctionSuccessful;
        TokenInfo tokenInfo;
        TokenInfo paymentCurrencyInfo;
        Document[] documents;
    }

    struct BatchAuctionInfo {
        address addr;
        address paymentCurrency;
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
        uint256 commitmentsTotal;
        uint256 minimumCommitmentAmount;
        bool finalized;
        bool usePointList;
        bool auctionSuccessful;
        TokenInfo tokenInfo;
        TokenInfo paymentCurrencyInfo;
        Document[] documents;
    }

    struct HyperbolicAuctionInfo {
        address addr;
        address paymentCurrency;
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
        uint128 minimumPrice;
        uint128 alpha;
        uint128 commitmentsTotal;
        bool finalized;
        bool usePointList;
        bool auctionSuccessful;
        TokenInfo tokenInfo;
        TokenInfo paymentCurrencyInfo;
        Document[] documents;
    }

    struct MarketBaseInfo {
        address addr;
        uint64 templateId;
        uint64 startTime;
        uint64 endTime;
        bool finalized;
        TokenInfo tokenInfo;
    }

    struct PLInfo {
        TokenInfo token0;
        TokenInfo token1;
        address pairToken;
        address operator;
        uint256 locktime;
        uint256 unlock;
        uint256 deadline;
        uint256 launchwindow;
        uint256 expiry;
        uint256 liquidityAdded;
        uint256 launched;
    }

    struct UserMarketInfo {
        uint256 commitments;
        uint256 tokensClaimable;
        uint256 claimed;
        bool isAdmin;
    }

    function getMarkets(
        uint256 pageSize,
        uint256 pageNbr,
        uint256 offset
    ) public view returns (MarketBaseInfo[] memory) {
        uint256 marketsLength = market.numberOfAuctions();
        uint256 startIdx = (pageNbr * pageSize) + offset;
        uint256 endIdx = startIdx + pageSize;
        MarketBaseInfo[] memory infos;
        if (endIdx > marketsLength) {
            endIdx = marketsLength;
        }
        if (endIdx < startIdx) {
            return infos;
        }
        infos = new MarketBaseInfo[](endIdx - startIdx);

        for (uint256 marketIdx = 0; marketIdx + startIdx < endIdx; marketIdx++) {
            address marketAddress = market.auctions(marketIdx + startIdx);
            infos[marketIdx] = _getMarketInfo(marketAddress);
        }

        return infos;
    }

    function getMarkets(uint256 pageSize, uint256 pageNbr) public view returns (MarketBaseInfo[] memory) {
        return getMarkets(pageSize, pageNbr, 0);
    }

    function getMarkets() public view returns (MarketBaseInfo[] memory) {
        address[] memory markets = market.getMarkets();
        MarketBaseInfo[] memory infos = new MarketBaseInfo[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            MarketBaseInfo memory marketInfo = _getMarketInfo(markets[i]);
            infos[i] = marketInfo;
        }

        return infos;
    }

    function _getMarketInfo(address _marketAddress) private view returns (MarketBaseInfo memory marketInfo) {
        uint64 templateId = market.getMarketTemplateId(_marketAddress);
        address auctionToken;
        uint64 startTime;
        uint64 endTime;
        bool finalized;
        (auctionToken, startTime, endTime, finalized) = IBaseAuction(_marketAddress).getBaseInformation();
        TokenInfo memory tokenInfo = getTokenInfo(auctionToken);

        marketInfo.addr = _marketAddress;
        marketInfo.templateId = templateId;
        marketInfo.startTime = startTime;
        marketInfo.endTime = endTime;
        marketInfo.finalized = finalized;
        marketInfo.tokenInfo = tokenInfo;
    }

    function getCrowdsaleInfo(address _crowdsale) public view returns (CrowdsaleInfo memory) {
        ICrowdsale crowdsale = ICrowdsale(_crowdsale);
        CrowdsaleInfo memory info;

        info.addr = address(crowdsale);
        (info.commitmentsTotal, info.finalized, info.usePointList) = crowdsale.marketStatus();
        (info.startTime, info.endTime, info.totalTokens) = crowdsale.marketInfo();
        (info.rate, info.goal) = crowdsale.marketPrice();
        (info.auctionSuccessful) = crowdsale.auctionSuccessful();
        info.tokenInfo = getTokenInfo(crowdsale.auctionToken());

        address paymentCurrency = crowdsale.paymentCurrency();
        TokenInfo memory paymentCurrencyInfo;
        if (paymentCurrency == ETH_ADDRESS) {
            paymentCurrencyInfo = _getETHInfo();
        } else {
            paymentCurrencyInfo = getTokenInfo(paymentCurrency);
        }
        info.paymentCurrencyInfo = paymentCurrencyInfo;

        info.documents = getDocuments(_crowdsale);

        return info;
    }

    function getDutchAuctionInfo(address payable _dutchAuction) public view returns (DutchAuctionInfo memory) {
        IDutchAuction dutchAuction = IDutchAuction(_dutchAuction);
        DutchAuctionInfo memory info;

        info.addr = address(dutchAuction);
        (info.startTime, info.endTime, info.totalTokens) = dutchAuction.marketInfo();
        (info.startPrice, info.minimumPrice) = dutchAuction.marketPrice();
        (info.auctionSuccessful) = dutchAuction.auctionSuccessful();
        (info.commitmentsTotal, info.finalized, info.usePointList) = dutchAuction.marketStatus();
        info.tokenInfo = getTokenInfo(dutchAuction.auctionToken());

        address paymentCurrency = dutchAuction.paymentCurrency();
        TokenInfo memory paymentCurrencyInfo;
        if (paymentCurrency == ETH_ADDRESS) {
            paymentCurrencyInfo = _getETHInfo();
        } else {
            paymentCurrencyInfo = getTokenInfo(paymentCurrency);
        }
        info.paymentCurrencyInfo = paymentCurrencyInfo;
        info.documents = getDocuments(_dutchAuction);

        return info;
    }

    function getBatchAuctionInfo(address payable _batchAuction) public view returns (BatchAuctionInfo memory) {
        IBatchAuction batchAuction = IBatchAuction(_batchAuction);
        BatchAuctionInfo memory info;

        info.addr = address(batchAuction);
        (info.startTime, info.endTime, info.totalTokens) = batchAuction.marketInfo();
        (info.auctionSuccessful) = batchAuction.auctionSuccessful();
        (info.commitmentsTotal, info.minimumCommitmentAmount, info.finalized, info.usePointList) = batchAuction
            .marketStatus();
        info.tokenInfo = getTokenInfo(batchAuction.auctionToken());
        address paymentCurrency = batchAuction.paymentCurrency();
        TokenInfo memory paymentCurrencyInfo;
        if (paymentCurrency == ETH_ADDRESS) {
            paymentCurrencyInfo = _getETHInfo();
        } else {
            paymentCurrencyInfo = getTokenInfo(paymentCurrency);
        }
        info.paymentCurrencyInfo = paymentCurrencyInfo;
        info.documents = getDocuments(_batchAuction);

        return info;
    }

    function getHyperbolicAuctionInfo(
        address payable _hyperbolicAuction
    ) public view returns (HyperbolicAuctionInfo memory) {
        IHyperbolicAuction hyperbolicAuction = IHyperbolicAuction(_hyperbolicAuction);
        HyperbolicAuctionInfo memory info;

        info.addr = address(hyperbolicAuction);
        (info.startTime, info.endTime, info.totalTokens) = hyperbolicAuction.marketInfo();
        (info.minimumPrice, info.alpha) = hyperbolicAuction.marketPrice();
        (info.auctionSuccessful) = hyperbolicAuction.auctionSuccessful();
        (info.commitmentsTotal, info.finalized, info.usePointList) = hyperbolicAuction.marketStatus();
        info.tokenInfo = getTokenInfo(hyperbolicAuction.auctionToken());

        address paymentCurrency = hyperbolicAuction.paymentCurrency();
        TokenInfo memory paymentCurrencyInfo;
        if (paymentCurrency == ETH_ADDRESS) {
            paymentCurrencyInfo = _getETHInfo();
        } else {
            paymentCurrencyInfo = getTokenInfo(paymentCurrency);
        }
        info.paymentCurrencyInfo = paymentCurrencyInfo;
        info.documents = getDocuments(_hyperbolicAuction);

        return info;
    }

    function getUserMarketInfo(address _action, address _user) public view returns (UserMarketInfo memory userInfo) {
        IIHubMarket market = IIHubMarket(_action);
        userInfo.commitments = market.commitments(_user);
        userInfo.tokensClaimable = market.tokensClaimable(_user);
        userInfo.claimed = market.claimed(_user);
        userInfo.isAdmin = market.hasAdminRole(_user);
    }

    function _getETHInfo() private pure returns (TokenInfo memory token) {
        token.addr = ETH_ADDRESS;
        token.name = "SHIMMER";
        token.symbol = "SMR";
        token.decimals = 18;
    }
}

contract IHubHelper is MarketHelper, FarmHelper {
    constructor(
        address _accessControls,
        address _tokenFactory,
        address _market,
        address _launcher,
        address _farmFactory
    ) public {
        require(_accessControls != address(0));
        accessControls = IHubAccessControls(_accessControls);
        tokenFactory = IIHubTokenFactory(_tokenFactory);
        market = IIHubMarketFactory(_market);
        launcher = _launcher;
        farmFactory = IIHubFarmFactory(_farmFactory);
    }

    function getTokens() public view returns (TokenInfo[] memory) {
        address[] memory tokens = tokenFactory.getTokens();
        TokenInfo[] memory infos = getTokensInfo(tokens);

        infos = getTokensInfo(tokens);

        return infos;
    }

    function getTokens(uint256 pageSize, uint256 pageNbr, uint256 offset) public view returns (TokenInfo[] memory) {
        uint256 tokensLength = tokenFactory.numberOfTokens();

        uint256 startIdx = (pageNbr * pageSize) + offset;
        uint256 endIdx = startIdx + pageSize;
        TokenInfo[] memory infos;
        if (endIdx > tokensLength) {
            endIdx = tokensLength;
        }
        if (endIdx < startIdx) {
            return infos;
        }
        infos = new TokenInfo[](endIdx - startIdx);

        for (uint256 tokenIdx = 0; tokenIdx + startIdx < endIdx; tokenIdx++) {
            address tokenAddress = tokenFactory.tokens(tokenIdx + startIdx);
            infos[tokenIdx] = getTokenInfo(tokenAddress);
        }

        return infos;
    }

    function getTokens(uint256 pageSize, uint256 pageNbr) public view returns (TokenInfo[] memory) {
        return getTokens(pageSize, pageNbr, 0);
    }
}

pragma solidity 0.6.12;

// IHub Farm Factory
//
// A factory to conveniently deploy your own token farming contracts
//
// Inspired by Bokky's EtherVendingMachince.io
// https://github.com/bokkypoobah/FixedSupplyTokenFactory
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "./Utils/CloneFactory.sol";
import "./interfaces/IIHubFarm.sol";
import "./Access/IHubAccessControls.sol";

contract IHubFarmFactory is CloneFactory {
    /// @notice Responsible for access rights to the contract.
    IHubAccessControls public accessControls;
    bytes32 public constant FARM_MINTER_ROLE = keccak256("FARM_MINTER_ROLE");

    /// @notice Whether farm factory has been initialized or not.
    bool private initialised;
    /// @notice Contract locked status. If locked, only minters can deploy
    bool public locked;

    /// @notice Struct to track Farm template.
    struct Farm {
        bool exists;
        uint256 templateId;
        uint256 index;
    }

    /// @notice Mapping from auction created through this contract to Auction struct.
    mapping(address => Farm) public farmInfo;

    /// @notice Farms created using the factory.
    address[] public farms;

    /// @notice Template id to track respective farm template.
    uint256 public farmTemplateId;

    /// @notice Mapping from template id to farm template address.
    mapping(uint256 => address) private farmTemplates;

    /// @notice mapping from farm template address to farm template id
    mapping(address => uint256) private farmTemplateToId;

    // /// @notice mapping from template type to template id
    mapping(uint256 => uint256) public currentTemplateId;

    /// @notice Minimum fee to create a farm through the factory.
    uint256 public minimumFee;
    uint256 public integratorFeePct;

    /// @notice Any IHub dividends collected are sent here.
    address payable public iHubDiv;

    /// @notice Event emitted when first initializing the IHub Farm Factory.
    event IHubInitFarmFactory(address sender);

    /// @notice Event emitted when a farm is created using template id.
    event FarmCreated(address indexed owner, address indexed addr, address farmTemplate);

    /// @notice Event emitted when farm template is added to factory.
    event FarmTemplateAdded(address newFarm, uint256 templateId);

    /// @notice Event emitted when farm template is removed.
    event FarmTemplateRemoved(address farm, uint256 templateId);

    /**
     * @notice Single gateway to initialize the IHub Farm factory with proper address.
     * @dev Can only be initialized once
     * @param _accessControls Sets address to get the access controls from.
     * @param _iHubDiv Sets address to send the dividends.
     * @param _minimumFee Sets a minimum fee for creating farm in the factory.
     * @param _integratorFeePct Fee to UI integration
     */
    function initIHubFarmFactory(
        address _accessControls,
        address payable _iHubDiv,
        uint256 _minimumFee,
        uint256 _integratorFeePct
    ) external {
        /// @dev Maybe missing require message?
        require(!initialised);
        require(_iHubDiv != address(0));
        locked = true;
        initialised = true;
        iHubDiv = _iHubDiv;
        minimumFee = _minimumFee;
        integratorFeePct = _integratorFeePct;
        accessControls = IHubAccessControls(_accessControls);
        emit IHubInitFarmFactory(msg.sender);
    }

    /**
     * @notice Sets the minimum fee.
     * @param _amount Fee amount.
     */
    function setMinimumFee(uint256 _amount) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubFarmFactory: Sender must be operator");
        minimumFee = _amount;
    }

    /**
     * @notice Sets integrator fee percentage.
     * @param _amount Percentage amount.
     */
    function setIntegratorFeePct(uint256 _amount) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubFarmFactory: Sender must be operator");
        /// @dev this is out of 1000, ie 25% = 250
        require(_amount <= 1000, "IHubFarmFactory: Range is from 0 to 1000");
        integratorFeePct = _amount;
    }

    /**
     * @notice Sets dividend address.
     * @param _divaddr Dividend address.
     */
    function setDividends(address payable _divaddr) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubFarmFactory: Sender must be operator");
        require(_divaddr != address(0));
        iHubDiv = _divaddr;
    }

    /**
     * @notice Sets the factory to be locked or unlocked.
     * @param _locked bool.
     */
    function setLocked(bool _locked) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubFarmFactory: Sender must be admin");
        locked = _locked;
    }

    /**
     * @notice Sets the current template ID for any type.
     * @param _templateType Type of template.
     * @param _templateId The ID of the current template for that type
     */
    function setCurrentTemplateId(uint256 _templateType, uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubFarmFactory: Sender must be admin"
        );
        currentTemplateId[_templateType] = _templateId;
    }

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasFarmMinterRole(address _address) public view returns (bool) {
        return accessControls.hasRole(FARM_MINTER_ROLE, _address);
    }

    /**
     * @notice Deploys a farm corresponding to the _templateId and transfers fees.
     * @param _templateId Template id of the farm to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @return farm address.
     */
    function deployFarm(
        uint256 _templateId,
        address payable _integratorFeeAccount
    ) public payable returns (address farm) {
        /// @dev If the contract is locked, only admin and minters can deploy.
        if (locked) {
            require(
                accessControls.hasAdminRole(msg.sender) ||
                    accessControls.hasMinterRole(msg.sender) ||
                    hasFarmMinterRole(msg.sender),
                "IHubFarmFactory: Sender must be minter if locked"
            );
        }

        require(msg.value >= minimumFee, "IHubFarmFactory: Failed to transfer minimumFee");
        require(farmTemplates[_templateId] != address(0));
        uint256 integratorFee = 0;
        uint256 iHubFee = msg.value;
        if (_integratorFeeAccount != address(0) && _integratorFeeAccount != iHubDiv) {
            integratorFee = (iHubFee * integratorFeePct) / 1000;
            iHubFee = iHubFee - integratorFee;
        }
        farm = createClone(farmTemplates[_templateId]);
        farmInfo[address(farm)] = Farm(true, _templateId, farms.length);
        farms.push(address(farm));
        emit FarmCreated(msg.sender, address(farm), farmTemplates[_templateId]);
        if (iHubFee > 0) {
            iHubDiv.transfer(iHubFee);
        }
        if (integratorFee > 0) {
            _integratorFeeAccount.transfer(integratorFee);
        }
    }

    /**
     * @notice Creates a farm corresponding to the _templateId.
     * @dev Initializes farm with the parameters passed.
     * @param _templateId Template id of the farm to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @param _data Data to be passed to the farm contract for init.
     * @return farm address.
     */
    function createFarm(
        uint256 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address farm) {
        farm = deployFarm(_templateId, _integratorFeeAccount);
        IIHubFarm(farm).initFarm(_data);
    }

    /**
     * @notice Function to add a farm template to create through factory.
     * @dev Should have operator access.
     * @param _template Farm template address to create a farm.
     */
    function addFarmTemplate(address _template) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubFarmFactory: Sender must be operator"
        );
        require(farmTemplateToId[_template] == 0, "IHubFarmFactory: Template already added");
        uint256 templateType = IIHubFarm(_template).farmTemplate();
        require(templateType > 0, "IHubFarmFactory: Incorrect template code ");
        farmTemplateId++;
        farmTemplates[farmTemplateId] = _template;
        farmTemplateToId[_template] = farmTemplateId;
        currentTemplateId[templateType] = farmTemplateId;
        emit FarmTemplateAdded(_template, farmTemplateId);
    }

    /**
     * @notice Function to remove a farm template.
     * @dev Should have operator access.
     * @param _templateId Refers to template ID that is to be deleted.
     */
    function removeFarmTemplate(uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubFarmFactory: Sender must be operator"
        );
        require(farmTemplates[_templateId] != address(0));
        address template = farmTemplates[_templateId];
        farmTemplates[_templateId] = address(0);
        delete farmTemplateToId[template];
        emit FarmTemplateRemoved(template, _templateId);
    }

    /**
     * @notice Get the address based on template ID.
     * @param _farmTemplate Farm template ID.
     * @return Address of the required template ID.
     */
    function getFarmTemplate(uint256 _farmTemplate) external view returns (address) {
        return farmTemplates[_farmTemplate];
    }

    /**
     * @notice Get the ID based on template address.
     * @param _farmTemplate Farm template address.
     * @return ID of the required template address.
     */
    function getTemplateId(address _farmTemplate) external view returns (uint256) {
        return farmTemplateToId[_farmTemplate];
    }

    /**
     * @notice Get the total number of farms in the factory.
     * @return Farms count.
     */
    function numberOfFarms() external view returns (uint256) {
        return farms.length;
    }

    /**
     * @notice Get all farm created in the factory.
     * @return created farms.
     */
    function getFarms() external view returns (address[] memory) {
        return farms;
    }
}

pragma solidity 0.6.12;

// IHub Launcher
//
// A factory to conveniently deploy your own liquidity contracts
//
// Inspired by Bokky's EtherVendingMachince.io
// https://github.com/bokkypoobah/FixedSupplyTokenFactory
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "./Utils/SafeTransfer.sol";
import "./Utils/BoringMath.sol";
import "./Access/IHubAccessControls.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IIHubLiquidity.sol";
import "./interfaces/INeutronStarFactory.sol";
import "./OpenZeppelin/token/ERC20/SafeERC20.sol";

contract IHubLauncher is SafeTransfer {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using SafeERC20 for IERC20;

    /// @notice Responsible for access rights to the contract.
    IHubAccessControls public accessControls;
    bytes32 public constant LAUNCHER_MINTER_ROLE = keccak256("LAUNCHER_MINTER_ROLE");

    /// @notice Whether launcher has been initialized or not.
    bool private initialised;

    /// @notice Struct to track Auction template.
    struct Launcher {
        bool exists;
        uint64 templateId;
        uint128 index;
    }

    /// @notice All the launchers created using factory.
    address[] public launchers;

    /// @notice Template id to track respective auction template.
    uint256 public launcherTemplateId;

    INeutronStarFactory public neutronStar;

    /// @notice Mapping from template id to launcher template address.
    mapping(uint256 => address) private launcherTemplates;

    /// @notice mapping from launcher template address to launcher template id
    mapping(address => uint256) private launcherTemplateToId;

    // /// @notice mapping from template type to template id
    mapping(uint256 => uint256) public currentTemplateId;

    /// @notice Mapping from launcher created through this contract to Launcher struct.
    mapping(address => Launcher) public launcherInfo;

    /// @notice Struct to define fees.
    struct LauncherFees {
        uint128 minimumFee;
        uint32 integratorFeePct;
    }

    /// @notice Minimum fee to create a launcher through the factory.
    LauncherFees public launcherFees;

    /// @notice Contract locked status. If locked, only minters can deploy
    bool public locked;

    ///@notice Any donations if set are sent here.
    address payable public iHubDiv;

    /// @notice Event emitted when first intializing the liquidity launcher.
    event IHubInitLauncher(address sender);

    /// @notice Event emitted when launcher is created using template id.
    event LauncherCreated(address indexed owner, address indexed addr, address launcherTemplate);

    /// @notice Event emitted when launcher template is added to factory.
    event LauncherTemplateAdded(address newLauncher, uint256 templateId);

    /// @notice Event emitted when launcher template is removed.
    event LauncherTemplateRemoved(address launcher, uint256 templateId);

    constructor() public {}

    /**
     * @notice Single gateway to initialize the IHub Launcher with proper address.
     * @dev Can only be initialized once.
     * @param _accessControls Sets address to get the access controls from.
     */
    function initIHubLauncher(address _accessControls, address _neutronStar) external {
        require(!initialised);
        require(_accessControls != address(0), "initIHubLauncher: accessControls cannot be set to zero");
        require(_neutronStar != address(0), "initIHubLauncher: neutronStar cannot be set to zero");

        accessControls = IHubAccessControls(_accessControls);
        neutronStar = INeutronStarFactory(_neutronStar);
        locked = true;
        initialised = true;

        emit IHubInitLauncher(msg.sender);
    }

    /**
     * @notice Sets the minimum fee.
     * @param _amount Fee amount.
     */
    function setMinimumFee(uint256 _amount) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubLauncher: Sender must be operator");
        launcherFees.minimumFee = BoringMath.to128(_amount);
    }

    /**
     * @notice Sets integrator fee percentage.
     * @param _amount Percentage amount.
     */
    function setIntegratorFeePct(uint256 _amount) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubLauncher: Sender must be operator");
        /// @dev this is out of 1000, ie 25% = 250
        require(_amount <= 1000, "IHubLauncher: Percentage is out of 1000");
        launcherFees.integratorFeePct = BoringMath.to32(_amount);
    }

    /**
     * @notice Sets dividend address.
     * @param _divaddr Dividend address.
     */
    function setDividends(address payable _divaddr) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubLauncher: Sender must be operator");
        require(_divaddr != address(0));
        iHubDiv = _divaddr;
    }

    /**
     * @notice Sets the factory to be locked or unlocked.
     * @param _locked bool.
     */
    function setLocked(bool _locked) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubLauncher: Sender must be admin");
        locked = _locked;
    }

    /**
     * @notice Sets the current template ID for any type.
     * @param _templateType Type of template.
     * @param _templateId The ID of the current template for that type
     */
    function setCurrentTemplateId(uint256 _templateType, uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubLauncher: Sender must be Operator"
        );
        currentTemplateId[_templateType] = _templateId;
    }

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasLauncherMinterRole(address _address) public view returns (bool) {
        return accessControls.hasRole(LAUNCHER_MINTER_ROLE, _address);
    }

    /**
     * @notice Creates a launcher corresponding to _templateId.
     * @param _templateId Template id of the launcher to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @return launcher  Launcher address.
     */
    function deployLauncher(
        uint256 _templateId,
        address payable _integratorFeeAccount
    ) public payable returns (address launcher) {
        /// @dev If the contract is locked, only admin and minters can deploy.
        if (locked) {
            require(
                accessControls.hasAdminRole(msg.sender) ||
                    accessControls.hasMinterRole(msg.sender) ||
                    hasLauncherMinterRole(msg.sender),
                "IHubLauncher: Sender must be minter if locked"
            );
        }

        LauncherFees memory _launcherFees = launcherFees;
        address launcherTemplate = launcherTemplates[_templateId];
        require(msg.value >= uint256(_launcherFees.minimumFee), "IHubLauncher: Failed to transfer minimumFee");
        require(launcherTemplate != address(0), "IHubLauncher: Launcher template doesn't exist");
        uint256 integratorFee = 0;
        uint256 iHubFee = msg.value;
        if (_integratorFeeAccount != address(0) && _integratorFeeAccount != iHubDiv) {
            integratorFee = (iHubFee * uint256(_launcherFees.integratorFeePct)) / 1000;
            iHubFee = iHubFee - integratorFee;
        }
        /// @dev Deploy using the NeutronStar factory.
        launcher = neutronStar.deploy(launcherTemplate, "", false);
        launcherInfo[address(launcher)] = Launcher(
            true,
            BoringMath.to64(_templateId),
            BoringMath.to128(launchers.length)
        );
        launchers.push(address(launcher));
        emit LauncherCreated(msg.sender, address(launcher), launcherTemplates[_templateId]);
        if (iHubFee > 0) {
            iHubDiv.transfer(iHubFee);
        }
        if (integratorFee > 0) {
            _integratorFeeAccount.transfer(integratorFee);
        }
    }

    /**
     * @notice Creates a new IHubLauncher using _templateId.
     * @dev Initializes auction with the parameters passed.
     * @param _templateId Id of the auction template to create.
     * @param _token The token address to be sold.
     * @param _tokenSupply Amount of tokens to be sold at market.
     * @param _integratorFeeAccount Address to send refferal bonus, if set.
     * @param _data Data to be sent to template on Init.
     * @return newLauncher Launcher address.
     */
    function createLauncher(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newLauncher) {
        newLauncher = deployLauncher(_templateId, _integratorFeeAccount);
        if (_tokenSupply > 0) {
            _safeTransferFrom(_token, msg.sender, _tokenSupply);
            IERC20(_token).safeApprove(newLauncher, _tokenSupply);
        }
        IIHubLiquidity(newLauncher).initLauncher(_data);

        if (_tokenSupply > 0) {
            uint256 remainingBalance = IERC20(_token).balanceOf(address(this));
            if (remainingBalance > 0) {
                _safeTransfer(_token, msg.sender, remainingBalance);
            }
        }
        return newLauncher;
    }

    /**
     * @notice Function to add a launcher template to create through factory.
     * @dev Should have operator access
     * @param _template Launcher template address.
     */
    function addLiquidityLauncherTemplate(address _template) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubLauncher: Sender must be operator"
        );
        uint256 templateType = IIHubLiquidity(_template).liquidityTemplate();
        require(templateType > 0, "IHubLauncher: Incorrect template code");
        launcherTemplateId++;

        launcherTemplates[launcherTemplateId] = _template;
        launcherTemplateToId[_template] = launcherTemplateId;
        currentTemplateId[templateType] = launcherTemplateId;
        emit LauncherTemplateAdded(_template, launcherTemplateId);
    }

    /**
     * @dev Function to remove a launcher template from factory.
     * @dev Should have operator access.
     * @param _templateId Id of the template to be deleted.
     */
    function removeLiquidityLauncherTemplate(uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubLauncher: Sender must be operator"
        );
        require(launcherTemplates[_templateId] != address(0));
        address _template = launcherTemplates[_templateId];
        launcherTemplates[_templateId] = address(0);
        delete launcherTemplateToId[_template];
        uint256 templateType = IIHubLiquidity(_template).liquidityTemplate();
        if (currentTemplateId[templateType] == _templateId) {
            delete currentTemplateId[templateType];
        }
        emit LauncherTemplateRemoved(_template, _templateId);
    }

    /**
     * @notice Get the address based on launcher template ID.
     * @param _templateId Launcher template ID.
     * @return address of the required template ID.
     */
    function getLiquidityLauncherTemplate(uint256 _templateId) external view returns (address) {
        return launcherTemplates[_templateId];
    }

    function getTemplateId(address _launcherTemplate) external view returns (uint256) {
        return launcherTemplateToId[_launcherTemplate];
    }

    /**
     * @notice Get the total number of launchers in the contract.
     * @return uint256 Launcher count.
     */
    function numberOfLiquidityLauncherContracts() external view returns (uint256) {
        return launchers.length;
    }

    function minimumFee() external view returns (uint128) {
        return launcherFees.minimumFee;
    }

    function getLauncherTemplateId(address _launcher) external view returns (uint64) {
        return launcherInfo[_launcher].templateId;
    }

    function getLaunchers() external view returns (address[] memory) {
        return launchers;
    }
}

pragma solidity 0.6.12;

// IHub Marketplace
//
// A factory to conveniently deploy your own source code verified auctions
//
// Inspired by Bokky's EtherVendingMachince.io
// https://github.com/bokkypoobah/FixedSupplyTokenFactory
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "./Access/IHubAccessControls.sol";
import "./Utils/BoringMath.sol";
import "./Utils/SafeTransfer.sol";
import "./interfaces/IIHubMarket.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/INeutronStarFactory.sol";
import "./OpenZeppelin/token/ERC20/SafeERC20.sol";

contract IHubMarket is SafeTransfer {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using SafeERC20 for IERC20;

    /// @notice Responsible for access rights to the contract.
    IHubAccessControls public accessControls;
    bytes32 public constant MARKET_MINTER_ROLE = keccak256("MARKET_MINTER_ROLE");

    /// @notice Whether market has been initialized or not.
    bool private initialised;

    /// @notice Struct to track Auction template.
    struct Auction {
        bool exists;
        uint64 templateId;
        uint128 index;
    }

    /// @notice Auctions created using factory.
    address[] public auctions;

    /// @notice Template id to track respective auction template.
    uint256 public auctionTemplateId;

    INeutronStarFactory public neutronStar;

    /// @notice Mapping from market template id to market template address.
    mapping(uint256 => address) private auctionTemplates;

    /// @notice Mapping from market template address to market template id.
    mapping(address => uint256) private auctionTemplateToId;

    // /// @notice mapping from template type to template id
    mapping(uint256 => uint256) public currentTemplateId;

    /// @notice Mapping from auction created through this contract to Auction struct.
    mapping(address => Auction) public auctionInfo;

    /// @notice Struct to define fees.
    struct MarketFees {
        uint128 minimumFee;
        uint32 integratorFeePct;
    }

    /// @notice Minimum fee to create a farm through the factory.
    MarketFees public marketFees;

    /// @notice Contract locked status. If locked, only minters can deploy
    bool public locked;

    ///@notice Any donations if set are sent here.
    address payable public iHubDiv;

    ///@notice Event emitted when first initializing the Market factory.
    event IHubInitMarket(address sender);

    /// @notice Event emitted when template is added to factory.
    event AuctionTemplateAdded(address newAuction, uint256 templateId);

    /// @notice Event emitted when auction template is removed.
    event AuctionTemplateRemoved(address auction, uint256 templateId);

    /// @notice Event emitted when auction is created using template id.
    event MarketCreated(address indexed owner, address indexed addr, address marketTemplate);

    constructor() public {}

    /**
     * @notice Initializes the market with a list of auction templates.
     * @dev Can only be initialized once.
     * @param _accessControls Sets address to get the access controls from.
     * @param _templates Initial array of IHubMarket templates.
     */
    function initIHubMarket(address _accessControls, address _neutronStar, address[] memory _templates) external {
        require(!initialised);
        require(_accessControls != address(0), "initIHubMarket: accessControls cannot be set to zero");
        require(_neutronStar != address(0), "initIHubMarket: neutronStar cannot be set to zero");

        accessControls = IHubAccessControls(_accessControls);
        neutronStar = INeutronStarFactory(_neutronStar);

        for (uint i = 0; i < _templates.length; i++) {
            _addAuctionTemplate(_templates[i]);
        }
        locked = true;
        initialised = true;
        emit IHubInitMarket(msg.sender);
    }

    /**
     * @notice Sets the minimum fee.
     * @param _amount Fee amount.
     */
    function setMinimumFee(uint256 _amount) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubMarket: Sender must be operator");
        marketFees.minimumFee = BoringMath.to128(_amount);
    }

    /**
     * @notice Sets the factory to be locked or unlocked.
     * @param _locked bool.
     */
    function setLocked(bool _locked) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubMarket: Sender must be admin");
        locked = _locked;
    }

    /**
     * @notice Sets integrator fee percentage.
     * @param _amount Percentage amount.
     */
    function setIntegratorFeePct(uint256 _amount) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubMarket: Sender must be operator");
        /// @dev this is out of 1000, ie 25% = 250
        require(_amount <= 1000, "IHubMarket: Percentage is out of 1000");
        marketFees.integratorFeePct = BoringMath.to32(_amount);
    }

    /**
     * @notice Sets dividend address.
     * @param _divaddr Dividend address.
     */
    function setDividends(address payable _divaddr) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubMarket.setDev: Sender must be operator");
        require(_divaddr != address(0));
        iHubDiv = _divaddr;
    }

    /**
     * @notice Sets the current template ID for any type.
     * @param _templateType Type of template.
     * @param _templateId The ID of the current template for that type
     */
    function setCurrentTemplateId(uint256 _templateType, uint256 _templateId) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubMarket: Sender must be admin");
        require(auctionTemplates[_templateId] != address(0), "IHubMarket: incorrect _templateId");
        require(
            IIHubMarket(auctionTemplates[_templateId]).marketTemplate() == _templateType,
            "IHubMarket: incorrect _templateType"
        );
        currentTemplateId[_templateType] = _templateId;
    }

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasMarketMinterRole(address _address) public view returns (bool) {
        return accessControls.hasRole(MARKET_MINTER_ROLE, _address);
    }

    /**
     * @notice Creates a new IHubMarket from template _templateId and transfers fees.
     * @param _templateId Id of the crowdsale template to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @return newMarket Market address.
     */
    function deployMarket(
        uint256 _templateId,
        address payable _integratorFeeAccount
    ) public payable returns (address newMarket) {
        /// @dev If the contract is locked, only admin and minters can deploy.
        if (locked) {
            require(
                accessControls.hasAdminRole(msg.sender) ||
                    accessControls.hasMinterRole(msg.sender) ||
                    hasMarketMinterRole(msg.sender),
                "IHubMarket: Sender must be minter if locked"
            );
        }

        MarketFees memory _marketFees = marketFees;
        address auctionTemplate = auctionTemplates[_templateId];
        require(msg.value >= uint256(_marketFees.minimumFee), "IHubMarket: Failed to transfer minimumFee");
        require(auctionTemplate != address(0), "IHubMarket: Auction template doesn't exist");
        uint256 integratorFee = 0;
        uint256 iHubFee = msg.value;
        if (_integratorFeeAccount != address(0) && _integratorFeeAccount != iHubDiv) {
            integratorFee = (iHubFee * uint256(_marketFees.integratorFeePct)) / 1000;
            iHubFee = iHubFee - integratorFee;
        }

        /// @dev Deploy using the NeutronStar factory.
        newMarket = neutronStar.deploy(auctionTemplate, "", false);
        auctionInfo[newMarket] = Auction(true, BoringMath.to64(_templateId), BoringMath.to128(auctions.length));
        auctions.push(newMarket);
        emit MarketCreated(msg.sender, newMarket, auctionTemplate);
        if (iHubFee > 0) {
            iHubDiv.transfer(iHubFee);
        }
        if (integratorFee > 0) {
            _integratorFeeAccount.transfer(integratorFee);
        }
    }

    /**
     * @notice Creates a new IHubMarket using _templateId.
     * @dev Initializes auction with the parameters passed.
     * @param _templateId Id of the auction template to create.
     * @param _token The token address to be sold.
     * @param _tokenSupply Amount of tokens to be sold at market.
     * @param _integratorFeeAccount Address to send refferal bonus, if set.
     * @param _data Data to be sent to template on Init.
     * @return newMarket Market address.
     */
    function createMarket(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newMarket) {
        newMarket = deployMarket(_templateId, _integratorFeeAccount);
        if (_tokenSupply > 0) {
            _safeTransferFrom(_token, msg.sender, _tokenSupply);
            IERC20(_token).safeApprove(newMarket, _tokenSupply);
        }
        IIHubMarket(newMarket).initMarket(_data);

        if (_tokenSupply > 0) {
            uint256 remainingBalance = IERC20(_token).balanceOf(address(this));
            if (remainingBalance > 0) {
                _safeTransfer(_token, msg.sender, remainingBalance);
            }
        }
        return newMarket;
    }

    /**
     * @notice Function to add an auction template to create through factory.
     * @dev Should have operator access.
     * @param _template Auction template to create an auction.
     */
    function addAuctionTemplate(address _template) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubMarket: Sender must be operator"
        );
        _addAuctionTemplate(_template);
    }

    /**
     * @dev Function to remove an auction template.
     * @dev Should have operator access.
     * @param _templateId Refers to template that is to be deleted.
     */
    function removeAuctionTemplate(uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubMarket: Sender must be operator"
        );
        address template = auctionTemplates[_templateId];
        uint256 templateType = IIHubMarket(template).marketTemplate();
        if (currentTemplateId[templateType] == _templateId) {
            delete currentTemplateId[templateType];
        }
        auctionTemplates[_templateId] = address(0);
        delete auctionTemplateToId[template];
        emit AuctionTemplateRemoved(template, _templateId);
    }

    /**
     * @notice Function to add an auction template to create through factory.
     * @param _template Auction template address to create an auction.
     */
    function _addAuctionTemplate(address _template) internal {
        require(_template != address(0), "IHubMarket: Incorrect template");
        require(auctionTemplateToId[_template] == 0, "IHubMarket: Template already added");
        uint256 templateType = IIHubMarket(_template).marketTemplate();
        require(templateType > 0, "IHubMarket: Incorrect template code ");
        auctionTemplateId++;

        auctionTemplates[auctionTemplateId] = _template;
        auctionTemplateToId[_template] = auctionTemplateId;
        currentTemplateId[templateType] = auctionTemplateId;
        emit AuctionTemplateAdded(_template, auctionTemplateId);
    }

    /**
     * @notice Get the address based on template ID.
     * @param _templateId Auction template ID.
     * @return Address of the required template ID.
     */
    function getAuctionTemplate(uint256 _templateId) external view returns (address) {
        return auctionTemplates[_templateId];
    }

    /**
     * @notice Get the ID based on template address.
     * @param _auctionTemplate Auction template address.
     * @return ID of the required template address.
     */
    function getTemplateId(address _auctionTemplate) external view returns (uint256) {
        return auctionTemplateToId[_auctionTemplate];
    }

    /**
     * @notice Get the total number of auctions in the factory.
     * @return Auction count.
     */
    function numberOfAuctions() external view returns (uint) {
        return auctions.length;
    }

    function minimumFee() external view returns (uint128) {
        return marketFees.minimumFee;
    }

    function getMarkets() external view returns (address[] memory) {
        return auctions;
    }

    function getMarketTemplateId(address _auction) external view returns (uint64) {
        return auctionInfo[_auction].templateId;
    }
}

pragma solidity 0.6.12;

// IHub Reactor
//
// A factory to conveniently deploy your own token vault contracts
//
// Inspired by Bokky's EtherVendingMachince.io
// https://github.com/bokkypoobah/FixedSupplyTokenFactory
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "./Utils/CloneFactory.sol";
import "./Access/IHubAccessControls.sol";

/// @notice  Token escrow, lock up tokens for a period of time

contract IHubReactor is CloneFactory {
    /// @notice Responsible for access rights to the contract.
    IHubAccessControls public accessControls;
    bytes32 public constant VAULT_MINTER_ROLE = keccak256("VAULT_MINTER_ROLE");

    /// @notice Whether farm factory has been initialized or not.
    bool private initialised;
    /// @notice Contract locked status. If locked, only minters can deploy
    bool public locked;

    /// @notice Struct to track Reactor template.
    struct Reactor {
        bool exists;
        uint256 templateId;
        uint256 index;
    }

    /// @notice Escrows created using the factory.
    address[] public escrows;

    /// @notice Template id to track respective escrow template.
    uint256 public escrowTemplateId;

    /// @notice Mapping from template id to escrow template address.
    mapping(uint256 => address) private escrowTemplates;

    /// @notice mapping from escrow template address to escrow template id
    mapping(address => uint256) private escrowTemplateToId;

    /// @notice mapping from escrow address to struct Reactor
    mapping(address => Reactor) public isChildEscrow;

    /// @notice Event emitted when first initializing IHub reactor.
    event IHuInitReactor(address sender);

    /// @notice Event emitted when escrow template added.
    event EscrowTemplateAdded(address newTemplate, uint256 templateId);

    /// @notice Event emitted when escrow template is removed.
    event EscrowTemplateRemoved(address template, uint256 templateId);

    /// @notice Event emitted when escrow is created.
    event EscrowCreated(address indexed owner, address indexed addr, address escrowTemplate);

    /**
     * @notice Single gateway to initialize the IHub Market with proper address.
     * @dev Can only be initialized once.
     * @param _accessControls Sets address to get the access controls from.
     */
    function initIHubReactor(address _accessControls) external {
        /// @dev Maybe missing require message?
        require(!initialised);
        initialised = true;
        locked = true;
        accessControls = IHubAccessControls(_accessControls);
        emit IHuInitReactor(msg.sender);
    }

    /**
     * @notice Sets the factory to be locked or unlocked.
     * @param _locked bool.
     */
    function setLocked(bool _locked) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubReactor: Sender must be admin");
        locked = _locked;
    }

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasVaultMinterRole(address _address) public view returns (bool) {
        return accessControls.hasRole(VAULT_MINTER_ROLE, _address);
    }

    /**
     * @notice Creates a new escrow corresponding to template Id.
     * @param _templateId Template id of the escrow to create.
     * @return newEscrow Escrow address.
     */
    function createEscrow(uint256 _templateId) external returns (address newEscrow) {
        /// @dev If the contract is locked, only admin and minters can deploy.
        if (locked) {
            require(
                accessControls.hasAdminRole(msg.sender) ||
                    accessControls.hasMinterRole(msg.sender) ||
                    hasVaultMinterRole(msg.sender),
                "IHubReactor: Sender must be minter if locked"
            );
        }

        require(escrowTemplates[_templateId] != address(0));
        newEscrow = createClone(escrowTemplates[_templateId]);

        isChildEscrow[address(newEscrow)] = Reactor(true, _templateId, escrows.length);
        escrows.push(newEscrow);
        emit EscrowCreated(msg.sender, address(newEscrow), escrowTemplates[_templateId]);
    }

    /**
     * @notice Function to add a escrow template to create through factory.
     * @dev Should have operator access.
     * @param _escrowTemplate Escrow template to create a token.
     */
    function addEscrowTemplate(address _escrowTemplate) external {
        require(accessControls.hasOperatorRole(msg.sender), "IHubReactor: Sender must be operator");
        escrowTemplateId++;
        escrowTemplates[escrowTemplateId] = _escrowTemplate;
        escrowTemplateToId[_escrowTemplate] = escrowTemplateId;
        emit EscrowTemplateAdded(_escrowTemplate, escrowTemplateId);
    }

    /**
     * @notice Function to remove a escrow template.
     * @dev Should have operator access.
     * @param _templateId Refers to template that is to be deleted.
     */
    function removeEscrowTemplate(uint256 _templateId) external {
        require(accessControls.hasOperatorRole(msg.sender), "IHubReactor: Sender must be operator");
        require(escrowTemplates[_templateId] != address(0));
        address template = escrowTemplates[_templateId];
        escrowTemplates[_templateId] = address(0);
        delete escrowTemplateToId[template];
        emit EscrowTemplateRemoved(template, _templateId);
    }

    /**
     * @notice Get the address of the escrow template based on template ID.
     * @param _templateId Escrow template ID.
     * @return Address of the required template ID.
     */
    function getEscrowTemplate(uint256 _templateId) external view returns (address) {
        return escrowTemplates[_templateId];
    }

    /**
     * @notice Get the ID based on template address.
     * @param _escrowTemplate Escrow template address.
     * @return templateId ID of the required template address.
     */
    function getTemplateId(address _escrowTemplate) external view returns (uint256 templateId) {
        return escrowTemplateToId[_escrowTemplate];
    }

    /**
     * @notice Get the total number of escrows in the factory.
     * @return Escrow count.
     */
    function numberOfTokens() external view returns (uint256) {
        return escrows.length;
    }
}

pragma solidity 0.6.12;

// IHub Token Factory
//
// A factory to conveniently deploy your own source code verified  token contracts
//
// Inspired by Bokky's EtherVendingMachince.io
// https://github.com/bokkypoobah/FixedSupplyTokenFactory
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "./Utils/CloneFactory.sol";
import "./interfaces/IIHubToken.sol";
import "./Access/IHubAccessControls.sol";
import "./Utils/SafeTransfer.sol";
import "./interfaces/IERC20.sol";

contract IHubTokenFactory is CloneFactory, SafeTransfer {
    /// @dev Responsible for access rights to the contract
    IHubAccessControls public accessControls;
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");

    /// @dev Constant to indicate precision
    uint256 private constant INTEGRATOR_FEE_PRECISION = 1000;

    /// @dev Whether token factory has been initialized or not.
    bool private initialised;

    /// @dev Struct to track Token template.
    struct Token {
        bool exists;
        uint256 templateId;
        uint256 index;
    }

    /// @dev Mapping from token address created through this contract to Token struct.
    mapping(address => Token) public tokenInfo;

    /// @notice Array of tokens created using the factory.
    address[] public tokens;

    /// @notice Template id to track respective token template.
    uint256 public tokenTemplateId;

    /// @notice Mapping from token template id to token template address.
    mapping(uint256 => address) private tokenTemplates;

    /// @notice mapping from token template address to token template id
    mapping(address => uint256) private tokenTemplateToId;

    /// @notice mapping from template type to template id
    mapping(uint256 => uint256) public currentTemplateId;

    /// @notice Minimum fee to create a token through the factory.
    uint256 public minimumFee;
    uint256 public integratorFeePct;

    /// @notice Contract locked status. If locked, only minters can deploy
    bool public locked;

    /// @notice Any IHub dividends collected are sent here.
    address payable public iHubDiv;

    /// @notice Event emitted when first initializing IHub Token Factory.
    event IHubInitTokenFactory(address sender);

    /// @notice Event emitted when a token is created using template id.
    event TokenCreated(address indexed owner, address indexed addr, address tokenTemplate);

    /// @notice event emitted when a token is initialized using template id
    event TokenInitialized(address indexed addr, uint256 templateId, bytes data);

    /// @notice Event emitted when a token template is added.
    event TokenTemplateAdded(address newToken, uint256 templateId);

    /// @notice Event emitted when a token template is removed.
    event TokenTemplateRemoved(address token, uint256 templateId);

    constructor() public {}

    /**
     * @notice Single gateway to initialize the IHub Token Factory with proper address.
     * @dev Can only be initialized once.
     * @param _accessControls Sets address to get the access controls from.
     */
    /// @dev GP: Migrate to the NeutronStar.
    function initIHubTokenFactory(address _accessControls) external {
        require(!initialised);
        initialised = true;
        locked = true;
        accessControls = IHubAccessControls(_accessControls);
        emit IHubInitTokenFactory(msg.sender);
    }

    /**
     * @notice Sets the minimum fee.
     * @param _amount Fee amount.
     */
    function setMinimumFee(uint256 _amount) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubTokenFactory: Sender must be operator");
        minimumFee = _amount;
    }

    /**
     * @notice Sets integrator fee percentage.
     * @param _amount Percentage amount.
     */
    function setIntegratorFeePct(uint256 _amount) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubTokenFactory: Sender must be operator");
        /// @dev this is out of 1000, ie 25% = 250
        require(_amount <= INTEGRATOR_FEE_PRECISION, "IHubTokenFactory: Range is from 0 to 1000");
        integratorFeePct = _amount;
    }

    /**
     * @notice Sets dividend address.
     * @param _divaddr Dividend address.
     */
    function setDividends(address payable _divaddr) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubTokenFactory: Sender must be operator");
        require(_divaddr != address(0));
        iHubDiv = _divaddr;
    }

    /**
     * @notice Sets the factory to be locked or unlocked.
     * @param _locked bool.
     */
    function setLocked(bool _locked) external {
        require(accessControls.hasAdminRole(msg.sender), "IHubTokenFactory: Sender must be admin");
        locked = _locked;
    }

    /**
     * @notice Sets the current template ID for any type.
     * @param _templateType Type of template.
     * @param _templateId The ID of the current template for that type
     */
    function setCurrentTemplateId(uint256 _templateType, uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubTokenFactory: Sender must be admin"
        );
        require(tokenTemplates[_templateId] != address(0), "IHubTokenFactory: incorrect _templateId");
        require(
            IIHubToken(tokenTemplates[_templateId]).tokenTemplate() == _templateType,
            "IHubTokenFactory: incorrect _templateType"
        );
        currentTemplateId[_templateType] = _templateId;
    }

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasTokenMinterRole(address _address) public view returns (bool) {
        return accessControls.hasRole(TOKEN_MINTER_ROLE, _address);
    }

    /**
     * @notice Creates a token corresponding to template id and transfers fees.
     * @dev Initializes token with parameters passed
     * @param _templateId Template id of token to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @return token Token address.
     */
    function deployToken(
        uint256 _templateId,
        address payable _integratorFeeAccount
    ) public payable returns (address token) {
        /// @dev If the contract is locked, only admin and minters can deploy.
        if (locked) {
            require(
                accessControls.hasAdminRole(msg.sender) ||
                    accessControls.hasMinterRole(msg.sender) ||
                    hasTokenMinterRole(msg.sender),
                "IHubTokenFactory: Sender must be minter if locked"
            );
        }
        require(msg.value >= minimumFee, "IHubTokenFactory: Failed to transfer minimumFee");
        require(tokenTemplates[_templateId] != address(0), "IHubTokenFactory: incorrect _templateId");
        uint256 integratorFee = 0;
        uint256 iHubFee = msg.value;
        if (_integratorFeeAccount != address(0) && _integratorFeeAccount != iHubDiv) {
            integratorFee = (iHubFee * integratorFeePct) / INTEGRATOR_FEE_PRECISION;
            iHubFee = iHubFee - integratorFee;
        }
        token = createClone(tokenTemplates[_templateId]);
        /// @dev GP: Triple check the token index is correct.
        tokenInfo[token] = Token(true, _templateId, tokens.length);
        tokens.push(token);
        emit TokenCreated(msg.sender, token, tokenTemplates[_templateId]);
        if (iHubFee > 0) {
            iHubDiv.transfer(iHubFee);
        }
        if (integratorFee > 0) {
            _integratorFeeAccount.transfer(integratorFee);
        }
    }

    /**
     * @notice Creates a token corresponding to template id.
     * @dev Initializes token with parameters passed.
     * @param _templateId Template id of token to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @param _data Data to be passed to the token contract for init.
     * @return token Token address.
     */
    function createToken(
        uint256 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address token) {
        token = deployToken(_templateId, _integratorFeeAccount);
        emit TokenInitialized(address(token), _templateId, _data);
        IIHubToken(token).initToken(_data);
        uint256 initialTokens = IERC20(token).balanceOf(address(this));
        if (initialTokens > 0) {
            _safeTransfer(token, msg.sender, initialTokens);
        }
    }

    /**
     * @notice Function to add a token template to create through factory.
     * @dev Should have operator access.
     * @param _template Token template to create a token.
     */
    function addTokenTemplate(address _template) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubTokenFactory: Sender must be operator"
        );
        uint256 templateType = IIHubToken(_template).tokenTemplate();
        require(templateType > 0, "IHubTokenFactory: Incorrect template code ");
        require(tokenTemplateToId[_template] == 0, "IHubTokenFactory: Template exists");
        tokenTemplateId++;
        tokenTemplates[tokenTemplateId] = _template;
        tokenTemplateToId[_template] = tokenTemplateId;
        currentTemplateId[templateType] = tokenTemplateId;
        emit TokenTemplateAdded(_template, tokenTemplateId);
    }

    /**
     * @notice Function to remove a token template.
     * @dev Should have operator access.
     * @param _templateId Refers to template that is to be deleted.
     */
    function removeTokenTemplate(uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender),
            "IHubTokenFactory: Sender must be operator"
        );
        require(tokenTemplates[_templateId] != address(0));
        address template = tokenTemplates[_templateId];
        uint256 templateType = IIHubToken(tokenTemplates[_templateId]).tokenTemplate();
        if (currentTemplateId[templateType] == _templateId) {
            delete currentTemplateId[templateType];
        }
        tokenTemplates[_templateId] = address(0);
        delete tokenTemplateToId[template];
        emit TokenTemplateRemoved(template, _templateId);
    }

    /**
     * @notice Get the total number of tokens in the factory.
     * @return Token count.
     */
    function numberOfTokens() external view returns (uint256) {
        return tokens.length;
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @notice Get the address based on template ID.
     * @param _templateId Token template ID.
     * @return Address of the required template ID.
     */
    function getTokenTemplate(uint256 _templateId) external view returns (address) {
        return tokenTemplates[_templateId];
    }

    /**
     * @notice Get the ID based on template address.
     * @param _tokenTemplate Token template address.
     * @return ID of the required template address.
     */
    function getTemplateId(address _tokenTemplate) external view returns (uint256) {
        return tokenTemplateToId[_tokenTemplate];
    }
}

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;
import "./ISafeGnosis.sol";

interface IGnosisProxyFactory {
    function createProxy(ISafeGnosis masterCopy, bytes memory data) external returns (ISafeGnosis proxy);
}

pragma solidity 0.6.12;

interface IIHubAuction {
    function initAuction(
        address _funder,
        address _token,
        uint256 _tokenSupply,
        uint256 _startDate,
        uint256 _endDate,
        address _paymentCurrency,
        uint24 _fee,
        uint256 _startPrice,
        uint256 _minimumPrice,
        address _operator,
        address _pointList,
        address payable _wallet
    ) external;

    function auctionSuccessful() external view returns (bool);

    function finalized() external view returns (bool);

    function wallet() external view returns (address);

    function paymentCurrency() external view returns (address);

    function auctionToken() external view returns (address);

    // TangleswapPool->fee
    function fee() external view returns (uint24);

    function finalize() external;

    function tokenPrice() external view returns (uint256);

    function getTotalTokens() external view returns (uint256);
}

pragma solidity 0.6.12;

interface IIHubFarm {
    function initFarm(bytes calldata data) external;

    function farmTemplate() external view returns (uint256);
}

pragma solidity 0.6.12;

interface IIHubLiquidity {
    function initLauncher(bytes calldata data) external;

    function getMarkets() external view returns (address[] memory);

    function liquidityTemplate() external view returns (uint256);
}

pragma solidity 0.6.12;

interface IIHubMarket {
    function init(bytes calldata data) external payable;

    function initMarket(bytes calldata data) external;

    function marketTemplate() external view returns (uint256);
}

pragma solidity 0.6.12;

interface IIHubToken {
    function init(bytes calldata data) external payable;

    function initToken(bytes calldata data) external;

    function tokenTemplate() external view returns (uint256);
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../Utils/BoringERC20.sol";

interface IMasterCore {
    using BoringERC20 for IERC20;
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. rewards to distribute per block.
        uint256 lastRewardBlock; // Last block number that rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
    }

    function poolInfo(uint256 pid) external view returns (IMasterCore.PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
}

pragma solidity 0.6.12;

interface INeutronStarFactory {
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address cloneAddress);

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity 0.6.12;

// ----------------------------------------------------------------------------
// Purple List interface
// ----------------------------------------------------------------------------

interface IPointList {
    function isInList(address account) external view returns (bool);

    function hasPoints(address account, uint256 amount) external view returns (bool);

    function setPoints(address[] memory accounts, uint256[] memory amounts) external;

    function initPointList(address accessControl) external;
}

pragma solidity 0.6.12;

import "../Utils/BoringERC20.sol";

interface IRewarder {
    using BoringERC20 for IERC20;

    function onReward(uint256 pid, address user, uint256 rewardAmount) external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 rewardAmount
    ) external returns (IERC20[] memory, uint256[] memory);
}

pragma solidity 0.6.12;

interface ISafeGnosis {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        //ENUM.Operation?
        uint256 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures
    ) external payable returns (bool success);
}

pragma solidity 0.6.12;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint) external;

    function transfer(address, uint) external returns (bool);
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Post Auction Launcher
//
// A post auction contract that takes the proceeds and creates a liquidity pool
//
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "../OpenZeppelin/utils/ReentrancyGuard.sol";
import "../Access/IHubAccessControls.sol";
import "../Utils/SafeTransfer.sol";
import "../Utils/ERC721Holder.sol";
import "../Utils/BoringMath.sol";
// interfaces of Tangleswap
import "../Tangleswap/core/interfaces/ITangleswapPool.sol";
import "../Tangleswap/core/interfaces/ITangleswapFactory.sol";
import "../Tangleswap/periphery/interfaces/INonfungiblePositionManager.sol";
import "../Utils/TangleswapCallingParams.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IIHubAuction.sol";

// Uncomment if needed.
// import "hardhat/console.sol";

contract PostAuctionLauncher is IHubAccessControls, SafeTransfer, ReentrancyGuard, ERC721Holder {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using BoringMath32 for uint32;
    using BoringMath16 for uint16;

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant LIQUIDITY_PRECISION = 10000;

    /// @notice IHubLiquidity template id.
    uint256 public constant liquidityTemplate = 3;

    /// @notice First Token address.
    IERC20 public token1;
    /// @notice Second Token address.
    IERC20 public token2;
    // Tangleswap TangleswapPool->fee
    uint24 public fee;
    // nft id
    uint256 public tokenId;
    /// @dev Contract of the Tangleswap Nonfungible Position Manager.
    address public nonfungiblePositionManager;
    // notice Tangleswap factory address
    ITangleswapFactory public factory;
    /// @notice WETH contract address.
    address private immutable weth;

    /// @notice LP pair address.
    address public tokenPair;
    /// @notice Withdraw wallet address.
    address public wallet;
    /// @notice Token market contract address.
    IIHubAuction public market;

    struct LauncherInfo {
        uint32 locktime;
        uint64 unlock;
        uint16 liquidityPercent;
        bool launched;
        uint128 liquidityAdded;
    }
    LauncherInfo public launcherInfo;

    /// @notice Emitted when LP contract is initialised.
    event InitLiquidityLauncher(address indexed token1, address indexed token2, address factory, address sender);
    /// @notice Emitted when LP is launched.
    event LiquidityAdded(uint256 liquidity);
    /// @notice Emitted when wallet is updated.
    event WalletUpdated(address indexed wallet);
    /// @notice Emitted when launcher is cancelled.
    event LauncherCancelled(address indexed wallet);
    /// @notice Emitted when nft is withdrawn。
    event NftWithdrawn(address indexed to, uint256 tokenId);

    constructor(address _weth) public {
        weth = _weth;
    }

    /**
     * @notice Initializes main contract variables (requires launchwindow to be more than 2 days.)
     * @param _nonfungiblePositionManager Contract of the Tangleswap Nonfungible Position Manager.
     * @param _market Auction address for launcher.
     * @param _factory Tangleswap factory address.
     * @param _admin Contract owner address.
     * @param _wallet Withdraw wallet address.
     * @param _liquidityPercent Percentage of payment currency sent to liquidity pool.
     * @param _locktime How long the liquidity will be locked. Number of seconds.
     */
    function initAuctionLauncher(
        address _nonfungiblePositionManager,
        address _market,
        address _factory,
        address _admin,
        address _wallet,
        uint256 _liquidityPercent,
        uint256 _locktime
    ) public {
        require(_locktime < 10000000000, "PostAuction: Enter an unix timestamp in seconds, not miliseconds");
        require(
            _liquidityPercent <= LIQUIDITY_PRECISION,
            "PostAuction: Liquidity percentage greater than 100.00% (>10000)"
        );
        require(_liquidityPercent > 0, "PostAuction: Liquidity percentage equals zero");
        require(_admin != address(0), "PostAuction: admin is the zero address");
        require(_wallet != address(0), "PostAuction: wallet is the zero address");

        initAccessControls(_admin);

        market = IIHubAuction(_market);
        token1 = IERC20(market.paymentCurrency());
        token2 = IERC20(market.auctionToken());
        // TangleswapPool->fee
        fee = market.fee();

        if (address(token1) == ETH_ADDRESS) {
            token1 = IERC20(weth);
        }

        uint256 d1 = uint256(token1.decimals());
        uint256 d2 = uint256(token2.decimals());
        require(d2 >= d1);

        // Tangleswap
        nonfungiblePositionManager = _nonfungiblePositionManager;
        factory = ITangleswapFactory(_factory);
        tokenPair = factory.getPool(address(token1), address(token2), fee);

        wallet = _wallet;
        launcherInfo.liquidityPercent = BoringMath.to16(_liquidityPercent);
        launcherInfo.locktime = BoringMath.to32(_locktime);

        uint256 initalTokenAmount = market.getTotalTokens().mul(_liquidityPercent).div(LIQUIDITY_PRECISION);
        _safeTransferFrom(address(token2), msg.sender, initalTokenAmount);

        emit InitLiquidityLauncher(address(token1), address(token2), address(_factory), _admin);
    }

    receive() external payable {
        if (msg.sender != weth) {
            depositETH();
        }
    }

    /// @notice Deposits ETH to the contract.
    function depositETH() public payable {
        require(address(token1) == weth || address(token2) == weth, "PostAuction: Launcher not accepting ETH");
        if (msg.value > 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }

    /**
     * @notice Deposits first Token to the contract.
     * @param _amount Number of tokens to deposit.
     */
    function depositToken1(uint256 _amount) external returns (bool success) {
        return _deposit(address(token1), msg.sender, _amount);
    }

    /**
     * @notice Deposits second Token to the contract.
     * @param _amount Number of tokens to deposit.
     */
    function depositToken2(uint256 _amount) external returns (bool success) {
        return _deposit(address(token2), msg.sender, _amount);
    }

    /**
     * @notice Deposits Tokens to the contract.
     * @param _amount Number of tokens to deposit.
     * @param _from Where the tokens to deposit will come from.
     * @param _token Token address.
     */
    function _deposit(address _token, address _from, uint _amount) internal returns (bool success) {
        require(!launcherInfo.launched, "PostAuction: Must first launch liquidity");
        require(launcherInfo.liquidityAdded == 0, "PostAuction: Liquidity already added");

        require(_amount > 0, "PostAuction: Token amount must be greater than 0");
        _safeTransferFrom(_token, _from, _amount);
        return true;
    }

    /**
     * @notice Checks if market wallet is set to this launcher
     */
    function marketConnected() public view returns (bool) {
        return market.wallet() == address(this);
    }

    /**
     * @notice Finalizes Token sale and launches LP.
     * @return liquidity Number of LPs.
     */
    function finalize(
        uint160 sqrtPriceX96,
        int24 tickLower,
        int24 tickUpper
    ) external nonReentrant returns (uint256 liquidity) {
        // GP: Can we remove admin, let anyone can finalise and launch?
        // require(hasAdminRole(msg.sender) || hasOperatorRole(msg.sender), "PostAuction: Sender must be operator");
        require(
            marketConnected(),
            "PostAuction: Auction must have this launcher address set as the destination wallet"
        );
        require(!launcherInfo.launched, "PostAuction: Auction must be unlaunched");

        if (!market.finalized()) {
            market.finalize();
        }

        launcherInfo.launched = true;
        if (!market.auctionSuccessful()) {
            return 0;
        }

        /// @dev if the auction is settled in weth, wrap any contract balance
        uint256 launcherBalance = address(this).balance;
        if (launcherBalance > 0) {
            IWETH(weth).deposit{value: launcherBalance}();
        }

        (uint256 token1Amount, uint256 token2Amount) = getTokenAmounts();

        /// @dev cannot start a liquidity pool with no tokens on either side
        if (token1Amount == 0 || token2Amount == 0) {
            return 0;
        }

        // Tangleswap TangleswapFactory.getPool
        address pair = factory.getPool(address(token1), address(token2), fee);
        require(pair == address(0) || ITangleswapPool(pair).liquidity() == 0, "PostLiquidity: Pair not new");
        if (pair == address(0)) {
            createPool(sqrtPriceX96);
        }

        // @dev add liquidity to pool via the nonfungiblePositionManager --- work with Tangleswap
        _safeApprove(address(token1), nonfungiblePositionManager, token1Amount);
        _safeApprove(address(token2), nonfungiblePositionManager, token2Amount);
        // Tangleswap NonfungiblePositionManager.mint
        INonfungiblePositionManager.MintParams memory mintParam = TangleswapCallingParams.mintParams(
            address(token1),
            address(token2),
            fee,
            token1Amount,
            token2Amount,
            tickLower,
            tickUpper,
            type(uint256).max
        );
        (tokenId, liquidity, , ) = INonfungiblePositionManager(nonfungiblePositionManager).mint(mintParam);

        launcherInfo.liquidityAdded = BoringMath.to128(uint256(launcherInfo.liquidityAdded).add(liquidity));

        /// @dev if unlock time not yet set, add it.
        if (launcherInfo.unlock == 0) {
            // solhint-disable-next-line not-rely-on-time
            launcherInfo.unlock = BoringMath.to64(block.timestamp + uint256(launcherInfo.locktime));
        }
        emit LiquidityAdded(liquidity);
    }

    function getTokenAmounts() public view returns (uint256 token1Amount, uint256 token2Amount) {
        token1Amount = getToken1Balance().mul(uint256(launcherInfo.liquidityPercent)).div(LIQUIDITY_PRECISION);
        token2Amount = getToken2Balance();

        uint256 tokenPrice = market.tokenPrice();
        uint256 d2 = uint256(token2.decimals());
        uint256 maxToken1Amount = token2Amount.mul(tokenPrice).div(10 ** (d2));
        uint256 maxToken2Amount = token1Amount.mul(10 ** (d2)).div(tokenPrice);

        /// @dev if more than the max.
        if (token2Amount > maxToken2Amount) {
            token2Amount = maxToken2Amount;
        }
        /// @dev if more than the max.
        if (token1Amount > maxToken1Amount) {
            token1Amount = maxToken1Amount;
        }
    }

    /**
     * @notice Tangleswap Withdraws NFT from the contract.
     */
    function withdrawNft() external {
        require(hasAdminRole(msg.sender) || hasOperatorRole(msg.sender), "Sender must be operator");
        require(
            tokenId > 0 && INonfungiblePositionManager(nonfungiblePositionManager).ownerOf(tokenId) == address(this),
            "Invalid nft"
        );
        require(launcherInfo.launched, "Must first launch liquidity");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= uint256(launcherInfo.unlock), "Liquidity is locked");
        INonfungiblePositionManager(nonfungiblePositionManager).safeTransferFrom(address(this), wallet, tokenId);

        emit NftWithdrawn(wallet, tokenId);
    }

    /// @notice Withraws deposited tokens and ETH from the contract to wallet.
    function withdrawDeposits() external {
        require(hasAdminRole(msg.sender) || hasOperatorRole(msg.sender), "Sender must be operator");
        require(launcherInfo.launched, "Must first launch liquidity");

        uint256 token1Amount = getToken1Balance();
        if (token1Amount > 0) {
            _safeTransfer(address(token1), wallet, token1Amount);
        }
        uint256 token2Amount = getToken2Balance();
        if (token2Amount > 0) {
            _safeTransfer(address(token2), wallet, token2Amount);
        }
    }

    // TODO
    // GP: Sweep non relevant ERC20s / ETH

    //--------------------------------------------------------
    // Setter functions
    //--------------------------------------------------------

    /**
     * @notice Admin can set the wallet through this function.
     * @param _wallet Wallet is where funds will be sent.
     */
    function setWallet(address payable _wallet) external {
        require(hasAdminRole(msg.sender), "not the admin");
        require(_wallet != address(0), "Wallet is the zero address");

        wallet = _wallet;

        emit WalletUpdated(_wallet);
    }

    function cancelLauncher() external {
        require(hasAdminRole(msg.sender), "not the admin");
        require(!launcherInfo.launched, "already launched");

        launcherInfo.launched = true;
        emit LauncherCancelled(msg.sender);
    }

    //--------------------------------------------------------
    // Helper functions
    //--------------------------------------------------------

    /**
     * @notice Creates new SLP pair through TangleSwap.
     */
    function createPool(uint160 sqrtPriceX96) internal {
        // Tangleswap TangleswapFactory.createPool
        tokenPair = factory.createPool(address(token1), address(token2), fee);
        // Sets the initial price for the pool
        ITangleswapPool(tokenPair).initialize(sqrtPriceX96);
    }

    //--------------------------------------------------------
    // Getter functions
    //--------------------------------------------------------

    /**
     * @notice Gets the number of first token deposited into this contract.
     * @return uint256 Number of WETH.
     */
    function getToken1Balance() public view returns (uint256) {
        return token1.balanceOf(address(this));
    }

    /**
     * @notice Gets the number of second token deposited into this contract.
     * @return uint256 Number of WETH.
     */
    function getToken2Balance() public view returns (uint256) {
        return token2.balanceOf(address(this));
    }

    /**
     * @notice Returns LP token address.
     * @return address LP address.
     */
    function getLPTokenAddress() public view returns (address) {
        return tokenPair;
    }

    //--------------------------------------------------------
    // Init functions
    //--------------------------------------------------------

    /**
     * @notice Decodes and hands auction data to the initAuction function.
     * @param _data Encoded data for initialization.
     */

    function init(bytes calldata _data) external payable {}

    function initLauncher(bytes calldata _data) public {
        (
            address _nonfungiblePositionManager,
            address _market,
            address _factory,
            address _admin,
            address _wallet,
            uint256 _liquidityPercent,
            uint256 _locktime
        ) = abi.decode(_data, (address, address, address, address, address, uint256, uint256));
        initAuctionLauncher(
            _nonfungiblePositionManager,
            _market,
            _factory,
            _admin,
            _wallet,
            _liquidityPercent,
            _locktime
        );
    }

    /**
     * @notice Collects data to initialize the auction and encodes them.
     * @param _nonfungiblePositionManager Contract of the Tangleswap Nonfungible Position Manager.
     * @param _market Auction address for launcher.
     * @param _factory Tangleswap factory address.
     * @param _admin Contract owner address.
     * @param _wallet Withdraw wallet address.
     * @param _liquidityPercent Percentage of payment currency sent to liquidity pool.
     * @param _locktime How long the liquidity will be locked. Number of seconds.
     * @return _data All the data in bytes format.
     */
    function getLauncherInitData(
        address _nonfungiblePositionManager,
        address _market,
        address _factory,
        address _admin,
        address _wallet,
        uint256 _liquidityPercent,
        uint256 _locktime
    ) external pure returns (bytes memory _data) {
        return
            abi.encode(_nonfungiblePositionManager, _market, _factory, _admin, _wallet, _liquidityPercent, _locktime);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";
import "../Utils/SafeTransfer.sol";

interface IIHubTokenFactory {
    function createToken(
        uint256 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address token);
}

interface IPointList {
    function deployPointList(
        address _listOwner,
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external payable returns (address pointList);
}

interface IIHubLauncher {
    function createLauncher(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newLauncher);
}

interface IIHubMarket {
    function createMarket(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    ) external payable returns (address newMarket);

    function setAuctionWallet(address payable _wallet) external;

    function addAdminRole(address _address) external;

    function getAuctionTemplate(uint256 _templateId) external view returns (address);
}

interface IAuctionTemplate {
    function marketTemplate() external view returns (uint256);
}

// Auction Creation Molecule
// 1. Create Token
// 2. Create purplelist (Optional)
// 3. Create Auction with token address and purplelist address
// 4. Create Liquidity Launcher with auction and token address
// 5. Set destination wallet of auction to liquidity launcher
contract AuctionCreation is SafeTransfer {
    IIHubTokenFactory public iHubTokenFactory;
    IPointList public pointListFactory;
    IIHubLauncher public iHubLauncher;
    IIHubMarket public iHubMarket;
    address public factory;

    constructor(
        IIHubTokenFactory _iHubTokenFactory,
        IPointList _pointListFactory,
        IIHubLauncher _iHubLauncher,
        IIHubMarket _iHubMarket,
        address _factory
    ) public {
        iHubTokenFactory = _iHubTokenFactory;
        pointListFactory = _pointListFactory;
        iHubLauncher = _iHubLauncher;
        iHubMarket = _iHubMarket;
        factory = _factory;
    }

    function prepareIHub(
        bytes memory tokenFactoryData,
        address[] memory _accounts,
        uint256[] memory _amounts,
        bytes memory marketData,
        bytes memory launcherData
    ) external payable {
        require(_accounts.length == _amounts.length, "!len");

        address token = createToken(tokenFactoryData);

        address pointList = createPointList(_accounts, _amounts);

        (address newMarket, uint256 tokenForSale) = createMarket(marketData, token, pointList);

        // IHub market has to give admin role to the user, since it's set to this contract initially
        // to allow the auction wallet to be set to launcher once it's been deployed
        IIHubMarket(newMarket).addAdminRole(msg.sender);

        createLauncher(launcherData, token, tokenForSale, newMarket);

        uint256 tokenBalanceRemaining = IERC20(token).balanceOf(address(this));
        if (tokenBalanceRemaining > 0) {
            _safeTransfer(token, msg.sender, tokenBalanceRemaining);
        }
    }

    function createToken(bytes memory tokenFactoryData) internal returns (address token) {
        (
            bool isDeployed,
            address deployedToken,
            uint256 _iHubTokenFactoryTemplateId,
            string memory _name,
            string memory _symbol,
            uint256 _initialSupply
        ) = abi.decode(tokenFactoryData, (bool, address, uint256, string, string, uint256));
        if (isDeployed) {
            token = deployedToken;
            IERC20(deployedToken).transferFrom(msg.sender, address(this), _initialSupply);
        } else {
            token = iHubTokenFactory.createToken(
                _iHubTokenFactoryTemplateId,
                address(0),
                abi.encode(_name, _symbol, msg.sender, _initialSupply)
            );
        }

        IERC20(token).approve(address(iHubMarket), _initialSupply);
        IERC20(token).approve(address(iHubLauncher), _initialSupply);
    }

    function createPointList(
        address[] memory _accounts,
        uint256[] memory _amounts
    ) internal returns (address pointList) {
        if (_accounts.length != 0) {
            pointList = pointListFactory.deployPointList(msg.sender, _accounts, _amounts);
        }
    }

    function createMarket(
        bytes memory marketData,
        address token,
        address pointList
    ) internal returns (address newMarket, uint256 tokenForSale) {
        (uint256 _marketTemplateId, bytes memory mData) = abi.decode(marketData, (uint256, bytes));

        tokenForSale = getTokenForSale(_marketTemplateId, mData);

        newMarket = iHubMarket.createMarket(
            _marketTemplateId,
            token,
            tokenForSale,
            address(0),
            abi.encodePacked(
                abi.encode(address(iHubMarket), token),
                mData,
                abi.encode(address(this), pointList, msg.sender)
            )
        );
    }

    function createLauncher(
        bytes memory launcherData,
        address token,
        uint256 tokenForSale,
        address newMarket
    ) internal returns (address newLauncher) {
        (uint256 _launcherTemplateId, uint256 _liquidityPercent, uint256 _locktime) = abi.decode(
            launcherData,
            (uint256, uint256, uint256)
        );

        if (_liquidityPercent > 0) {
            newLauncher = iHubLauncher.createLauncher(
                _launcherTemplateId,
                token,
                (tokenForSale * _liquidityPercent) / 10000,
                address(0),
                abi.encode(newMarket, factory, msg.sender, msg.sender, _liquidityPercent, _locktime)
            );

            // Have to set auction wallet to the new launcher address AFTER the market is created
            // new launcher address is casted to payable to satisfy interface.
            IIHubMarket(newMarket).setAuctionWallet(payable(newLauncher));
        }
    }

    function getTokenForSale(
        uint256 marketTemplateId,
        bytes memory mData
    ) internal view returns (uint256 tokenForSale) {
        address auctionTemplate = iHubMarket.getAuctionTemplate(marketTemplateId);

        uint256 auctionTemplateId = IAuctionTemplate(auctionTemplate).marketTemplate();

        if (auctionTemplateId == 1) {
            (, tokenForSale) = abi.decode(mData, (uint256, uint256));
        } else {
            tokenForSale = abi.decode(mData, (uint256));
        }
    }
}

pragma solidity 0.6.12;

import "../utils/EnumerableSet.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity 0.6.12;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.6.12;

import "../utils/Context.sol";

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.6.12;

import "../../../interfaces/IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
        _callOptionalReturn(token, abi.encodeWithSelector(0xa9059cbb, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
        _callOptionalReturn(token, abi.encodeWithSelector(0x23b872dd, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.6.12;

import "./SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    constructor (IERC20 token_, address beneficiary_, uint256 releaseTime_) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }
}

pragma solidity 0.6.12;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.6.12;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity 0.6.12;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity 0.6.12;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity 0.6.12;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Tangleswap Factory
/// @notice The Tangleswap Factory facilitates creation of Tangleswap pools and control over the protocol fees
interface ITangleswapFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

    /// @notice Burn Wallet (used for buyback-and-burn of VOID)
    /// @dev Can be changed by the current owner via modifyBurnWallet
    /// @return The address of burn wallet
    function burnWallet() external view returns (address);

    /// @notice Update burn wallet
    /// @dev Must be called by the current owner
    /// @param _burnWallet The new burn wallet
    function modifyBurnWallet(address _burnWallet) external;

    /// @notice Initialize NonfungiblePositionManager address
    /// @dev The nonfungiblePositionManager address will be initialized when NonfungiblePositionManager contract deployed, and it can only be initialized once
    function initNonfungiblePositionManager(address _nonfungiblePositionManager) external;

    /// @return Returns current nonfungiblePositionManager address
    function nonfungiblePositionManager() external returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface ITangleswapPool {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(
        bytes32 key
    )
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of ITangleswapMintCallback#tangleswapMintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of ITangleswapSwapCallback#tangleswapSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(
        int24 tick
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(
        uint256 index
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title Non-fungible token for positions
/// @notice Wraps Tangleswap positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    /// @return Returns the address of the Tangleswap factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    // solhint-disable-next-line func-name-mixedcase
    function WETH9() external view returns (address);

    // details about the Tangleswap position
    struct Position {
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        // the ID of the pool with which this token is connected
        uint80 poolId;
        // the tick range of the position
        int24 tickLower;
        int24 tickUpper;
        // the liquidity of the position
        uint128 liquidity;
        // the fee growth of the aggregate position as of the last action on the individual position
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // how many uncollected tokens are owed to the position, as of the last computation
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address owner) external view returns (uint256);

    // @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `index` >= `balanceOf(owner)` or if
    ///  `owner` is the zero address, representing invalid NFTs.
    /// @param owner An address where we are interested in NFTs owned by them
    /// @param index A counter less than `balanceOf(owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address to, uint256 tokenId) external;
}

pragma solidity 0.6.12;

import "../OpenZeppelin/GSN/Context.sol";
import "../OpenZeppelin/math/SafeMath.sol";
import "../interfaces/IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

contract ERC20 is IERC20, Context {
    using SafeMath for uint256;
    bytes32 public DOMAIN_SEPARATOR;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public nonces;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    bool private _initialized;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function _initERC20(string memory name_, string memory symbol_) internal {
        require(!_initialized, "ERC20: token has already been initialized!");
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"), chainId, address(this))
        );

        _initialized = true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < deadline, "ERC20: Expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner_, "ERC20: Invalid Signature");
        _approve(owner_, spender, value);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);

        _afterTokenTransfer(sender, recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        _afterTokenTransfer(address(0), account, amount);

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);

        _afterTokenTransfer(account, address(0), amount);

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

pragma solidity ^0.6.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the callers
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

pragma solidity ^0.6.0;

import "../ERC20.sol";
import "../../OpenZeppelin/utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

pragma solidity 0.6.12;

import "./ERC20.sol";
import "../interfaces/IIHubToken.sol";

// ---------------------------------------------------------------------
//
// From the IHub Token Factory
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

contract FixedToken is ERC20, IIHubToken {
    /// @notice IHub template id for the token factory.
    /// @dev For different token types, this must be incremented.
    uint256 public constant override tokenTemplate = 1;

    /// @dev First set the token variables. This can only be done once
    function initToken(string memory _name, string memory _symbol, address _owner, uint256 _initialSupply) public {
        _initERC20(_name, _symbol);
        _mint(msg.sender, _initialSupply);
    }

    function init(bytes calldata _data) external payable override {}

    function initToken(bytes calldata _data) public override {
        (string memory _name, string memory _symbol, address _owner, uint256 _initialSupply) = abi.decode(
            _data,
            (string, string, address, uint256)
        );

        initToken(_name, _symbol, _owner, _initialSupply);
    }

    /**
     * @dev Generates init data for Farm Factory
     * @param _name - Token name
     * @param _symbol - Token symbol
     * @param _owner - Contract owner
     * @param _initialSupply Amount of tokens minted on creation
     */
    function getInitData(
        string calldata _name,
        string calldata _symbol,
        address _owner,
        uint256 _initialSupply
    ) external pure returns (bytes memory _data) {
        return abi.encode(_name, _symbol, _owner, _initialSupply);
    }
}

pragma solidity 0.6.12;

import "../OpenZeppelin/access/AccessControl.sol";
import "./ERC20/ERC20Burnable.sol";
import "./ERC20/ERC20Pausable.sol";
import "../interfaces/IIHubToken.sol";

// ---------------------------------------------------------------------
//
// From the IHub Token Factory
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

contract MintableToken is AccessControl, ERC20Burnable, ERC20Pausable, IIHubToken {
    /// @notice IHub template id for the token factory.
    /// @dev For different token types, this must be incremented.
    uint256 public constant override tokenTemplate = 2;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function initToken(string memory _name, string memory _symbol, address _owner, uint256 _initialSupply) public {
        _initERC20(_name, _symbol);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MINTER_ROLE, _owner);
        _setupRole(PAUSER_ROLE, _owner);
        _mint(msg.sender, _initialSupply);
    }

    function init(bytes calldata _data) external payable override {}

    function initToken(bytes calldata _data) public override {
        (string memory _name, string memory _symbol, address _owner, uint256 _initialSupply) = abi.decode(
            _data,
            (string, string, address, uint256)
        );

        initToken(_name, _symbol, _owner, _initialSupply);
    }

    /**
     * @dev Generates init data for Token Factory
     * @param _name - Token name
     * @param _symbol - Token symbol
     * @param _owner - Contract owner
     * @param _initialSupply Amount of tokens minted on creation
     */
    function getInitData(
        string calldata _name,
        string calldata _symbol,
        address _owner,
        uint256 _initialSupply
    ) external pure returns (bytes memory _data) {
        return abi.encode(_name, _symbol, _owner, _initialSupply);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "MintableToken: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MintableToken: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MintableToken: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

pragma solidity 0.6.12;

import "../OpenZeppelin/GSN/Context.sol";
import "../OpenZeppelin/math/SafeMath.sol";
import "../OpenZeppelin/utils/Address.sol";
import "../interfaces/IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

contract USDC is IERC20, Context {
    using SafeMath for uint256;
    using Address for address;
    bytes32 public DOMAIN_SEPARATOR;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public nonces;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    bool private _initialized;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    /// @dev First set the token variables. This can only be done once
    function initToken(string memory _name, string memory _symbol, address _owner, uint256 _initialSupply) public {
        _initERC20(_name, _symbol);
        _mint(msg.sender, _initialSupply);
    }

    function init(bytes calldata _data) external payable {}

    function initToken(bytes calldata _data) public {
        (string memory _name, string memory _symbol, address _owner, uint256 _initialSupply) = abi.decode(
            _data,
            (string, string, address, uint256)
        );

        initToken(_name, _symbol, _owner, _initialSupply);
    }

    function _initERC20(string memory name_, string memory symbol_) internal {
        require(!_initialized, "ERC20: token has already been initialized!");
        _name = name_;
        _symbol = symbol_;
        _decimals = 6;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"), chainId, address(this))
        );

        _initialized = true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < deadline, "ERC20: Expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner_, "ERC20: Invalid Signature");
        _approve(owner_, spender, value);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// Audit on 5-Jan-2021 by Keno and BoringCrypto

import "./BoringERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    /// @return successes An array indicating the success of a call, mapped one-to-one to `calls`.
    /// @return results An array with the returned data of each function call, mapped one-to-one to `calls`.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results) {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "BoringMath: Div zero");
        c = a / b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= uint16(-1), "BoringMath: uint16 Overflow");
        c = uint16(a);
    }

}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath16 {
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

pragma solidity 0.6.12;

// ----------------------------------------------------------------------------
// CloneFactory.sol
// From
// https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
// ----------------------------------------------------------------------------

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query) internal view returns (bool result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(eq(mload(clone), mload(other)), eq(mload(add(clone, 0xd)), mload(add(other, 0xd))))
        }
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


/**
 * @title Standard implementation of ERC1643 Document management
 */
contract Documents {

    struct Document {
        uint32 docIndex;    // Store the document name indexes
        uint64 lastModified; // Timestamp at which document details was last modified
        string data; // data of the document that exist off-chain
    }

    // mapping to store the documents details in the document
    mapping(string => Document) internal _documents;
    // mapping to store the document name indexes
    mapping(string => uint32) internal _docIndexes;
    // Array use to store all the document name present in the contracts
    string[] _docNames;

    // Document Events
    event DocumentRemoved(string indexed _name, string _data);
    event DocumentUpdated(string indexed _name, string _data);

    /**
     * @notice Used to attach a new document to the contract, or update the data or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _data Off-chain data of the document from where it is accessible to investors/advisors to read.
     */
    function _setDocument(string calldata _name, string calldata _data) internal {
        require(bytes(_name).length > 0, "Zero name is not allowed");
        require(bytes(_data).length > 0, "Should not be a empty data");
        // Document storage document = _documents[_name];
        if (_documents[_name].lastModified == uint64(0)) {
            _docNames.push(_name);
            _documents[_name].docIndex = uint32(_docNames.length);
        }
        _documents[_name] = Document(_documents[_name].docIndex, uint64(now), _data);
        emit DocumentUpdated(_name, _data);
    }

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */

    function _removeDocument(string calldata _name) internal {
        require(_documents[_name].lastModified != uint64(0), "Document should exist");
        uint32 index = _documents[_name].docIndex - 1;
        if (index != _docNames.length - 1) {
            _docNames[index] = _docNames[_docNames.length - 1];
            _documents[_docNames[index]].docIndex = index + 1; 
        }
        _docNames.pop();
        emit DocumentRemoved(_name, _documents[_name].data);
        delete _documents[_name];
    }

    /**
     * @notice Used to return the details of a document with a known name (`string`).
     * @param _name Name of the document
     * @return string The data associated with the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(string calldata _name) external view returns (string memory, uint256) {
        return (
            _documents[_name].data,
            uint256(_documents[_name].lastModified)
        );
    }

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return string List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (string[] memory) {
        return _docNames;
    }

    /**
     * @notice Used to retrieve the total documents in the smart contract.
     * @return uint256 Count of the document names present in the contract.
     */
    function getDocumentCount() external view returns (uint256) {
        return _docNames.length;
    }

    /**
     * @notice Used to retrieve the document name from index in the smart contract.
     * @return string Name of the document name.
     */
    function getDocumentName(uint256 _index) external view returns (string memory) {
        require(_index < _docNames.length, "Index out of bounds");
        return _docNames[_index];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity 0.6.12;

import "../interfaces/IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity 0.6.12;

// import "../../interfaces/IERC20.sol";

contract Owned {
    address private mOwner;
    bool private initialised;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function _initOwned(address _owner) internal {
        require(!initialised);
        mOwner = address(uint160(_owner));
        initialised = true;
        emit OwnershipTransferred(address(0), mOwner);
    }

    function owner() public view returns (address) {
        return mOwner;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == mOwner;
    }

    function transferOwnership(address _newOwner) public {
        require(isOwner());
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(mOwner, newOwner);
        mOwner = address(uint160(newOwner));
        newOwner = address(0);
    }
}

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 *  SafeMath + plus min(), max() and square root functions
 *    (square root needs 10*9 factor if using 18 decimals)
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts
 */
library SafeMathPlus {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a <= b ? a : b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity 0.6.12;

contract SafeTransfer {
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Event for token withdrawals.
    event TokensWithdrawn(address token, address to, uint256 amount);

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _safeTokenPayment(address _token, address payable _to, uint256 _amount) internal {
        if (address(_token) == ETH_ADDRESS) {
            _safeTransferETH(_to, _amount);
        } else {
            _safeTransfer(_token, _to, _amount);
        }

        emit TokensWithdrawn(_token, _to, _amount);
    }

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _tokenPayment(address _token, address payable _to, uint256 _amount) internal {
        if (address(_token) == ETH_ADDRESS) {
            _to.transfer(_amount);
        } else {
            _safeTransfer(_token, _to, _amount);
        }

        emit TokensWithdrawn(_token, _to, _amount);
    }

    /// @dev Transfer helper from UniswapV2 Router
    function _safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    /**
     * There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
     * Im trying to make it a habit to put external calls last (reentrancy)
     * You can put this in an internal function if you like.
     */
    function _safeTransfer(address token, address to, uint256 amount) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) = token.call(
            // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed
    }

    function _safeTransferFrom(address token, address from, uint256 amount) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) = token.call(
            // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
            abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 TransferFrom failed
    }

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Tangleswap/periphery/interfaces/INonfungiblePositionManager.sol";

library TangleswapCallingParams {
    function mintParams(
        address tokenX,
        address tokenY,
        uint24 fee,
        uint256 amountX,
        uint256 amountY,
        int24 leftPoint,
        int24 rightPoint,
        uint256 deadline
    ) internal view returns (INonfungiblePositionManager.MintParams memory params) {
        params.fee = fee;
        params.tickLower = leftPoint;
        params.tickUpper = rightPoint;
        params.deadline = deadline;
        params.recipient = address(this);
        params.amount0Min = 0;
        params.amount1Min = 0;
        if (tokenX < tokenY) {
            params.token0 = tokenX;
            params.token1 = tokenY;
            params.amount0Desired = amountX;
            params.amount1Desired = amountY;
        } else {
            params.token0 = tokenY;
            params.token1 = tokenX;
            params.amount0Desired = amountY;
            params.amount1Desired = amountX;
        }
    }
}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

pragma solidity 0.6.12;

import "../OpenZeppelin/math/SafeMath.sol";

contract Timelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;
    bool public admin_initialized;

    mapping(bytes32 => bool) public queuedTransactions;

    constructor(address admin_, uint delay_) public {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
        admin_initialized = false;
    }

    receive() external payable {}

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        // allows one time setting of admin for deployment purposes
        if (admin_initialized) {
            require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
            admin_initialized = true;
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(
            eta >= getBlockTimestamp().add(delay),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);

        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}

pragma solidity 0.6.12;

import "../Access/IHubAccessControls.sol";
import "../interfaces/IGnosisProxyFactory.sol";
import "../interfaces/ISafeGnosis.sol";
import "../interfaces/IERC20.sol";

contract GnosisSafeFactory {
    /// @notice ISafeGnosis interface.
    ISafeGnosis public safeGnosis;

    /// @notice IGnosisProxyFactory interface.
    IGnosisProxyFactory public proxyFactory;

    /// @notice IHubAccessControls interface.
    IHubAccessControls public accessControls;

    /// @notice Whether initialized or not.
    bool private initialised;

    /// @notice Mapping from user address to Gnosis Safe interface.
    mapping(address => ISafeGnosis) userToProxy;

    /// @notice Emitted when Gnosis Safe is created.
    event GnosisSafeCreated(address indexed user, address indexed proxy, address safeGnosis, address proxyFactory);

    /// @notice Emitted when Gnosis Vault is initialized.
    event IHubInitGnosisVault(address sender);

    /// @notice Emitted when Gnosis Safe is updated.
    event SafeGnosisUpdated(address indexed sender, address oldSafeGnosis, address newSafeGnosis);

    /// @notice Emitted when Proxy Factory is updated.
    event ProxyFactoryUpdated(address indexed sender, address oldProxyFactory, address newProxyFactory);

    /**
     * @notice Initializes Gnosis Vault with safe, proxy and accesscontrols contracts.
     * @param _accessControls AccessControls contract address.
     * @param _safeGnosis SafeGnosis contract address.
     * @param _proxyFactory ProxyFactory contract address.
     */
    function initGnosisVault(address _accessControls, address _safeGnosis, address _proxyFactory) public {
        require(!initialised);
        safeGnosis = ISafeGnosis(_safeGnosis);
        proxyFactory = IGnosisProxyFactory(_proxyFactory);
        accessControls = IHubAccessControls(_accessControls);
        initialised = true;
        emit IHubInitGnosisVault(msg.sender);
    }

    /**
     * @notice Function that can change Gnosis Safe contract address.
     * @param _safeGnosis SafeGnosis contract address.
     */
    function setSafeGnosis(address _safeGnosis) external {
        require(accessControls.hasOperatorRole(msg.sender), "GnosisVault.setSafeGnosis: Sender must be operator");
        address oldSafeGnosis = address(safeGnosis);
        safeGnosis = ISafeGnosis(_safeGnosis);
        emit SafeGnosisUpdated(msg.sender, oldSafeGnosis, address(safeGnosis));
    }

    /**
     * @notice Function that can change Proxy Factory contract address.
     * @param _proxyFactory ProxyFactory contract address.
     */
    function setProxyFactory(address _proxyFactory) external {
        require(accessControls.hasOperatorRole(msg.sender), "GnosisVault.setProxyFactory: Sender must be operator");
        address oldProxyFactory = address(proxyFactory);
        proxyFactory = IGnosisProxyFactory(_proxyFactory);
        emit ProxyFactoryUpdated(msg.sender, oldProxyFactory, address(proxyFactory));
    }

    /**
     * @notice Function for creating a new safe.
     * @param _owners List of Safe owners.
     * @param _threshold Number of required confirmations for a Safe transaction.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @param fallbackHandler Handler for fallback calls to this contract.
     * @param paymentToken Token that should be used for the payment (0 is ETH).
     * @param payment Value that should be paid.
     * @param paymentReceiver Address that should receive the payment (or 0 if tx.origin).
     */
    function createSafe(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) public returns (ISafeGnosis proxy) {
        bytes memory safeGnosisData = abi.encode(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            _owners,
            _threshold,
            to,
            data,
            fallbackHandler,
            paymentToken,
            payment,
            paymentReceiver
        );
        proxy = proxyFactory.createProxy(safeGnosis, safeGnosisData);
        userToProxy[msg.sender] = proxy;
        emit GnosisSafeCreated(msg.sender, address(proxy), address(safeGnosis), address(proxyFactory));
        return proxy;
    }
    /// GP: Can we also use the proxy with a nonce? Incase we need it.
    /// GP: Can we have a simplifed version with a few things already set? eg an ETH by default verision.
    /// GP: Can we set empty data or preset the feedback handler? Whats the minimum feilds required?
}

pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";
import "../Utils/SafeMathPlus.sol";
import "../Utils/SafeTransfer.sol";
import "../OpenZeppelin/math/SafeMath.sol";
import "../OpenZeppelin/utils/EnumerableSet.sol";

contract TokenVault is SafeTransfer {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Struct representing each batch of tokens locked in the vault.
    struct Item {
        uint256 amount;
        uint256 unlockTime;
        address owner;
        uint256 userIndex;
    }

    /// @notice Struct that keeps track of assets belonging to a particular user.
    struct UserInfo {
        mapping(address => uint256[]) lockToItems;
        EnumerableSet.AddressSet lockedItemsWithUser;
    }

    /// @notice Mapping from user address to UserInfo struct.
    mapping(address => UserInfo) users;

    /// @notice Id number of the vault deposit.
    uint256 public depositId;

    /// @notice An array of all the deposit Ids.
    uint256[] public allDepositIds;

    /// @notice Mapping from item Id to the Item struct.
    mapping(uint256 => Item) public lockedItem;

    /// @notice Emitted when tokens are locked inside the vault.
    event onLock(address tokenAddress, address user, uint256 amount);

    /// @notice Emitted when tokens are unlocked from the vault.
    event onUnlock(address tokenAddress, uint256 amount);

    /**
     * @notice Function for locking tokens in the vault.
     * @param _tokenAddress Address of the token locked.
     * @param _amount Number of tokens locked.
     * @param _unlockTime Timestamp number marking when tokens get unlocked.
     * @param _withdrawer Address where tokens can be withdrawn after unlocking.
     */
    function lockTokens(
        address _tokenAddress,
        uint256 _amount,
        uint256 _unlockTime,
        address payable _withdrawer
    ) public returns (uint256 _id) {
        require(_amount > 0, "token amount is Zero");
        require(_unlockTime < 10000000000, "Enter an unix timestamp in seconds, not miliseconds");
        require(_withdrawer != address(0));
        _safeTransferFrom(_tokenAddress, msg.sender, _amount);

        _id = ++depositId;

        lockedItem[_id].amount = _amount;
        lockedItem[_id].unlockTime = _unlockTime;
        lockedItem[_id].owner = _withdrawer;

        allDepositIds.push(_id);

        UserInfo storage userItem = users[_withdrawer];
        userItem.lockedItemsWithUser.add(_tokenAddress);
        userItem.lockToItems[_tokenAddress].push(_id);
        uint256 userIndex = userItem.lockToItems[_tokenAddress].length - 1;
        lockedItem[_id].userIndex = userIndex;

        emit onLock(_tokenAddress, msg.sender, lockedItem[_id].amount);
    }

    /**
     * @notice Function for withdrawing tokens from the vault.
     * @param _tokenAddress Address of the token to withdraw.
     * @param _index Index number of the list with Ids.
     * @param _id Id number.
     * @param _amount Number of tokens to withdraw.
     */
    function withdrawTokens(address _tokenAddress, uint256 _index, uint256 _id, uint256 _amount) external {
        require(_amount > 0, "token amount is Zero");
        uint256 id = users[msg.sender].lockToItems[_tokenAddress][_index];
        Item storage userItem = lockedItem[id];
        require(id == _id && userItem.owner == msg.sender, "LOCK MISMATCH");
        // solhint-disable-next-line not-rely-on-time
        require(userItem.unlockTime < block.timestamp, "Not unlocked yet");
        userItem.amount = userItem.amount.sub(_amount);

        if (userItem.amount == 0) {
            uint256[] storage userItems = users[msg.sender].lockToItems[_tokenAddress];
            userItems[_index] = userItems[userItems.length - 1];
            userItems.pop();
        }

        _safeTransfer(_tokenAddress, msg.sender, _amount);

        emit onUnlock(_tokenAddress, _amount);
    }

    /**
     * @notice Function to retrieve data from the Item under user index number.
     * @param _index Index number of the list with Item ids.
     * @param _tokenAddress Address of the token corresponding to this Item.
     * @param _user User address.
     * @return Items token amount number, Items unlock timestamp, Items owner address, Items Id number
     */
    function getItemAtUserIndex(
        uint256 _index,
        address _tokenAddress,
        address _user
    ) external view returns (uint256, uint256, address, uint256) {
        uint256 id = users[_user].lockToItems[_tokenAddress][_index];
        Item storage item = lockedItem[id];
        return (item.amount, item.unlockTime, item.owner, id);
    }

    /**
     * @notice Function to retrieve token address at desired index for the specified user.
     * @param _user User address.
     * @param _index Index number.
     * @return Token address.
     */
    function getUserLockedItemAtIndex(address _user, uint256 _index) external view returns (address) {
        UserInfo storage user = users[_user];
        return user.lockedItemsWithUser.at(_index);
    }

    /**
     * @notice Function to retrieve all the data from Item struct under given Id.
     * @param _id Id number.
     * @return All the data for this Id (token amount number, unlock time number, owner address and user index number)
     */
    function getLockedItemAtId(uint256 _id) external view returns (uint256, uint256, address, uint256) {
        Item storage item = lockedItem[_id];
        return (item.amount, item.unlockTime, item.owner, item.userIndex);
    }
}