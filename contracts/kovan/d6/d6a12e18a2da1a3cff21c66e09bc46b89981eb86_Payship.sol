/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

//
// Payship
// Interface: VSDC.info Swapship.org Payship.org
// Virtual Stable Denomination Contract: Lending/Borrowing Contract V1
// May 2021
//

// //////////////////////////////////////////////////////////////////////////////// //
//                                                                                  //
//                               ////   //////   /////                              //
//                              //        //     //                                 //
//                              //        //     /////                              //
//                                                                                  //
//                              Never break the chain.                              //
//                                   www.RTC.wtf                                    //
//                                                                                  //
// //////////////////////////////////////////////////////////////////////////////// //

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function devsdcription() external view returns (string memory);
    function version() external view returns (uint256);

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

// File: contracts/ERC20Interface.sol

pragma solidity ^0.8.0;

interface ERC20Interface {
    function mint(address usr, uint wad) external;
    function burnFrom(address src, uint wad) external;
    function balanceOf(address usr) external returns (uint);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// Copyright (C) 2021 RTC/Veronika
// SPDX-License-Identifier: No License
// File: contracts/Payship00.sol

pragma solidity ^0.8.0;

contract Payship {
    AggregatorV3Interface internal ethpf;
    ERC20Interface public vsdc;

    struct FaucetInfo {
      uint depo;
      uint debt;
    }

    uint public ctvb = 1e20;        // Collateral-to-Value Base
    uint public ctv = 80;           // Collateral-to-Value

    uint public frb = 1000;         // Fee Rate Base
    uint public fr = frb - 997;     // Fee Rate

    uint public ceil = 1e23;        // Minting ceilling

    address public _chest = 0xeaA5A8e2946a586A06A8B16Be2E87d78F556d835;
    address public _vsdc = 0xF757c584aF5846446d0989775D68Ef7DD963Df55;

    mapping (address => FaucetInfo) public faucets;
    mapping (address => uint) public blocks;

    event  Deposit(address indexed dst, uint wad);
    event  Borrow(address indexed dst, uint val);
    event  Repay(address indexed dst, uint val);
    event  Withdrawal(address indexed src, uint wad);
    event  Liquidation(address indexed src, address indexed dst, uint wad);

    constructor() {
        vsdc = ERC20Interface(_vsdc);

        /*
         * Network: Kovan
         * Aggregator: ETH/USD
         * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
         *
         * Network: Mainnet
         * Aggregator: ETH/USD
         * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
         */
         ethpf = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    function deposit() public payable {
        require(blocks[msg.sender] < block.number, "deposit: Block alredy used. Try next block.");
        require(msg.value > 0, "deposit: Amount must be greater than zero. Increase amount.");
        uint wad = msg.value;
        uint prx = getPrice();

        require(prx > 0, "deposit: Price feed cannot be zero. Try again.");
        uint val = (wad * prx * ctv * 3) / (4 * ctvb);

        require(val <= ceil, "deposit: Minting ceiling reached. Decrease deposit.");
        vsdc.mint(msg.sender, val); ceil -= val;
        faucets[msg.sender].depo += wad;
        faucets[msg.sender].debt += val;

        blocks[msg.sender] = block.number;
        emit Deposit(msg.sender, msg.value);
    }

    function borrow(uint size) public {
        require(blocks[msg.sender] < block.number, "borrow: Block alredy used. Try next block.");
        uint depo = faucets[msg.sender].depo;
        uint debt = faucets[msg.sender].debt;
        uint prx = getPrice();

        require(prx > 0, "borrow: Price feed cannot be zero. Try again.");
        uint val = depo * prx * ctv / ctvb;
        
        require(val > 0 && val > debt, "borrow: Amount cannot exceed available credit. Increase collateral.");
        uint ext = val - debt;

        require(ext <= ceil && size <= ext, "borrow: Minting ceiling reached. Decrease loan.");
        vsdc.mint(msg.sender, size); ceil -= size;
        faucets[msg.sender].debt += size;

        blocks[msg.sender] = block.number;
        emit Borrow(msg.sender, size);
    }

    function repay(uint val) public {
        require(blocks[msg.sender] < block.number, "repay: Block alredy used. Try next block.");
        require(val > 0 && val <= faucets[msg.sender].debt, "repay: Amount must be greater than zero and less/equal than actual debt. Try again.");
        uint fee = val * fr / frb;
        uint tot = val + fee;

        require(tot <= vsdc.balanceOf(msg.sender), "repay: Total amount exceeds balance. Decrease amount.");
        if (fee > 0) {
            vsdc.transferFrom(msg.sender,_chest,fee);
        }

        vsdc.burnFrom(msg.sender,val); ceil += val;
        faucets[msg.sender].debt -= val;

        blocks[msg.sender] = block.number;
        emit Repay(msg.sender, val);
    }

    function withdraw(uint wad) public {
        require(blocks[msg.sender] < block.number, "withdraw: Block alredy used. Try next block.");
        uint depo = faucets[msg.sender].depo;
        uint debt = faucets[msg.sender].debt;
        address payable _to = payable(msg.sender);

        require(wad > 0 && depo >= wad, "withdraw: Amount must be greater than zero and less/equal than actual deposit. Try again.");
        uint prx = getPrice();

        require(prx > 0, "withdraw: Price feed cannot be zero. Try again.");
        uint depoval = depo * prx * ctv / ctvb;

        require(depoval >= debt, "withdraw: Debt value exceeds collateral. Increase collateral.");
        uint val = debt * wad / depo;
        uint fee = val * fr / frb;
        uint tot = val + fee;

        require(tot <= vsdc.balanceOf(msg.sender), "withdraw: Total amount exceeds balance. Decrease amount.");
        if (fee > 0) {
            vsdc.transferFrom(msg.sender,_chest,fee);
        }

        if (val > 0) {
            vsdc.burnFrom(msg.sender, val); ceil += val;
        }

        (bool sent, bytes memory data) = _to.call{value: wad}("");

        require(sent, "withdraw: Collateral withdraw failed. Try again.");
        faucets[msg.sender].depo -= wad;
        faucets[msg.sender].debt -= val;

        blocks[msg.sender] = block.number;
        emit Withdrawal(msg.sender, wad);
    }

    function liquidate(address usr) public {
        require(blocks[msg.sender] < block.number, "liquidate: Block alredy used. Try next block.");
        require(faucets[usr].depo > 0 && faucets[usr].debt > 0);
        uint depo = faucets[usr].depo;
        uint debt = faucets[usr].debt;

        address payable _to = payable(msg.sender);
        uint prx = getPrice();

        require(prx > 0);
        uint depoval = depo * prx / 1e18;

        require(depoval < debt);
        uint val = debt + (debt - depoval);
        uint fee = val * fr / frb;
        uint tot = val + fee;

        require(tot <= vsdc.balanceOf(msg.sender));
        if (fee > 0) {
            vsdc.transferFrom(msg.sender,_chest,fee);
        }

        if (val > 0) {
            vsdc.burnFrom(msg.sender, val); ceil += val;
        }

        (bool sent, bytes memory data) = _to.call{value: depo}("");

        require(sent);
        faucets[usr].depo = 0;
        faucets[usr].debt = 0;

        blocks[msg.sender] = block.number;
        emit Liquidation(usr, msg.sender, depo);
    }

    function sink(address usr) public {
        require(blocks[msg.sender] < block.number, "sink: Block alredy used. Try next block.");
        require(faucets[usr].depo > 0 && faucets[usr].debt > 0);
        uint depo = faucets[usr].depo;
        uint debt = faucets[usr].debt;
        uint prx = getPrice();

        require(prx > 0);
        uint depoval = depo * prx / 1e18;

        require(depoval < debt);
        faucets[usr].depo = 0;
        faucets[usr].debt = 0;

        blocks[msg.sender] = block.number;
        emit Liquidation(usr, address(this), depo);
    }

    function getStatus(address usr) public view returns (bool) {
        uint depo = faucets[usr].depo;
        uint debt = faucets[usr].debt;
        uint prx = getPrice();

        require(prx > 0);
        uint depoval = depo * prx / 1e18;

        if (depoval < debt) return false;
        return true;
    }

    function getPrice() public view returns (uint) {
        uint price = 0;
        
        (
            uint80 roundID, 
            int ticker,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethpf.latestRoundData();

        if(ticker < 0) {
            price = uint(-ticker);
        }
        else {
            price = uint(ticker);
        }
        
        return (price * 1e10);
    }
}