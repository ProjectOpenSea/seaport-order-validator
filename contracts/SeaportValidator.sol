// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { ItemType } from "./lib/ConsiderationEnums.sol";
import {
    Order,
    OrderParameters,
    BasicOrderParameters,
    OfferItem,
    ConsiderationItem
} from "./lib/ConsiderationStructs.sol";
import { ConsiderationTypeHashes } from "./lib/ConsiderationTypeHashes.sol";
import {
    ConsiderationInterface
} from "./interfaces/ConsiderationInterface.sol";
import {
    ConduitControllerInterface
} from "./interfaces/ConduitControllerInterface.sol";
import { ZoneInterface } from "./interfaces/ZoneInterface.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {
    ErrorsAndWarnings,
    ErrorsAndWarningsLib
} from "./lib/ErrorsAndWarnings.sol";
import { SafeStaticCall } from "./lib/SafeStaticCall.sol";
import { Murky } from "./lib/Murky.sol";
import {
    RoyaltyEngineInterface
} from "./interfaces/RoyaltyEngineInterface.sol";
import {
    ValidationConfiguration,
    ValidationError,
    ValidationWarning
} from "./lib/SeaportValidatorTypes.sol";

/**
 * @title SeaportValidator
 * @notice SeaportValidator validates simple orders that adhere to a set of rules defined below:
 *    - The order is either a bid or an ask order (one NFT to buy or one NFT to sell).
 *    - The first consideration is the primary consideration.
 *    - The order pays up to two fees in the fungible token currency. First fee is protocol fee, second is royalty fee.
 *    - In private orders, the last consideration specifies a recipient for the offer item.
 *    - Offer items must be owned and properly approved by the offerer.
 *    - Consideration items must exist.
 */
