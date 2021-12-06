# METL ERC20 Smart Contract

### Develop Locally

Download files and run `yarn`

## Upgrading

Download and run `yarn`

Duplicate `src/contracts/METL.sol`

Rename duplicated solidity file to whatever you please. We recommend `METLvX.sol`
**Important:** you must also rename the contract on line 32 to match filename (for testing).

Add new code below line 286.
Refer to code comments in lines 277 to 286 for upgrade deployment instructions.
The original deployer is Mackenzie on Rinkeby and Avalanche C-Chain.

## Testing

Duplicate `src/test/metl-tests.js`

Edit the string on line 17

```
    Token = await ethers.getContractFactory("CONTRACT_NAME_HERE");
```

That string is used to iterate through `src/contracts/*.sol` looking for a contract with exactly that name.

Add tests using Mocha, Chai, and Ethers.

To run tests, run `npx hardhat test` from the command line.

## Deploying

### To deploy to ETH Mainnet or Testnets, add a network to `src/hardhat.config.js`

```
  networks: {
    rinkeby: {
      url: process.env.RINKEBY_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
		mainnet: {
			url: process.env.MAINNET_URL || "",
			accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
		}
  },
```

where `*_URL` is an alchemy api URL and `PRIVATE_KEY` is a deployer hotwallet private key stored in
`src/.env` (this file is ignored by git, you'll need to create it locally to deploy.)
**Important:** storing private keys in `.env` is dangerous. Make sure it's a hot wallet and transfer ownership to a more secure wallet soon after deploying on Mainnet.

### To deploy on Avalanche C-Chain:

Duplicate contents of your solidity file to a new Remix window.
Follow the [instructions here](https://docs.avax.network/build/tutorials/smart-contracts/deploy-a-smart-contract-on-avalanche-using-remix-and-metamask)

## DAPP User Guide:
https://hackmd.io/@N6gQB3PZSY-b9EWhAgPtbw/BJeq6u6DY
