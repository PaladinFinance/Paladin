pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./VTokenInterface.sol";
import "./vLoanPools/VLoanPoolInterface.sol";
import "./PaladinControllerInterface.sol";
import "./InterestCalculator.sol";
import "./utils/IERC20.sol";

contract VToken is VTokenInterface {
    using SafeMath for uint;

    //Struct

    struct Borrow {
        address payable borrower;
        address payable loanPool;
        uint amount;
        address underlying;
        address feesTokens;
        uint feesAmount;
        uint feesUsed;
    }


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

    uint public _totalReserve;
    uint public _totalBorrowed;
    uint public _totalSupply;

    uint internal constant maxBorrowRate = 0; //to change
    uint internal constant maxReserveFactor = 0; //to change

    uint internal initialExchangeRate;
    uint public reserveFactor;
    uint public accrualBlockNumber;
    uint public borrowIndex;

    mapping (address => address) internal _usersByBorrows;
    Borrow[] internal _borrows;

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
    constructor(string memory name, string memory symbol, uint decimals, PaladinControllerInterface controller, address payable admin, address underlying, address stableCoin){

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
    function _underlyingBalance() internal view returns(uint){
        
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

    function _deposit(address dest, address loanPool, address feeToken, uint feeAmount) internal preventReentry returns(uint){
        
    }
    
    function killBorrow(address killer, address loanPool) external override returns(uint){
        
    }

    function _deposit(address killer, address loanPool) internal preventReentry returns(uint){
        
    }
    


    function getLoansPools() external view override returns(address [] memory){
        
    }
    
    function getLoansByBorrowerStored(address borrower) external view override returns(address [] memory){

    }

    function getLoansByBorrower(address borrower) external override preventReentry returns(address [] memory){

    }
    

    function borrowRatePerBlock() external view override returns (uint){

    }
    
    function supplyRatePerBlock() external view override returns (uint){

    }
    
    function totalBorrowsCurrent() external override preventReentry returns (uint){

    }
    
    function _exchangeRate() internal returns (uint){

    }

    function exchangeRateCurrent() external override preventReentry returns (uint){

    }
    
    function exchangeRateStored() external view override returns (uint){

    }
    
    function _getCash() internal returns (uint){

    }

    function getCash() external view override returns (uint){

    }

    function _updateInterest() internal returns (uint){
        
    }
    
    function updateInterest() external override returns (uint){

    }
    




    // Admin Functions
    function setNewAdmin(address payable newAdmin) external override {
        require(msg.sender == _admin, "Admin function");
        _admin = newAdmin;
    }

    

    function setNewController(PaladinControllerInterface newController) external override {
        require(msg.sender == _admin, "Admin function");
        _controller = newController;
    }
    

    /*function setNewSwapModule(SwapModule newSwapModule) external override {
        require(msg.sender == _admin, "Admin function");
        
    } -> TODO */


    function setNewStablecoin(address newStablecoin) external override {
        require(msg.sender == _admin, "Admin function");
        _stablecoinAddress = newStablecoin;
    }
    

}