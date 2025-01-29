# PoliFX Marketplace Smart Contract

## Overview
PoliFX Marketplace is a decentralized prediction market platform built on Stacks blockchain. It allows users to create markets around policy outcomes, place bets on these markets, and earn rewards for correct predictions.

## Features
- Create prediction markets with customizable parameters
- Place bets on market outcomes
- Admin controls for market parameters
- Built-in validation and safety checks
- STX-based betting system

## Contract Functions

### Market Creation and Management
- `create-market`: Create a new prediction market
  - Parameters:
    - `description`: Market description (string-ascii 256)
    - `betting-close-time`: Block height when betting closes
  - Returns: Market ID

- `place-wager`: Place a bet on a market
  - Parameters:
    - `market-id`: ID of the target market
    - `prediction`: Predicted outcome (boolean)
    - `bet-amount`: Amount of STX to bet
  - Returns: Success/failure response

### Administrative Functions
- `set-market-resolution-period`: Set the resolution period for markets
- `set-minimum-bet-amount`: Set the minimum allowed bet amount
- `set-maximum-bet-amount`: Set the maximum allowed bet amount
- `transfer-admin`: Transfer admin rights to a new address
- `get-admin`: Get the current admin address

## Constants

### Error Codes
- `ERROR-INVALID-CLOSE-TIME` (u1): Invalid market closing time
- `ERROR-MARKET-INACTIVE` (u2): Market is not active
- `ERROR-MARKET-RESOLVED` (u3): Market has already been resolved
- `ERROR-INVALID-WAGER` (u4): Invalid wager amount
- `ERROR-MARKET-NOT-EXISTS` (u5): Market does not exist
- And more...

### Configuration Limits
- Maximum close time delay: ~1 year (52,560 blocks)
- Minimum close time delay: ~1 day (144 blocks)
- Maximum timeout delay: ~2 years (105,120 blocks)
- Minimum description length: 10 characters

## Data Structures

### Markets
```clarity
{
  description: (string-ascii 256),
  outcome: (optional bool),
  betting-close-time: uint,
  resolution-deadline: uint,
  creator: principal
}
```

### Wagers
```clarity
{
  bet-amount: uint,
  prediction: bool
}
```

## Setup and Deployment

1. Ensure you have the Clarity CLI tools installed
2. Clone the repository
3. Deploy the contract using:
```bash
clarinet contract deploy polifx
```

## Security Considerations
- All bets are final and cannot be reversed
- Market creation parameters are validated to ensure fairness
- Admin functions are protected with proper authorization checks
- Betting amounts are bounded to prevent excessive exposure

## Development and Testing
- Built using Clarity language
- Use Clarinet for local testing
- Run tests with:
```bash
clarinet test
```

## Contributing
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
