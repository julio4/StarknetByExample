// ANCHOR: Hashing
use hash::{HashStateTrait, Hash};

#[derive(Serde, Drop, Copy, Hash)]
struct Data {
    id: u256,
    content: u256
}

#[starknet::contract]
mod HashedDataContract {
    use core::hash::HashStateExTrait;
    use hash::{HashStateTrait, Hash};
    use poseidon::{PoseidonTrait, HashState};
    use super::Data;

    use starknet::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        datas: LegacyMap::<ContractAddress, HashState>, 
    }

    #[generate_trait]
    #[external(v0)]
    impl MapContractImpl of IMapContract {
        fn set(ref self: ContractState, data: Data) {
            let hash_state = PoseidonTrait::new().update_with(data);
            self.datas.write(get_caller_address(), hash_state);
        }

        fn add(ref self: ContractState, data: Data) {
            let caller = get_caller_address();
            let current_hash_state = self.datas.read(caller);
            self.datas.write(caller, current_hash_state.update_with(data));
        }

        fn get(self: @ContractState, address: ContractAddress) -> felt252 {
            self.datas.read(address).finalize()
        }
    }
}
// ANCHOR_END: Hashing

use starknet::ContractAddress;

#[starknet::interface]
trait IHashedDataContract<TContractState> {
    fn set(ref self: TContractState, data: Data);
    fn add(ref self: TContractState, data: Data);
    fn get(ref self: @TContractState, address: ContractAddress) -> felt252;
}

#[cfg(test)]
mod tests {
    use super::{HashedDataContract, Data, IHashedDataContractDispatcher, IHashedDataContractDispatcherTrait};
    use starknet::{deploy_syscall, ContractAddress, contract_address_const};
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::{set_contract_address};

    use test::test_utils::{assert_eq};
    use hash::{HashStateTrait, HashStateExTrait};
    use poseidon::PoseidonTrait;
    use debug::PrintTrait;

    fn deploy() -> IHashedDataContractDispatcher {
        let mut calldata = ArrayTrait::new();
        let (contract_address, _) = deploy_syscall(
            HashedDataContract::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();
        IHashedDataContractDispatcher { contract_address }
    }

    #[test]
    #[available_gas(20000000)]
    fn test_set_hash() {
        let mut contract = deploy();

        let user = contract_address_const::<1>();
        set_contract_address(user);

        // Add a data entry.
        let data = Data { id: 1, content: 2 };
        contract.set(data); 

        // Read the hash
        let read_hash = contract.get(user);

        assert_eq(
            @read_hash,
            @PoseidonTrait::new().update_with(data).finalize(),
            'Bad hash for Data'
        );
    }

    #[test]
    #[available_gas(20000000)]
    fn test_add_hash() {
        let mut contract = deploy();

        let user = contract_address_const::<1>();
        set_contract_address(user);

        // Add a data entry.
        let first_data = Data { id: 1, content: 2 };
        contract.set(first_data); 
        let first_read_hash = contract.get(user);
        first_read_hash.print();

        // Add a second entry (accumulating hash)
        let second_data = Data { id: 2, content: 15 };
        contract.add(second_data);

        // Read the resulting hash
        let read_hash = contract.get(user);
        read_hash.print();

        assert_eq(
            @read_hash,
            @PoseidonTrait::new().update_with(first_data).update_with(second_data).finalize(),
            'Bad accumulating hash'
        );
    }
}
