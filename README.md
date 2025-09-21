# Influencer Marketing Platform Smart Contract

A comprehensive Clarity smart contract built for the Stacks blockchain that facilitates secure influencer marketing campaigns with automated escrow, ratings, and payment processing.

## Overview

This smart contract creates a decentralized platform where brands can create marketing campaigns, influencers can apply and complete work, and both parties are protected through an automated escrow system with built-in reputation tracking.

## Key Features

### 🎯 Campaign Management
- **Create Campaigns**: Brands can create campaigns with budgets, deadlines, and specific requirements
- **Application System**: Influencers submit proposals with custom pricing
- **Selection Process**: Brands choose influencers based on applications and profiles
- **Work Submission**: Structured workflow for deliverable submission and approval

### 💰 Secure Payment System
- **Automatic Escrow**: Campaign funds locked in smart contract upon creation
- **Platform Fees**: Configurable fee structure (default 2.5%)
- **Payment Release**: Funds released only after work approval
- **Emergency Cancellation**: Brands can cancel campaigns with automatic refunds

### 👤 Profile Management
- **Influencer Profiles**: Track followers, engagement rates, and campaign history
- **Brand Profiles**: Monitor spending and campaign statistics
- **Verification System**: Admin-controlled influencer verification
- **Reputation Tracking**: Mutual rating system for quality assurance

### 🔒 Security Features
- **Input Validation**: All user inputs sanitized and validated
- **Authorization Controls**: Role-based access to sensitive functions
- **Double-Spend Protection**: Prevents duplicate payments and fund manipulation
- **Error Handling**: Comprehensive error codes with clear messaging

## Contract Functions

### Public Functions

#### Profile Creation
```clarity
(create-influencer-profile name bio social-handles follower-count engagement-rate)
(create-brand-profile name description website)
```

#### Campaign Operations
```clarity
(create-campaign title description budget deadline requirements)
(apply-to-campaign campaign-id proposal requested-amount)
(select-influencer campaign-id influencer)
(submit-work campaign-id)
(approve-work campaign-id)
```

#### Rating & Management
```clarity
(rate-campaign campaign-id brand-rating influencer-rating)
(cancel-campaign campaign-id)
```

#### Admin Functions
```clarity
(verify-influencer influencer)
(withdraw-fees amount)
```

### Read-Only Functions
```clarity
(get-campaign campaign-id)
(get-influencer-profile influencer)
(get-brand-profile brand)
(get-campaign-application campaign-id influencer)
(calculate-platform-fee amount)
```

## Workflow

### 1. Setup Phase
1. Influencers create profiles with social metrics
2. Brands create company profiles
3. Admin can verify trusted influencers

### 2. Campaign Phase
1. Brand creates campaign with escrow deposit
2. Influencers apply with proposals and pricing
3. Brand reviews applications and selects influencer

### 3. Execution Phase
1. Selected influencer completes work
2. Influencer submits deliverables
3. Brand approves work and releases payment

### 4. Completion Phase
1. Both parties rate each other (1-5 stars)
2. Reputation scores updated
3. Campaign marked as completed

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized |
| u101 | Campaign not found |
| u102 | Invalid amount |
| u103 | Campaign expired |
| u104 | Already applied |
| u105 | Not selected |
| u106 | Work not submitted |
| u107 | Already completed |
| u108 | Insufficient funds |
| u109 | Invalid rating |
| u110 | Invalid input |

## Constants & Limits

- **Platform Fee**: 2.5% (250 basis points)
- **Rating Range**: 1-5 stars
- **Max Engagement Rate**: 100% (10,000 basis points)
- **Max Follower Count**: 1 billion
- **Min Campaign Duration**: 144 blocks (~1 day)

## Security Considerations

### Input Validation
- All string inputs sanitized with fallback defaults
- Numeric inputs validated within reasonable ranges
- Campaign IDs checked for existence and validity

### Access Control
- Only campaign creators can select influencers and approve work
- Only selected influencers can submit work
- Admin functions restricted to contract owner

### Financial Security
- Escrow system prevents fund manipulation
- Platform fees collected separately from campaign budgets
- Emergency cancellation preserves brand funds

## Deployment

1. Deploy contract to Stacks blockchain
2. Initialize with desired platform fee rate
3. Set admin wallet for fee collection
4. Contract is ready for user interaction

## Integration

The contract can be integrated with:
- Web applications via Stacks.js
- Mobile apps using Stacks API
- Other smart contracts through function calls
- Analytics platforms for campaign metrics

## Future Enhancements

- Multi-token support (beyond STX)
- Milestone-based payments
- Dispute resolution system
- Advanced reputation algorithms
- Integration with social media APIs

