module my_first_package::m3 {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
    }

    public fun magic(self: &Sword): u64 {
        self.magic
    }

    public fun strength(self: &Sword): u64 {
        self.strength
    }

    public entry fun sword_create(magic: u64, strength: u64, recipient: address, ctx: &mut TxContext) {
        use sui::transfer;
        // use sui::tx_context;
        
        // create a sword
        let sword = Sword {
            id:       object::new(ctx),
            magic:    magic,
            strength: strength,
        };
        
        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    public entry fun sword_transfer(sword: Sword, recipient: address, _ctx: &mut TxContext) {
        use sui::transfer;

        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    #[test]
    fun test_sword_transactions() {
        use sui::test_scenario;

        let admin         = @0xABBA;
        let initial_owner = @0xCAFE;
        let final_owner   = @0xFACE;

        // first transaction executed by admin
        let scenario = &mut test_scenario::begin(&admin);
        {
            // create the sword and transfer it to the initial owner
            sword_create(42, 7, initial_owner, test_scenario::ctx(scenario));
        };
        // second transaction executed by the initial sword owner
        test_scenario::next_tx(scenario, &initial_owner);
        {
            // extract the sword owned by the initial owner
            let sword = test_scenario::take_owned<Sword>(scenario);
            // transfer the sword to the final owner
            sword_transfer(sword, final_owner, test_scenario::ctx(scenario));
        };
        // third transaction executed by the final sword owner
        test_scenario::next_tx(scenario, &final_owner);
        {
            // extract the sword owned by the final owner
            let sword = test_scenario::take_owned<Sword>(scenario);
            // verify that the sword has expected properties
            assert!(magic(&sword) == 42 && strength(&sword) == 7, 1);
            // return the sword to the object pool (it cannot be simply "dropped")
            test_scenario::return_owned(scenario, sword)
        }
    }

    #[test]
    public fun test_sword_create() {
        use sui::transfer;
        use sui::tx_context;
        use std::debug;

        // create a dummy TxContext for testing
        let ctx = tx_context::dummy();

        // create a sword
        let sword = Sword {
            id:       object::new(&mut ctx),
            magic:    42,
            strength: 7,
        };

        // check if accessor functions return correct values
        assert!(magic(&sword) == 42 && strength(&sword) == 7, 1);

        debug::print(&sword);


        // create a dummy address and transfer the sword
        let dummy_address = @0xCAFE;
        transfer::transfer(sword, dummy_address);
    }
}
