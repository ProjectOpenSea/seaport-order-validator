import { ethers } from "ethers";
import fs from "fs";
import path from "path";

import type {
  ErrorsAndWarningsStruct,
  OrderParametersStruct,
  OrderStruct,
  ValidationConfigurationStruct,
} from "../typechain-types/contracts/lib/SeaportValidator";
import type { BigNumber, BigNumberish, Contract } from "ethers";

const seaportValidatorArtifact = JSON.parse(
  fs.readFileSync(
    path.join(
      __dirname,
      "../../artifacts/contracts/lib/SeaportValidator.sol/SeaportValidator.json"
    ),
    "utf8"
  )
);

export const SEAPORT_VALIDATOR_ABI = seaportValidatorArtifact.abi;
export const SEAPORT_VALIDATOR_ADDRESS =
  "0xF75194740067D6E4000000003b350688DD770000";

export class SeaportOrderValidator {
  private seaportValidator: Contract;

  /**
   * Create a `SeaportOrderValidator` instance.
   * @param provider The ethers provider to use for the contract
   */
  public constructor(provider: ethers.providers.JsonRpcProvider) {
    if (!provider) {
      throw new Error("No provider provided");
    }

    this.seaportValidator = new ethers.Contract(
      SEAPORT_VALIDATOR_ADDRESS,
      SEAPORT_VALIDATOR_ABI,
      provider
    );
  }

