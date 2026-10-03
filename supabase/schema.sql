-- ==============================================================================
-- SaveBite Supabase Database Schema & Storage Configuration (V1.0)
-- ==============================================================================
-- Run this complete script in your Supabase Dashboard:
-- SQL Editor -> New Query -> Paste & Click "Run"
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABLES
-- ==============================================================================

-- 2.1 PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'restaurant', 'admin')),
    avatar_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    disabled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2.2 RESTAURANTS TABLE
CREATE TABLE IF NOT EXISTS public.restaurants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    phone TEXT,
    address TEXT NOT NULL,
    division TEXT NOT NULL DEFAULT 'Dhaka',
    area TEXT NOT NULL,
    cuisine_type TEXT,
    image_url TEXT,
    opening_time TEXT DEFAULT '11:00 AM',
    closing_time TEXT DEFAULT '11:00 PM',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'suspended')),
    approved_at TIMESTAMP WITH TIME ZONE,
    suspended_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_restaurant_owner UNIQUE (owner_id)
);

-- 2.3 OFFERS TABLE
CREATE TABLE IF NOT EXISTS public.offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    restaurant_name TEXT,
    restaurant_address TEXT,
    division TEXT NOT NULL DEFAULT 'Dhaka',
    area TEXT,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    category TEXT NOT NULL CHECK (category IN ('Rice', 'Burger', 'Pizza', 'Chicken', 'Bakery', 'Healthy', 'Drinks', 'Snacks', 'Dessert', 'Fast Food', 'Other')),
    original_price NUMERIC NOT NULL CHECK (original_price > 0),
    discounted_price NUMERIC NOT NULL CHECK (discounted_price > 0 AND discounted_price <= original_price),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    available_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    available_until TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    admin_blocked BOOLEAN NOT NULL DEFAULT FALSE,
    blocked_at TIMESTAMP WITH TIME ZONE,
    blocked_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2.4 PROMO BANNERS TABLE (Optional Supporting Table for Dynamic Admin Hero Banners)
CREATE TABLE IF NOT EXISTS public.promo_banners (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    tag TEXT NOT NULL,
    image_url TEXT NOT NULL,
    target_route TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 3. INDEXES FOR HIGH-PERFORMANCE SEARCH & FILTERING (Section 60)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);

CREATE INDEX IF NOT EXISTS idx_restaurants_owner ON public.restaurants(owner_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_status ON public.restaurants(status);
CREATE INDEX IF NOT EXISTS idx_restaurants_area ON public.restaurants(division, area);

CREATE INDEX IF NOT EXISTS idx_offers_restaurant ON public.offers(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_offers_category ON public.offers(category);
CREATE INDEX IF NOT EXISTS idx_offers_is_active ON public.offers(is_active);
CREATE INDEX IF NOT EXISTS idx_offers_available_until ON public.offers(available_until);
CREATE INDEX IF NOT EXISTS idx_offers_feed ON public.offers(is_active, admin_blocked, available_until);

-- ==============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES (Sections 47, 48, 49)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_banners ENABLE ROW LEVEL SECURITY;

-- 4.1 PROFILES POLICIES
-- Anyone authenticated or anon can read active profiles (needed to see restaurant owners/avatars)
DROP POLICY IF EXISTS "Public profiles read" ON public.profiles;
CREATE POLICY "Public profiles read" ON public.profiles
    FOR SELECT USING (true);

-- Users can insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- 4.2 RESTAURANTS POLICIES
-- Anyone can view approved restaurants
DROP POLICY IF EXISTS "Anyone can view approved restaurants" ON public.restaurants;
CREATE POLICY "Anyone can view approved restaurants" ON public.restaurants
    FOR SELECT USING (status = 'approved' OR auth.uid() = owner_id);

-- Restaurant owners can create their restaurant profile
DROP POLICY IF EXISTS "Owners can insert restaurant" ON public.restaurants;
CREATE POLICY "Owners can insert restaurant" ON public.restaurants
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Restaurant owners can update their own restaurant
DROP POLICY IF EXISTS "Owners can update own restaurant" ON public.restaurants;
CREATE POLICY "Owners can update own restaurant" ON public.restaurants
    FOR UPDATE USING (auth.uid() = owner_id);

-- 4.3 OFFERS POLICIES
-- Anyone can view active, non-blocked, unexpired offers from approved restaurants
DROP POLICY IF EXISTS "Public can view valid offers" ON public.offers;
CREATE POLICY "Public can view valid offers" ON public.offers
    FOR SELECT USING (
        (is_active = TRUE AND admin_blocked = FALSE AND available_until > now())
        OR EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = offers.restaurant_id AND r.owner_id = auth.uid()
        )
    );

-- Restaurant owners can insert offers for their restaurant
DROP POLICY IF EXISTS "Owners can insert offers" ON public.offers;
CREATE POLICY "Owners can insert offers" ON public.offers
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = offers.restaurant_id AND r.owner_id = auth.uid()
        )
    );

