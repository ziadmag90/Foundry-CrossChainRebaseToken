//SPDX-License-Identifier:MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract BridgeTokensScript is Script {
    function run(
        address receiverAddress,
        uint64 destinationChainSelector,
        address tokenToSendAddress,
        uint256 amountToSend,
        address linkTokenAddress,
        address routerAddress
    ) external {
        vm.startBroadcast();
        // Prepare the token amounts to be sent
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: tokenToSendAddress, amount: amountToSend});

        // Prepare the message to be sent
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiverAddress),
            data: abi.encode(""),
            tokenAmounts: tokenAmounts,
            feeToken: linkTokenAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 0}))
        });

        // get the fee for sending the message
        uint256 fee = IRouterClient(routerAddress).getFee(destinationChainSelector, message);
        // Approve the link token for the router
        IERC20(linkTokenAddress).approve(routerAddress, fee);
        // Approve the token to be sent for the router
        IERC20(tokenToSendAddress).approve(routerAddress, amountToSend);
        // Send the message
        IRouterClient(routerAddress).ccipSend(destinationChainSelector, message);
        vm.stopBroadcast();
    }
}
