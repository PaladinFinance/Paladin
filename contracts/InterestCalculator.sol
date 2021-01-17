pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

contract InterestCalculator {

    //Values for tests, the contract will be modofied when adding economic functions : 
    // get exchangeRate for tokens, update the rate, etc ...
    uint public conversionRate = 1; //1:1
    uint public borrowPriceRateNumerator = 1; //1%
    uint public borrowPriceRateDenominator = 100;
}