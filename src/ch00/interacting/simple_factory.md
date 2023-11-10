# Factory Pattern

Here's a minimal example of a factory contract that deploy the `SimpleCounter` contract:

```rust
{{#include ../../../listings/getting-started/simple_factory/src/factory.cairo}}
```

This factory can be used to deploy multiple instances of the `SimpleCounter` contract by calling the `create_counter` and `create_counter_at` functions.

The `SimpleCounter` class hash is stored inside the factory, and can be upgraded with the `update_counter_class_hash` function which allows to reuse the same factory contract when the `SimpleCounter` contract is upgraded.

This minimal example lacks several useful features, you can find a more complete example in the [Factory Example](../../ch01/factory.md) chapter.