const { ethers, upgrades } = require("hardhat");
// eslint-disable-next-line prettier/prettier
async function main() {
  const METL = await ethers.getContractFactory("USDR");
  const metl = await upgrades.deployProxy(METL);
  await metl.deployed();
  const name = await metl.name();
  console.log("Contract is: ", name);
  console.log("Proxy Address: ", metl.address);
  console.log("KEEP TRACK OF PROXY ADDRESS. IT IS REQUIRED FOR UPGRADING.");
  console.log("MAKE MULTIPLE COPIES.");
}

main();
