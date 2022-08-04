// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ValidationConfiguration {
    address protocolFeeRecipient;
    uint256 protocolFeeBips;
    bool checkRoyaltyFee;
    bool skipStrictValidation;
}

enum TimeError {
    EndTimeBeforeStartTime,
    Expired
}

enum StatusError {
    Cancelled,
    FullyFilled
}

enum OfferError {
    Offer_ZeroItems,
    Offer_AmountZero
}

enum ConsiderationError {
    Consideration_AmountZero,
    Consideration_NullRecipient,
    Consideration_ExtraItems,
    Consideration_PrivateSaleToSelf
}

enum ProtocolFeeError {
    ProtocolFee_Missing,
    ProtocolFee_ItemType,
    ProtocolFee_Token,
    ProtocolFee_StartAmount,
    ProtocolFee_EndAmount,
    ProtocolFee_Recipient
}

enum ERC721Error {
    ERC721_AmountNotOne,
    ERC721_InvalidToken,
    ERC721_IdentifierDNE,
    ERC721_NotOwner,
    ERC721_NotApproved
}

enum ERC1155Error {
    ERC1155_InvalidToken,
    ERC1155_NotApproved,
    ERC1155_InsufficientBalance
}

enum ERC20Error {
    ERC20_IdentifierNonZero,
    ERC20_InvalidToken,
    ERC20_InsufficientAllowance,
    ERC20_InsufficientBalance
}

enum NativeError {
    Native_TokenAddress,
    Native_IdentifierNonZero,
    Native_InsufficientBalance
}

enum ZoneError {
    Zone_RejectedOrder
}

enum ConduitError {
    Conduit_KeyInvalid
}

enum RoyaltyFeeError {
    RoyaltyFee_Missing,
    RoyaltyFee_ItemType,
    RoyaltyFee_Token,
    RoyaltyFee_StartAmount,
    RoyaltyFee_EndAmount,
    RoyaltyFee_Recipient
}

enum SignatureError {
    Signature_Invalid,
    Signature_LowCounter
}

enum GenericError {
    InvalidItemType,
    MerkleError,
    InvalidOrderFormat
}

library ErrorParser {
    function parseInt(ERC20Error err) internal pure returns (uint16) {
        return uint16(err) + 200;
    }

    function parseInt(ERC721Error err) internal pure returns (uint16) {
        return uint16(err) + 300;
    }

    function parseInt(ERC1155Error err) internal pure returns (uint16) {
        return uint16(err) + 400;
    }

    function parseInt(ConsiderationError err) internal pure returns (uint16) {
        return uint16(err) + 500;
    }

    function parseInt(OfferError err) internal pure returns (uint16) {
        return uint16(err) + 600;
    }

    function parseInt(ProtocolFeeError err) internal pure returns (uint16) {
        return uint16(err) + 700;
    }

    function parseInt(StatusError err) internal pure returns (uint16) {
        return uint16(err) + 800;
    }

    function parseInt(TimeError err) internal pure returns (uint16) {
        return uint16(err) + 900;
    }

    function parseInt(ConduitError err) internal pure returns (uint16) {
        return uint16(err) + 1000;
    }

    function parseInt(SignatureError err) internal pure returns (uint16) {
        return uint16(err) + 1100;
    }

    function parseInt(GenericError err) internal pure returns (uint16) {
        return uint16(err) + 1200;
    }

    function parseInt(RoyaltyFeeError err) internal pure returns (uint16) {
        return uint16(err) + 1300;
    }

    function parseInt(NativeError err) internal pure returns (uint16) {
        return uint16(err) + 1400;
    }

    function parseInt(ZoneError err) internal pure returns (uint16) {
        return uint16(err) + 1500;
    }
}

enum ValidationWarning {
    Time_DistantExpiration,
    Time_NotActive,
    Time_ShortOrder,
    Offer_MoreThanOneItem,
    Offer_NativeItem,
    Consideration_ZeroItems,
    Signature_HighCounter,
    Signature_OriginalConsiderationItems
}
