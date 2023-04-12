// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./Profile.sol";
import "../Libraries/DataTypes.sol";

// Contract to set, verify, close goal or become a goal motivator
contract GameGoal {
    event GoalSet(uint256 id, DataTypes.Goal);

    Profile private _profile;
    bool public paused;
    address owner;

    mapping(uint256 => DataTypes.Goal) public goal;
    uint256 goalId;

    constructor(address _profileAddress) {
        _profile = Profile(_profileAddress);
        owner = msg.sender;
    }

    modifier onlyWhenNotPaused() {
        if (paused) {
            revert("Contract is paused!");
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyProfileOwners() {
        require(
            _profile.hasProfile(msg.sender),
            "You need to setup a profile!!!"
        );
        _;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    // function to set a goal
    function setGoal(
        string memory _description,
        uint256 _deadlineTimestamp
    ) public payable onlyWhenNotPaused onlyProfileOwners {
        require(msg.value == 0.1 ether, "You need to send 0.1 ether");
        require(
            _deadlineTimestamp > block.timestamp + 24 hours,
            "Deadline must be at least 24 hours later"
        );
        DataTypes.Goal memory goalParams = DataTypes.Goal(
            block.timestamp,
            _description,
            msg.sender,
            msg.value,
            _deadlineTimestamp,
            false,
            false
        );
        goal[goalId] = goalParams;
        emit GoalSet(goalId, goalParams);
    }
}
