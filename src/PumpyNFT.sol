// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/security/ReentrancyGuard.sol";

contract PumpyNFT is ERC721, ReentrancyGuard {
    mapping(uint _tokenId => uint _ROI) public pumpRet;
    uint constant MAX_SUPPLY = 10000;

    uint totalSupply;

    constructor() ERC721("PumpyNFT", "PUMPY_NFT") {}

    function mint(uint amount) external nonReentrant {
        for (uint i = 0; i < amount; i++) {
            uint id = totalSupply;
            totalSupply = id;
            _safeMint(msg.sender, id);
            pumpRet[id] = 50;
        }
    }
}
