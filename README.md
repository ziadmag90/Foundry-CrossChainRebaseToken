# Foundry Cross Chain Rebase Token

## About

This project is a cross-chain rebase token where users can deposit ETH in exchange for rebase tokens which accrue rewards over time. It demonstrates advanced Solidity, Foundry, and Chainlink CCIP cross-chain development.

---

## Table of Contents

- [About](#about)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Start a local node](#start-a-local-node)
  - [Deploy](#deploy)
  - [Deploy - Other Network](#deploy---other-network)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Deployment to a testnet or mainnet](#deployment-to-a-testnet-or-mainnet)
  - [Scripts](#scripts)
  - [Estimate gas](#estimate-gas)
- [Formatting](#formatting)
- [Thank you!](#thank-you)

---

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [foundry](https://getfoundry.sh/)

## Quickstart

```sh
git clone https://github.com/ziadmag90/Foundry-CrossChainRebaseToken.git
cd cross-chain-rebase-token
forge build
```

# Usage

## Start a local node

```sh
anvil
```

## Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

```sh
forge deploy
```

## Deploy - Other Network

[See below](#deployment-to-a-testnet-or-mainnet)

## Testing

We talk about 4 test tiers on Updraft:

1. Unit
2. Integration
3. Forked
4. Staging

In this repo we cover #1 and Fuzzing.

```sh
forge test
```

### Test Coverage

```sh
forge coverage
forge coverage --report debug
```

# Deployment to a testnet or mainnet

1. Setup environment variables

Set your `SEPOLIA_RPC_URL` as an environment variable. You can add it to a `.env` file, similar to `.env.example`.

- `SEPOLIA_RPC_URL`: The URL of your Sepolia testnet node (get one from [Alchemy](https://alchemy.com/?a=673c802981)).

**Wallet Management:**

For better security, use Foundry's wallet management with `cast wallet import` instead of storing your private key in plain text.

- Import your private key interactively:

```sh
cast wallet import wallet-name --interactive
```

- This will prompt you to enter your private key securely and store it in the Foundry keystore.
- When running scripts or sending transactions, you can use `--account <wallet-name>` to reference your imported wallet.

Example:

```sh
forge script script/Deployer.s.sol --rpc-url $SEPOLIA_RPC_URL --account wallet-name --broadcast
```

2. Get testnet ETH

Use [faucets.chain.link](https://faucets.chain.link/) to get Sepolia ETH.

3. Deploy

```sh
forge script script/Deployer.s.sol --rpc-url $SEPOLIA_RPC_URL --account wallet-name --broadcast
```

## Scripts

You can use the `cast` command to interact with the contract.

For example, on Sepolia:

- Get some RebaseTokens

```sh
cast send <vault-contract-address> "deposit()" --value 0.1ether --rpc-url $SEPOLIA_RPC_URL --account wallet-name
```

- Redeem RebaseTokens for ETH

```sh
cast send <vault-contract-address> "redeem(uint256)" 10000000000000000 --rpc-url $SEPOLIA_RPC_URL --account wallet-name
```

## Estimate gas

```sh
forge snapshot
```

# Formatting

```sh
forge fmt
```

# Thank you!

---

## Project design and assumptions

- This project is a cross-chain rebase token that integrates Chainlink CCIP to enable users to bridge their tokens cross-chain.
- Rewards are assumed to be in the contract.
- Protocol rewards early users and users who bridge to L2.
  - The interest rate decreases discretely.
  - The interest rate when a user bridges is bridged with them and stays static.
- You can only deposit and withdraw on the L1.
- You cannot earn interest in the time while bridging.
- Don't forget to bridge back the amount of interest accrued on the destination chain in that time.

---

## 🚀 Deployed Contract Addresses

| Network          | Rebase Token Address                         | Vault Address                                |
| ---------------- | -------------------------------------------- | -------------------------------------------- |
| Ethereum Sepolia | `0x479A2426F8BB3E3595B60910C3C37d0DC8A5277c` | `0x91CD130f410508d9e8C88B84c660986121b476DD` |
| zkSync Sepolia   | `0x95960bd4d172Ea75e8F8898a1aD72D1cc72C7111` | -                                            |

**Deployment Transaction Hash:**
[`0x35df60d39e60a33979d6b168a61681f47859bde4427373224485019e89525be1`](https://sepolia.etherscan.io/tx/0x35df60d39e60a33979d6b168a61681f47859bde4427373224485019e89525be1)

**Success Transaction**
<p align="center">
  <img src="img/Success Transaction.png" alt="Rebase Token Demo" width="600"/>
</p>

---

**Course:** [Cyfrin Updraft](https://updraft.cyfrin.io/)  
**Instructor:** Ciara Nightingale
