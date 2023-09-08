// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import "./interfaces/IPumpyStaking.sol";

contract PumpyStaking is IPumpyStaking {
    IERC20 public pumpToken;
    IERC721 public pumpNFT;

    /*
     * user address of the user
     * returns struct StakingInfo
     */
    mapping(address _user => StakingInfo) public userInfo;
    mapping(address => uint256) public stakedPumpAmount;
    mapping(address => uint256) public stakingStartTime;
    mapping(uint256 => uint256) public nftToROI;

    constructor(address _pumpToken, address _pumpNFT) {
        pumpToken = IERC20(_pumpToken);
        pumpNFT = IERC721(_pumpNFT);
    }

    function stakePump(uint256 nftId, uint256 amount) external {
        require(
            pumpNFT.ownerOf(nftId) == msg.sender,
            "Not the owner of the NFT"
        );
        require(stakedPumpAmount[msg.sender] == 0, "Already staking");

        pumpToken.transferFrom(msg.sender, address(this), amount);

        stakedPumpAmount[msg.sender] = amount;
        stakingStartTime[msg.sender] = block.timestamp;

        pumpNFT.transferFrom(msg.sender, address(this), nftId); // Transfer NFT to contract for staking
    }

    function claimRewards() external {
        require(stakedPumpAmount[msg.sender] > 0, "Not staking any tokens");

        uint256 elapsedTime = block.timestamp - stakingStartTime[msg.sender];
        uint256 rewardAmount = stakedPumpAmount[msg.sender] * elapsedTime;

        require(
            pumpToken.transfer(msg.sender, rewardAmount),
            "Failed to transfer rewards"
        );

        stakingStartTime[msg.sender] = block.timestamp; // reset staking start time for next claim
    }

    function unstake() external {
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
    }
}
