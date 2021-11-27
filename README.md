# MineCrypto-Smart-Contracts

In this repo you can find all the smart contracts used on MineCrypto.

## Contracts

**MineNft.sol**: the NFT rank contract which is the core of the system

**MineNftPresale.sol**: allows us to whitelist users for the presale

**MineRandom.sol**: generates random numbers safely using ChainLink's Verifiable Random Function. This randoms are used for the NFT Rank's purity

**IMineMintRandom.sol**: interface to allow communication from `MineNft.sol` and `MineRandom.sol`. This allows us to migrate the random number generation to newer versions of VRF without changing the NFT Rank contract. 

## Audits

We are in the process of getting audits from big firms, for now the contracts were reviewd by three private auditors.

## Considerations

These contracts are prepared to allow for the Minter, Oracle and Forge entities. More on them in the future. 
