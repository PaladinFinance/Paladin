pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./PaladinControllerInterface.sol";
import "./VTokenInterface.sol";
import "./VToken.sol";
import "./utils/IERC20.sol";

contract PaladinController is PaladinControllerInterface {
    using SafeMath for uint;
    

    //Contract admin
    address payable internal admin;

    //List of all the vToken contracts
    address[] public vTokens;


    constructor(){
        admin = msg.sender;
    }

    function _isVToken(address token) internal view returns(bool){
        //Check if the given address is in the vToken list
        for(uint i = 0; i < vTokens.length; i++){
            if(vTokens[i] == token){
                return true;
            }
        }
        return false;
    }


    function getVTokens() external view override returns(address[] memory){
        return vTokens;
    }

    function addNewVToken(address vToken) external override returns(bool){
        //Add a new address to the vToken list
        require(msg.sender == admin, "Admin function");
        vTokens.push(vToken);
        return true;
    }
    
    
    //Admin function
    function setNewAdmin(address payable newAdmin) external override returns(bool){
        require(msg.sender == admin, "Admin function");
        admin = newAdmin;
        return true;
    }
    
    

    function withdrawPossible(address vToken, uint amount) external view override returns(bool){
        //Get the underlying balance of the vToken contract to check if the action is possible
        VToken _vToken = VToken(vToken);
        IERC20 underlying = _vToken.underlying();
        return(underlying.balanceOf(vToken) >= amount);
    }
    
    function borrowPossible(address vToken, uint amount) external view override returns(bool){
        //Get the underlying balance of the vToken contract to check if the action is possible
        VToken _vToken = VToken(vToken);
        IERC20 underlying = _vToken.underlying();
        return(underlying.balanceOf(vToken) >= amount);
    }
    

    function depositVerify(address vToken, address dest, uint amount) external view override returns(bool){
        //Check if the minting succeeded
        
        //no method yet 

        return true;
    }
    
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
    
}