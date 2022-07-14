// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library SafeStaticCall {
    function safeStaticCallBool(
        address target,
        bytes memory callData,
        bool expectedReturn
    ) internal view returns (bool) {
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
    ) internal view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;

        if (
            bytes32(res) &
                0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF !=
            bytes32(res)
        ) {
            // Ensure only 20 bytes used
            return false;
        }

        return abi.decode(res, (address)) == expectedReturn;
    }

    function safeStaticCallUint256(
        address target,
        bytes memory callData,
        uint256 minExpectedReturn
    ) internal view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;

        return abi.decode(res, (uint256)) >= minExpectedReturn;
    }

    function safeStaticCallBytes4(
        address target,
        bytes memory callData,
        bytes4 expectedReturn
    ) internal view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;
        if (
            bytes32(res) &
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 !=
            bytes32(res)
        ) {
            // Ensure only 4 bytes used
            return false;
        }

        return abi.decode(res, (bytes4)) == expectedReturn;
    }
}
