pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./VLoanPoolInterface.sol";
import "../utils/IERC20.sol";
import "../utils/SafeMath.sol";
import "../tokens/AAVE/IGovernancePowerDelegationToken.sol";

/** @title VToken Loan Pool contract (deployed by VToken contract) - AAVE version  */
/// @author Paladin - Valentin VIGER
contract VAaveLoanPool is VLoanPoolInterface {
    using SafeMath for uint;

    //Variables

    /** @notice Address of the udnerlying token for this loan */
    address public underlying;
    /** @notice Amount of the underlying token in this loan */
    uint public amount;
    /** @notice Address of the borrower to delegate the voting power */
    address public borrower;
    /** @notice vToken Pool that created this loan */
    address payable public motherPool;
    /** @notice Amount of fees paid for this loan */
    uint public feesAmount;

    //Functions
    constructor(address _motherPool, address _borrower, address _underlying){
        //Set up initial values
        motherPool = payable(_motherPool);
        borrower = _borrower;
        underlying = _underlying;
    }

    /**
    * @notice Starts the Loan and Delegate the voting Power to the Borrower
    * @dev Calls the internal function _initiate
    * @param _amount Amount of the underlying token for this loan
    * @param _feesAmount Amount of fees (in the underlying token) paid by the borrower
    * @return bool : Power Delagation success
    */
    function initiate(uint _amount, uint _feesAmount) external override returns(bool){
        //We only want the creator contract to call this contract
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        _initiate(_amount, _feesAmount);
        return true;
    }

    /**
    * @dev Sets the amount values for the Loan, then delegate the voting power to the Borrower
    * @param _amount Amount of the underlying token for this loan
    * @param _feesAmount Amount of fees (in the underlying token) paid by the borrower
    */
    function _initiate(uint _amount, uint _feesAmount) internal {
        //Set up the borrowed amount and the amount of fees paid
        amount = _amount;
        feesAmount = _feesAmount;
        
        //Delegate governance power : AAVE version
        IGovernancePowerDelegationToken govToken = IGovernancePowerDelegationToken(underlying);
        govToken.delegate(borrower);
        emit StartLoan(borrower, underlying, amount, block.number);
    }

    /**
    * @notice Increases the amount of fees paid to expand the Loan
    * @dev Calls the internal function _expand
    * @param _newFeesAmount new Amount of fees paid by the Borrower
    * @return bool : Expand success
    */
    function expand(uint _newFeesAmount) external override returns(bool){
        //We only want the creator contract to call this contract
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        _expand(_newFeesAmount);
        return true;
    }

    /**
    * @dev Updates the feesAmount value for this Loan
    * @param _newFeesAmount new Amount of fees paid by the Borrower
    */
    function _expand(uint _newFeesAmount) internal {
        //Update the amount of paid fees if the loan is expanded
        feesAmount = feesAmount.add(_newFeesAmount);
        emit ExpandLoan(borrower, underlying, _newFeesAmount);
    }

    /**
    * @notice Closes a Loan, and returns the non-used fees to the Borrower
    * @dev Calls the internal function _close
    * @param _usedAmount Amount of fees to be used as interest for the Loan
    */
    function closeLoan(uint _usedAmount) external override {
        //We only want the creator contract to call this contract
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        return _close(_usedAmount);
    }

    /**
    * @dev Return the non-used fees to the Borrower, the loaned tokens and the used fees to the vToken Pool, then destroy the contract
    * @param _usedAmount Amount of fees to be used as interest for the Loan
    */
    function _close(uint _usedAmount) internal {
        IERC20 _underlying = IERC20(underlying);
        
        //Return the remaining amount to the borrower
        //Then return the borrowed amount and the used fees to the pool
        uint _returnAmount = feesAmount.sub(_usedAmount);
        uint _keepAmount = amount.add(_usedAmount);
        _underlying.transfer(borrower, _returnAmount);
        _underlying.transfer(motherPool, _keepAmount);

        //Destruct the contract (to get gas refund on the transaction)
        selfdestruct(motherPool);
    }

    /**
    * @notice Kills a Loan, and reward the Killer a part of the fees of the Loan
    * @dev Calls the internal function _kill
    * @param _killer Address of the Loan Killer
    * @param killerRatio Percentage of the fees to reward to the killer (scale 1e18)
    */
    function killLoan(address _killer, uint killerRatio) external override {
        //We only want the creator contract to call this contract
        require(msg.sender == motherPool, "Only the origin Pool can call this function");
        return _kill(_killer, killerRatio);
    }

    /**
    * @dev Send the reward fees to the Killer, then return the loaned tokens and the fees to the vToken Pool, and destroy the contract
    * @param _killer Address of the Loan Killer
    * @param killerRatio Percentage of the fees to reward to the killer (scale 1e18)
    */
    function _kill(address _killer, uint killerRatio) internal {
        IERC20 _underlying = IERC20(underlying);
        
        //Send the killer reward to the killer
        //Then return the borrowed amount and the fees to the pool
        uint _killerAmount = feesAmount.mul(killerRatio).div(uint(1e18));
        uint _balance = amount.add(feesAmount);
        uint _poolAmount = _balance.sub(_killerAmount);
        _underlying.transfer(_killer, _killerAmount);
        _underlying.transfer(motherPool, _poolAmount);

        //Destruct the contract (to get gas refund on the transaction)
        selfdestruct(motherPool);
    }
}