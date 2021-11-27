// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./IMineMintRandom.sol";
import "./MineNft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MineRandom is VRFConsumerBase, Ownable, IMineMintRandom {


    // requestId to tokenId for mint requests
    mapping(bytes32 => uint256) public tokenMintRequest;

    // vrf
    bytes32 internal keyHash;
    uint256 internal fee;

    // contracts
    MineNft mineNft;

    /**
     * Constructor inherits VRFConsumerBase
     *
     */

    constructor()
        VRFConsumerBase(
            0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, // VRF Coordinator
            0x404460C6A5EdE2D891e8297795264fDe62ADBB75 // LINK Token
        )
    {
        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
        fee = 0.2 * 10**18;
    }

    function getRandomMintPurity(uint256 tokenId) external override {
        require(msg.sender == address(mineNft), "Only NFT call allowed");

        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - contact an admin");

        bytes32 requestId = requestRandomness(keyHash, fee);

        tokenMintRequest[requestId] = tokenId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        mineNft.setPurity(tokenMintRequest[requestId], randomness);
    }

    /**
     * ADMINISTRATION
     */
    function withdrawLink() external onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }

    function setNftAddress(address newAddress) external onlyOwner {
        mineNft = MineNft(newAddress);
    }

}
