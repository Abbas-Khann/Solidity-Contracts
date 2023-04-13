// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./Profile.sol";
import "../Libraries/DataTypes.sol";

// Contract to set, verify, close goal or become a goal motivator
contract GameGoal {
    event GoalSet(uint256 indexed id, DataTypes.Goal indexed params);
    event Motivator(uint256 indexed id, DataTypes.GoalMotivator indexed params);

    Profile private _profile;
    bool public paused;
    address owner;

    mapping(uint256 => DataTypes.Goal) public goal;
    mapping(uint256 => DataTypes.GoalMotivator[]) goalMotivators;
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

    modifier alreadyClosedOrAchieved(uint256 _id) {
        require(!goal[_id].isAchieved, "Goal closed or already achieved!");
        _;
    }

    modifier onlyGoalOwner(uint256 _id) {
        require(
            msg.sender == goal[_id].authorAddress,
            "You are not the goal owner"
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
            false
        );
        goal[goalId] = goalParams;
        emit GoalSet(goalId, goalParams);
    }

    function becomeMotivator(
        uint256 _id,
        string memory _motivationalMessage
    ) public onlyWhenNotPaused onlyProfileOwners alreadyClosedOrAchieved(_id) {
        require(
            goal[_id].authorAddress != msg.sender,
            "You can't be your own motivator"
        );
        require(
            goal[_id].deadlineTimestamp > block.timestamp,
            "Goal not active anymore"
        );
        DataTypes.GoalMotivator memory motivator = DataTypes.GoalMotivator(
            block.timestamp,
            msg.sender,
            _motivationalMessage
        );
        goalMotivators[goalId].push(motivator);
        emit Motivator(goalId, motivator);
    }

    function closeGoal(
        uint256 _id
    )
        external
        onlyWhenNotPaused
        onlyGoalOwner(_id)
        alreadyClosedOrAchieved(_id)
    {
        require(
            goal[_id].deadlineTimestamp > block.timestamp,
            "Goal not active anymore"
        );
        goal[_id].isAchieved = true;
    }

    function withdrawLockedFunds(
        uint256 _id
    ) external onlyWhenNotPaused onlyGoalOwner(_id) {
        require(goal[_id].isAchieved, "Goal was not achieved");
        (bool sent, ) = goal[_id].authorAddress.call{
            value: goal[_id].lockedAmount
        }("");
        require(sent, "Failed to withdraw");
    }

    /*
    @dev Get motivators
    */
    function getGoalMotivators(
        uint256 _id
    ) public view returns (DataTypes.GoalMotivator[] memory) {
        return goalMotivators[_id];
    }
}
