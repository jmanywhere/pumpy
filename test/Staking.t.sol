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

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    function getDepositAmount(address user) public view returns (uint256) {
        (uint256 depositAmount, , , , ) = staking.userInfo(user);
        return depositAmount;
    }


    function setUp() public {

        //
        // VALUES 
        //
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
        // END VALUES
        // Old values
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0x112233;

        // Instantiate contracts
        pumpy = new PUMPY();
        nft = new PumpyNFT(values, address(pumpy));
        staking = new PumpyStaking(address(pumpy), address(nft));

        pumpy.transfer(address(staking), 1_000_000 ether);
        
        nft.setNFTPrice(1 ether);
        pumpy.transfer(user1, 500 ether);
        pumpy.transfer(user2, 500 ether);
        pumpy.transfer(user3, 500 ether);        
        vm.prank(user1);
        pumpy.approve(address(nft), 500 ether);
        vm.prank(user2);
        pumpy.approve(address(nft), 500 ether);       
        vm.prank(user3);
        pumpy.approve(address(nft), 500 ether);  

        vm.prank(user1);
        nft.mint(12);        
        vm.prank(user1);
        nft.setApprovalForAll(address(staking), true);
        vm.prank(user2);
        nft.mint(48);
        vm.prank(user3);
        nft.mint(6);        
        vm.prank(user1);
        nft.setApprovalForAll(address(staking), true);
        vm.prank(user2);
        nft.setApprovalForAll(address(staking), true);        
        vm.prank(user3);
        nft.setApprovalForAll(address(staking), true);              
        // vm.prank(user1);
        // nft.approve(address(staking), 2);
        vm.prank(user1);
        pumpy.approve(address(staking), 500 ether);
        vm.prank(user2);
        pumpy.approve(address(staking), 500 ether);
        vm.prank(user3);
        pumpy.approve(address(staking), 500 ether);        
        // vm.prank(user1);
        // staking.deposit(1, 2 ether);
        
    }

    // WILL REFACTOR INTO MULTIPLE FUNCTIONS
    function test_deposit() public {

        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user1);
        assertEq(nft.balanceOf(user1), 12);
        assertEq(nft.totalSupply(), 66);
        assertEq(nft.tokenType(1), 2);
        assertEq(nft.tokenType(2), 3);
        assertEq(nft.tokenType(12), 6);
        assertEq(nft.tokenType(60), 6);        

        assertEq(staking.totalStakes(), 0 ether);
        assertEq(staking.rewardPool(), 1_000_000 ether);

        // Deposit
        vm.prank(user1);
        staking.deposit(12, 100 ether);
        vm.prank(user2);
        staking.deposit(60, 200 ether);
        vm.prank(user3);
        staking.deposit(61, 50 ether);        

        assertEq(staking.totalStakes(), 350 ether);
        assertEq(staking.rewardPool(), 1_000_000 ether);
        assertEq(nft.ownerOf(12), address(staking));

        assertEq(getDepositAmount(user1), 100 ether);

        assertEq(nft.ownerOf(60), address(staking));
        
        assertEq(getDepositAmount(user2), 200 ether);
        
        // 3 days later...
        vm.warp(block.timestamp + 3 days);

        // Second deposit by user3
        vm.prank(user3);
        staking.deposit(61, 50 ether); // claims with compound 3 rewards
        // assertEq(getDepositAmount(user3), 100 ether);
        
        // claimRewards (single)
        assertEq(pumpy.balanceOf(user1), 388 ether);
        vm.prank(user1);
        staking.claimRewards(false); // Claims 15 rewards
        // vm.prank(user1); staking.claimRewards(false); // verify cannot claim twice in same day

        assertEq(staking.totalRewardsGiven(), 18 ether);
        assertEq(pumpy.balanceOf(user1), 403 ether);
        assertEq(staking.rewardPool(),  999_982 ether);

        // Compound claimRewards
        vm.prank(user2);
        assertEq(getDepositAmount(user2), 200 ether);
        
        vm.prank(user2);
        staking.claimRewards(true);
        assertEq(getDepositAmount(user2), 230 ether);
        assertEq(staking.totalRewardsGiven(), 48 ether);
        // assertEq(staking.rewardPool(), 300 ether);

        // Test withdraw
        vm.warp(block.timestamp + 2 days);
        vm.prank(user1);
        staking.withdraw();
        assertEq(getDepositAmount(user1), 0 ether);


        // assertEq(staking.rewardPool(), 300 ether);
        
        // Testing state variables
        assertEq(staking.totalStakes(), 330 ether);

    //     //TBD
    //     // value 0x1 = binary 0001;
    //     // value 0x2 = binary 0010
    //     // value 0x3 = binary 0011
    //     // value 0xf = binary 1111
    //     // 0x12 & 0xf = 0x02
    //     // 0x12 >> 4 = 00010010 >> 4 = 00000001 = 0x01
    }
}
