module CarbonCreditRegistr::CarbonCreditRegistry {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    struct CarbonCredit has store, key {
        total_credits: u64,      
        verified_credits: u64,   
        price_per_credit: u64,   
    }

    const E_INSUFFICIENT_CREDITS: u64 = 1;
    const E_INSUFFICIENT_FUNDS: u64 = 2;
    const E_INVALID_AMOUNT: u64 = 3;
    public fun register_carbon_credits(
        owner: &signer, 
        verified_credits: u64, 
        price_per_credit: u64
    ) {
        let carbon_credit = CarbonCredit {
            total_credits: verified_credits,
            verified_credits,
            price_per_credit,
        };
        move_to(owner, carbon_credit);
    }

    public fun purchase_carbon_credits(
        buyer: &signer, 
        seller_address: address, 
        credits_amount: u64
    ) acquires CarbonCredit {
        let seller_credits = borrow_global_mut<CarbonCredit>(seller_address);
        
        assert!(seller_credits.verified_credits >= credits_amount, E_INSUFFICIENT_CREDITS);
        
  
        let total_cost = credits_amount * seller_credits.price_per_credit;
        
   
        let payment = coin::withdraw<AptosCoin>(buyer, total_cost);
        coin::deposit<AptosCoin>(seller_address, payment);
        
     
        seller_credits.verified_credits = seller_credits.verified_credits - credits_amount;
        
        if (!exists<CarbonCredit>(signer::address_of(buyer))) {
            let buyer_credits = CarbonCredit {
                total_credits: credits_amount,
                verified_credits: 0, // Purchased credits are not for resale initially
                price_per_credit: 0,
            };
            move_to(buyer, buyer_credits);
        } else {
            let buyer_credits = borrow_global_mut<CarbonCredit>(signer::address_of(buyer));
            buyer_credits.total_credits = buyer_credits.total_credits + credits_amount;
        };
    }
}
