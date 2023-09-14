// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "./interfaces/IPumpyStaking.sol";
import "./Pumpy.sol";
import "./PumpyNFT.sol";

contract PumpyStaking is IPumpyStaking, IERC721Receiver, ReentrancyGuard {
    PUMPY public pumpy;
    PumpyNFT public nft;

    // State variables
    uint256 public totalStakes;
    uint256 public totalRewardsGiven;
    uint256 public rewardsPerSecond;

    // uint256 public lastUpdated; // Timestamp of the last time the reward pool was updated    
    
    mapping(address _user => StakingInfo) public userInfo;
    uint256 private constant _BASE_PERCENT = 1000;
    uint private constant MAGNIFIER = 1e18;
    
    constructor(address _pumpy, address _nft) {
        pumpy = PUMPY(_pumpy);
        nft = PumpyNFT(_nft);
    }

    function onERC721Received (
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    function calculateRewardsPerSecond () internal {
        uint256 dailyRewards = (userInfo[msg.sender].depositAmount * userInfo[msg.sender].nftRoi) / _BASE_PERCENT;
        rewardsPerSecond += (dailyRewards / 1 days) * MAGNIFIER;
        
    }

    function deposit(uint256 nftId, uint256 amount) external nonReentrant {
        userInfo[msg.sender].nftRoi = nft.pumpRet(nft.tokenType(nftId));
        if (amount <= 0)
            revert DepositAmount();
        
        if (userInfo[msg.sender].nftId == 0) {
            if (nft.ownerOf(nftId) != msg.sender)
                revert DepositOwnerNFT(nft.ownerOf(nftId), msg.sender);
            nft.safeTransferFrom(msg.sender, address(this), nftId);
        } else {
            if (userInfo[msg.sender].nftId != nftId)
                revert DepositSameNFT();
            claimRewards(false);
        }

        // Transfer toknes to the stake contract
        pumpy.transferFrom(msg.sender, address(this), amount);

        userInfo[msg.sender].nftId = nftId;
        userInfo[msg.sender].lastAction = block.timestamp;
        userInfo[msg.sender].depositAmount += amount;
        totalStakes += amount;
        calculateRewardsPerSecond();

        emit Deposit(msg.sender, nftId, amount);
    }

    function claimRewards(bool isCompound) public {
        uint256 nftId = userInfo[msg.sender].nftId;
        uint256 timeElapsed = block.timestamp - userInfo[msg.sender].lastAction;
        uint256 dailyRewards = (userInfo[msg.sender].depositAmount * userInfo[msg.sender].nftRoi) / _BASE_PERCENT;
        uint256 rewards = (dailyRewards * timeElapsed) / 1 days;

        if (userInfo[msg.sender].nftId == 0) 
            revert ClaimStakeNFT();
        
        if (block.timestamp <= userInfo[msg.sender].lastAction)
            revert ClaimLastAction();

        if (rewardPool() < rewards)
            revert ClaimRewardPool(rewardPool(), rewards);

        totalRewardsGiven += rewards;
        userInfo[msg.sender].lastAction = block.timestamp;

        emit Claim(msg.sender, nftId, rewards, isCompound);

        if (isCompound == true) {
            userInfo[msg.sender].depositAmount += rewards;
            totalStakes += rewards;
        } else {
            pumpy.transfer(msg.sender, rewards);
            userInfo[msg.sender].totalRewards += rewards;   
        }
    }

    function withdraw() external {
        if (userInfo[msg.sender].depositAmount <= 0)
            revert WithdrawTokensAmount();

        claimRewards(false);

        uint256 amountToWithdraw = userInfo[msg.sender].depositAmount;
        uint256 nftId = userInfo[msg.sender].nftId;

        // Update State
        userInfo[msg.sender].depositAmount = 0;
        userInfo[msg.sender].nftId = 0;
        totalStakes -= amountToWithdraw;

        emit Withdraw(msg.sender, nftId);

        // Transfers
        pumpy.transfer(msg.sender, amountToWithdraw);
        nft.transferFrom(address(this), msg.sender, nftId);
    }

    function estimatedEndTime() external view returns (uint256) {
        uint256 endTime = block.timestamp + (rewardPool() * MAGNIFIER / rewardsPerSecond);
        return endTime;
    }

    function rewardPool() public view returns (uint256) {
        return pumpy.balanceOf(address(this)) - totalStakes;
    }
 
}