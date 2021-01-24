pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./VTokenInterface.sol";
import "./vLoanPools/VLoanPoolInterface.sol";
import "./PaladinControllerInterface.sol";
import "./InterestCalculator.sol";
import "./utils/IERC20.sol";
import "./utils/AggregatorV3Interface.sol";
import "./SwapModule.sol";


//Depending on the pool :
import "./vLoanPools/VAaveLoanPool.sol";

contract VToken is VTokenInterface {
    using SafeMath for uint;

    
    //ERC20 Variables & Mappings
    string public name;
    string public symbol;
    uint public decimals;

    mapping(address => uint) internal balances;
    mapping(address => mapping (address => uint)) internal transferAllowances;

    //VToken varaibles & Mappings
    address public underlying;

    bool internal entered = false;

    address payable internal admin;

    uint public totalReserve;
    uint public totalBorrowed;
    uint public totalSupply;

    uint internal constant maxBorrowRate = 0; //to change
    uint internal constant maxReserveFactor = 0; //to change

    uint internal initialExchangeRate;
    uint public reserveFactor;
    uint public accrualBlockNumber;
    uint public borrowIndex;

    uint constant internal mantissaScale = 1e18;

    mapping (address => address[]) internal borrowsByUser;
    Borrow[] internal borrows;
    uint internal borrowCount;


    //Modules
    PaladinControllerInterface public controller;

    address internal stablecoinAddress;
    SwapModule internal swapModule;
    
    AggregatorV3Interface internal oracle;


    modifier preventReentry() {
        //modifier to prevent reentry in internal functions
        require(entered, "re-entered");
        entered = true;
        _;
        entered = false;
    }

    //Functions
    constructor(
        string memory _name, 
        string memory _symbol, 
        uint _decimals, 
        address _controller, 
        address _underlying, 
        address _stableCoin, 
        address _oracleAddress,
        address _swapModule
    ){
        //Set admin & ERC20 values
        admin = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        //Set inital values & modules
        controller = PaladinControllerInterface(_controller);
        underlying = _underlying;
        stablecoinAddress = _stableCoin;
        borrowCount = 0;
        accrualBlockNumber = block.number;

        oracle = AggregatorV3Interface(_oracleAddress);
        swapModule = SwapModule(_swapModule);
    }

    function transfer(address dest, uint amount) external override returns(bool){
        return _transfer(msg.sender, dest, msg.sender, amount);
    }

    function transferFrom(address dest, address src, uint amount) external override returns(bool){
        return _transfer(msg.sender, dest, src, amount);
    }

    function _transfer(address spender, address dest, address src, uint amount) internal preventReentry returns(bool){
        //Check if the transfer is possible
        require(balances[src] <= amount, "Balance too low");
        require(dest != src, "Can't do self-transfer ");

        //Update allowance (if the spender send the transaction, allowance is -1)
        uint oldAllowance = 0;
        if(src == spender){
            oldAllowance = uint(-1);
        }
        else{
            oldAllowance = transferAllowances[src][spender];
        }

        //Check if allowance is enough
        require(oldAllowance >= amount, "Transfer not allowed");

        //Update balances & allowance
        balances[src] = balances[src].sub(amount);
        balances[dest] = balances[dest].add(amount);
        uint newAllowance = oldAllowance.sub(amount);
        if(oldAllowance != uint(-1)){
            transferAllowances[src][spender] = newAllowance;
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

    function _underlyingBalance() public view returns(uint){
        //Return the balance of this contract for the underlying asset
        IERC20 _underlying = IERC20(underlying);
        return _underlying.balanceOf(address(this));
    }
    



    function deposit(uint amount) external override returns(uint){
        _updateInterest();
        return _mint(msg.sender, amount);
    }

    function _mint(address dest, uint amount) internal preventReentry returns(uint){
        //Need the market to be fresh
        require(accrualBlockNumber == block.number, "Market update failed");

        //Retrieve the current exchange rate vToken:underlying
        uint _exchRate = _exchangeRate();

        //Transfer the underlying to this contract
        //The amount of underlying needs to be updated approved before
        IERC20 _token = IERC20(underlying);
        uint _previousBalance = _token.balanceOf(address(this));
        _token.transferFrom(dest, address(this), amount);
        uint _newBalance = _token.balanceOf(address(this));
        require(_newBalance.sub(_previousBalance) == amount, "Transfer of underlying token failed");

        //Find the amount to mint depending of the previous transfer
        uint _num = amount.mul(mantissaScale);
        uint _toMint = _num.div(_exchRate);

        //Mint the vToken : update balances and Supply
        totalSupply = totalSupply.add(_toMint);
        balances[dest] = balances[dest].add(_toMint);

        //Emit the Deposit event
        emit Deposit(dest, amount, address(this));

        //Use the controller to check if the minting was successfull
        require(controller.depositVerify(address(this), dest, amount),'Deposit failed');

        return _toMint;
    }



    
    function withdraw(uint amount) external override returns(uint){
        _updateInterest();
        return _withdraw(msg.sender, amount);
    }

    function _withdraw(address dest, uint amount) internal preventReentry returns(uint){
        //Need the market to be fresh
        require(accrualBlockNumber == block.number, "Market update failed");

        //Retrieve the current exchange rate vToken:underlying
        uint _exchRate = _exchangeRate();

        IERC20 _token = IERC20(underlying);

        //Find the amount to return depending on the amount of vToken to burn
        uint _num = amount.mul(_exchRate);
        uint _toReturn = _num.div(mantissaScale);

        //Check if the pool has enough underlying to return
        require(_toReturn < _underlyingBalance(), "Not enough funds in the pool");

        //Update the vToken balance & Supply
        totalSupply = totalSupply.sub(_toReturn);
        balances[dest] = balances[dest].sub(_toReturn);

        //Make the underlying transfer
        uint _previousBalance = _token.balanceOf(address(this));
        _token.transfer(dest, _toReturn);
        uint _newBalance = _token.balanceOf(address(this));
        require(_previousBalance.sub(_newBalance) == _toReturn, "Transfer of underlying token failed");

        //Emit the Withdraw event
        emit Withdraw(dest, amount, address(this));

        return _toReturn;
    }
    



    function borrow(uint amount, address feeToken, uint feeAmount) external override returns(uint){
        _updateInterest();
        return _borrow(msg.sender, amount, feeToken, feeAmount);
    }

    function _borrow(address dest, uint amount, address feeToken, uint feeAmount) internal preventReentry returns(uint){
        require(amount < _underlyingBalance(), "Not enough funds in the pool");
        //TODO
    }
    
    function expandBorrow(address loanPool, address feeToken, uint feeAmount) external override returns(uint){
        _updateInterest();
        return _expandBorrow(loanPool, feeToken, feeAmount);
    }
    
    function killBorrow(address loanPool) external override returns(uint){
        _updateInterest();
        return _killBorrow(msg.sender, loanPool);
    }

    function closeBorrow(address loanPool) external override returns(uint){
        _updateInterest();
        return _closeBorrow(loanPool);
    }

    function _expandBorrow(address loanPool, address feeToken, uint feeAmount) internal preventReentry returns(uint){
        //TODO
    }

    function _killBorrow(address killer, address loanPool) internal preventReentry returns(uint){
        //TODO
    }

    function _closeBorrow(address loanPool) internal preventReentry returns(uint){
        //TODO
    }
    



    function getLoansPools() external view override returns(address [] memory){
        //Return the addresses of all LoanPools (old ones and active ones)
        address[] memory pools = new address[](borrowCount);
        for(uint i = 0; i < borrowCount; i++){
            pools[i] = borrows[i].loanPool;
        }
        return pools;
    }
    
    function getLoansByBorrowerStored(address borrower) external view override returns(address [] memory){
        return borrowsByUser[borrower];
    }

    function getLoansByBorrower(address borrower) external override preventReentry returns(address [] memory){
        require(_updateInterest());
        return borrowsByUser[borrower];
    }

    function getBorrowData(address __loanPool) external view override returns(
        address payable _borrower,
        address payable _loanPool,
        uint _amount,
        address _underlying,
        address _feesTokens,
        uint _feesAmount,
        uint _feesUsed,
        bool _closed
    ){
        //Return the data inside a Borrow struct
        for(uint i = 0; i < borrowCount; i++){
            if(borrows[i].loanPool == __loanPool){
                return (
                    borrows[i].borrower,
                    borrows[i].loanPool,
                    borrows[i].amount,
                    borrows[i].underlying,
                    borrows[i].feesTokens,
                    borrows[i].feesAmount,
                    borrows[i].feesUsed,
                    borrows[i].closed
                );
            }
        }
    }
    

    function borrowRatePerBlock() external view override returns (uint){

    }
    
    function supplyRatePerBlock() external view override returns (uint){

    }
    
    function totalBorrowsCurrent() external override preventReentry returns (uint){
        return totalBorrowed;
    }
    
    function _exchangeRate() internal view returns (uint){
        //TODO
    }

    function exchangeRateCurrent() external override preventReentry returns (uint){
        require(_updateInterest());
        return _exchangeRate();
    }
    
    function exchangeRateStored() external view override returns (uint){
        return _exchangeRate();
    }
    

    function getCash() external view override returns (uint){
        return _underlyingBalance();
    }

    function _updateBorrows() internal returns (bool){
        //TODO
    }

    function _updateInterest() internal returns (bool){
        //TODO
    }
    
    function updateInterest() external override returns (bool){
        return _updateInterest();
    }
    




    // Admin Functions
    function setNewAdmin(address payable _newAdmin) external override {
        require(msg.sender == admin, "Admin function");
        admin = _newAdmin;
    }

    

    function setNewController(address _newController) external override {
        require(msg.sender == admin, "Admin function");
        controller = PaladinControllerInterface(_newController);
    }
    

    /*function setNewSwapModule(address _newSwapModule) external override {
        require(msg.sender == _admin, "Admin function");
        swapModule = SwapModule(_newSwapModule);
    } -> TODO */


    function setNewStablecoin(address _newStablecoin) external override {
        require(msg.sender == admin, "Admin function");
        stablecoinAddress = _newStablecoin;
    }


    //Oracle functions
    function _getUnderlyingPrice() internal view returns(uint){
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = oracle.latestRoundData();
        return uint(price);
    }

    function getUnderlyingPrice() external view override returns(uint){
        return _getUnderlyingPrice();
    }

    function setNewOracle(address _oracleAddress) external override {
        require(msg.sender == admin, "Admin function");
        oracle = AggregatorV3Interface(_oracleAddress);
    }
    

}