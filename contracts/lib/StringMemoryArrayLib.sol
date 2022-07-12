// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library StringMemoryArray {
    function concatMemory(string[] memory array1, string[] memory array2)
        internal
        pure
        returns (string[] memory)
    {
        if (array1.length == 0) {
            return array2;
        } else if (array2.length == 0) {
            return array1;
        }

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

    function pushMemory(string[] memory stringArray, string memory newValue)
        internal
        pure
        returns (string[] memory)
    {
        string[] memory returnValue = new string[](stringArray.length + 1);

        for (uint256 i = 0; i < stringArray.length; i++) {
            returnValue[i] = stringArray[i];
        }
        returnValue[stringArray.length] = newValue;

        return returnValue;
    }
}
