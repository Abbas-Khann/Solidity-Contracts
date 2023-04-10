// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";

contract Profile is ERC721Base {
    event URISet(uint256 tokenId, string tokenURI);

    mapping(address => uint256) public owners;
    // AT (0X7....1A3BV) => tokenID at 5
    mapping(uint256 => string) public profileURI;
    // AT 1 => "IPFS.CDNASDFASDF"

    constructor(string memory _name, string memory _symbol, address _royaltyRecipient, uint128 _royaltyBps)
        ERC721Base(_name, _symbol, _royaltyRecipient, _royaltyBps)
    {}

    /*
    @dev set the starting tokenId to 1
    */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*
    @dev Setup profile
    */
    function setupProfile(string memory _tokenURI) public {
        // Run a check to make sure if the user owns a token otherwise we will mint them a token else just update the URI
        if (owners[msg.sender] == 0) {
            owners[msg.sender] = nextTokenIdToMint();
            // mintTo calls overridden setTokenURI
            mintTo(msg.sender, _tokenURI);
        } else {
            _setTokenURI(owners[msg.sender], _tokenURI);
        }
    }

    /*
    @dev setting upgradeable tokenURI
    */
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal override {
        profileURI[_tokenId] = _tokenURI;
        emit URISet(_tokenId, _tokenURI);
    }

    /*
    @dev Make tokens non-transferrable
    */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
    {
        require(from == address(0), "Profiles are non-transferable");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /*//////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/
    function getTokenId(address _owner) public view returns (uint256) {
        return owners[_owner];
    }

    function getTokenURI(address _owner) public view returns (string memory) {
        uint256 tokenId = getTokenId(_owner);
        if (_exists(tokenId)) {
            return profileURI[tokenId];
        } else {
            return "";
        }
    }
}
