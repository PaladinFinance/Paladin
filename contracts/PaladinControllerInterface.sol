pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

interface PaladinControllerInterface {
    
    //Events

    event NewVToken(address vToken);

    event NewAdmin(address oldAdmin, address newAdmin);


    //Functions

    function getVTokens() external view returns(address[] memory);
    function addNewVToken(address vToken) external returns(bool);

    function setNewAdmin(address payable newAdmin) external returns(bool);

    function withdrawPossible(address vToken, uint amount) external view returns(bool);
    function borrowPossible(address vToken, uint amount) external view returns(bool);

    function depositVerify(address vToken, address dest, uint amount) external view returns(bool);
    function borrowVerify(address vToken, address borrower, uint amount, uint feesAmount, address loanPool) external view returns(bool);

}