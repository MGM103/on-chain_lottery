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

    constructor(uint256 entryFee) {
        s_entryFee = entryFee;
    }

    function enterLottery() public payable {}

    /** Setter functions */
    function setEntryFee(uint256 newEntryFee) external {
        s_entryFee = newEntryFee;
    }

    /** Getter functions */
    function getEntryFee() public view returns (uint256) {
        return s_entryFee;
    }
}
