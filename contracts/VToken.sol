pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./VTokenInterface.sol";
import "./VTokenStorage.sol";
import "./VTokenERC20.sol";
import "./vLoanPools/VLoanPoolInterface.sol";
import "./PaladinControllerInterface.sol";
import "./InterestInterface.sol";
import "./utils/IERC20.sol";

//Depending on the pool :
import "./vLoanPools/VAaveLoanPool.sol";


contract VToken is VTokenERC20, VTokenInterface, VTokenStorage {
    using SafeMath for uint;

    modifier preventReentry() {
        //modifier to prevent reentry in internal functions
        require(!entered);
        entered = true;
        _;
        entered = false;
    }

    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }

    //Functions
    constructor(
        string memory _name, 
        string memory _symbol, 
        uint _decimals, 
        address _controller, 
        address _underlying,
        address _interestModule
    ){
        //Set admin & ERC20 values
        admin = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        //Set inital values & modules
        controller = PaladinControllerInterface(_controller);
        underlying = IERC20(_underlying);
        accrualBlockNumber = block.number;
        interestModule = InterestInterface(_interestModule);
        borrowIndex = 1e18;

        totalSupply = 0;
        totalBorrowed = 0;
        totalReserve = 0;
    }

    function _underlyingBalance() public view returns(uint){
        //Return the balance of this contract for the underlying asset
        return underlying.balanceOf(address(this));
    }
    

    function deposit(uint amount) external override preventReentry returns(uint){
        require(_updateInterest());

        //Retrieve the current exchange rate vToken:underlying
        uint _exchRate = _exchangeRate();

        //Transfer the underlying to this contract
        //The amount of underlying needs to be approved before
        underlying.transferFrom(msg.sender, address(this), amount);

        //Find the amount to mint depending of the previous transfer
        uint _num = amount.mul(mantissaScale);
        uint _toMint = _num.div(_exchRate);

        //Mint the vToken : update balances and Supply
        totalSupply = totalSupply.add(_toMint);
        balances[msg.sender] = balances[msg.sender].add(_toMint);

        //Emit the Deposit event
        emit Deposit(msg.sender, amount, address(this));

        //Use the controller to check if the minting was successfull
        require(controller.depositVerify(address(this), msg.sender, _toMint),'Deposit failed');

        return _toMint;
    }

    function withdraw(uint amount) external override preventReentry returns(uint){
        require(_updateInterest());

        //Retrieve the current exchange rate vToken:underlying
        uint _exchRate = _exchangeRate();

        //Find the amount to return depending on the amount of vToken to burn
        uint _num = amount.mul(_exchRate);
        uint _toReturn = _num.div(mantissaScale);

        //Check if the pool has enough underlying to return
        require(_toReturn < _underlyingBalance(), "Balance too low");

        //Update the vToken balance & Supply
        totalSupply = totalSupply.sub(_toReturn);
        balances[msg.sender] = balances[msg.sender].sub(_toReturn);

        //Make the underlying transfer
        underlying.transfer(msg.sender, _toReturn);

        //Emit the Withdraw event
        emit Withdraw(msg.sender, amount, address(this));

        return _toReturn;
    }
    



    function borrow(uint amount, uint feeAmount) external override returns(uint){
        return _borrow(msg.sender, amount, feeAmount);
    }

    function _borrow(address _dest, uint _amount, uint _feeAmount) internal preventReentry returns(uint){
        require(_amount < _underlyingBalance(), "Pool too low");
        require(_updateInterest());

        Borrow memory _newBorrow = Borrow(
            _dest,
            address(this),
            _amount,
            address(underlying),
            _feeAmount,
            borrowIndex,
            false
        );

        VAaveLoanPool _newLoan = new VAaveLoanPool(
            address(this),
            _dest,
            address(underlying)
        );

        underlying.transfer(address(_newLoan), _amount);

        underlying.transferFrom(_dest, address(_newLoan), _feeAmount);

        _newLoan.initiate(_amount, _feeAmount);

        totalBorrowed = totalBorrowed.add(_amount);
        borrows.push(address(_newLoan));
        loanToBorrow[address(_newLoan)] = _newBorrow;
        borrowsByUser[_dest].push(address(_newLoan));

        require(controller.borrowVerify(address(this), _dest, _amount, _feeAmount, address(_newLoan)), "Borrow failed");

        emit NewBorrow(_dest, _amount, address(this));

        return _amount;
    }
    
    function expandBorrow(address loanPool, uint feeAmount) external override returns(uint){
        return _expandBorrow(loanPool, feeAmount);
    }
    
    function killBorrow(address loanPool) external override returns(uint){
        return _killBorrow(msg.sender, loanPool);
    }

    function closeBorrow(address loanPool) external override returns(uint){
        return _closeBorrow(loanPool);
    }

    function _expandBorrow(address loanPool, uint feeAmount) internal preventReentry returns(uint){
        Borrow memory __borrow = loanToBorrow[loanPool];
        require(!__borrow.closed, 'Loan closed');
        require(__borrow.borrower == msg.sender, 'Not owner');
        require(_updateInterest());
        
        VLoanPoolInterface _loan = VLoanPoolInterface(__borrow.loanPool);

        underlying.transferFrom(__borrow.borrower, __borrow.loanPool, feeAmount);

        bool success = _loan.expand(feeAmount);
        require(success, "Transfer failed");

        __borrow.feesAmount = __borrow.feesAmount.add(feeAmount);

        loanToBorrow[loanPool]= __borrow;

        return feeAmount;
    }

    function _closeBorrow(address loanPool) internal preventReentry returns(uint){
        Borrow memory __borrow = loanToBorrow[loanPool];
        require(!__borrow.closed, 'Loan closed');
        require(__borrow.borrower == msg.sender, 'Not owner');
        require(_updateInterest());

        VLoanPoolInterface _loan = VLoanPoolInterface(__borrow.loanPool);

        uint _feesUsed = __borrow.amount.sub(__borrow.amount.mul(__borrow.borrowIndex).div(borrowIndex));
        
        _loan.closeLoan(_feesUsed);

        __borrow.closed = true;

        totalBorrowed = totalBorrowed.sub(__borrow.amount);

        loanToBorrow[loanPool]= __borrow;

        emit CloseLoan(__borrow.borrower, __borrow.amount, address(this));

        return 0;
    }

    function _killBorrow(address killer, address loanPool) internal preventReentry returns(uint){
        Borrow memory __borrow = loanToBorrow[loanPool];
        require(!__borrow.closed, 'Loan closed');
        require(__borrow.borrower != killer, 'Loan owner');
        require(_updateInterest());

        uint _feesUsed = __borrow.amount.sub(__borrow.amount.mul(__borrow.borrowIndex).div(borrowIndex));
        uint _loanHealthFactor = uint(1e18) - _feesUsed.mul(uint(1e18)).div(__borrow.feesAmount);
        require(_loanHealthFactor <= killFactor, "Not killable");

        VLoanPoolInterface _loan = VLoanPoolInterface(__borrow.loanPool);

        _loan.killLoan(killer, killerRatio);

        __borrow.closed = true;

        totalBorrowed = totalBorrowed.sub(__borrow.amount);

        loanToBorrow[loanPool]= __borrow;

        return 0;
    }


    function getLoansPools() external view override returns(address [] memory){
        //Return the addresses of all LoanPools (old ones and active ones)
        return borrows;
    }
    
    function getLoansByBorrowerStored(address borrower) external view override returns(address [] memory){
        return borrowsByUser[borrower];
    }

    function getLoansByBorrower(address borrower) external override preventReentry returns(address [] memory){
        require(_updateInterest());
        return borrowsByUser[borrower];
    }

    function getBorrowDataStored(address __loanPool) external view override returns(
        address _borrower,
        address _loanPool,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        bool _closed
    ){
        return _getBorrowData(__loanPool);
    }

    function getBorrowData(address __loanPool) external override returns(
        address _borrower,
        address _loanPool,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        bool _closed
    ){
        require(_updateInterest());
        return _getBorrowData(__loanPool);
    }

    function _getBorrowData(address __loanPool) internal view returns(
        address _borrower,
        address _loanPool,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        bool _closed
    ){
        //Return the data inside a Borrow struct
        Borrow memory __borrow = loanToBorrow[__loanPool];
        return (
            __borrow.borrower,
            __borrow.loanPool,
            __borrow.amount,
            __borrow.underlying,
            __borrow.feesAmount,
            __borrow.amount.sub(__borrow.amount.mul(__borrow.borrowIndex).div(borrowIndex)),
            __borrow.closed
        );

    }
    

    function borrowRatePerBlock() external view override returns (uint){
        return interestModule.getBorrowRate(_underlyingBalance(), totalBorrowed, totalReserve);
    }
    
    function supplyRatePerBlock() external view override returns (uint){
        return interestModule.getSupplyRate(_underlyingBalance(), totalBorrowed, totalReserve, reserveFactor);
    }
    
    function totalBorrowsCurrent() external override preventReentry returns (uint){
        _updateInterest();
        return totalBorrowed;
    }
    
    function _exchangeRate() internal view returns (uint){
        if(totalSupply == 0){
            return initialExchangeRate;
        }
        else{
            uint _cash = _underlyingBalance();
            uint _availableCash = _cash.add(totalBorrowed).sub(totalReserve);
            return _availableCash.mul(1e18).div(totalSupply);
        }
    }

    function exchangeRateCurrent() external override returns (uint){
        _updateInterest();
        return _exchangeRate();
    }
    
    function exchangeRateStored() external view override returns (uint){
        return _exchangeRate();
    }

    function _updateInterest() public returns (bool){
        uint _currentBlock = block.number;
        if(_currentBlock == accrualBlockNumber){
            return true;
        }

        uint _cash = _underlyingBalance();
        uint _borrows = totalBorrowed;
        uint _reserves = totalReserve;
        uint _oldBorrowIndex = borrowIndex;

        uint _borrowRate = interestModule.getBorrowRate(_cash, _borrows, _reserves);

        uint _ellapsedBlocks = _currentBlock.sub(accrualBlockNumber);

        uint _interestFactor = _borrowRate.mul(_ellapsedBlocks);
        uint _accumulatedInterest = _interestFactor.mul(_borrows).div(mantissaScale);
        uint _newBorrows = _borrows.add(_accumulatedInterest);
        uint _newReserve = _reserves.add(reserveFactor.mul(_accumulatedInterest).div(mantissaScale));
        uint _newBorrowIndex = _oldBorrowIndex.add(_interestFactor.mul(_oldBorrowIndex).div(mantissaScale));

        totalBorrowed = _newBorrows;
        totalReserve = _newReserve;
        borrowIndex = _newBorrowIndex;
        accrualBlockNumber = _currentBlock;

        return true;
    }

    


    // Admin Functions
    function setNewAdmin(address payable _newAdmin) external override adminOnly {
        admin = _newAdmin;
    }

    function setNewController(address _newController) external override adminOnly {
        controller = PaladinControllerInterface(_newController);
    }

    function setNewInterestModule(address _interestModule) external override adminOnly {
        interestModule = InterestInterface(_interestModule);
    }

    function addReserve(uint _amount) external override adminOnly {
        require(_updateInterest());

        underlying.transferFrom(admin, address(this), _amount);

        totalReserve = totalReserve.add(_amount);
    }

    function removeReserve(uint _amount) external override adminOnly {
        require(_updateInterest());
        require(_amount < _underlyingBalance() && _amount < totalReserve);

        underlying.transfer(admin, _amount);

        totalReserve = totalReserve.sub(_amount);
    }

}