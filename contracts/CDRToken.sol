//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title CDRToken
 * @notice CDRToken (symbol: CDR) is Goldfinch's liquidity token, representing shares
 *  in the Pool. When USDC token is deposited, the the protocol mints a corresponding amount of Token, 
 *  and when you withdraw, then CDR Token is burnt. The share price of the Pool implicitly represents the "exchange rate" between Token
 *  and USDC
 */

contract CDRToken is ERC20Burnable{
    constructor() ERC20("CDRToken", "CDR") {
    }

    function mintTo(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function burnFrom(address _from, uint256 _amount) public override{
        _burn(_from, _amount);
    }
}