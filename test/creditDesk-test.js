const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CreditDesk", function () {
    it("Should deploy the Credit Desk successfully", async function () {
        const [owner, borrower] = await ethers.getSigners();
        const CDRToken = await ethers.getContractFactory("CDRToken");
        const cdrToken = await CDRToken.deploy();
        await cdrToken.deployed();

        const TestUSDC = await ethers.getContractFactory("TestUSDC");
        const testUSDC = await TestUSDC.deploy(BigInt('1000000000000000000000000'));
        await testUSDC.deployed();        
        
        const Pool = await ethers.getContractFactory("Pool");
        const pool = await Pool.deploy(cdrToken.address, testUSDC.address);
        await pool.deployed();

        const CreditDesk = await ethers.getContractFactory("CreditDesk");
        const creditDesk = await CreditDesk.deploy(testUSDC.address);
        await creditDesk.deployed();
        
        expect(creditDesk.address.toString().length).to.equal(42);
    })
})