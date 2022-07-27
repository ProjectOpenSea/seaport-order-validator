// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ValidationConfiguration {
    address ProtocolFee_Recipient;
    uint256 protocolFeeBips;
}

enum ValidationError {
    InvalidSignature,
    EndTimeBeforeStartTime,
    OrderExpired,
    OrderCancelled,
    OrderFullyFilled,
    Offer_ZeroItems,
    ProtocolFee_Missing,
    ProtocolFee_ItemType,
    ProtocolFee_Token,
    ProtocolFee_StartAmount,
    ProtocolFee_EndAmount,
    ProtocolFee_Recipient,
    ConsiderationAmountZero,
    ERC721_AmountNotOne,
    ERC721_InvalidToken,
    ERC721_IdentifierDNE,
    ERC1155_InvalidToken,
    ERC20_IdentifierNonZero,
    ERC20_InvalidToken,
    Native_TokenAddress,
    Native_IdentifierNonZero,
    InvalidItemType,
    OfferAmountZero,
    ERC721_NotOwner,
    ERC721_NotApproved,
    ERC1155_NotApproved,
    ERC1155_InsufficientBalance,
    ERC20_InsufficientAllowance,
    ERC20_InsufficientBalance,
    Native_InsufficientBalance,
    Zone_RejectedOrder,
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
    Consideration_MoreThanThreeItems,
    Offer_NativeItem,
    RoyaltyFee_Missing,
    RoyaltyFee_ItemType,
    RoyaltyFee_Token,
    RoyaltyFee_StartAmount,
    RoyaltyFee_EndAmount,
    RoyaltyFee_Recipient,
    FeesUncheckable
}
