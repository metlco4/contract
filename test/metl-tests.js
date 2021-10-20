const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");


describe("METL", function () {

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

	beforeEach(async function () {
		Token = await ethers.getContractFactory("METL");
		[owner, minter, burner, pauser, freezer, frozen, pool, user] = await ethers.getSigners();
		// Q: is everyone in the above array deploying the contract?
		METL = await upgrades.deployProxy(Token);
		await METL.deployed();
	})

	it("Should have a name", async () => {
		expect(await METL.name()).to.exist;
	})

	it("Should be named METL Coin", async () => {
		expect(await METL.name()).to.equal("METL Coin");
	})

	it("Should have a symbol", async () => {
		expect(await METL.symbol()).to.exist;
	})

	it("Should have the symbol 'METL'", async () => {
		expect(await METL.symbol()).to.equal("METL");
	})
	
	it("Should have an admin role", async () => {
		expect(await METL.DEFAULT_ADMIN_ROLE()).to.exist;
	})

	it("Should set the admin role to the owner address", async () => {
		const DFA = await METL.DEFAULT_ADMIN_ROLE();
		expect(await METL.getRoleMember(DFA, 0)).to.equal(owner.address);
	});

	it("Should allow the owner to change the pool address", async () => {
		await METL.changePoolAddress(pool.address);
		expect(await METL.poolAddress()).to.equal(pool.address);
	})
	it("Should have a 'MINTER' role", async () => {
		expect(await METL.MINTER_ROLE()).to.exist;
	});
	it("Should have a 'BURNER' role", async () => {
		expect(await METL.BURNER_ROLE()).to.exist;
	});
	it("Should have a 'FREEZER' role", async () => {
		expect(await METL.FREEZER_ROLE()).to.exist;
	});
	it("Should have a 'FROZEN' role", async () => {
		expect(await METL.FROZEN_USER()).to.exist;
	});
	it("Should have a 'PAUSER' role", async () => {
		expect(await METL.PAUSER_ROLE()).to.exist;
	});

	it("Should allow ADMIN to add to MINTER_ROLE", async () => {
		const MR = await METL.MINTER_ROLE();
		await METL.addMinter(minter.address);
		expect(await METL.getRoleMember(MR, 0)).to.equal(minter.address);
	});

	it("Should allow ADMIN to add to BURNER_ROLE", async () => {
		const BR = await METL.BURNER_ROLE();
		await METL.addBurner(burner.address);
		expect(await METL.getRoleMember(BR, 0)).to.equal(burner.address);
	});

	it("Should allow ADMIN to add to FREEZER_ROLE", async () => {
		const FR = await METL.FREEZER_ROLE();
		await METL.addFreezer(freezer.address);
		expect(await METL.getRoleMember(FR, 0)).to.equal(freezer.address);
	});

	it("Should allow ADMIN to add to PAUSER_ROLE", async () => {
		const PR = await METL.PAUSER_ROLE();
		await METL.addPauser(pauser.address);
		expect(await METL.getRoleMember(PR, 0)).to.equal(pauser.address);
	});


	it("Should allow ADMIN to remove from MINTER_ROLE", async () => {
		const MR = await METL.MINTER_ROLE();
		await METL.addMinter(minter.address);
		await METL.removeMinter(minter.address);
		expect(await METL.getRoleMemberCount(MR)).to.equal(0);
	});

	it("Should allow ADMIN to remove from BURNER_ROLE", async () => {
		const BR = await METL.BURNER_ROLE();
		await METL.addBurner(burner.address);
		await METL.removeBurner(burner.address);
		expect(await METL.getRoleMemberCount(BR)).to.equal(0);
	});

	it("Should allow ADMIN to remove from FREEZER_ROLE", async () => {
		const FR = await METL.FREEZER_ROLE();
		await METL.addFreezer(freezer.address);
		await METL.removeFreezer(freezer.address);
		expect(await METL.getRoleMemberCount(FR)).to.equal(0);
	});

	it("Should allow ADMIN to remove from PAUSER_ROLE", async () => {
		const PR = await METL.PAUSER_ROLE();
		await METL.addPauser(pauser.address);
		await METL.removePauser(pauser.address);
		expect(await METL.getRoleMemberCount(PR)).to.equal(0);
	});

	it("Should allow MINTER to MINT", async () => {
		await METL.changePoolAddress(pool.address);
		await METL.addMinter(minter.address);
		await METL.connect(minter).poolMint(1000);
		expect(await METL.totalSupply()).to.equal(1000);
	});

	it("Should allow BURNER to BURN from POOL", async () => {
		await METL.changePoolAddress(pool.address);
		await METL.addMinter(minter.address);
		await METL.addBurner(burner.address);
		await METL.connect(minter).poolMint(1000);
		await METL.connect(burner).poolBurn(750);
		expect(await METL.totalSupply()).to.equal(250);
	});

	it("Should allow FREEZER to FREEZE a USER", async () => {
		const FU = await METL.FROZEN_USER();
		await METL.addFreezer(freezer.address);
		await METL.connect(freezer).freezeUser(user.address);
		expect(await METL.getRoleMember(FU, 0)).to.equal(user.address);
	});

	it("Should allow PAUSER to PAUSE", async () => {
		await METL.addPauser(pauser.address);
		await METL.connect(pauser).pause();
		await expect(METL.connect(user).transfer(minter.address, 1000)).to.be.revertedWith("Pausable: paused");
	});

	it("Should allow PAUSER to UNPAUSE", async () => {
		await METL.addPauser(pauser.address);
		await METL.connect(pauser).pause();
		await expect(METL.connect(user).transfer(minter.address, 1000)).to.be.revertedWith("Pausable: paused");
		await METL.connect(pauser).unpause();
		await expect(METL.connect(user).transfer(minter.address, 1000)).to.not.be.revertedWith("Pausable: paused");
	});

	it("Should allow OWNER to UPGRADE", async () => {
		const METLV2 = await ethers.getContractFactory("METLV2");
		const nuMETL = await upgrades.upgradeProxy(METL.address, METLV2);
		await nuMETL.mint(user.address, 1000)
		expect(await nuMETL.balanceOf(user.address)).to.equal(1000);
	})

	it("Should block NOT-MINTERS from MINTING to POOL", async () => {
		await METL.changePoolAddress(pool.address);
		await METL.addBurner(burner.address);
		await METL.addFreezer(freezer.address);
		await METL.addPauser(pauser.address);
		await expect(METL.connect(owner).poolMint(1000)).to.be.reverted;
		await expect(METL.connect(burner).poolMint(1000)).to.be.reverted;
		await expect(METL.connect(freezer).poolMint(1000)).to.be.reverted;
		await expect(METL.connect(pauser).poolMint(1000)).to.be.reverted;
		await expect(METL.connect(user).poolMint(1000)).to.be.reverted;
	})

	it("Should block NOT-BURNERS from BURNING from POOL", async () => {
		await METL.changePoolAddress(pool.address);
		await METL.addMinter(minter.address);
		await METL.addFreezer(freezer.address);
		await METL.addPauser(pauser.address);
		await METL.connect(minter).poolMint(1000);
		await expect(METL.connect(owner).poolBurn(750)).to.be.reverted;
		await expect(METL.connect(minter).poolBurn(750)).to.be.reverted;
		await expect(METL.connect(freezer).poolBurn(750)).to.be.reverted;
		await expect(METL.connect(pauser).poolBurn(750)).to.be.reverted;
		await expect(METL.connect(user).poolBurn(750)).to.be.reverted;
		expect(await METL.totalSupply()).to.equal(1000);
	});

	it("Should block NOT-FREEZERS from FREEZING", async () => {
		await METL.addMinter(minter.address);
		await METL.addBurner(burner.address);
		await METL.addPauser(pauser.address);
		await expect(METL.connect(owner).freezeUser(frozen.address)).to.be.reverted;
		await expect(METL.connect(minter).freezeUser(frozen.address)).to.be.reverted;
		await expect(METL.connect(burner).freezeUser(frozen.address)).to.be.reverted;
		await expect(METL.connect(pauser).freezeUser(frozen.address)).to.be.reverted;
		await expect(METL.connect(user).freezeUser(frozen.address)).to.be.reverted;
	})

	it("Should block NOT-FREEZERS from UNFREEZING", async () => {
		const FU = await METL.FROZEN_USER();
		await METL.addMinter(minter.address);
		await METL.addBurner(burner.address);
		await METL.addPauser(pauser.address);
		await METL.addFreezer(freezer.address);
		await METL.connect(freezer).freezeUser(frozen.address);
		await expect(METL.connect(owner).unfreezeUser(frozen.address)).to.be.reverted;
		await expect(METL.connect(minter).unfreezeUser(frozen.address)).to.be.reverted;
		await expect(METL.connect(burner).unfreezeUser(frozen.address)).to.be.reverted;
		await expect(METL.connect(pauser).unfreezeUser(frozen.address)).to.be.reverted;
		await expect(METL.connect(user).unfreezeUser(frozen.address)).to.be.reverted;
		expect(await METL.getRoleMember(FU, 0)).to.equal(frozen.address);
	})

	it("Should block FROZEN_USERS from SENDING", async () => {
		await METL.addFreezer(freezer.address);
		await METL.connect(freezer).freezeUser(frozen.address);
		await expect(METL.connect(frozen).transfer(user.address, 1000)).to.be.revertedWith("Sender is currently frozen.");
	});

	it("Should block FROZEN_USERS from RECEIVING", async () => {
		await METL.addFreezer(freezer.address);
		await METL.connect(freezer).freezeUser(frozen.address);
		await expect(METL.connect(user).transfer(frozen.address, 1000)).to.be.revertedWith("Recipient is currently frozen.");
	});
});