contract SeaportValidator is ConsiderationTypeHashes {
    using ErrorsAndWarningsLib for ErrorsAndWarnings;
    using SafeStaticCall for address;

    ConsiderationInterface constant seaport =
        ConsiderationInterface(0x00000000006c3852cbEf3e08E8dF289169EdE581);
    ConduitControllerInterface constant conduitController =
        ConduitControllerInterface(0x00000000F9490004C11Cef243f5400493c00Ad63);
    RoyaltyEngineInterface constant royaltyEngine =
        RoyaltyEngineInterface(0x0385603ab55642cb4Dd5De3aE9e306809991804f);
    Murky immutable murky;

    constructor() {
        murky = new Murky(false);
    }

    /**
     * @notice Conduct a comprehensive validation of the given order.
     * @param order The order to validate.
     * @return errorsAndWarnings The errors and warnings found in the order.
     */
    function isValidOrder(Order calldata order)
        external
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        return
            isValidOrderWithConfiguration(
                order,
                ValidationConfiguration(address(0), 0, false)
            );
    }

    function isValidOrderWithConfiguration(
        Order memory order,
        ValidationConfiguration memory validationConfiguration
    ) public returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        errorsAndWarnings.concat(validateTime(order.parameters));
        errorsAndWarnings.concat(validateOfferItems(order.parameters));
        errorsAndWarnings.concat(validateConsiderationItems(order.parameters));
        errorsAndWarnings.concat(validateOrderStatus(order.parameters));
        errorsAndWarnings.concat(isValidZone(order.parameters));
        errorsAndWarnings.concat(
            validateStrictLogic(
                order.parameters,
                validationConfiguration.protocolFeeRecipient,
                validationConfiguration.protocolFeeBips,
                validationConfiguration.checkRoyaltyFee
            )
        );

        Order[] memory orders = new Order[](1);
        orders[0] = order;

        // Successful if sig valid or validated on chain
        if (!errorsAndWarnings.hasErrors()) {
            try seaport.validate(orders) {} catch {
                // Not validated on chain, and sig not currently valid
                errorsAndWarnings.addError(ValidationError.InvalidSignature);
            }
        }
    }

    function isValidConduit(bytes32 conduitKey)
        external
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        (, errorsAndWarnings) = getApprovalAddress(conduitKey);
    }

    /**
     * @notice Check the time validity of an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateTime(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        if (orderParameters.endTime <= orderParameters.startTime) {
            errorsAndWarnings.addError(
                ValidationError.Time_EndTimeBeforeStartTime
            );
            return errorsAndWarnings;
        }

        if (orderParameters.endTime < block.timestamp) {
            errorsAndWarnings.addError(ValidationError.Time_Expired);
            return errorsAndWarnings;
        } else if (orderParameters.endTime > block.timestamp + (30 weeks)) {
            errorsAndWarnings.addWarning(
                ValidationWarning.Time_DistantExpiration
            );
        }

        if (orderParameters.startTime > block.timestamp) {
            errorsAndWarnings.addWarning(ValidationWarning.Time_NotActive);
        }

        if (
            orderParameters.endTime -
                (
                    orderParameters.startTime > block.timestamp
                        ? orderParameters.startTime
                        : block.timestamp
                ) <
            30 minutes
        ) {
            errorsAndWarnings.addWarning(ValidationWarning.Time_ShortOrder);
        }
    }

    /**
     * @notice Validate the status of an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOrderStatus(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        uint256 currentOffererCounter = seaport.getCounter(
            orderParameters.offerer
        );
        bytes32 orderHash = _deriveOrderHash(
            orderParameters,
            currentOffererCounter
        );
        (, bool isCancelled, uint256 totalFilled, uint256 totalSize) = seaport
            .getOrderStatus(orderHash);
        // Order is cancelled
        if (isCancelled) {
            errorsAndWarnings.addError(ValidationError.Status_Cancelled);
        }

        if (totalSize > 0 && totalFilled == totalSize) {
            errorsAndWarnings.addError(ValidationError.Status_FullyFilled);
        }
    }

    /**
     * @notice Validate all offer items for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOfferItems(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        for (uint256 i = 0; i < orderParameters.offer.length; i++) {
            errorsAndWarnings.concat(validateOfferItem(orderParameters, i));
        }

        // You must have an offer item
        if (orderParameters.offer.length == 0) {
            errorsAndWarnings.addError(ValidationError.Offer_ZeroItems);
        }

        if (orderParameters.offer.length > 1) {
            errorsAndWarnings.addWarning(
                ValidationWarning.Offer_MoreThanOneItem
            );
        }
    }

    /**
     * @notice Validate all consideration items for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItems(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        if (orderParameters.consideration.length == 0) {
            errorsAndWarnings.addWarning(
                ValidationWarning.Consideration_ZeroItems
            );
            return errorsAndWarnings;
        }

        for (uint256 i = 0; i < orderParameters.consideration.length; i++) {
            errorsAndWarnings.concat(
                validateConsiderationItem(orderParameters, i)
            );
        }

        if (orderParameters.consideration.length > 3) {
            errorsAndWarnings.addWarning(
                ValidationWarning.Consideration_MoreThanThreeItems
            );
        }
    }

    /**
     * @notice Strict validation operates under tight assumptions. It validates protocol
     *    fee, royalty fee, private sale consideration, and overall order format.
     * @dev Only checks first fee recipient provided by RoyaltyRegistry.
     *    Order of consideration items must be as follows:
     *    1. Primary consideration
     *    2. Protocol fee
     *    3. Royalty Fee
     *    4. Private sale consideration
     * @param orderParameters The parameters for the order to validate.
     * @param protocolFeeRecipient The protocol fee recipient. Set to null address for no protocol fee.
     * @param protocolFeeBips The protocol fee in BIPs.
     * @param checkRoyaltyFee Should check for royalty fee. If true, royalty fee must be present as
     *    according to royalty engine. If false, must not have royalty fee.
     * @return errorsAndWarnings The errors and warnings.
     */
    function validateStrictLogic(
        OrderParameters memory orderParameters,
        address protocolFeeRecipient,
        uint256 protocolFeeBips,
        bool checkRoyaltyFee
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        {
            bool canCheckFee = true;
            if (
                orderParameters.offer.length != 1 ||
                orderParameters.consideration.length == 0
            ) {
                // Not bid or ask, can't check fees
                canCheckFee = false;
            } else if (
                isPaymentToken(orderParameters.offer[0].itemType) &&
                isPaymentToken(orderParameters.consideration[0].itemType)
            ) {
                // Not bid or ask, can't check fees
                canCheckFee = false;
            } else if (
                !isPaymentToken(orderParameters.offer[0].itemType) &&
                !isPaymentToken(orderParameters.consideration[0].itemType)
            ) {
                // Not bid or ask, can't check fees
                canCheckFee = false;
            }
            if (!canCheckFee) {
                errorsAndWarnings.addError(ValidationError.InvalidOrderFormat);
                return errorsAndWarnings;
            }
        }

        (
            uint256 tertiaryConsiderationIndex,
            ErrorsAndWarnings memory errorsAndWarningsLocal
        ) = validateSecondaryConsiderationItems(
                orderParameters,
                protocolFeeRecipient,
                protocolFeeBips,
                checkRoyaltyFee
            );

        errorsAndWarnings.concat(errorsAndWarningsLocal);

        if (tertiaryConsiderationIndex != 0) {
            errorsAndWarnings.concat(
                validateTertiaryConsiderationItems(
                    orderParameters,
                    tertiaryConsiderationIndex
                )
            );
        }
    }

    function validateSecondaryConsiderationItems(
        OrderParameters memory orderParameters,
        address protocolFeeRecipient,
        uint256 protocolFeeBips,
        bool checkRoyaltyFee
    )
        internal
        view
        returns (
            uint256 tertiaryConsiderationIndex,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        // Check protocol fee
        address assetAddress;
        uint256 assetIdentifier;
        uint256 transactionAmountStart;
        uint256 transactionAmountEnd;

        ConsiderationItem memory royaltyFeeConsideration;

        if (isPaymentToken(orderParameters.offer[0].itemType)) {
            // Offer is a bid
            royaltyFeeConsideration.itemType = orderParameters
                .offer[0]
                .itemType;
            royaltyFeeConsideration.token = orderParameters.offer[0].token;
            transactionAmountStart = orderParameters.offer[0].startAmount;
            transactionAmountEnd = orderParameters.offer[0].endAmount;

            assetAddress = orderParameters.consideration[0].token;
            assetIdentifier = orderParameters
                .consideration[0]
                .identifierOrCriteria;
        } else {
            // Assume order must be an ask
            royaltyFeeConsideration.itemType = orderParameters
                .consideration[0]
                .itemType;
            royaltyFeeConsideration.token = orderParameters
                .consideration[0]
                .token;
            transactionAmountStart = orderParameters
                .consideration[0]
                .startAmount;
            transactionAmountEnd = orderParameters.consideration[0].endAmount;

            assetAddress = orderParameters.offer[0].token;
            assetIdentifier = orderParameters.offer[0].identifierOrCriteria;
        }

        if (protocolFeeRecipient != address(0)) {
            if (orderParameters.consideration.length < 2) {
                errorsAndWarnings.addError(ValidationError.ProtocolFee_Missing);
                return (0, errorsAndWarnings);
            }

            ConsiderationItem memory protocolFeeItem = orderParameters
                .consideration[1];

            if (protocolFeeItem.itemType != royaltyFeeConsideration.itemType) {
                errorsAndWarnings.addError(
                    ValidationError.ProtocolFee_ItemType
                );
                return (0, errorsAndWarnings);
            }

            if (protocolFeeItem.token != royaltyFeeConsideration.token) {
                errorsAndWarnings.addError(ValidationError.ProtocolFee_Token);
            }
            if (
                protocolFeeItem.startAmount <
                (transactionAmountStart * protocolFeeBips) / 10000
            ) {
                errorsAndWarnings.addError(
                    ValidationError.ProtocolFee_StartAmount
                );
            }
            if (
                protocolFeeItem.endAmount <
                (transactionAmountEnd * protocolFeeBips) / 10000
            ) {
                errorsAndWarnings.addError(
                    ValidationError.ProtocolFee_EndAmount
                );
            }
            if (protocolFeeItem.recipient != protocolFeeRecipient) {
                errorsAndWarnings.addError(
                    ValidationError.ProtocolFee_Recipient
                );
            }
        }

        // Check royalty fee
        {
            (
                address payable[] memory royaltyRecipients,
                uint256[] memory royaltyAmountsStart
            ) = royaltyEngine.getRoyaltyView(
                    assetAddress,
                    assetIdentifier,
                    transactionAmountStart
                );
            if (royaltyRecipients.length != 0) {
                royaltyFeeConsideration.recipient = royaltyRecipients[0];
                royaltyFeeConsideration.startAmount = royaltyAmountsStart[0];

                (, uint256[] memory royaltyAmountsEnd) = royaltyEngine
                    .getRoyaltyView(
                        assetAddress,
                        assetIdentifier,
                        transactionAmountEnd
                    );
                royaltyFeeConsideration.endAmount = royaltyAmountsEnd[0];
            }
        }

        bool royaltyFeePresent = false;

        if (
            royaltyFeeConsideration.recipient != address(0) && checkRoyaltyFee
        ) {
            uint16 royaltyConsiderationIndex = protocolFeeBips != 0 ? 2 : 1; // 2 if protocol fee, ow 1

            // Check that royalty consideration item exists
            if (
                orderParameters.consideration.length - 1 <
                royaltyConsiderationIndex
            ) {
                errorsAndWarnings.addError(ValidationError.RoyaltyFee_Missing);
                return (0, errorsAndWarnings);
            }

            ConsiderationItem memory royaltyFeeItem = orderParameters
                .consideration[royaltyConsiderationIndex];
            royaltyFeePresent = true;

            if (royaltyFeeItem.itemType != royaltyFeeConsideration.itemType) {
                errorsAndWarnings.addError(ValidationError.RoyaltyFee_ItemType);
                return (0, errorsAndWarnings);
            }
            if (royaltyFeeItem.token != royaltyFeeConsideration.token) {
                errorsAndWarnings.addError(ValidationError.RoyaltyFee_Token);
            }
            if (
                royaltyFeeItem.startAmount < royaltyFeeConsideration.startAmount
            ) {
                errorsAndWarnings.addError(
                    ValidationError.RoyaltyFee_StartAmount
                );
            }
            if (royaltyFeeItem.endAmount < royaltyFeeConsideration.endAmount) {
                errorsAndWarnings.addError(
                    ValidationError.RoyaltyFee_EndAmount
                );
            }
            if (royaltyFeeItem.recipient != royaltyFeeConsideration.recipient) {
                errorsAndWarnings.addError(
                    ValidationError.RoyaltyFee_Recipient
                );
            }
        }

        // Check additional consideration items
        tertiaryConsiderationIndex =
            1 +
            (protocolFeeBips != 0 ? 1 : 0) +
            (royaltyFeePresent ? 1 : 0);
    }

    function validateTertiaryConsiderationItems(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) internal pure returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        if (orderParameters.consideration.length <= considerationItemIndex) {
            // Not a private sale
            return errorsAndWarnings;
        }

        ConsiderationItem memory privateSaleConsideration = orderParameters
            .consideration[considerationItemIndex];

        if (isPaymentToken(orderParameters.offer[0].itemType)) {
            errorsAndWarnings.addError(
                ValidationError.Consideration_ExtraItems
            );
            return errorsAndWarnings;
        }

        if (privateSaleConsideration.recipient == orderParameters.offerer) {
            errorsAndWarnings.addError(
                ValidationError.Consideration_PrivateSaleToSelf
            );
            return errorsAndWarnings;
        }

        if (
            privateSaleConsideration.itemType !=
            orderParameters.offer[0].itemType ||
            privateSaleConsideration.token != orderParameters.offer[0].token ||
            orderParameters.offer[0].startAmount !=
            privateSaleConsideration.startAmount ||
            orderParameters.offer[0].endAmount !=
            privateSaleConsideration.endAmount ||
            orderParameters.offer[0].identifierOrCriteria !=
            privateSaleConsideration.identifierOrCriteria
        ) {
            // Invalid private sale, say extra consideration item
            errorsAndWarnings.addError(
                ValidationError.Consideration_ExtraItems
            );
            return errorsAndWarnings;
        }

        if (orderParameters.consideration.length - 1 > considerationItemIndex) {
            // Extra consideration items
            errorsAndWarnings.addError(
                ValidationError.Consideration_ExtraItems
            );
            return errorsAndWarnings;
        }
    }

    /**
     * @notice Validate a consideration item
     * @param orderParameters The parameters for the order to validate
     * @param considerationItemIndex The index of the consideration item to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItem(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        errorsAndWarnings.concat(
            validateConsiderationItemParameters(
                orderParameters,
                considerationItemIndex
            )
        );
    }

    /**
     * @notice Validates the parameters of a consideration item including contract validation
     * @param orderParameters The parameters for the order to validate
     * @param considerationItemIndex The index of the consideration item to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItemParameters(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        ConsiderationItem memory considerationItem = orderParameters
            .consideration[considerationItemIndex];

        if (
            considerationItem.startAmount == 0 &&
            considerationItem.endAmount == 0
        ) {
            errorsAndWarnings.addError(
                ValidationError.Consideration_AmountZero
            );
        }

        if (considerationItem.recipient == address(0)) {
            errorsAndWarnings.addError(
                ValidationError.Consideration_NullRecipient
            );
        }

        if (considerationItem.itemType == ItemType.ERC721) {
            if (
                considerationItem.startAmount != 1 ||
                considerationItem.endAmount != 1
            ) {
                errorsAndWarnings.addError(ValidationError.ERC721_AmountNotOne);
            }

            if (
                !checkInterface(
                    considerationItem.token,
                    type(IERC721).interfaceId
                )
            ) {
                errorsAndWarnings.addError(ValidationError.ERC721_InvalidToken);
                return errorsAndWarnings;
            }

            // Ensure that token exists. Will return false if owned by null address.
            if (
                !considerationItem.token.safeStaticCallUint256(
                    abi.encodeWithSelector(
                        IERC721.ownerOf.selector,
                        considerationItem.identifierOrCriteria
                    ),
                    1
                )
            ) {
                errorsAndWarnings.addError(
                    ValidationError.ERC721_IdentifierDNE
                );
            }
        } else if (
            considerationItem.itemType == ItemType.ERC721_WITH_CRITERIA
        ) {
            if (
                !checkInterface(
                    considerationItem.token,
                    type(IERC721).interfaceId
                )
            ) {
                errorsAndWarnings.addError(ValidationError.ERC721_InvalidToken);
            }
        } else if (
            considerationItem.itemType == ItemType.ERC1155 ||
            considerationItem.itemType == ItemType.ERC1155_WITH_CRITERIA
        ) {
            if (
                !checkInterface(
                    considerationItem.token,
                    type(IERC1155).interfaceId
                )
            ) {
                errorsAndWarnings.addError(
                    ValidationError.ERC1155_InvalidToken
                );
            }
        } else if (considerationItem.itemType == ItemType.ERC20) {
            if (considerationItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    ValidationError.ERC20_IdentifierNonZero
                );
            }

            if (
                !considerationItem.token.safeStaticCallUint256(
                    abi.encodeWithSelector(
                        IERC20.allowance.selector,
                        address(seaport),
                        address(seaport)
                    ),
                    0
                )
            ) {
                // Not an ERC20 token
                errorsAndWarnings.addError(ValidationError.ERC20_InvalidToken);
            }
        } else if (considerationItem.itemType == ItemType.NATIVE) {
            if (considerationItem.token != address(0)) {
                errorsAndWarnings.addError(ValidationError.Native_TokenAddress);
            }
            if (considerationItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    ValidationError.Native_IdentifierNonZero
                );
            }
        } else {
            errorsAndWarnings.addError(ValidationError.InvalidItemType);
        }
    }

    /**
     * @notice Validates an offer item
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItem(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = validateOfferItemParameters(
            orderParameters,
            offerItemIndex
        );
        if (errorsAndWarnings.hasErrors()) {
            // Only validate approvals and balances if parameters are valid
            return errorsAndWarnings;
        }

        errorsAndWarnings.concat(
            validateOfferItemApprovalAndBalance(orderParameters, offerItemIndex)
        );
    }

    /**
     * @notice Validates the OfferItem parameters. This includes token contract validation
     * @dev OfferItems with criteria are currently not allowed
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItemParameters(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        OfferItem memory offerItem = orderParameters.offer[offerItemIndex];

        if (offerItem.startAmount == 0 && offerItem.endAmount == 0) {
            errorsAndWarnings.addError(ValidationError.Offer_AmountZero);
        }

        if (offerItem.itemType == ItemType.ERC721) {
            if (offerItem.startAmount != 1 || offerItem.endAmount != 1) {
                errorsAndWarnings.addError(ValidationError.ERC721_AmountNotOne);
            }

            if (!checkInterface(offerItem.token, type(IERC721).interfaceId)) {
                errorsAndWarnings.addError(ValidationError.ERC721_InvalidToken);
            }
        } else if (offerItem.itemType == ItemType.ERC1155) {
            if (!checkInterface(offerItem.token, type(IERC1155).interfaceId)) {
                errorsAndWarnings.addError(
                    ValidationError.ERC1155_InvalidToken
                );
            }
        } else if (offerItem.itemType == ItemType.ERC20) {
            if (offerItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    ValidationError.ERC20_IdentifierNonZero
                );
            }

            // validate contract
            (, bytes memory res) = offerItem.token.staticcall(
                abi.encodeWithSelector(
                    IERC20.allowance.selector,
                    address(seaport),
                    address(seaport)
                )
            );
            if (res.length == 0) {
                // Not an ERC20 token
                errorsAndWarnings.addError(ValidationError.ERC20_InvalidToken);
            }
        } else if (offerItem.itemType == ItemType.NATIVE) {
            if (offerItem.token != address(0)) {
                errorsAndWarnings.addError(ValidationError.Native_TokenAddress);
            }

            if (offerItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    ValidationError.Native_IdentifierNonZero
                );
            }
        } else {
            errorsAndWarnings.addError(ValidationError.InvalidItemType);
        }
    }

    /**
     * @notice Validates the OfferItem approvals and balances
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItemApprovalAndBalance(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        // Note: If multiple items are of the same token, token amounts are not summed for validation

        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        (
            address approvalAddress,
            ErrorsAndWarnings memory ew
        ) = getApprovalAddress(orderParameters.conduitKey);

        errorsAndWarnings.concat(ew);

        OfferItem memory offerItem = orderParameters.offer[offerItemIndex];

        if (offerItem.itemType == ItemType.ERC721) {
            // TODO: Deal with ERC721 with criteria
            IERC721 token = IERC721(offerItem.token);

            // Check owner
            if (
                !address(token).safeStaticCallAddress(
                    abi.encodeWithSelector(
                        IERC721.ownerOf.selector,
                        offerItem.identifierOrCriteria
                    ),
                    orderParameters.offerer
                )
            ) {
                errorsAndWarnings.addError(ValidationError.ERC721_NotOwner);
            }

            // Check approval
            if (
                !address(token).safeStaticCallAddress(
                    abi.encodeWithSelector(
                        IERC721.getApproved.selector,
                        offerItem.identifierOrCriteria
                    ),
                    approvalAddress
                )
            ) {
                if (
                    !address(token).safeStaticCallBool(
                        abi.encodeWithSelector(
                            IERC721.isApprovedForAll.selector,
                            orderParameters.offerer,
                            approvalAddress
                        ),
                        true
                    )
                ) {
                    errorsAndWarnings.addError(
                        ValidationError.ERC721_NotApproved
                    );
                }
            }
        } else if (offerItem.itemType == ItemType.ERC1155) {
            IERC1155 token = IERC1155(offerItem.token);

            if (
                !address(token).safeStaticCallBool(
                    abi.encodeWithSelector(
                        IERC721.isApprovedForAll.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    true
                )
            ) {
                errorsAndWarnings.addError(ValidationError.ERC1155_NotApproved);
            }

            uint256 minBalance = offerItem.startAmount < offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        IERC1155.balanceOf.selector,
                        orderParameters.offerer,
                        offerItem.identifierOrCriteria
                    ),
                    minBalance
                )
            ) {
                errorsAndWarnings.addError(
                    ValidationError.ERC1155_InsufficientBalance
                );
            }
        } else if (offerItem.itemType == ItemType.ERC20) {
            IERC20 token = IERC20(offerItem.token);

            uint256 minBalanceAndAllowance = offerItem.startAmount <
                offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        IERC20.allowance.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    minBalanceAndAllowance
                )
            ) {
                errorsAndWarnings.addError(
                    ValidationError.ERC20_InsufficientAllowance
                );
            }

            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        IERC20.balanceOf.selector,
                        orderParameters.offerer
                    ),
                    minBalanceAndAllowance
                )
            ) {
                errorsAndWarnings.addError(
                    ValidationError.ERC20_InsufficientBalance
                );
            }
        } else if (offerItem.itemType == ItemType.NATIVE) {
            uint256 minBalance = offerItem.startAmount < offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            if (orderParameters.offerer.balance < minBalance) {
                errorsAndWarnings.addError(
                    ValidationError.Native_InsufficientBalance
                );
            }

            errorsAndWarnings.addWarning(ValidationWarning.Offer_NativeItem);
        } else {
            errorsAndWarnings.addError(ValidationError.InvalidItemType);
        }
    }

    // TODO: Need to add support for order with extra data
    /**
     * @notice Validates the zone call for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function isValidZone(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        if (address(orderParameters.zone).code.length == 0) {
            // Address is EOA. Valid order
            return errorsAndWarnings;
        }

        uint256 currentOffererCounter = seaport.getCounter(
            orderParameters.offerer
        );

        if (
            !orderParameters.zone.safeStaticCallBytes4(
                abi.encodeWithSelector(
                    ZoneInterface.isValidOrder.selector,
                    _deriveOrderHash(orderParameters, currentOffererCounter),
                    msg.sender, /* who should be caller? */
                    orderParameters.offerer,
                    orderParameters.zoneHash
                ),
                ZoneInterface.isValidOrder.selector
            )
        ) {
            errorsAndWarnings.addError(ValidationError.Zone_RejectedOrder);
        }
    }

    /**
     * @notice Gets the approval address for the given conduit key
     * @param conduitKey Conduit key to get approval address for
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function getApprovalAddress(bytes32 conduitKey)
        public
        view
        returns (address, ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));
        if (conduitKey == 0) return (address(seaport), errorsAndWarnings);
        (address conduitAddress, bool exists) = conduitController.getConduit(
            conduitKey
        );
        if (!exists) {
            errorsAndWarnings.addError(ValidationError.Conduit_KeyInvalid);
            conduitAddress = address(0); // Don't return invalid conduit
        }
        return (conduitAddress, errorsAndWarnings);
    }

    /**
     * @notice Safely check that a contract implements an interface
     * @param token The token address to check
     * @param interfaceHash The interface hash to check
     */
    function checkInterface(address token, bytes4 interfaceHash)
        public
        view
        returns (bool)
    {
        return
            token.safeStaticCallBool(
                abi.encodeWithSelector(
                    IERC165.supportsInterface.selector,
                    interfaceHash
                ),
                true
            );
    }

    function isPaymentToken(ItemType itemType) public pure returns (bool) {
        return itemType == ItemType.NATIVE || itemType == ItemType.ERC20;
    }

    /*//////////////////////////////////////////////////////////////
                        Merkle Helpers
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a merkle proof for the the targetIndex contained in includedTokens.
     * @dev `targetIndex` is referring to the index of an element in `includedTokens`.
     *    `includedTokens` must be sorting in ascending order according to the keccak256 hash of the value.
     * @return merkleProof The merkle proof
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleProof(
        uint256[] memory includedTokens,
        uint256 targetIndex
    )
        public
        view
        returns (
            bytes32[] memory merkleProof,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        (bool success, bytes memory res) = address(murky).staticcall(
            abi.encodeWithSelector(
                murky.getProof.selector,
                includedTokens,
                targetIndex
            )
        );
        if (!success) {
            errorsAndWarnings.addError(ValidationError.MerkleError);
            return (new bytes32[](0), errorsAndWarnings);
        }

        return (abi.decode(res, (bytes32[])), errorsAndWarnings);
    }

    /**
     * @notice Creates a merkle root for includedTokens.
     * @dev `includedTokens` must be sorting in ascending order according to the keccak256 hash of the value.
     * @return merkleRoot The merkle root
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleRoot(uint256[] memory includedTokens)
        public
        view
        returns (bytes32 merkleRoot, ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint8[](0), new uint8[](0));

        (bool success, bytes memory res) = address(murky).staticcall(
            abi.encodeWithSelector(murky.getRoot.selector, includedTokens)
        );
        if (!success) {
            errorsAndWarnings.addError(ValidationError.MerkleError);
            return (0, errorsAndWarnings);
        }

        return (abi.decode(res, (bytes32)), errorsAndWarnings);
    }
}
