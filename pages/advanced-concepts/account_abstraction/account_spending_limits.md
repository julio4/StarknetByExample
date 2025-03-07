# Account Contract with Spending Limits

In this example, we will write an account contract with spending limits.

Before proceeding with this example, make sure that you read the [intro](/advanced-concepts/account_abstraction/account_contract) to account contracts on Starknet which will help you understand how Starknet account contracts work.

## Key Specifications

The account contract will have the following features: 

- Spending limits can be added for any ERC-20 token with any amount by the account owner.
- A limit will reset after a specified time. The account owner can set any time limit they want (daily, weekly or 12 hours), but once set, it cannot be changed by anyone.

### How to detect that a function call is a spending transaction?

We need to identify the function calls that are spending transactions.
The token standard (i.e. ERC-20) is defined in the [SNIP-2](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-2.md).
 In this example, we will consider the "approve" and "transfer" functions as spending transactions.

- If one of the calls has the "approve" or "transfer" function selectors, the spending limit will decrease accordingly by the amount given in the function call. If there is no limit left, the transaction will revert.

<!-- ## Implementation

The function `__execute__` will check if the function called is "approve" or "transfer", and if yes, the limit will decrease by the amount in the call. Here is the code for the `__execute__` function: 

```cairo
// Execute
```

Here is the full code of the account contract with spending limits:

```cairo
// [!include ~/listings/advanced-concepts/account_spending_limits/src/account.cairo]
``` -->