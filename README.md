# Staking The Bridge by Polygon ZkEVM

Source code for Staking The Bridge project by Polygon ZkEVM.

## Contracts

### L1Escrow

- L1Escrow receive TKN from users on L1 and trigger a mint of the TKN on L2 via LxLy.
- L1Escrow is upgradable.
- L1Escrow hold the backing for TKN and contain the investment logic.
- Roles:
  - **Admin**
    - Ability to upgrade the contract
    - Ability to pause the contract
    - Ability to grant/revoke roles
  - **EscrowManager**
    - Ability to withdraw ETH/ERC-20 tokens from backing
- Follow the ERC-20 Mintable Interface supported by Polygon Portal

## Development

Install latest version of [foundry](https://github.com/foundry-rs/foundry).

Install dependencies:

```shell
forge install
```

Create `.env` file with the following content:

```shell
ETH_RPC_URL="https://ethereum.publicnode.com"
```

Run the test:

```shell
forge test
```
