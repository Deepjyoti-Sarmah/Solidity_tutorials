// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Encoding {
    function combineStrings() public pure returns(string memory) {
        return string(abi.encodePacked("Hi", "Hello"));
    }

    function encodeNumber() public pure returns(bytes memory) {
        bytes memory number = abi.encode(1);
        return number;
    }

    function encodeString() public pure returns(bytes memory) {
        bytes memory strings = abi.encode("Hello There");
        return strings;
    }

    function encodeStringPacked() public pure returns(bytes memory) {
        bytes memory strings = abi.encodePacked("Hello There");
        return strings;
    }

    function encodeStringBytes() public pure returns(bytes memory) {
        bytes memory stringsbytes = bytes("Hello There");
        return stringsbytes;
    }

    function decodeString() public  pure returns(string memory) {
        string memory someString = abi.decode(encodeString(), (string));
        return someString;
    }

    function multiEncode() public pure returns(bytes memory) {
        bytes memory stringEncode = abi.encode("Hi", "Hello");
        return stringEncode;
    }


    function multiDecode() public pure returns(string memory, string memory) {
        (string memory stringOne, string memory stringTwo) = abi.decode(multiEncode(), (string, string));
        return (stringOne, stringTwo);
    }

    function multiEncodePacked() public pure returns(bytes memory) {
        bytes memory stringEncode = abi.encodePacked("Hi", "Hello");
        return stringEncode;
    }

    function multiCastStringPacked() public pure returns(string memory) {
        string memory stringOne = string(multiEncodePacked());
        return (stringOne);
    }
}