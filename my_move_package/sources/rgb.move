module my_first_package::rgb {
    use sui::object::UID;
    use sui::object;
    use sui::tx_context::TxContext;
    use sui::tx_context;
    use sui::transfer;

    struct ColorObject has key {
        id:    UID,
        red:   u8,
        green: u8,
        blue:  u8,
    }

    fun new(red: u8, green: u8, blue: u8, ctx: &mut TxContext): ColorObject {
        return ColorObject {
            id: object::new(ctx),
            red,
            green,
            blue,
        }
    }

    public entry fun create(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::transfer(color_object, tx_context::sender(ctx))
    }

    public fun get_color(self: &ColorObject): (u8, u8, u8) {
        return (self.red, self.green, self.blue)
    }

    public entry fun copy_into(from_object: &ColorObject, into_object: &mut ColorObject) {
        into_object.red   = from_object.red;
        into_object.green = from_object.green;
        into_object.blue  = from_object.blue;
    }

    public entry fun delete(object: ColorObject) {
        let ColorObject { id, red: _, green: _, blue: _ } = object;
        object::delete(id);
    }

    // ------------- test ------------- //

    #[test]
    fun test() {
        use sui::test_scenario;
        use std::debug;

        let owner = @0x1;
        let scenario = &mut test_scenario::begin(&owner);
        {
            create(255, 0, 255, test_scenario::ctx(scenario));
        
            debug::print(&1);        
        };

        let not_owner = @0x2;
        test_scenario::next_tx(scenario, &not_owner);
        {
            assert!(!test_scenario::can_take_owned<ColorObject>(scenario), 0);

            debug::print(&2);
        };

        test_scenario::next_tx(scenario, &owner);
        {
            let object = test_scenario::take_owned<ColorObject>(scenario);
            let (red, green, blue) = get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            test_scenario::return_owned(scenario, object);

            debug::print(&3);
        };

        let (id1, id2) = {
            let ctx = test_scenario::ctx(scenario);
            create(255, 255, 255, ctx);
            let id1 = object::id_from_address(tx_context::last_created_object_id(ctx));
            create(0, 0, 0, ctx);
            let id2 = object::id_from_address(tx_context::last_created_object_id(ctx));
            (id1, id2)
        };

        test_scenario::next_tx(scenario, &owner);
        {
            let obj1 = test_scenario::take_owned_by_id<ColorObject>(scenario, id1);
            let obj2 = test_scenario::take_owned_by_id<ColorObject>(scenario, id2);

            let (red, green, blue) = get_color(&obj1);
            assert!(red == 255 && green == 255 && blue == 255, 0);

            copy_into(&obj2, &mut obj1);

            debug::print(&obj1);
            debug::print(&obj2); 

            let (red, green, blue) = get_color(&obj2);
            assert!(red == 0 && green == 0 && blue == 0, 0);

            test_scenario::return_owned(scenario, obj1);
            test_scenario::return_owned(scenario, obj2);
        };

        test_scenario::next_tx(scenario, &owner);
        {
            let obj1 = test_scenario::take_owned_by_id<ColorObject>(scenario, id1);
            let (red, green, blue) = get_color(&obj1);
            assert!(red == 0 && green == 0 && blue == 0, 0);
            test_scenario::return_owned(scenario, obj1);
        };
    }

    #[test]
    fun test2() {
        use sui::test_scenario;
        use std::debug;

        let owner = @0x1;

        let scenario = &mut test_scenario::begin(&owner);
        {
            let ctx = test_scenario::ctx(scenario);
            create(255, 0, 255, ctx);
        };
        // Delete the ColorObject we just created.
        test_scenario::next_tx(scenario, &owner);
        {
            let object = test_scenario::take_owned<ColorObject>(scenario);
            delete(object);
        };
        // Verify that the object was indeed deleted.
        test_scenario::next_tx(scenario, &owner);
        {
            let own = test_scenario::can_take_owned<ColorObject>(scenario);
            debug::print(&own);
            assert!(!test_scenario::can_take_owned<ColorObject>(scenario), 0);
        }
    }
}
