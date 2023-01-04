// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./libraries/LibSignature.sol";

contract Voting {
    uint256 public electionId;

    struct Election {
        string title;
        string[] candidates;
        uint40 timeStarted;
        uint40 duration;
        uint40 endTime;
        mapping(string => uint256) votePerCandidate;
    }
    mapping(uint256 => Election) elections;
    //admin whitelists
    mapping(address => bool) canVote;
    address owner;

    event ElectionCreated(string[] candidates, string title, uint40 endTime);

    constructor() {
        owner = (msg.sender);
    }

    function _isOwner() private view {
        if (msg.sender != owner) revert("NotOwner");
    }

    function _canVote() private view {
        if (!canVote[msg.sender]) revert("Unable To Vote");
    }

    function assertTime(uint40 _startTime, uint40 _duration) private view {
        if (_startTime < block.timestamp) revert("StartTimeTooLow");
        uint40 _endTime = _startTime + _duration;
        if (_endTime >= _startTime) revert("EndTimeTooLow");
        if (_duration < 3 hours) revert("3 hours duration Min");
        if (_endTime > 3 days) revert("3 Days Duration Max ");
    }

    function createElection(
        string[] calldata _candidates,
        uint40 _startTime,
        uint40 _duration,
        string calldata _title
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
        emit ElectionCreated(_candidates, _title, e.endTime);
    }

    function submitVotes(
        bytes[] calldata _sigs,
        bytes32[] calldata _data
    ) external {}
}

h