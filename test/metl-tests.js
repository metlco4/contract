const { expect } = require("chai");
const { ethers } = require("hardhat");


// FUNCTIONS - PERFORMANCE LOGIC
	// EDIT ROLES
	// MINT
	// BURN
	// TRANSFER
	// SEND
	// FREEZE
	// UNFREEZE
	// PAUSE
	// UNPAUSE
	// UPGRADE

// ROLES - HANDLE STORING ADDRESSES INTO STATE TO VALIDATE FUNCTION REQUESTS
	// ARRAY ADMIN
	// ARRAY MINTER
	// ARRAY BURNER
	// ARRAY FREEZER
	// ARRAY FROZEN
	// ARRAY PAUSER
	// ARRAY UPGRADER

// DATA
	// BOOL ISPAUSED
	// INT TOTALSUPPLY

// EDIT ROLES
	// ACCEPT A TARGET ADDRESS
	// ACCEPT A SIGNERL

// MINT ONLYROLE(MINTER)
	// ACCEPT A NUMBER TO BE MINTED 'X'
	// IF 'X' IS <= 0, EXIT
	// IF ISPAUSED === TRUE, EXIT
	// MINT 'X' TOKENS
	// SEND 'X' TOKENS TO MULTISIG WALLET (?)
	// EMIT EVENT FOR ADMIN TO READ

// BURN
	// ACCEPT A NUMBER TO BE BURNED 'X'
	// ACCEPT A SIGNER 
	// IFF SIGNER'S ADDRESS IS NOT LISTED IN 'BURNER' ARRAY, EXIT
	// IF ISPAUSED === TRUE, EXIT
	// IF 'X' IS <= 0, EXIT
	// BURN 'X' TOKENS
	// EMIT EVENT FOR ADMIN TO READ

// TRANSFER
	// ACCEPT A NUMBER TO BE SENT 'X'
	// ACCEPT A SIGNER
	// ACCEPT A TARGET ADDRESS
	// IF ISPAUSED === TRUE, EXIT
	// IF 'X' IS <= 0, EXIT
	// IF 'X' IS > SIGNER'S ACCOUNT BALANCE, EXIT
	// SUBTRACT 'X' FROM SIGNER
	// ADD 'X' TO TARGET ADDRESS
	// EMIT EVENT

// SEND
	// ACCEPT A NUMBER TO BE SENT 'X'
	// ACCEPT A SIGNER
	// ACCEPT A TARGET ADDRESS
	// IF ISPAUSED === TRUE, EXIT
	// IF SIGNER'S ADDRESS IS NOT LISTED IN 'ADMIN' ARRAY, EXIT
	// IF 'X' <= 0, EXIT
	// IF 'X' < MULTISIGWALLET(?).BALANCEOF, EXIT

// FREEZE
	// ACCEPT AN 'ADDRESS'
	// ACCEPT A SIGNER
	// IF SIGNER'S ADDRESS IS NOT LISTED IN 'FREEZER' ARRAY, EXIT
	// ADD TARGET ADDRESS TO 'FROZEN' ROLE
	// EMIT EVENT FOR ADMIN TO READ

// UNFREEZE
	// ACCEPT AN 'ADDRESS'
	// ACCEPT A SIGNER
	// IF SIGNER'S ADDRESS IS NOT LISTED IN 'FREEZER' ARRAY, EXIT
	// REMOVE TARGET ADDRESS TO 'FROZEN' ROLE
	// EMIT EVENT FOR ADMIN TO READ

// PAUSE
	// ACCEPT A SIGNER
	// IF SIGNERS ADDRESS IS NOT LISTEN IN 'PAUSER' ARRAY, EXIT
	// SET ISPAUSED VALUE TO TRUE
	// EMIT EVENT FOR ADMIN TO READ


describe("METL", function () {

  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
	
	
});
