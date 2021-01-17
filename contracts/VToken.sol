pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./VTokenInterface.sol";
import "./VLoanPoolInterface.sol";
import "./PaladinControllerInterface.sol";
import "./InterestCalculator.sol";
import "../utils/IERC20.sol";

contract VToken is VTokenInterface {
    using SafeMath for uint;

    //ERC20 Variables & Mappings
    string public _name;
    string public _symbol;
    string public _decimals;

    mapping(address => uint) internal _balances;
    mapping(address => mapping (address => uint)) internal _transferAllowances;

    //VToken varaibles & Mappings
    address public _underlying;

    bool internal _entered = false;

    address payable private _admin;

    address [] internal _loanPools;

    uint public _totalReserve;
    uint public _totalBorrowed;
    mapping (address => address) internal _borrows;

    PaladinControllerInterface public _controller;

    address internal _stablecoinAddress;
    //SwapModule internal _swapModule; -> TODO


    /*
        TO ADD : Price Oracle system for loan time determination
    */

    modifier preventReentry() {
        require(_entered, "re-entered");
        _entered = true;
        _;
        _entered = false;
    }

    //Functions
    constructor(string name, string symbol, uint decimals, PaladinControllerInterface controller, address payable admin, address underlying, address stableCoin){

    }

    function transfer(address dest, uint amount) external override returns(bool){

    }

    function transferFrom(address dest, address src, uint amount) external override returns(bool){

    }

    function _transfer(address dest, address src, uint amount) internal preventReentry returns(bool){
        
    }

    function approve(address spender, uint amount) external override returns(bool){
        address src = msg.sender;
        _transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns(uint){
        return _transferAllowances[owner][spender];
    }

    function balanceOf(address owner) external view override returns(uint){
        return _balances[owner];
    }

    //Return the balance of this contract for the underlying asset
    function _underlyingBalance() internal view override returns(uint){
        
    }
    



    function deposit(address dest, uint amount) external override returns(uint){
        
    }

    function _mint(address dest, uint amount) internal preventReentry returns(uint){
        
    }

    function _deposit(address dest, uint amount) internal preventReentry returns(uint){
        
    }
    
    function withdraw(address dest, uint amount) external override returns(uint){
        
    }

    function _withdraw(address dest, uint amount) internal preventReentry returns(uint){
        
    }
    
    function borrow(address dest, uint amount, address feeToken, uint feeAmount) external override returns(uint){
        
    }

    function _borrow(address dest, uint amount, address feeToken, uint feeAmount) internal preventReentry returns(uint){
        
    }
    
    function expandBorrow(address dest, address loanPool, address feeToken, uint feeAmount) external override returns(uint){
        
    }

    function _deposit(address dest, address loanPool, address feeToken, uint feeAmount)) internal preventReentry returns(uint){
        
    }
    
    function killBorrow(address killer, address loanPool) external override returns(uint){
        
    }

    function _deposit(address killer, address loanPool) internal preventReentry returns(uint){
        
    }
    


    function getLoansPools() external view override returns(address [] memory){
        return _loanPools;
    }
    
    function getLoansByBorrower(address borrower) external view override returns(address [] memory){
        
    }
    


    // Admin Functions
    function setNewAdmin(address payable newAdmin) external override {
        require(msg.sender == _admin, "Admin function");
        _admin = newAdmin;
    }

    

    function setNewController(PaladinControllerInterface newController) external override {
        require(msg.sender == _admin, "Admin function");
        
    }
    

    /*function setNewSwapModule(SwapModule newSwapModule) external override {
        require(msg.sender == _admin, "Admin function");
        
    } -> TODO */


    function setNewStablecoin(address stablecoin) external override {
        require(msg.sender == _admin, "Admin function");
        
    }
    

}