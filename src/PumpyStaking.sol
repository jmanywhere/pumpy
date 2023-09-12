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
    uint256 public totalRewardsGiven;
    // uint256 public lastUpdated; // Timestamp of the last time the reward pool was updated    
    
    mapping(address _user => StakingInfo) public userInfo;
    //mapping(address => uint256) public stakedPumpyAmount;
    //mapping(address => uint256) public lastClaim;

    constructor(address _pumpy, address _nft) {
        pumpy = PUMPY(_pumpy);
        nft = PumpyNFT(_nft);
    }

    function deposit(uint256 nftId, uint256 amount) external {
        require(amount > 0, "You need to stake at least some tokens");
        
        if (userInfo[msg.sender].nftId == 0) {
            require(nft.ownerOf(nftId) == msg.sender, "You are not the owner of the NFT");
            nft.transferFrom(msg.sender, address(this), nftId);
        } else {
            require(userInfo[msg.sender].nftId == nftId, "You need to stake the same NFT");
            // @jmanywhere is it going to be always compound for multiple deposits ?
            claimRewards(true);
        }

        // Transfer toknes to the stake contract
        pumpy.transferFrom(msg.sender, address(this), amount);

        userInfo[msg.sender].nftId = nftId;
        userInfo[msg.sender].lastAction = block.timestamp;
        userInfo[msg.sender].depositAmount += amount;
        totalStakes += amount;

        emit Deposit(msg.sender, nftId, amount);
    }

    function claimRewards(bool isCompound) public {

        uint256 nftId = userInfo[msg.sender].nftId;
        uint256 pumpRet = nft.pumpRet(nft.tokenType(nftId));
        uint256 timeElapsed = block.timestamp - userInfo[msg.sender].lastAction;
        uint256 dailyRewards = (userInfo[msg.sender].depositAmount * pumpRet) / 1000;
        uint256 rewards = (dailyRewards * timeElapsed) / 86400/*oneDay*/ ;

        require(nftId != 0, "You are not staking any NFTs");
        require(block.timestamp > userInfo[msg.sender].lastAction + 1 days, "You can claim your rewards only once per day");
        require(rewardPool() >= rewards, "There are not enough PUMPY tokens to pay rewards");

        if (isCompound == true) {
            userInfo[msg.sender].depositAmount += rewards;
            totalStakes += rewards;

        } else {
            pumpy.transfer(msg.sender, rewards);
            userInfo[msg.sender].totalRewards += rewards;
            
        }

        totalRewardsGiven += rewards;
        userInfo[msg.sender].lastAction = block.timestamp;

        emit Claim(msg.sender, nftId, rewards);
    }

    function withdraw() external {
        require(userInfo[msg.sender].depositAmount > 0, "You are not staking any tokens");

        // Can they call the withdraw function on the same day they previously claimed rewards?
        claimRewards(false);

        uint256 amountToWithdraw = userInfo[msg.sender].depositAmount;
        uint256 nftId = userInfo[msg.sender].nftId;

        // Transfert tokens to the owner
        pumpy.transfer(msg.sender, amountToWithdraw);
        userInfo[msg.sender].depositAmount = 0;
        totalStakes -= amountToWithdraw;

        // Transfert NFT to the owner
        nft.transferFrom(address(this), msg.sender, nftId);
        userInfo[msg.sender].nftId = 0;

        emit Withdraw(msg.sender, nftId);
    }

    function estimatedEndTime() external pure returns (uint256) {
        // TODO: Implement function logic
        return 0;  // Placeholder return
    }

    function rewardPool() public view returns (uint256) {
        return pumpy.balanceOf(address(this)) - totalStakes;
    }

    /* QQ
    1. If the user is already staking an NFT, can they make additional deposits on the same NFT?
    2. Are rewards paid off the staked amount or the token balance?
    */
}
