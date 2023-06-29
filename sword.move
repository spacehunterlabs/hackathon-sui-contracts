module spacehunter::sword {
    friend spacehunter::mint;
    use sui::url::{Self,Url};
    use std::string;
    use sui::event;
    use sui::object::{Self,ID,UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::package;
    use sui::display;
    use std::string::{String};

    struct Sword has key, store { 
        id: UID,
        name: String,
        symbol: String,
        image_url: Url,
        level: u64,
        damage: u64,
        intrinsic_attribute: String,
    }

    struct MintSwordEvent has copy, drop {
        id : ID,
        owner_addr: address,
        name_Sword: String
    }

    struct SWORD has drop {}

    fun init(otw: SWORD,ctx: &mut TxContext) {
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
        let display = display::new_with_fields<Sword>(
            &publisher, keys, values, ctx
        );
        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    public(friend) entry fun mint(name: String, symbol: String, image_url: String, damage: u64, intrinsic_attribute: String,  ctx: &mut TxContext) {    
        let nft = Sword {
            id: object::new(ctx),
            name,
            symbol,
            image_url: url::new_unsafe(string::to_ascii(image_url)),
            level: 1,
            damage,
            intrinsic_attribute,
        };
        let event = MintSwordEvent {
            id: object::uid_to_inner(&nft.id),
            owner_addr: tx_context::sender(ctx),
            name_Sword : name
        };
        event::emit(event);
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    public(friend) entry fun upgrade(sword:&mut Sword, level: u64, damage: u64) {
        sword.level = level;
        sword.damage = damage;
    }

    public entry fun burn(sword: Sword, _: &mut TxContext) {
        let Sword { id,
            name: _,
            symbol: _,
            image_url: _,
            level: _,
            damage: _,
            intrinsic_attribute: _, }
            = sword;
        object::delete(id)
    }
}


