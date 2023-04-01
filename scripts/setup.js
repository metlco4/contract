const hre = require("hardhat");

async function main() {

  const METL = await hre.ethers.getContractAt("USDR", "0x87AC4d8506bE938D4388c6DEc7BDc90643bC2dd8");

  [owner, minter, burner, pauser, freezer, frozen, pool, user] =
      await ethers.getSigners();

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
