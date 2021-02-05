# Paladin


Paladin smart contracts


Lending protocol for governance power (inspired by Compound lending system). Instead of sending the tokens to the borrower, the tokens are moved to a smart contract that will delegate its governance power to the borrower


## `vToken`

A vToken Pools hold the governance token, allows user to deposit or withdraw them, and to create Borrows.

A Borrow represent a loan. Loans are not collateralized, but the borrower needs to pay fees when starting the loan, instead of paying interests when reimbursing the loan. A certain amount of fees represents the duration of the loan (in blocks), depending on the Borrow Rate.



### `deposit(uint amount)`
Send the underlying token to the Pool, and gets a vToken in returned, representing the amount deposited + all accrued interests


### `withdraw(uint amount)`
Send an amount of vToken to the Pool to retrieve a corresponding amount of underlying token


### `borrow(uint amount, uint feesAmount)`
Creates a new Borrow, and deploy a new Loan Pool contract to hold the loan.

amount parameter is the amount of underlying token to borrow

feesAmount parameter is the amount of fees paid for the loan.


### `expandBorrow(addres loanPool, uint feesAmount)`
Reserved for the Loan owner.

Allow to pay an extra amount of fees to expand the Loan duration


### `closeBorrow(address loanPool)`
Reserved for the Loan owner.

Allow to close a Borrow, and retrieve all unused fees from the Loan.


### `killBorrow(address loanPool)`
Forbidden to Loan owner.

Allow to kill a Loan that used all of its fees (= loan duration is over).

Killer (caller of this function) gets a reward for killing the Loan.





Other functions coming soon.





## `vLoanPool`

A smart contract deployed by a vToken Pool to bear the Loan, and delegate the governance power to the borrower.

Also holds the fees paid by the borrower.






## `PaladinController`


Controller contract, that list all vToken Pools, and 







## `InterestModule`


Smart contract to calculate Utilization Rate, Borrow Rate and Supply Rate of a vToken Pool. Based on a JumpRate Interest Model







## Kovan addresses 

Controller : 0x06A5D095a25853610aD2468360Bbe441c5D3Bb52

Interest Module : 0xFF6032D410EAeD14a38afCF4D8cCD0A4DEf47114


vAAVE VPool : 0xEbcc6a16302b72842724e9E6bc26FE243def99b7
