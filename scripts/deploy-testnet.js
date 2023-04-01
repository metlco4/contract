const { ethers, upgrades } = require("hardhat");

async function main() {

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  // const USDR = await ethers.getContractFactory("USDR");
  // const usdr = await upgrades.deployProxy(USDR);
  // await usdr.deployed();
  // const name = await usdr.name();
  // console.log("Contract is: ", name);
  // console.log("Proxy Address: ", usdr.address);
  console.log("KEEP TRACK OF PROXY ADDRESS. IT IS REQUIRED FOR UPGRADING.");
  console.log("MAKE MULTIPLE COPIES.");
  
  

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
