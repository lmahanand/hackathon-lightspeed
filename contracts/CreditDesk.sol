//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/ICreditDesk.sol";
import "./interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CreditDesk is ICreditDesk, AccessControl {
    address usdc;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    using SafeMath for uint256;

    uint256 public constant MaxUnderwriterLimit = 10000000000000000000000; // 10000 USDC
    constructor(address _usdc){
        // Grant the owner role to the deployer
        _setupRole(OWNER_ROLE, msg.sender);
        usdc = _usdc;
        bool success = IERC20(usdc).approve(address(this), type(uint256).max);
        require(success, "Failed to approve USDC");
    }

    struct CreditLine {   
        uint256 id;     
        // Credit line terms
        address pool;
        address borrower;
        address underwriter;
        uint256 limit;
        uint256 interestApr;
        uint256 paymentPeriodInDays;
        uint256 termInDays;

        // Accounting variables
        uint256 balance;
        uint256 interestOwed;
        uint256 principalOwed;
        uint256 termEndBlock;
        uint256 nextDueBlock;
        uint256 interestAccruedAsOfBlock;
        uint256 lastFullPaymentBlock;
    }

    struct Underwriter {
        uint256 governanceLimit;
        CreditLine[] creditLines;
    }

    struct Borrower {
        CreditLine[] creditLines;
    }

    event PaymentApplied(
        address indexed payer,
        address indexed creditLine,
        uint256 interestAmount,
        uint256 principalAmount,
        uint256 remainingAmount
    );
    event PaymentCollected(address indexed payer, uint256 indexed creditLineId, uint256 paymentAmount);
    event DrawdownMade(address indexed borrower, uint256 indexed creditLineId, uint256 drawdownAmount);
    event CreditLineCreated(address indexed borrower, address indexed creditLine);
    event GovernanceUpdatedUnderwriterLimit(address indexed underwriter, uint256 newLimit);

    mapping(address => Underwriter) public underwriters;
    mapping(address => Borrower) private borrowers;
    

    function setUnderwriterGovernanceLimit(address underwriterAddress, uint256 limit)
        external
        override
        onlyAdmin
    {
        require(withinMaxUnderwriterLimit(limit), "This limit is greater than the max allowed by the protocol");
        underwriters[underwriterAddress].governanceLimit = limit;
        emit GovernanceUpdatedUnderwriterLimit(underwriterAddress, limit);
    }

    // Allows an underwriter to create a new CreditLine for a single borrower
    // The caller must be an underwriter with enough limit
    function createCreditLine(
        address _pool,
        address _borrower,
        uint256 _limit,
        uint256 _interestApr,
        uint256 _paymentPeriodInDays,
        uint256 _termInDays
    ) public override{
        require(_borrower != address(0), "Zero address passed in");
        Underwriter storage underwriter = underwriters[msg.sender];
        require(underwriter.governanceLimit != 0, "underwriter does not have governance limit");
        Borrower storage borrower = borrowers[_borrower];
        
        CreditLine memory creditLine = CreditLine(            
            borrower.creditLines.length + 1, 
            _pool,
            _borrower, 
            msg.sender, 
            _limit,
            _interestApr,
            _paymentPeriodInDays,
            _termInDays,
            _limit, 0, 0, 0, 0, 0, 0
        );
        borrower.creditLines.push(creditLine);
    }

    function drawdown(
        uint256 amount,
        uint256 creditLineId,
        address addressToSendTo
    ) external override {
        Borrower storage borrower = borrowers[msg.sender];
        require(borrower.creditLines.length > 0, "No credit lines exist for this borrower");
        require(amount > 0, "Must drawdown more than zero");
        
        if (addressToSendTo == address(0)) {
            addressToSendTo = msg.sender;
        }
        CreditLine memory creditline;
        uint256 clIndex = 0;
        for (uint i=0; i<borrower.creditLines.length; i++) {
            if (borrower.creditLines[i].id == creditLineId) {
                creditline = borrower.creditLines[i];
                clIndex = i;
                break;
            }
        }
        require(amount <= creditline.balance, "Must drawdown more than zero");
        emit DrawdownMade(msg.sender, creditline.id, amount);

        uint256 balance = creditline.balance.sub(amount);        
        borrower.creditLines[clIndex].balance = balance;
        bool success = IPool(creditline.pool).transferFrom(creditline.pool, addressToSendTo, amount);
        require(success, "Failed to drawdown");
    }

    // Allows a borrower to repay their loan
    function pay(uint256 creditLineId, uint256 amount)
        external
        override
    {
        require(amount > 0, "Must pay more than zero");
        Borrower storage borrower = borrowers[msg.sender];
        require(borrower.creditLines.length > 0, "No credit lines exist for this borrower");        
        
        CreditLine memory creditline;
        uint256 clIndex = 0;
        for (uint i=0; i<borrower.creditLines.length; i++) {
            if (borrower.creditLines[i].id == creditLineId) {
                creditline = borrower.creditLines[i];
                clIndex = i;
                break;
            }
        }
        require(IERC20(usdc).balanceOf(msg.sender) >= amount, "You have insufficent balance for this payment");

        emit PaymentCollected(msg.sender, creditLineId, amount);

        bool success = IPool(creditline.pool).transferFrom(msg.sender, creditline.pool, amount);  
        require(success, "Failed to collect payment");
    }

    function withinMaxUnderwriterLimit(uint256 amount) internal pure returns (bool) {
        return amount <= MaxUnderwriterLimit;
    }

    function isAdmin() public view returns (bool) {
        return hasRole(OWNER_ROLE, _msgSender());
    }

    function getUSDCBalance(address _address) internal view returns (uint256) {
        return IERC20(usdc).balanceOf(_address);
    }

    modifier onlyAdmin() {
        require(isAdmin(), "Must have admin role to perform this action");
        _;
    }
}