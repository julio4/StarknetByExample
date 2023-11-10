#[starknet::interface]
trait ITarget1<TContractState> {
    fn get(self: @TContractState) -> u8;
}

#[starknet::contract]
mod Target1 {
    #[storage]
    struct Storage {
        first: u8,
    }

    #[constructor]
    fn constructor(ref self: ContractState, first: u8) {
        self.first.write(first);
    }

    #[abi(embed_v0)]
    impl Target1 of super::ITarget1<ContractState> {
        fn get(self: @ContractState) -> u8 {
            self.first.read()
        }
    }
}

#[starknet::interface]
trait ITarget2<TContractState> {
    fn get_1(self: @TContractState) -> u8;
    fn get_2(self: @TContractState) -> u8;
}

#[starknet::contract]
mod Target2 {
    #[storage]
    struct Storage {
        first: u8,
        second: u8,
    }

    #[constructor]
    fn constructor(ref self: ContractState, first: u8, second: u8) {
        self.first.write(first);
    }

    #[abi(embed_v0)]
    impl Target2 of super::ITarget2<ContractState> {
        fn get_1(self: @ContractState) -> u8 {
            self.first.read()
        }

        fn get_2(self: @ContractState) -> u8 {
            self.second.read()
        }
    }
}
