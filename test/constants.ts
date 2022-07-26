import { BigNumber } from "ethers";

export const SEAPORT_CONTRACT_NAME = "Seaport";
export const SEAPORT_CONTRACT_VERSION = "1.1";
export const OPENSEA_CONDUIT_KEY =
  "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000";
export const OPENSEA_CONDUIT_ADDRESS =
  "0x1E0049783F008A0085193E00003D00cd54003c71";
export const EIP_712_ORDER_TYPE = {
  OrderComponents: [
    { name: "offerer", type: "address" },
    { name: "zone", type: "address" },
    { name: "offer", type: "OfferItem[]" },
    { name: "consideration", type: "ConsiderationItem[]" },
    { name: "orderType", type: "uint8" },
    { name: "startTime", type: "uint256" },
    { name: "endTime", type: "uint256" },
    { name: "zoneHash", type: "bytes32" },
    { name: "salt", type: "uint256" },
    { name: "conduitKey", type: "bytes32" },
    { name: "counter", type: "uint256" },
  ],
  OfferItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
  ],
  ConsiderationItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
    { name: "recipient", type: "address" },
  ],
};

export enum OrderType {
  FULL_OPEN = 0, // No partial fills, anyone can execute
  PARTIAL_OPEN = 1, // Partial fills supported, anyone can execute
  FULL_RESTRICTED = 2, // No partial fills, only offerer or zone can execute
  PARTIAL_RESTRICTED = 3, // Partial fills supported, only offerer or zone can execute
}

export enum ItemType {
  NATIVE = 0,
  ERC20 = 1,
  ERC721 = 2,
  ERC1155 = 3,
  ERC721_WITH_CRITERIA = 4,
  ERC1155_WITH_CRITERIA = 5,
}

export enum Side {
  OFFER = 0,
  CONSIDERATION = 1,
}

export type NftItemType =
  | ItemType.ERC721
  | ItemType.ERC1155
  | ItemType.ERC721_WITH_CRITERIA
  | ItemType.ERC1155_WITH_CRITERIA;

export enum BasicOrderRouteType {
  ETH_TO_ERC721,
  ETH_TO_ERC1155,
  ERC20_TO_ERC721,
  ERC20_TO_ERC1155,
  ERC721_TO_ERC20,
  ERC1155_TO_ERC20,
}

export const MAX_INT = BigNumber.from(
  "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
);
export const ONE_HUNDRED_PERCENT_BP = 10000;
export const NO_CONDUIT =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

// Supply here any known conduit keys as well as their conduits
export const KNOWN_CONDUIT_KEYS_TO_CONDUIT = {
  [OPENSEA_CONDUIT_KEY]: OPENSEA_CONDUIT_ADDRESS,
};

export const CROSS_CHAIN_SEAPORT_ADDRESS =
  "0x00000000006c3852cbEf3e08E8dF289169EdE581";

export const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";
export const EMPTY_BYTES32 =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

export enum ValidationError {
  InvalidSignature,
  EndTimeBeforeStartTime,
  OrderExpired,
  OrderCancelled,
  OrderFullyFilled,
  ZeroOfferItems,
  ProtocolFee_Missing,
  ProtocolFeeItemType,
  ProtocolFeeToken,
  ProtocolFeeStartAmount,
  ProtocolFeeEndAmount,
  ProtocolFeeRecipient,
  ConsiderationAmountZero,
  ERC721AmountNotOne,
  ERC721InvalidToken,
  ERC721IdentifierDNE,
  ERC1155InvalidToken,
  ERC20IdentifierNonZero,
  ERC20InvalidToken,
  NativeTokenAddress,
  NativeIdentifierNonZero,
  InvalidItemType,
  OfferAmountZero,
  ERC721NotOwner,
  ERC721NotApproved,
  ERC1155NotApproved,
  ERC1155InsufficientBalance,
  ERC20InsufficientAllowance,
  ERC20InsufficientBalance,
  NativeInsufficientBalance,
  ZoneRejectedOrder,
  ConduitKeyInvalid,
  MerkleProofError,
  FeesUncheckable,
}

export enum ValidationWarning {
  Time_DistantExpiration,
  Time_NotActive,
  Time_ShortOrder,
  Offer_MoreThanOneItem,
  Consideration_ZeroItems,
  Consideration_MoreThanThreeItems,
  Offer_NativeItem,
  RoyaltyFee_Missing,
  RoyaltyFee_ItemType,
  RoyaltyFee_Token,
  RoyaltyFee_StartAmount,
  RoyaltyFee_EndAmount,
  RoyaltyFee_Recipient,
  FeesUncheckable,
}
