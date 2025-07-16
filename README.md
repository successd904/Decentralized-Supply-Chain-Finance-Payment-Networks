# Decentralized Supply Chain Finance Payment Networks

A comprehensive blockchain-based system for managing supply chain finance operations, including coordinator verification, payment processing, credit management, settlement coordination, and risk monitoring.

## System Overview

This system consists of five interconnected smart contracts that work together to provide a complete supply chain finance solution:

### Core Contracts

1. **Finance Coordinator Verification** (`finance-coordinator.clar`)
    - Validates and manages supply chain finance coordinators
    - Handles coordinator registration, verification, and status management
    - Maintains coordinator reputation and performance metrics

2. **Payment Processing** (`payment-processor.clar`)
    - Processes supply chain payments between parties
    - Handles payment initiation, validation, and execution
    - Manages payment status and transaction records

3. **Credit Management** (`credit-manager.clar`)
    - Manages supplier credit limits and utilization
    - Handles credit scoring and risk assessment
    - Tracks credit history and payment behavior

4. **Settlement Coordination** (`settlement-coordinator.clar`)
    - Coordinates payment settlements between multiple parties
    - Manages settlement batching and netting
    - Handles dispute resolution and settlement finalization

5. **Risk Monitoring** (`risk-monitor.clar`)
    - Monitors payment risks across the network
    - Tracks risk metrics and generates alerts
    - Manages risk thresholds and mitigation strategies

## Features

- **Decentralized Verification**: Trustless coordinator verification system
- **Automated Payments**: Smart contract-based payment processing
- **Dynamic Credit Management**: Real-time credit scoring and limit management
- **Efficient Settlement**: Batch settlement with netting capabilities
- **Risk Management**: Comprehensive risk monitoring and alerting

## Architecture

The system uses a modular architecture where each contract handles specific functionality while maintaining data consistency and security. All contracts are designed to work independently without cross-contract calls.

## Getting Started

### Prerequisites

- Clarinet CLI
- Node.js and npm
- Stacks blockchain testnet access

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Testing

The system includes comprehensive tests using Vitest:

\`\`\`bash
npm test
\`\`\`

## Contract Specifications

### Data Types

- **Coordinators**: Verified entities that facilitate supply chain finance
- **Payments**: Individual payment transactions with status tracking
- **Credit Records**: Supplier credit information and history
- **Settlements**: Batch settlement operations
- **Risk Metrics**: Risk assessment data and thresholds

### Error Codes

- `ERR-NOT-AUTHORIZED` (u100): Unauthorized access
- `ERR-INVALID-INPUT` (u101): Invalid input parameters
- `ERR-NOT-FOUND` (u102): Resource not found
- `ERR-ALREADY-EXISTS` (u103): Resource already exists
- `ERR-INSUFFICIENT-FUNDS` (u104): Insufficient balance
- `ERR-INVALID-STATUS` (u105): Invalid status transition

## Security Considerations

- All functions include proper authorization checks
- Input validation prevents malicious data
- State transitions are carefully controlled
- Risk monitoring provides early warning systems

## License

MIT License
