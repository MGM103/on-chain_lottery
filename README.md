# Provably Random On-chain Lottery

## About

This project creates a provably random lottery via smart contracts that allows users to participate in the lottery in a trustless and decentralised manner. Additionally the users can verify themselves that the contracts are provably random as they are powered by chainlink VRF.

### Lottery Process

1. Users can enter by paying for a ticket
    1. The ticket fees are going to go to the winer during the draw
2. After a period of time, the lottery will automatically draw a winner at random
    1. Chainlink Automation will be used to create a time based trigger
    2. Chainlink VRF will be used to select the winner from the participant pool