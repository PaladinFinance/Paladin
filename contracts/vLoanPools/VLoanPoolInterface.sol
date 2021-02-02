pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

interface VLoanPoolInterface {
    //Events
    event StartLoan(
        address borrower,
        address underlying,
        uint amount,
        uint startBlock
    );

    event ExpandLoan(
        address borrower,
        address underlying,
        uint addedFees
    );


    //Functions
    function initiate(uint _amount, uint _feesAmount) external returns(bool);
    function expand(uint _newFeesAmount) external returns(bool);
    function closeLoan(uint _usedAmount) external;
    function killLoan(address _killer, uint killerRatio) external;
}