# Understanding Sierra: From High-Level Cairo to Safe CASM

Sierra (Safe Intermediate REpresentAtion) is a linear intermediate representation of Cairo instructions, designed to bridge the gap between high-level Cairo 1 intermdiate and low-level Cairo Assembly (CASM).
Sierra can be compiled to a subset of CASM, known as `Safe CASM{:md}`.

Sierra ensures that programs are always **provable** by preventing the compilation of programs with infinite loops or invalid constraints.

### From Cairo 1 to Sierra

Before Starknet Alpha v0.11.0, developers wrote contracts in Cairo 0, which compiled directly to Cairo Assembly (CASM), and contract classes were submitted to the sequencer via `DECLARE` transactions.
This approach had risks, as the sequencer could not determine whether a given transaction would fail without executing it, and therefore could not charge fees for failed transactions.

Cairo 1 introduced contract class compilation to this new Sierra intermediate representation instead of directly compiling to CASM. The Sierra code is then submitted to the sequencer, compiled down to CASM, and finally executed by the Starknet OS.
Using Sierra ensures that all transactions (including failed ones) are provable, and allows sequencers to charge fees for all submitted transactions, making DoS attacks significantly more expensive.

### Compilation Pipeline

```
    Cairo 1.0 Source (High-level)
          |
          |	with Cairo-to-Sierra Compiler
          V
    Sierra IR (Safe, Provable Code)
          |
          |	with Sierra-to-CASM Compiler (Run by Sequencer)
          V
    CASM (Cairo Assembly)
          |
          | with CairoVM Execution
          V
    STARK Proofs (Proof Generation)
```

At its core, Sierra's compilation process is focused on safety and efficiency.
Cairo 1 uses a linear type system and a non-deterministic, immutable, contiguous memory model, which guarantees that dereferencing never fails.

Sierra transforms loops into recursion and keeps track of gas usage, which prevents infinite loops.

:::note
If you're interested in really understanding how the compilation works under the hood, check out the [cairo-compiler-workshop](https://github.com/software-mansion-labs/cairo-compiler-workshop).
:::

### Anatomy of a Sierra Program

### Type Declarations

Sierra, as a Cairo representation, also uses a **linear type system**, where each value **must be used exactly once**.
During the compilation, a unique identifier is assigned to each type.

When types can safely be used multiple times, they need to be duplicated using the `dup` instruction, which will assign two new identifiers to preserve linearity.

Type declaration is done with the following syntax:

```cairo
type type_id = concrete_type;
```

:::info
In addition, each type has a set of attributes that describe how it can be used:

- storable
- droppable
- duplicatable
- zero_sized

They are added in the type declaration:

```cairo
type type_id = concrete_type [storable: bool, drop: bool, dup: bool, zero_sized: bool]
```

:::

### Library Function Declarations

Sierra comes with a set of built-in functions (`libfuncs`) that represent the call to low-level units of code known to be safe. After type declarations, a Sierra program must define all the libfuncs used in the program along with their expected input types.

Libfunc declaration is done with the following syntax:

```cairo
libfunc libfunc_id = libfunc_name<input_types>;
```

:::note
While this section is generic, Starknet uses an allowed [list](https://github.com/starkware-libs/cairo/tree/main/crates/cairo-lang-starknet-classes/src/allowed_libfuncs_lists) of libfuncs.
:::

### Statements

This section shows the sequence of operations that occur during execution, describing the actual logic of the program. A statement either invokes a libfunc or returns a value.

Statements are declared with the following syntax:

```cairo
libfunc_id<input_types>(input_variables) -> (output_variables);
```

To return a value, we use the `return(variable_id)` statement.

### User Defined Functions Declarations

At the end of a Sierra program, each user-defined function is declared with a unique identifier and the statement index where the function starts. This provides information about the function, such as its signature, while the implementation is defined in the statements section.

An user defined function is declared with the following syntax:

```cairo
function_id@statement_index(parameters: types) -> (return_types);
```

## Simple Sierra Program Breakdown

Let's go through the following Cairo program:

```cairo
// [!include ~/listings/advanced-concepts/sierra_ir/src/simple_program.cairo]
```

It compiles to the following Sierra code:

```cairo
// [!include ~/listings/advanced-concepts/sierra_ir/simple_program.sierra]
```

Type Declarations:

- `felt252`: Represents the field element type

Libfunc Declarations:

- `felt252_add`: Performs addition on field elements
- `store_temp<felt252>`: Temporarily stores the result

Statements Section:

- Statement 0: calls the `felt252_add` libfunc to add the values from memory cells 0 and 1, storing the result in memory cell 2
- Statement 1: calls the `store_temp<felt252>` libfunc to prepare the result for the return statement
- Statement 2: returns the value from memory cell 2

User Defined Functions:

- `add_numbers`: Takes two `felt252` types in memory cells 0 and 1 and returns a `felt252` value by starting at statement 0

:::info
To enable Sierra code generation in a human-readable format, add the `sierra-text` flag to the library target in your `Scarb.toml{:md}` file:

```toml
[lib]
sierra-text = true
```

:::

### Storage Variables Smart Contract Sierra Code

You can find a more complex example of the [compiled Sierra code](/advanced-concepts/sierra_ir_storage_contract) of the [Storage Variables Example](/getting-started/basics/variables#storage-variables).

## Further Reading

- [Under the hood of Cairo 1.0: Exploring Sierra](https://www.nethermind.io/blog/under-the-hood-of-cairo-1-0-exploring-sierra-part-1)

- [Under the hood of Cairo 2.0: Exploring Sierra](https://www.nethermind.io/blog/under-the-hood-of-cairo-1-0-exploring-sierra-part-2)

- [Under the hood of Cairo 1.0: Exploring Sierra](https://www.nethermind.io/blog/under-the-hood-of-cairo-1-0-exploring-sierra-part-3)

- [Cairo and Sierra](https://docs.starknet.io/architecture-and-concepts/smart-contracts/cairo-and-sierra/)

- [Sierra - Deep Dive](https://www.starknet.io/blog/sierra-deep-dive-video/)

- [Cairo and MLIR](https://blog.lambdaclass.com/cairo-and-mlir/)
