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

/** @title vToken Pool contract  */
/// @author Paladin - Valentin VIGER
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
        //allows onyl the admin of this contract to call the function
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

        //Set base values
        totalSupply = 0;
        totalBorrowed = 0;
        totalReserve = 0;
    }

    /**
    * @notice Get the underlying balance for this Pool
    * @dev Get the underlying balance of this Pool
    * @return uint : balance of this pool in the underlying token
    */
    function _underlyingBalance() public view returns(uint){
        //Return the balance of this contract for the underlying asset
        return underlying.balanceOf(address(this));
    }
    
    /**
    * @notice Deposit underlying in the Pool
    * @dev Deposit underlying, and mints vToken for the user
    * @param amount Amount of underlying to deposit
    * @return bool : amount of minted vTokens
    */
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

    /**
    * @notice Withdraw underliyng token from the Pool
    * @dev Transfer underlying token to the user, and burn the corresponding vToken amount
    * @param amount Amount of vToken to return
    * @return uint : amount of underlying returned
    */
    function withdraw(uint amount) external override preventReentry returns(uint){
        require(_updateInterest());
        require(balances[msg.sender] <= amount);

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
    
    /**
    * @notice Start a Loan
    * @param amount Amount of underlying to borrow
    * @param feeAmount Amount of fee to pay to start the loan
    * @return uint : amount of paid fees
    */
    function borrow(uint amount, uint feeAmount) external override returns(uint){
        return _borrow(msg.sender, amount, feeAmount);
    }

    /**
    * @dev Create a Borrow, deploy a Loan Pool and delegate voting power
    * @param _dest Address of the Borrower
    * @param _amount Amount of underlying to borrow
    * @param _feeAmount Amount of fee to pay to start the loan
    * @return uint : amount of paid fees
    */
    function _borrow(address _dest, uint _amount, uint _feeAmount) internal preventReentry returns(uint){
        //Need the pool to have enough liquidity, and the interests to be up to date
        require(_amount < _underlyingBalance(), "Pool too low");
        require(_updateInterest());


        //Deploy a new Loan Pool contract
        VAaveLoanPool _newLoan = new VAaveLoanPool(
            address(this),
            _dest,
            address(underlying)
        );

        //Create a new Borrow struct for this new Loan
        Borrow memory _newBorrow = Borrow(
            _dest,
            address(_newLoan),
            _amount,
            address(underlying),
            _feeAmount,
            borrowIndex,
            false
        );


        //Send the borrowed amount of underlying tokens to the Loan
        underlying.transfer(address(_newLoan), _amount);

        //And transfer the fees from the Borrower to the Loan
        underlying.transferFrom(_dest, address(_newLoan), _feeAmount);

        //Start the Loan (and delegate voting power)
        _newLoan.initiate(_amount, _feeAmount);

        //Update Total Borrowed, and add the new Loan to mappings
        totalBorrowed = totalBorrowed.add(_amount);
        borrows.push(address(_newLoan));
        loanToBorrow[address(_newLoan)] = _newBorrow;
        borrowsByUser[_dest].push(address(_newLoan));

        //Check the borrow succeeded
        require(controller.borrowVerify(address(this), _dest, _amount, _feeAmount, address(_newLoan)), "Borrow failed");

        //Emit the NewBorrow Event
        emit NewBorrow(_dest, _amount, address(this));

        //Return the borrowed amount
        return _amount;
    }
    
    /**
    * @notice Expand a Loan by paying fees
    * @param loanPool Address of the Loan
    * @param feeAmount New amount of fees to pay
    * @return bool : Amount of fees paid
    */
    function expandBorrow(address loanPool, uint feeAmount) external override returns(uint){
        return _expandBorrow(loanPool, feeAmount);
    }
    
    /**
    * @notice Kill a non-healthy Loan to collect rewards
    * @param loanPool Address of the Loan
    * @return uint : -
    */
    function killBorrow(address loanPool) external override returns(uint){
        return _killBorrow(msg.sender, loanPool);
    }

    /**
    * @notice Close a Loan, and return the non-used fees to the Borrower
    * @param loanPool Address of the Loan
    * @return uint : -
    */
    function closeBorrow(address loanPool) external override returns(uint){
        return _closeBorrow(loanPool);
    }

    /**
    * @notice Transfer the new fees to the Loan, and expand the Loan
    * @param loanPool Address of the Loan
    * @param feeAmount New amount of fees to pay
    * @return bool : Amount of fees paid
    */
    function _expandBorrow(address loanPool, uint feeAmount) internal preventReentry returns(uint){
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow memory __borrow = loanToBorrow[loanPool];
        require(!__borrow.closed, 'Loan closed');
        require(__borrow.borrower == msg.sender, 'Not owner');
        require(_updateInterest());
        
        //Load the Loan Pool contract
        VLoanPoolInterface _loan = VLoanPoolInterface(__borrow.loanPool);

        //Transfer the new fees to the Loan
        //If success, update the Borrow data, and call the expand fucntion of the Loan
        underlying.transferFrom(__borrow.borrower, __borrow.loanPool, feeAmount);

        bool success = _loan.expand(feeAmount);
        require(success, "Transfer failed");

        __borrow.feesAmount = __borrow.feesAmount.add(feeAmount);

        loanToBorrow[loanPool]= __borrow;

        return feeAmount;
    }

    /**
    * @dev Close a Loan, and return the non-used fees to the Borrower
    * @param loanPool Address of the Loan
    * @return uint : -
    */
    function _closeBorrow(address loanPool) internal preventReentry returns(uint){
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow memory __borrow = loanToBorrow[loanPool];
        require(!__borrow.closed, 'Loan closed');
        require(__borrow.borrower == msg.sender, 'Not owner');
        require(_updateInterest());

        //Load the Loan contract
        VLoanPoolInterface _loan = VLoanPoolInterface(__borrow.loanPool);

        //Calculates the amount of fees used
        uint _feesUsed = __borrow.amount.sub(__borrow.amount.mul(__borrow.borrowIndex).div(borrowIndex));
        
        //Close and destroy the loan
        _loan.closeLoan(_feesUsed);

        //Set the Borrow as closed
        __borrow.closed = true;

        //Update the storage varaibles
        totalBorrowed = totalBorrowed.sub(__borrow.amount);

        loanToBorrow[loanPool]= __borrow;

        //Emit the CloseLoan Event
        emit CloseLoan(__borrow.borrower, __borrow.amount, address(this));

        return 0;
    }

    /**
    * @dev Kill a non-healthy Loan to collect rewards
    * @param killer Address of the Killer
    * @param loanPool Address of the Loan
    * @return uint : -
    */
    function _killBorrow(address killer, address loanPool) internal preventReentry returns(uint){
        //Fetch the corresponding Borrow
        //And check that the killer is not the Borrower, and the Loan is still active
        Borrow memory __borrow = loanToBorrow[loanPool];
        require(!__borrow.closed, 'Loan closed');
        require(__borrow.borrower != killer, 'Loan owner');
        require(_updateInterest());

        //Calculate the amount of fee used, and check if the Loan is killable
        uint _feesUsed = __borrow.amount.sub(__borrow.amount.mul(__borrow.borrowIndex).div(borrowIndex));
        uint _loanHealthFactor = uint(1e18) - _feesUsed.mul(uint(1e18)).div(__borrow.feesAmount);
        require(_loanHealthFactor <= killFactor, "Not killable");

        //Load the Loan
        VLoanPoolInterface _loan = VLoanPoolInterface(__borrow.loanPool);

        //Kill the Loan
        _loan.killLoan(killer, killerRatio);

        //Close the Loan, and update storage variables
        __borrow.closed = true;

        totalBorrowed = totalBorrowed.sub(__borrow.amount);

        loanToBorrow[loanPool]= __borrow;

        return 0;
    }

    /**
    * @notice Return the list of all Loans for this Pool (closed and active)
    * @return address[] : list of Loans
    */
    function getLoansPools() external view override returns(address [] memory){
        //Return the addresses of all LoanPools (old ones and active ones)
        return borrows;
    }
    
    /**
    * @notice Return all the Loans for a given address
    * @param borrower Address of the user
    * @return address[] : list of Loans
    */
    function getLoansByBorrowerStored(address borrower) external view override returns(address [] memory){
        return borrowsByUser[borrower];
    }

    /**
    * @notice Update the Interests & Return all the Loans for a given address
    * @param borrower Address of the user
    * @return address[] : list of Loans
    */
    function getLoansByBorrower(address borrower) external override preventReentry returns(address [] memory){
        require(_updateInterest());
        return borrowsByUser[borrower];
    }

    /**
    * @notice Return the stored Borrow data for a given Loan
    * @param __loanPool address of the new Controller Admin
    * Composants of a Borrow struct
    */
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

    /**
    * @notice Update the Interests & Return the Borrow data for a given Loan
    * @param __loanPool address of the new Controller Admin
    * Composants of a Borrow struct
    */
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

    /**
    * @dev Return the Borrow data for a given Loan
    * @param __loanPool address of the new Controller Admin
    * Composants of a Borrow struct
    */
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
            //Calculate amount of fees used
            __borrow.amount.sub(__borrow.amount.mul(__borrow.borrowIndex).div(borrowIndex)),
            __borrow.closed
        );

    }
    
    /**
    * @notice Get the Borrow Rate for this Pool
    * @dev Get the Borrow Rate from the Interest Module
    * @return uint : Borrow Rate (scale 1e18)
    */
    function borrowRatePerBlock() external view override returns (uint){
        return interestModule.getBorrowRate(_underlyingBalance(), totalBorrowed, totalReserve);
    }
    
    /**
    * @notice Get the Supply Rate for this Pool
    * @dev Get the Supply Rate from the Interest Module
    * @return uint : Supply Rate (scale 1e18)
    */
    function supplyRatePerBlock() external view override returns (uint){
        return interestModule.getSupplyRate(_underlyingBalance(), totalBorrowed, totalReserve, reserveFactor);
    }
    
    /**
    * @notice Return the total amount of funds borrowed
    * @return uint : Total amount of token borrowed (scale 1e18)
    */
    function totalBorrowsCurrent() external override preventReentry returns (uint){
        _updateInterest();
        return totalBorrowed;
    }
    
    /**
    * @dev Calculates the current exchange rate
    * @return uint : current exchange rate (scale 1e18)
    */
    function _exchangeRate() internal view returns (uint){
        //If no vTokens where minted, use the initial exchange rate
        if(totalSupply == 0){
            return initialExchangeRate;
        }
        else{
            // Exchange Rate = (Cash + Borrows - Reserve) / Supply
            uint _cash = _underlyingBalance();
            uint _availableCash = _cash.add(totalBorrowed).sub(totalReserve);
            return _availableCash.mul(1e18).div(totalSupply);
        }
    }

    /**
    * @notice Get the current exchange rate for the vToken
    * @dev Updates interest & Calls internal function _exchangeRate
    * @return uint : current exchange rate (scale 1e18)
    */
    function exchangeRateCurrent() external override returns (uint){
        _updateInterest();
        return _exchangeRate();
    }
    
        /**
    * @notice Get the stored exchange rate for the vToken
    * @dev Calls internal function _exchangeRate
    * @return uint : current exchange rate (scale 1e18)
    */
    function exchangeRateStored() external view override returns (uint){
        return _exchangeRate();
    }

    /**
    * @dev Updates Inetrest and variables for this Pool
    * @return bool : Update success
    */
    function _updateInterest() public returns (bool){
        //Get the current block
        //Check if the Pool has already been updated this block
        uint _currentBlock = block.number;
        if(_currentBlock == accrualBlockNumber){
            return true;
        }

        //Get Pool variables from Storage
        uint _cash = _underlyingBalance();
        uint _borrows = totalBorrowed;
        uint _reserves = totalReserve;
        uint _oldBorrowIndex = borrowIndex;

        //Get the Borrow Rate from the Interest Module
        uint _borrowRate = interestModule.getBorrowRate(_cash, _borrows, _reserves);

        //Delta of blocks since the last update
        uint _ellapsedBlocks = _currentBlock.sub(accrualBlockNumber);

        /*
        Interest Factor = Borrow Rate * Ellapsed Blocks
        Accumulated Interests = Interest Factor * Borrows
        Total Borrows = Borrows + Accumulated Interests
        Total Reserve = Reserve + Accumulated Interests * Reserve Factor
        Borrow Index = old Borrow Index + old Borrow Index * Accumulated Interests 
        */
        uint _interestFactor = _borrowRate.mul(_ellapsedBlocks);
        uint _accumulatedInterest = _interestFactor.mul(_borrows).div(mantissaScale);
        uint _newBorrows = _borrows.add(_accumulatedInterest);
        uint _newReserve = _reserves.add(reserveFactor.mul(_accumulatedInterest).div(mantissaScale));
        uint _newBorrowIndex = _oldBorrowIndex.add(_interestFactor.mul(_oldBorrowIndex).div(mantissaScale));

        //Update storage
        totalBorrowed = _newBorrows;
        totalReserve = _newReserve;
        borrowIndex = _newBorrowIndex;
        accrualBlockNumber = _currentBlock;

        return true;
    }

    


    // Admin Functions

    /**
    * @notice Set a new Admin
    * @dev Changes the address for the admin parameter
    * @param _newAdmin address of the new Controller Admin
    */
    function setNewAdmin(address payable _newAdmin) external override adminOnly {
        admin = _newAdmin;
    }

    /**
    * @notice Set a new Controller
    * @dev Loads the new Controller for the Pool
    * @param  _newController address of the new Controller
    */
    function setNewController(address _newController) external override adminOnly {
        controller = PaladinControllerInterface(_newController);
    }

    /**
    * @notice Set a new Interest Module
    * @dev Load a new Interest Module
    * @param _interestModule address of the new Interest Module
    */
    function setNewInterestModule(address _interestModule) external override adminOnly {
        interestModule = InterestInterface(_interestModule);
    }

    /**
    * @notice Add underlying in the Pool Reserve
    * @dev Transfer underlying token from the admin to the Pool
    * @param _amount Amount of underlying to transfer
    */
    function addReserve(uint _amount) external override adminOnly {
        require(_updateInterest());

        //Transfer from the admin to the Pool
        underlying.transferFrom(admin, address(this), _amount);

        totalReserve = totalReserve.add(_amount);
    }

    /**
    * @notice Remove underlying from the Pool Reserve
    * @dev Transfer underlying token from the Pool to the admin
    * @param _amount Amount of underlying to transfer
    */
    function removeReserve(uint _amount) external override adminOnly {
        //Check if there is enough in the reserve
        require(_updateInterest());
        require(_amount < _underlyingBalance() && _amount < totalReserve);

        //Transfer underlying to the admin
        underlying.transfer(admin, _amount);

        totalReserve = totalReserve.sub(_amount);
    }

}