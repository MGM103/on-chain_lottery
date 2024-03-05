# Provably Random On-chain Lottery

## About

This project creates a provably random lottery via smart contracts that allows users to participate in the lottery in a trustless and decentralised manner. Additionally the users can verify themselves that the contracts are provably random as they are powered by chainlink VRF. The lottery is also compatible with chainlink keepers to run the lottery automatically.

## Table of contents

1. [Getting started](#getting-started)
   - [1.1 Requirements](#requirements)
   - [1.2 Quickstart](#quickstart)
2. [Lottery Process](#lottery-process)
3. [Usage](#usage)
   - [3.1 Deploying Locally](#deploying-locally)
   - [3.2 Deploying to a testnet or mainnet](#deploying-to-a-testnet-or-mainnet)
4. [Testing](#testing)
   - [4.1 Unit tests](#unit-tests)
   - [4.2 Coverage](#test-coverage)
5. [Additional Notes](#additional-notes)
6. [Acknowledgements](#acknowledgements)

## Lottery Process

1. Users can enter by paying for a ticket
   1. The ticket fees are going to go to the winer during the draw
2. After a period of time, the lottery will automatically draw a winner at random
   1. Chainlink Automation will be used to create a time based trigger
   2. Chainlink VRF will be used to select the winner from the participant pool

## Getting Started

### Requirements

The following must be installed on your machine:

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/)
- [foundry](https://book.getfoundry.sh/getting-started/installation)

### Quickstart:

```
git clone https://github.com/MGM103/on-chain_lottery.git
cd on-chain_lottery
forge build
```

## Usage

### Deploying locally

In one terminal run anvil. Anvil is a local Ethereum node, designed for development with Forge, akin to Ganache.

```
anvil
```

In another terminal run the following command to deploy:

```
make deploy
```

### Deploying to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

2. Deploy

```
make deploy ARGS="--network sepolia"
```

This will setup a ChainlinkVRF Subscription for you. If you already have one, update it in the `scripts/HelperConfig.s.sol` file. It will also automatically add your contract as a consumer.

3. Register a Chainlink Automation Upkeep

[You can follow the documentation if you get lost.](https://docs.chain.link/chainlink-automation/compatible-contracts)

Go to [automation.chain.link](https://automation.chain.link/new) and register a new upkeep. Choose `Custom logic` as your trigger mechanism for automation.

#### Scripts

After deploying to a testnet or local net, you can run the scripts.

Using cast deployed locally example:

```
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.1ether --private-key <PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL
```

or, to create a ChainlinkVRF Subscription:

```
make createSubscription ARGS="--network sepolia"
```

## Testing

### Unit tests

To run the unit tests for this project you can run the following commands:

```
forge test // run all tests
forge test --mt <testFunctionName> // run specific test
```

### Test Coverage

To see the amount of coverage the tests in the project cover of the codebase you can run the following command:

```
forge coverage
```

## Additional Notes

If you are unfamiliar with the foundry smart contract development framework please refer to: https://book.getfoundry.sh/

## Acknowledgements

Full credit must go to [Patrick Collins](https://github.com/PatrickAlphaC). He is a fantastic teacher of blockchain development and this project came from his [course](https://github.com/Cyfrin/foundry-full-course-f23). If you are interested in learning more please checkout his [youtube](https://www.youtube.com/@PatrickAlphaC).
