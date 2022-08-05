// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract BullBear is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    KeeperCompatibleInterface
{
    using Counters for Counters.Counter;

    uint256 public lastTimeStamp;
    uint256 private immutable i_interval;

    Counters.Counter private _tokenIdCounter;

    constructor(uint256 interval) ERC721("Bull&Bear", "BBTK") {
        lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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
