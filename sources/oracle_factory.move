// Oracle Factory contract that is used to create and interact with new oracles.
module oracles::oracle_factory{
    use sui::object::{Self, ID, Info};
    use sui::tx_context::{Self, TxContext};

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
}