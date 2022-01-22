// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MineToken is ERC20, Pausable, Ownable {
    // whale feature variables
    bool public antiWhaleEnabled = false;
    uint256 public antiWhaleMaxTransfer = 100_000 * 10**18;
    mapping(address => bool) public whaleWhitelist;

    constructor() ERC20("MineCrypto Token", "MCR") {
        _mint(msg.sender, 90_000_000 * 10**18);
    }

    /**
     * ADMIN
     */

    /**
     * @dev pauses the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpauses the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * ANTI-WHALE ADMIN
     */

    /**
     * @dev toggles the anti whale feature
     */
    function antiWhaleToggle(bool value) public onlyOwner {
        antiWhaleEnabled = value;
    }

    /**
     * @dev changes the max transfer for whales
     */
    function setWhaleMax(uint256 value) public onlyOwner {
        antiWhaleMaxTransfer = value * 10**18;
    }

    /**
     * @dev removes an address from the whale whitelist
     */
    function addToWhaleWhitelist(address _address) public onlyOwner {
        whaleWhitelist[_address] = true;
    }

    /**
     * @dev adds an address to the whale whitelist
     */
    function removeFromWhaleWhitelist(address _address) public onlyOwner {
        whaleWhitelist[_address] = false;
    }

    /**
     * HOOKS
     */

    /**
     * @dev Allow pausing token transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        if (antiWhaleEnabled) {
            if (!whaleWhitelist[from] && !whaleWhitelist[to]) {
                require(amount <= antiWhaleMaxTransfer, "MCR: transfer is too big");
            }
        }
    }
}
