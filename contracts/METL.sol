//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract METL is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  AccessControlEnumerableUpgradeable
{
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
  bytes32 public constant FROZEN_USER = keccak256("FROZEN_USER");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant SENDER_ROLE = keccak256("SENDER_ROLE");
  event RoleChange(address wallet, string role, bool wasAdded);
  event PoolChange(address newPool);
  address public poolAddress;

  function initialize() public initializer {
    __ERC20_init("METL Coin", "METL");
    __ERC20Burnable_init();
    __Pausable_init();
    __AccessControl_init();
    poolAddress = 0x0000000000000000000000000000000000000000;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(FROZEN_USER, FREEZER_ROLE);
  }

  function changePoolAddress(address newAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    poolAddress = newAddress;
    emit PoolChange(newAddress);
  }

  function addAdmin(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, newAddress);
    emit RoleChange(newAddress, "Admin", true);
  }

  function removeAdmin(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(DEFAULT_ADMIN_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Admin", false);
  }

  function addMinter(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(MINTER_ROLE, newAddress);
    emit RoleChange(newAddress, "Minter", true);
  }

  function removeMinter(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(MINTER_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Minter", false);
  }

  function addBurner(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(BURNER_ROLE, newAddress);
    emit RoleChange(newAddress, "Burner", true);
  }

  function removeBurner(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(BURNER_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Burner", false);
  }

  // EDIT FREEZERS
  function addFreezer(address newAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    grantRole(FREEZER_ROLE, newAddress);
    emit RoleChange(newAddress, "Freezer", true);
  }

  function removeFreezer(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(FREEZER_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Freezer", false);
  }

  // EDIT FROZEN USERS
  function freezeUser(address newAddress) external onlyRole(FREEZER_ROLE) {
    grantRole(FROZEN_USER, newAddress);
    emit RoleChange(newAddress, "Frozen", true);
  }

  function unfreezeUser(address oldAddress) external onlyRole(FREEZER_ROLE) {
    revokeRole(FROZEN_USER, oldAddress);
    emit RoleChange(oldAddress, "Frozen", false);
  }

  // EDIT PAUSERS
  function addPauser(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(PAUSER_ROLE, newAddress);
    emit RoleChange(newAddress, "Pauser", true);
  }

  function removePauser(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(PAUSER_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Pauser", false);
  }

  // MINT
  function poolMint(uint256 amount) external onlyRole(MINTER_ROLE) {
    require(
      poolAddress != 0x0000000000000000000000000000000000000000,
      "METL Pool not set"
    );
    _mint(poolAddress, amount);
  }

  // BURN
  function poolBurn(uint256 amount) external onlyRole(BURNER_ROLE) {
    require(
      poolAddress != 0x0000000000000000000000000000000000000000,
      "METL Pool not set"
    );
    _burn(poolAddress, amount);
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
  function poolTransfer(address recipient, uint256 amount)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(
      poolAddress != 0x0000000000000000000000000000000000000000,
      "METL Pool not set"
    );
    transferFrom(poolAddress, recipient, amount);
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
  // TO UPGRADE:
  // Duplicate this file, change the contract name, and add new code below this block
  // Deploy as normal
}
