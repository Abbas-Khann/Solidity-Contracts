// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library DataTypes {
    struct Goal {
        uint256 createdTimestamp;
        string description;
        address authorAddress;
        uint256 lockedAmount;
        uint256 deadlineTimestamp;
        bool isAchieved;
        string proofURI;
    }

    struct GoalMotivator {
        uint256 motivationTimestamp;
        address motivatorAddress;
        string description;
    }

    struct GoalMessage {
        uint256 addedTimestamp;
        address authorAddress;
        string message;
    }
}
