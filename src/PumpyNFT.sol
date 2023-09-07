// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {ERC721, Strings} from "openzeppelin/token/ERC721/ERC721.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import "forge-std/console.sol";

error PUMPY_NFT_SUPPLY_EXCEEDED();
error PUMPY_NFT_URI_SET();
error PUMPY_NFT_NOT_MINTED(uint tokenId);

contract PumpyNFT is ERC721, ReentrancyGuard, Ownable {
    using Strings for uint256;
    mapping(uint _tokenId => uint _ROI) public tokenType;
    mapping(uint tokenType => uint roiValue) public pumpRet;
    string private _uri;
    uint constant MAX_SUPPLY = 10000;
    uint[] private _idPrompts;
    uint public nftPrice;

    uint public totalSupply;
    IERC20 public pumpy;

    constructor(
        uint[] memory ids,
        address _pumpy
    ) ERC721("PumpyNFT", "PUMPY_NFT") {
        pumpy = IERC20(_pumpy);
        _idPrompts = ids;
        pumpRet[1] = 5;
        pumpRet[2] = 10;
        pumpRet[3] = 20;
        pumpRet[4] = 30;
        pumpRet[5] = 40;
        pumpRet[6] = 50;
    }

    function mint(uint amount) external nonReentrant {
        if (totalSupply + amount > MAX_SUPPLY)
            revert PUMPY_NFT_SUPPLY_EXCEEDED();

        for (uint i = 0; i < amount; i++) {
            uint id = totalSupply + 1;
            totalSupply = id;
            _safeMint(msg.sender, id);
            setVal(id);
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        uint promptType = tokenType[tokenId];
        if (promptType == 0) revert PUMPY_NFT_NOT_MINTED(tokenId);
        // Only have 6 different types of images based on the return value
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, promptType.toString()))
                : "";
    }

    function setUri(string memory uri) external onlyOwner {
        if (bytes(_uri).length != 0) revert PUMPY_NFT_URI_SET();
        _uri = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setVal(uint id) private {
        if (_idPrompts.length == 0) return;

        uint finalIndex = _idPrompts.length - 1;
        uint finalVal = _idPrompts[finalIndex];

        if (finalVal > 0) {
            uint roiId = finalVal & 0x0f;
            tokenType[id] = roiId;
            finalVal = finalVal >> 4;
            _idPrompts[finalIndex] = finalVal;
            if (_idPrompts[finalIndex] == 0) {
                _idPrompts.pop();
            }
        }
    }
}
