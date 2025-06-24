// SPDX-License-Identifier:MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";

import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

// This contract is used to deploy the rebase token and the pool
contract TokenAndPoolDeployer is Script {
    function run() external returns (RebaseToken token, RebaseTokenPool pool) {
        CCIPLocalSimulatorFork simulator = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory networkDetails = simulator.getNetworkDetails(block.chainid);
        address[] memory allowlist = new address[](0);
        vm.startBroadcast();
        token = new RebaseToken();
        pool = new RebaseTokenPool(
            IERC20(address(token)), allowlist, networkDetails.rmnProxyAddress, networkDetails.routerAddress
        );
        vm.stopBroadcast();
    }
}

// This contract is used to set the permissions for the rebase token and the pool
contract SetPermissions is Script {
    function grantRole(address token, address pool) public {
        vm.startBroadcast();
        IRebaseToken(token).grantMintAndBurnRole(address(pool));
        vm.stopBroadcast();
    }

    function setAdmin(address token, address pool) public {
        CCIPLocalSimulatorFork simulator = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory networkDetails = simulator.getNetworkDetails(block.chainid);
        vm.startBroadcast();
        RegistryModuleOwnerCustom(networkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(token));
        TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(token));
        TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress).setPool(address(token), address(pool));
        vm.stopBroadcast();
    }
}

// This contract is used to deploy the vault and set the mint and burn roles for the rebase token
contract VaultDeployer is Script {
    function run(address _rebaseToken) external returns (Vault vault) {
        vm.startBroadcast();
        vault = new Vault(IRebaseToken(_rebaseToken));
        IRebaseToken(_rebaseToken).grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
    }
}
