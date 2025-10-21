// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract HelloWorld {
    string public message;

    event MessageSet(string newMessage);

    constructor() {
        message = "Hello, Rice Dev!";
    }

    function setMessage(string memory _message) public {
        message = _message;
        emit MessageSet(_message);
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}
