use hash_solidity_compatible::solidity_keccak::keccak_sol_256s;

#[test]
#[available_gas(99999999)]
fn test_keccak_sol_u256() {
    let input: Span<u256> = array![
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    ].span();

    let hashed = keccak_sol_256s(input);

    assert(
        hashed == 0xa9c584056064687e149968cbab758a3376d22aedc6a55823d1b3ecbee81b8fb9,
        'keccak_sol_256s: wrong hash'
    )
}

// #[test]
// #[available_gas(99999999)]
// fn test_keccak_sol_any() {
//     let input: Span<u256> = array![0xAA].span();

//     // Split the input in u64 chunks


//     assert(
//         compatible_hash == 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365,
//         'wrong hash'
//     )
// }
