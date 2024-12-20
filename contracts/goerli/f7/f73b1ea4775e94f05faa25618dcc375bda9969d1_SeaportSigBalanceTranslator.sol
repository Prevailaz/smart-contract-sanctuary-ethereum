// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SeaportSigBalanceTranslator {
    enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}


enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}


struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}


struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}



struct BalanceOut {
    address token;
    uint256 amount;
}

struct BalanceIn {
    address token;
    uint256 amount;
}


    function evalEIP712Buffer(OrderComponents memory order) public view returns(BalanceOut[] memory balanceOut, BalanceIn[] memory balanceIn, uint256 expirationTime) { 
        BalanceOut[] memory balanceOut = new BalanceOut[](order.offer.length);
        BalanceIn[] memory balanceIn = new BalanceIn[](order.consideration.length);

        for (uint i; i < order.offer.length; i++) {   
            balanceOut[i] = BalanceOut(order.offer[i].token, order.offer[i].startAmount);
        }

        for (uint i; i < order.consideration.length; i++) {   
            balanceIn[i] = BalanceIn(order.consideration[i].token, order.consideration[i].startAmount);
        }

      return (balanceOut, balanceIn, order.endTime);
    }

}