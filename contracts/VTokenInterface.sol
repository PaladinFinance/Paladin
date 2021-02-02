pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./PaladinControllerInterface.sol";
import "./ERC20Interface.sol";

interface VTokenInterface is ERC20Interface {

    //Events
    /** @notice Event when an user deposit tokens in the pool */
    event Deposit(address user, uint amount, address vToken);
    /** @notice Event when an user withdraw tokens from the pool */
    event Withdraw(address user, uint amount, address vToken);
    /** @notice Event when a loan is started */
    event NewBorrow(address user, uint amount, address vToken);
    /** @notice Event when a loan is ended */
    event CloseLoan(address user, uint amount, address vToken);
    /** @notice (Admin) Event when the contract admin is updated */
    event newAdmin(address oldAdmin, address newAdmin);
    /** @notice (Admin) Event when the contract controller is updated */
    event newController(PaladinControllerInterface oldController, PaladinControllerInterface newController);


    //Functions
    function deposit(uint amount) external returns(uint);
    function withdraw(uint amount) external returns(uint);
    function borrow(uint amount, uint feeAmount) external returns(uint);
    function expandBorrow(address loanPool, uint feeAmount) external returns(uint);
    function closeBorrow(address loanPool) external returns(uint);
    function killBorrow(address loanPool) external returns(uint);

    function getLoansPools() external view returns(address [] memory);
    function getLoansByBorrowerStored(address borrower) external view returns(address [] memory);
    function getLoansByBorrower(address borrower) external returns(address [] memory);
    function getBorrowDataStored(address __loanPool) external view returns(
        address _borrower,
        address _loanPool,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        bool _closed
    );
    function getBorrowData(address _loanPool) external returns(
        address borrower,
        address loanPool,
        uint amount,
        address underlying,
        uint feesAmount,
        uint feesUsed,
        bool closed
    );

    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);

    // Admin Functions
    function setNewAdmin(address payable _newAdmin) external;

    function setNewController(address _newController) external;
    function setNewInterestModule(address _interestModule) external;

    function addReserve(uint _amount) external;
    function removeReserve(uint _amount) external;

}