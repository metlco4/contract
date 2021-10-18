//SPDX-License-Identifier: Unlicensed
pragma solidity ^2.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract METL is Initializable, ERC20Upgradable, ERC20BurnableUpgradable, PausableUpgradeable, AccessControlUpgradeable  {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
	bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
	bytes32 public constant FROZEN_ROLE = keccak256("FROZEN_ROLE");

	constructor() initializer {}

	function initialize() initializer public {
		__ERC20_init("METL Coin", "METL");
		__ERC20Burnable_init();
		__Pausable_init();
		__AccessControl_init();

		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	// ROLES - HANDLE STORING ADDRESSES INTO STATE TO VALIDATE FUNCTION REQUESTS
		// ADMIN

		constructor(address owner) ERC20("METL Coin","METL") {
			_setupRole(MINTER_ROLE, null);
			_setupRole(BURNER_ROLE, null);
			_setupRole(FREEZER_ROLE, null);
			_setupRole(PAUSER_ROLE, null);
			_setupRole(UPGRADER_ROLE, null);
		}

// FUNCTIONS - PERFORMANCE LOGIC
	// EDIT ROLES
	function add_minter(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		grantRole(MINTER_ROLE, newAddress);
	}

	function remove_minter(address oldAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		revokeRole(MINTER_ROLE, oldAddress);
	}

	function add_burner(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		grantRole(BURNER_ROLE, newAddress);
	}

	function remove_burner(address oldAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		revokeRole(BURNER_ROLE, oldAddress);
	}

	// EDIT FREEZERS

	function add_freezer(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		grantRole(FREEZER_ROLE, newAddress);
	}
	function remove_freezer(address oldAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		revokeRole(FREEZER_ROLE, oldAddress);
	}

	// EDIT FROZENERS
	function freeze_user(address newAddress) public onlyRole(FREEZER_ROLE) {
		grantRole(FREEZER_ROLE, newAddress);
	}
	function unfreeze_user(address oldAddress) public onlyRole(FREEZER_ROLE) {
		revokeRole(FREEZER_ROLE, oldAddress);
	}

	// EDIT PAUSERS
	function add_pauser(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		grantRole(PAUSER_ROLE, newAddress);
	}
	function remove_pauser(address oldAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		revokeRole(PAUSER_ROLE, oldAddress);
	}

	// EDIT UPGRADERS

	function add_upgrader(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		grantRole(UPGRADER_ROLE, newAddress);
	}
	function remove_upgrader(address oldAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		revokeRole(UPGRADER_ROLE, oldAddress);
	}

	// MINT
	// to do: hardcode multisig wallet address in from
	function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
		_mint(to, amount);
	}

	// BURN
	// to do: hardcode multisig wallet address in from
	function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
		_burn(from, amount);
	}

	// TRANSFER (and block frozen wallets)

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override
	{
		require(!hasRole(FROZEN_ROLE, from), "Sender is currently frozen.");
		require(!hasRole(FROZEN_ROLE, to), "Recipient is currently frozen.");
		super._beforeTokenTransfer(from, to, amount);
	}

	// SEND

	// to do: hardcode multisig wallet address in from
	function adminTransfer(address from, address to, uint256 amount) onlyRole(DEFAULT_ADMIN_ROLE) {
		transfer(from, to, amount);
	}


	// PAUSE
	function pause() public onlyRole(PAUSER_ROLE) {
		_pause();
	}

	// UNPAUSE
	function unpause() public onlyRole(PAUSER_ROLE) {
		_unpause();
	}

	// UPGRADE
}