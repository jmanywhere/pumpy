# PUMPY

## Ecosystem

### Token

PUMPY (`$PUMP`) is a token with a Maximum Supply of 1 trillion tokens.

#### Description

The token is a standard ERC20 token. Tokens will be burned on each buy of NFTs. The burning mechanism selected for the token is to send to the `0x00...00dEad` wallet

#### Tokenomics

TBD

### NFT

Each NFT will unlock the ability to Stake itself along with `$PUMP` tokens. The NFT has a value associataed with the expected return on each deposit (see Staking). The price of each NFT will be in `$PUMP` and will have a value of `TBD`.

### Staking Pool

To stake `$PUMP`, users will need to also stake an NFT along with it.Only one NFT will be able to be staked per wallet. Depending on the `pumpRet` value of each NFT, users will be able to claim a daily amount of:

`pumpRet * PUMP_stakedAmount` where:

- `pumpRet`: percentage (ranging from 0.5% to 5%).
- `PUMP_stakedAmount`: The amount of `$PUMP` staked alongside each NFT.
