module spacehunter::hunter {
    friend spacehunter::mint;
    friend spacehunter::farming;
    friend spacehunter::crafting;
    use sui::url::{Self,Url};
    use std::string;
    use sui::event;
    use sui::object::{Self,ID,UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::package;
    use sui::display;
    use std::string::{String};

    const EXP_PER_LEVEL : u64 = 1000;
    const HP_PER_POINT : u64 = 10;
    const SPEED_PER_POINT : u64 = 1;
    const ATTACK_PER_POINT : u64 = 1;
    const DEFEND_PER_POINT: u64 = 1;
    

    struct Hunter has key, store { 
        id: UID,
        name: String,
        symbol: String,
        image_url: Url,
        level: u64,
        exp: u64,
        hp: u64,
        speed: u64,
        attack: u64,
        defend : u64,
        point: u64,
    }

    struct MintHunterEvent has copy, drop {
        id : ID,
        owner_addr: address,
        name_hunter: String
    }

    struct HUNTER has drop {}

    fun init(otw: HUNTER,ctx: &mut TxContext) {
         let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"project_url"),
        ];

        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"{image_url}"),
            string::utf8(b"NFTs in SpaceHunter introduce a new level of interactivity among players, enabling them to own rare and collectible items within the game. This also opens opportunities for players to create a virtual economy within the game, creating their own unique gaming experience. With NFTs, SpaceHunter takes gaming to the next level of engagement, creativity and ownership"),
            string::utf8(b"https://spacehunter.io/"),
        ];
        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<Hunter>(
            &publisher, keys, values, ctx
        );
        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }
    

    public(friend) entry fun mint(name: String, hp: u64, speed: u64, attack: u64, defend: u64, symbol: String, image_url: String, ctx: &mut TxContext) {    
        let nft = Hunter {
            id: object::new(ctx),
            name,
            symbol,
            image_url: url::new_unsafe(string::to_ascii(image_url)),
            level: 1,
            exp: 0,
            hp,
            speed,
            attack,
            defend, 
            point: 0,
        };
        let event = MintHunterEvent {
            id: object::uid_to_inner(&nft.id),
            owner_addr: tx_context::sender(ctx),
            name_hunter : name
        };
        event::emit(event);
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    public(friend) entry fun upgrade_level(hunter:&mut Hunter, exp: u64) {
        hunter.exp = hunter.exp + exp;
        let new_level = hunter.exp / EXP_PER_LEVEL;
        hunter.point = hunter.point + (new_level - hunter.level);
    }

    public entry fun upgrade_hp(hunter: &mut Hunter, amount_point: u64) {
        hunter.point = hunter.point - amount_point;
        hunter.hp = amount_point * HP_PER_POINT;
    }

    public entry fun upgrade_speed(hunter: &mut Hunter, amount_point: u64) {
        hunter.point = hunter.point - amount_point;
        hunter.speed = amount_point * SPEED_PER_POINT;
        
    }

    public entry fun upgrade_attack(hunter: &mut Hunter, amount_point: u64) {
        hunter.point = hunter.point - amount_point;
        hunter.attack = amount_point * ATTACK_PER_POINT;        
    }

    public entry fun upgrade_defend(hunter: &mut Hunter, amount_point: u64) {
        hunter.point = hunter.point - amount_point;
        hunter.defend = amount_point * DEFEND_PER_POINT;
    }

    public(friend) fun get_mut_id(hunter:&mut Hunter): &mut UID {
        &mut hunter.id
    }

    public entry fun burn(hunter: Hunter, _: &mut TxContext) {
        let Hunter { id,
            name: _,
            symbol: _,
            image_url: _,
            level: _,
            exp: _ ,
            hp: _,
            speed: _,
            attack: _,
            defend: _,
            point: _}
            = hunter;
        object::delete(id)
    }
}


