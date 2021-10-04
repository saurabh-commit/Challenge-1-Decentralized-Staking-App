pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = now + 30 seconds;
  bool openForWithdraw = false;

  event Stake(address, uint256);
  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier thresholdReached() {
    require(address(this).balance >= threshold, "Threshold not reached!");
    _;
  }

  modifier thresholdNotReached() {
    require(address(this).balance < threshold, "Threshold reached!");
    _;
  }

  modifier exceededDeadline() {
    require(now >= deadline, "DeadLine not reached, can't execute stake or withdraw!");
    _;
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Staking already completed!");
    _;
  }
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() 
    public 
    payable 
    notCompleted{
      balances[msg.sender] += msg.value;
      emit Stake(msg.sender, msg.value);
  } 
  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute()
    public 
    exceededDeadline 
    thresholdReached 
    notCompleted {
      exampleExternalContract.complete{value: address(this).balance}();
  }
  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw(address payable user) 
    external 
    exceededDeadline 
    thresholdNotReached 
    notCompleted {
      require(balances[user] != 0, "User's balance is 0, can't withdraw.");
      uint256 withdrawAmount = balances[user];
      balances[user] = 0;
      user.transfer(withdrawAmount);
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() 
    public 
    view 
    returns (uint256) {
      return now >= deadline ? 0 : (deadline - now);
  }

}
