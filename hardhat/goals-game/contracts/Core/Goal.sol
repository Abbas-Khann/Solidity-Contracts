// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Profile.sol";

// Contract to set, verify, close goal or become a goal motivator
contract Goal {
    Profile private _profile;

    constructor(address _profileAddress) {
        _profile = Profile(_profileAddress);
    }
}
