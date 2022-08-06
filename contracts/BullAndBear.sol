// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

// 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
// 10030
// 0x7A1A449206B6957f52e3eFE4e17b26Ee69a64E04
contract BullBear is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    KeeperCompatibleInterface,
    VRFConsumerBaseV2
{
    using Counters for Counters.Counter;

    event console_logs(int latestPrice, uint256 randomWord);
    event RequestId(uint256 indexed requestId);

    // VRF Variables
    VRFCoordinatorV2Interface Coordinator;
    uint64 s_subId;
    // address vrfCoordinatorAddress = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // address for the rinkeby network
    bytes32 gasLaneHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 4;
    uint32 numWords = 1;
    uint256 internal randomWord;

    uint256 public lastTimeStamp;
    uint256 private immutable i_interval;

    Counters.Counter private _tokenIdCounter;

    AggregatorV3Interface internal priceFeed;

    int internal currentPrice;

    string[] bears = [
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json",
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json"
    ];

    string[] bulls = [
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json",
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json"
    ];

    constructor(
        uint256 interval,
        address priceFeedAddress,
        uint64 subId,
        address vrfCoordinatorAddress
    ) ERC721("Bull&Bear", "BBTK") VRFConsumerBaseV2(vrfCoordinatorAddress) {
        Coordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        lastTimeStamp = block.timestamp;
        i_interval = interval;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        currentPrice = getLatestPrice();
        s_subId = subId;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomWord = randomWords[0];
        int latestPrice = getLatestPrice();
        if (currentPrice > latestPrice) {
            // bears
            for (uint i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bears[randomWords[0] % bears.length]);
            }
        } else {
            // bulls
            for (uint i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bulls[randomWords[0] % bulls.length]);
            }
        }
        currentPrice = latestPrice;
    }

    function getLatestPrice() public view returns (int) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, bulls[0]);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upKeepNeeded, bytes memory performUpData)
    {
        upKeepNeeded = (block.timestamp - lastTimeStamp) > i_interval;
        performUpData = "";
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) public override {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) revert("UpKeepNotNeeded");
        lastTimeStamp = block.timestamp;
        uint256 requestId = Coordinator.requestRandomWords(
            gasLaneHash,
            s_subId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RequestId(requestId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
