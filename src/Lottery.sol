//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Lottery
 * @author Marcus Marinelli
 * @notice This contract is a lottery contract
 * @dev This contract implements Chainlink VRF v2
 */
contract Lottery {
    uint256 private s_entryFee;
    address private s_owner;
    address payable[] private s_participants;

    /** Events */
    event LotteryEntered(address indexed participant);

    error Lottery__NotOwner();
    error Lottery__InsufficientFunds();

    constructor(uint256 entryFee) {
        s_entryFee = entryFee;
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert Lottery__NotOwner();
        _;
    }

    function enterLottery() external payable {
        if (msg.value < s_entryFee) revert Lottery__InsufficientFunds();

        s_participants.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    /**
     * Setter functions
     */
    function setEntryFee(uint256 newEntryFee) external onlyOwner {
        s_entryFee = newEntryFee;
    }

    /**
     * Getter functions
     */
    function getEntryFee() public view returns (uint256) {
        return s_entryFee;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }
}
