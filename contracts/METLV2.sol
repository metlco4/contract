//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract METLV2 is
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
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    poolAddress = newAddress;
  }

  function addMinter(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(MINTER_ROLE, newAddress);
  }

  function removeMinter(address oldAddress)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(MINTER_ROLE, oldAddress);
  }

  function addBurner(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(BURNER_ROLE, newAddress);
  }

  function removeBurner(address oldAddress)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(BURNER_ROLE, oldAddress);
  }

  // EDIT FREEZERS
  function addFreezer(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(FREEZER_ROLE, newAddress);
  }

  function removeFreezer(address oldAddress)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(FREEZER_ROLE, oldAddress);
  }

  // EDIT FROZEN USERS
  function freezeUser(address newAddress) public onlyRole(FREEZER_ROLE) {
    grantRole(FROZEN_USER, newAddress);
  }

  function unfreezeUser(address oldAddress) public onlyRole(FREEZER_ROLE) {
    revokeRole(FROZEN_USER, oldAddress);
  }

  // EDIT PAUSERS
  function addPauser(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(PAUSER_ROLE, newAddress);
  }

  function removePauser(address oldAddress)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(PAUSER_ROLE, oldAddress);
  }

  // MINT
  function poolMint(uint256 amount) public onlyRole(MINTER_ROLE) {
    require(
      poolAddress != 0x0000000000000000000000000000000000000000,
      "METL Pool not set"
    );
    _mint(poolAddress, amount);
  }

  // BURN
  function poolBurn(uint256 amount) public onlyRole(BURNER_ROLE) {
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

  function mint(address recipient, uint256 amount) public {
    _mint(recipient, amount);
  }
}
