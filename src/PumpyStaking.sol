// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import "./interfaces/IPumpyStaking.sol";

contract PumpyStaking is IPumpyStaking {
    PUMPY public pumpy;
    PumpyNFT public nft;
    
    mapping(address _user => StakingInfo) public userInfo;
    mapping(address => uint256) public stakedPumpyAmount;
    mapping(address => uint256) public stakingStartTime;
    mapping(uint256 => uint256) public nftToROI;
    
    constructor(address _pumpToken, address _pumpNFT) {
        pumpToken = IERC20(_pumpToken);
        pumpNFT = IERC721(_pumpNFT);
    }

    function deposit(uint256 nftId, uint256 amount) external {
        require(amount > 0, "You need to stake at least some tokens");
        require(nft.ownerOf(nftId) == msg.sender, "You are not the owner of the NFT");
        require(stakingInfo[_user].nftId == 0, "You are already staking an NFT");

        pumpy.transferFrom(msg.sender, address(this), amount);
        nft.transferFrom(msg.sender, address(this), nftId);

        userInfo[msg.sender].nftId = nftId;
        userInfo[msg.sender].lastAction = block.timestamp;
        stakedPumpyAmount[msg.sender] += amount;

        emit Deposit(msg.sender, nftId, amount);
    }

/**
    function claimRewards() external {
        require(stakedPumpAmount[msg.sender] > 0, "Not staking any tokens");

        uint256 elapsedTime = block.timestamp - stakingStartTime[msg.sender];
        uint256 rewardAmount = stakedPumpAmount[msg.sender] * elapsedTime;

        require(
            pumpToken.transfer(msg.sender, rewardAmount),
            "Failed to transfer rewards"
        );

        stakingStartTime[msg.sender] = block.timestamp; // reset staking start time for next claim

       emit Claim(msg.sender, nftId, rewardAmount);
    }

    function withdraw() external {
        require(stakedPumpAmount[msg.sender] > 0, "Not staking any tokens");

        // claimRewards(); // first claim any pending rewards

        uint256 amount = stakedPumpAmount[msg.sender];
        stakedPumpAmount[msg.sender] = 0;

        require(
            pumpToken.transfer(msg.sender, amount),
            "Failed to transfer tokens"
        );

        // uint256 nftId = pumpNFT.tokenOfOwnerByIndex(msg.sender, 0);
        // pumpNFT.transferFrom(address(this), msg.sender, nftId); // return NFT to the owner

        emit Withdraw(msg.sender, nftId);
    } 
 */

}
