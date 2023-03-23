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
 * @author mpbowes, dcoleman, mkdir, st4rgard3n
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

  // Role for fee less minting
  bytes32 public constant FREE_MINTER = keccak256("FREE_MINTER");

  // Role for fee less burning
  bytes32 public constant FREE_BURNER = keccak256("FREE_BURNER");

  // Basis Point values
  uint256 public constant BASIS_RATE = 1000000000;

  // Mint transaction cleared by transferId
  event ReceivedMint(address indexed receipient, uint256 indexed amount, bytes32 indexed transferId);

  // Minting fee
  event MintFee(address indexed feeCollector, uint256 indexed fee);

  // Burn transaction initiated by transferId
  event ReceivedBurn(address indexed recipient, uint256 indexed amount, bytes32 indexed actionId);

  // Burning fee
  event BurnFee(address indexed feeCollector, uint256 indexed fee);

  // variableRate is the
  uint256 public variableRate;

  // Address where fees are collected
  address public currentFeeCollector;

  // Flag for allowing mint without paying fees
  bool public freeMinting;

  // Flag for allowing burning without paying fees
  bool public freeBurning;

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
    freeMinting = true; // Free minting activated
    freeBurning = true; // Free burning activated
  }

  /**
   * @notice Modify basis point variable rate
   * @param newRate the new variable rate for calculating protocol fees
   */
  function updateVariableRate(uint256 newRate)
    external
    onlyRole(FEE_CONTROLLER)
  {
    // Variable fee must be adjusted in increments of 0.1%
    require(newRate % 1000000 == 0, "Variable rate must be in increments of 0.1%!");
    // Variable fee max
    require(newRate <= 100000000, "New Rate Too Large");
    // Variable fee min
    require(newRate >= 1000000, "New Rate Too Small");
    variableRate = newRate;
  }

  /**
  * @notice Admin function for disabling the use of free minting and burning
  */
  function setMintFeeStatus() external onlyRole(DEFAULT_ADMIN_ROLE) {
    freeMinting = !freeMinting;
  }

  /**
  * @notice Admin function for disabling the use of free minting and burning
  */
  function setBurnFeeStatus() external onlyRole(DEFAULT_ADMIN_ROLE) {
    freeBurning = !freeBurning;
  }

  /**
  * @notice Set address of fee collector
  * @param feeCollector the address which will collect protocol fees
  */
  function setFeeCollector(address feeCollector) external onlyRole(FEE_CONTROLLER) {
    currentFeeCollector = feeCollector;
  }

  /**
   * @notice Modified Revoke Role for security
   * @param role the target role to revoke
   * @param account the address with role to be revoked
   */
  function revokeRole(bytes32 role, address account) public override {
    if (role == DEFAULT_ADMIN_ROLE) {
      require(getRoleMemberCount(role) > 1, "Contract requires one admin");
    }
    super.revokeRole(role, account);
  }

  /**
   * @notice Override preventing frozen accounts and the last admin from renouncing
   * @param role the target role to revoke
   * @param account the address with role to be revoked
   */
  function renounceRole(bytes32 role, address account) public override {
    if (role == FROZEN_USER) {
      require(hasRole(FREEZER_ROLE, msg.sender), "Only role admin can revoke");
    }
    if (role == DEFAULT_ADMIN_ROLE) {
      require(getRoleMemberCount(role) > 1, "Contract requires one admin");
    }
    super.renounceRole(role, account);
  }

  /**
   * @notice Minters may mint tokens to a whitelisted user while incurring fees
   * @param recipient the whitelisted user to mint to
   * @param amount how many tokens to mint
   * @param transferId transfer ID for event logging
   */
  function feeBankMint(address recipient, uint256 amount, bytes32 transferId)
    external
    onlyRole(MINTER_ROLE)
  {
    require(
      hasRole(WHITELIST_USER, recipient),
      "Recipient must be whitelisted."
    );
    require(amount % BASIS_RATE == 0, "Amount can't be more precise than 9 decimal places!");
    uint256 fee = (amount / BASIS_RATE) * variableRate;
    uint256 adjustedAmount = amount - fee;
    emit ReceivedMint(recipient, adjustedAmount, transferId);
    emit MintFee(currentFeeCollector, fee);
    _mint(currentFeeCollector, fee);
    _mint(recipient, adjustedAmount);
  }

  /**
   * @notice Minters may mint tokens to a whitelisted user without incurring fees
   * @param recipient the whitelisted user to mint to
   * @param amount how many tokens to mint
   * @param transferId transfer ID for event logging
   */
  function bankMint(address recipient, uint256 amount, bytes32 transferId)
    external
    onlyRole(FREE_MINTER)
  {
    require(
      hasRole(WHITELIST_USER, recipient),
      "Recipient must be whitelisted."
    );
    require(freeMinting == true, "Free minting is prohibited!");
    emit ReceivedMint(recipient, amount, transferId);
    _mint(recipient, amount);
  }

  /**
   * @notice Burners may burn tokens from a pool while incurring fees
   * @param target the address to burn from
   * @param amount how many tokens to burn
   */
  function feeBankBurn(address target, uint256 amount, bytes32 actionId)
    external
    onlyRole(BURNER_ROLE)
  {
    require(amount % BASIS_RATE == 0, "Amount can't be more precise than 9 decimal places!");
    uint256 fee = (amount / BASIS_RATE) * variableRate;
    _mint(currentFeeCollector, fee);
    emit ReceivedBurn(target, amount, actionId);
    emit BurnFee(currentFeeCollector, fee);
    _burn(target, amount);
  }

  /**
   * @notice Burners may burn tokens from a pool without incurring fees
   * @param target the address to burn from
   * @param amount how many tokens to burn
   */
  function bankBurn(address target, uint256 amount, bytes32 actionId)
    external
    onlyRole(FREE_BURNER)
  {
    require(freeBurning == true, "Free burning is prohibited!");
    emit ReceivedBurn(target, amount, actionId);
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

  /**
   * @notice Override regular external burn
   */
  function burn(uint256 amount) public virtual override(ERC20BurnableUpgradeable) {
    revert();
  }

  /**
   * @notice Override regular external burnFrom
   */
  function burnFrom(address account, uint256 amount) public virtual override(ERC20BurnableUpgradeable) {
    revert();
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
