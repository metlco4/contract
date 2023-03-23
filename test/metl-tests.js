const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { BigNumber } = require("ethers");

describe("USDR", function () {
  let Token;
  let METL;
  let owner;
  let minter;
  let burner;
  let pauser;
  let freezer;
  let frozen;
  let pool;
  let user;

  const transactionString = "TransactionId";
  
  const MINTER_ROLE = "MINTER_ROLE";
  const BURNER_ROLE = "BURNER_ROLE";
  const FREEZER_ROLE = "FREEZER_ROLE";
  const FROZEN_USER = "FROZEN_USER";
  const PAUSER_ROLE = "PAUSER_ROLE";
  const WHITELIST_USER = "WHITELIST_USER";
  const FEE_CONTROLLER = "FEE_CONTROLLER";
  const FREE_MINTER = "FREE_MINTER";
  const FREE_BURNER = "FREE_BURNER";

  const handleHashString = (string) => {
    const response = ethers.utils.toUtf8Bytes(string);
    return ethers.utils.keccak256(response);
  };

  beforeEach(async function () {
    Token = await ethers.getContractFactory("METLV3");
    [owner, minter, burner, pauser, freezer, frozen, pool, user] =
      await ethers.getSigners();
    METL = await upgrades.deployProxy(Token);
    await METL.deployed();
  });

  it("Should have a name", async () => {
    // eslint-disable-next-line no-unused-expressions
    expect(await METL.name()).to.exist;
  });

  it("Should be named USD Receipt", async () => {
    expect(await METL.name()).to.equal("USD Receipt");
  });

	it("Should have a symbol", async () => {
		// eslint-disable-next-line no-unused-expressions
    expect(await METL.symbol()).to.exist;
  });

  it("Should have the symbol 'USDR'", async () => {
    expect(await METL.symbol()).to.equal("USDR");
  });

	it("Should have an admin role", async () => {
		 // eslint-disable-next-line no-unused-expressions
    expect(await METL.DEFAULT_ADMIN_ROLE()).to.exist;
  });

  it("Should set the admin role to the owner address", async () => {
    const DFA = await METL.DEFAULT_ADMIN_ROLE();
    expect(await METL.getRoleMember(DFA, 0)).to.equal(owner.address);
  });

  // it("Should not have more than one default admin", async () => {
  //   const DFA = await METL.DEFAULT_ADMIN_ROLE();
  //   // expect(await METL.getRoleMember(DFA, 1)).to.be.reverted;
  // });

	it("Should have a 'MINTER' role", async () => {
		 // eslint-disable-next-line no-unused-expressions
    expect(await METL.MINTER_ROLE()).to.exist;
  });
    it("Should have a 'FREE_MINTER' role", async () => {
		 // eslint-disable-next-line no-unused-expressions
    expect(await METL.FREE_MINTER()).to.exist;
  });
	it("Should have a 'BURNER' role", async () => {
		 // eslint-disable-next-line no-unused-expressions
    expect(await METL.BURNER_ROLE()).to.exist;
  });
    it("Should have a 'FREE_BURNER' role", async () => {
		 // eslint-disable-next-line no-unused-expressions
    expect(await METL.FREE_BURNER()).to.exist;
  });
	it("Should have a 'FREEZER' role", async () => {
		 // eslint-disable-next-line no-unused-expressions
    expect(await METL.FREEZER_ROLE()).to.exist;
  });
	it("Should have a 'FROZEN' role", async () => {
		 // eslint-disable-next-line no-unused-expressions
    expect(await METL.FROZEN_USER()).to.exist;
  });
	it("Should have a 'PAUSER' role", async () => {
		 // eslint-disable-next-line no-unused-expressions
    expect(await METL.PAUSER_ROLE()).to.exist;
  });
	
	it("Should block last ADMIN from revoking own role", async () => {
		const AR = await METL.DEFAULT_ADMIN_ROLE();
		 // eslint-disable-next-line no-unused-expressions
		await expect(METL.revokeRole(AR, owner.address)).to.be.revertedWith("Contract requires one admin");
	})

  it("Should allow MINTER to MINT", async () => {
    await METL.grantRole(handleHashString(WHITELIST_USER), pool.address);
    await METL.grantRole(handleHashString(FREE_MINTER), minter.address);
    await METL.connect(minter).bankMint(pool.address, 1000, handleHashString(transactionString));
    expect(await METL.totalSupply()).to.equal(1000);
  });

    it("Should block FREE_MINTER when freeMint is disabled", async () => {
    await METL.grantRole(handleHashString(WHITELIST_USER), pool.address);
    await METL.grantRole(handleHashString(FREE_MINTER), minter.address);
    await METL.setMintFeeStatus();
    await expect(METL.connect(minter).bankMint(pool.address, 1000, handleHashString(transactionString))).to.be.revertedWith("Free minting is prohibited!");
  });

  it("Should allow BURNER to BURN from POOL", async () => {
    await METL.grantRole(handleHashString(WHITELIST_USER), pool.address);
    await METL.grantRole(handleHashString(FREE_MINTER), minter.address);
    await METL.grantRole(handleHashString(FREE_BURNER), burner.address);
    await METL.connect(minter).bankMint(pool.address, 1000, handleHashString(transactionString));
    await METL.connect(burner).bankBurn(pool.address, 750, handleHashString(transactionString));
    expect(await METL.totalSupply()).to.equal(250);
  });

  it("Should block FREE_BURNER when freeBurn is disabled", async () => {
    await METL.grantRole(handleHashString(WHITELIST_USER), pool.address);
    await METL.grantRole(handleHashString(FREE_MINTER), minter.address);
    await METL.grantRole(handleHashString(FREE_BURNER), burner.address);
    await METL.connect(minter).bankMint(pool.address, 1000, handleHashString(transactionString));
    await METL.setBurnFeeStatus();
    await expect(METL.connect(burner).bankBurn(pool.address, 750, handleHashString(transactionString))).to.be.revertedWith("Free burning is prohibited!");
  });

  it("Should collect default fees to currentFeeCollector during feeBankMint", async () => {
    await METL.grantRole(handleHashString(WHITELIST_USER), pool.address);
    await METL.grantRole(handleHashString(MINTER_ROLE), minter.address);
    await METL.grantRole(handleHashString(FEE_CONTROLLER), owner.address);
    await METL.setFeeCollector(owner.address);
    await METL.connect(minter).feeBankMint(pool.address, 1000000000000000, handleHashString(transactionString));
    expect(await METL.balanceOf(owner.address)).to.equal(15000000000000);
  });

  it("Should allow FREEZER to FREEZE a USER", async () => {
    const FU = await METL.FROZEN_USER();
    await METL.grantRole(handleHashString(FREEZER_ROLE), freezer.address);
    await METL.connect(freezer).grantRole(handleHashString(FROZEN_USER), user.address);
    expect(await METL.getRoleMember(FU, 0)).to.equal(user.address);
  });

  it("Should allow PAUSER to PAUSE", async () => {
    await METL.grantRole(handleHashString(PAUSER_ROLE), pauser.address);
    await METL.connect(pauser).pause();
    await expect(
      METL.connect(user).transfer(minter.address, 1000)
    ).to.be.revertedWith("Pausable: paused");
  });

  it("Should allow PAUSER to UNPAUSE", async () => {
    await METL.grantRole(handleHashString(PAUSER_ROLE), pauser.address);
    await METL.connect(pauser).pause();
    await expect(
      METL.connect(user).transfer(minter.address, 1000)
    ).to.be.revertedWith("Pausable: paused");
    await METL.connect(pauser).unpause();
    await expect(
      METL.connect(user).transfer(minter.address, 1000)
    ).to.not.be.revertedWith("Pausable: paused");
  });

  it("Should allow FREEZER to UNFREEZE a USER", async () => {
    const FU = await METL.FROZEN_USER();
    await METL.grantRole(handleHashString(FREEZER_ROLE), freezer.address);
    await METL.connect(freezer).grantRole(handleHashString(FROZEN_USER), user.address);
    await METL.connect(freezer).revokeRole(handleHashString(FROZEN_USER), user.address);
    expect(await METL.getRoleMemberCount(FU)).to.equal(0);
  });

  it("Should allow OWNER to UPGRADE", async () => {
    const METLV3 = await ethers.getContractFactory("METLV3");
    const nuMETL = await upgrades.upgradeProxy(METL.address, METLV3);
    await METL.grantRole(handleHashString(FREE_MINTER), owner.address);
    await METL.grantRole(handleHashString(WHITELIST_USER), owner.address);
    await nuMETL.bankMint(owner.address, 1000, handleHashString(transactionString));
    expect(await nuMETL.balanceOf(owner.address)).to.equal(1000);
  });

  it("Should block NOT-MINTERS from MINTING to WHITELIST", async () => {
    await METL.grantRole(handleHashString(WHITELIST_USER), pool.address);
    await METL.grantRole(handleHashString(BURNER_ROLE), burner.address);
    await METL.grantRole(handleHashString(FREEZER_ROLE), freezer.address);
    await METL.grantRole(handleHashString(PAUSER_ROLE), pauser.address);
    await expect(METL.connect(owner).bankMint(pool.address, 1000, handleHashString(transactionString))).to.be.reverted;
    await expect(METL.connect(burner).bankMint(pool.address, 1000, handleHashString(transactionString))).to.be.reverted;
    await expect(METL.connect(freezer).bankMint(pool.address, 1000, handleHashString(transactionString))).to.be.reverted;
    await expect(METL.connect(pauser).bankMint(pool.address, 1000, handleHashString(transactionString))).to.be.reverted;
    await expect(METL.connect(user).bankMint(pool.address, 1000, handleHashString(transactionString))).to.be.reverted;
  });

  it("Should block NOT-BURNERS from BURNING from WHITELIST", async () => {
    await METL.grantRole(handleHashString(WHITELIST_USER), pool.address);
    await METL.grantRole(handleHashString(FREE_MINTER), minter.address);
    await METL.grantRole(handleHashString(FREEZER_ROLE), freezer.address);
    await METL.grantRole(handleHashString(PAUSER_ROLE), pauser.address);
    await METL.grantRole(handleHashString(FREE_BURNER), burner.address);
    await METL.connect(minter).bankMint(pool.address, 1000, handleHashString(transactionString));
    await expect(METL.connect(owner).bankBurn(pool.address, 750, handleHashString(transactionString))).to.be.reverted;
    await expect(METL.connect(minter).bankBurn(pool.address, 750, handleHashString(transactionString))).to.be.reverted;
    await expect(METL.connect(freezer).bankBurn(pool.address, 750, handleHashString(transactionString))).to.be.reverted;
    await expect(METL.connect(pauser).bankBurn(pool.address, 750, handleHashString(transactionString))).to.be.reverted;
    await expect(METL.connect(user).bankBurn(pool.address, 750, handleHashString(transactionString))).to.be.reverted;
    expect(await METL.totalSupply()).to.equal(1000);
    await METL.connect(burner).bankBurn(pool.address, 500, handleHashString(transactionString));
    expect(await METL.totalSupply()).to.equal(500);
  });

  it("Should block NOT-FREEZERS from FREEZING", async () => {
    await METL.grantRole(handleHashString(MINTER_ROLE), minter.address);
    await METL.grantRole(handleHashString(BURNER_ROLE), burner.address);
    await METL.grantRole(handleHashString(PAUSER_ROLE), pauser.address);
    await expect(METL.connect(owner).grantRole(handleHashString(FROZEN_USER), frozen.address)).to.be.reverted;
    await expect(METL.connect(minter).grantRole(handleHashString(FROZEN_USER), frozen.address)).to.be
      .reverted;
    await expect(METL.connect(burner).grantRole(handleHashString(FROZEN_USER), frozen.address)).to.be
      .reverted;
    await expect(METL.connect(pauser).grantRole(handleHashString(FROZEN_USER), frozen.address)).to.be
      .reverted;
    await expect(METL.connect(user).grantRole(handleHashString(FROZEN_USER), frozen.address)).to.be.reverted;
  });

  it("Should block NOT-FREEZERS from UNFREEZING", async () => {
    const FU = await METL.FROZEN_USER();
    await METL.grantRole(handleHashString(MINTER_ROLE), minter.address);
    await METL.grantRole(handleHashString(BURNER_ROLE), burner.address);
    await METL.grantRole(handleHashString(PAUSER_ROLE), pauser.address);
    await METL.grantRole(handleHashString(FREEZER_ROLE), freezer.address);
    await METL.connect(freezer).grantRole(handleHashString(FROZEN_USER), frozen.address);
    await expect(METL.connect(owner).revokeRole(handleHashString(FROZEN_USER), frozen.address)).to.be
      .reverted;
    await expect(METL.connect(minter).revokeRole(handleHashString(FROZEN_USER), frozen.address)).to.be
      .reverted;
    await expect(METL.connect(burner).revokeRole(handleHashString(FROZEN_USER), frozen.address)).to.be
      .reverted;
    await expect(METL.connect(pauser).revokeRole(handleHashString(FROZEN_USER), frozen.address)).to.be
      .reverted;
    await expect(METL.connect(user).revokeRole(handleHashString(FROZEN_USER), frozen.address)).to.be
      .reverted;
    expect(await METL.getRoleMember(FU, 0)).to.equal(frozen.address);
  });

  it("Should block FROZEN_USERS from SENDING", async () => {
    await METL.grantRole(handleHashString(FREEZER_ROLE), freezer.address);
    await METL.connect(freezer).grantRole(handleHashString(FROZEN_USER), frozen.address);
    await expect(
      METL.connect(frozen).transfer(user.address, 1000)
    ).to.be.revertedWith("Sender is currently frozen.");
  });

  it("Should block FROZEN_USERS from RECEIVING", async () => {
    await METL.grantRole(handleHashString(FREEZER_ROLE), freezer.address);
    await METL.grantRole(handleHashString(FREE_MINTER), minter.address);
    await METL.grantRole(handleHashString(WHITELIST_USER), pool.address);
    await METL.connect(minter).bankMint(pool.address, 1000, handleHashString(transactionString));
    await METL.connect(pool).transfer(frozen.address, 1000);
    await METL.connect(freezer).grantRole(handleHashString(FROZEN_USER), frozen.address);
    await expect(
      METL.connect(pool).transfer(frozen.address, 1000)
    ).to.be.revertedWith("Recipient is currently frozen.");
  });

	it("Should block FROZEN_USERS from RENOUNCING", async () => {
		await METL.grantRole(handleHashString(FREEZER_ROLE), freezer.address);
		await METL.connect(freezer).grantRole(handleHashString(FROZEN_USER), frozen.address);
		const FR = await METL.FROZEN_USER();
		await expect(METL.connect(frozen).renounceRole(FR, frozen.address)).to.be.revertedWith("Only role admin can revoke");
	});
	
	it("Should block last ADMIN from RENOUNCING", async () => {
		const DAR = await METL.DEFAULT_ADMIN_ROLE();
		await expect(METL.renounceRole(DAR, owner.address)).to.be.revertedWith("Contract requires one admin")
	});

    it("Should revert on burn", async () => {
      await expect(METL.burn(10000000)).to.be.reverted;
    });

    it("Should revert on burnFrom", async () => {
      await expect(METL.burn(minter, 10000000)).to.be.reverted;
    });

  // it("Should block NOT-OWNER to UPGRADE", async () => {
  // 	const METLV2 = await ethers.getContractFactory("METLV2");
  // 	upgrades.admin.transferProxyAdminOwnership(user.address);
  // 	await expect(upgrades.upgradeProxy(METL.address, METLV2)).to.be.reverted;
  // });
});
