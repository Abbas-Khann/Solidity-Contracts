// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./Profile.sol";

// Contract to set, verify, close goal or become a goal motivator
contract Goal {
    Profile private _profile;
    bool public paused;
    address owner;

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
    function setGoal() public payable onlyWhenNotPaused onlyProfileOwners {}
}
