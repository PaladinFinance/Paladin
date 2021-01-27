pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./VLoanPoolInterface.sol";
import "../utils/IERC20.sol";
import "../utils/SafeMath.sol";
import "../tokens/AAVE/IGovernancePowerDelegationToken.sol";

contract VAaveLoanPool is VLoanPoolInterface {
    using SafeMath for uint;

    //Variables
    address public underlying;
    uint public amount;

    address payable public borrower;
    address payable public motherPool;

    uint public feesAmount;

    //Functions
    constructor(address payable _motherPool, address payable _borrower, address _underlying){
        //Set up initial values
        motherPool = _motherPool;
        borrower = _borrower;
        underlying = _underlying;
    }

    function initiate(uint _amount, uint _feesAmount) external override returns(bool){
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        _initiate(_amount, _feesAmount);
        return true;
    }

    function _initiate(uint _amount, uint _feesAmount) internal {
        //Set up the borrowed amount and the amount of fees paid
        amount = _amount;
        feesAmount = _feesAmount;
        
        //Delegate governance power : AAVE version
        IGovernancePowerDelegationToken govToken = IGovernancePowerDelegationToken(underlying);
        govToken.delegate(borrower);
        emit StartLoan(borrower, underlying, amount, block.number);
    }

    function expand(uint _newFeesAmount) external override returns(bool){
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        _expand(_newFeesAmount);
        return true;
    }

    function _expand(uint _newFeesAmount) internal {
        //Update the amount of paid fees if the loan is expanded
        feesAmount = feesAmount.add(_newFeesAmount);
        emit ExpandLoan(borrower, underlying, _newFeesAmount);
    }

    function closeLoan(address _borrower, uint _usedAmount) external override {
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        return _close(_borrower, _usedAmount);
    }

    function _close(address _borrower, uint _usedAmount) internal {
        IERC20 _underlying = IERC20(underlying);
        
        //Return the remaining amount to the borrower
        //Then return the borrowed amount and the used fees to the pool
        uint _returnAmount = feesAmount.sub(_usedAmount);
        uint _keepAmount = amount.add(_usedAmount);
        _underlying.transfer(_borrower, _returnAmount);
        _underlying.transfer(motherPool, _keepAmount);

        //Destruct the contract (to get gas refund on the transaction)
        selfdestruct(motherPool);
    }

    function killLoan(address _killer, uint killerRatio) external override {
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        return _kill(_killer, killerRatio);
    }

    function _kill(address _killer, uint killerRatio) internal {
        IERC20 _underlying = IERC20(underlying);
        
        //Send the killer reward to the killer
        //Then return the borrowed amount and the fees to the pool
        uint _killerAmount = feesAmount.mul(killerRatio).div(100000);
        uint _balance = amount.add(feesAmount);
        uint _poolAmount = _balance.sub(_killerAmount);
        _underlying.transfer(_killer, _killerAmount);
        _underlying.transfer(motherPool, _poolAmount);

        //Destruct the contract (to get gas refund on the transaction)
        selfdestruct(motherPool);
    }
}