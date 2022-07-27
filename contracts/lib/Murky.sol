// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Murky {
    uint136 constant _2_128 = 2**128;
    uint72 constant _2_64 = 2**64;
    uint40 constant _2_32 = 2**32;
    uint24 constant _2_16 = 2**16;
    uint16 constant _2_8 = 2**8;
    uint8 constant _2_4 = 2**4;
    uint8 constant _2_2 = 2**2;
    uint8 constant _2_1 = 2**1;

    /***************
     * CONSTRUCTOR *
     ***************/
    constructor() {}

    function hashLeafPairs(bytes32 left, bytes32 right)
        public
        pure
        returns (bytes32 _hash)
    {
        assembly {
            switch lt(left, right)
            case 0 {
                mstore(0x0, right)
                mstore(0x20, left)
            }
            default {
                mstore(0x0, left)
                mstore(0x20, right)
            }
            _hash := keccak256(0x0, 0x40)
        }
    }

    /**********************
     * PROOF VERIFICATION *
     **********************/

    function verifyProof(
        bytes32 root,
        bytes32[] calldata proof,
        bytes32 valueToProve
    ) external pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = valueToProve;
        uint256 length = proof.length;
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                rollingHash = hashLeafPairs(rollingHash, proof[i]);
            }
        }
        return root == rollingHash;
    }

    /********************
     * PROOF GENERATION *
     ********************/

    function getRoot(bytes32[] memory data) public pure returns (bytes32) {
        require(data.length > 1, "won't generate root for single leaf");

        processInput(data);

        while (data.length > 1) {
            data = hashLevel(data);
        }
        return data[0];
    }

    function getProof(bytes32[] memory data, uint256 node)
        public
        pure
        returns (bytes32[] memory)
    {
        require(data.length > 1, "won't generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves)
        bytes32[] memory result = new bytes32[](log2ceilBitMagic(data.length));
        uint256 pos = 0;

        processInput(data);

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while (data.length > 1) {
            unchecked {
                if (node & 0x1 == 1) {
                    result[pos] = data[node - 1];
                } else if (node + 1 == data.length) {
                    result[pos] = bytes32(0);
                } else {
                    result[pos] = data[node + 1];
                }
                ++pos;
                node /= 2;
            }
            data = hashLevel(data);
        }
        return result;
    }

    /// Original bitmagic adapted from https://github.com/paulrberg/prb-math/blob/main/contracts/PRBMath.sol
    /// @dev Note that x assumed > 1
    function log2ceilBitMagic(uint256 x) public pure returns (uint256) {
        if (x <= 1) {
            return 0;
        }
        uint256 msb = 0;
        uint256 _x = x;
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            msb += 1;
        }

        uint256 lsb = (~_x + 1) & _x;
        if ((lsb == _x) && (msb > 0)) {
            return msb;
        } else {
            return msb + 1;
        }
    }

    ///@dev function is private to prevent unsafe data from being passed
    function hashLevel(bytes32[] memory data)
        private
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory result;

        // Function is private, and all internal callers check that data.length >=2.
        // Underflow is not possible as lowest possible value for data/result index is 1
        // overflow should be safe as length is / 2 always.
        unchecked {
            uint256 length = data.length;
            if (length & 0x1 == 1) {
                result = new bytes32[](length / 2 + 1);
                result[result.length - 1] = data[length - 1];
            } else {
                result = new bytes32[](length / 2);
            }
            // pos is upper bounded by data.length / 2, so safe even if array is at max size
            uint256 pos = 0;
            for (uint256 i = 0; i < length - 1; i += 2) {
                result[pos] = hashLeafPairs(data[i], data[i + 1]);
                ++pos;
            }
        }
        return result;
    }

    /**
     * Hashes each element of the input array in place using keccak256
     */
    function processInput(bytes32[] memory data) public pure {
        // Hash inputs with keccak256
        for (uint256 i = 0; i < data.length; ++i) {
            assembly {
                mstore(
                    add(data, mul(0x20, add(1, i))),
                    keccak256(add(data, mul(0x20, add(1, i))), 0x20)
                )
                // for every element after the first, hashed value must be greater than the last one
                if and(
                    gt(i, 0),
                    iszero(
                        gt(
                            mload(add(data, mul(0x20, add(1, i)))),
                            mload(add(data, mul(0x20, add(1, sub(i, 1)))))
                        )
                    )
                ) {
                    revert(0, 0) // Elements not ordered by hash
                }
            }
        }
    }
}
