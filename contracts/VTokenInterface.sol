pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./PaladinControllerInterface.sol";
import "./ERC20Interface.sol";

interface VTokenInterface is ERC20Interface {

    //Events
    /* @notice Event when an user deposit tokens in the pool */
    event Deposit(address user, uint amount, address vToken);
    /* @notice Event when an user withdraw tokens from the pool */
    event Withdraw(address user, uint amount, address vToken);
    /* @notice Event when a loan is started */
    event Borrow(address user, uint amount, address vToken);
    /* @notice Event when a loan is ended */
    event CloseLoan(address user, uint amount, address vToken);
    /* @notice Event interest index is updated */
    event UpdateInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows, address vToken);
    /* @notice (Admin) Event when the contract admin is updated */
    event newAdmin(address oldAdmin, address newAdmin);
    /* @notice (Admin) Event when the contract controller is updated */
    event newController(PaladinControllerInterface oldController, PaladinControllerInterface newController);


    //Functions
    function deposit(address dest, uint amount) external returns(uint);
    function withdraw(address dest, uint amount) external returns(uint);
    function borrow(address dest, uint amount, address feeToken, uint feeAmount) external returns(uint);
    function expandBorrow(address dest, address loanPool, address feeToken, uint feeAmount) external returns(uint);
    function killBorrow(address killer, address loanPool) external returns(uint);


    function getLoansPools() external view returns(address [] memory);
    function getLoansByBorrowerStored(address borrower) external view returns(address [] memory);
    function getLoansByBorrower(address borrower) external returns(address [] memory);

    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);

    function getCash() external view returns (uint);
    function updateInterest() external returns (uint);

    // Admin Functions
    function setNewAdmin(address payable newAdmin) external;

    function setNewController(PaladinControllerInterface newController) external;

    //function setNewSwapModule(SwapModule newSwapModule) external; -> TODO
    function setNewStablecoin(address newStablecoin) external;
}