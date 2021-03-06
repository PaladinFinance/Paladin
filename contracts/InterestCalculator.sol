pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./InterestInterface.sol";

import "./utils/SafeMath.sol";

/** @title Interest Module for Paladin vToken pools  */
/// @author Paladin - Valentin VIGER
contract InterestCalculator is InterestInterface {
    using SafeMath for uint;

    /** @notice admin address (contract creator) */
    address public admin;

    /** @notice base mulitplier for borrow rate */
    uint public multiplierPerBlock = 0.0000002998e18;
    /** @notice base borrow rate */
    uint public baseRatePerBlock = 0.0000002416e18;
    /** @notice mulitplier for borrow rate for the kink */
    uint public kinkMultiplierPerBlock = 0.0000064021e18;
    /** @notice borrow rate for the kink */
    uint public kinkBaseRatePerBlock = 0.00000048325e18;
    /** @notice  ratio of utilization rate at wihich we use kink_ values*/
    uint public kink = 0.8e18;

    constructor(){
        admin = msg.sender;
    }

    /**
    * @notice Calculates the Utilization Rate of a vToken Pool
    * @dev Calculates the Utilization Rate of a vToken Pool depending of Cash, Borrows & Reserves
    * @param cash Cash amount of the calling vToken Pool
    * @param borrows Total Borrowed amount of the calling vToken Pool
    * @param reserves Total Reserves amount of the calling vToken Pool
    * @return uint : Utilisation Rate of the Pool (scale 1e18)
    */
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns(uint){
        //If no funds are borrowed, the Pool is not used
        if(borrows == 0){
            return 0;
        }
        // Utilization Rate = Borrows / (Cash + Borrows - Reserves)
        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    /**
    * @notice Calculates the Supply Rate for the calling vToken Pool
    * @dev Calculates the Supply Rate depending on the Pool Borrow Rate & Reserve Factor
    * @param cash Cash amount of the calling vToken Pool
    * @param borrows Total Borrowed amount of the calling vToken Pool
    * @param reserves Total Reserves amount of the calling vToken Pool
    * @param reserveFactor Reserve Factor of the calling vToken Pool
    * @return uint : Supply Rate for the Pool (scale 1e18)
    */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactor) external view override returns(uint){
        //Fetch the Pool Utilisation Rate & Borrow Rate
        uint _utilRate = utilizationRate(cash, borrows, reserves);
        uint _bRate = _borrowRate(cash, borrows, reserves);

        //Supply Rate = Utilization Rate * (Borrow Rate - Reserve Factor)
        uint _tempRate = _bRate.mul(uint(1e18).sub(reserveFactor)).div(1e18);
        return _utilRate.mul(_tempRate).div(1e18);
    }
    
    /**
    * @notice Get the Borrow Rate for a vToken Pool depending on the given parameters
    * @dev Calls the internal fucntion _borrowRate
    * @param cash Cash amount of the calling vToken Pool
    * @param borrows Total Borrowed amount of the calling vToken Pool
    * @param reserves Total Reserves amount of the calling vToken Pool
    * @return uint : Borrow Rate for the Pool (scale 1e18)
    */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view override returns(uint){
        //Internal call
        return _borrowRate(cash, borrows, reserves);
    }

    /**
    * @dev Calculates the Borrow Rate for the vToken pool, depending on the utilisation rate & the kink value.
    * @param cash Cash amount of the calling vToken Pool
    * @param borrows Total Borrowed amount of the calling vToken Pool
    * @param reserves Total Reserves amount of the calling vToken Pool
    * @return uint : Borrow Rate for the Pool (scale 1e18)
    */
    function _borrowRate(uint cash, uint borrows, uint reserves) internal view returns(uint){
        //Fetch the utilisation rate
        uint _utilRate = utilizationRate(cash, borrows, reserves);
        //If the Utilization Rate is less than the Kink value
        // Borrow Rate = Multiplier * Utilization Rate + Base Rate
        if(_utilRate < kink) {
            return _utilRate.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
        }
        //If the Utilization Rate is more than the Kink value
        // Borrow Rate = Kink Multiplier * (Utilization Rate - 0.8) + Kink Rate
        else {
            uint _temp = _utilRate.sub(0.8e18);
            return kinkMultiplierPerBlock.mul(_temp).div(1e18).add(kinkBaseRatePerBlock);
        }
    }
}