const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Pool", function () {
    it("Should deploy the Pool successfully with sharePrice 0", async function () {
        const [owner] = await ethers.getSigners();
        const CDRToken = await ethers.getContractFactory("CDRToken");
        const cdrToken = await CDRToken.deploy();
        await cdrToken.deployed();

        const TestUSDC = await ethers.getContractFactory("TestUSDC");
        const testUSDC = await TestUSDC.deploy(BigInt('1000000000000000000000000'));
        await testUSDC.deployed();

        const Pool = await ethers.getContractFactory("Pool");
        const pool = await Pool.deploy(cdrToken.address, testUSDC.address);
        await pool.deployed();
        
        const sharePrice = await pool.sharePrice()

        // Per share is 1 USDC
        expect(parseFloat(sharePrice)).to.equal(1000000000000000000);
        
    });

    it("Should deploy 100 USDC and have share of 100 Liquidity (CDR) Tokens", async function () {
        const [owner, depositer] = await ethers.getSigners();
        const CDRToken = await ethers.getContractFactory("CDRToken");
        const cdrToken = await CDRToken.deploy();
        await cdrToken.deployed();

        const TestUSDC = await ethers.getContractFactory("TestUSDC");
        const testUSDC = await TestUSDC.deploy(BigInt('1000000000000000000000000'));
        await testUSDC.deployed();

        const Pool = await ethers.getContractFactory("Pool");
        const pool = await Pool.deploy(cdrToken.address, testUSDC.address);
        await pool.deployed();
        

        // Transfer USDC from owner to depositer
        await testUSDC.approve(depositer.address, 200)
        await testUSDC.transfer(depositer.address, 200)

        expect(parseFloat(await testUSDC.balanceOf(depositer.address))).to.equal(200);

        expect(parseFloat(await testUSDC.balanceOf(pool.address))).to.equal(0);
        // Deposit 100 USDC to Pool
        await testUSDC.connect(depositer).approve(pool.address, 100)
        await pool.connect(depositer).deposit(100)
        // Depositor should have 100 Liquidity Token (CDR)
        expect(parseFloat(await cdrToken.balanceOf(depositer.address))).to.equal(100);

        expect(parseFloat(await testUSDC.balanceOf(pool.address))).to.equal(100);

        // Total size of the shares (Liquidity Tokens) should be 100
        expect(parseFloat(await cdrToken.totalSupply())).to.equal(100);
    });

    it("Should burn CDR token and USDC tokens are withdrawn", async function () {
        const [owner, depositer] = await ethers.getSigners();
        const CDRToken = await ethers.getContractFactory("CDRToken");
        const cdrToken = await CDRToken.deploy();
        await cdrToken.deployed();

        const TestUSDC = await ethers.getContractFactory("TestUSDC");
        const testUSDC = await TestUSDC.deploy(BigInt('1000000000000000000000000'));
        await testUSDC.deployed();

        const Pool = await ethers.getContractFactory("Pool");
        const pool = await Pool.deploy(cdrToken.address, testUSDC.address);
        await pool.deployed();
        

        // Transfer USDC from owner to depositer
        await testUSDC.approve(depositer.address, '200000000000000000000')
        await testUSDC.transfer(depositer.address, '200000000000000000000')

        expect(await testUSDC.balanceOf(depositer.address)).to.equal('200000000000000000000');

        expect(parseFloat(await testUSDC.balanceOf(pool.address))).to.equal(0);
        // Deposit 100 USDC to Pool
        await testUSDC.connect(depositer).approve(pool.address, '100000000000000000000')
        await pool.connect(depositer).deposit('100000000000000000000')
        // Depositor should have 100 Liquidity Token (CDR)
        expect(await cdrToken.balanceOf(depositer.address)).to.equal('100000000000000000000');

        expect(await testUSDC.balanceOf(pool.address)).to.equal('100000000000000000000');
        

        // Total size of the shares (Liquidity Tokens) should be 100        
        expect(await cdrToken.totalSupply()).to.equal('100000000000000000000');
        
        // Withdraw 50 USDC from Pool
        await pool.connect(depositer).withdraw('50000000000000000000')

        expect(parseFloat(await cdrToken.totalSupply())).to.equal(50000000000000000000);
        expect(parseFloat(await testUSDC.balanceOf(pool.address))).to.equal(50000000000000000000);
        expect(parseFloat(await testUSDC.balanceOf(depositer.address))).to.equal(150000000000000000000);
        
    });

    it("Should collect repayment from borrower and sends it to the Pool", async function () {
        const [owner, depositer, borrower] = await ethers.getSigners();
        const CDRToken = await ethers.getContractFactory("CDRToken");
        const cdrToken = await CDRToken.deploy();
        await cdrToken.deployed();

        const TestUSDC = await ethers.getContractFactory("TestUSDC");
        const testUSDC = await TestUSDC.deploy(BigInt('1000000000000000000000000'));
        await testUSDC.deployed();

        const Pool = await ethers.getContractFactory("Pool");
        const pool = await Pool.deploy(cdrToken.address, testUSDC.address);
        await pool.deployed();
        

        // Transfer USDC from owner to depositer
        await testUSDC.approve(depositer.address, '200000000000000000000')
        await testUSDC.transfer(depositer.address, '200000000000000000000')

        // Transfer USDC from owner to borrower
        await testUSDC.approve(borrower.address, '200000000000000000000')
        await testUSDC.transfer(borrower.address, '200000000000000000000')
        expect(await testUSDC.balanceOf(borrower.address)).to.equal('200000000000000000000');

        expect(await testUSDC.balanceOf(depositer.address)).to.equal('200000000000000000000');

        expect(parseFloat(await testUSDC.balanceOf(pool.address))).to.equal(0);
        // Deposit 100 USDC to Pool
        await testUSDC.connect(depositer).approve(pool.address, '100000000000000000000')
        await pool.connect(depositer).deposit('100000000000000000000')
        // Depositor should have 100 Liquidity Token (CDR)
        expect(await cdrToken.balanceOf(depositer.address)).to.equal('100000000000000000000');

        expect(await testUSDC.balanceOf(pool.address)).to.equal('100000000000000000000');
        

        // Total size of the shares (Liquidity Tokens) should be 100        
        expect(await cdrToken.totalSupply()).to.equal('100000000000000000000');
        
        // Collect repayment from the borrower
        const principalAmount = '100000000000000000000'
        const interestAmount = '10000000000000000000'
        await testUSDC.connect(borrower).approve(pool.address, '200000000000000000000')
        await pool.collectRepayment(borrower.address, principalAmount, interestAmount)
        const sharePrice = await pool.sharePrice()
        expect(parseFloat(sharePrice)).to.equal(1100000000000000000);
        expect(await testUSDC.balanceOf(pool.address)).to.equal('210000000000000000000');
    });
});