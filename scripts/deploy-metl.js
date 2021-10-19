const { ethers, upgrades } = require('hardhat');

async function main() {
	const METL = await ethers.getContractFactory('METL');
	const metl = await upgrades.deployProxy(METL);
	await metl.deployed();
	console.log('Proxy Address: ', metl.address);
	console.log('KEEP TRACK OF PROXY ADDRESS. IT IS REQUIRED FOR UPGRADING.');
	console.log('MAKE MULTIPLE COPIES.');
}

main();