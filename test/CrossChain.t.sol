// SPDX-License-Identifier:MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";

import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract CrossChainTest is Test {
    address owner = makeAddr("owner");
    address ziad = makeAddr("ziad");
    CCIPLocalSimulatorFork public simulator;
    uint256 private constant SEND_VALUE = 1e5;

    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;

    RebaseTokenPool sepoliaPool;
    RebaseTokenPool arbSepoliaPool;

    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;

    Vault vault;

    function setUp() public {
        address[] memory allowlist = new address[](0);

        // create blockchain forks
        sepoliaFork = vm.createSelectFork("sepolia-eth");
        arbSepoliaFork = vm.createFork("arb-sepolia");

        simulator = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(simulator));

        // Deploy and configure on Sepolia
        sepoliaNetworkDetails = simulator.getNetworkDetails(block.chainid);
        vm.startPrank(owner);

        sepoliaToken = new RebaseToken();

        sepoliaPool = new RebaseTokenPool(
            IERC20(address(sepoliaToken)),
            allowlist,
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );

        // deploy the vault
        vault = new Vault(IRebaseToken(address(sepoliaToken)));

        // add reward to the vault
        vm.deal(address(vault), 1e18);

        // Grant roles to the vault and pool
        sepoliaToken.grantMintAndBurnRole(address(vault));
        sepoliaToken.grantMintAndBurnRole(address(sepoliaPool));

        // Register the token in the registry module owner custom
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(sepoliaToken)
        );

        // Accept admin role and set the pool in the TokenAdminRegistry
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(sepoliaToken), address(sepoliaPool)
        );

        vm.stopPrank();

        // Deploy and configure on Arbitrum Sepolia
        vm.selectFork(arbSepoliaFork);

        vm.startPrank(owner);

        arbSepoliaNetworkDetails = simulator.getNetworkDetails(block.chainid);
        arbSepoliaToken = new RebaseToken();

        arbSepoliaPool = new RebaseTokenPool(
            IERC20(address(arbSepoliaToken)),
            allowlist,
            arbSepoliaNetworkDetails.rmnProxyAddress,
            arbSepoliaNetworkDetails.routerAddress
        );

        // Grant roles to the pool
        arbSepoliaToken.grantMintAndBurnRole(address(arbSepoliaPool));

        // Register the token in the registry module owner custom
        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(arbSepoliaToken)
        );

        // Accept admin role and set the pool in the TokenAdminRegistry
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(arbSepoliaToken), address(arbSepoliaPool)
        );

        vm.stopPrank();
    }
    /**
     * @notice This function configures the token pool on the local chain to interact with the remote pool.
     * @param fork The fork ID for the local chain.
     * @param localPool The local token pool instance.
     * @param remotePool The remote token pool instance.
     * @param remoteToken The remote RebaseToken instance.
     * @param remoteNetworkDetails The network details for the remote chain.
     */

    function configureTokenPool(
        uint256 fork,
        TokenPool localPool,
        TokenPool remotePool,
        IRebaseToken remoteToken,
        Register.NetworkDetails memory remoteNetworkDetails
    ) public {
        vm.selectFork(fork);
        vm.startPrank(owner);
        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(address(remotePool));

        bytes memory remoteTokenAddress = abi.encode(address(remoteToken));

        // Create the chain update to allow the local pool to interact with the remote pool
        TokenPool.ChainUpdate[] memory chainsToAdd = new TokenPool.ChainUpdate[](1);
        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteNetworkDetails.chainSelector,
            remotePoolAddresses: remotePoolAddresses,
            remoteTokenAddress: remoteTokenAddress,
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
        });
        uint64[] memory remoteChainSelectorsToRemove = new uint64[](0);
        localPool.applyChainUpdates(remoteChainSelectorsToRemove, chainsToAdd);
        vm.stopPrank();
    }
    /**
     * @notice  This function bridges a specified amount of tokens from the local chain to the remote chain.
     * @param amountToBridge The amount of tokens to bridge.
     * @param localFork The fork ID for the local chain.
     * @param remoteFork The fork ID for the remote chain.
     * @param localNetworkDetails The network details for the local chain.
     * @param remoteNetworkDetails The network details for the remote chain.
     * @param localToken The RebaseToken instance on the local chain.
     * @param remoteToken The RebaseToken instance on the remote chain.
     */

    function bridgeTokens(
        uint256 amountToBridge,
        uint256 localFork,
        uint256 remoteFork,
        Register.NetworkDetails memory localNetworkDetails,
        Register.NetworkDetails memory remoteNetworkDetails,
        RebaseToken localToken,
        RebaseToken remoteToken
    ) internal {
        vm.selectFork(localFork);
        vm.startPrank(ziad);
        // Ensure the sender has enough balance
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: address(localToken), amount: amountToBridge});

        // Approve the router to burn tokens on users behalf
        IERC20(address(localToken)).approve(localNetworkDetails.routerAddress, amountToBridge);

        // Create the message to send to the remote chain
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(ziad),
            data: abi.encode(""),
            tokenAmounts: tokenAmounts,
            feeToken: localNetworkDetails.linkAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 300_000}))
        });
        vm.stopPrank();

        uint256 fee =
            IRouterClient(localNetworkDetails.routerAddress).getFee(remoteNetworkDetails.chainSelector, message);
        // Give the user the fee amount of LINK
        simulator.requestLinkFromFaucet(ziad, fee);
        vm.startPrank(ziad);
        IERC20(localNetworkDetails.linkAddress).approve(localNetworkDetails.routerAddress, fee); // Approve the fee

        // log the values before bridging
        uint256 balanceBeforeBridge = IERC20(address(localToken)).balanceOf(ziad);

        IRouterClient(localNetworkDetails.routerAddress).ccipSend(remoteNetworkDetails.chainSelector, message); // Send the message
        uint256 sourceBalanceAfterBridge = IERC20(address(localToken)).balanceOf(ziad);

        assertEq(sourceBalanceAfterBridge, balanceBeforeBridge - amountToBridge);
        vm.stopPrank();

        vm.selectFork(remoteFork);
        // Pretend it takes 20 minutes to bridge the tokens
        vm.warp(block.timestamp + 20 minutes);
        // get initial balance on Arbitrum
        uint256 initialArbBalance = IERC20(address(remoteToken)).balanceOf(ziad);
        simulator.switchChainAndRouteMessage(remoteFork);
        uint256 destBalance = IERC20(address(remoteToken)).balanceOf(ziad);

        assertEq(destBalance, initialArbBalance + amountToBridge);
    }

    // @notice This function tests the bridging of all tokens between Sepolia and Arbitrum Sepolia.
    function testBridgeAllTokens() public {
        // Configure pools
        configureTokenPool(
            sepoliaFork, sepoliaPool, arbSepoliaPool, IRebaseToken(address(arbSepoliaToken)), arbSepoliaNetworkDetails
        );
        configureTokenPool(
            arbSepoliaFork, arbSepoliaPool, sepoliaPool, IRebaseToken(address(sepoliaToken)), sepoliaNetworkDetails
        );

        // Deposit
        vm.selectFork(sepoliaFork);
        vm.deal(ziad, SEND_VALUE);
        vm.prank(ziad);
        Vault(payable(address(vault))).deposit{value: SEND_VALUE}();

        uint256 startBalance = sepoliaToken.balanceOf(ziad);
        assertEq(startBalance, SEND_VALUE);

        // bridge the tokens
        bridgeTokens(
            SEND_VALUE,
            sepoliaFork,
            arbSepoliaFork,
            sepoliaNetworkDetails,
            arbSepoliaNetworkDetails,
            sepoliaToken,
            arbSepoliaToken
        );

        vm.selectFork(arbSepoliaFork);
        // wait 20 minutes for the interest to accrue
        vm.warp(block.timestamp + 20 minutes);
        uint256 destBalance = arbSepoliaToken.balanceOf(ziad);
        // bridge the tokens
        bridgeTokens(
            destBalance,
            arbSepoliaFork,
            sepoliaFork,
            arbSepoliaNetworkDetails,
            sepoliaNetworkDetails,
            arbSepoliaToken,
            sepoliaToken
        );
    }

    function testBridgeTwice() public {
        configureTokenPool(
            sepoliaFork, sepoliaPool, arbSepoliaPool, IRebaseToken(address(arbSepoliaToken)), arbSepoliaNetworkDetails
        );
        configureTokenPool(
            arbSepoliaFork, arbSepoliaPool, sepoliaPool, IRebaseToken(address(sepoliaToken)), sepoliaNetworkDetails
        );
        // We are working on the source chain (Sepolia)
        vm.selectFork(sepoliaFork);
        // Give the user some ETH
        vm.deal(ziad, SEND_VALUE);
        vm.startPrank(ziad);
        // Deposit to the vault and receive tokens
        Vault(payable(address(vault))).deposit{value: SEND_VALUE}();
        uint256 startBalance = sepoliaToken.balanceOf(ziad);
        assertEq(startBalance, SEND_VALUE);
        vm.stopPrank();
        // bridge half tokens to the destination chain
        // bridge the tokens
        bridgeTokens(
            SEND_VALUE / 2,
            sepoliaFork,
            arbSepoliaFork,
            sepoliaNetworkDetails,
            arbSepoliaNetworkDetails,
            sepoliaToken,
            arbSepoliaToken
        );
        // wait 20 minutes for the interest to accrue
        vm.selectFork(sepoliaFork);
        vm.warp(block.timestamp + 20 minutes);
        uint256 newSourceBalance = sepoliaToken.balanceOf(ziad);
        // bridge the tokens
        bridgeTokens(
            newSourceBalance,
            sepoliaFork,
            arbSepoliaFork,
            sepoliaNetworkDetails,
            arbSepoliaNetworkDetails,
            sepoliaToken,
            arbSepoliaToken
        );
        // bridge back ALL TOKENS to the source chain after 1 hour
        vm.selectFork(arbSepoliaFork);
        // wait an hour for the tokens to accrue interest on the destination chain
        vm.warp(block.timestamp + 3600);
        uint256 destBalance = arbSepoliaToken.balanceOf(ziad);
        bridgeTokens(
            destBalance,
            arbSepoliaFork,
            sepoliaFork,
            arbSepoliaNetworkDetails,
            sepoliaNetworkDetails,
            arbSepoliaToken,
            sepoliaToken
        );
    }
}