-- Restaurant owners can update their own offers
DROP POLICY IF EXISTS "Owners can update own offers" ON public.offers;
CREATE POLICY "Owners can update own offers" ON public.offers
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = offers.restaurant_id AND r.owner_id = auth.uid()
        )
    );

-- Restaurant owners can delete their own offers
DROP POLICY IF EXISTS "Owners can delete own offers" ON public.offers;
CREATE POLICY "Owners can delete own offers" ON public.offers
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = offers.restaurant_id AND r.owner_id = auth.uid()
        )
    );

-- 4.4 PROMO BANNERS POLICIES
-- Anyone can read promo banners
DROP POLICY IF EXISTS "Anyone can view promo banners" ON public.promo_banners;
CREATE POLICY "Anyone can view promo banners" ON public.promo_banners
    FOR SELECT USING (true);

-- ==============================================================================
-- 5. AUTOMATIC USER PROFILE TRIGGER (On Supabase Auth Sign Up)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, phone)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        COALESCE(new.raw_user_meta_data->>'role', 'customer'),
        new.raw_user_meta_data->>'phone'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger execution
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 6. STORAGE BUCKETS (Section 51)
-- ==============================================================================
-- Creates 'avatars', 'restaurant-images', 'offer-images', 'promo-banners'
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('avatars', 'avatars', true),
    ('restaurant-images', 'restaurant-images', true),
    ('offer-images', 'offer-images', true),
    ('promo-banners', 'promo-banners', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ==============================================================================
-- 7. STORAGE POLICIES
-- ==============================================================================
-- 7.1 Public Read for all buckets
DROP POLICY IF EXISTS "Public Access Avatars" ON storage.objects;
CREATE POLICY "Public Access Avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Public Access Restaurant Images" ON storage.objects;
CREATE POLICY "Public Access Restaurant Images" ON storage.objects
    FOR SELECT USING (bucket_id = 'restaurant-images');

DROP POLICY IF EXISTS "Public Access Offer Images" ON storage.objects;
CREATE POLICY "Public Access Offer Images" ON storage.objects
    FOR SELECT USING (bucket_id = 'offer-images');

DROP POLICY IF EXISTS "Public Access Promo Banners" ON storage.objects;
CREATE POLICY "Public Access Promo Banners" ON storage.objects
    FOR SELECT USING (bucket_id = 'promo-banners');

-- 7.2 Authenticated User Uploads
DROP POLICY IF EXISTS "Auth Users Upload Avatars" ON storage.objects;
CREATE POLICY "Auth Users Upload Avatars" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars' AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Auth Users Upload Restaurant Images" ON storage.objects;
CREATE POLICY "Auth Users Upload Restaurant Images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'restaurant-images' AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Auth Users Upload Offer Images" ON storage.objects;
CREATE POLICY "Auth Users Upload Offer Images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'offer-images' AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Auth Users Upload Promo Banners" ON storage.objects;
CREATE POLICY "Auth Users Upload Promo Banners" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'promo-banners' AND auth.role() = 'authenticated'
    );

-- ==============================================================================
-- 8. DEFAULT SEED PROMO BANNERS
-- ==============================================================================
INSERT INTO public.promo_banners (id, title, subtitle, tag, image_url, target_route, display_order)
VALUES 
    (
        'banner_1',
        'Save Food, Save Wallet',
        'Hot surplus meals at 50% to 70% discount from top kitchens',
        'HOT DEALS',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600',
        '/customer/hot-deals',
        1
    ),
    (
        'banner_2',
        'Authentic Biryani Surplus',
        'Fragrant kacchi and tehari ready for grab before closing time',
        'BEST SELLER',
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',
        '/customer/search',
        2
    ),
    (
        'banner_3',
        'Evening Bakery Clearance',
        'Fresh artisanal croissants, breads and desserts at half price',
        'LIMITED TIME',
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600',
        '/customer/search',
        3
    )
ON CONFLICT (id) DO NOTHING;
