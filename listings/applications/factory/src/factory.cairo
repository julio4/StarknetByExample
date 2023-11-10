/// INTERFACE
use starknet::{ContractAddress, ClassHash};
#[starknet::interface]
trait IFactory<TContractState> {
    /// Create a new contract
    fn create(ref self: TContractState, calldata: Span<felt252>) -> ContractAddress;
    /// Set/Update the class hash of the contract
    fn set_class_hash(ref self: TContractState, class_hash: ClassHash);
    /// Get last deployed instance contract address
    fn get_latest_address(ref self: TContractState) -> Option<ContractAddress>;
    /// Get last deployed instance
    fn get_latest_instance(ref self: TContractState) -> Option<Instance>;
}

/// An instance in a factory is a deployed contract from a given class hash
#[derive(Drop, Serde, starknet::Store)]
struct Instance {
    contract_address: ContractAddress,
    class_hash: ClassHash,
    deployed_at: u64,
}

#[starknet::contract]
mod Factory {
    use core::zeroable::Zeroable;
    use super::Instance;
    use starknet::{
        event::EventEmitter, syscalls::deploy_syscall, ContractAddress, ClassHash,
        get_caller_address, get_block_info,
        contract_address::ContractAddressZeroable
    };

    #[storage]
    struct Storage {
        /// Store the class hash
        class_hash: ClassHash,
        /// Instances manager: keep track of instances
        instances: LegacyMap::<ContractAddress, Instance>,
        /// Latest deployed instance contract
        latest: ContractAddress,
        /// Role manager
        roles: LegacyMap::<(Role, ContractAddress), bool>,
    }

    // *************************************************************************
    // EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RoleGranted: RoleGranted,
        RoleRevoked: RoleRevoked,
        ContractClassUpgrade: ContractClassUpgrade,
        ContractDeployment: ContractDeployment,
    }

    #[derive(Drop, starknet::Event)]
    struct RoleGranted {
        role: felt252,
        account: ContractAddress,
        granted_by: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct RoleRevoked {
        role: felt252,
        account: ContractAddress,
        revoked_by: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct ContractClassUpgrade {
        class_hash: ClassHash,
        declared_at: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct ContractDeployment {
        address: ContractAddress,
        class_hash: ClassHash,
        deployed_at: u64,
    }

    // *************************************************************************
    // ACCESS CONTROL
    // *************************************************************************
    use super::access_control::{Role, Error, IAccessControl};

    #[abi(per_item)]
    impl FactoryAccessControl of IAccessControl<ContractState> {
        /// Grant a role to an address
        #[external(v0)]
        fn grant_role(ref self: ContractState, role: Role, address: ContractAddress) {
            self.only_role(Role::OWNER);

            // Only grant if not already granted
            if !self.has_role(role, address) {
                self.roles.write((role, address), true);
                self
                    .emit(
                        RoleGranted {
                            role: role.into(), account: address, granted_by: get_caller_address(),
                        }
                    );
            }
        }

        /// Revoke a role to an address
        #[external(v0)]
        fn revoke_role(ref self: ContractState, role: Role, address: ContractAddress) {
            self.only_role(Role::OWNER);

            // Only revoke if has the role
            if self.has_role(role, address) {
                self.roles.write((role, address), false);
                self
                    .emit(
                        RoleRevoked {
                            role: role.into(), account: address, revoked_by: get_caller_address(),
                        }
                    );
            }
        }

        /// Check if an address has a role
        fn has_role(self: @ContractState, role: Role, address: ContractAddress) -> bool {
            self.roles.read((role.into(), address))
        }

        /// Assert that the caller has the given role
        fn only_role(self: @ContractState, role: Role) {
            if !self.has_role(role, get_caller_address()) {
                panic_with_felt252(Error::NOT_ALLOWED);
            }
        }
    }

    // *************************************************************************
    // FACTORY LOGIC
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.latest.write(ContractAddressZeroable::zero());

        // Initial 'OWNER' role is not 'granted' but 'assigned' (no event)
        self.roles.write((Role::OWNER, get_caller_address()), true);
    }

    #[abi(embed_v0)]
    impl Factory of super::IFactory<ContractState> {
        fn create(ref self: ContractState, calldata: Span<felt252>) -> ContractAddress {
            self.only_role(Role::OWNER);

            let deployed_address = self._deploy(calldata);

            self
                .emit(
                    ContractDeployment {
                        address: deployed_address,
                        class_hash: self.instances.read(deployed_address).class_hash,
                        deployed_at: self.instances.read(deployed_address).deployed_at
                    }
                );
            deployed_address
        }

        fn set_class_hash(ref self: ContractState, class_hash: ClassHash) {
            self.only_role(Role::UPGRADE);

            self.class_hash.write(class_hash);

            self
                .emit(
                    Event::ContractClassUpgrade(
                        ContractClassUpgrade {
                            class_hash: self.class_hash.read(),
                            declared_at: starknet::get_block_timestamp(),
                        }
                    )
                );
        }

        fn get_latest_address(ref self: ContractState) -> Option<ContractAddress> {
            match self.latest.read().is_zero() {
                bool::False => Option::None,
                bool::True => Option::Some(self.latest.read()),
            }
        }

        fn get_latest_instance(ref self: ContractState) -> Option<Instance> {
            match self.latest.read().is_zero() {
                bool::False => Option::None,
                bool::True => Option::Some(self.instances.read(self.latest.read())),
            }
        }
    }

    // INTERNAL FUNCTIONS
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _upgrade(ref self: ContractState, class_hash: ClassHash) {
            self.class_hash.write(class_hash);
        }

        fn _deploy(ref self: ContractState, calldata: Span<felt252>) -> ContractAddress {
            // Contract deployment
            let (deployed_address, _) = deploy_syscall(self.class_hash.read(), 0, calldata, false)
                .expect('failed to deploy');

            // Store the deployed contract
            self
                .instances
                .write(
                    deployed_address,
                    Instance {
                        contract_address: deployed_address,
                        class_hash: self.class_hash.read(),
                        deployed_at: starknet::get_block_timestamp(),
                    }
                );

            // Update latest deployed contract
            self.latest.write(deployed_address);

            deployed_address
        }
    }
}

// ** ACCESS CONTROL **
// We can define roles that can be assigned to each accounts
// Roles can be used to restrict access to certain functions
mod access_control {
    #[derive(Copy, Drop, Serde, Hash)]
    enum Role {
        OWNER,
        UPGRADE,
    }

    impl RoleIntoFelt of Into<Role, felt252> {
        fn into(self: Role) -> felt252 {
            match self {
                Role::OWNER => 'OWNER',
                Role::UPGRADE => 'UPGRADE',
            }
        }
    }

    mod Error {
        const NOT_ALLOWED: felt252 = 'NOT_ALLOWED';
    }

    use starknet::ContractAddress;
    trait IAccessControl<TContractState> {
        fn grant_role(ref self: TContractState, role: Role, address: ContractAddress);
        fn revoke_role(ref self: TContractState, role: Role, address: ContractAddress);
        fn has_role(self: @TContractState, role: Role, address: ContractAddress) -> bool;
        fn only_role(self: @TContractState, role: Role);
    }
}
