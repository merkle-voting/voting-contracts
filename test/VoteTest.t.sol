// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Voting.sol";
import "./Helpers.sol";

contract VotingTest is Helpers {
    Voting public voting;
    uint256 privkey =
        0xc3b172d7cd994e15ea0a094a9e7bdc79eee4b44c732d0bc7255e710d93dde325;

    function setUp() public {
        voting = new Voting();
    }

    function testMerkleTreeVerifier() public {
        string[] memory t = new string[](1);
        t[0] = "tayo";
        //create election
        voting.createElection(
            getNo(),
            uint40(block.timestamp),
            1 days,
            "Futa Staff",
            3,
            t
        );

        address v = 0x18fc3C49ddb53542d98Ef8708294204579Ea4D08;
        bytes32 voterHash = 0x8b7f45d244cfb094621a6a43100e46570af5028a66d3304d01185754723f5b27;
        bytes32 root = 0xadc9607e74ab807e4d5b7cd47b1a0eace70edd24030e22b75de66b7838334e32;
        bytes32[] memory p = new bytes32[](2);
        p[
            0
        ] = 0xbd9edf19cd2eb1e712b2af05be2b466320f26ae17412b633d80947da0b576906;
        p[
            1
        ] = 0x6b224e8b6ac1f0190545401fd9a867b9962d4e814098e99014fe56937e660c1a;
        bytes memory sig = Helpers.constructSig(v, 0, 1, privkey);

        voting.activateElection(0, root);
        Voting.VoteData memory vote = Voting.VoteData(sig, 1, v, voterHash, p);
        Voting.VoteData memory vote2 = Voting.VoteData(sig, 2, v, voterHash, p);
        Voting.VoteData[] memory votes = new Voting.VoteData[](2);
        votes[0] = vote;
        votes[1] = vote2;
        voting.submitVotes(votes, 0);
        voting.viewResults(0);
        voting.viewElection(0);
    }
}

function getNo() pure returns (uint256[] memory t) {
    t = new uint256[](3);
    t[0] = 0;
    t[1] = 1;
    t[2] = 2;
}
