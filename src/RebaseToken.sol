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
     * @notice Get the principal balance of the user
     * @param _user The user to get the principal balance of
     */
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
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
     * @notice Burn the user tokens when they withdraw from the vault
     * @param _from the user to burn the tokens from
     * @param _amount  the amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _mintAccuratedInterest(_from);
        _burn(_from, _amount);
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
     * @notice Transfer tokens from one user to another
     * @param _recipient  The recipient of the tokens
     * @param _amount  The amount of tokens to transfer
     * @return true if the transfer is successful
     */
    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccuratedInterest(msg.sender);
        _mintAccuratedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Transfer tokens from one user to another
     * @param _sender  The sender of the tokens
     * @param _recipient  The recipient of the tokens
     * @param _amount  The amount of tokens to transfer
     * @return true if the transfer is successful
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccuratedInterest(_sender);
        _mintAccuratedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice Calculate the interest that has accumulated since the last update
     * @param _user  The user to calculate the interest accumulated
     * @return  linearInterest The interest that has accumulated since the last update
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256 linearInterest) {
        uint256 timeElapsed = block.timestamp -
            s_userLastUpdatedTimestamp[_user];
        linearInterest =
            PRECISION_FACTOR +
            (s_userInterestRate[_user] * timeElapsed);
    }

    /**
     * @notice Mint the Accurated interest to the user since the last time they interact with the protocol (eg, mint, deposit, withdraw)
     * @param _user The user to mint the tokens to
     */

    function _mintAccuratedInterest(address _user) internal {
        // find their current balance of rebase tokens that have been minted to the user --> principal balance
        uint256 previousPrincipalBalance = super.balanceOf(_user);
        // calculate theit current balance including interest  -> balanceOf
        uint256 currentBalance = balanceOf(_user);
        // calculate the number of tokens need to be minted to the user
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;

        s_userLastUpdatedTimestamp[_user] = block.timestamp;

        // call mint to mint the token to the user
        _mint(_user, balanceIncrease);
    }

    /**
     * @notice Get the interest rate that is current set in the contract. Any future deposit will recieve this interest rate
     * @return The interest rate for the contract
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
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
