// SPDX-License-Identifier: MIT
import {
    ValidationError,
    ValidationWarning
} from "./SeaportValidatorTypes.sol";

pragma solidity ^0.8.10;

struct ErrorsAndWarnings {
    uint8[] errors;
    uint8[] warnings;
}

library ErrorsAndWarningsLib {
    function concat(ErrorsAndWarnings memory ew1, ErrorsAndWarnings memory ew2)
        internal
        pure
    {
        ew1.errors = concatMemory(ew1.errors, ew2.errors);
        ew1.warnings = concatMemory(ew1.warnings, ew2.warnings);
    }

    function addError(ErrorsAndWarnings memory ew, ValidationError err)
        internal
        pure
    {
        ew.errors = pushMemory(ew.errors, uint8(err));
    }

    function addWarning(ErrorsAndWarnings memory ew, ValidationWarning warn)
        internal
        pure
    {
        ew.warnings = pushMemory(ew.warnings, uint8(warn));
    }

    function hasErrors(ErrorsAndWarnings memory ew)
        internal
        pure
        returns (bool)
    {
        return ew.errors.length != 0;
    }

    function hasWarnings(ErrorsAndWarnings memory ew)
        internal
        pure
        returns (bool)
    {
        return ew.warnings.length != 0;
    }

    // Helper Functions
    function concatMemory(uint8[] memory array1, uint8[] memory array2)
        private
        pure
        returns (uint8[] memory)
    {
        if (array1.length == 0) {
            return array2;
        } else if (array2.length == 0) {
            return array1;
        }

        uint8[] memory returnValue = new uint8[](array1.length + array2.length);

        for (uint256 i = 0; i < array1.length; i++) {
            returnValue[i] = array1[i];
        }
        for (uint256 i = 0; i < array2.length; i++) {
            returnValue[i + array1.length] = array2[i];
        }

        return returnValue;
    }

    function pushMemory(uint8[] memory uint8Array, uint8 newValue)
        internal
        pure
        returns (uint8[] memory)
    {
        uint8[] memory returnValue = new uint8[](uint8Array.length + 1);

        for (uint256 i = 0; i < uint8Array.length; i++) {
            returnValue[i] = uint8Array[i];
        }
        returnValue[uint8Array.length] = newValue;

        return returnValue;
    }
}
