-- ==============================================================================
-- SaveBite: Customer Reviews, Ratings & Verified Review Badges Migration
-- ==============================================================================

-- 1. Create reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    customer_name TEXT NOT NULL,
    customer_avatar_url TEXT,
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    restaurant_name TEXT NOT NULL,
    offer_id UUID REFERENCES public.offers(id) ON DELETE SET NULL,
    offer_title TEXT,
    rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    comment TEXT NOT NULL,
    image_url TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_order_review UNIQUE (order_id)
);

-- 2. Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_reviews_restaurant_id ON public.reviews (restaurant_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON public.reviews (customer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_offer_id ON public.reviews (offer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.reviews (created_at DESC);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Anyone can view reviews
CREATE POLICY "Public reviews are viewable by everyone" 
ON public.reviews FOR SELECT 
USING (true);

-- Customers can insert their own verified review for their completed orders
CREATE POLICY "Customers can create a review for their own order" 
ON public.reviews FOR INSERT 
WITH CHECK (auth.uid() = customer_id);

-- Customers can update their own reviews
CREATE POLICY "Customers can update their own review" 
ON public.reviews FOR UPDATE 
USING (auth.uid() = customer_id);

-- Admins can delete or moderate reviews
CREATE POLICY "Admins can delete inappropriate reviews" 
ON public.reviews FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
);
