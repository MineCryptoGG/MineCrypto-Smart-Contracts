// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MineNft.sol";
import "./IMineForgeRandom.sol";
import "./IMineForge.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// todo set wait time by rank
contract MineForge is Pausable, AccessControl, IMineForge {
    // struct to store forge info
    struct ForgeInfo {
        bool isBeingForged;
        address forger;
        bool isPresent;
    }

    // struct to store forge info
    struct UserInfo {
        uint256[] createdForges;
        bool isForging;
    }

    // struct to store forge stats
    struct ForgeStats {
        uint256 burnedRanks;
        uint256 mintedRanks;
    }

    // CONTRACTS
    MineNft private mineNft;
    IMineForgeRandom forgeRandom;

    // FORGING VARIABLES
    MineNft.RankType MAX_RANK_START = MineNft.RankType.EMERALD;
    MineNft.RankType MAX_RANK_END = MineNft.RankType.EMERALD;

    // DATA
    mapping(uint256 => ForgeInfo) public currentForge; // forge data for tokens
    mapping(address => UserInfo) public usersInfo;
    mapping(MineNft.RankType => ForgeStats) public forgeStats; // general forge stats

    // CONSTANTS
    uint16 MAX_PURITY = 10_000;

    //ROLES
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev starts a forge process
     * @param rankId rank being forged
     */
    function startForge(uint256 rankId) external whenNotPaused {
        require(mineNft.ownerOf(rankId) == msg.sender, "You dont own the rank");

        require(mineNft.getApproved(rankId) == address(this), "Contract not approved");

        require(!currentForge[rankId].isPresent, "Rank is already in forge");

        MineNft.RankType rankType = mineNft.getType(rankId);

        require(uint256(rankType) <= uint256(MAX_RANK_START), "Rank exceeds max forge");

        require(!usersInfo[msg.sender].isForging, "User already forging");

        mineNft.burn(rankId);

        currentForge[rankId].isBeingForged = true;
        currentForge[rankId].forger = msg.sender;
        currentForge[rankId].isPresent = true;

        usersInfo[msg.sender].isForging = true;
        usersInfo[msg.sender].createdForges.push(rankId);

        forgeStats[rankType].burnedRanks++;
    }

    /**
     * @dev finishes the forge after a user completes the process
     * @param rankId rank to finish forge
     * @param maxPurityIncrease maximum purity increase (100 is 1% increase)
     */
    function finishForge(uint256 rankId, uint16 maxPurityIncrease)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        require(maxPurityIncrease < 10_000, "maxPurityIncrease bigger than max purity");

        bool isBeingForged = currentForge[rankId].isBeingForged;

        require(isBeingForged, "Rank is not being forged");

        currentForge[rankId].isBeingForged = false;

        address forgeCreator = currentForge[rankId].forger;

        usersInfo[forgeCreator].isForging = false;

        MineNft.RankType rankType = mineNft.getType(rankId);

        require(uint256(rankType) <= uint256(MAX_RANK_END), "Rank exceeds max forge");

        MineNft.RankType newRankType = MineNft.RankType(uint256(rankType) + 1);

        uint256 newRankId = mineNft.mintRankForge(forgeCreator, newRankType);

        forgeRandom.setIsForge(newRankId, rankId, maxPurityIncrease);

        forgeStats[newRankType].mintedRanks++;

        return newRankId;
    }

    /**
     * @dev method called by VRF with a random number
     * @param newRankId rank to set random for
     * @param parentRankId parent rank
     * @param randomness random number
     * @param maxPurityIncrease maximum purity increase (100 is 1% increase)
     */
    function setNewPurity(
        uint256 newRankId,
        uint256 parentRankId,
        uint256 randomness,
        uint16 maxPurityIncrease
    ) external override {
        require(
            msg.sender == address(forgeRandom) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only random or admin allowed"
        );

        uint256 randomModulo = randomness % 100;

        uint256 purityIncreasePercentage = 0;

        if (randomModulo > 15) {
            purityIncreasePercentage = ((randomModulo - 15) * 100) / 85;
        }

        uint256 purityIncrease = (purityIncreasePercentage * maxPurityIncrease) / 100;

        uint16 purity = mineNft.getPurity(parentRankId);
        uint16 newPurity = purity + uint16(purityIncrease);

        uint16 finalPurity = (newPurity >= MAX_PURITY) ? MAX_PURITY : newPurity;
        mineNft.setPurity(newRankId, finalPurity);
    }

    function getUserInfo(address user) external view returns (UserInfo memory) {
        return usersInfo[user];
    }

    /** 
    ADMINISTRATION FUNCTIONS 
    */

    /**
     * @dev pauses the contract
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev unpauses the contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev sets the maximum rank that can be achieved forging
     * @param startMaxRank max rank with which you can start the forge
     *  @param endMaxRank max rank with which you can finish the forge
     */
    function setMaxRank(MineNft.RankType startMaxRank, MineNft.RankType endMaxRank)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAX_RANK_START = startMaxRank;
        MAX_RANK_END = endMaxRank;
    }

    function setRandomAddress(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        forgeRandom = IMineForgeRandom(newAddress);
    }

    function setNftAddress(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mineNft = MineNft(newAddress);
    }

    function manuallyDisableRankForge(uint256 rankId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        currentForge[rankId].isBeingForged = false;
    }

    function manuallyDisableUserForge(address forgeCreator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usersInfo[forgeCreator].isForging = false;
    }

    /**
     * @dev allows withdrawing any token that is stuck in the contract
     * @param tokenAddress addres of the token we are withdrawing
     */
    function emergencyWithdrawToken(address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 tokenContract = IERC20(tokenAddress);

        uint256 withdrawBalance = tokenContract.balanceOf(address(this));

        require(withdrawBalance > 0, "No balance for this token");

        tokenContract.transfer(msg.sender, withdrawBalance);
    }

    /**
     * @dev allows withdrawing BNB that is stuck in the contract
     */
    function emergencyWithdrawBNB() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
}
