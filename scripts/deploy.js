async function main() {
    // Deploy USDC
    const TestUSDC = await ethers.getContractFactory("TestUSDC");
    const testUSDC = await TestUSDC.deploy("1000000000000000000000000"); // 10000 Test USDC
  
    await testUSDC.deployed();
  
    console.log("TestUSDC deployed to:", testUSDC.address);

    // Deploy CDR Token
    const CDRToken = await ethers.getContractFactory("CDRToken");
    const cdrToken = await CDRToken.deploy();
    await cdrToken.deployed();
    console.log("CDRToken deployed to:", cdrToken.address);

    const Pool = await ethers.getContractFactory("Pool");
    const pool = await Pool.deploy(cdrToken.address, testUSDC.address);
    await pool.deployed();

    console.log("Pool deployed to:", pool.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });