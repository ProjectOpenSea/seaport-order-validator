// SPDX-License-Identifier: MIT
import { StringMemoryArray } from "./StringMemoryArray.sol";

pragma solidity ^0.8.10;

struct ErrorsAndWarnings {
    string[] errors;
    string[] warnings;
}

library ErrorsAndWarningsLib {
    using StringMemoryArray for string[];

    function concat(ErrorsAndWarnings memory ew1, ErrorsAndWarnings memory ew2)
        internal
        pure
    {
        ew1.errors = ew1.errors.concatMemory(ew2.errors);
        ew1.warnings = ew1.warnings.concatMemory(ew2.warnings);
    }

    function addError(ErrorsAndWarnings memory ew, string memory err)
        internal
        pure
    {
        ew.errors = ew.errors.pushMemory(err);
    }

    function addWarning(ErrorsAndWarnings memory ew, string memory warn)
        internal
        pure
    {
        ew.warnings = ew.warnings.pushMemory(warn);
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
}
