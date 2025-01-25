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
    error RebaseToken__InterestRateCanOnlyDecrease(
        uint256 oldInterestRate,
        uint256 newInterestRate
    );

    uint256 private s_interestRate = 5e10;

    uint256 private constant PRECISION_FACTOR = 1e18;

    mapping(address => uint256) public s_userInterestRate;
    mapping(address => uint256) public s_userLastUpdatedTimestamp;

    event InterstRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") {}

    /**
     * @notice Set the interest rate in the contract
     * @param _newInterestRate the new interest rate to set
     * @dev The interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external {
        // Set interest rate
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(
                s_interestRate,
                _newInterestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit InterstRateSet(_newInterestRate);
    }

    /**
     * @notice Mint the user tokens when they deposit into the vault
     * @param _to The user to mint the tokens to
     * @param _amount The amount of tokens to mint
     */

    function mint(address _to, uint256 _amount) external {
        _mintAccuratedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice calculate the balance of the user including the interest
     * @param _user  The user to get the balance of
     * @return The balance of the user including the interest
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // get the current principal balance of the user (the number of tokens that have actually been minted to the user)
        return
            (super.balanceOf(_user) *
                _calculateUserAccumulatedInterestSinceLastUpdate(_user)) /
            PRECISION_FACTOR;
    }

    /**
     * @notice Calculate the interest that has accumulated since the last update
     * @param _user  The user to calculate the interest accumulated
     * @return The interest that has accumulated since the last update
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256 linearInterest) {
        uint256 timeElapsed = block.timestamp -
            s_userLastUpdatedTimestamp[_user];
        linearInterest =
            PRECISION_FACTOR +
            (s_userLastUpdatedTimestamp[_user] * timeElapsed);
    }

    function _mintAccuratedInterest(address _to) internal {
        // find their current balance of rebase tokens that have been minted to the user --> principal balance
        // calculate theit current balance including interest  -> balanceOf
        // calculate the number of tokens need to be minted to the user
        // call mint to mint the token to the user
        s_userLastUpdatedTimestamp[_to] = block.timestamp;

        _mint(_to, interest);
    }

    /**
     * @notice Get the interest rate for the user
     * @param _user the user to get the interest rate
     * @return The interest rate for the user
     */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
