mod tests {
    use core::{
        serde::Serde,
        array::ArrayTrait,
        option::OptionTrait,
        traits::{Into, TryInto}
    };
    use starknet::{
        syscalls::deploy_syscall,
        ContractAddress, ClassHash, contract_address_const
    };
    use factory::{
        factory::{
            Factory, IFactoryDispatcher, IFactoryDispatcherTrait,
        },
        target::{Target1, Target2, ITarget1Dispatcher, ITarget1DispatcherTrait, ITarget2Dispatcher, ITarget2DispatcherTrait}
    };

    /// Deploy a factory contract
    fn deploy_factory() -> IFactoryDispatcher {
        let owner_address: ContractAddress = contract_address_const::<'owner'>();
        let deployed_contract_address = contract_address_const::<'factory'>();

        let (factory_address, _) = deploy_syscall(
            Factory::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![].span(),
            false
        ).expect('failed to deploy factory');

        IFactoryDispatcher { contract_address: factory_address }
    }

    #[test]
    #[available_gas(20000000)]
    fn test_deploy_factory() {
        let factory = deploy_factory();
    }

    #[test]
    #[available_gas(20000000)]
    fn test_target1_deploy() {
        let factory = deploy_factory();
        // Grant role UPGRADE to OWNER

        let value = 10;
        factory.set_class_hash(Target1::TEST_CLASS_HASH.try_into().unwrap());

        let current_timestamp = starknet::get_block_timestamp();
        let target1_address = factory.create(array![value.into()].span());
        let target1 = ITarget1Dispatcher { contract_address: target1_address };

        assert(target1.get() == value, 'Target1: wrong value');
        assert(factory.get_latest_address().unwrap() == target1_address, 'Factory: latest address');

        let deployed_instance = factory.get_latest_instance().unwrap();
        assert(deployed_instance.contract_address == target1_address, 'Factory: instance address');
        assert(deployed_instance.class_hash == Target1::TEST_CLASS_HASH.try_into().unwrap(), 'Factory: instance class hash');
        assert(deployed_instance.deployed_at != current_timestamp, 'Factory: instance timestamp');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_target2_deploy() {
        let factory = deploy_factory();

        let first = 10;
        let second = 20;
        factory.set_class_hash(Target2::TEST_CLASS_HASH.try_into().unwrap());

        let target2_address = factory.create(array![first.into(), second.into()].span());
        let target2 = ITarget2Dispatcher { contract_address: target2_address };

        assert(target2.get_1() == first, 'Target2: wrong first value');
        assert(target2.get_2() == second, 'Target2: wrong second value');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_upgrade_class_hash() {
        let factory = deploy_factory();

        let value = 10;
        factory.set_class_hash(Target1::TEST_CLASS_HASH.try_into().unwrap());
        let target1_address = factory.create(array![value].span());

        let first = 10;
        let second = 20;
        factory.set_class_hash(Target2::TEST_CLASS_HASH.try_into().unwrap());
        let target2_address = factory.create(array![first.into(), second.into()].span());
        let target2 = ITarget2Dispatcher { contract_address: target2_address };

        assert(target2.get_1() == first, 'Target2: wrong first value');
        assert(target2.get_2() == second, 'Target2: wrong second value');
    }
}
