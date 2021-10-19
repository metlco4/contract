const { ethers, upgrades } = require('hardhat');

const contractAddress; // set your old contract address here - string
// note: the old contract address is technically the 'proxy' contract address,
// for all intents and purposes it is the contract address, it's the same one
// that you interact with on etherscan and everyone calls for mints, burns, and transfers. 

const newContractName; // set your new contract name here - string, eg 'METLV2'

async function main() {
	const newMETL = await ethers.getContractFactory(newContractName);
	console.log('Upgrading METL...');
	await upgrades.upgradeProxy(contractAddress, newMETL);
	console.log('METL Upgraded');
}

main();