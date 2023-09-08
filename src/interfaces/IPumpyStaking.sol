// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPumpyStaking {
    
    function stake(uint256 nftId, uint256 amount) external;
    
    function claimRewards() external;
    
    function unstake() external;
    
    function stakedAmount(address user) external view returns (uint256);
    
    function stakingStartTime(address user) external view returns (uint256);
}