  /**
   * Conduct a comprehensive validation of the given order.
   *    `isValidOrder` validates simple orders that adhere to a set of rules defined below:
   *    - The order is either a listing or an offer order (one NFT to buy or one NFT to sell).
   *    - The first consideration is the primary consideration.
   *    - The order pays up to two fees in the fungible token currency. First fee is primary fee, second is creator fee.
   *    - In private orders, the last consideration specifies a recipient for the offer item.
   *    - Offer items must be owned and properly approved by the offerer.
   *    - There must be one offer item
   *    - Consideration items must exist.
   *    - The signature must be valid, or the order must be already validated on chain
   * @param order The order to validate.
   * @return The errors and warnings found in the order.
   */
  public async isValidOrder(
    order: OrderStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.isValidOrder(order)
    );
  }

  /**
   * Same as `isValidOrder` but allows for more configuration related to fee validation.
   *    If `skipStrictValidation` is set order logic validation is not carried out: fees are not
   *    checked and there may be more than one offer item as well as any number of consideration items.
   */
  public async isValidOrderWithConfiguration(
    validationConfiguration: ValidationConfigurationStruct,
    order: OrderStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.isValidOrderWithConfiguration(
        validationConfiguration,
        order
      )
    );
  }

  /**
   * Checks if a conduit key is valid.
   * @param conduitKey The conduit key to check.
   * @return The errors and warnings
   */
  public async isValidConduit(
    conduitKey: string
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.isValidConduit(conduitKey)
    );
  }

  /**
   * Gets the approval address for the given conduit key
   * @param conduitKey Conduit key to get approval address for
   * @return The address to use for approvals
   * @return An ErrorsAndWarnings structs with results
   */
  public async getApprovalAddress(conduitKey: string): Promise<{
    approvalAddress: string;
    errorsAndWarnings: ErrorsAndWarningsStruct;
  }> {
    const res = await this.seaportValidator.getApprovalAddress(conduitKey);
    return {
      approvalAddress: res[0],
      errorsAndWarnings: processErrorsAndWarnings(res[1]),
    };
  }

  /**
   * Validates the signature for the order using the offerer's current counter
   * Will also check if order is validated on chain.
   */
  public async validateSignature(
    order: OrderStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return await processErrorsAndWarnings(
      this.seaportValidator.validateSignature(order)
    );
  }

  /**
   * Validates the signature for the order using the given counter
   * Will also check if order is validated on chain.
   */
  public async validateSignatureWithCounter(
    order: OrderStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateSignatureWithCounter(order)
    );
  }

  /**
   * Check the time validity of an order
   * @param orderParameters The parameters for the order to validate
   * @param shortOrderDuration The duration of which an order is considered short
   * @param distantOrderExpiration Distant order expiration delta in seconds.
   * @return The errors and warnings
   */
  public async validateTime(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateTime(orderParameters)
    );
  }

  /**
   * Validate the status of an order
   * @param orderParameters The parameters for the order to validate
   * @return errorsAndWarnings  The errors and warnings
   */
  public async validateOrderStatus(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateOrderStatus(orderParameters)
    );
  }

  /**
   * Validate all offer items for an order. Ensures that
   *    offerer has sufficient balance and approval for each item.
   * Amounts are not summed and verified, just the individual amounts.
   * @param orderParameters The parameters for the order to validate
   * @return errorsAndWarnings  The errors and warnings
   */
  public async validateOfferItems(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateOfferItems(orderParameters)
    );
  }

  /**
   * @notice Validates an offer item
   * @param orderParameters The parameters for the order to validate
   * @param offerItemIndex The index of the offerItem in offer array to validate
   * @return An ErrorsAndWarnings structs with results
   */
  public async validateOfferItem(
    orderParameters: OrderParametersStruct,
    offerItemIndex: number
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateOfferItem(
        orderParameters,
        offerItemIndex
      )
    );
  }

  /**
   * @notice Validates the OfferItem parameters. This includes token contract validation
   * @dev OfferItems with criteria are currently not allowed
   * @param orderParameters The parameters for the order to validate
   * @param offerItemIndex The index of the offerItem in offer array to validate
   * @return An ErrorsAndWarnings structs with results
   */
  public async validateOfferItemParameters(
    orderParameters: OrderParametersStruct,
    offerItemIndex: number
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateOfferItemParameters(
        orderParameters,
        offerItemIndex
      )
    );
  }

  /**
   * Validates the OfferItem approvals and balances
   * @param orderParameters The parameters for the order to validate
   * @param offerItemIndex The index of the offerItem in offer array to validate
   * @return errorsAndWarnings An ErrorsAndWarnings structs with results
   */
  public async validateOfferItemApprovalAndBalance(
    orderParameters: OrderParametersStruct,
    offerItemIndex: number
  ): Promise<ErrorsAndWarningsStruct> {
    return await processErrorsAndWarnings(
      this.seaportValidator.validateOfferItemApprovalAndBalance(
        orderParameters,
        offerItemIndex
      )
    );
  }

  /**
   * Validate all consideration items for an order
   * @param orderParameters The parameters for the order to validate
   * @return errorsAndWarnings  The errors and warnings
   */
  public async validateConsiderationItems(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateConsiderationItems(orderParameters)
    );
  }

  /**
   * Validate a consideration item
   * @param orderParameters The parameters for the order to validate
   * @param considerationItemIndex The index of the consideration item to validate
   * @return errorsAndWarnings  The errors and warnings
   */
  public async validateConsiderationItem(
    orderParameters: OrderParametersStruct,
    considerationItemIndex: number
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateConsiderationItem(
        orderParameters,
        considerationItemIndex
      )
    );
  }

  /**
   * Validates the parameters of a consideration item including contract validation
   * @param orderParameters The parameters for the order to validate
   * @param considerationItemIndex The index of the consideration item to validate
   * @return errorsAndWarnings  The errors and warnings
   */
  public async validateConsiderationItemParameters(
    orderParameters: OrderParametersStruct,
    considerationItemIndex: number
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateConsiderationItemParameters(
        orderParameters,
        considerationItemIndex
      )
    );
  }

  /**
   * Strict validation operates under tight assumptions. It validates primary
   *    fee, creator fee, private sale consideration, and overall order format.
   * Only checks first fee recipient provided by CreatorFeeEngine.
   *    Order of consideration items must be as follows:
   *    1. Primary consideration
   *    2. Primary fee
   *    3. Creator Fee
   *    4. Private sale consideration
   * @param orderParameters The parameters for the order to validate.
   * @param primaryFeeRecipient The primary fee recipient. Set to null address for no primary fee.
   * @param primaryFeeBips The primary fee in BIPs.
   * @param checkCreatorFee Should check for creator fee. If true, creator fee must be present as
   *    according to creator fee engine. If false, must not have creator fee.
   * @return errorsAndWarnings The errors and warnings.
   */
  public async validateStrictLogic(
    orderParameters: OrderParametersStruct,
    primaryFeeRecipient: string,
    primaryFeeBips: BigNumberish,
    checkCreatorFee: boolean
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateStrictLogic(
        orderParameters,
        primaryFeeRecipient,
        primaryFeeBips,
        checkCreatorFee
      )
    );
  }

  /**
   * Fetches the on chain creator fees.
   * Uses the creatorFeeEngine when available, otherwise fallback to `IERC2981`.
   * @param token The token address
   * @param tokenId The token identifier
   * @param transactionAmountStart The transaction start amount
   * @param transactionAmountEnd The transaction end amount
   * @return recipient creator fee recipient
   * @return creator fee start amount
   * @return creator fee end amount
   */
  public async getCreatorFeeInfo(
    token: string,
    tokenId: BigNumberish,
    transactionAmountStart: BigNumberish,
    transactionAmountEnd: BigNumberish
  ): Promise<{
    recipient: string;
    creatorFeeAmountStart: BigNumber;
    creatorFeeAmountEnd: BigNumber;
  }> {
    const res = await this.seaportValidator.getCreatorFeeInfo(
      token,
      tokenId,
      transactionAmountStart,
      transactionAmountEnd
    );

    return {
      recipient: res.recipient,
      creatorFeeAmountStart: res.creatorFeeAmountStart,
      creatorFeeAmountEnd: res.creatorFeeAmountEnd,
    };
  }

  /**
   * Validates the zone call for an order
   * @param {OrderParametersStruct} orderParameters The parameters for the order to validate
   * @return errorsAndWarnings An ErrorsAndWarnings structs with results
   */
  public async isValidZone(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.isValidZone(orderParameters)
    );
  }

  /**
   * Sorts an array of token ids by the keccak256 hash of the id. Required ordering of ids
   *    for other merkle operations.
   * @param {BigNumberish[]} includedTokens An array of included token ids.
   * @return The sorted `includedTokens` array.
   */
  public async sortMerkleTokens(
    includedTokens: BigNumberish[]
  ): Promise<BigNumber[]> {
    return await this.seaportValidator.sortMerkleTokens(includedTokens);
  }

  /**
   * Creates a merkle root for includedTokens.
   * @dev `includedTokens` must be sorting in strictly ascending order according to the keccak256 hash of the value.
   * @return The merkle root
   * @return Errors and warnings from the operation
   */
  public async getMerkleRoot(includedTokens: BigNumberish[]): Promise<{
    merkleRoot: string;
    errorsAndWarnings: ErrorsAndWarningsStruct;
  }> {
    const res = await this.seaportValidator.getMerkleRoot(includedTokens);
    return {
      merkleRoot: res.merkleRoot,
      errorsAndWarnings: processErrorsAndWarnings(res.errorsAndWarnings),
    };
  }

  /**
   * Creates a merkle proof for the the targetIndex contained in includedTokens.
   * `targetIndex` is referring to the index of an element in `includedTokens`.
   *    `includedTokens` must be sorting in ascending order according to the keccak256 hash of the value.
   *
   * @return merkleProof The merkle proof
   * @return errorsAndWarnings Errors and warnings from the operation
   */
  public async getMerkleProof(
    includedTokens: BigNumberish[],
    targetIndex: BigNumberish
  ): Promise<{
    merkleProof: string[];
    errorsAndWarnings: ErrorsAndWarningsStruct;
  }> {
    const res = await this.seaportValidator.getMerkleProof(
      includedTokens,
      targetIndex
    );
    return {
      merkleProof: res.merkleProof,
      errorsAndWarnings: processErrorsAndWarnings(res.errorsAndWarnings),
    };
  }

  /**
   * Verifies a merkle proof for the value to prove and given root and proof.
   * The `valueToProve` is hashed prior to executing the proof verification.
   * @param merkleRoot The root of the merkle tree
   * @param merkleProof The merkle proof
   * @param valueToProve The value to prove
   * @return whether proof is valid
   */
  public async verifyMerkleProof(
    merkleRoot: string,
    merkleProof: string[],
    valueToProve: BigNumberish
  ): Promise<boolean> {
    return await this.seaportValidator.verifyMerkleProof(
      merkleRoot,
      merkleProof,
      valueToProve
    );
  }
}

function processErrorsAndWarnings(rawReturn: any): ErrorsAndWarningsStruct {
  const errors = rawReturn.errors;
  const warnings = rawReturn.warnings;
  return { errors, warnings };
}
