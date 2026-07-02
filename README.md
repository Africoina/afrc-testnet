# AFR!COIN (AFRC) — The Pan-African Monetary Bridge

> *"We do not build a bridge to cross it ourselves. We build it so that generations may cross after us."*

## Overview

AFR!COIN is a Pan-African utility token and non-custodial mobile wallet built on **Polygon PoS**. It enables fast, low-cost cross-border payments between 40+ African currencies without dependency on USD, EUR, or costly intermediaries.

AFR!COIN is an initiative of **AFR!UMOJA COMMUNITY** ("The Hope of the Hopeless"), a non-profit organization serving African communities.

**NGO:** [afriumoja.org](https://www.afriumoja.org)

---

## Smart Contracts (Testnet — Polygon Amoy)

| Contract | Address | Description |
| :--- | :--- | :--- |
| **AFRCToken** | `0x94d34D3D18DC021F62C5f811Cd043F28c7485Ead` | ERC-20 utility token — 300M fixed supply |
| **VestingVault** | `0x3C156979864d756383D163ECfF681FBbeF9E1601` | Founder vesting (40/40/20 — 4/6/8 years) |
| **PNPRegistry** | `0xC02d73f1c2492c39984887c2Fc612D6a952a386E` | .panaf.eth name registry |
| **AFRCTreasury** | `0x0Aa96e7DD38c5377b2c3179AbfdA1803Ea65c1c7` | Multi-sig treasury (5/7) |

---

## Verified Transactions

| Test | Transaction |
| :--- | :--- |
| Transfer 100 AFRC | [View](https://amoy.polygonscan.com/tx/0xf2d70416a2295c1a6bb200b340819224599a8466f1899d5455046b2eb3bc0890) |
| Burn 100 AFRC | [View](https://amoy.polygonscan.com/tx/0x197b87cef3a0ba95707792937836c2b6fe96935b5c2b8abfafaef2f13ed14121) |
| Circuit-Breaker (Pause) | [View](https://amoy.polygonscan.com/tx/0xf773adcbdfc2c956f029dc863c8b0c113ad64a68f75e0bb221d4ea1caa016ee8) |
| Blacklist Block | [View](https://amoy.polygonscan.com/tx/0x20a026b645d445ee5897f955437b730077641a0585a7b9d97776361adb9ed79f) |

---

## Tech Stack

| Layer | Technology |
| :--- | :--- |
| Blockchain | Polygon PoS (Amoy testnet) |
| Language | Solidity 0.8.20 |
| Framework | Hardhat 2.22 |
| Library | OpenZeppelin 5.0.2 |
| RPC Provider | Alchemy |

---

## Getting Started

```bash
git clone https://github.com/Africoina/afrc-testnet.git
cd afrc-testnet
npm install
npx hardhat compile
npx hardhat test
License
GNU General Public License v3.0
