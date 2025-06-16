## 🐙 OctoChest NFT

![Octo DeFi Logo](./assets/octo-defi-logo.png)

A fully on-chain, burnable, enumerable ERC721 collection where each NFT is randomly assigned one of 20 IPFS-hosted image variations.

Built with **Solidity**, **Hardhat**, **Foundry**, and **OpenZeppelin**, and deployed using **Hardhat Ignition**.

---

### 🛠️ Tech Stack

- [Solidity ^0.8.27](https://docs.soliditylang.org)
- [OpenZeppelin Contracts ^5.0.0](https://docs.openzeppelin.com/contracts)
- [Hardhat](https://hardhat.org/)
- [Foundry](https://book.getfoundry.sh/)
- [Ignition (Hardhat Deployment Plugin)](https://hardhat.org/hardhat-runner/plugins/nomicfoundation-hardhat-ignition)
- [IPFS](https://ipfs.tech/) for metadata storage

---

### 🚀 Features

- ✅ ERC721 compliant (using OpenZeppelin)
- 🔥 Burnable via `ERC721Burnable`
- 🧮 Enumerable via `ERC721Enumerable`
- 🛂 Role-based minting (`MINTER_ROLE`)
- 🎲 Random image assignment (1–20) per NFT
- 📦 IPFS-based metadata (`ipfs://.../N.json` pattern)
- 🔐 AccessControl with `DEFAULT_ADMIN_ROLE`

---

### 📁 Project Structure

```
.
├── contracts/
│   └── OctoChest.sol          # Main smart contract
├── ignition/
│   └── modules/
│       └── OctoChestModule.ts # Ignition deployment module
├── scripts/
│   └── interact.ts            # (optional) interaction examples
├── test/
│   └── OctoChest.test.ts      # Contract tests
├── foundry.toml
├── hardhat.config.ts
├── README.md
└── package.json
```

---

### 📦 Installation

```bash
git clone <your-repo>
cd <your-repo>
npm install
```

---

### 🧪 Testing

You can test your contracts using **Foundry** or **Hardhat**.

**With Foundry:**

```bash
forge test
```

**With Hardhat:**

```bash
npx hardhat test
```

---

### 📤 Deployment (with Ignition)

Make sure you set up the right environment (network config in `hardhat.config.ts`).

Then deploy with:

```bash
NETWORK=<network> npm run deploy
```

Example:

```bash
NETWORK=sepolia npm run deploy
```

> This will use `ignition/modules/OctoChestModule.ts` for deployment.

You can inspect the deployed addresses at:

```bash
ignition/deployments/chain-<chainId>/deployed_addresses.json
```

---

### 🌐 Token Metadata

The metadata is served via IPFS and looks like:

```
ipfs://QmZS34ktG626a3Gqu7CC3QiHeRtVWQzDSt7LsDGHuZoJzw/<imageNumber>.json
```

Each token’s metadata file is randomly selected from 20 variants (`1.json` to `20.json`) at mint time.

---

### 🔐 Roles

- `DEFAULT_ADMIN_ROLE`: Full access (set at deployment)
- `MINTER_ROLE`: Can call `safeMint(address to)`

---

### 🔎 Contract Preview

```solidity
safeMint(address to): mints a new token with a random image assigned
tokenURI(tokenId): returns full IPFS URI of the token's metadata
burn(tokenId): allows burning if the caller owns the token
```

---

### 📄 License

MIT © \[#3Blocks]
