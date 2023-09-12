// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import "./interfaces/IPumpyStaking.sol";
import "./Pumpy.sol";
import "./PumpyNFT.sol";

contract PumpyStaking is IPumpyStaking {
    PUMPY public pumpy;
    PumpyNFT public nft;

    // State variables
    uint256 public totalStakes;
    uint256 public rewardPool;
    uint256 public totalRewardsGiven;
    // uint256 public lastUpdated; // Timestamp of the last time the reward pool was updated    
    
    mapping(address _user => StakingInfo) public userInfo;
    mapping(address => uint256) public stakedPumpyAmount;
    mapping(address => uint256) public stakingStartTime;
    mapping(uint256 => uint256) public nftToROI;
    mapping(address => uint256) public lastClaim;

    constructor(address _pumpy, address _nft) {
        pumpy = PUMPY(_pumpy);
        nft = PumpyNFT(_nft);
    }

    function deposit(uint256 nftId, uint256 amount) external {
        require(amount > 0, "You need to stake at least some tokens");
        require(nft.ownerOf(nftId) == msg.sender, "You are not the owner of the NFT");
        require(userInfo[msg.sender].nftId == 0, "You are already staking an NFT");

        pumpy.transferFrom(msg.sender, address(this), amount);
        nft.transferFrom(msg.sender, address(this), nftId);

        userInfo[msg.sender].nftId = nftId;
        userInfo[msg.sender].lastAction = block.timestamp;
        stakedPumpyAmount[msg.sender] += amount;
        totalStakes += amount;

        lastClaim[msg.sender] = block.timestamp;
        // If user makes a deposit on the same NFT, claim rewards and compound them?
        emit Deposit(msg.sender, nftId, amount);
    }

    function claimRewards(bool isCompound) public {

        uint256 nftId = userInfo[msg.sender].nftId;
        uint256 pumpRet = nft.pumpRet(nft.tokenType(nftId));
        uint256 timeElapsed = block.timestamp - lastClaim[msg.sender];
        uint256 oneDay = 86400; // Number of seconds in a day
        uint256 dailyRewards = (stakedPumpyAmount[msg.sender] * pumpRet) / 1000;
        uint256 rewards = (dailyRewards * timeElapsed) / oneDay;

        require(nftId != 0, "You are not staking any NFTs");
        require(block.timestamp > lastClaim[msg.sender] + 1 days, "You can claim your rewards only once per day");
        require(pumpy.balanceOf(address(this)) >= rewards, "There are not enough PUMPY tokens to pay rewards");

        if (isCompound == true) {
            pumpy.transferFrom(msg.sender, address(this), rewards);
            stakedPumpyAmount[msg.sender] += rewards;
            totalStakes += rewards;

        } else {
            pumpy.transfer(msg.sender, rewards);
            // Update state variables
            totalRewardsGiven += rewards;
        }

        // rewardPool = pumpy.balanceOf(address(this)) - totalStakes;
        lastClaim[msg.sender] = block.timestamp;

        emit Claim(msg.sender, nftId, rewards);
    }

    function withdraw() external {
        require(stakedPumpyAmount[msg.sender] > 0, "You are not staking any tokens");

        // Can they call the withdraw function on the same day they previously claimed rewards?
        claimRewards(false);

        uint256 amountToWithdraw = stakedPumpyAmount[msg.sender];
        uint256 nftId = userInfo[msg.sender].nftId;

        require(pumpy.transfer(msg.sender, amountToWithdraw), "There are not enough PUMPY tokens to pay rewards");
        
        totalStakes -= amountToWithdraw;
        stakedPumpyAmount[msg.sender] = 0;

        nft.transferFrom(address(this), msg.sender, nftId); // return NFT to the owner

        emit Withdraw(msg.sender, nftId);
    }
 
     function estimatedEndTime() external view returns (uint256) {
        // TODO: Implement function logic
        return 0;  // Placeholder return
    }

    /* QQ
    1. If the user is already staking an NFT, can they make additional deposits on the same NFT?
    2. Are rewards paid off the staked amount or the token balance?
    */

}
