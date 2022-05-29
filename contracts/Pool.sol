//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICDRToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20withDec.sol";
contract Pool is IPool{
    address cdrToken;
    address usdc;
    using SafeMath for uint256;
    event DepositMade(address indexed capitalProvider, uint256 amount, uint256 shares);
    event WithdrawalMade(address indexed capitalProvider, uint256 userAmount);
    event InterestCollected(address indexed payer, uint256 poolAmount);
    event TransferMade(address indexed from, address indexed to, uint256 amount);

    constructor(address _cdrToken, address _usdc){
        cdrToken = _cdrToken;
        usdc = _usdc;
        bool success = IERC20(usdc).approve(address(this), type(uint256).max);
        require(success, "Failed to approve USDC");
    }

    function deposit(uint256 amount) external override {
        require(amount > 0, "Must deposit more than zero");
        // Check if the amount of new shares to be added is within limits
        uint256 depositShares = getNumShares(amount);
        totalShares().add(depositShares);        
        bool success = doUSDCTransfer(msg.sender, address(this), amount);
        require(success, "Failed to transfer for deposit");

        ICDRToken(cdrToken).mintTo(msg.sender, amount);
    }

    // Withdraws `amount` USDC from the Pool to msg.sender, and burns the equivalent value of CDR tokens
    function withdraw(uint256 amount) external override {
        require(amount > 0, "Withdraw amount should be greater than zero");
        // Determine current shares the address has and the shares requested to withdraw
        uint256 currentShares = IERC20(cdrToken).balanceOf(msg.sender);
        uint256 withdrawShares = getNumShares(amount);
        require(withdrawShares <= currentShares, "Amount requested is greater than what this address owns");
        emit WithdrawalMade(msg.sender, amount);
        bool success = doUSDCTransfer(address(this), msg.sender, amount);
        require(success, "Failed to transfer for withdraw");

        // Burn the shares
        ICDRToken(cdrToken).burnFrom(msg.sender, amount);
    }

    // Collects `principalAmount` and `interestAmount` ins USDC as repayment from `from` and sends it to the Pool.
    function collectRepayment(address from, uint256 principalAmount, uint256 interestAmount) external override{
        uint256 poolAmount = principalAmount.add(interestAmount);
        emit InterestCollected(from, poolAmount);
        uint256 increment = usdcToSharePrice(interestAmount);
        sharePrice = sharePrice.add(increment);
        bool success = doUSDCTransfer(from, address(this), poolAmount);
        require(success, "Failed to transfer repayment");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        bool result = doUSDCTransfer(from, to, amount);
        emit TransferMade(from, to, amount);
        return result;
    }


    /** Internal Methods **/

    function totalShares() internal view returns (uint256) {
        return IERC20(cdrToken).totalSupply();
    }

    function usdcToSharePrice(uint256 usdcAmount) internal view returns (uint256) {
        return usdcToToken(usdcAmount).mul(tokenMantissa()).div(totalShares());
    }

    function tokenMantissa() internal view returns (uint256) {
        return uint256(10)**uint256(IERC20withDec(cdrToken).decimals());
    }

    function usdcMantissa() internal view returns (uint256) {
        return uint256(10)**uint256(IERC20withDec(usdc).decimals());
    }

    function usdcToToken(uint256 amount) internal view returns (uint256) {
        return amount.mul(tokenMantissa()).div(usdcMantissa());
    }

    function getNumShares(uint256 amount) internal view returns (uint256) {
        return usdcToToken(amount).mul(tokenMantissa()).div(sharePrice);
    }

    function doUSDCTransfer(
    address from,
    address to,
    uint256 amount
    ) internal returns (bool) {
        require(to != address(0), "Can't send to zero address");
        uint256 balanceBefore = IERC20(usdc).balanceOf(to);

        bool success = IERC20(usdc).transferFrom(from, to, amount);

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(usdc).balanceOf(to);
        require(balanceAfter >= balanceBefore, "Token Transfer Overflow Error");
        return success;
  }
}