// Oracle Factory contract that is used to create and interact with new oracles.
module oracles::price_oracle_factory{
    use sui::object::{Self, ID, Info};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};


    ///*///////////////////////////////////////////////////////////////
    //                      MAIN FUNCTIONALITY OBJECTS               //
    /////////////////////////////////////////////////////////////////*/

    // This object represents an oracle. A new `Oracle` object is created when a new oracle is initialized.
    // It holds data about the oracle and its current state.
    struct Oracle has key, store {
        info: Info,

        // Timestamp of the last update.
        last_update: u64,

        // Interval before the data is updated.
        interval: u64,

        // Minimum posts required to update the data.
        min_posts: u8,

        // Current data.
        data: Data,
    }

    struct Data has store {
        // Price Data stored by the oracle.
        price: u64,
    }

    ///*///////////////////////////////////////////////////////////////
    //                          CAPABILITIES                         //
    /////////////////////////////////////////////////////////////////*/

    // This object is created when a new oracle is generated.
    // It enables the holder to list/unlist validators and deprecate the oracle.
    struct OracleOwnerCap has key, store {
        info: Info,

        // The ID of the oracle that is owned by this contract.
        oracle_id: ID,
    }

    // This object is created when a validator listed (and destroyed when unlisted) by the oracle owner.
    struct OracleValidatorCap has key, store {
        info: Info,

        // The ID of the oracle that the validator can push information to.
        oracle_id: ID,
    }

    ///*///////////////////////////////////////////////////////////////
    //                     ORACLE CREATION LOGIC                     //
    /////////////////////////////////////////////////////////////////*/

    // Initialize a new oracle and send it to the direct caller of this contract.
    public fun new_oracle(
        // The interval before the data is updated.
        interval: u64,
        // The minimum posts required to update the data.
        min_posts: u8,
        // Transaction Context.
        ctx: &mut TxContext,
    ): OracleOwnerCap {
        // Create a new `Info` object and extract its id. This object will be used to create an Oracle object.
        let oracle_info = object::new(ctx);
        let oracle_id = *object::info_id(&oracle_info);

        // Create a new Oracle object. Make it shared so that it can be accessed by anyone.
        let oracle = Oracle {
            info: oracle_info,
            last_update: 0,
            interval: interval,
            min_posts: min_posts,
            data: Data {
                price: 0,
            },
        };
        transfer::share_object(oracle);

        // Create a new OracleOwnerCap object and return it to the caller.
        OracleOwnerCap {
            info: object::new(ctx),
            oracle_id: oracle_id,
        }
    }

    public entry fun create_oracle(        
        // The interval before the data is updated.
        interval: u64,
        // The minimum posts required to update the data.
        min_posts: u8,
        // Transaction Context.
        ctx: &mut TxContext
    ) {
        // Create a new Oracle object and retreive its respective owner capability object.
        let oracle_owner_cap = new_oracle(interval, min_posts, ctx);

        // Transfer to Owner Capability to the original caller.
        transfer::transfer(oracle_owner_cap, tx_context::sender(ctx));
    } 
}