// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {PumpyNFT} from "../src/PumpyNFT.sol";
import {PUMPY} from "../src/Pumpy.sol";

contract TestNFT is Test {
    PumpyNFT nft;
    PUMPY pumpy;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
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
        pumpy = new PUMPY();
        nft = new PumpyNFT(values, address(pumpy));

        nft.setNFTPrice(1 ether);
        pumpy.transfer(user1, 100 ether);
        pumpy.transfer(user2, 100 ether);
        vm.prank(user1);
        pumpy.approve(address(nft), 100 ether);
        vm.prank(user2);
        pumpy.approve(address(nft), 100 ether);
    }

    function test_mint() public {
        vm.prank(user1);
        nft.mint(2);

        assertEq(nft.balanceOf(user1), 2);
        assertEq(nft.totalSupply(), 2);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user1);
        assertEq(nft.tokenType(1), 2);
        assertEq(nft.tokenType(2), 3);

        nft.setUri("test/");

        assertEq(nft.tokenURI(1), "test/2");
        assertEq(nft.tokenURI(2), "test/3");

        vm.prank(user2);
        nft.mint(1);

        assertEq(nft.tokenURI(3), "test/5");
        assertEq(nft.tokenType(3), 5);

        vm.prank(user2);
        nft.mint(1);

        assertEq(nft.tokenURI(4), "test/2");
        assertEq(nft.tokenType(4), 2);
    }
}
