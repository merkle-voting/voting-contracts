// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/libraries/LibSignature.sol";

abstract contract Helpers is Test {
    event hh(bytes32);

    function constructSig(
        address _voter,
        uint256 _electionId,
        uint256 _candidateId,
        uint256 privKey
    ) public pure returns (bytes memory sig) {
        bytes32 mHash = keccak256(
            abi.encodePacked(_voter, _electionId, _candidateId)
        );
        mHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", mHash)
        );
        //  emit log_bytes32(mHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, mHash);
        sig = getSig(v, r, s);
    }

    function getSig(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory sig) {
        sig = bytes.concat(r, s, bytes1(v));
    }
}
