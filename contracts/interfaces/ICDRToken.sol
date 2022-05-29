//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICDRToken {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;
}
