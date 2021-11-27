// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MineNft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MineNftPresale is Ownable {
    // NFT contract
    MineNft private mineNft;

    // Maximum pre-sale units
    uint16 public maxGoldRanks = 300;
    uint16 public maxDiamondRanks = 30;
    uint16 public maxEmeraldRanks = 10;

    // Current presale units
    uint16 public mintedGoldRanks = 0;
    uint16 public mintedDiamondRanks = 0;
    uint16 public mintedEmeraldRanks = 0;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public boughtWhitelist;

    /**
     * @dev Initializes the contract
     * @param nftAddress address for the NFT contract
     */
    constructor(address nftAddress) {
        mineNft = MineNft(nftAddress);
    }

    /**
     * WHITELIST METHODS
     */

    /**
     * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
     */
    modifier isWhitelisted() {
        require(whitelist[msg.sender], "Not in whitelist");
        _;
    }

    /**
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] memory _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }

    /**
     * PRESALE METHODS
     */

    /**
     * @dev Mints a Gold rank NFT for the caller if they are in
     *      whitelist and send enough BNB
     */
    function mintGold() external payable isWhitelisted {
        require(!boughtWhitelist[msg.sender], "Has already bought a rank");
        require(msg.value >= 0.5 ether, "Not enough BNB");
        require(mintedGoldRanks < maxGoldRanks, "Mint limit reached");

        boughtWhitelist[msg.sender] = true;
        mintedGoldRanks++;

        mineNft.mintPresale(MineNft.RankType(0), msg.sender);
    }

    /**
     * @dev Mints a Diamond rank NFT for the caller if they are in
     *      whitelist and send enough BNB
     */
    function mintDiamond() external payable isWhitelisted {
        require(!boughtWhitelist[msg.sender], "Has already bought a rank");
        require(msg.value >= 1 ether, "Not enough BNB");
        require(mintedDiamondRanks < maxDiamondRanks, "Mint limit reached");

        boughtWhitelist[msg.sender] = true;
        mintedDiamondRanks++;

        mineNft.mintPresale(MineNft.RankType(1), msg.sender);
    }

    /**
     * @dev Mints an Emerald rank NFT for the caller if they are in
     *      whitelist and send enough BNB
     */
    function mintEmerald() external payable isWhitelisted {
        require(!boughtWhitelist[msg.sender], "Has already bought a rank");
        require(msg.value >= 2 ether, "Not enough BNB");
        require(mintedEmeraldRanks < maxEmeraldRanks, "Mint limit reached");

        boughtWhitelist[msg.sender] = true;
        mintedEmeraldRanks++;

        mineNft.mintPresale(MineNft.RankType(2), msg.sender);
    }

    /**
     * WITHDRAW METHODS
     */

    /**
     * @dev allows withdrawing BNB that is in the contract
     */
    function withdrawBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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
}
