// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ValidationConfiguration {
    address protocolFeeRecipient;
    uint256 protocolFeeBips;
    bool checkRoyaltyFee;
    bool skipStrictValidation;
}

enum TimeIssue {
    EndTimeBeforeStartTime,
    Expired,
    DistantExpiration,
    NotActive,
    ShortOrder
}

enum StatusIssue {
    Cancelled,
    FullyFilled
}

enum OfferIssue {
    ZeroItems,
    AmountZero,
    MoreThanOneItem,
    NativeItem
}

enum ConsiderationIssue {
    AmountZero,
    NullRecipient,
    ExtraItems,
    PrivateSaleToSelf,
    ZeroItems
}

enum ProtocolFeeIssue {
    Missing,
    ItemType,
    Token,
    StartAmount,
    EndAmount,
    Recipient
}

enum ERC721Issue {
    AmountNotOne,
    InvalidToken,
    IdentifierDNE,
    NotOwner,
    NotApproved
}

enum ERC1155Issue {
    InvalidToken,
    NotApproved,
    InsufficientBalance
}

enum ERC20Issue {
    IdentifierNonZero,
    InvalidToken,
    InsufficientAllowance,
    InsufficientBalance
}

enum NativeIssue {
    TokenAddress,
    IdentifierNonZero,
    InsufficientBalance
}

enum ZoneIssue {
    Zone_RejectedOrder
}

enum ConduitIssue {
    KeyInvalid
}

enum RoyaltyFeeIssue {
    Missing,
    ItemType,
    Token,
    StartAmount,
    EndAmount,
    Recipient
}

enum SignatureIssue {
    Invalid,
    LowCounter,
    HighCounter,
    OriginalConsiderationItems
}

enum GenericIssue {
    InvalidItemType,
    MerkleError,
    InvalidOrderFormat
}

library IssueParser {
    function parseInt(ERC20Issue err) internal pure returns (uint16) {
        return uint16(err) + 200;
    }

    function parseInt(ERC721Issue err) internal pure returns (uint16) {
        return uint16(err) + 300;
    }

    function parseInt(ERC1155Issue err) internal pure returns (uint16) {
        return uint16(err) + 400;
    }

    function parseInt(ConsiderationIssue err) internal pure returns (uint16) {
        return uint16(err) + 500;
    }

    function parseInt(OfferIssue err) internal pure returns (uint16) {
        return uint16(err) + 600;
    }

    function parseInt(ProtocolFeeIssue err) internal pure returns (uint16) {
        return uint16(err) + 700;
    }

    function parseInt(StatusIssue err) internal pure returns (uint16) {
        return uint16(err) + 800;
    }

    function parseInt(TimeIssue err) internal pure returns (uint16) {
        return uint16(err) + 900;
    }

    function parseInt(ConduitIssue err) internal pure returns (uint16) {
        return uint16(err) + 1000;
    }

    function parseInt(SignatureIssue err) internal pure returns (uint16) {
        return uint16(err) + 1100;
    }

    function parseInt(GenericIssue err) internal pure returns (uint16) {
        return uint16(err) + 1200;
    }

    function parseInt(RoyaltyFeeIssue err) internal pure returns (uint16) {
        return uint16(err) + 1300;
    }

    function parseInt(NativeIssue err) internal pure returns (uint16) {
        return uint16(err) + 1400;
    }

    function parseInt(ZoneIssue err) internal pure returns (uint16) {
        return uint16(err) + 1500;
    }
}
