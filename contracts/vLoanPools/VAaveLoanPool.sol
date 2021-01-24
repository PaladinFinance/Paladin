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

    address public feesToken;
    uint public feesAmount;

    //Functions
    constructor(address payable _motherPool, address payable _borrower, address _underlying, address _feesToken){
        //Set up initial values
        motherPool = _motherPool;
        borrower = _borrower;
        underlying = _underlying;
        feesToken = _feesToken;
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
    }

    function expand(uint _newFeesAmount) external override returns(bool){
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        _expand(_newFeesAmount);
        return true;
    }

    function _expand(uint _newFeesAmount) internal {
        //Update the amount of paid fees if the loan is expanded
        feesAmount = feesAmount.add(_newFeesAmount);
    }

    function closeLoan(address _borrower, uint _usedAmount) external override {
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        return _close(_borrower, _usedAmount);
    }

    function _close(address _borrower, uint _usedAmount) internal {
        //Return the borrowed amount to the pool
        IERC20 _underlying = IERC20(underlying);
        _underlying.transfer(motherPool, amount);
        
        //Send the amount of fees used to the pool (to be swaped)
        //Then return the remaining amount to the borrower
        uint _returnAmount = feesAmount.sub(_usedAmount);
        IERC20 _stablecoin = IERC20(feesToken);
        _stablecoin.transfer(_borrower, _returnAmount);
        _stablecoin.transfer(motherPool, _usedAmount);

        //Destruct the contract (to get gas refund on the transaction)
        selfdestruct(motherPool);
    }

    function killLoan(address _killer, uint killerRatio) external override {
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        return _kill(_killer, killerRatio);
    }

    function _kill(address _killer, uint killerRatio) internal {
        //Return the borrowed amount to the pool
        IERC20 _underlying = IERC20(underlying);
        _underlying.transfer(motherPool, amount);
        
        //Send a portion of the fees to the killer, depending on the ratio given
        //And send the rest of the fees to the main pool
        uint _killerAmount = feesAmount.mul(killerRatio).div(100000);
        uint _poolAmount = feesAmount.sub(_killerAmount);
        IERC20 _stablecoin = IERC20(feesToken);
        _stablecoin.transfer(_killer, _killerAmount);
        _stablecoin.transfer(motherPool, _poolAmount);
        
        //Destruct the contract (to get gas refund on the transaction)
        selfdestruct(motherPool);
    }
}