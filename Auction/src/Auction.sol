// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../Interfaces/IERC721.sol";

error BID_NOT_HIGHEST();
error BID_NOT_ACTIVE();
error AUCTION_TIME_EXCEEDED();
error INVALID_ADDRESS_CALL();
error NOT_BIDDER();
error ONLY_SELLER();

contract Auction {
    // event to emit when a bid is made
    event Bid(address indexed sender, uint256 amount);
    // event to emit when the auction is ended
    event AuctionEnded(address indexed winner, uint256 ending_timestamp);
    // event to emit when bidder withdraws their ether
    event Withdraw(address indexed withdrawer, uint256 amount);
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
    uint256 private auction_ending_timestamp;
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
        auction_ending_timestamp = block.timestamp + bid_timespan;
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
        if (block.timestamp > auction_ending_timestamp) {
            revert AUCTION_TIME_EXCEEDED();
        }
        _;
    }

    // modifier to only allow bidder to call a function
    modifier isBidder() {
        if (amount_bid[msg.sender] == 0) {
            revert NOT_BIDDER();
        }
        _;
    }

    // modifier to only allow seller to call a function
    modifier onlySeller() {
        if (msg.sender != seller) {
            revert ONLY_SELLER();
        }
        _;
    }

    /*
    @dev function to get the amount bid by each bidder
    */
    function getAmountBid(address _bidder) private view returns (uint256) {
        return amount_bid[_bidder];
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
        emit Bid(msg.sender, msg.value);
    }

    /*
    @dev function that allows bidders to withdraw their ether if they don't win the auction
    */
    function withdraw() public payable isValidCaller isBidder nonReentrant {
        require(msg.sender != seller, "You can't withdraw or bid your NFT");
        require(
            msg.sender != highest_bidder,
            "You are the highest bidder, You can't withdraw"
        );
        uint256 balance = getAmountBid(msg.sender);
        (bool withdrawEther, ) = msg.sender.call{value: balance}("");
        require(withdrawEther, "Failed to withdraw ether");
        // delete the mapping of the caller to his price
        delete amount_bid[msg.sender];
        emit Withdraw(msg.sender, balance);
    }

    /*
    @dev function that allows owner to end the auction after the time has exceeded
    */
    function endAuction() public payable isValidCaller nonReentrant onlySeller {
        require(
            block.timestamp > auction_ending_timestamp,
            "Auction not ended yet"
        );
        bidding_active = false;
        address winner = highest_bidder;
        nft_contract.safeTransferFrom(seller, winner, token_id);
        (bool sent, ) = seller.call{value: highest_bid}("");
        require(sent, "Failed to pay nft owner");
        delete amount_bid[winner];
        // call the func to repay the rest if not repaid yet
        for (uint256 i = 0; i < bidders.length; i++) {
            // payback here
            repay(bidders[i]);
        }
        bidding_active = false;
        emit AuctionEnded(winner, block.timestamp);
    }

    /*
    @dev function that repays all users if they haven't withdrawn their ether
    */
    function repay(address _bidder) private nonReentrant {
        // get the amount each bidder has bid
        uint256 _amount = amount_bid[_bidder];

        // if the amount bid is greater than 0 we need to pay them back
        if (_amount > 0) {
            (bool payback, ) = _bidder.call{value: _amount}("");
            require(payback, "Failed to payback");
        }
    }
}
