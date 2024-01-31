# ERC20 Bridge on Polygon ZkEVM

This is implementation of Universal ERC20 Bridge that will work for any ERC20.

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
