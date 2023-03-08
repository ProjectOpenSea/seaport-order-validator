[![Test CI][ci-badge]][ci-link]
[![Code Coverage][coverage-badge]][coverage-link]

# Seaport Order Validator

This repo has been deprecated. An updated Seaport Validator contract has been deployed to [0x00000000be3af6882a06323fd3f400a9e6a0dc42](https://etherscan.io/address/0x00000000be3af6882a06323fd3f400a9e6a0dc42#code).

Seaport Order Validator provides a solidity contract which validates orders and order components via RPC static calls. Seaport Order Validator currently supports validation of orders (not advanced orders) and provides minimal validation for criteria based items. This is an ongoing effort. The Seaport Order Validator is deployed at the address `0xF75194740067D6E4000000003b350688DD770000`.

There are a variety of functions which conduct micro and macro validations on various components of the order. Each validation function returns two arrays of uint16s, the first is an array of errors, and the second is an array of warnings. For a quick lookup of issue codes, see the [issue table](contracts/README.md).

## Table of Contents

- [JS Package Usage](#js-package-usage)
- [Macro-Validation](#macro-validation)
- [Micro-Validation](#micro-validation)
  - [validateTime](#validatetime---validates-the-timing-of-the-order)
  - [validateOrderStatus](#validateorderstatus---validates-the-order-status-from-on-chain-data)
  - [validateOfferItems](#validateofferitems---validates-the-offer-item-parameters-and-balancesapproval)
  - [validateOfferItem](#validateofferitem---validates-the-parameters-and-balancesapprovals-for-one-offer-item)
  - [validateOfferItemParameters](#validateofferitemparameters---validates-the-parameters-for-one-offer-item)
  - [validateOfferItemApprovalAndBalance](#validateofferitemapprovalandbalance---validates-the-balancesapprovals-for-one-offer-item)
  - [validateConsiderationItems](#validateconsiderationitems---validate-the-parameters-of-the-consideration-items)
  - [validateConsiderationItemParameters](#validateconsiderationitemparameters---check-the-parameters-for-a-single-consideration-item)
  - [isValidZone](#isvalidzone---checks-if-the-zone-accepts-the-order)
  - [validateStrictLogic](#validatestrictlogic---validate-strict-order-logic)
  - [validateSignature](#validatesignature---validates-the-signature-using-current-counter)
  - [validateSignatureWithCounter](#validatesignaturewithcounter---validates-the-signature-using-the-given-counter)
  - [getApprovalAddress](#getapprovaladdress---gets-the-approval-address-for-a-conduit-key)
- [Merkle Validation](#merkle-validation)
  - [sortMerkleTokens](#sortmerkletokens)
  - [getMerkleRoot](#getmerkleroot)
  - [getMerkleProof](#getmerkleroot)

## JS Package Usage

- Add the package via `yarn add @opensea/seaport-order-validator` or `npm i @opensea/seaport-order-validator`
- Import the package to your JS/TS file via `import { SeaportOrderValidator } from "@opensea/seaport-order-validator"`
- Create an instance of `SeaportOrderValidator` `const validator = new SeaportOrderValidator(new ethers.providers.JsonRpcProvider(<RPC>));`
- All validation functions are exposed to the `SeaportOrderValidator` instance

## Macro-Validation

- There are two macro-validation function, `isValidOrder` and `isValidOrderWithConfiguration`. `isValidOrder` simply calls `isValidOrderWithConfiguration` with a default configuration as follows:
  ```solidity
  {
  	primaryFeeRecipient = address(0),
  	primaryFeeBips = 0,
  	checkCreatorFee = false,
  	skipStrictValidation = false,
  	shortOrderDuration = 30 minutes,
  	distantOrderExpiration = 26 weeks
  }
  ```
- `isValidOrderWithConfiguration`
  - Calls the following micro-validations and aggregates the results:
    - `validateTime` - Called with variables from configuration
    - `validateOrderStatus`
    - `validateOfferItems`
    - `validateConsiderationItems`
    - `isValidZone`
    - `validateStrictLogic` - if skipStrictValidation is false. Called with the parameters from the configuration
    - `validateSignature`

## Micro-Validation

- ##### `validateTime` - Validates the timing of the order
  - Errors:
    - End time must be after start time
    - Current time must be before or equal to end time
  - Warnings:
    - End time is in more than `distantOrderExpiration` (distant expiration)
    - Start time is greater than current time (order not active)
    - Order duration is less than `shortOrderDuration` (either endTime - startTime or endTime - currentTime)
- ##### `validateOrderStatus` - Validates the order status from on-chain data
  - Errors:
    - Order is cancelled
    - Order is fully filled
- ##### `validateOfferItems` - Validates the offer item parameters and balances/approval
  - Errors:
    - Zero Offer Items
  - Warnings:
    - More than one offer item
  Nested validation call to `validateOfferItem` for each `offerItem`
- ##### `validateOfferItem` - Validates the parameters and balances/approvals for one offer item
  - Nested validation call to `validateOfferItemParameters` and if there are no errors, a subsequent call to `validateOfferItemApprovalAndBalance`
- ##### `validateOfferItemParameters` - Validates the parameters for one offer item
  - Errors:
    - Either the startAmount or the endAmount must be non-zero
    - The contract must exist and abide by the interface required for the given `ItemType`.
    - Identifier must be 0 for fungible tokens
    - Token address must be null-address for native offer item
    - Amounts must be 1 for if the `ItemType` is an ERC721
  - Warnings:
    - Large steps for amount. This is due to the fact that as time passes, the change in amount will be relatively drastic at each step. Occurs if min amount is less than 1e15 and `minAmount ≠ maxAmount`.
    - High velocity for amount. This means that the price changes more than 5% per 30 min relative to the highest amount.
- ##### `validateOfferItemApprovalAndBalance` - Validates the balances/approvals for one offer item
  - Errors:
    - Must be the owner of non-fungible items
    - Must have sufficient balance of fungible items
    - Must have sufficient allowance to the given conduit (seaport if none given)
  - Warnings:
    - Native offer item (a native offer item can not be pulled from the user wallet for fulfillment)
  There is also a nested validation call to `getApprovalAddress` to get the associated conduit for checking approvals.
- ##### `validateConsiderationItems` - Validate the parameters of the consideration items
  - Warnings:
    - Zero consideration items
  For each consideration item, there is a nested validation call to `validateConsiderationItem` which is just a wrapper for `validateConsiderationItemParameters`
- ##### `validateConsiderationItemParameters` - Check the parameters for a single consideration item
  - Errors:
    - Either start amount or end amount must be non-zero
    - The recipient can not be the null address
    - ERC721 type must have amounts be one
    - ERC721 token with identifier must exist
    - All token contracts must exist and implement the required interfaces
    - Native consideration item contract must be zero
    - Identifier for fungible items must be 0
- ##### `isValidZone` - Checks if the zone accepts the order
  - Errors:
    - Zone Rejected Order
      - Note: Validation always passes if given zone is an EOA
      - Zone caller is msg.sender
- ##### `validateStrictLogic` - Validate strict order logic
  The first consideration item is called the “primary consideration” for this section.
  - Errors:
    - Force 1 offer item along with at least one consideration item
    - Either the offer item or the primary consideration item must be fungible—the other non-fungible.
      - This ensures an either an offer or listing typed order
    - If `primaryFeeRecipient` and `primaryFeeBips` are non-zero, the second consideration item must be set correctly to the primary fee consideration. This must be omitted if the primary fee would be zero.
    - If `checkCreatorFee` is set to true, the creator fee engine is checked for royalties on the non-fungible item. If the creator fee is non-zero, the creator fee consideration item must be the next consideration item in the sequence.
    - There may be one last consideration item which signifies a private sale. This consideration item must be exactly the same as the offer item and the recipient must not be the offerer (no private sale to self).
    - There may not be any additional consideration items.
- ##### `validateSignature` - Validates the signature using current counter
  Calls `validateSignatureWithCounter` using the offerers current counter
- ##### `validateSignatureWithCounter` - Validates the signature using the given counter
  - Errors:
    - Counter below current counter - signature will never be valid
    - Signature Invalid
  - Warnings:
    - Signature Counter High - The signature counter is more than 2 greater than the current counter for the signer.
    - When error is invalid, original consideration Items field in order does not match the total consideration items. This may be the cause of the invalid signature.
- ##### `getApprovalAddress` - Gets the approval address for a conduit key
  - Returns the approval address for the given conduit key. (seaport address if conduit key is 0)
  - Errors:
    - Conduit key invalid (not created). Returns zero address for the approval address.

### Merkle Validation

- ##### `sortMerkleTokens`
  To generate a merkle root for a criteria order, the included token ids must first be sorted by their keccak256 hash. This function sorts accordingly.
- ##### `getMerkleRoot`
  - Generates the merkle root from the given `includedTokens`
  - If `MerkleError` is given, elements are not sorted correctly, or there are too many elements.
- ##### `getMerkleProof`
  - Generate the merkle proof for an element within the `includedTokens` at index `targetIndex`.

---

[ci-badge]: https://github.com/ProjectOpenSea/seaport-order-validator/actions/workflows/test.yml/badge.svg
[ci-link]: https://github.com/ProjectOpenSea/seaport-order-validator/actions/workflows/test.yml
[coverage-badge]: https://coveralls.io/repos/github/ProjectOpenSea/seaport-order-validator/badge.svg?branch=main&t=UvcQpQ
[coverage-link]: https://coveralls.io/github/ProjectOpenSea/seaport-order-validator?branch=main
