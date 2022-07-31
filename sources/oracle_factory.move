// Create and share price oracles.
module oracles::price_oracle_factory{
    use std::vector;

    use sui::object::{Self, ID, Info};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};


    ///*///////////////////////////////////////////////////////////////
    //                          MAIN OBJECTS                         //
    /////////////////////////////////////////////////////////////////*/

    // This object represents an oracle. It hold metadata for the oracle along with the data that the oracle is supposed to return.
    struct Oracle has key, store {
        info: Info,

        // Timestamp of the last update.
        last_update: u64,

        // Time between updates.
        interval: u64,

        // Minimum posts required to update the price.
        min_posts: u64,

        // Vector containing posted data.
        new_data: vector<Data>,

        // Most recent updated price (average of all written information since the last update).
        data: Data,

    }
    
    // Represents data held by the oracle.
    // Implemented to make it easier to fork the module to return more than just prices.
    struct Data has store, drop {
        // Price Data stored by the oracle.
        price: u64,
    }

    ///*///////////////////////////////////////////////////////////////
    //                          CAPABILITIES                         //
    /////////////////////////////////////////////////////////////////*/

    // Created when a new oracle is generated.
    // Represents ownership, enabling the holder to list/unlist validators.
    struct OwnerCap has key, store {
        info: Info,

        // The ID of the oracle that is owned by this contract.
        oracle_id: ID,
    }

    // Created when a validator is listed by the oracle owner, grants the ability to write data to the oracle.
    struct ValidatorCap has key, store {
        info: Info,

        // The ID of the oracle that the validator can push information to.
        oracle_id: ID,
    }

    ///*///////////////////////////////////////////////////////////////
    //                           ERROR CODES                         //
    /////////////////////////////////////////////////////////////////*/

    // Attempt to perform an operation only allowed by the owner.
    const EOwnerOnly: u64 = 0;

    // Attempt to perform an operation only allowed by a validator.
    const EValidatorOnly: u64 = 1;

    ///*///////////////////////////////////////////////////////////////
    //                     ORACLE CREATION LOGIC                     //
    /////////////////////////////////////////////////////////////////*/

    // Initialize a new oracle and send the owner capability directly to the function caller.
    public fun new_oracle(
        interval: u64,
        min_posts: u64,
        ctx: &mut TxContext,
    ): OwnerCap {
        // Create a new `Info` object and extract its id. 
        let oracle_info = object::new(ctx);
        let oracle_id = *object::info_id(&oracle_info);

        // Create a new Oracle object. Make it shared so that it can be accessed by anyone.
        let oracle = Oracle {
            info: oracle_info,
            last_update: 0,
            interval: interval,
            min_posts: min_posts,
            new_data: vector<Data>[],
            data: Data {
                price: 0,
            },
        };
        transfer::share_object(oracle);

        // Create a new OwnerCap object and return it to the caller.
        OwnerCap {
            info: object::new(ctx),
            oracle_id: oracle_id,
        }
    }

    // Create a new oracle and send the owner capability to the sender of the tx origin.
    public entry fun create_oracle(        
        interval: u64,
        min_posts: u64,
        ctx: &mut TxContext
    ) {
        // Create a new Oracle object and retreive its respective owner capability object.
        let oracle_owner_cap = new_oracle(interval, min_posts, ctx);

        // Transfer to Owner Capability to the original caller.
        transfer::transfer(oracle_owner_cap, tx_context::sender(ctx));
    }

    ///*///////////////////////////////////////////////////////////////
    //                   VALIDATOR LISTING FUNCTIONS                 //
    /////////////////////////////////////////////////////////////////*/

    // List a new validator (can only be called by the owner).
    public fun list_validator(
        self: &mut Oracle,
        validator: address,
        oracle_owner_cap: &OwnerCap,
        ctx: &mut TxContext,
    ) {
        // Check if the caller is the owner of the referenced oracle.
        check_owner(self, oracle_owner_cap);

        // Create a new ValidatorCap object.
        let validator_cap = ValidatorCap {
            info: object::new(ctx),
            oracle_id: *object::info_id(&self.info),
        };

        // Transfer the validator capability to the validator.
        transfer::transfer(validator_cap, validator);
    }


    ///*///////////////////////////////////////////////////////////////
    //                    PRICE POSTS + UPDATE LOGIC                 //
    /////////////////////////////////////////////////////////////////*/

    // Force the oracle to update its pricing data (can only be called by the owner of the oracle).
    public fun force_update(
        self: &mut Oracle,
        oracle_owner_cap: &OwnerCap,
        timestamp: u64,
    ): u64 {
        // Check if the caller is the owner of the referenced oracle.
        check_owner(self, oracle_owner_cap);

        // Update the pricing data.
        update_data(self, timestamp)
    }

    // Write data to the oracle (can only be called by a validator).
    public entry fun write_data(self: &mut Oracle, validator_cap: &mut ValidatorCap, timestamp: u64, data: Data) {
        // Ensure the caller is a verified validator.
        check_validator(self, validator_cap);

        // Push the data to the Oracle object's `new_data` vector.
        vector::push_back(&mut self.new_data, data);

        // If the oracle has enough posts or has not been updated within its interval, update the data.
        if(vector::length(&self.new_data) >= self.min_posts || timestamp - self.last_update > self.interval) {
            // Update the data.
            update_data(self, timestamp);
        }
    }

    // Update the oracle's data by calculating the averages of the supplied information. Return the new price.
    fun update_data(self: &mut Oracle, timestamp: u64): u64 {
        // Calculate the average of all data in the `new_data` vector.
        let total = 0;
        let data_vector = &mut self.new_data;
        let size = vector::length(data_vector);
        
        let i = 0;
        while(size>i) {
            let data = vector::borrow(data_vector, i);
            total = total + data.price;
            i = i + 1;
        };

        // Calculate the average price.
        let average = total / size;

        // Update the new price, clear the `new_data` vector, and update the `last_update` timestamp.
        self.data.price = *&average;
        self.new_data = vector<Data>[];
        self.last_update = timestamp;

        average
    }

    ///*///////////////////////////////////////////////////////////////
    //                           VIEW METHODS                        //
    /////////////////////////////////////////////////////////////////*/

    // This function can be called by anyone to read an oracle's data.
    public fun read_data(
        // The ID of the oracle object.
        self: &Oracle,
    ): u64 {
        self.data.price
    }

    ///*///////////////////////////////////////////////////////////////
    //                  INTERNAL UTILITY FUNCTIONS                   //
    /////////////////////////////////////////////////////////////////*/

    // Ensure that an OwnerCap object matches the oracle object.
    fun check_owner(self: &mut Oracle, admin_cap: &OwnerCap) {
        // Ensure the caller is the owner of the Oracle object.
        assert!(object::id(self) == &admin_cap.oracle_id, EOwnerOnly);
    }

    // Ensure that an ValidatorCap object matches the oracle object.
    fun check_validator(self: &mut Oracle, validator_cap: &ValidatorCap) {
        // Ensure the caller is a verified validator of the Oracle object.
        assert!(object::id(self) == &validator_cap.oracle_id, EValidatorOnly);
    }
}