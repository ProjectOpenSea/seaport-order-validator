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
import { StringMemoryArray } from "./lib/StringMemoryArrayLib.sol";
import {
    ErrorsAndWarnings,
    ErrorsAndWarningsLib
} from "./lib/ErrorsAndWarnings.sol";
import "hardhat/console.sol";

contract SeaportVerifier is ConsiderationTypeHashes {
    using ErrorsAndWarningsLib for ErrorsAndWarnings;
    using StringMemoryArray for string[];

    ConsiderationInterface constant seaport =
        ConsiderationInterface(0x00000000006c3852cbEf3e08E8dF289169EdE581);
    ConduitControllerInterface constant conduitController =
        ConduitControllerInterface(0x00000000F9490004C11Cef243f5400493c00Ad63);

    function isValidOrder(Order calldata order)
        external
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        errorsAndWarnings.concat(validateTime(order.parameters));
        errorsAndWarnings.concat(validateOfferItems(order.parameters));
        errorsAndWarnings.concat(validateConsiderationItems(order.parameters));
        errorsAndWarnings.concat(validateOrderStatus(order.parameters));
        errorsAndWarnings.concat(isValidZone(order.parameters));

        Order[] memory orders = new Order[](1);
        orders[0] = order;

        // Sucessfull if sig valid or validated on chain
        try seaport.validate(orders) {} catch {
            // Not validated on chain, and sig not currently valid
            errorsAndWarnings.addError("invalid signature");
        }
    }

    function isValidConduit(bytes32 conduitKey) external view {
        getApprovalAddress(conduitKey);
    }

    function validateTime(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));
        if (orderParameters.endTime < block.timestamp) {
            errorsAndWarnings.errors = errorsAndWarnings.errors.pushMemory(
                "Order expired"
            );
        }

        // TODO: check if order is not yet started
    }

    function validateOrderStatus(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

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
            errorsAndWarnings.errors = errorsAndWarnings.errors.pushMemory(
                "Order cancelled"
            );
        }

        if (totalSize > 0 && totalFilled == totalSize) {
            errorsAndWarnings.errors = errorsAndWarnings.errors.pushMemory(
                "Order is fully filled"
            );
        }
    }

    function validateOfferItems(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        for (uint256 i = 0; i < orderParameters.offer.length; i++) {
            errorsAndWarnings.concat(validateOfferItem(orderParameters, i));
        }

        // You must have an offer item
        if (orderParameters.offer.length == 0) {
            errorsAndWarnings.errors = errorsAndWarnings.errors.pushMemory(
                "Need at least one offer item"
            );
        }
    }

    function validateConsiderationItems(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        for (uint256 i = 0; i < orderParameters.consideration.length; i++) {
            errorsAndWarnings.concat(
                validateConsiderationItem(orderParameters, i)
            );
        }
    }

    function validateConsiderationItem(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        errorsAndWarnings.concat(
            validateConsiderationItemParameters(
                orderParameters,
                considerationItemIndex
            )
        );
    }

    function validateConsiderationItemParameters(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        ConsiderationItem memory considerationItem = orderParameters
            .consideration[considerationItemIndex];

        if (
            considerationItem.startAmount == 0 &&
            considerationItem.endAmount == 0
        ) {
            errorsAndWarnings.addError("Consideration amount must not be 0");
        }

        if (considerationItem.itemType == ItemType.ERC721) {
            if (
                considerationItem.startAmount != 1 ||
                considerationItem.endAmount != 1
            ) {
                errorsAndWarnings.addError("ERC721 token amount must be 1");
            }

            if (
                !checkInterface(
                    considerationItem.token,
                    type(IERC721).interfaceId
                )
            ) {
                errorsAndWarnings.addError("Invalid ERC721 token");
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
                errorsAndWarnings.addError("Invalid ERC721 token");
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
                errorsAndWarnings.addError("Invalid ERC1155 token");
            }
        } else if (considerationItem.itemType == ItemType.ERC20) {
            if (considerationItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError("ERC20 can not have identifier");
            }

            // validate contract
            (bool success, bytes memory res) = considerationItem
                .token
                .staticcall(
                    abi.encodeWithSelector(
                        IERC20.allowance.selector,
                        address(seaport),
                        address(seaport)
                    )
                );
            if (!success || res.length == 0) {
                // Not an ERC20 token
                errorsAndWarnings.addError("Invalid ERC20 token");
            }
        } else if (considerationItem.itemType == ItemType.NATIVE) {
            if (considerationItem.token != address(0)) {
                errorsAndWarnings.addError(
                    "Native token address must be null address"
                );
            }
            if (considerationItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    "Native token can not have identifier"
                );
            }
        } else {
            errorsAndWarnings.addError("Invalid item type");
        }
    }

    function validateOfferItem(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        errorsAndWarnings.concat(
            validateOfferItemParameters(orderParameters, offerItemIndex)
        );

        errorsAndWarnings.concat(
            validateOfferItemApprovalAndBalance(orderParameters, offerItemIndex)
        );
    }

    function validateOfferItemParameters(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        OfferItem memory offerItem = orderParameters.offer[offerItemIndex];

        if (offerItem.startAmount == 0 && offerItem.endAmount == 0) {
            errorsAndWarnings.addError("Offer amount must not be 0");
        }

        if (offerItem.itemType == ItemType.ERC721) {
            if (offerItem.startAmount != 1 || offerItem.endAmount != 1) {
                errorsAndWarnings.addError("ERC721 token amount must be 1");
            }

            if (!checkInterface(offerItem.token, type(IERC721).interfaceId)) {
                errorsAndWarnings.addError("Invalid ERC721 token");
            }
        } else if (offerItem.itemType == ItemType.ERC721_WITH_CRITERIA) {
            if (!checkInterface(offerItem.token, type(IERC721).interfaceId)) {
                errorsAndWarnings.addError("Invalid ERC721 token");
            }
        } else if (
            offerItem.itemType == ItemType.ERC1155 ||
            offerItem.itemType == ItemType.ERC1155_WITH_CRITERIA
        ) {
            if (!checkInterface(offerItem.token, type(IERC1155).interfaceId)) {
                errorsAndWarnings.addError("Invalid ERC1155 token");
            }
        } else if (offerItem.itemType == ItemType.ERC20) {
            if (offerItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError("ERC20 can not have identifier");
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
                errorsAndWarnings.addError("Invalid ERC20 token");
            }
        } else if (offerItem.itemType == ItemType.NATIVE) {
            if (offerItem.token != address(0)) {
                errorsAndWarnings.addError(
                    "Native token address must be null address"
                );
            }

            if (offerItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    "Native token can not have identifier"
                );
            }
        } else {
            errorsAndWarnings.addError("Invalid item type");
        }
    }

    // Won't work as expected if contracts are not as stated
    function validateOfferItemApprovalAndBalance(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        address approvalAddress = getApprovalAddress(
            orderParameters.conduitKey
        );
        OfferItem memory offerItem = orderParameters.offer[offerItemIndex];

        if (offerItem.itemType == ItemType.ERC721) {
            // TODO: Deal with ERC721 with criteria
            IERC721 token = IERC721(offerItem.token);

            // Check owner
            if (
                !safeStaticCallAddress(
                    address(token),
                    abi.encodeWithSelector(
                        IERC721.ownerOf.selector,
                        offerItem.identifierOrCriteria
                    ),
                    orderParameters.offerer
                )
            ) {
                errorsAndWarnings.addError("not owner of token");
            }

            // Check approval
            if (
                !safeStaticCallAddress(
                    address(token),
                    abi.encodeWithSelector(
                        IERC721.getApproved.selector,
                        offerItem.identifierOrCriteria
                    ),
                    approvalAddress
                )
            ) {
                if (
                    !safeStaticCallBool(
                        address(token),
                        abi.encodeWithSelector(
                            IERC721.isApprovedForAll.selector,
                            orderParameters.offerer,
                            approvalAddress
                        ),
                        true
                    )
                ) {
                    errorsAndWarnings.addError("no token approval");
                }
            }
        } else if (
            offerItem.itemType == ItemType.ERC1155 ||
            offerItem.itemType == ItemType.ERC1155_WITH_CRITERIA
        ) {
            IERC1155 token = IERC1155(offerItem.token);

            if (
                !safeStaticCallBool(
                    address(token),
                    abi.encodeWithSelector(
                        IERC721.isApprovedForAll.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    true
                )
            ) {
                errorsAndWarnings.addError("no token approval");
            }

            uint256 tokenBalance = token.balanceOf(
                orderParameters.offerer,
                offerItem.identifierOrCriteria
            );

            if (
                tokenBalance < offerItem.startAmount ||
                tokenBalance < offerItem.endAmount
            ) {
                errorsAndWarnings.addError("insufficient token balance");
            }
        } else if (offerItem.itemType == ItemType.ERC20) {
            IERC20 token = IERC20(offerItem.token);

            uint256 tokenAllowance = token.allowance(
                orderParameters.offerer,
                approvalAddress
            );
            if (
                tokenAllowance < offerItem.startAmount ||
                tokenAllowance < offerItem.endAmount
            ) {
                errorsAndWarnings.addError("insufficient token allowance");
            }

            uint256 tokenBalance = token.balanceOf(orderParameters.offerer);
            if (
                tokenBalance < offerItem.startAmount ||
                tokenBalance < offerItem.endAmount
            ) {
                errorsAndWarnings.addError("insufficient token balance");
            }
        } else {
            errorsAndWarnings.addError("invalid item type");
        }
    }

    // TODO: Need to add support for order with extra data
    function isValidZone(OrderParameters memory orderParameters)
        public
        view
        returns (ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new string[](0), new string[](0));

        ZoneInterface zone = ZoneInterface(orderParameters.zone);

        if (address(zone).code.length == 0) {
            // Address is EOA. Valid order
            return errorsAndWarnings;
        }

        uint256 currentOffererCounter = seaport.getCounter(
            orderParameters.offerer
        );

        try
            zone.isValidOrder(
                _deriveOrderHash(orderParameters, currentOffererCounter),
                msg.sender, /* who should be caller? */
                orderParameters.offerer,
                orderParameters.zoneHash
            )
        returns (bytes4 zoneReturn) {
            if (zoneReturn != ZoneInterface.isValidOrder.selector) {
                errorsAndWarnings.addError("Zone rejected order");
            }
        } catch {
            errorsAndWarnings.addError("Zone reverted");
        }
    }

    function getApprovalAddress(bytes32 conduitKey)
        public
        view
        returns (address)
    {
        if (conduitKey == 0) return address(seaport);
        (address conduitAddress, bool exists) = conduitController.getConduit(
            conduitKey
        );
        if (!exists) revert("invalid conduit key");
        return conduitAddress;
    }

    function checkInterface(address token, bytes4 interfaceId)
        public
        view
        returns (bool)
    {
        return
            safeStaticCallBool(
                token,
                abi.encodeWithSelector(
                    IERC165.supportsInterface.selector,
                    interfaceId
                ),
                true
            );
    }

    function safeStaticCallBool(
        address target,
        bytes memory callData,
        bool expectedReturn
    ) public view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;

        for (uint256 i = 0; i < 31; i++) {
            if (res[i] != 0) return false;
        }

        return expectedReturn ? res[31] == 0x01 : res[31] == 0;
    }

    function safeStaticCallAddress(
        address target,
        bytes memory callData,
        address expectedReturn
    ) public view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;

        for (uint256 i = 0; i < 12; i++) {
            if (res[i] != 0) return false; // ensure only 20 bits are filled
        }

        return abi.decode(res, (address)) == expectedReturn;
    }

    function safeStaticCallUint256(
        address target,
        bytes memory callData,
        uint256 expectedReturn
    ) public view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;

        return abi.decode(res, (uint256)) == expectedReturn;
    }

    function pushMemoryArray(
        string[] memory stringArray,
        string memory newValue
    ) internal pure returns (string[] memory) {
        string[] memory returnValue = new string[](stringArray.length + 1);

        for (uint256 i = 0; i < stringArray.length; i++) {
            returnValue[i] = stringArray[i];
        }
        returnValue[stringArray.length] = newValue;

        return returnValue;
    }

    function concatMemoryArrays(string[] memory array1, string[] memory array2)
        internal
        pure
        returns (string[] memory)
    {
        string[] memory returnValue = new string[](
            array1.length + array2.length
        );

        for (uint256 i = 0; i < array1.length; i++) {
            returnValue[i] = array1[i];
        }
        for (uint256 i = 0; i < array2.length; i++) {
            returnValue[i + array1.length] = array2[i];
        }

        return returnValue;
    }
}
