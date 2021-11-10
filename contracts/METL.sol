//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////
//      ...     ..      ..           ..      .         .....                ...       //
//    x*8888x.:*8888: -"888:      x88f` `..x88. .>  .H8888888h.  ~-.    .zf"` `"tu    //
//   X   48888X `8888H  8888    :8888   xf`*8888%   888888888888x  `>  x88      '8N.  //
//  X8x.  8888X  8888X  !888>  :8888f .888  `"`    X~     `?888888hx~  888k     d88&  //
//  X8888 X8888  88888   "*8%- 88888' X8888. >"8x  '      x8.^"*88*"   8888N.  @888F  //
//  '*888!X8888> X8888  xH8>   88888  ?88888< 888>  `-:- X8888x        `88888 9888%   //
//    `?8 `8888  X888X X888>   88888   "88888 "8%        488888>         %888 "88F    //
//    -^  '888"  X888  8888>   88888 '  `8888>         .. `"88*           8"   "*h=~  //
//     dx '88~x. !88~  8888>   `8888> %  X88!        x88888nX"      .   z8Weu         //
//   .8888Xf.888x:!    X888X.:  `888X  `~""`   :    !"*8888888n..  :   ""88888i.   Z  //
//  :""888":~"888"     `888*"     "88k.      .~    '    "*88888888*   "   "8888888*   //
//      "~'    "~        ""         `""*==~~`              ^"***"`          ^"**""    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title ERC20 token for Metl by RaidGuild
 *
 * @author mpbowes, dcoleman, mkdir
 */
