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

    function setUp() public {
        pumpy = new PUMPY();
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0x112233;
        nft = new PumpyNFT(ids, address(pumpy));
        staking = new PumpyStaking(address(pumpy), address(nft));
    }

    function test_deposit() public {
        //TBD
        // value 0x1 = binary 0001
        // value 0x2 = binary 0010
        // value 0x3 = binary 0011
        // value 0xf = binary 1111
        // 0x12 & 0xf = 0x02
        // 0x12 >> 4 = 00010010 >> 4 = 00000001 = 0x01
    }
}