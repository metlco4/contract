const { ethers, upgrades } = require("hardhat");

async function main() {

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const USDR = await ethers.getContractFactory("USDR");
  const usdr = await upgrades.deployProxy(USDR);
  await usdr.deployed();
  const name = await usdr.name();
  console.log("Contract is: ", name);
  console.log("Proxy Address: ", usdr.address);
  console.log("KEEP TRACK OF PROXY ADDRESS. IT IS REQUIRED FOR UPGRADING.");
  console.log("MAKE MULTIPLE COPIES.");

  const dummy = "0x97be92Af211430a80284fd088bE1Fc7183E3212c";

  const MINTER_ROLE = "MINTER_ROLE";
  const LIMITED_MINTER = "LIMITED_MINTER";
  const BURNER_ROLE = "BURNER_ROLE";
  const FREEZER_ROLE = "FREEZER_ROLE";
  const PAUSER_ROLE = "PAUSER_ROLE";
  const WHITELIST_USER = "WHITELIST_USER";
  const FEE_CONTROLLER = "FEE_CONTROLLER";
  const BURN_PROOF = "BURN_PROOF";

  const asyncTimeout = (ms) => {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
    };

  const handleHashString = (string) => {

    const response = ethers.utils.toUtf8Bytes(string);
    return ethers.utils.keccak256(response);
  };

  let tx = await usdr.grantRole(handleHashString(MINTER_ROLE), deployer.address);
  await tx.wait();
  console.log("Grant minter role: ", tx.hash);

  let tx2 = await usdr.grantRole(handleHashString(LIMITED_MINTER), deployer.address);
  await tx2.wait();
  console.log("Grant limited minter role: ", tx2.hash);

  let tx3 = await usdr.grantRole(handleHashString(BURNER_ROLE), deployer.address);
  await tx3.wait();
  console.log("Grant burner role: ", tx3.hash);

  let tx4 = await usdr.grantRole(handleHashString(FREEZER_ROLE), deployer.address);
  await tx4.wait();
  console.log("Grant freezer role: ", tx4.hash);

  let tx5 = await usdr.grantRole(handleHashString(PAUSER_ROLE), deployer.address);
  await tx5.wait();
  console.log("Grant pauser role: ", tx5.hash);

  let tx6 = await usdr.grantRole(handleHashString(WHITELIST_USER), deployer.address);
  await tx6.wait();
  console.log("Grant whitelist role: ", tx6.hash);

  let tx7 = await usdr.grantRole(handleHashString(FEE_CONTROLLER), deployer.address);
  await tx7.wait();
  console.log("Grant fee controller role: ", tx7.hash);

  let tx8 = await usdr.grantRole(handleHashString(BURN_PROOF), deployer.address);
  await tx8.wait();
  console.log("Grant burn ban role: ", tx8.hash);

  tx = await usdr.grantRole(handleHashString(WHITELIST_USER), dummy);
  await tx.wait();
  console.log("Grant whitelisting dummy: ", tx.hash);

  tx = await usdr.commitMint(dummy, ethers.utils.parseEther("1"), handleHashString("Mint 1"));
  await tx.wait();
  console.log("Commitment 1: ", tx.hash);

  console.log("Waiting 9 seconds")
  await asyncTimeout(9000);

  tx = await usdr.limitedMint(dummy, ethers.utils.parseEther("1"), handleHashString("Mint 1"));
  await tx.wait();
  console.log("Limited mint: ", tx.hash);

  tx = await usdr.bankBurn(dummy, ethers.utils.parseEther("1"), handleHashString("Burn 1"));
  await tx.wait();
  console.log("Bank burn: ", tx.hash);

  tx = await usdr.setFeeCollector(deployer.address);
  await tx.wait();
  console.log("Set fee collector: ", tx.hash);

  tx = await usdr.setControls(false, false, 180, 9);
  await tx.wait();
  console.log("Set controls: ", tx.hash);

  tx = await usdr.mint(dummy, ethers.utils.parseEther("2"), handleHashString("Mint 2"));
  await tx.wait();
  console.log("Unlimited fee mint: ", tx.hash);

  tx = await usdr.bankBurn(dummy, ethers.utils.parseEther("1"), handleHashString("Burn 2"));
  await tx.wait();
  console.log("Fee burn: ", tx.hash);

  console.log("Waiting 181 seconds for commit cooldown");
  await asyncTimeout(181000);

  tx = await usdr.commitMint(dummy, ethers.utils.parseEther("1"), handleHashString("Commit 2"));
  await tx.wait();
  console.log("Commitment 2: ", tx.hash);

  tx = await usdr.vetoMint(dummy, ethers.utils.parseEther("1"), handleHashString("Commit 2"));
  await tx.wait();
  console.log("Veto: ", tx.hash);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
