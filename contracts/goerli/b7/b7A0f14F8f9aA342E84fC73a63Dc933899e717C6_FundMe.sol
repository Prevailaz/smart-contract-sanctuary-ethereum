// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // only accepts funds of more than 50 dollars
        uint256 minimumUSD = 5 * 10 * 18;
        require(getConversionRate(msg.value) >= minimumUSD, "Funding are accepted starting from 50 USD, please increase the amount !");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getEntranceFee() public view returns(uint256) {
        uint256 mininumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mininumUSD * precision)/ price;
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethPriceinUSD = (ethAmount * ethPrice) / 1000000000000000000;
        return ethPriceinUSD;
    }

    function withdraw() public onlyOwner payable {
        (payable(msg.sender)).transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex ++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function fetchContributionBySender(address senderAddress) public view returns (uint256) {
        return addressToAmountFunded[senderAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}