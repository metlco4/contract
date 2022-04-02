//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.11;

////////////////////////////////////////////////////////////////////////////////////////
//      ...     ..      ..           ..      .         .....                ...       //
//    x*8888x.:*8888: -"888:      x88f` `..x88. .>  .H8888888h.  ~-.    .zf"` `"tu    //
//   X   48888X `8888H  8888    :8888   xf`*8888%   888888888888x  `>  x88      '8N.  //
//  X8x.  8888X  8888X  !888>  :8888f .888  `"`    X~     `?888888hx~  888k     d88&  //
//  X8888 X8888  88888   "*8%- 88888' X8888. >"8x  '      x8.^"*88*"   8888N.  $888F  //
//  '*888!X8888> X8888  xH8>   88888  ?88888< 888>  `-:- X8888x        `88888 9888%   //
//    `?8 `8888  X888X X888>   88888   "88888 "8%        488888>         %888 "88F    //
//    -^  '888"  X888  8888>   88888 '  `8888>         .. `"88*           8"   "*h=~  //
//     dx '88~x. !88~  8888>   `8888> %  X88!        x88888nX"      .   z8Weu         //
//   .8888Xf.888x:!    X888X.:  `888X  `~""`   :    !"*8888888n..  :   ""88888i.   Z  //
//  :""888":~"888"     `888*"     "88k.      .~    '    "*88888888*   "   "8888888*   //
//      "~'    "~        ""         `""*==~~`              ^"***"`          ^"**""    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @title ERC20 token for Metl by RaidGuild
 *
 * @author mpbowes, dcoleman, mkdir, kyle_stargarden
 */
