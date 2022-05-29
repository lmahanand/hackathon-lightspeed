//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IPool {
  uint256 public sharePrice = uint256(10)**uint256(18); // 1 CDR = 1 USDC

  function deposit(uint256 amount) external virtual;

  function withdraw(uint256 amount) external virtual;

  function collectRepayment(address from, uint256 principalAmount, uint256 interestAmount) external virtual;

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual returns (bool);

}
