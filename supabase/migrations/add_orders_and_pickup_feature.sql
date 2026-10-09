-- ==============================================================================
-- MIGRATION: Food Ordering, Payment, Self-Pickup & Stock Decrement
-- ==============================================================================

-- 1. Ensure columns exist on orders table for customer & restaurant details
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_email TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_name TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_address TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS unit_price NUMERIC DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_savings NUMERIC DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS pickup_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS transaction_id TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS email_sent_customer BOOLEAN DEFAULT TRUE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS email_sent_restaurant BOOLEAN DEFAULT TRUE;

-- 2. Relax payment_method check constraint to support modern gateway options
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_payment_method_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_payment_method_check 
    CHECK (payment_method IN ('cash_on_pickup', 'bKash', 'Nagad', 'Rocket', 'card', 'wallet'));

-- 3. Trigger Function: Automatically decrease food offer quantity when order is placed
CREATE OR REPLACE FUNCTION public.decrease_offer_quantity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.offer_id IS NOT NULL THEN
        UPDATE public.offers
        SET quantity = GREATEST(0, quantity - NEW.quantity),
            is_active = CASE 
                WHEN (quantity - NEW.quantity) <= 0 THEN FALSE 
                ELSE is_active 
            END,
            updated_at = timezone('utc'::text, now())
        WHERE id = NEW.offer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Attach trigger to orders table
DROP TRIGGER IF EXISTS trg_decrease_offer_quantity ON public.orders;
CREATE TRIGGER trg_decrease_offer_quantity
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.decrease_offer_quantity();

-- 5. Additional Indexing for rapid queries
CREATE INDEX IF NOT EXISTS idx_orders_pickup_time ON public.orders(pickup_time);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON public.orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);

-- 6. Ensure RLS policies are permissive for authenticated customers & restaurants
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (
        auth.uid() = customer_id
        OR EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = orders.restaurant_id AND r.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Customers can create orders" ON public.orders;
CREATE POLICY "Customers can create orders" ON public.orders
    FOR INSERT WITH CHECK (
        auth.uid() = customer_id
        OR auth.uid() IS NOT NULL
    );

DROP POLICY IF EXISTS "Restaurant owners or customer can update order" ON public.orders;
CREATE POLICY "Restaurant owners or customer can update order" ON public.orders
    FOR UPDATE USING (
        auth.uid() = customer_id
        OR EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = orders.restaurant_id AND r.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );
