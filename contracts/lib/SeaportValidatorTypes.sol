// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ValidationConfiguration {
    address protocolFeeRecipient;
    uint256 protocolFeeBips;
    bool checkRoyaltyFee;
}

enum ValidationError {
    Time_EndTimeBeforeStartTime,
    Time_Expired,
    Status_Cancelled,
    Status_FullyFilled,
    Offer_ZeroItems,
    Offer_AmountZero,
    Consideration_AmountZero,
    Consideration_NullRecipient,
    Consideration_ExtraItems,
    Consideration_PrivateSaleToSelf,
    ProtocolFee_Missing,
    ProtocolFee_ItemType,
    ProtocolFee_Token,
    ProtocolFee_StartAmount,
    ProtocolFee_EndAmount,
    ProtocolFee_Recipient,
    ERC721_AmountNotOne,
    ERC721_InvalidToken,
    ERC721_IdentifierDNE,
    ERC721_NotOwner,
    ERC721_NotApproved,
    ERC1155_InvalidToken,
    ERC1155_NotApproved,
    ERC1155_InsufficientBalance,
    ERC20_IdentifierNonZero,
    ERC20_InvalidToken,
    ERC20_InsufficientAllowance,
    ERC20_InsufficientBalance,
    Native_TokenAddress,
    Native_IdentifierNonZero,
    Native_InsufficientBalance,
    Zone_RejectedOrder,
    Conduit_KeyInvalid,
    InvalidItemType,
    MerkleError,
    InvalidOrderFormat,
    InvalidSignature,
    RoyaltyFee_Missing,
    RoyaltyFee_ItemType,
    RoyaltyFee_Token,
    RoyaltyFee_StartAmount,
    RoyaltyFee_EndAmount,
    RoyaltyFee_Recipient
}

enum ValidationWarning {
    Time_DistantExpiration,
    Time_NotActive,
    Time_ShortOrder,
    Offer_MoreThanOneItem,
    Offer_NativeItem,
    Consideration_ZeroItems
}
