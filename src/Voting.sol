// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./libraries/LibSignature.sol";
import "solmate/utils/MerkleProofLib.sol";

contract Voting {
    uint256 public electionId;

    struct Election {
        string title;
        uint256[] candidates;
        uint40 timeStarted;
        uint40 duration;
        uint40 endTime;
        mapping(uint256 => uint256) votePerCandidate;
        uint8 maxCandidateNo;
        bool active;
        bytes32 merkleRoot;
    }

    struct VoteData {
        bytes signature;
        uint256 candidateId;
        address voter;
        bytes32 voterHash;
        bytes32[] proof;
    }

    struct ElectionM {
        string title;
        uint256[] candidates;
        uint40 timeStarted;
        uint40 duration;
        uint40 endTime;
        bytes32 merkleRoot;
    }
    mapping(uint256 => Election) elections;
    //admin whitelists
    mapping(address => mapping(uint256 => bool)) canVote;
    address owner;

    event ElectionCreated(uint256[] candidates, string title, uint40 endTime);
    event Voted(address voter, uint256 electionId, uint256 candidate);

    constructor() {
        owner = (msg.sender);
    }

    function _isOwner() private view {
        if (msg.sender != owner) revert("NotOwner");
    }

    //confirm if the user is a registered voter in the given election
    function _isVoter(
        address _voter,
        bytes32 _voterHash,
        bytes32[] calldata _merkleProof,
        uint256 _electionId
    ) internal view {
        //short-circuit election id
        bytes32 root = _assertElection(_electionId);
        //compute the leaf/node hash
        bytes32 node = keccak256(
            abi.encodePacked(_voter, _voterHash, _electionId)
        );

        if (!MerkleProofLib.verify(_merkleProof, root, node))
            revert("InvalidVoter");
    }

    function _canVote(address _voter, uint256 _electionId) private view {
        if (!canVote[_voter][_electionId]) revert("Unable To Vote");
    }

    function _assertTime(uint40 _startTime, uint40 _duration) private view {
        if (_startTime < block.timestamp) revert("StartTimeTooLow");
        uint40 _endTime = _startTime + _duration;
        if (_endTime >= _startTime) revert("EndTimeTooLow");
        if (_duration < 3 hours) revert("3 hours duration Min");
        //put in a check for startTime restriction
        if (_endTime > 3 days) revert("3 Days Duration Max ");
    }

    function _assertElection(
        uint256 _electionId
    ) private view returns (bytes32 root_) {
        if (_electionId > electionId) revert("InvalidElectionID");
        if (elections[_electionId].endTime > block.timestamp)
            revert("ElectionFinished");
        root_ = elections[_electionId].merkleRoot;
        if (!elections[_electionId].active) revert("InactiveElection");
    }

    function createElection(
        uint256[] calldata _candidates,
        uint40 _startTime,
        uint40 _duration,
        string calldata _title,
        uint8 _maxCandidates
    ) external {
        _isOwner();
        if (_candidates.length > 5) revert("max candidate length is 5");
        _assertTime(_startTime, _duration);
        Election storage e = elections[electionId];
        e.candidates = _candidates;
        e.title = _title;
        e.duration = _duration;
        e.timeStarted = _startTime;
        e.endTime = _startTime + _duration;
        e.maxCandidateNo = _maxCandidates;
        emit ElectionCreated(_candidates, _title, e.endTime);
        electionId++;
    }

    function activateElection(
        uint256 _electionId,
        bytes32 _merkleRoot
    ) external {
        _isOwner();
        elections[_electionId].merkleRoot = _merkleRoot;
        elections[_electionId].active = true;
    }

    // function whitelistVoters(address[] calldata _voters) external {
    //     _isOwner();
    //     for (uint256 i = 0; i < _voters.length; ) {
    //         canVote[_voters[i]] = true;
    //         unchecked {
    //             ++i;
    //         }
    //     }
    // }

    //_data[i] should be a hash of vote details e.g consisting of candidate id and voter detail hash
    function submitVotes(
        VoteData[] calldata _data,
        uint256 _electionId
    ) external {
        //assert(_sigs.length == _data.length);
        if (_data.length > 0) {
            for (uint256 i = 0; i < _data.length; ) {
                VoteData memory data = _data[i];
                //check voter eligibility
                _canVote(data.voter, _electionId);
                _isVoter(
                    data.voter,
                    data.voterHash,
                    _data[i].proof,
                    _electionId
                );
                Election storage e = elections[_electionId];
                if (_data[i].candidateId > e.maxCandidateNo - 1)
                    revert("NoSuchCandidate");
                //increase vote count for candidate

                e.votePerCandidate[data.candidateId]++;
                emit Voted(data.voter, _electionId, data.candidateId);
                unchecked {
                    ++i;
                }
            }
        }
    }

    function viewResults(
        uint256 _electionId
    )
        public
        view
        returns (uint256[] memory candidateIds, uint256[] memory _votes)
    {
        candidateIds = new uint256[](elections[_electionId].maxCandidateNo);
        _votes = new uint256[](elections[_electionId].maxCandidateNo);
        for (uint256 i = 0; i < _votes.length; i++) {
            candidateIds[i] = i;
            _votes[i] = elections[_electionId].votePerCandidate[i];
        }
    }

    function viewElection(
        uint256 _id
    ) public view returns (ElectionM memory e_) {
        Election storage e = elections[_id];
        e_.candidates = e.candidates;
        e_.title = e.title;
        e_.timeStarted = e.timeStarted;
        e_.duration = e.duration;
        e_.endTime = e.endTime;
        e_.merkleRoot = e.merkleRoot;
    }
}
