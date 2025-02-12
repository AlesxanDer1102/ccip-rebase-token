// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    error Vault__RedeemFailed();

    IRebaseToken private immutable i_rebaseToken;

    event Deposited(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    /**
     * @notice Allows user to deposit ETH into the vault and mint rebase tokens in return
     */
    function deposit() external payable {
        // 1.- we need to use the amount of ETH the user has sent to mint tokens to the user
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    /**
     *
     * @notice Allows user to redeem their rebase tokens for ETG
     * @param _amount the amount of rebase tokens to redeem
     */
    function redeem(uint256 _amount) external {
        //1.- burn tokens
        i_rebaseToken.burn(msg.sender, _amount);
        //2.- transfer ETH to the user
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice Get the address of the rebase token
     */
    function getRebaseTokenAdress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
