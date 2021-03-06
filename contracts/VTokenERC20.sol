pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./ERC20Interface.sol";

/** @title vToken ERC20 contract  */
/// @author Paladin - Valentin VIGER
contract VTokenERC20 is ERC20Interface {
    using SafeMath for uint;

    //ERC20 Variables & Mappings :

    /** @notice ERC20 token Name */
    string public name;
    /** @notice ERC20 token Symbol */
    string public symbol;
    /** @notice ERC20 token Decimals */
    uint public decimals;

    /** @dev Balances for this ERC20 token */
    mapping(address => uint) internal balances;
    /** @dev Allowances for this ERC20 token, sorted by user */
    mapping(address => mapping (address => uint)) internal transferAllowances;


    //Functions : 

    function transfer(address dest, uint amount) external override returns(bool){
        return _transfer(msg.sender, dest, msg.sender, amount);
    }

    function transferFrom(address dest, address src, uint amount) external override returns(bool){
        return _transfer(msg.sender, dest, src, amount);
    }

    function _transfer(address spender, address dest, address src, uint amount) internal returns(bool){
        //Check if the transfer is possible
        require(balances[src] <= amount, "Balance");
        require(dest != src, "Self-transfer");

        //Check allowance if needed
        uint oldAllowance = uint(-1);
        if(src != spender){
            oldAllowance = transferAllowances[src][spender];
        }
        require(oldAllowance >= amount, "Allowance");

        //Update balances & allowance
        balances[src] = balances[src].sub(amount);
        balances[dest] = balances[dest].add(amount);
        if(oldAllowance != uint(-1)){
            transferAllowances[src][spender] = oldAllowance.sub(amount);
        }

        //emit the Transfer Event
        emit Transfer(src,dest,amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns(bool){
        address src = msg.sender;
        //Update allowance and emit the Approval event
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns(uint){
        return transferAllowances[owner][spender];
    }

    function balanceOf(address owner) external view override returns(uint){
        return balances[owner];
    }

}