module CarbonCreditRegistr::CarbonCreditRegistry {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing a carbon credit certificate
    struct CarbonCredit has store, key {
        total_credits: u64,      // Total carbon credits owned
        verified_credits: u64,   // Verified carbon credits available for trading
        price_per_credit: u64,   // Price per carbon credit in APT tokens
    }

    /// Error codes
    const E_INSUFFICIENT_CREDITS: u64 = 1;
    const E_INSUFFICIENT_FUNDS: u64 = 2;
    const E_INVALID_AMOUNT: u64 = 3;

    /// Function to register a new carbon credit holder with initial verified credits
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

    /// Function to purchase carbon credits from a registered holder
    public fun purchase_carbon_credits(
        buyer: &signer, 
        seller_address: address, 
        credits_amount: u64
    ) acquires CarbonCredit {
        let seller_credits = borrow_global_mut<CarbonCredit>(seller_address);
        
        // Check if seller has enough verified credits
        assert!(seller_credits.verified_credits >= credits_amount, E_INSUFFICIENT_CREDITS);
        
        // Calculate total cost
        let total_cost = credits_amount * seller_credits.price_per_credit;
        
        // Transfer payment from buyer to seller
        let payment = coin::withdraw<AptosCoin>(buyer, total_cost);
        coin::deposit<AptosCoin>(seller_address, payment);
        
        // Update seller's credits
        seller_credits.verified_credits = seller_credits.verified_credits - credits_amount;
        
        // Create or update buyer's carbon credits
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