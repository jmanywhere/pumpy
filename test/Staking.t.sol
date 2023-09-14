//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/Pumpy.sol";
import "src/PumpyNFT.sol";
import "src/PumpyStaking.sol";

contract StakingTest is Test {
    PUMPY public pumpy;
    PumpyNFT public nft;
    PumpyStaking public staking;

    address user1;
    address user2;
    address user3;   

    function getDepositAmount(address user) public view returns (uint256) {
        (uint256 depositAmount, , , , ) = staking.userInfo(user);
        return depositAmount;
    }

    function getTotalRewards(address user) public view returns (uint256) {
        (, , , , uint256 totalRewards) = staking.userInfo(user);
        return totalRewards;
    }    

    function setUp() public {

        // Users
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");        

        // NFTs pool
        uint[] memory values = new uint[](11);
        values[
            0
        ] = 0x3224451213233112661131114655134522253121224131222111342223226233;
        values[
            1
        ] = 0x5233133312614634224242214523522111221511156312341132553125123413;
        values[
            2
        ] = 0x1322221312222111111155222213212412111432221512441222111111311312;
        values[
            3
        ] = 0x2361131511141313362221326211126223453261211242133211154514111632;
        values[
            4
        ] = 0x1523241162532341223425222122221213161122443415432412251112222533;
        values[
            5
        ] = 0x5243412115416441112623231412213143311642121316221222311423432162;
        values[
            6
        ] = 0x4215111342412122111132344212365111163422222223251311141131243622;
        values[
            7
        ] = 0x6254113244341121312321313122351125425223541212112245224522516161;
        values[
            8
        ] = 0x1212521226145312142212212211111524322232234533443514136254133433;
        values[
            9
        ] = 0x1212336222143213122312152212152233411112111122214421116411325225;
        values[10] = 0x32;

    //     //TBD
    //     // value 0x1 = binary 0001;
    //     // value 0x2 = binary 0010
    //     // value 0x3 = binary 0011
    //     // value 0xf = binary 1111
    //     // 0x12 & 0xf = 0x02
    //     // 0x12 >> 4 = 00010010 >> 4 = 00000001 = 0x01                

        // Instantiate contracts
        pumpy = new PUMPY();
        nft = new PumpyNFT(values, address(pumpy));
        staking = new PumpyStaking(address(pumpy), address(nft));

        // Set up initial state
        nft.setNFTPrice(1 ether);
        pumpy.transfer(address(staking), 100 ether);        
        pumpy.transfer(user1, 500 ether);
        pumpy.transfer(user2, 500 ether);
        pumpy.transfer(user3, 500 ether);

        // Set up user1
        vm.startPrank(user1);
        pumpy.approve(address(nft), 500 ether);        
        nft.mint(12);
        nft.setApprovalForAll(address(staking), true);
        pumpy.approve(address(staking), 500 ether);
        vm.stopPrank();

        // Set up user2
        vm.startPrank(user2);
        pumpy.approve(address(nft), 500 ether);        
        nft.mint(48);
        nft.setApprovalForAll(address(staking), true);
        pumpy.approve(address(staking), 500 ether);
        vm.stopPrank();        

        // Set up user3
        vm.startPrank(user3);
        pumpy.approve(address(nft), 500 ether);   
        nft.mint(6);        
        nft.setApprovalForAll(address(staking), true);              
        pumpy.approve(address(staking), 500 ether);
        vm.stopPrank();        
        
    }

    function test_rewardPool() public {
        assertEq(staking.rewardPool(), 100 ether);
    }

    function test_estimatedEndTime() public {
                  
        // Make deposits
        vm.prank(user1);
        staking.deposit(12, 100 ether);
        vm.prank(user2);
        staking.deposit(60, 200 ether);
        vm.prank(user3);
        staking.deposit(61, 50 ether);

        // rewardPool = 100 tokens
        // dailyRewards = 16 tokens: user1 gets 5 tokens; user2 gets 10 tokens; user3 gets 1 tokens
        // It'd take 6.25 days to deplete the reward pool = 540_000 seconds
        assertEq(staking.rewardsPerSecond(), 18_518_518_518_518_4 ether); // rewardsPerSecond * MAGNIFIER
        assertEq(staking.estimatedEndTime(), 540_001); // 540_000 + block.timestamp (1)

        // 3 days later
        vm.warp(block.timestamp + 3 days);
        assertEq(staking.rewardsPerSecond(), 18_518_518_518_518_4 ether); // rewardsPerSecond * MAGNIFIER
        vm.prank(user2);
        staking.deposit(60, 200 ether); // claims 30 tokens
        assertEq(getDepositAmount(user2), 400 ether);
        // rewardPool = 70 tokens
        // dailyRewards = 26 tokens: user1 gets 5 tokens; user2 gets 20 tokens; user3 gets 1 tokens
        assertEq(staking.rewardPool(),  70 ether);
        assertEq(staking.rewardsPerSecond(), 300_925_925_925_924 ether); // rewardsPerSecond * MAGNIFIER

        // 2 days later
        vm.warp(block.timestamp + 2 days);
        vm.prank(user2);
        staking.claimRewards(true); // claims and restakes 40 rewards (20 tokens/day * 2 days)
        // rewardPool = 30 tokens
        assertEq(staking.rewardPool(),  30 ether);
        assertEq(getDepositAmount(user2), 440 ether);
        pumpy.transfer(address(staking), 110 ether); // Injeting funds to rewardPool to make it to 140 tokens           
        // dailyRewards = 28 tokens: user1 gets 5 tokens; user2 gets 22 tokens; user3 gets 1 tokens
        // It'd take 5 days to deplete the reward pool = 432_000 seconds
        assertEq(staking.totalStakes(), 590 ether);
        assertEq(staking.rewardsPerSecond(), 324_074_074_074_072 ether); // rewardsPerSecond * MAGNIFIER
        assertEq(staking.estimatedEndTime(), (432_000 + block.timestamp));

        vm.prank(user1);
        // 5 days since its only deposit; has earned 5 rewards daily = 25 rewards
        staking.withdraw(); // Claims 25 rewards
        assertEq(staking.totalStakes(), 490 ether);
        assertEq(staking.rewardPool(), 115 ether); // 140 - 25
        // rewardPool = 115 tokens        
        // dailyRewards = 23 tokens: user1 gets 0 tokens; user2 gets 22 tokens; user3 gets 1 tokens
        // It'd take 5 days to deplete the reward pool = 432_000 seconds
        assertEq(staking.rewardsPerSecond(), 266_203_703_703_702 ether); // rewardsPerSecond * MAGNIFIER    
        assertEq(staking.estimatedEndTime(), (432_000 + block.timestamp));           

    }

    function test_deposit() public {
        // Make deposits
        vm.prank(user1);
        staking.deposit(12, 100 ether);
        vm.prank(user2);
        staking.deposit(60, 200 ether);
        vm.prank(user3);
        staking.deposit(61, 50 ether);

        assertEq(getDepositAmount(user1), 100 ether);
        assertEq(getDepositAmount(user2), 200 ether);
        assertEq(getDepositAmount(user3), 50 ether);

        assertEq(nft.ownerOf(12), address(staking));
        assertEq(nft.ownerOf(60), address(staking));
        assertEq(nft.ownerOf(61), address(staking));

        assertEq(staking.totalStakes(), 350 ether);

        // 3 days later
        vm.warp(block.timestamp + 3 days);
        vm.prank(user3);
        staking.deposit(61, 50 ether); // Second deposit & claims with compound 3 tokens (1 token/day)

        assertEq(getTotalRewards(user3), 3 ether);
        assertEq(staking.totalRewardsGiven(), 3 ether);
        assertEq(staking.rewardPool(),  97 ether); // initial reward pool (100) - 3 tokens
        assertEq(staking.totalStakes(), 400 ether);
        
        // assertEq(getDepositAmount(user3), 53 ether);
        // shoult it work since initial deposit (50) + implicit deposit (3 tokens)?
    }

    function test_claimRewards() public {
        test_deposit();

        // claimRewards (simple)
        vm.prank(user1);
        staking.claimRewards(false); // claims 15 rewards: 5 tokens/day * 3 days
        // vm.prank(user1); staking.claimRewards(false); // verified cannot claim twice in same day

        assertEq(getTotalRewards(user1), 15 ether);
        assertEq(staking.totalRewardsGiven(), 18 ether);
        assertEq(staking.rewardPool(), 82 ether);

        // claimRewards (compound)
        vm.prank(user2);
        staking.claimRewards(true); // claims 30 rewards: 10 tokens/day * 3 days, and restakes
        
        assertEq(getDepositAmount(user2), 230 ether);
        assertEq(staking.totalRewardsGiven(), 48 ether);
        assertEq(staking.rewardPool(), 52 ether);
        assertEq(staking.totalStakes(), 430 ether);

    }    
    function test_withdraw () public {

        test_claimRewards();
        
        vm.warp(block.timestamp + 2 days);
        vm.prank(user1);
        staking.withdraw(); // claims 10 rewards: 5 tokens/day * 2 days

        assertEq(getDepositAmount(user1), 0 ether);
        assertEq(staking.rewardPool(), 42 ether);
        assertEq(staking.totalStakes(), 330 ether);
    }
}
