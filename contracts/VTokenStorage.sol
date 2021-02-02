pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./PaladinControllerInterface.sol";
import "./InterestInterface.sol";
import "./VTokenInterface.sol";
import "./utils/IERC20.sol";

contract VTokenStorage {

    struct Borrow {
        address borrower;
        address loanPool;
        uint amount;
        address underlying;
        uint feesAmount;
        uint borrowIndex;
        bool closed;
    }

    //VToken variables & Mappings
    IERC20 public underlying;

    bool internal entered = false;

    address payable internal admin;

    uint public totalReserve;
    uint public totalBorrowed;
    uint public totalSupply;

    uint internal constant maxBorrowRate = 0.0002e18;

    uint internal constant killFactor = 0.15e18;
    uint internal constant killerRatio = 0.98e18;

    uint internal initialExchangeRate = 0.02e18;
    uint public reserveFactor = 0.2e18;
    uint public accrualBlockNumber;
    uint public borrowIndex;

    uint constant internal mantissaScale = 1e18;

    mapping (address => address[]) internal borrowsByUser;
    mapping (address => Borrow) internal loanToBorrow;
    address[] internal borrows;


    //Modules
    PaladinControllerInterface public controller;
    InterestInterface internal interestModule;
    
}