module spacehunter::crafting {
    use spacehunter::stone::{Self, Stone};
    use spacehunter::mint::{Self, MinterData};
    use spacehunter::hunter::{Self, Hunter};

    use std::string::{String};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use std::vector;
    use sui::dynamic_field;
    use sui::dynamic_object_field as dof;

    const ENotAdmin : u64 = 0;
    const EInvalidVectorStone: u64 = 1;
    const EInvalidStone: u64 = 1;

    struct CraftingData has key, store {
        id: UID,
        owner: address,
    }

    struct Material has store {
        //Symbol stone to burn
        symbol: String,
        //Amount stone to burn
        amount: u64,
    }

    struct MaterialAdded has copy, drop {
        symbol_item: String,
    }

    struct ItemEquipped has copy, drop { 
        hunter_id: ID,
        type_item: String,
    }

    struct ItemRemoved has copy, drop { 
        hunter_id: ID,
        type_item: String,
    }

    fun init(ctx: &mut TxContext) {
        let minter_data = CraftingData {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
        };
        transfer::share_object(minter_data);
    }

    //------------------PUBLIC FRIEND FUNCTIONS---------------------//  

    public entry fun crafting_sword(carfting_data: &CraftingData, minter_data : &mut MinterData, stones: vector<Stone>, symbol_sword: String,ctx: &mut TxContext) {
        let material = dynamic_field::borrow(&carfting_data.id, symbol_sword);
        burn_stones(material, stones, ctx);
        mint::mint_sword(minter_data, symbol_sword, ctx);
    }

    public entry fun equip<T: key + store>(hunter: Hunter, item: T, type_item: String, ctx: &mut TxContext) {
        dof::add(hunter::get_mut_id(&mut hunter), type_item, item);
        event::emit(ItemEquipped {
            hunter_id: object::id(&hunter),
            type_item
        });
        transfer::public_transfer(hunter, tx_context::sender(ctx));
    }

    public entry fun cancel_equip<T: key + store>(hunter: Hunter, type_item: String, ctx: &mut TxContext) {
        let item : T =  dof::remove(hunter::get_mut_id(&mut hunter),type_item);
         event::emit(ItemRemoved {
            hunter_id: object::id(&hunter),
            type_item
        });
        transfer::public_transfer(hunter, tx_context::sender(ctx));
        transfer::public_transfer(item, tx_context::sender(ctx));
    }

    //------------------ADMIN FUNCTIONS---------------------//

    public entry fun add_material(carfting_data: &mut CraftingData,symbol_item: String , symbol: String, amount: u64, ctx: &mut TxContext) {
        assert!(is_admin(carfting_data.owner, ctx),ENotAdmin);
        dynamic_field::add(&mut carfting_data.id, symbol_item, Material {
            symbol,
            amount
        });
        event::emit(MaterialAdded {
            symbol_item,
        });
    }
    
    public entry fun edit_material(carfting_data: &mut CraftingData,symbol_item: String , symbol: String, amount: u64, ctx: &mut TxContext) {
        assert!(is_admin(carfting_data.owner, ctx),ENotAdmin);
        let material :&mut  Material = dynamic_field::borrow_mut(&mut carfting_data.id, symbol_item);
        material.symbol = symbol; 
        material.amount = amount;
    }

    //------------------INTERNAL FUNCTIONS---------------------//

    fun is_admin(owner: address,ctx: &mut TxContext): bool {
        (tx_context::sender(ctx) == @admin || tx_context::sender(ctx) == owner)
    }

    fun burn_stones(material: &Material, stones : vector<Stone>, ctx: &mut TxContext) {
        assert!(material.amount == vector::length(&stones),EInvalidVectorStone);
        while(!vector::is_empty(&stones)){
            let stone = vector::pop_back(&mut stones);
            assert!(material.symbol == stone::get_symbol(&stone),EInvalidStone);
            stone::burn(stone, ctx);
        };
        vector::destroy_empty(stones);
    }
}

