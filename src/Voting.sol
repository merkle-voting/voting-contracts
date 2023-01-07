// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./libraries/LibSignature.sol";

contract Voting {
    uint256 public electionId;

    struct Election {
        string title;
        uint256[] candidates;
        uint40 timeStarted;
        uint40 duration;
        uint40 endTime;
        mapping(string => uint256) votePerCandidate;
        bytes merkleRoot;
    }

    struct VoteData {
        bytes signature;
        uint256 candidateId;
        address voter;
        bytes32 voterHash;
    }

    struct ElectionM {
        string title;
        uint256[] candidates;
        uint40 timeStarted;
        uint40 duration;
        uint40 endTime;
        bytes merkleRoot;
    }
    mapping(uint256 => Election) elections;
    //admin whitelists
    mapping(address => bool) canVote;
    address owner;

    event ElectionCreated(uint256[] candidates, string title, uint40 endTime);
    event Voted(address voter, uint256 electionId, string candidate);

    constructor() {
        owner = (msg.sender);
    }

    function _isOwner() private view {
        if (msg.sender != owner) revert("NotOwner");
    }

    function _canVote() private view {
        if (!canVote[msg.sender]) revert("Unable To Vote");
        //verify merkleRoot with voter's info hash
        
    }

    function assertTime(uint40 _startTime, uint40 _duration) private view {
        if (_startTime < block.timestamp) revert("StartTimeTooLow");
        uint40 _endTime = _startTime + _duration;
        if (_endTime >= _startTime) revert("EndTimeTooLow");
        if (_duration < 3 hours) revert("3 hours duration Min");
        if (_endTime > 3 days) revert("3 Days Duration Max ");
    }

    function createElection(
        uint256[] calldata _candidates,
        uint40 _startTime,
        uint40 _duration,
        string calldata _title,
        bytes memory _merkleRoot
    ) external {
        _isOwner();
        if (_candidates.length > 5) revert("max candidate length is 5");
        assertTime(_startTime, _duration);
        Election storage e = elections[electionId];
        e.candidates = _candidates;
        e.title = _title;
        e.duration = _duration;
        e.timeStarted = _startTime;
        e.endTime = _startTime + _duration;
        e.merkleRoot = _merkleRoot;
        emit ElectionCreated(_candidates, _title, e.endTime);
    }

    function whitelistVoters(address[] calldata _voters) external {
        _isOwner();
        for (uint256 i = 0; i < _voters.length; ) {
            canVote[_voters[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    //_data[i] should be a hash of vote details e.g consisting of candidate id and voter detail hash
    function submitVotes(VoteData[] calldata _data) external {
        //assert(_sigs.length == _data.length);
        if(_data.length>0){

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
