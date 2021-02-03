pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Ineterest Module for Paladin vToken pools  */
/// @author Paladin - Valentin VIGER
interface VLoanPoolInterface {

    //Events

    /** @notice Event emitted when the Loan starts */
    event StartLoan(
        address borrower,
        address underlying,
        uint amount,
        uint startBlock
    );

    /** @notice Event when the fee amount in the loan is updated */
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