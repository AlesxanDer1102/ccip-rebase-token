// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Rebase Token
 * @author Diego Alesxander
 * @notice This is a cross-chain rebase token that incentivises to deposit into a vault
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate that is the goblal interest rate  at the time of depositing
 */
contract RebaseToken is ERC20 {
    uint256 private s_interestRate = 5e10;

    constructor() ERC20("Rebase Token", "RBT") {}

    function setInterestRate(uint256 _interestRate) external {
        // Set interest rate
        s_interestRate = _interestRate;
    }
}
