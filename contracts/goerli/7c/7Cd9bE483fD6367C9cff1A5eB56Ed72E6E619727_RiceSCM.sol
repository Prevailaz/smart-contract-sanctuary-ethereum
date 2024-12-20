pragma solidity ^0.5.8;

import './ConsumerRole.sol';
import './DistributorRole.sol';
import './FarmerRole.sol';
import './RetailerRole.sol';


contract AccessControl is FarmerRole, DistributorRole, RetailerRole, ConsumerRole {
  constructor() public {}
}

pragma solidity ^0.5.8;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'ConsumerRole' to manage this role - add, remove, check
contract ConsumerRole {
    using Roles for Roles.Role;

    // Define 2 events, one for Adding, and other for Removing
    event ConsumerAdded(address indexed account);
    event ConsumerRemoved(address indexed account);

    // Define a struct 'consumers' by inheriting from 'Roles' library, struct Role
    Roles.Role private consumers;

    // In the constructor make the address that deploys this contract the 1st consumer
    constructor() public {
        _addConsumer(msg.sender);
    }

    // Define an internal function '_addConsumer' to add this role, called by 'addConsumer'
    function _addConsumer(address account) internal {
        consumers.add(account);
        emit ConsumerAdded(account);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyConsumer() {
        require(isConsumer(msg.sender), "Only consumers allowed.");
        _;
    }

    // Define a function 'isConsumer' to check this role
    function isConsumer(address account) public view returns (bool) {
        return consumers.has(account);
    }

    // Define a function 'addConsumer' that adds this role
    function addConsumer(address account) public onlyConsumer {
        _addConsumer(account);
    }

    // Define a function 'renounceConsumer' to renounce this role
    function renounceConsumer() public {
        _removeConsumer(msg.sender);
    }

    // Define an internal function '_removeConsumer' to remove this role, called by 'removeConsumer'
    function _removeConsumer(address account) internal {
        consumers.remove(account);
        emit ConsumerRemoved(account);
    }
}

pragma solidity ^0.5.8;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'DistributorRole' to manage this role - add, remove, check
contract DistributorRole {
    using Roles for Roles.Role;

    // Define 2 events, one for Adding, and other for Removing
    event DistributorAdded(address indexed account);
    event DistributorRemoved(address indexed account);

    // Define a struct 'distributors' by inheriting from 'Roles' library, struct Role
    Roles.Role private distributors;

    // In the constructor make the address that deploys this contract the 1st distributor
    constructor() public {
        _addDistributor(msg.sender);
    }

    // Define an internal function '_addDistributor' to add this role, called by 'addDistributor'
    function _addDistributor(address account) internal {
        distributors.add(account);
        emit DistributorAdded(account);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyDistributor() {
        require(isDistributor(msg.sender), "Only distributors allowed.");
        _;
    }

    // Define a function 'isDistributor' to check this role
    function isDistributor(address account) public view returns (bool) {
        return distributors.has(account);
    }

    // Define a function 'addDistributor' that adds this role
    function addDistributor(address account) public onlyDistributor {
        _addDistributor(account);
    }

    // Define a function 'renounceDistributor' to renounce this role
    function renounceDistributor() public {
        _removeDistributor(msg.sender);
    }

    // Define an internal function '_removeDistributor' to remove this role, called by 'removeDistributor'
    function _removeDistributor(address account) internal {
        distributors.remove(account);
        emit DistributorRemoved(account);
    }
}

pragma solidity ^0.5.8;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'FarmerRole' to manage this role - add, remove, check
contract FarmerRole {
    using Roles for Roles.Role;

    // Define 2 events, one for Adding, and other for Removing
    event FarmerAdded(address indexed account);
    event FarmerRemoved(address indexed account);

    // Define a struct 'farmers' by inheriting from 'Roles' library, struct Role
    Roles.Role private farmers;

    constructor() public {
        _addFarmer(msg.sender);
    }

    // Define an internal function '_addFarmer' to add this role, called by 'addFarmer'
    function _addFarmer(address account) internal {
        farmers.add(account);
        emit FarmerAdded(account);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyFarmer() {
        require(isFarmer(msg.sender), "Only farmers allowed.");
        _;
    }

    // Define a function 'isFarmer' to check this role
    function isFarmer(address account) public view returns (bool) {
        return farmers.has(account);
    }

    // Define a function 'addFarmer' that adds this role
    function addFarmer(address account) public onlyFarmer {
        _addFarmer(account);
    }

    // Define a function 'renounceFarmer' to renounce this role
    function renounceFarmer() public {
        _removeFarmer(msg.sender);
    }

    // Define an internal function '_removeFarmer' to remove this role, called by 'removeFarmer'
    function _removeFarmer(address account) internal {
        farmers.remove(account);
        emit FarmerRemoved(account);
    }
}

pragma solidity ^0.5.8;

/// Provides basic authorization control
contract Ownable {
    address private origOwner;

    // Define an Event
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// Assign the contract to an owner
    constructor() internal {
        origOwner = msg.sender;
        emit TransferOwnership(address(0), origOwner);
    }

    /// Look up the address of the owner
    function owner() public view returns (address) {
        return origOwner;
    }

    /// Define a function modifier 'onlyOwner'
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /// Check if the calling address is the owner of the contract
    function isOwner() public view returns (bool) {
        return msg.sender == origOwner;
    }

    /// Define a function to renounce ownerhip
    function renounceOwnership() public onlyOwner {
        emit TransferOwnership(origOwner, address(0));
        origOwner = address(0);
    }

    /// Define a public function to transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /// Define an internal function to transfer ownership
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit TransferOwnership(origOwner, newOwner);
        origOwner = newOwner;
    }
}

pragma solidity ^0.5.8;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'RetailerRole' to manage this role - add, remove, check
contract RetailerRole {
    using Roles for Roles.Role;
    // Define 2 events, one for Adding, and other for Removing
    event RetailerAdded(address indexed account);
    event RetailerRemoved(address indexed account);

    // Define a struct 'retailers' by inheriting from 'Roles' library, struct Role
    Roles.Role private retailers;

    // In the constructor make the address that deploys this contract the 1st retailer
    constructor() public {
        _addRetailer(msg.sender);
    }

    // Define an internal function '_addRetailer' to add this role, called by 'addRetailer'
    function _addRetailer(address account) internal {
        retailers.add(account);
        emit RetailerAdded(account);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyRetailer() {
        require(isRetailer(msg.sender), "Only retailers allowed.");
        _;
    }

    // Define a function 'isRetailer' to check this role
    function isRetailer(address account) public view returns (bool) {
        return retailers.has(account);
    }

    // Define a function 'addRetailer' that adds this role
    function addRetailer(address account) public onlyRetailer {
        _addRetailer(account);
    }

    // Define a function 'renounceRetailer' to renounce this role
    function renounceRetailer() public {
        _removeRetailer(msg.sender);
    }

    // Define an internal function '_removeRetailer' to remove this role, called by 'removeRetailer'
    function _removeRetailer(address account) internal {
        retailers.remove(account);
        emit RetailerRemoved(account);
    }
}

pragma solidity ^0.5.8;

import "./AccessControl.sol";
import "./Ownable.sol";

// Define a contract 'Supplychain'
contract RiceSCM is Ownable, AccessControl {
    // Define a variable called 'upc' for Universal Product Code (UPC)
    uint upc;

    // Define a variable called 'sku' for Stock Keeping Unit (SKU)
    uint sku;

    // Define a public mapping 'items' that maps the UPC to an Item.
    mapping(uint => Item) items;

    // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash,
    // that track its journey through the supply chain -- to be sent from DApp.
    mapping(uint => string[]) itemsHistory;

    // Define enum 'State' with the following values:
    enum State {
        New, // 0
        Harvested, // 1
        // Processed,  // 2
        // Packed,     // 3
        ForSale, // 4
        Sold, // 5
        Shipped, // 6
        Received, // 7
        Purchased // 8
    }

    State constant defaultState = State.Harvested;

    // Define a struct 'Item' with the following fields:
    struct Item {
        uint sku; // Stock Keeping Unit (SKU)
        uint upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
        address ownerID; // Metamask-Ethereum address of the current owner as the product moves through 8 stages
        address originFarmerID; // Metamask-Ethereum address of the Farmer
        string originFarmerName; // Farmer Name
        string originFarmInformation; // Farmer Information
        string originFarmLatitude; // Farm Latitude
        string originFarmLongitude; // Farm Longitude
        uint productID; // Product ID potentially same as upc (TODO add SKU in future)
        string productName; // Product Notes
        uint productPrice; // Product Price
        State itemState; // Product State as represented in the enum above
        address distributorID; // Metamask-Ethereum address of the Distributor
        address retailerID; // Metamask-Ethereum address of the Retailer
        address consumerID; // Metamask-Ethereum address of the Consumer
    }

    // Define 8 events with the same 8 state values and accept 'upc' as input argument
    event Harvested(uint indexed upc);
    event ForSale(uint indexed upc, uint price);
    event Sold(uint indexed upc, address distributorID);
    event Shipped(uint indexed upc);
    event Received(uint indexed upc, address retailerID);
    event Purchased(uint indexed upc, address purchaserID);

    modifier newitem(uint _upc) {
        require(items[_upc].itemState == State.New, "item already exists");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Harvested
    modifier harvested(uint _upc) {
        require(items[_upc].itemState == State.Harvested, "invalid state, expected Harvested");
        _;
    }

    modifier onlyItemOwnerOrOwner(uint _upc) {
        require(items[_upc].ownerID == msg.sender || isOwner(), "caller is not the owner of the item");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is ForSale
    modifier forSale(uint _upc) {
        require(items[_upc].itemState == State.ForSale, "invalid state, expected ForSale");
        _;
    }

    // Define a modifier that checks if the paid amount is sufficient to cover the price
    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    // Define a modifier that checks the price and refunds the remaining balance
    modifier checkValue(uint _upc) {
        _;
        uint _price = items[_upc].productPrice;
        uint amountToReturn = msg.value - _price;
        msg.sender.transfer(amountToReturn);
    }

    // Define a modifier that checks if an item.state of a upc is Sold
    modifier sold(uint _upc) {
        require(items[_upc].itemState == State.Sold, "invalid state, expected Sold");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Shipped
    modifier shipped(uint _upc) {
        require(items[_upc].itemState == State.Shipped, "invalid state, expected Shipped");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Received
    modifier received(uint _upc) {
        require(items[_upc].itemState == State.Received, "invalid state, expected Received");
        _;
    }

    constructor() public payable {
        // owner = msg.sender;
        sku = 1;
        upc = 1;
    }

    // Define a function 'kill' if required
    function kill() public {
        if (msg.sender == owner()) {
            selfdestruct(makePayable(owner()));
        }
    }

    function makePayable(address _addr) private pure returns (address payable) {
        return address(uint160(_addr));
    }

    // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
    function harvestItem(
        uint _upc,
        address _originFarmerID,
        string memory _originFarmerName,
        string memory _originFarmLatitude,
        string memory _originFarmLongitude,
        string memory _productName
    ) public onlyFarmer newitem(_upc) {
        // Add the new item as part of Harvest
        items[_upc].upc = _upc;
        items[_upc].sku = sku;
        items[_upc].productID = sku + _upc;
        items[_upc].originFarmerID = _originFarmerID;
        items[_upc].ownerID = _originFarmerID;
        items[_upc].originFarmerName = _originFarmerName;
        items[_upc].originFarmLatitude = _originFarmLatitude;
        items[_upc].originFarmLongitude = _originFarmLongitude;
        items[_upc].productName = _productName;
        items[_upc].itemState = State.Harvested;

        // Increment sku
        sku = sku + 1;

        // Emit the appropriate event
        emit Harvested(_upc);
    }

    // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
    function sellItem(
        uint _upc,
        uint _price
    )
        public
        // Call modifier to check if upc has passed previous supply chain stage
        harvested(_upc)
        onlyFarmer
        // Call modifier to verify caller of this function
        onlyItemOwnerOrOwner(_upc)
    {
        // Update the appropriate fields
        items[_upc].productPrice = _price;
        items[_upc].itemState = State.ForSale;

        // Emit the appropriate event
        emit ForSale(_upc, _price);
    }

    // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
    // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough,
    // and any excess ether sent is refunded back to the buyer
    function buyItem(
        uint _upc
    )
        public
        payable
        // Call modifier to check if upc has passed previous supply chain stage
        forSale(_upc)
        // Call modifer to check if buyer has paid enough
        paidEnough(items[_upc].productPrice)
        // Only distributors are allowed to buy
        onlyDistributor
        // Call modifer to send any excess ether back to buyer
        checkValue(_upc)
    {
        // Update the appropriate fields - ownerID, distributorID, itemState
        items[_upc].ownerID = msg.sender;
        items[_upc].distributorID = msg.sender;
        items[_upc].itemState = State.Sold;

        // Transfer money to farmer
        address payable farmerAddress = makePayable(items[_upc].originFarmerID);
        farmerAddress.transfer(items[_upc].productPrice);

        // emit the appropriate event
        emit Sold(_upc, items[_upc].distributorID);
    }

    // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
    // Use the above modifers to check if the item is sold
    function shipItem(
        uint _upc
    )
        public
        // Call modifier to check if upc has passed previous supply chain stage
        sold(_upc)
        // Only distributors are allowed to buy
        onlyDistributor
        // Call modifier to verify caller of this function
        onlyItemOwnerOrOwner(_upc)
    {
        // Update the appropriate fields
        items[_upc].itemState = State.Shipped;

        // Emit the appropriate event
        emit Shipped(_upc);
    }

    // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
    // Use the above modifiers to check if the item is shipped
    function receiveItem(
        uint _upc
    )
        public
        // Call modifier to check if upc has passed previous supply chain stage
        shipped(_upc)
        // Access Control List enforced by calling Smart Contract / DApp
        onlyRetailer
    {
        // Update the appropriate fields - ownerID, retailerID, itemState
        items[_upc].ownerID = msg.sender;
        items[_upc].retailerID = msg.sender;
        items[_upc].itemState = State.Received;

        // Emit the appropriate event
        emit Received(_upc, msg.sender);
    }

    // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
    // Use the above modifiers to check if the item is received
    function purchaseItem(
        uint _upc
    )
        public
        // Call modifier to check if upc has passed previous supply chain stage
        received(_upc)
        // Access Control List enforced by calling Smart Contract / DApp
        onlyConsumer
    {
        // Update the appropriate fields - ownerID, consumerID, itemState
        items[_upc].ownerID = msg.sender;
        items[_upc].consumerID = msg.sender;
        items[_upc].itemState = State.Purchased;

        // Emit the appropriate event
        emit Purchased(_upc, msg.sender);
    }

    // Define a function 'fetchItemBufferOne' that fetches the data
    function fetchItemBufferOne(
        uint _upc
    )
        public
        view
        returns (
            uint itemSKU,
            uint itemUPC,
            address ownerID,
            address originFarmerID,
            string memory originFarmerName,
            string memory originFarmLatitude,
            string memory originFarmLongitude
        )
    {
        // Assign values to the 8 parameters
        itemSKU = items[_upc].upc;
        itemUPC = items[_upc].sku;
        ownerID = items[_upc].ownerID;
        originFarmerID = items[_upc].originFarmerID;
        originFarmerName = items[_upc].originFarmerName;
        originFarmLatitude = items[_upc].originFarmLatitude;
        originFarmLongitude = items[_upc].originFarmLongitude;

        return (itemSKU, itemUPC, ownerID, originFarmerID, originFarmerName, originFarmLatitude, originFarmLongitude);
    }

    // Define a function 'fetchItemBufferTwo' that fetches the data
    function fetchItemBufferTwo(
        uint _upc
    )
        public
        view
        returns (
            uint itemSKU,
            uint itemUPC,
            uint productID,
            string memory productName,
            uint productPrice,
            uint itemState,
            address distributorID,
            address retailerID,
            address consumerID
        )
    {
        // Assign values to the 9 parameters
        itemSKU = items[_upc].upc;
        itemUPC = items[_upc].sku;
        productID = items[_upc].productID;
        productName = items[_upc].productName;
        productPrice = items[_upc].productPrice;
        itemState = uint256(items[_upc].itemState);
        distributorID = items[_upc].distributorID;
        retailerID = items[_upc].retailerID;
        consumerID = items[_upc].consumerID;
        return (itemSKU, itemUPC, productID, productName, productPrice, itemState, distributorID, retailerID, consumerID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}