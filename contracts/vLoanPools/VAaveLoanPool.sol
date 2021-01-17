pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./VLoanPoolInterface.sol";
import "../utils/IERC20.sol";

contract VAaveLoanPool is VLoanPoolInterface {

    //Varaibles
    address public _underlying;
    uint public _underlyingAmount;

    address payable public _borrower;
    address payable public _motherPool;

    uint public _startBlock;
    uint public _endBlock;

    address public _feesToken;
    uint private _feesAmount;

    //Functions
    constructor(address payable motherPool, address payable borrower, address underlying, address feesToken){
        _motherPool = motherPool;
        _borrower = borrower;
        _underlying = underlying;
        _feesToken = feesToken;
    }

    function initiate(uint amount, uint endBlock, uint feesAmount) external override returns(bool){
        require(msg.sender == _motherPool, "Only the origin Pool can call this function");
        _initiate(amount, endBlock, feesAmount);
    }

    function _initiate(uint amount, uint endBlock, uint feesAmount) internal {
        
    }

    function _delegate(address borrower) internal {

    }

    function expandLoan(uint newEndBlock, uint additionalFeesAmount) external override returns(bool){
        require(msg.sender == _motherPool, "Only the origin Pool can call this function");
        return _expand(newEndBlock, additionalFeesAmount);
    }

    function _expand(uint newEndBlock, uint additionalFeesAmount) internal returns(bool) {
        
        return true;
    }

    function killLoan(address killer) external override returns(bool){
        require(msg.sender == _motherPool, "Only the origin Pool can call this function");
        return _kill(killer);
    }

    function _kill(address killer) internal returns(bool) {
        
        return true;
    }
}