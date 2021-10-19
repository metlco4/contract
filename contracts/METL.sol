//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract METL is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bytes32 public constant FROZEN_USER = keccak256("FROZEN_USER");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
	// constructor() initializer {}

    function initialize() public initializer {
        __ERC20_init("METL Coin", "METL");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function add_minter(address newAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, newAddress);
    }

    function remove_minter(address oldAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MINTER_ROLE, oldAddress);
    }

    function add_burner(address newAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(BURNER_ROLE, newAddress);
    }

    function remove_burner(address oldAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(BURNER_ROLE, oldAddress);
    }

    // EDIT FREEZERS
    function add_freezer(address newAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(FREEZER_ROLE, newAddress);
    }

    function remove_freezer(address oldAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(FREEZER_ROLE, oldAddress);
    }

    // EDIT FROZEN USERS
    function freeze_user(address newAddress) public onlyRole(FREEZER_ROLE) {
        grantRole(FROZEN_USER, newAddress);
    }

    function unfreeze_user(address oldAddress) public onlyRole(FREEZER_ROLE) {
        revokeRole(FROZEN_USER, oldAddress);
    }

    // EDIT PAUSERS
    function add_pauser(address newAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(PAUSER_ROLE, newAddress);
    }

    function remove_pauser(address oldAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(PAUSER_ROLE, oldAddress);
    }

	// FUNCTIONS
    // MINT
    // to do: hardcode multisig wallet address in from
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // BURN
    // to do: hardcode multisig wallet address in from (?)
    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    // TRANSFER (and block frozen wallets)
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override whenNotPaused {
        require(!hasRole(FROZEN_USER, sender), "Sender is currently frozen.");
        require(!hasRole(FROZEN_USER, recipient), "Recipient is currently frozen.");
        super._beforeTokenTransfer(sender, recipient, amount);
    }

    // SEND

    // to do: hardcode multisig wallet address in sender
    function adminTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        transferFrom(sender, recipient, amount);
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
	// UPGRADE is handled via a transparent proxy network
	// It is not an internal contract call
	// On deploy, the only account able to updgrade the contract is the DEPLOYER
	// DEPLOYER may call transferOwnership(address newOwner) on the contract to TRANSFER OWNERSHIP to the new address
	// THERE IS ONLY EVER ONE OWNER
	// https://docs.openzeppelin.com/upgrades-plugins/1.x/faq#what-is-a-proxy-admin
}
