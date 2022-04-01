# METL v3 Peer Review
## By: Carter Carlson

# Findings
## HIGH RISK
### 1. `bankMint()` and `feeBankMint()`, `bankBurn()` & `feeBankBurn()` access control
For minting or burning, the same exact access control is used with or without fees.  Meaning, why would an approved minter / burner ever pay fees when they could call the same function without fees?

**Suggestion**: Modify access control so that it requires more permission to mint/burn without fees, or remove the non-fee mint/burn functions entirely.

## MEDIUM RISK
### 2. Minter can pay less fees than expected
See [`exploit.js`](test/exploit.js) for test and `@AUDIT` tag within `feeBankBurn()` for suggestion.

### 3. Burner can pay less fees than expected
See [`exploit.js`](test/exploit.js) for test and `@AUDIT` tag within `feeBankBurn()` for suggestion.

### 4. Setting of `variableRate` to non-round number
Setting variableRate to a non-rounded number will lead to less fees paid to the protocol. Many mints/burns would end up charging less fees if the amount is not fully divisible by `variableRate`. If suggestions 2 and 3 are implemented, many mints/burns would revert.  See `@AUDIT` tag within `updateVariableRate()` for suggestion. 


## INFORMATIONAL
### Gas optimizations
* The modifier `onlyRole(DEFAULT_ADMIN_ROLE)` is not needed with any functions that call `grantRole()` or `revokeRole()` as those inherited functions [already check for admin role](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/3ec5746e4e50c6a3359dd685300d7cce90b4afb9/contracts/access/AccessControlUpgradeable.sol#L148).
*  Several public functions can be converted to external.  See `@AUDIT` tags.


#### Best Practices
*  As `_feeCollector` is a public variable, no leading underscore is needed.
* Add natspec coverage to fully describe all function parameters.  