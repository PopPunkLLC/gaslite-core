## Gaslite Core Repository

**Hyper optimized smart contracts for every day use cases**


## Contracts
```
src
    ├─ GasliteDrop -> Bulk transfers for ERC20, ERC721, and Native Network Tokens
    ├─ GasliteDrop1155 -> Bulk transfers for ERC1155
    ├─ GasliteSplitter -> Efficient splitting for payments in ERC20 and Native Network Tokens
    ├─ GasliteNFT -> Efficient NFT contract with whitelist support
    ├─ examples
        ├─ NFTSplitter -> An example NFT contract that splits mint proceeds using GasliteSplitter
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
