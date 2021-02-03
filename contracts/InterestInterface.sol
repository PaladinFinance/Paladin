pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Interest Module Interface  */
/// @author Paladin - Valentin VIGER
interface InterestInterface {

    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactor) external view returns(uint);
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns(uint);
}