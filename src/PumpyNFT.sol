// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {ERC721, Strings} from "openzeppelin/token/ERC721/ERC721.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

error PUMPY_NFT_SUPPLY_EXCEEDED();
error PUMPY_NFT_URI_SET();
error PUMPY_NFT_NOT_MINTED(uint tokenId);
error PUMPY_NFT__INVALID_PRICE();

contract PumpyNFT is ERC721, ReentrancyGuard, Ownable {
    //---------------------------------------------
    // Library usage
    //---------------------------------------------
    using Strings for uint256;

    //---------------------------------------------
    // State Variables
    //---------------------------------------------
    // Each token ID has an ROI type associated with it.
    mapping(uint _tokenId => uint _ROI) public tokenType;
    // Each ROI type has an value associated with it.
    // roiValue is in percentage with 1 decimal place.
    //      e.g. 5 = 0.5% / 10 = 1% / 20 = 2% / 30 = 3% / 40 = 4% / 50 = 5%
    mapping(uint tokenType => uint roiValue) public pumpRet;
    // DEAD WALLET (for burns)
    address constant DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    // baseURI, each roiType will have a different image
    string private _uri;
    // Max supply of NFTs - 650
    uint constant MAX_SUPPLY = 650;
    // This holds each Token's ROI type
    uint[] private _idPrompts;
    // Price of each NFT in PUMP (pumpy)
    uint public nftPrice;
    // Total supply of NFTs minted
    uint public totalSupply;
    // PUMP token
    IERC20 public pumpy;

    //---------------------------------------------
    // Events
    //---------------------------------------------
    event URISet(uint timestamp);
    event PriceSet(uint newPrice);

    //---------------------------------------------
    // Constructor
    //---------------------------------------------
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

    //---------------------------------------------
    // External Functions
    //---------------------------------------------

    /**
     * @notice Mint NFTs with their associated ROI type
     * @param amount - number of NFTs to mint
     */
    function mint(uint amount) external nonReentrant {
        if (totalSupply + amount > MAX_SUPPLY)
            revert PUMPY_NFT_SUPPLY_EXCEEDED();

        if (nftPrice == 0) revert PUMPY_NFT__INVALID_PRICE();
        uint cost = nftPrice * amount;
        pumpy.transferFrom(msg.sender, DEAD_WALLET, cost);

        for (uint i = 0; i < amount; i++) {
            uint id = totalSupply + 1;
            totalSupply = id;
            _safeMint(msg.sender, id);
            setVal(id);
        }
    }

    /**
     * @notice Set the baseURI for the NFTs to get the
     * @param uri - baseURI for the ROI types of each NFT id
     * @dev Only can be set once
     */
    function setUri(string memory uri) external onlyOwner {
        if (bytes(_uri).length != 0) revert PUMPY_NFT_URI_SET();
        _uri = uri;
        emit URISet(block.timestamp);
    }

    /**
     * @notice Sets the new price of each NFT in PUMP
     * @param _pumpyAmount - new price of each NFT in PUMP
     */
    function setNFTPrice(uint _pumpyAmount) external onlyOwner {
        nftPrice = _pumpyAmount;
        emit PriceSet(_pumpyAmount);
    }

    //---------------------------------------------
    // Internal / Private Functions
    //---------------------------------------------

    /**
     * @notice get the base URI for the NFT metadata
     * @return string - base URI - e.g. ipfs://<hash>/
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /**
     * @notice Sets the ROI type for the NFT
     * @param id - token ID
     * @dev This function is called when minting NFTs
     */
    function setVal(uint id) private {
        if (_idPrompts.length == 0) return;

        uint finalIndex = _idPrompts.length - 1;
        uint finalVal = _idPrompts[finalIndex];

        if (finalVal > 0) {
            uint roiId = finalVal & 0x0f;
            tokenType[id] = roiId;
            finalVal = finalVal >> 4;

            if (finalVal == 0) _idPrompts.pop();
            else _idPrompts[finalIndex] = finalVal;
        }
    }

    //---------------------------------------------
    // External VIEW Functions
    //---------------------------------------------

    /**
     * @notice get the metadata based on the token's ROI type the ID has
     * @param tokenId - token ID to check
     * @return string - metadata URI for the type
     */
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
}
