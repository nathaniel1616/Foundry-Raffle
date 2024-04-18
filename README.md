## This is a smart contract lottery
it uses the verified random to declare the winner 

user can enter raffle
at a given time the raffle will end 
the random winner is calculated

### Requirement 
To use this repo locally , you need to have the following installed on your machine
-  Foundry   , foundry can be install using the documentation  [here](https://book.getfoundry.sh/)
-  Git 

 

### installing dependencies
use the commannds in the MakeFile

```shell
$ make install
```
#### Remember to set your environment variable before deploying.
#### See .env.example to make your own .
#### Save your config in .env

### deploying on anvil 
```shell
$ make deploy
```

### deploying on testnet , eg sepolia
```shell
$ make deploy --network sepolia


#### Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

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

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