contract METL is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  AccessControlEnumerableUpgradeable
{
  // Role for minters
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // Role for burners
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  // Role for freezers
  bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");

  // Role for frozen users
  bytes32 public constant FROZEN_USER = keccak256("FROZEN_USER");

  // Role for pausers
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // Role for Multisig
  bytes32 public constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");

  // Emit event for role changes
  event RoleChange(address wallet, string role, bool wasAdded);

  // Emit event for pooladdress changes
  event PoolChange(address newPool);

  // Address for mint/burn pool
  address public poolAddress;

  /**
   * @notice Initializes contract and sets state variables
   * Note: no params, just assigns deployer to default_admin_role
   */
  function initialize() public initializer {
    __ERC20_init("METL Coin", "METL");
    __ERC20Burnable_init();
    __Pausable_init();
    __AccessControl_init();
    poolAddress = address(0);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(FROZEN_USER, FREEZER_ROLE);
  }

  /**
   * @notice Admins may update the shared pool address
   * @param newAddress address of new pool
   */
  function changePoolAddress(address newAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    poolAddress = newAddress;
    emit PoolChange(newAddress);
  }

  /**
   * @notice Admins may add other admins
   * @param newAddress address of new admin
   */

  function addAdmin(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, newAddress);
    emit RoleChange(newAddress, "Admin", true);
  }

  /**
   * @notice Admins may revoke other admins
   * @param oldAddress address of admin to revoke
   */
  function removeAdmin(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(DEFAULT_ADMIN_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Admin", false);
  }

  /**
   * @notice Whitelists a bank multisig address
   * @param newAddress address of multisig to add
   */
  function addMultisig(address newAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    grantRole(MULTISIG_ROLE, newAddress);
    emit RoleChange(newAddress, "Multisig", true);
  }

  /**
   * @notice Whitelists a bank multisig address
   * @param oldAddress address of multisig to add
   */
  function revokeMultisig(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    grantRole(MULTISIG_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Multisig", false);
  }

  /**
   * @notice Admins may add new minters
   * @param newAddress address to grant minter role to
   */
  function addMinter(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(MINTER_ROLE, newAddress);
    emit RoleChange(newAddress, "Minter", true);
  }

  /**
   * @notice Admins may revoke minters
   * @param oldAddress address of minter to revoke
   */
  function removeMinter(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(MINTER_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Minter", false);
  }

  /**
   * @notice Admins may add new burners
   * @param newAddress address to grant burner role
   */
  function addBurner(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(BURNER_ROLE, newAddress);
    emit RoleChange(newAddress, "Burner", true);
  }

  /**
   * @notice Admins may revoke burners
   * @param oldAddress address of burner to revoke
   */
  function removeBurner(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(BURNER_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Burner", false);
  }

  /**
   * @notice Admins may add new freezers
   * @param newAddress address to grant freezer role
   */
  function addFreezer(address newAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    grantRole(FREEZER_ROLE, newAddress);
    emit RoleChange(newAddress, "Freezer", true);
  }

  /**
   * @notice Admins may revoke freezers
   * @param oldAddress address of freezer to revoke
   */
  function removeFreezer(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(FREEZER_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Freezer", false);
  }

  /**
   * @notice Freezers may 'freeze' users
   * @param newAddress address to freeze
   */
  function freezeUser(address newAddress) external onlyRole(FREEZER_ROLE) {
    grantRole(FROZEN_USER, newAddress);
    emit RoleChange(newAddress, "Frozen", true);
  }

  /**
   * @notice Freezers may 'unfreeze' users
   * @param oldAddress address to unfreeze
   */
  function unfreezeUser(address oldAddress) external onlyRole(FREEZER_ROLE) {
    revokeRole(FROZEN_USER, oldAddress);
    emit RoleChange(oldAddress, "Frozen", false);
  }

  /**
   * @notice Admins may add new pausers
   * @param newAddress address to grant pauser role
   */
  function addPauser(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(PAUSER_ROLE, newAddress);
    emit RoleChange(newAddress, "Pauser", true);
  }

  /**
   * @notice Admins may revoke pausers
   * @param oldAddress address of pauser to revoke
   */
  function removePauser(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(PAUSER_ROLE, oldAddress);
    emit RoleChange(oldAddress, "Pauser", false);
  }

  /**
   * @notice Minters may mint tokens to a pool
   * @param amount how many tokens to mint
   */
  function poolMint(uint256 amount) external onlyRole(MINTER_ROLE) {
    require(poolAddress != address(0), "METL Pool not set");
    _mint(poolAddress, amount);
  }

  /**
   * @notice Minters may mint tokens to a whitelisted pool
   * @param recipient the whitelisted multisig to mint to
   * @param amount how many tokens to mint
   */
  function bankMint(address recipient, uint256 amount)
    external
    onlyRole(MINTER_ROLE)
  {
    require(
      hasRole(MULTISIG_ROLE, recipient),
      "Recipient must be whitelisted."
    );
    _mint(recipient, amount);
  }

  /**
   * @notice Burners may burn tokens from a pool
   * @param amount how many tokens to burn
   */
  function poolBurn(uint256 amount) external onlyRole(BURNER_ROLE) {
    require(poolAddress != address(0), "METL Pool not set");
    _burn(poolAddress, amount);
  }

  /**
   * @notice Require users to be unfrozen before allowing a transfer
   * @param sender address tokens will be deducted from
   * @param recipient address tokens will be registered to
   * @param amount how many tokens to send
   */
  function _beforeTokenTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override whenNotPaused {
    require(!hasRole(FROZEN_USER, sender), "Sender is currently frozen.");
    require(!hasRole(FROZEN_USER, recipient), "Recipient is currently frozen.");
    super._beforeTokenTransfer(sender, recipient, amount);
  }

  /**
   * @notice Admins may send tokens from a pool
   * @param recipient address tokens will be registered to
   * @param amount how many tokens to send
   */
  function poolTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(hasRole(MULTISIG_ROLE, sender), "Recipient must be whitelisted.");
    transferFrom(poolAddress, recipient, amount);
  }

  /**
   * @notice Pausers may pause the network
   */
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @notice Pausers may unpause the network
   */
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
