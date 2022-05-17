// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./IMineMintRandom.sol";
import "./IMineForgeRandom.sol";
import "./IMineForge.sol";
import "./MineNft.sol";

contract MineRandomv2 is VRFConsumerBase, Ownable, IMineMintRandom, IMineForgeRandom {
    // requestId to tokenId for mint requests
    mapping(bytes32 => uint256) public tokenMintRequest;
    // tokenId for the new token, to tokenId of the parent NFT and maxPurityIncrease
    mapping(uint256 => ForgedRankInfo) public forgedRank;

    struct ForgedRankInfo {
        uint256 parentId;
        uint16 maxPurityIncrease;
    }

    // vrf
    bytes32 internal keyHash;
    uint256 internal fee;

    // contracts
    MineNft mineNft;
    IMineForge mineForge;

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

    function setIsForge(uint256 newRankId, uint256 parentRankId, uint16 maxPurityIncrease) external override {
        require(msg.sender == address(mineForge), "Only forge call allowed");

        forgedRank[newRankId].maxPurityIncrease = maxPurityIncrease;
        forgedRank[newRankId].parentId = parentRankId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 newTokenId = tokenMintRequest[requestId];

        uint256 parentRank = forgedRank[newTokenId].parentId;
        uint16 maxPurityIncrease = forgedRank[newTokenId].maxPurityIncrease;

        bool isForge = parentRank != 0;

        if (isForge) {
            mineForge.setNewPurity(newTokenId, parentRank, randomness, maxPurityIncrease);
        } else {
            mineNft.setPurity(newTokenId, randomness);
        }
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

    function setForgeAddress(address newAddress) external onlyOwner {
        mineForge = IMineForge(newAddress);
    }

    /**
     * @dev allows withdrawing any token that is stuck in the contract
     * @param tokenAddress addres of the token we are withdrawing
     */
    function emergencyWithdrawToken(address tokenAddress) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenAddress);

        uint256 withdrawBalance = tokenContract.balanceOf(address(this));

        require(withdrawBalance > 0, "No balance for this token");

        tokenContract.transfer(msg.sender, withdrawBalance);
    }

    /**
     * @dev allows withdrawing BNB that is stuck in the contract
     */
    function emergencyWithdrawBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
