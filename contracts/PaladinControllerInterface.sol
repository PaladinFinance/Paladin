pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

interface PaladinControllerInterface {
    
    //Events

    event NewVToken(address vToken);

    event NewAdmin(address oldAdmin, address newAdmin);


    //Functions

    function getVTokens() external view returns(address[] memory);
    function addNewVToken(address vToken) external returns(bool);
    function removeVToken(address vToken) external returns(bool);

    function getLoansForBorrower(address borrower) external returns(address[] memory);

    function setNewAdmin(address payable newAdmin) external returns(bool);

    function deposit(address vToken, address dest, uint amount) external returns(uint);
    function withdraw(address vToken, address dest, uint amount) external returns(uint);
    function borrow(address vToken, address dest, uint amount, address feeToken, uint feeAmount) external returns(uint);
    function expandBorrow(address vToken, address dest, address loanPool, address feeToken, uint feeAmount) external returns(uint);
    function killBorrow(address vToken, address killer, address loanPool) external returns(uint);

    function withdrawPossible(address vToken, uint amount) external returns(bool);
    function borrowPossible(address vToken, uint amount, address feeToken, uint feeAmount) external returns(bool);

    function depositVerify(address vToken, address dest, uint amount) external returns(bool);
    function withdrawVerify(address vToken, address dest, uint amount) external returns(bool);
    function borrowVerify(address vToken, address dest, uint amount, address loanPool) external returns(bool);
}