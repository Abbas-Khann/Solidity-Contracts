// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../Interfaces/IERC721.sol";

contract Auction {
    IERC721 private nft_contract;
    uint256 nft_id;
    address private seller;
    uint256 private starting_bid;
    bool private bidding_active;
    uint64 private bid_timespan;

    constructor(address _nft_contract, uint256 _nft_id) payable {
        nft_contract = IERC721(_nft_contract);
        nft_id = _nft_id;
        seller = msg.sender;
        starting_bid = msg.value;
        bidding_active = true;
    }
}
