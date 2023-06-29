module spacehunter::farming {
    use spacehunter::mint::{Self, MinterData};
    use spacehunter::hunter::{Self, Hunter};

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::clock::{Self, Clock};
    use sui::bcs;
    use sui::ed25519;
    use std::vector;
    use std::string::{String};

    const ENotAdmin : u64 = 0;
    const EFarming : u64 = 1;
    const EInvalidFarming : u64 = 2;
    const ENotYetFarming : u64 = 3;
    const EInvalidHunter : u64 = 4;
    const EInvalidExchanger : u64 = 5;
    const EInvalidSig : u64 = 6;
    const EInvalidData : u64 = 7;

    struct FarmingData has key, store {
        id: UID,
        owner: address,
        exchanger_public_keys: vector<vector<u8>>,
        farmers: VecMap<address, Farmer>,
        time_per_farming: u64,
    }

    struct Farmer has store {
        last_time: u64,
        hunter_id: address,
        farming: bool
    }
    
    fun init(ctx: &mut TxContext) {
        let minter_data = FarmingData {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            exchanger_public_keys: vector::empty(),
            farmers: vec_map::empty(),
            time_per_farming: 3600000,
        };
        transfer::share_object(minter_data);
    }

    //------------------PUBLIC FRIEND FUNCTIONS---------------------//  

    public fun start_farming(farm_data: &mut FarmingData, hunter: &Hunter, clock: &Clock, ctx:&mut TxContext) {
        let farmer_addr = tx_context::sender(ctx);
        let now = clock::timestamp_ms(clock);
        if(!vec_map::contains(&farm_data.farmers, &farmer_addr)) {
            vec_map::insert(&mut farm_data.farmers, farmer_addr, 
                Farmer {
                    last_time: 0,
                    hunter_id: @0x00,
                    farming: false
                }
            );
        };
        let farmer = vec_map::get_mut(&mut farm_data.farmers, &farmer_addr);
        assert!(!farmer.farming,EFarming);
        assert!(now >  farmer.last_time + farm_data.time_per_farming,EInvalidFarming);
        farmer.hunter_id = object::id_address(hunter);
        farmer.farming = true;
    }

    public entry fun cancel_farming(farm_data: &mut FarmingData, clock: &Clock, ctx:&mut TxContext) {
        let farmer_addr = tx_context::sender(ctx);
        let farmer = vec_map::get_mut(&mut farm_data.farmers, &farmer_addr);
        assert!(!farmer.farming,EFarming);
        farmer.last_time = clock::timestamp_ms(clock);
        farmer.hunter_id = @0x00;
        farmer.farming =  false;
    }

    public fun end_farming(farm_data: &mut FarmingData, minter_data: &mut MinterData, hunter: Hunter, clock: &Clock, signature: vector<u8>, exchanger: vector<u8>, exp: u64, amount_stones: vector<u8>, symbol_stones: vector<String>, ctx:&mut TxContext) {
        let farmer_addr = tx_context::sender(ctx);
        let now = clock::timestamp_ms(clock);
        let farmer = vec_map::get_mut(&mut farm_data.farmers, &farmer_addr);
        assert!(farmer.farming,EFarming);
        assert!(farmer.hunter_id == object::id_address(&hunter),EInvalidHunter);
        assert!(vector::contains(&farm_data.exchanger_public_keys, &exchanger),EInvalidExchanger);
        let raw_msg = raw_msg_farming(&exp, &amount_stones, &symbol_stones);
        assert!(ed25519::ed25519_verify(&signature, &exchanger, &raw_msg),EInvalidSig);
        hunter::upgrade_level(&mut hunter, exp);
        mint_stones(minter_data, amount_stones, symbol_stones,ctx);
        farmer.last_time = now;
        farmer.hunter_id = @0x00;
        farmer.farming = false;
        transfer::public_transfer(hunter, farmer_addr);
    }

    //------------------ADMIN FUNCTIONS---------------------//

    public entry fun add_exchanger(farm_data: &mut FarmingData, exchanger : vector<u8>, ctx: &mut TxContext) {
        assert!(is_admin(farm_data.owner, ctx),ENotAdmin);
        vector::push_back(&mut farm_data.exchanger_public_keys, exchanger);
    }

    public entry fun remove_exchanger(farm_data: &mut FarmingData, exchanger : vector<u8>, ctx: &mut TxContext) {
        assert!(is_admin(farm_data.owner, ctx),ENotAdmin);
        let (_, index) = vector::index_of(&farm_data.exchanger_public_keys, &exchanger);
        vector::remove(&mut farm_data.exchanger_public_keys, index);
    }

    //------------------INTERNAL FUNCTIONS---------------------//

    fun is_admin(owner: address,ctx: &mut TxContext): bool {
        (tx_context::sender(ctx) == @admin || tx_context::sender(ctx) == owner)
    }

    fun raw_msg_farming(exp: &u64, amount_stones: &vector<u8>, symbol_stones: &vector<String>) : vector<u8> { 
        let raw_msg = vector::empty();
        vector::append(&mut raw_msg, bcs::to_bytes(exp));
        vector::append(&mut raw_msg, bcs::to_bytes(amount_stones));
        vector::append(&mut raw_msg, bcs::to_bytes(symbol_stones));
        raw_msg
    }

    fun mint_stones(minter_data: &mut MinterData, amount_stones: vector<u8>, symbol_stones: vector<String>, ctx: &mut TxContext) {
        while(!vector::is_empty(&symbol_stones)){
            let j = 0;
            let symbol_stone = vector::pop_back(&mut symbol_stones);
            let amount_stone = vector::pop_back(&mut amount_stones);
            while(j < amount_stone){
                mint::mint_stone(minter_data, symbol_stone, ctx);
                j = j + 1;
            };
        };
    }
}

