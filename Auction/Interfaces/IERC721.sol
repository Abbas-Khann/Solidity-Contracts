// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;

    function transferFrom(address, address, uint) external;
}
