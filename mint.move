module spacehunter::mint {
    friend spacehunter::farming;
    friend spacehunter::crafting;

    use spacehunter::hunter;
    use spacehunter::stone;
    use spacehunter::item;
    use spacehunter::sword;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::vec_map::{Self, VecMap};
    use std::string::{Self, String};
    use std::vector;
    

    const ENotAdmin : u64 = 0;
    
    struct MinterData has key, store {
        id: UID,
        owner: address,
        exchanger_addresses: vector<address>,
        hunter_datas: VecMap<String, HunterData>,
        item_datas : VecMap<String, ItemData>,
        sword_datas: VecMap<String, SwordData>,
        stone_datas : VecMap<String, StoneData>
    }

    struct HunterData has store {
        name: String,
        image_url: String,
        next_token_id: u64,
        hp: u64,
        speed: u64,
        attack: u64,
        defend: u64,
    }

    struct ItemData has store {
        name: String,
        image_url: String,
        type: String,
        rarity: String,
        intrinsic_attribute: String,
        next_token_id: u64,
    }

    struct StoneData has store {
        name: String,
        image_url: String,
        type: String,
        rarity: String, 
        next_token_id: u64,
    }
    
    struct SwordData has store {
        name: String,
        image_url: String,
        type: String,
        rarity: String,
        strength: u64,
        intrinsic_attribute: String,
        next_token_id: u64,
    }

    struct DataAdded has copy, drop {
        symbol: String,
        type: String,
    }

    fun init(ctx: &mut TxContext) {
        let minter_data = MinterData {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            exchanger_addresses: vector::empty(),
            hunter_datas: vec_map::empty(),
            item_datas: vec_map::empty(),
            sword_datas: vec_map::empty(),
            stone_datas: vec_map::empty()
        };
        transfer::share_object(minter_data);
    }

    //------------------PUBLIC FUNCTIONS---------------------//  

    public entry fun mint_hunter(minter_data: &mut MinterData, symbol_hunter: String , ctx: &mut TxContext) {    
        let hunter_data = vec_map::get_mut(&mut minter_data.hunter_datas,&symbol_hunter);
        let token_name = get_token_name(hunter_data.next_token_id, hunter_data.name);
        
        hunter::mint(token_name, hunter_data.hp, hunter_data.speed, hunter_data.attack, hunter_data.defend,symbol_hunter,  hunter_data.image_url, ctx);

        hunter_data.next_token_id = hunter_data.next_token_id + 1;
    }

    //------------------PUBLIC FRIEND FUNCTIONS---------------------//  

    public(friend) entry fun mint_stone(minter_data: &mut MinterData, symbol_stone: String , ctx: &mut TxContext) {    
        let stone_data = vec_map::get_mut(&mut minter_data.stone_datas,&symbol_stone);
        let token_name = get_token_name(stone_data.next_token_id, stone_data.name);
        
        stone::mint(token_name, symbol_stone, stone_data.image_url, stone_data.type, stone_data.rarity, ctx);

        stone_data.next_token_id = stone_data.next_token_id + 1;
    }

    public entry fun mint_item(minter_data: &mut MinterData, symbol_item: String , ctx: &mut TxContext) {    
        let item_data = vec_map::get_mut(&mut minter_data.item_datas, &symbol_item);
        let token_name = get_token_name(item_data.next_token_id, item_data.name);
        
        item::mint(token_name, symbol_item , item_data.image_url, item_data.type, item_data.rarity, item_data.intrinsic_attribute, ctx);

        item_data.next_token_id = item_data.next_token_id + 1;
    }

    public(friend) entry fun mint_sword(minter_data: &mut MinterData, symbol_sword: String , ctx: &mut TxContext) {    
        let sword_data = vec_map::get_mut(&mut minter_data.sword_datas, &symbol_sword);
        let token_name = get_token_name(sword_data.next_token_id, sword_data.name);
        
        sword::mint(token_name, symbol_sword, sword_data.image_url, sword_data.strength ,sword_data.intrinsic_attribute, ctx);

        sword_data.next_token_id = sword_data.next_token_id + 1;
    }

    //------------------ADMIN FUNCTIONS---------------------//

    public entry fun add_exchanger(minter_data: &mut MinterData, exchanger_address : address, ctx: &mut TxContext) {
        assert!(is_admin(minter_data.owner, ctx),ENotAdmin);
        vector::push_back(&mut minter_data.exchanger_addresses, exchanger_address);
    }

    public entry fun add_hunter_data(minter_data: &mut MinterData, hp: u64, speed: u64, attack: u64, defend: u64, symbol_hunter: String, name: String, image_url: String, ctx: &mut TxContext) {
        assert!(is_admin(minter_data.owner, ctx),ENotAdmin);
        vec_map::insert(&mut minter_data.hunter_datas, symbol_hunter, HunterData {
            name,
            image_url,
            next_token_id : 1,
            hp,
            speed,
            attack,
            defend
        });
        event::emit(DataAdded {
            symbol: symbol_hunter,
            type: string::utf8(b"hunter"),
        });
    }

    public entry fun add_stone_data(minter_data: &mut MinterData, symbol_stone: String, name: String, image_url: String, type: String, rarity: String, ctx: &mut TxContext) {
        assert!(is_admin(minter_data.owner, ctx),ENotAdmin);
        vec_map::insert(&mut minter_data.stone_datas, symbol_stone, StoneData {
            name,
            image_url,
            type,
            rarity, 
            next_token_id: 1
        });
        event::emit(DataAdded {
            symbol: symbol_stone,
            type: string::utf8(b"stone"),
        });
    }

    public entry fun add_sword_data(minter_data: &mut MinterData, symbol_sword: String, name: String, image_url: String, type: String, rarity: String, strength: u64, intrinsic_attribute: String,ctx: &mut TxContext) {
        assert!(is_admin(minter_data.owner, ctx), ENotAdmin);
        vec_map::insert(&mut minter_data.sword_datas, symbol_sword, SwordData {
            name,
            image_url,
            type,
            rarity,
            strength,
            intrinsic_attribute,
            next_token_id: 1,
        });
        event::emit(DataAdded {
            symbol: symbol_sword,
            type: string::utf8(b"sword"),
        });
    }

    public entry fun add_item_data(minter_data: &mut MinterData, symbol_item: String, name: String, image_url: String, type: String, rarity: String, intrinsic_attribute: String, ctx: &mut TxContext) {
        assert!(is_admin(minter_data.owner, ctx), ENotAdmin);
        vec_map::insert(&mut minter_data.item_datas, symbol_item, ItemData {
            name,
            image_url,
            type,
            rarity,
            intrinsic_attribute,
            next_token_id: 1
        });
        event::emit(DataAdded {
            symbol: symbol_item,
            type: string::utf8(b"item"),
        });
    }
 
    //------------------INTERNAL FUNCTIONS---------------------//

    fun num_str(num: u64): String {
        let v1 = vector::empty();
        while (num/10 > 0){
            let rem = num%10;
            vector::push_back(&mut v1, (rem+48 as u8));
            num = num/10;
        };
        vector::push_back(&mut v1, (num+48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }

    fun get_token_name(token_id: u64, name: String): String {
        let token_name = name;
        string::append(&mut token_name,string::utf8(b" #"));
        string::append(&mut token_name,num_str(token_id));
        token_name
    }

    fun is_admin(owner: address,ctx: &mut TxContext): bool {
        (tx_context::sender(ctx) == @admin || tx_context::sender(ctx) == owner)
    }
    
}

