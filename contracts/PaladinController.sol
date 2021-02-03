pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./PaladinControllerInterface.sol";
import "./VTokenInterface.sol";
import "./VToken.sol";
import "./utils/IERC20.sol";

/** @title Paladin Controller contract  */
/// @author Paladin - Valentin VIGER
contract PaladinController is PaladinControllerInterface {
    using SafeMath for uint;
    

    /** @dev Admin address for this contract */
    address payable internal admin;

    /** @notice List of current active vToken Pools */
    address[] public vTokens;


    constructor(){
        admin = msg.sender;
    }

    //Check if an address is a valid vToken Pool
    function _isVToken(address token) internal view returns(bool){
        //Check if the given address is in the vToken list
        for(uint i = 0; i < vTokens.length; i++){
            if(vTokens[i] == token){
                return true;
            }
        }
        return false;
    }

    //Return the list of vToken Pools
    function getVTokens() external view override returns(address[] memory){
        return vTokens;
    }

    //Add a new vToken Pool to the list
    function addNewVToken(address vToken) external override returns(bool){
        //Add a new address to the vToken list
        require(msg.sender == admin, "Admin function");
        vTokens.push(vToken);
        return true;
    }    
    
    //Check if a Withdraw is possible for a given vToken Pool
    function withdrawPossible(address vToken, uint amount) external view override returns(bool){
        //Get the underlying balance of the vToken contract to check if the action is possible
        VToken _vToken = VToken(vToken);
        IERC20 underlying = _vToken.underlying();
        return(underlying.balanceOf(vToken) >= amount);
    }
    
    //Check if a Borrow is possible for a given vToken Pool
    function borrowPossible(address vToken, uint amount) external view override returns(bool){
        //Get the underlying balance of the vToken contract to check if the action is possible
        VToken _vToken = VToken(vToken);
        IERC20 underlying = _vToken.underlying();
        return(underlying.balanceOf(vToken) >= amount);
    }
    
    //Check if a Deposit was successful (to do)
    function depositVerify(address vToken, address dest, uint amount) external view override returns(bool){
        //Check if the minting succeeded
        
        //no method yet 

        return true;
    }
    
    //Check if a Borrow was successful
    function borrowVerify(address vToken, address borrower, uint amount, uint feesAmount, address loanPool) external view override returns(bool){
        //Check if the borrow was successful
        VTokenInterface _vToken = VTokenInterface(vToken);
        (
            address _borrower,
            address _loanPool,
            uint _amount,
            address _underlying,
            uint _feesAmount,
            uint _feesUsed,
            bool _closed
        ) = _vToken.getBorrowDataStored(loanPool);
        return(borrower == _borrower && amount == _amount && feesAmount == _feesAmount && _closed == false);
    }
        
    
    //Admin function

    /**
    * @notice Set a new Controller Admin
    * @dev Changes the address for the admin parameter
    * @param newAdmin address of the new Controller Admin
    * @return bool : Update success
    */
    function setNewAdmin(address payable newAdmin) external override returns(bool){
        require(msg.sender == admin, "Admin function");
        admin = newAdmin;
        return true;
    }
}