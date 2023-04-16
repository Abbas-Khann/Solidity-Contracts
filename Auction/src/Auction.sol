// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../Interfaces/IERC721.sol";

error BID_NOT_HIGHEST();
error BID_NOT_ACTIVE();
error AUCTION_TIME_EXCEEDED();
error INVALID_ADDRESS_CALL();

contract Auction {
    // event to emit when a bid is made
    event bid_made(address indexed sender, uint256 amount);
    // event to emit when the auction is ended
    event auction_ended(address indexed winner, uint256 ending_timestamp);
    // nft contract address
    IERC721 private nft_contract;
    // token_id for the nft
    uint256 private token_id;
    // seller address
    address private seller;
    // highest_bidder for the NFT
    address private highest_bidder;
    // starting bid for the NFT
    uint256 private starting_bid;
    // highest bid for each NFT
    uint256 private highest_bid;
    // bool to check if bidding is still active
    bool private bidding_active;
    // timespan of the bid
    uint64 private constant bid_timespan = 24 hours;
    // bidding starting time
    uint256 private bidding_ending_timestamp;
    // boolean for state variable
    bool private locked;
    // array of all bidders
    address[] private bidders;
    // mapping to track the amount bid by each bidder
    mapping(address => uint256) public amount_bid;

    constructor(address _nft_contract, uint256 _token_id) payable {
        // initializing the nft contract address
        nft_contract = IERC721(_nft_contract);
        // setting up the token_id
        token_id = _token_id;
        // initializing the seller as the auction contract owner
        seller = msg.sender;
        // initializing the starting_bid to be the amount sent by the seller
        starting_bid = msg.value;
        // setting the bidding_active bool to true after contract is deployed
        bidding_active = true;
        // setting the starting timestamp state to the current timestamp
        bidding_ending_timestamp = block.timestamp + bid_timespan;
    }

    // modifier to check if the caller is valid
    modifier isValidCaller() {
        if (msg.sender == address(0)) {
            revert INVALID_ADDRESS_CALL();
        }
        _;
    }

    // modifier to check for Reentrancies
    modifier nonReentrant() {
        // Makes sure locked = false
        require(!locked, "No re-entrancy");
        // sets locked to true and locks the function
        locked = true;
        // _; executes the function
        _;
        // sets locked back up to false to unlock it again
        locked = false;
    }

    /*
    @dev modifier to check for Valid bids
    */
    modifier onlyValidBids() {
        // amount sent should be higher than the highest_bid var
        if (msg.value <= highest_bid) {
            revert BID_NOT_HIGHEST();
        }
        // check to make sure the bidding is still active
        if (!bidding_active) {
            revert BID_NOT_ACTIVE();
        }
        // check to make sure the bidding has not expired
        if (block.timestamp > bidding_ending_timestamp) {
            revert AUCTION_TIME_EXCEEDED();
        }
        _;
    }

    /*
    @dev function to place a bid
    */
    function bid() public payable isValidCaller onlyValidBids {
        require(msg.sender != seller, "CANT_BID_ON_YOUR_OWN_NFT");
        if (msg.value > highest_bid) {
            highest_bid = msg.value;
        }
        highest_bidder = msg.sender;
        amount_bid[msg.sender] = msg.value;
        bidders.push(msg.sender);
        emit bid_made(msg.sender, msg.value);
    }
}
