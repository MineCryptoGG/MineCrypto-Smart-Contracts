// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// todo set wait time by rank
interface IMineForge {

    function setNewPurity(
        uint256 newRankId,
        uint256 parentRankId,
        uint256 randomness,
        uint16 maxPurityIncrease
    ) external;
    
}
