const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CDRToken", function () {
  it("Should deploy the CDR Token and mint 1000 CDR Tokens", async function () {
    const [owner] = await ethers.getSigners();
    const CDRToken = await ethers.getContractFactory("CDRToken");
    const cdrToken = await CDRToken.deploy();
    await cdrToken.deployed();
    const mintToTx = await cdrToken.mintTo(owner.address, 1000)
    await mintToTx.wait();
    expect(parseFloat(await cdrToken.balanceOf(owner.address))).to.equal(1000);

  });

  it("Should mint 1000 CDR Tokens and tranfer 500 CDR Tokens to receiver", async function () {
    const [owner, receiver] = await ethers.getSigners();
    const CDRToken = await ethers.getContractFactory("CDRToken");
    const cdrToken = await CDRToken.deploy();
    await cdrToken.deployed();
    const mintToTx = await cdrToken.mintTo(owner.address, 1000)
    await mintToTx.wait();
    
    await cdrToken.transfer(receiver.address, 500)
    expect(parseFloat(await cdrToken.balanceOf(receiver.address))).to.equal(500);
  });

  it("Should mint 1000 CDR Tokens and tranfer 500 CDR Tokens to receiver and burn 250 tokens", async function () {
    const [owner, receiver] = await ethers.getSigners();
    const CDRToken = await ethers.getContractFactory("CDRToken");
    const cdrToken = await CDRToken.deploy();
    await cdrToken.deployed();
    const mintToTx = await cdrToken.mintTo(owner.address, 1000)
    await mintToTx.wait();
    
    await cdrToken.transfer(receiver.address, 500)
    expect(parseFloat(await cdrToken.balanceOf(receiver.address))).to.equal(500);

    await cdrToken.burnFrom(receiver.address, 250)
    expect(parseFloat(await cdrToken.balanceOf(receiver.address))).to.equal(250);
  });
});
