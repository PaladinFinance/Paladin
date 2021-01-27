pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./InterestInterface.sol";

contract InterestCalculator is InterestInterface {

    address public admin;

    uint public multiplierPerBlock;
    uint public baseRatePerBlock;
    uint public jumpMultiplierPerBlock;
    uint public kink;

    constructor(uint _baseRate, uint _multiplier, uint _jumpMultiplier, uint _kink){
        admin = msg.sender;
        multiplierPerBlock = _multiplier;
        baseRatePerBlock = _baseRate;
        jumpMultiplierPerBlock = _jumpMultiplier;
        kink = _kink;
    }

    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns(uint){
        
    }

    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactor) external view override returns(uint){

    }
    
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view override returns(uint){

    }
}