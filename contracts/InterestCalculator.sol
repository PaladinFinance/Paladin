pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./InterestInterface.sol";

import "./utils/SafeMath.sol";


contract InterestCalculator is InterestInterface {
    using SafeMath for uint;

    address public admin;

    uint public multiplierPerBlock = 0.00000295e18;
    uint public baseRatePerBlock = 0.0000243e18;
    uint public kinkMultiplierPerBlock = 0.00006337e18;
    uint public kinkBaseRatePerBlock = 0.000046875e18;
    uint public kink = 0.8e18;

    constructor(){
        admin = msg.sender;
    }

    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns(uint){
        if(borrows == 0){
            return 0;
        }
        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactor) external view override returns(uint){
        uint _utilRate = utilizationRate(cash, borrows, reserves);
        uint _bRate = _borrowRate(cash, borrows, reserves);
        uint _tempRate = _bRate.mul(uint(1e18).sub(reserveFactor)).div(1e18);
        return _utilRate.mul(_tempRate).div(1e18);
    }
    
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view override returns(uint){
        return _borrowRate(cash, borrows, reserves);
    }

    function _borrowRate(uint cash, uint borrows, uint reserves) internal view returns(uint){
        uint _utilRate = utilizationRate(cash, borrows, reserves);
        if(_utilRate <= kink) {
            return _utilRate.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
        } 
        else {
            return _utilRate.mul(kinkMultiplierPerBlock).div(1e18).add(kinkBaseRatePerBlock);
        }
    }
}