# Hash Solidity Compatible

This chapter will explains how to get Solidity's keccak256 compatible hashing in Cairo.

While both use Keccak, their endianness differs: Cairo is little-endian, Solidity big-endian.
We will use the `keccak` corelib's functions to be able to map Solidity's hashing.

### Hashing 256 bits types

For `u256`'s types, we can simply use the `keccak_u256s_be` function, followed by `u128_byte_reverse` to get the same result as Solidity. Luckily, most solidity types are encoded on 256 bits, so we can use this function for them.

Example:
```rust
# TODO
```

### Hashing arbitrary number of bits

To hash an arbitrary number of bits, it gets a bit more complicated.

First, we have to divide the input into 64 bits words.
The last words is not necessarily 64 bits long, so we also have to keep track of the number of bytes in the last word.

Then, we can use the `cairo_keccak` function to hash the input. Here's the function's signature:

```rust
cairo_keccak(
	ref input: Array<u64>,
	last_input_word: u64, 
	last_input_num_bytes: usize
) -> u256
```

For our hashing function, we will take a `span<u8>` as input, so it can works with any array of bytes.


> Alexandria provide a similar `keccak256` function

For example:

<!-- ```rust
{{#include ../../listings/ch02-advanced-concepts/hash_solidity_compatible/src/contract.cairo}}
``` -->

Play with the contract in [Remix](https://remix.ethereum.org/?#activate=Starknet&url=https://github.com/NethermindEth/StarknetByExample/blob/main/listings/ch02-advanced-concepts/hash_solidity_compatible/src/contract.cairo).
