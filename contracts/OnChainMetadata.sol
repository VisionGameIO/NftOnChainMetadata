// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

abstract contract OnChainMetadata {
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    struct Metadata {
        uint256 keyCount; // number of metadata keys
        mapping(bytes32 => string[]) data; // key => values
        mapping(bytes32 => uint256) valueCount; // key => number of values
    }

    struct PropertyKeyValuePair {
        bytes32 key;
        string value;
        bool isString;
    }

    Metadata _contractMetadata; // metadata for the contract
    Metadata _defaultTokenMetadata; // metadata for the token
    mapping(uint256 => Metadata) _tokenMetadata; // per-token metadata overrides

    bytes32 constant MetadataKeyName = "name";
    bytes32 constant MetadataKeyDescription = "description";
    bytes32 constant MetadataKeyImage = "image";
    bytes32 constant MetadataKeyExternalLink = "external_link";

    bytes32 constant MetadataKeyAnimationUrl = "animation_url";
    bytes32 constant MetadataKeyExternalUrl = "external_url";
    bytes32 constant MetadataKeyBackgroundColor = "background_color";
    bytes32 constant MetadataKeyYoutubeUrl = "youtube_url";
    bytes32 constant MetadataKeyAttributes = "attributes";
    bytes32 constant MetadataKeyAttributesTraitType = "trait_type";
    bytes32 constant MetadataKeyAttributesTraitValue = "trait_value";
    bytes32 constant MetadataKeyAttributesTraitDisplayType = "trait_display";
    bytes32 constant MetadataKeyAttributesMaxValue = "max_value";

    /**
     * @dev Get the values of a token metadata key.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     */
    function _getTokenMetadataValues(uint256 tokenId, bytes32 key) internal view returns (string[] storage) {
        string[] storage tokenValue = _tokenMetadata[tokenId].data[key];
        if (tokenValue.length != 0) {
            return tokenValue;
        } else {
            string[] storage defaultTokenValue = _defaultTokenMetadata.data[key];
            return defaultTokenValue;
        }
    }

    /**
     * @dev Get the first value of a token metadata key.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     */
    function _getTokenMetadataValue(uint256 tokenId, bytes32 key) internal view returns (string memory) {
        return _getFirstOrDefaultValue(_getTokenMetadataValues(tokenId, key));
    }

    /**
     * @dev Get the first value of a token metadata key as a PropertyKeyValuePair.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     * @param isString whether the property is a string and should be wrapped in quotes.
     */
    function _getTokenMetadataValueAsProperty(uint256 tokenId, bytes32 key, bool isString) internal view returns (PropertyKeyValuePair memory) {
        string memory value = _getTokenMetadataValue(tokenId, key);
        return PropertyKeyValuePair(key, value, isString);
    }

    ///
    /**
     * @dev Get the values of a default token metadata key.
     * @param key the contract metadata key.
     */
    function _getDefaultTokenMetadataValues(bytes32 key) internal view returns (string[] storage) {
        return _defaultTokenMetadata.data[key];
    }

    /**
     * @dev Get the first value of a default token metadata key.
     * @param key the contract metadata key.
     */
    function _getDefaultTokenMetadataValue(bytes32 key) internal view returns (string memory) {
        return _getFirstOrDefaultValue(_getDefaultTokenMetadataValues(key));
    }

    /**
     * @dev Get the first value of a contract metadata key.
     * @param key the contract metadata key.
     */
    function _getContractMetadataValue(bytes32 key) internal view returns (string memory) {
        return _getFirstOrDefaultValue(_contractMetadata.data[key]);
    }

    /**
     * @dev Get the first value of a contract metadata key key as PropertyKeyValuePair.
     * @param key the contract metadatakey.
     * @param isString whether the property is a string and should be wrapped in quotes.
     */
    function _getContractMetadataValueAsProperty(bytes32 key, bool isString) internal view returns (PropertyKeyValuePair memory) {
        string memory value = _getContractMetadataValue(key);
        return PropertyKeyValuePair(key, value, isString);
    }

    /**
     * @dev Set the values on a contract metadata key.
     * @param key the contract metadata key.
     * @param values the contract metadata values.
     */
    function _setContractMetadataValues(bytes32 key, string[] memory values) internal {
        Metadata storage meta = _contractMetadata;
        _setGenericMetadataValues(meta, key, values);
    }

    /**
     * @dev Set a single value on a contract metadata key.
     * @param key the contract metadata key.
     * @param value the contract metadata value.
     */
    function _setContractMetadataValue(bytes32 key, string memory value) internal {
        _setContractMetadataValues(key, _createSingleElementStringArray(value));
    }

    /**
     * @dev Set the values on a token metadata key.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     * @param values the token metadata values.
     */
    function _setTokenMetadataValues(uint256 tokenId, bytes32 key, string[] memory values) internal {
        Metadata storage meta = _tokenMetadata[tokenId];
        _setGenericMetadataValues(meta, key, values);
    }

    /**
     * @dev Set a single value on a token metadata key.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     * @param value the token metadata value.
     */
    function _setTokenMetadataValue(uint256 tokenId, bytes32 key, string memory value) internal {
        _setTokenMetadataValues(tokenId, key, _createSingleElementStringArray(value));
    }

    /**
     * @dev Set values on a given Metadata instance.
     * @param meta the metadata to modify.
     * @param key the token metadata key.
     * @param values the token metadata values.
     */
    function _addTokenMetadataValues(Metadata storage meta, bytes32 key, string[] memory values) internal {
        require(meta.valueCount[key] == 0, "OnChainMetadata: key already exists");
        meta.keyCount = meta.keyCount + 1;
        meta.data[key] = values;
        meta.valueCount[key] = values.length;
    }

    /**
     * @dev Set a single value on a given Metadata instance.
     * @param meta the metadata to modify.
     * @param key the token metadata key.
     * @param value the token metadata value.
     */
    function _addTokenMetadataValue(Metadata storage meta, bytes32 key, string memory value) internal {
        _addTokenMetadataValues(meta, key, _createSingleElementStringArray(value));
    }

    /**
     * @dev Set the values on a default token metadata key.
     * @param key the token metadata key.
     * @param values the token metadata values.
     */
    function _setDefaultTokenMetadataValues(bytes32 key, string[] memory values) internal {
        Metadata storage meta = _defaultTokenMetadata;
        _setGenericMetadataValues(meta, key, values);
    }

    /**
     * @dev Set a single value on a default token metadata key.
     * @param key the token metadata key.
     * @param value the token metadata value.
     */
    function _setDefaultTokenMetadataValue(bytes32 key, string memory value) internal {
        _setDefaultTokenMetadataValues(key, _createSingleElementStringArray(value));
    }

    function _createTokenURI(uint256 tokenId) internal view virtual returns (string memory) {
        PropertyKeyValuePair memory name = _getTokenMetadataValueAsProperty(tokenId, MetadataKeyName, true);
        PropertyKeyValuePair memory description = _getTokenMetadataValueAsProperty(tokenId, MetadataKeyDescription, true);

        string[] memory traitTypes = _getTokenMetadataValues(tokenId, MetadataKeyAttributesTraitType);
        string memory attributes = _createAttributesJson(tokenId, traitTypes);

        _requireBasicMetadata(name.value, description.value);

        PropertyKeyValuePair[] memory elements = new PropertyKeyValuePair[](8);
        elements[0] = name;
        elements[1] = description;
        elements[2] = _getTokenMetadataValueAsProperty(tokenId, MetadataKeyImage, true);
        elements[3] = _getTokenMetadataValueAsProperty(tokenId, MetadataKeyAnimationUrl, true);
        elements[4] = _getTokenMetadataValueAsProperty(tokenId, MetadataKeyExternalUrl, true);
        elements[5] = _getTokenMetadataValueAsProperty(tokenId, MetadataKeyBackgroundColor, true);
        elements[6] = _getTokenMetadataValueAsProperty(tokenId, MetadataKeyYoutubeUrl, true);
        elements[7] = PropertyKeyValuePair(MetadataKeyAttributes, attributes, false);
        return _createDataUrlFromJson(_createJson(elements));
    }

    function _createContractURI() internal view virtual returns (string memory) {
        PropertyKeyValuePair memory name = _getContractMetadataValueAsProperty(MetadataKeyName, true);
        PropertyKeyValuePair memory description = _getContractMetadataValueAsProperty(MetadataKeyDescription, true);

        _requireBasicMetadata(name.value, description.value);

        PropertyKeyValuePair[] memory elements = new PropertyKeyValuePair[](4);
        elements[0] = name;
        elements[1] = description;
        elements[2] = _getContractMetadataValueAsProperty(MetadataKeyImage, true);
        elements[3] = _getContractMetadataValueAsProperty(MetadataKeyExternalLink, true);
        return _createDataUrlFromJson(_createJson(elements));
    }

    function _createAttributesJson(uint256 tokenId, string[] memory traitTypes) internal view virtual returns (string memory) {
        if (traitTypes.length == 0) return "";

        string[] memory traitValues = _getTokenMetadataValues(tokenId, MetadataKeyAttributesTraitValue);
        string[] memory traitDisplayTypes = _getTokenMetadataValues(tokenId, MetadataKeyAttributesTraitDisplayType);
        string[] memory traitMaxValues = _getTokenMetadataValues(tokenId, MetadataKeyAttributesMaxValue);

        return _createAttributesJson(traitTypes, traitValues, traitDisplayTypes, traitMaxValues);
    }

    /**
     * Requirements:
     *
     * - traitTypes and traitValues must be of the same length
     */
    function _createAttributesJson(
        string[] memory traitTypes,
        string[] memory traitValues,
        string[] memory traitDisplayTypes,
        string[] memory traitMaxValues
    ) internal view virtual returns (string memory) {
        string memory attributes = "[";

        for (uint256 i = 0; i < traitTypes.length; i++) {
            string memory traitDisplayType = i < traitDisplayTypes.length ? traitDisplayTypes[i] : "";
            string memory traitMaxValue = i < traitMaxValues.length ? traitMaxValues[i] : "";
            bool isNumericTrait = _stringsEqual(traitDisplayType, "numeric") ||
                _stringsEqual(traitDisplayType, "boost_percentage") ||
                _stringsEqual(traitDisplayType, "boost_number") ||
                _stringsEqual(traitDisplayType, "display_type");

            string memory valueWrapper = '"';
            if (isNumericTrait) {
                valueWrapper = "";
            }

            attributes = string.concat(
                attributes,
                i > 0 ? "," : "",
                "{",
                _formatJsonAttribute('"trait_type":"', traitTypes[i], '",'),
                '"value":',
                valueWrapper,
                traitValues[i],
                valueWrapper,
                _formatJsonAttribute(',"display_type":"', traitDisplayType, '"'),
                _formatJsonAttribute(',"max_value":', traitMaxValue, ""),
                "}"
            );
        }

        attributes = string.concat(attributes, "]");
        return attributes;
    }

    function _createJson(PropertyKeyValuePair[] memory pairs) internal pure returns (string memory) {
        string memory result = "{";

        bool firstWritten = false;
        for (uint256 index = 0; index < pairs.length; index++) {
            PropertyKeyValuePair memory pair = pairs[index];
            if (bytes(pair.value).length == 0) continue;

            if (firstWritten) {
                result = string.concat(result, ",");
            }

            result = string.concat(
                result,
                '"',
                _bytes32toString(pair.key),
                '":',
                pair.isString ? '"' : "",
                pair.value,
                pair.isString ? '"' : ""
            );
            firstWritten = true;
        }

        result = string.concat(result, "}");
        return result;
    }

    function _createDataUrlFromJson(string memory json) internal pure returns (string memory) {
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    // https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    function _bytes32toString(bytes32 source) internal pure returns (string memory result) {
        uint8 length = 0;
        while (source[length] != 0 && length < 32) {
            length++;
        }
        assembly {
            result := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(result, 0x40))
            // store length in memory
            mstore(result, length)
            // write actual data
            mstore(add(result, 0x20), source)
        }
    }

    function _stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }

    function _getFirstOrDefaultValue(string[] storage array) internal view returns (string memory) {
        if (array.length > 0) {
            return array[0];
        } else {
            return "";
        }
    }

    function _createSingleElementStringArray(string memory value) internal pure returns (string[] memory) {
        string[] memory values = new string[](1);
        values[0] = value;
        return values;
    }

    function _requireBasicMetadata(string memory name, string memory description) private pure {
        require(bytes(name).length != 0, "OnChainMetadata: prop 'name' not set");
        require(bytes(description).length != 0, "OnChainMetadata: prop 'description' not set");
    }

    function _formatJsonAttribute(
        string memory propName,
        string memory propValue,
        string memory suffix
    ) private pure returns (string memory) {
        if (bytes(propValue).length == 0) return "";

        return string.concat(propName, propValue, suffix);
    }

    function _setGenericMetadataValues(Metadata storage metadata, bytes32 key, string[] memory values) private {
        if (metadata.valueCount[key] == 0) {
            metadata.keyCount = metadata.keyCount + 1;
        }
        metadata.data[key] = values;
        metadata.valueCount[key] = values.length;
    }
}
