use starknet::{ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait,
};
use hello_starknet::counter::{
    Counter, ICounterDispatcher, ICounterDispatcherTrait, ICounterSafeDispatcher,
    ICounterSafeDispatcherTrait
};
// use testing_events::contract::{
//     SpyEventsChecker, ISpyEventsCheckerDispatcher, ISpyEventsCheckerDispatcherTrait
// };

pub mod Accounts {
    use starknet::ContractAddress;
    use core::traits::TryInto;

    pub fn admin() -> ContractAddress {
        'admin'.try_into().unwrap()
    }

    pub fn account1() -> ContractAddress {
        'account1'.try_into().unwrap()
    }
}

fn deploy(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let constructor_args = array![Accounts::admin().into()];
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

#[test]
fn test_deployment_was_successful() {
    let contract_address = deploy("Counter");

    let counter_dispatcher = ICounterDispatcher { contract_address };

    let admin_address: ContractAddress = counter_dispatcher.get_admin();

    assert_eq!(Accounts::admin(), admin_address);
}

#[test]
#[should_panic(expected: 'caller not admin')]
fn test_set_count_should_panic_when_called_from_unauthorised_address() {
    let contract_address = deploy("Counter");

    let counter_dispatcher = ICounterDispatcher { contract_address };

    start_cheat_caller_address(contract_address, Accounts::account1());

    counter_dispatcher.set_count(99);
}

// SafeDispatcher
#[test]
fn test_set_owner_should_panic_when_called_with_zero_value() {
    let contract_address = deploy("Counter");

    let counter_safe_dispatcher = ICounterSafeDispatcher { contract_address };

    start_cheat_caller_address(contract_address, Accounts::admin());

    match counter_safe_dispatcher.set_count(0) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => { assert(*panic_data.at(0) == 'zero value', *panic_data.at(0)); }
    }
}

#[test]
fn test_event_was_emitted_on_set_count() {
    let contract_address = deploy("Counter");
    let counter_dispatcher = ICounterDispatcher { contract_address };

    let mut spy = spy_events();
    counter_dispatcher.set_count(99);

    spy
        .assert_emitted(
            @array![
                (contract_address,
                Counter::Event::SetCountCalled(
                    Counter::SetCountCalled { owner: contract_address, value: 99 }
                ))
            ]
        );
    // assert(, '');
}