contract METLV3 is
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

  // Role for whitelisted users
  bytes32 public constant WHITELIST_USER = keccak256("WHITELIST_USER");

  // Role for the fee controller
  bytes32 public constant FEE_CONTROLLER = keccak256("FEE_CONTROLLER");

  // Basis Point values
  uint256 public constant BASIS_RATE = 1000000000;

  event ReceivedMint(address indexed receipient, uint256 indexed amount, bytes32 indexed bytesId, string transferId);

  event MintFee(address indexed feeCollector, uint256 indexed fee);

  // variableRate is the
  uint256 public variableRate;

  // Address where fees are collected
  address public currentFeeCollector;

  /**
   * @notice Initializes contract and sets state variables
   * Note: no params, just assigns deployer to default_admin_role
   */
  function initialize() public initializer {
    __ERC20_init("USD Receipt", "USDR");
    __ERC20Burnable_init();
    __Pausable_init();
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(FROZEN_USER, FREEZER_ROLE);
    variableRate = 15000000; // 15000000 = 1.5%
  }

  /**
   * @notice Modify basis point variable rate
   */
  function updateVariableRate(uint256 newRate)
    external
    onlyRole(FEE_CONTROLLER)
  {
    // Variable fee must be adjusted in increments of 0.1%
    require(newRate % 1000000 == 0, "Variable rate must be in increments of 0.1%!");
    // Variable fee is never over 10%
    require(newRate < 100000000, "New Rate Too Large");
    // Variable fee is never under 0.3%
    require(newRate > 3000000, "New Rate Too Small");
    variableRate = newRate;
  }

  /**
  * @notice Return the keccak256 hash of a string
  */
  function toBytes32(string calldata transferId) public pure returns(bytes32 hash) {
    return keccak256(abi.encodePacked(transferId));
  }

  /**
  * @notice Set address of fee collector
  */
  function setFeeCollector(address feeCollector) external onlyRole(FEE_CONTROLLER) {
    currentFeeCollector = feeCollector;
  }

  /**
   * @notice Modified Revoke Role for security
   */
  function revokeRole(bytes32 role, address account) public override {
    if (role == DEFAULT_ADMIN_ROLE) {
      require(getRoleMemberCount(role) > 1, "Contract requires one admin");
    }
    super.revokeRole(role, account);
  }

  /**
   * @notice Override preventing frozen accounts and the last admin from renouncing
   */
  function renounceRole(bytes32 role, address account) public override {
    if (role == FROZEN_USER) {
      require(hasRole(FREEZER_ROLE, msg.sender), "Only role admin can revoke.");
    }
    if (role == DEFAULT_ADMIN_ROLE) {
      require(getRoleMemberCount(role) > 1, "Contract requires one admin");
    }
    super.renounceRole(role, account);
  }

  /**
   * @notice Admins may add other admins
   * @param newAddress address of new admin
   */
  function addAdmin(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, newAddress);
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
  }

  /**
   * @notice Whitelists a whitelisted user address
   * @param newAddress address of user to add
   */
  function addWhitelist(address newAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    grantRole(WHITELIST_USER, newAddress);
  }

  /**
   * @notice Removes a user's whitelist address
   * @param oldAddress address of whitelist to add
   */
  function revokeWhitelist(address oldAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(WHITELIST_USER, oldAddress);
  }

  /**
   * @notice Admins may add new fee_controller
   * @param newAddress address to grant fee_controller role
   */
  function addController(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(FEE_CONTROLLER, newAddress);
  }

  /**
   * @notice Admins may add new minters
   * @param newAddress address to grant minter role
   */
  function addMinter(address newAddress) external {
    grantRole(MINTER_ROLE, newAddress);
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
  }

  /**
   * @notice Admins may add new burners
   * @param newAddress address to grant burner role
   */
  function addBurner(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(BURNER_ROLE, newAddress);
  }

  /**
   * @notice Admins may revoke burners
   * @param oldAddress address of burner to revoke
   */
  function removeBurner(address oldAddress)
    external
  {
    revokeRole(BURNER_ROLE, oldAddress);
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
  }

  /**
   * @notice Freezers may 'freeze' users
   * @param newAddress address to freeze
   */
  function freezeUser(address newAddress) external onlyRole(FREEZER_ROLE) {
    grantRole(FROZEN_USER, newAddress);
  }

  /**
   * @notice Freezers may 'unfreeze' users
   * @param oldAddress address to unfreeze
   */
  function unfreezeUser(address oldAddress) external onlyRole(FREEZER_ROLE) {
    revokeRole(FROZEN_USER, oldAddress);
  }

  /**
   * @notice Admins may add new pausers
   * @param newAddress address to grant pauser role
   */
  function addPauser(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(PAUSER_ROLE, newAddress);
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
  }

  /**
   * @notice Minters may mint tokens to a whitelisted user while incurring fees
   * @param recipient the whitelisted user to mint to
   * @param amount how many tokens to mint
   */
  function feeBankMint(address recipient, uint256 amount, string calldata transferId)
    external
    onlyRole(MINTER_ROLE)
  {
    require(
      hasRole(WHITELIST_USER, recipient),
      "Recipient must be whitelisted."
    );
    require(amount % BASIS_RATE == 0, "Amount can't be more precise than 9 decimal places!");
    uint256 fee = (amount / BASIS_RATE) * variableRate;
    uint256 _amount = amount - fee;
    bytes32 bytesId = keccak256(abi.encodePacked(transferId));
    emit ReceivedMint(recipient, _amount, bytesId, transferId);
    emit MintFee(currentFeeCollector, fee);
    _mint(currentFeeCollector, fee);
    _mint(recipient, _amount);
  }

  /**
   * @notice Minters may mint tokens to a whitelisted user without incurring fees
   * @param recipient the whitelisted user to mint to
   * @param amount how many tokens to mint
   */
  function bankMint(address recipient, uint256 amount, string calldata transferId)
    external
    onlyRole(MINTER_ROLE)
  {
    require(
      hasRole(WHITELIST_USER, recipient),
      "Recipient must be whitelisted."
    );
    bytes32 bytesId = keccak256(abi.encodePacked(transferId));
    emit ReceivedMint(recipient, amount, bytesId, transferId);
    _mint(recipient, amount);
  }

  /**
   * @notice Burners may burn tokens from a pool while incurring fees
   * @param target the address to burn from
   * @param amount how many tokens to burn
   */
  function feeBankBurn(address target, uint256 amount)
    external
    onlyRole(BURNER_ROLE)
  {
    require(amount % BASIS_RATE == 0, "Amount can't be more precise than 9 decimal places!");
    uint256 fee = (amount / BASIS_RATE) * variableRate;
    _mint(currentFeeCollector, fee);
    _burn(target, amount);
  }

  /**
   * @notice Burners may burn tokens from a pool without incurring fees
   * @param target the address to burn from
   * @param amount how many tokens to burn
   */
  function bankBurn(address target, uint256 amount)
    external
    onlyRole(BURNER_ROLE)
  {
    _burn(target, amount);
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
   * @notice Pausers may pause the network
   */
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @notice Pausers may unpause the network
   */
  function unpause() external onlyRole(PAUSER_ROLE) {
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
