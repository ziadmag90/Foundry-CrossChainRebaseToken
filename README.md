# 🚀 Foundry Cross-Chain Rebase Token

## 🌟 About

Welcome to the **Cross-Chain Rebase Token** project! This cutting-edge project lets you deposit ETH and receive rebase tokens that **automatically accrue rewards over time**. Powered by **Chainlink CCIP** (Cross-Chain Interoperability Protocol), it enables seamless token bridging between **Ethereum Sepolia** and **zkSync Sepolia**. Whether you're a Solidity enthusiast, a Foundry power user, or just curious about cross-chain development, this project showcases advanced blockchain mechanics in action!

---

## 📑 Table of Contents

- [About](#about)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Deployment](#deployment)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Interacting with the Contract](#interacting-with-the-contract)
- [Estimate Gas](#estimate-gas)
- [Formatting](#formatting)
- [Project Design & Assumptions](#project-design--assumptions)
- [Deployed Contracts](#deployed-contracts)
- [Thank You!](#thank-you)

---

# 🚀 Getting Started

## 📋 Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) – For cloning the repository.
- [Foundry](https://getfoundry.sh/) – A fast and flexible Ethereum development toolkit.

**Pro Tip:** New to Foundry? Check out the [official docs](https://book.getfoundry.sh/) to get started quickly!

## ⚡ Quickstart

Clone and build the project with these commands:

```sh
git clone https://github.com/ziadmag90/Foundry-CrossChainRebaseToken.git
cd Foundry-CrossChainRebaseToken
forge build
```

**Note:** Ensure git and Foundry are installed and up-to-date. Run `foundryup` if you need the latest Foundry version.

---

# 🛠️ Usage

## 🚀 Deployment

Deploying to **Sepolia** or **zkSync Sepolia** is simple. Follow these steps:

1. **Set Up Environment Variables**  
   Create a `.env` file (use `.env.example` as a template) and add:
   - `SEPOLIA_RPC_URL`: Get it from [Alchemy](https://alchemy.com/?a=673c802981).
   - `ZKSYNC_SEPOLIA_RPC_URL`: Your zkSync Sepolia node URL.

2. **Secure Your Wallet**  
   Use Foundry’s keystore for safety:
   ```sh
   cast wallet import wallet-name --interactive
   ```
   Follow the prompts to import your private key securely. Use `--account wallet-name` in deployment commands.

3. **Get Testnet ETH**  
   Grab some Sepolia ETH from [faucets.chain.link](https://faucets.chain.link/).

4. **Deploy to Sepolia**  
   ```sh
   forge script script/Deployer.s.sol --rpc-url $SEPOLIA_RPC_URL --account wallet-name --broadcast
   ```

5. **Deploy to zkSync Sepolia**  
   ```sh
   forge script script/Deployer.s.sol --rpc-url $ZKSYNC_SEPOLIA_RPC_URL --account wallet-name --broadcast
   ```

6. **Verify Deployment**  
   - Check contract addresses in your terminal output.
   - Confirm on [Etherscan Sepolia](https://sepolia.etherscan.io/) or [zkSync Explorer](https://sepolia.explorer.zksync.io/).

**Security Note:** Never expose your private key in plain text or commit it to git. Always use `.env` and keystore management.

## 🧪 Testing

This repo includes **unit tests** and **fuzzing** to ensure contract reliability. Additional tiers (integration, forked, staging) can be added for broader validation.

Run the tests:
```sh
forge test
```

### 📊 Test Coverage
Check test coverage with:
```sh
forge coverage
```
For a detailed report:
```sh
forge coverage --report debug
```

---

# 🤝 Interacting with the Contract

Use `cast` to interact with your deployed contracts. Examples for **Sepolia**:

- **Deposit 0.1 ETH for RebaseTokens**  
   ```sh
   cast send <vault-contract-address> "deposit()" --value 0.1ether --rpc-url $SEPOLIA_RPC_URL --account wallet-name
   ```

- **Redeem 0.01 RebaseTokens for ETH**  
   ```sh
   cast send <vault-contract-address> "redeem(uint256)" 10000000000000000 --rpc-url $SEPOLIA_RPC_URL --account wallet-name
   ```

**Note:** Replace `<vault-contract-address>` with your deployed vault address.

---

# ⛽ Estimate Gas

Optimize gas costs by running:
```sh
forge snapshot
```
This generates a gas usage report for your contracts.

---

# 🎨 Formatting

Keep your code tidy with:
```sh
forge fmt
```
**Why?** Clean code boosts readability and collaboration.

---

# 🧠 Project Design & Assumptions

- **Core Concept**: A cross-chain rebase token using Chainlink CCIP for bridging between Ethereum Sepolia and zkSync Sepolia.
- **Rewards**: Assumed to be pre-loaded in the contract, rewarding early users and L2 bridgers with higher rates.
- **Interest Rate**: Decreases over time; locks in statically when bridging.
- **Deposit/Withdraw**: Only available on L1 (Ethereum Sepolia).
- **Bridging**: No interest accrues during the process. Remember to bridge back accrued interest from the destination chain.

---

# 📍 Deployed Contracts

| Network          | Rebase Token Address                         | Vault Address                                |
|------------------|----------------------------------------------|----------------------------------------------|
| Ethereum Sepolia | `0x479A2426F8BB3E3595B60910C3C37d0DC8A5277c` | `0x91CD130f410508d9e8C88B84c660986121b476DD` |
| zkSync Sepolia   | `0x95960bd4d172Ea75e8F8898a1aD72D1cc72C7111` | -                                            |

**Deployment Transaction Hash:**  
[`0x35df60d39e60a33979d6b168a61681f47859bde4427373224485019e89525be1`](https://sepolia.etherscan.io/tx/0x35df60d39e60a33979d6b168a61681f47859bde4427373224485019e89525be1)

**Success Screenshot:**  
<p align="center">
  <img src="img/Success Transaction.png" alt="Deployment Success" width="600"/>
</p>

---

# 🙏 Thank You!

Big thanks to the **Cyfrin Updraft** team and instructor **Ciara Nightingale** for their amazing guidance. Shoutout to the community for their support and contributions!
