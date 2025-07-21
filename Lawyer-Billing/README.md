# Legal Billing Automation Smart Contract

A comprehensive Clarity smart contract for the Stacks blockchain that automates legal billing, time tracking, client management, and invoicing for law firms and legal professionals.

## Overview

This smart contract provides a decentralized solution for legal professionals to manage their billing operations, track billable hours, manage client relationships, and automate invoice generation and payments. The contract ensures transparency, immutability, and automated processing of legal billing workflows.

## Features

### Core Functionality
- **Client Management**: Register and manage client profiles with contact information
- **Lawyer Management**: Register lawyers with hourly rates and specializations
- **Case Management**: Create and track legal cases with client-lawyer assignments
- **Time Tracking**: Record billable and non-billable time entries with detailed descriptions
- **Automated Billing**: Calculate billing amounts based on time entries and hourly rates
- **Invoice Generation**: Create and manage invoices with automated calculations
- **Payment Processing**: Handle invoice payments with contract fee deduction
- **Relationship Management**: Establish client-lawyer relationships with retainer agreements

### Key Benefits
- **Transparency**: All billing data is recorded on the blockchain
- **Automation**: Automatic calculation of fees and invoice generation
- **Security**: Smart contract ensures secure payment processing
- **Immutability**: Permanent record of all time entries and payments
- **Fee Management**: Built-in contract fee system (default 5%)

## Contract Structure

### Data Models

#### Clients
```clarity
{
    name: string-ascii 100,
    email: string-ascii 100,
    address: principal,
    active: bool,
    created-at: uint
}
```

#### Lawyers
```clarity
{
    name: string-ascii 100,
    email: string-ascii 100,
    address: principal,
    hourly-rate: uint,
    specialization: string-ascii 50,
    active: bool,
    created-at: uint
}
```

#### Cases
```clarity
{
    client-id: uint,
    lawyer-id: uint,
    title: string-ascii 200,
    description: string-ascii 500,
    status: string-ascii 20, // "active", "closed", "pending"
    created-at: uint,
    updated-at: uint
}
```

#### Time Entries
```clarity
{
    case-id: uint,
    lawyer-id: uint,
    client-id: uint,
    description: string-ascii 500,
    minutes: uint,
    hourly-rate: uint,
    amount: uint,
    date: uint,
    billable: bool,
    invoiced: bool
}
```

#### Invoices
```clarity
{
    client-id: uint,
    lawyer-id: uint,
    case-id: uint,
    total-amount: uint,
    paid-amount: uint,
    status: string-ascii 20, // "pending", "paid", "overdue", "cancelled"
    due-date: uint,
    created-at: uint,
    paid-at: optional uint
}
```

## Usage Guide

### Initial Setup

1. **Deploy the Contract**: Deploy the contract to the Stacks blockchain
2. **Set Contract Fee**: Update the contract fee percentage if needed (default: 5%)

### Client Management

```clarity
;; Register a new client
(contract-call? .legal-billing register-client 
    "John Doe" 
    "john@example.com" 
    'SP1HTBVD3JG9C05J7HDJKDBAAD9QC17LBWW6D7DPFR)

;; Deactivate a client
(contract-call? .legal-billing deactivate-client u1)
```

### Lawyer Management

```clarity
;; Register a new lawyer
(contract-call? .legal-billing register-lawyer 
    "Jane Smith" 
    "jane@lawfirm.com" 
    'SP2HTBVD3JG9C05J7HDJKDBAAD9QC17LBWW6D7DPFR
    u300  ;; $300 per hour
    "Corporate Law")

;; Update lawyer's hourly rate
(contract-call? .legal-billing update-lawyer-rate u1 u350)
```

### Case Management

```clarity
;; Create a new case
(contract-call? .legal-billing create-case 
    u1    ;; client-id
    u1    ;; lawyer-id
    "Contract Dispute Resolution"
    "Client needs assistance with breach of contract issue")

;; Update case status
(contract-call? .legal-billing update-case-status u1 "closed")
```

### Time Tracking

```clarity
;; Add a billable time entry
(contract-call? .legal-billing add-time-entry 
    u1      ;; case-id
    u1      ;; lawyer-id
    "Research contract law precedents and draft initial response"
    u120    ;; 2 hours in minutes
    true)   ;; billable
```

### Invoice Management

```clarity
;; Create an invoice
(contract-call? .legal-billing create-invoice 
    u1    ;; client-id
    u1    ;; lawyer-id
    u1    ;; case-id
    u1008) ;; due in 1008 blocks (~1 week)

;; Update invoice amount
(contract-call? .legal-billing update-invoice-amount u1 u600)

;; Pay an invoice (called by client)
(contract-call? .legal-billing pay-invoice u1)
```

## Validation Rules

### Hourly Rates
- Minimum: $50 per hour
- Maximum: $10,000 per hour

### Time Entries
- Minimum: 1 minute
- Maximum: 1440 minutes (24 hours)

### Contract Fees
- Maximum: 20% of invoice amount

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Client not found |
| u102 | Lawyer not found |
| u103 | Invalid amount |
| u104 | Invalid hourly rate |
| u105 | Invoice not found |
| u106 | Invoice already paid |
| u107 | Insufficient payment |
| u108 | Time entry not found |
| u109 | Invalid time entry |
| u110 | Client already exists |
| u111 | Lawyer already exists |
| u112 | Invalid status |
| u113 | Case not found |
| u114 | Case already exists |

## Read-Only Functions

- `get-client(client-id)` - Retrieve client information
- `get-lawyer(lawyer-id)` - Retrieve lawyer information
- `get-case(case-id)` - Retrieve case information
- `get-time-entry(entry-id)` - Retrieve time entry details
- `get-invoice(invoice-id)` - Retrieve invoice information
- `calculate-amount(minutes, hourly-rate)` - Calculate billing amount
- `get-contract-fee-percentage()` - Get current contract fee rate

## Security Features

- **Owner-Only Functions**: Critical operations restricted to contract owner
- **Lawyer Authorization**: Lawyers can only modify their own time entries
- **Client Authorization**: Clients can only pay their own invoices
- **Input Validation**: Comprehensive validation of all inputs
- **Status Checks**: Prevents double-payment and invalid state transitions

## Development Status

This is a production-ready smart contract with the following considerations:

### Implemented Features
- Complete client and lawyer management
- Time tracking and billing calculations
- Invoice generation and payment processing
- Comprehensive error handling and validation