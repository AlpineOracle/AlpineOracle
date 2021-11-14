pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";


contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

event Deposit(address sender, uint256 amount);
event Withdraw(address sender, uint256 amount);

mapping ( address => uint256 ) public balance;
bool public isActive = false;
bool public notExecuted = true;
uint256 public constant threshold = 1 ether;
uint256 public deadline = now + 20 minutes;
receive() external payable { deposit(); }


//modifiers
modifier notCompleted() {
        
        _;
        notExecuted = false;
}

modifier withdrawRequirements() {
    require (notExecuted == true, "It's too late! Already Executed!!");
    require(now > deadline, "There is still time! Try again after timer reaches 0");
    require(isActive == false, "Contract is active. Try Executing!");
    require(balance[msg.sender] > 0, "Nice try! You have nothing deposited!");
  _;
}


modifier depositRequirements() {
  require (notExecuted == true, "Contract has already executed! That was close!");
  _;
}


function deposit() public payable depositRequirements {
  emit Deposit(msg.sender, msg.value);
  balance[msg.sender] += msg.value;

  if (now <= deadline && address(this).balance >= threshold) {
    isActive = true;
  }
 }


 // if the `threshold` was not met, allow everyone to call a `withdraw()` function
function withdraw() public withdrawRequirements {      
    uint256 amount = balance[msg.sender];
    balance[msg.sender] = 0;
    msg.sender.transfer(amount);
    emit Withdraw(msg.sender, amount);
}


// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
//  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
function stake() public payable depositRequirements {
  balance[msg.sender] += msg.value;
  
  if (now <= deadline && address(this).balance >= threshold) 
    isActive = true;
  emit Deposit(msg.sender, msg.value);
}


// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
function timeLeft() public view returns (uint256) {
  if (now >= deadline) return 0;
return deadline - now;
}


// Add the `receive()` special function that receives eth and calls stake()
function recieve() public payable depositRequirements {
  balance[msg.sender] += msg.value;

  if (now <= deadline && address(this).balance >= threshold) 
  isActive = true;
  emit Deposit(msg.sender, msg.value);
}


// After some `deadline` allow anyone to call an `execute()` function---
//  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
function execute() public notCompleted {
  require (isActive == true, "Threshold not met! Stake more ETH or withdraw after deadline");
  require (deadline <= now, "Deadline not met! Execute or withdraw after deadline");
  require (notExecuted == true, "Already Executed!");
  exampleExternalContract.complete{value: address(this).balance}();
 
            
}


}
