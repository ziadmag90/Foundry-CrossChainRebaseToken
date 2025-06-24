// SPDX-License-Identifier:MIT
pragma solidity ^0.8.28;

import {IRebaseToken} from "./Interfaces/IRebaseToken.sol";

contract Vault {
    error Vault__RedeemFailed();

    IRebaseToken private immutable i_rebasetoken;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor(IRebaseToken _rebasetoken) {
        i_rebasetoken = _rebasetoken;
    }

    /**
     * @dev deposits ETH into the vault and mints rebase tokens to the user
     */
    function deposit() external payable {
        uint256 interestRate = i_rebasetoken.getInterestRate();
        i_rebasetoken.mint(msg.sender, msg.value, interestRate);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev redeems rebase token for the underlying asset
     * @param _amount the amount being redeemed
     */
    function redeem(uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = i_rebasetoken.balanceOf(msg.sender);
        }
        i_rebasetoken.burn(msg.sender, _amount);
        (bool success,) = payable(msg.sender).call{value: _amount}("");

        if (!success) {
            revert Vault__RedeemFailed();
        }

        emit Redeem(msg.sender, _amount);
    }

    // allows the contract to receive rewards
    receive() external payable {}

    // get the address of the rebase token
    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebasetoken);
    }
}
