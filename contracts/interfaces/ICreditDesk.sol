//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract ICreditDesk {
  uint256 public totalLoansOutstanding;

  function setUnderwriterGovernanceLimit(address underwriterAddress, uint256 limit) external virtual;

  function createCreditLine(
    address _pool,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays
  ) public virtual;

  function drawdown(
    uint256 amount,
    uint256 creditLineId,
    address addressToSendTo
  ) external virtual;

  function pay(uint256 creditLineId, uint256 amount) external virtual;

  // function assessCreditLine(address creditLineAddress) external virtual;
}
