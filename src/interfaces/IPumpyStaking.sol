// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPumpyStaking {
    //-------------------------------------------------------------------------
    // Type definitions
    //-------------------------------------------------------------------------
    struct StakingInfo {
        uint256 depositAmount;
        uint256 lastAction;
        uint256 nftId;
        uint256 nftRoi;
    }

    //-------------------------------------------------------------------------
    // Events
    //-------------------------------------------------------------------------

    event Deposit(
        address indexed user,
        uint256 indexed nftId,
        uint256 tokenAmount
    );
    event Withdraw(address indexed user, uint256 indexed nftId);
    event Claim(
        address indexed user,
        uint256 indexed nftId,
        uint256 rewardAmount
    );

    //-------------------------------------------------------------------------
    // Interface Functions
    //-------------------------------------------------------------------------
    /**
     * @notice Stakes PUMP tokens with an NFT to get daily ROI
     * @param nftId id of the NFT to stake
     * @param amount amount of PUMPY tokens to stake
     * @dev The NFT must be owned by the caller
     *      - Staking with another NFT ID is not possible
     *      - Adding more PUMPY tokens to an existing stake is only when NFT id matches
     *      - Adding more PUMPY compounds current rewards
     */
    function deposit(uint256 nftId, uint256 amount) external;

    /**
     * @notice Claims rewards for the caller and optionally compounds them
     * @param isCompound if true, rewards are claimed and added to the stake Deposit
     */
    function claimRewards(bool isCompound) external;

    /**
     * @notice Unstakes PUMPY tokens and returns the NFT to the caller
     * @dev Rewards are claimed
     * @dev Reset user position after withdraw
     */
    function withdraw() external;

    /**
     * @notice Returns the total amount of PUMPY tokens received by all users
     */
    function totalRewardsGiven() external view returns (uint256);

    /**
     * @notice Returns the total amount of PUMPY tokens staked by all users
     */
    function totalStakes() external view returns (uint256);

    /**
     * @notice Returns the extimated end time of the staking pool rewards
     * @dev with the help of an internal variable `rewardsPerSecond` we can calculate the end time
     */
    function estimatedEndTime() external view returns (uint256);

    /**
     * @notice Returns the total amount of PUMPY tokens in the staking pool that are designated to rewards
     * @dev PUMPY.balanceOf(this) - totalStakes()
     * -- INVARIANT --
     * @dev balance should only be  >= totalStakes()
     */
    function rewardPool() external view returns (uint256);
}
