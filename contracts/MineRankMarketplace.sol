// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IMineBans.sol";
import "./MineNft.sol";

contract MineRankMarketplace is Ownable, Pausable, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    // structs
    struct Listing {
        address owner;
        uint256 price;
        uint256 creation;
        uint256 tokenId;
    }

    // data
    mapping(uint256 => Listing) public listings; // tokenId to Listing
    mapping(address => EnumerableSet.UintSet) private userListings; // wallet to tokenIds being sold
    EnumerableSet.UintSet private allListings; // iterable set containing all listings

    // stats
    uint256 public totalVolume;
    uint256 public totalFees;
    uint256 public totalTrades;

    // config
    uint16 public protocolFee = 30;
    address public protocolWallet;
    bool isSellingEnabled = true;

    // contracts
    MineNft public mineNft;
    IERC20 public mineToken;
    IMineBans public mineBans;

    // events
    event ListingCreated(uint256 indexed tokenId, address indexed owner, uint256 price);

    event ListingPurchased(uint256 indexed tokenId, address indexed buyer, uint256 price);

    event ListingCanceled(uint256 indexed tokenId);

    constructor(
        address nftAddress,
        address tokenAddress,
        address bansAddress,
        address _protocolWallet
    ) {
        mineNft = MineNft(nftAddress);
        mineToken = IERC20(tokenAddress);
        mineBans = IMineBans(bansAddress);
        protocolWallet = _protocolWallet;
    }

    function addListing(uint256 tokenId, uint256 price) external whenNotPaused {
        require(isSellingEnabled, "MineMKT: Selling disabled");
        require(!_isBanned(tokenId), "MineMKT: Nft is banned");

        require(mineNft.ownerOf(tokenId) == msg.sender, "MineMKT: Not owner");
        require(mineNft.isApprovedForAll(msg.sender, address(this)), "MineMKT: Not approved");

        require(price > 0, "MineMKT: Invalid price");

        listings[tokenId] = Listing(msg.sender, price, block.timestamp, tokenId);
        userListings[msg.sender].add(tokenId);
        allListings.add(tokenId);

        mineNft.safeTransferFrom(msg.sender, address(this), tokenId);

        emit ListingCreated(tokenId, msg.sender, price);
    }

    function purchaseListing(uint256 tokenId) external whenNotPaused {
        require(isSellingEnabled, "MineMKT: Selling disabled");
        require(!_isBanned(tokenId), "MineMKT: Nft is banned");

        Listing memory listing = listings[tokenId];

        require(listing.owner != msg.sender, "MineMKT: Owner of the listing");

        uint256 price = listing.price;

        require(price > 0, "MineMKT: No listing for that nft");

        require(
            mineToken.allowance(msg.sender, address(this)) >= price,
            "MineMKT: Not enough allowance"
        );

        deleteListing(tokenId, msg.sender);

        uint256 fee = (price * protocolFee) / 1000;

        require(
            mineToken.transferFrom(msg.sender, listing.owner, price - fee),
            "MineMKT: Error transfering owner tokens"
        );

        require(
            mineToken.transferFrom(msg.sender, protocolWallet, fee),
            "MineMKT: Error transfering fee tokens"
        );

        mineNft.safeTransferFrom(address(this), msg.sender, tokenId);

        totalVolume += price;
        totalFees += fee;
        totalTrades++;
        emit ListingPurchased(tokenId, msg.sender, price);
    }

    function cancelListing(uint256 tokenId) external whenNotPaused {
        Listing memory listing = listings[tokenId];

        uint256 price = listing.price;

        require(price > 0, "MineMKT: No listing for that nft");

        require(listing.owner == msg.sender, "MineMKT: Not the owner of the listing");

        deleteListing(tokenId, msg.sender);

        mineNft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit ListingCanceled(tokenId);
    }

    function deleteListing(uint256 tokenId, address owner) private {
        delete listings[tokenId];
        userListings[owner].remove(tokenId);
        allListings.remove(tokenId);
    }

    /**
     * VIEWS
     */

    function getUserListingIDs(address _seller) public view returns (uint256[] memory) {
        return userListings[_seller].values();
    }

    function getUserListings(address _seller) external view returns (Listing[] memory) {
        uint256[] memory listingsIds = getUserListingIDs(_seller);

        Listing[] memory toReturn = new Listing[](listingsIds.length);

        for (uint256 i = 0; i < listingsIds.length; i++) {
            toReturn[i] = listings[listingsIds[i]];
        }

        return toReturn;
    }

    function getMarketListingIDs() public view returns (uint256[] memory) {
        return allListings.values();
    }

    function getMarketListings() external view returns (Listing[] memory) {
        uint256[] memory listingsIds = getMarketListingIDs();

        Listing[] memory toReturn = new Listing[](listingsIds.length);

        for (uint256 i = 0; i < listingsIds.length; i++) {
            toReturn[i] = listings[listingsIds[i]];
        }

        return toReturn;
    }

    function _isBanned(uint256 tokenId) private view returns (bool) {
        return mineBans.isBanned(tokenId);
    }

    /**
     * OVERRIDES
     */

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * CONFIG FUNCTIONS
     */

    /**
     * @dev allows changing the protocol fee percentage (30 means 3%)
     */
    function setProtocolFee(uint16 newFee) external onlyOwner {
        protocolFee = newFee;
    }

    /**
     * @dev allows changing the protocol fee wallet
     */
    function setProtocolFeeWallet(address newWallet) external onlyOwner {
        protocolWallet = newWallet;
    }

    /**
     * @dev controls disabling selling and buying
     */
    function setSellingEnabled(bool enabled) external onlyOwner {
        isSellingEnabled = enabled;
    }

    /**
     * @dev allows changing the bans contract
     */
    function setMineBans(address newAddress) external onlyOwner {
        mineBans = IMineBans(newAddress);
    }

    /**
     * ADMIN FUNCTIONS
     */

    /**
     * @dev allows withdrawing any token that is stuck in the contract
     * @param tokenAddress address of the token we are withdrawing
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

    /**
     * @dev allows withdrawing an NFT that is stuck in the contract
     */
    function emergencyWithdrawNft(uint256 tokenId) external onlyOwner {
        Listing memory listing = listings[tokenId];

        require(listing.price > 0, "MineMKT: No listing for that nft");

        deleteListing(tokenId, listing.owner);

        mineNft.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @dev pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
