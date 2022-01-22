// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// BASED ON: https://github.com/1inch/governance-contracts/blob/master/contracts/StepVesting.sol
contract StepVesting is Ownable {
    event ReceiverChanged(address oldWallet, address newWallet);

    // token to claim
    IERC20 public immutable token;

    // cliff & vesting config
    uint256 public immutable started;
    uint256 public immutable cliffDuration;
    uint256 public immutable stepDuration;
    uint256 public immutable cliffAmount;
    uint256 public immutable stepAmount;
    uint256 public immutable numOfSteps;
    address public receiver;

    // claimed amount
    uint256 public claimed;

    // address tha can clearExceedingFunds
    address public deployer;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "access denied");
        _;
    }

    modifier onlyReceiver() {
        require(msg.sender == receiver, "access denied");
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _started,
        uint256 _cliffDuration,
        uint256 _stepDuration,
        uint256 _cliffAmount,
        uint256 _stepAmount,
        uint256 _numOfSteps,
        address _receiver
    ) {
        deployer = msg.sender;

        token = _token;
        started = _started;
        cliffDuration = _cliffDuration;
        stepDuration = _stepDuration;
        cliffAmount = _cliffAmount;
        stepAmount = _stepAmount;
        numOfSteps = _numOfSteps;
        setReceiver(_receiver);
    }

    function available() public view returns (uint256) {
        return claimable() - claimed;
    }

    function claimable() public view returns (uint256) {
        if (block.timestamp < (started + cliffDuration)) {
            return 0;
        }

        uint256 passedSinceCliff = block.timestamp - (started + cliffDuration);
        uint256 stepsPassed = Math.min(numOfSteps, (passedSinceCliff / stepDuration));
        return cliffAmount + (stepsPassed * stepAmount);
    }

    function claim() external onlyReceiver {
        uint256 amount = available();
        require(amount > 0, "Nothing to claim");

        claimed = claimed + amount;
        
        token.transfer(msg.sender, amount);
    }

    /**
     * ADMIN FUNCTIONS
     */

    function setReceiver(address _receiver) public onlyOwner {
        require(_receiver != address(0), "Receiver is zero address");
        emit ReceiverChanged(receiver, _receiver);
        receiver = _receiver;
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
     * @dev Remove funds stuck after the vesting is completed
     */
    function clearExceedingFunds() external onlyDeployer {
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 exceedingFunds = (contractBalance + claimed) - totalVesting();

        require(exceedingFunds > 0, "No exceeding funds");

        token.transfer(msg.sender, exceedingFunds);
    }

    /**
     * @dev Delete deployer access to clearExceedingFunds
     */
    function deleteDeployer() external {
        require(msg.sender == owner() || msg.sender == deployer, "access denied");
        deployer = address(0);
    }

    /**
     * @dev Change deployer address
     */
    function changeDeployer(address newDeployer) external {
        require(msg.sender == owner() || msg.sender == deployer, "access denied");
        deployer = newDeployer;
    }

    /**
     * VIEWS FOR BETTER OBSERVABILITY
     */

    function totalVesting() public view returns (uint256) {
        return cliffAmount + (stepAmount * numOfSteps);
    }

    function cliffEnds() external view returns (uint256) {
        return started + cliffDuration;
    }

    function vestingEnds() external view returns (uint256) {
        return started + cliffDuration + (stepDuration * numOfSteps);
    }

    function nextClaim() external view returns (uint256) {
        if (block.timestamp < (started + cliffDuration)) {
            if (cliffAmount > 0) {
                return started + cliffDuration;
            } else {
                return started + cliffDuration + stepDuration;
            }
        }

        uint256 claimedWithoutCliff = claimed - cliffAmount;
        uint256 claimedPeriods = claimedWithoutCliff / stepAmount;
        uint256 lastClaimeableDate = started + cliffDuration + (claimedPeriods * stepDuration);

        return lastClaimeableDate + stepDuration;
    }
}
