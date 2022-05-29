//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDC is ERC20{
    constructor(uint256 _totalSupply) ERC20("Test USDC", "TestUSDC") {
        _mint(msg.sender, _totalSupply);
    }
}