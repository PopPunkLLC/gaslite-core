## Gaslite Core Repository

**Hyper optimized smart contracts for every day use cases**


## Contracts
```
src
    ├─ GasliteDrop -> Bulk transfers for ERC20, ERC721, and Native Network Tokens
    ├─ GasliteDrop1155 -> Bulk transfers for ERC1155
    ├─ GasliteSplitter -> Efficient splitting for payments in ERC20 and Native Network Tokens
    ├─ GasliteNFT -> Efficient NFT contract with whitelist support
    ├─ GasliteToken -> Efficient base ERC20 token with UniswapV2 support
    ├─ GasliteVest -> Efficient bare bones linear continuous vesting contract for ERC20 tokens
    ├─ GasliteMerkleDN -> Efficient base contract for Merkle "Airdrops" of native tokens
    ├─ GasliteMerkleDT -> Efficient base contract for Merkle "Airdrops" of ERC20 tokens
    ├─ GaslitePoints -> Efficient base contract for points & points staking
    ├─ examples
        ├─ NFTSplitter -> An example NFT contract that splits mint proceeds using GasliteSplitter
        ├─ Claim -> An example benchmarking 3 ways to handle claims in a smart contract
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```
