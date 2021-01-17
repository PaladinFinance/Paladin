pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./PaladinControllerInterface.sol";

contract PaladinController is PaladinControllerInterface {
    using SafeMath for uint;

    address payable private _admin;

    address[] public _vTokens;


    function _isVToken() internal returns(bool){
        
    }


    function getVTokens() external view override returns(address[] memory){

    }

    function addNewVToken(address vToken) external override returns(bool){
        require(msg.sender == _admin, "Admin function");
        
    }
    
    function removeVToken(address vToken) external override returns(bool){
        require(msg.sender == _admin, "Admin function");
        
    }
    

    function getLoansForBorrower(address borrower) external override returns(address[] memory){

    }
    

    function setNewAdmin(address payable newAdmin) external override returns(bool){
        require(msg.sender == _admin, "Admin function");
        
    }
    

    function deposit(address vToken, address dest, uint amount) external override returns(uint){

    }
    
    function withdraw(address vToken, address dest, uint amount) external override returns(uint){

    }
    
    function borrow(address vToken, address dest, uint amount, address feeToken, uint feeAmount) external override returns(uint){

    }
    
    function expandBorrow(address vToken, address dest, address loanPool, address feeToken, uint feeAmount) external override returns(uint){

    }
    
    function killBorrow(address vToken, address killer, address loanPool) external override returns(uint){

    }
    

    function withdrawPossible(address vToken, uint amount) external override returns(bool){

    }
    
    function borrowPossible(address vToken, uint amount, address feeToken, uint feeAmount) external override returns(bool){

    }
    

    function depositVerify(address vToken, address dest, uint amount) external override returns(bool){

    }
    
    function withdrawVerify(address vToken, address dest, uint amount) external override returns(bool){

    }
    
    function borrowVerify(address vToken, address dest, uint amount, address loanPool) external override returns(bool){

    }
    
}