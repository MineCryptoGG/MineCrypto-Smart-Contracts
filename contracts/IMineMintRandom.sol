// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IMineMintRandom {

    /**
     * Requests randomness for the mint purity
     */
    function getRandomMintPurity(uint256 tokenId) external;

}
