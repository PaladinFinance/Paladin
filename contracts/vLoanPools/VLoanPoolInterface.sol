pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

interface VLoanPoolInterface {
    //Events
    event StartLoan(
        address borrower,
        address underlying,
        uint amount,
        uint startBlock,
        uint endBlock
    );

    event ExpandLoan(
        address borrower,
        address underlying,
        uint oldEndBlock,
        uint newEndBlock
    );

    event KillLoan(
        address borrower,
        address underlying,
        address killer,
        uint endBlock
    );


    //Functions
    function initiate(uint amount, uint endBlock, uint feesAmount) external returns(bool);
    function expandLoan(uint newEndBlock, uint additionalFeesAmount) external returns(bool);
    function killLoan(address killer) external returns(bool);
}