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

  public async isValidOrder(
    order: OrderStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.isValidOrder(order)
    );
  }

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

  public async isValidConduit(
    conduitKey: string
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.isValidConduit(conduitKey)
    );
  }

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

  public async validateSignature(
    order: OrderStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return await processErrorsAndWarnings(
      this.seaportValidator.validateSignature(order)
    );
  }

  public async validateSignatureWithCounter(
    order: OrderStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateSignatureWithCounter(order)
    );
  }

  public async validateTime(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateTime(orderParameters)
    );
  }

  public async validateOrderStatus(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateOrderStatus(orderParameters)
    );
  }

  public async validateOfferItems(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateOfferItems(orderParameters)
    );
  }

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

  public async validateConsiderationItems(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.validateConsiderationItems(orderParameters)
    );
  }

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

  public async isValidZone(
    orderParameters: OrderParametersStruct
  ): Promise<ErrorsAndWarningsStruct> {
    return processErrorsAndWarnings(
      await this.seaportValidator.isValidZone(orderParameters)
    );
  }

  public async checkInterface(
    token: string,
    interfaceHash: string
  ): Promise<boolean> {
    return await this.seaportValidator.checkInterface(token, interfaceHash);
  }

  public async isPaymentToken(itemType: number): Promise<boolean> {
    return await this.seaportValidator.isPaymentToken(itemType);
  }

  public async sortMerkleTokens(
    includedTokens: BigNumberish[]
  ): Promise<BigNumber[]> {
    return await this.seaportValidator.sortMerkleTokens(includedTokens);
  }

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
