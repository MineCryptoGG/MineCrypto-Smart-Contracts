// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMineBans {
    /**
     * Returns whether a token is banned or not
     */
    function isBanned(uint256 tokenId) external view returns (bool);
}
