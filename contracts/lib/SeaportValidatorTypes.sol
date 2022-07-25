// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ValidationConfiguration {
    address protocolFeeRecipient;
    uint256 protocolFeeBips;
}

enum ValidationError {
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
    FeesUncheckable
}

enum ValidationWarning {
    Time_DistantExpiration,
    Time_NotActive,
    Time_ShortOrder,
    Offer_MoreThanOneItem,
    Consideration_ZeroItems,
    Consideration_MoreThanFourItems,
    Offer_NativeItem,
    RoyaltyFee_Missing,
    RoyaltyFee_ItemType,
    RoyaltyFee_Token,
    RoyaltyFee_StartAmount,
    RoyaltyFee_EndAmount,
    RoyaltyFee_Recipient,
    FeesUncheckable
}
