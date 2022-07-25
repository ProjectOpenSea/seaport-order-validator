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
    ProtocolFeeItemType,
    ProtocolFeeToken,
    ProtocolFeeStartAmount,
    ProtocolFeeEndAmount,
    ProtocolFeeRecipient,
    ConsiderationAmountZero,
    ERC721AmountNonZero,
    ERC721AmountNotOne,
    ERC721InvalidToken,
    ERC721TokenDNE,
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
    NativeOfferItem,
    ZoneRejectedOrder,
    ConduitKeyInvalid,
    MerkleProofError
}
