// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/OnChainMetadata.sol";

contract TestToken is ERC721, Ownable, OnChainMetadata {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    enum CreatureMood {
        Happy,
        Sad,
        Excited,
        Focused
    }

    struct CreatureTraits {
        CreatureMood mood;
        uint8 powerLevel;
        uint8 healthBonus;
        string emotion;
    }

    constructor() ERC721("Test NFT", "TST") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // Test stuff

    function safeMintWithTraits(address to, CreatureTraits calldata traits) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        Metadata storage meta = _tokenMetadata[tokenId];

        string[] memory traitTypes = new string[](4);
        traitTypes[0] = "Mood";
        traitTypes[1] = "Power Level";
        traitTypes[2] = "Health Bonus";
        traitTypes[3] = "Emotion";

        string[] memory traitDisplayTypes = new string[](4);
        traitDisplayTypes[0] = "numeric";
        traitDisplayTypes[1] = "numeric";
        traitDisplayTypes[2] = "boost_percentage";
        traitDisplayTypes[3] = "";

        string[] memory traitValues = new string[](4);
        traitValues[0] = Strings.toString(uint256(traits.mood));
        traitValues[1] = Strings.toString(traits.powerLevel);
        traitValues[2] = Strings.toString(traits.healthBonus);
        traitValues[3] = traits.emotion;

        _addTokenMetadataValues(meta, MetadataKeyAttributesTraitType, traitTypes);
        _addTokenMetadataValues(meta, MetadataKeyAttributesTraitDisplayType, traitDisplayTypes);
        _addTokenMetadataValues(meta, MetadataKeyAttributesTraitValue, traitValues);
    }

    function testDynamicTokenURI(uint256 tokenId) public view returns (string memory) {
        string memory name = _getTokenMetadataValue(tokenId, MetadataKeyName);
        string memory description = _getTokenMetadataValue(tokenId, MetadataKeyDescription);

        require(bytes(name).length != 0, "Token metadata field 'name' is not set");
        require(bytes(description).length != 0, "Token metadata field 'description' is not set");

        string memory animationUrl = string.concat(
            "http://ipfs.example.com/ipfs/?",
            "address=",
            Strings.toHexString(uint256(uint160(address(this)))),
            "&tokenId=",
            Strings.toString(tokenId)
        );
        PropertyKeyValuePair[] memory elements = new PropertyKeyValuePair[](3);
        elements[0] = PropertyKeyValuePair(MetadataKeyName, name, true);
        elements[1] = PropertyKeyValuePair(MetadataKeyDescription, description, true);
        elements[2] = PropertyKeyValuePair(MetadataKeyAnimationUrl, animationUrl, true);
        return _createDataUrlFromJson(_createJson(elements));
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return _createTokenURI(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return _createContractURI();
    }

    // Overrides

    function getTokenMetadataValues(uint256 tokenId, bytes32 key) public view returns (string[] memory) {
        return getTokenMetadataValues(tokenId, key);
    }

    function getTokenMetadataValue(uint256 tokenId, bytes32 key) public view returns (string memory) {
        return getTokenMetadataValue(tokenId, key);
    }

    function getDefaultTokenMetadataValues(bytes32 key) public view returns (string[] memory) {
        return _getDefaultTokenMetadataValues(key);
    }

    function getDefaultTokenMetadataValue(bytes32 key) public view returns (string memory) {
        return _getDefaultTokenMetadataValue(key);
    }

    function setDefaultTokenMetadataValues(bytes32 key, string[] memory values) public {
        _setDefaultTokenMetadataValues(key, values);
    }

    function setDefaultTokenMetadataValue(bytes32 key, string memory value) public {
        _setDefaultTokenMetadataValue(key, value);
    }

    function getContractMetadataValue(bytes32 key) public view returns (string memory) {
        return _getContractMetadataValue(key);
    }

    function setContractMetadataValue(bytes32 key, string memory value) public {
        _setContractMetadataValue(key, value);
    }
}
