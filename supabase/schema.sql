-- ==============================================================================
-- SaveBite Supabase Database Schema & Storage Configuration (V2.5 - Comprehensive)
-- ==============================================================================
-- Run this complete script in your Supabase Dashboard:
-- SQL Editor -> New Query -> Paste & Click "Run"
--
-- This script is completely IDEMPOTENT: it safely creates missing tables,
-- adds all required columns, configures storage buckets, sets up Row Level
-- Security (RLS) policies, and creates performance indexes.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. CORE & PROFILE TABLES
-- ==============================================================================

-- 2.1 PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    first_name TEXT,
    last_name TEXT,
    gender TEXT,
    address TEXT,
    city TEXT,
    date_of_birth TEXT,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'restaurant', 'admin', 'head_admin', 'moderator')),
    avatar_url TEXT,
    reward_points INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    disabled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure newly added columns exist if table was already created
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS date_of_birth TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS reward_points INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS disabled_at TIMESTAMP WITH TIME ZONE;

-- Update role constraint to support multi-tier administration (head_admin, admin, moderator)
DO $$
BEGIN
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
    ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check 
        CHECK (role IN ('customer', 'restaurant', 'admin', 'head_admin', 'moderator'));
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

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
    rejection_reason TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    suspended_at TIMESTAMP WITH TIME ZONE,
    -- Growth, Promotion & Verification Fields
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    subscription_plan TEXT,
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    boost_credits INTEGER NOT NULL DEFAULT 0,
    banner_credits INTEGER NOT NULL DEFAULT 0,
    has_active_banner BOOLEAN NOT NULL DEFAULT FALSE,
    active_banner_id TEXT,
    trade_license TEXT,
    nid TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_restaurant_owner UNIQUE (owner_id)
);

-- Ensure newly added columns exist if table was already created
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS is_premium BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS subscription_plan TEXT;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS boost_credits INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS banner_credits INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS has_active_banner BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS active_banner_id TEXT;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS trade_license TEXT;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS nid TEXT;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE;

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
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    available_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    available_until TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    admin_blocked BOOLEAN NOT NULL DEFAULT FALSE,
    blocked_at TIMESTAMP WITH TIME ZONE,
    blocked_reason TEXT,
    -- Promotional boost & status fields
    is_boosted BOOLEAN NOT NULL DEFAULT FALSE,
    boosted_until TIMESTAMP WITH TIME ZONE,
    is_done BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure newly added columns & relaxed constraints exist if table was already created
ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS is_boosted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS boosted_until TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS is_done BOOLEAN NOT NULL DEFAULT FALSE;
DO $$
BEGIN
    ALTER TABLE public.offers DROP CONSTRAINT IF EXISTS offers_quantity_check;
    ALTER TABLE public.offers ADD CONSTRAINT offers_quantity_check CHECK (quantity >= 0);
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- 2.4 PROMO BANNERS TABLE (Dynamic Admin & Restaurant Hero Banners)
CREATE TABLE IF NOT EXISTS public.promo_banners (
    id TEXT PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    tag TEXT NOT NULL,
    image_url TEXT NOT NULL,
    target_route TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected', 'ended', 'expired')),
    rejection_reason TEXT,
    starts_at TIMESTAMP WITH TIME ZONE,
    ends_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES public.profiles(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.promo_banners ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE;
ALTER TABLE public.promo_banners ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'approved';
ALTER TABLE public.promo_banners ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.promo_banners ADD COLUMN IF NOT EXISTS starts_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.promo_banners ADD COLUMN IF NOT EXISTS ends_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.promo_banners ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.promo_banners ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;

-- ==============================================================================
-- 3. ORDERS & COMMERCE TABLES
-- ==============================================================================

-- 3.1 ORDERS TABLE (Food Rescue Orders & Takeaway Pickups)
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT NOT NULL UNIQUE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    offer_id UUID REFERENCES public.offers(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    image_url TEXT,
    category TEXT,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    original_price NUMERIC CHECK (original_price >= 0),
    total_price NUMERIC NOT NULL CHECK (total_price >= 0),
    unit_price NUMERIC DEFAULT 0,
    total_savings NUMERIC DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'ready_for_pickup', 'completed', 'cancelled')),
    pickup_code TEXT NOT NULL,
    pickup_time TEXT,
    pickup_window_start TIMESTAMP WITH TIME ZONE,
    pickup_window_end TIMESTAMP WITH TIME ZONE,
    payment_method TEXT NOT NULL DEFAULT 'cash_on_pickup' CHECK (payment_method IN ('cash_on_pickup', 'bKash', 'Nagad', 'card', 'wallet')),
    payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    transaction_id TEXT,
    notes TEXT,
    customer_name TEXT,
    customer_phone TEXT,
    customer_email TEXT,
    restaurant_name TEXT,
    restaurant_address TEXT,
    restaurant_phone TEXT,
    restaurant_email TEXT,
    promo_code TEXT,
    discount_amount NUMERIC DEFAULT 0,
    restaurant_earnings NUMERIC DEFAULT 0,
    platform_subsidy NUMERIC DEFAULT 0,
    email_sent_customer BOOLEAN DEFAULT TRUE,
    email_sent_restaurant BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_email TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_name TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_address TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_phone TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_email TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS unit_price NUMERIC DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_savings NUMERIC DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS transaction_id TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS email_sent_customer BOOLEAN DEFAULT TRUE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS email_sent_restaurant BOOLEAN DEFAULT TRUE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promo_code TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS discount_amount NUMERIC DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_earnings NUMERIC DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS platform_subsidy NUMERIC DEFAULT 0;

-- Convert pickup_time to TEXT safely if it was originally created as TIMESTAMP
DO $$
BEGIN
    ALTER TABLE public.orders ALTER COLUMN pickup_time TYPE TEXT USING pickup_time::TEXT;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- Function to automatically decrease offer quantity when an order is placed
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
            is_done = CASE
                WHEN (quantity - NEW.quantity) <= 0 THEN TRUE
                ELSE is_done
            END,
            updated_at = timezone('utc'::text, now())
        WHERE id = NEW.offer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_decrease_offer_quantity ON public.orders;
CREATE TRIGGER trg_decrease_offer_quantity
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.decrease_offer_quantity();

-- 3.2 CUSTOMER ADDRESSES TABLE (Saved Delivery / Pickup Locations)
CREATE TABLE IF NOT EXISTS public.customer_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    label TEXT NOT NULL DEFAULT 'Home',
    address_line TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'Dhaka',
    area TEXT NOT NULL,
    division TEXT NOT NULL DEFAULT 'Dhaka',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3.3 FAVORITES TABLE (Saved Favourite Restaurants)
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_restaurant_favorite UNIQUE (user_id, restaurant_id)
);

-- 3.4 VOUCHERS TABLE (Platform Promo Codes & Coupons)
-- Business Rule: Setup exclusively by Admins. Discount 100% absorbed by platform authority.
CREATE TABLE IF NOT EXISTS public.vouchers (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    discount_type TEXT NOT NULL DEFAULT 'flat' CHECK (discount_type IN ('flat', 'percentage', 'free_delivery')),
    discount_value NUMERIC NOT NULL CHECK (discount_value > 0),
    min_order_amount NUMERIC NOT NULL DEFAULT 0 CHECK (min_order_amount >= 0),
    max_discount NUMERIC,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_super_saver_exclusive BOOLEAN NOT NULL DEFAULT FALSE,
    is_platform_sponsored BOOLEAN NOT NULL DEFAULT TRUE,
    used_count INTEGER NOT NULL DEFAULT 0,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (timezone('utc'::text, now()) + interval '365 days'),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure vouchers supports string IDs & newly added promo code columns
DO $$
BEGIN
    ALTER TABLE public.vouchers ALTER COLUMN id TYPE TEXT USING id::TEXT;
    ALTER TABLE public.vouchers ALTER COLUMN id SET DEFAULT gen_random_uuid()::TEXT;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS is_platform_sponsored BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS used_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.vouchers ADD COLUMN IF NOT EXISTS max_discount NUMERIC;

-- 3.5 USER VOUCHERS TABLE (User Claims / Redemptions)
CREATE TABLE IF NOT EXISTS public.user_vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    voucher_id TEXT NOT NULL REFERENCES public.vouchers(id) ON DELETE CASCADE,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_voucher UNIQUE (user_id, voucher_id)
);

DO $$
BEGIN
    ALTER TABLE public.user_vouchers ALTER COLUMN voucher_id TYPE TEXT USING voucher_id::TEXT;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- 3.6 RESTAURANT VERIFICATION REQUESTS TABLE (Protected Trade License & NID Approvals)
CREATE TABLE IF NOT EXISTS public.restaurant_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    trade_license_number TEXT,
    trade_license_document_url TEXT,
    nid_number TEXT,
    nid_document_url TEXT,
    requested_name TEXT,
    requested_phone TEXT,
    requested_address TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    reviewed_by UUID REFERENCES public.profiles(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3.7 AD PACKAGES & PROMOTION PURCHASES TABLE (24h Banner, 24h Boost, Subscriptions)
CREATE TABLE IF NOT EXISTS public.ad_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    package_type TEXT NOT NULL CHECK (package_type IN ('banner_24h', 'boost_24h', 'gold_subscription', 'custom_package')),
    price_bdt NUMERIC NOT NULL CHECK (price_bdt >= 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'expired', 'cancelled')),
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    banner_id TEXT,
    offer_id UUID REFERENCES public.offers(id) ON DELETE SET NULL,
    payment_method TEXT DEFAULT 'bKash',
    payment_status TEXT DEFAULT 'paid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3.8 REVIEWS & RATINGS TABLE
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    restaurant_name TEXT,
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    customer_name TEXT,
    customer_avatar_url TEXT,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    offer_id UUID REFERENCES public.offers(id) ON DELETE SET NULL,
    offer_title TEXT,
    rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    comment TEXT,
    image_url TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure all review model columns exist and user_id is nullable
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS restaurant_name TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS customer_avatar_url TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS offer_id UUID REFERENCES public.offers(id) ON DELETE SET NULL;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS offer_title TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.reviews ALTER COLUMN user_id DROP NOT NULL;

-- Trigger to keep user_id and customer_id synchronized
CREATE OR REPLACE FUNCTION public.handle_review_customer_sync()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.customer_id IS NULL AND NEW.user_id IS NOT NULL THEN
        NEW.customer_id = NEW.user_id;
    END IF;
    IF NEW.user_id IS NULL AND NEW.customer_id IS NOT NULL THEN
        NEW.user_id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_review_customer_user_id ON public.reviews;
CREATE TRIGGER trg_sync_review_customer_user_id
    BEFORE INSERT OR UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_review_customer_sync();

-- 3.9 IN-APP NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general' CHECK (type IN ('offer', 'order', 'promo', 'account', 'system', 'general')),
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Drop strict FK constraint on user_id so it can target either a customer profile or restaurant
DO $$
BEGIN
    ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
    ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- 3.10 GROUP ORDERS TABLE (Social Surplus Food Rescue with Friends)
CREATE TABLE IF NOT EXISTS public.group_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    group_code TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'locked', 'ordered', 'cancelled')),
    target_discount_threshold NUMERIC DEFAULT 1000,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 4. PERFORMANCE & SEARCH INDEXES
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);

CREATE INDEX IF NOT EXISTS idx_restaurants_owner ON public.restaurants(owner_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_status ON public.restaurants(status);
CREATE INDEX IF NOT EXISTS idx_restaurants_area ON public.restaurants(division, area);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_verified ON public.restaurants(is_verified);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_premium ON public.restaurants(is_premium);

CREATE INDEX IF NOT EXISTS idx_offers_restaurant ON public.offers(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_offers_category ON public.offers(category);
CREATE INDEX IF NOT EXISTS idx_offers_is_active ON public.offers(is_active);
CREATE INDEX IF NOT EXISTS idx_offers_available_until ON public.offers(available_until);
CREATE INDEX IF NOT EXISTS idx_offers_feed ON public.offers(is_active, admin_blocked, available_until);
CREATE INDEX IF NOT EXISTS idx_offers_is_boosted ON public.offers(is_boosted);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant ON public.orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON public.orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_customer_addresses_user ON public.customer_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_restaurant ON public.favorites(restaurant_id);

CREATE INDEX IF NOT EXISTS idx_vouchers_code ON public.vouchers(code);
CREATE INDEX IF NOT EXISTS idx_vouchers_active ON public.vouchers(is_active, valid_until);
CREATE INDEX IF NOT EXISTS idx_user_vouchers_user ON public.user_vouchers(user_id);

CREATE INDEX IF NOT EXISTS idx_verifications_status ON public.restaurant_verifications(status);
CREATE INDEX IF NOT EXISTS idx_ad_packages_restaurant ON public.ad_packages(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_reviews_restaurant ON public.reviews(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer ON public.reviews(customer_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_group_orders_code ON public.group_orders(group_code);

-- ==============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurant_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_orders ENABLE ROW LEVEL SECURITY;

-- 5.1 PROFILES POLICIES
DROP POLICY IF EXISTS "Public profiles read" ON public.profiles;
CREATE POLICY "Public profiles read" ON public.profiles
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (
        auth.uid() = id
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

-- 5.2 RESTAURANTS POLICIES
DROP POLICY IF EXISTS "Anyone can view approved restaurants" ON public.restaurants;
CREATE POLICY "Anyone can view approved restaurants" ON public.restaurants
    FOR SELECT USING (
        status = 'approved' 
        OR auth.uid() = owner_id
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin', 'moderator')
        )
    );

DROP POLICY IF EXISTS "Owners can insert restaurant" ON public.restaurants;
CREATE POLICY "Owners can insert restaurant" ON public.restaurants
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Owners can update own restaurant" ON public.restaurants;
CREATE POLICY "Owners can update own restaurant" ON public.restaurants
    FOR UPDATE USING (
        auth.uid() = owner_id
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin', 'moderator')
        )
    );

-- 5.3 OFFERS POLICIES
DROP POLICY IF EXISTS "Public can view valid offers" ON public.offers;
CREATE POLICY "Public can view valid offers" ON public.offers
    FOR SELECT USING (
        (is_active = TRUE AND admin_blocked = FALSE AND available_until > now())
        OR EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = offers.restaurant_id AND r.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin', 'moderator')
        )
    );

DROP POLICY IF EXISTS "Owners can insert offers" ON public.offers;
CREATE POLICY "Owners can insert offers" ON public.offers
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = offers.restaurant_id AND r.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

DROP POLICY IF EXISTS "Owners can update own offers" ON public.offers;
CREATE POLICY "Owners can update own offers" ON public.offers
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = offers.restaurant_id AND r.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

DROP POLICY IF EXISTS "Owners can delete own offers" ON public.offers;
CREATE POLICY "Owners can delete own offers" ON public.offers
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = offers.restaurant_id AND r.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

-- 5.4 PROMO BANNERS POLICIES
DROP POLICY IF EXISTS "Anyone can view promo banners" ON public.promo_banners;
CREATE POLICY "Anyone can view promo banners" ON public.promo_banners
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage promo banners" ON public.promo_banners;
CREATE POLICY "Admins can manage promo banners" ON public.promo_banners
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

-- 5.5 ORDERS POLICIES
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
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin', 'moderator')
        )
    );

DROP POLICY IF EXISTS "Customers can create orders" ON public.orders;
CREATE POLICY "Customers can create orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = customer_id);

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
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

-- 5.6 CUSTOMER ADDRESSES POLICIES
DROP POLICY IF EXISTS "Users manage own addresses" ON public.customer_addresses;
CREATE POLICY "Users manage own addresses" ON public.customer_addresses
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5.7 FAVORITES POLICIES
DROP POLICY IF EXISTS "Users manage own favorites" ON public.favorites;
CREATE POLICY "Users manage own favorites" ON public.favorites
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5.8 VOUCHERS POLICIES
DROP POLICY IF EXISTS "Anyone can view active vouchers" ON public.vouchers;
CREATE POLICY "Anyone can view active vouchers" ON public.vouchers
    FOR SELECT USING (
        (is_active = TRUE AND (valid_until IS NULL OR valid_until > now()))
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

DROP POLICY IF EXISTS "Admins can manage vouchers" ON public.vouchers;
CREATE POLICY "Admins can manage vouchers" ON public.vouchers
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

DROP POLICY IF EXISTS "Users manage own claimed vouchers" ON public.user_vouchers;
CREATE POLICY "Users manage own claimed vouchers" ON public.user_vouchers
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5.9 RESTAURANT VERIFICATION REQUESTS POLICIES
DROP POLICY IF EXISTS "Owners can view own verification requests" ON public.restaurant_verifications;
CREATE POLICY "Owners can view own verification requests" ON public.restaurant_verifications
    FOR SELECT USING (
        auth.uid() = owner_id
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin', 'moderator')
        )
    );

DROP POLICY IF EXISTS "Owners can insert verification request" ON public.restaurant_verifications;
CREATE POLICY "Owners can insert verification request" ON public.restaurant_verifications
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Admins can update verification requests" ON public.restaurant_verifications;
CREATE POLICY "Admins can update verification requests" ON public.restaurant_verifications
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin', 'moderator')
        )
    );

-- 5.10 AD PACKAGES POLICIES
DROP POLICY IF EXISTS "Owners can view own ad packages" ON public.ad_packages;
CREATE POLICY "Owners can view own ad packages" ON public.ad_packages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = ad_packages.restaurant_id AND r.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

DROP POLICY IF EXISTS "Owners can create ad packages" ON public.ad_packages;
CREATE POLICY "Owners can create ad packages" ON public.ad_packages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = ad_packages.restaurant_id AND r.owner_id = auth.uid()
        )
    );

-- 5.11 REVIEWS POLICIES
DROP POLICY IF EXISTS "Anyone can read reviews" ON public.reviews;
CREATE POLICY "Anyone can read reviews" ON public.reviews
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Customers can create reviews" ON public.reviews;
CREATE POLICY "Customers can create reviews" ON public.reviews
    FOR INSERT WITH CHECK (
        auth.uid() = customer_id 
        OR auth.uid() = user_id
    );

DROP POLICY IF EXISTS "Customers can update own reviews" ON public.reviews;
CREATE POLICY "Customers can update own reviews" ON public.reviews
    FOR UPDATE USING (
        auth.uid() = customer_id 
        OR auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

DROP POLICY IF EXISTS "Customers can delete own reviews" ON public.reviews;
CREATE POLICY "Customers can delete own reviews" ON public.reviews
    FOR DELETE USING (
        auth.uid() = customer_id 
        OR auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

-- 5.12 NOTIFICATIONS POLICIES
DROP POLICY IF EXISTS "Users view own notifications" ON public.notifications;
CREATE POLICY "Users view own notifications" ON public.notifications
    FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM public.restaurants r
            WHERE r.id = notifications.restaurant_id AND r.owner_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'head_admin')
        )
    );

DROP POLICY IF EXISTS "Auth users can insert notifications" ON public.notifications;
CREATE POLICY "Auth users can insert notifications" ON public.notifications
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications" ON public.notifications
    FOR DELETE USING (auth.uid() = user_id);

-- 5.13 GROUP ORDERS POLICIES
DROP POLICY IF EXISTS "Anyone can view open group orders" ON public.group_orders;
CREATE POLICY "Anyone can view open group orders" ON public.group_orders
    FOR SELECT USING (status = 'open' OR auth.uid() = creator_id);

DROP POLICY IF EXISTS "Users can create group orders" ON public.group_orders;
CREATE POLICY "Users can create group orders" ON public.group_orders
    FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- ==============================================================================
-- 6. AUTOMATED TRIGGERS (Updated At & Profile Creation)
-- ==============================================================================

-- 6.1 Generic updated_at timestamp trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_restaurants_updated_at ON public.restaurants;
CREATE TRIGGER set_restaurants_updated_at
    BEFORE UPDATE ON public.restaurants
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_offers_updated_at ON public.offers;
CREATE TRIGGER set_offers_updated_at
    BEFORE UPDATE ON public.offers
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_orders_updated_at ON public.orders;
CREATE TRIGGER set_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_customer_addresses_updated_at ON public.customer_addresses;
CREATE TRIGGER set_customer_addresses_updated_at
    BEFORE UPDATE ON public.customer_addresses
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_restaurant_verifications_updated_at ON public.restaurant_verifications;
CREATE TRIGGER set_restaurant_verifications_updated_at
    BEFORE UPDATE ON public.restaurant_verifications
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.2 Automatic User Profile Trigger (On Auth User Creation)
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 7. STORAGE BUCKETS CONFIGURATION (All 6 Application Buckets)
-- ==============================================================================
-- 1) avatars (Public)
-- 2) restaurant-images (Public)
-- 3) offer-images (Public)
-- 4) promo-banners (Public)
-- 5) verification-documents (Private / Protected for Trade License & NID)
-- 6) review-images (Public)

INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('avatars', 'avatars', true),
    ('restaurant-images', 'restaurant-images', true),
    ('offer-images', 'offer-images', true),
    ('promo-banners', 'promo-banners', true),
    ('verification-documents', 'verification-documents', false),
    ('review-images', 'review-images', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- ==============================================================================
-- 8. STORAGE RLS POLICIES (Read, Insert, Update / Upsert, Delete)
-- ==============================================================================

-- 8.1 Public Read for public media buckets
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

DROP POLICY IF EXISTS "Public Access Review Images" ON storage.objects;
CREATE POLICY "Public Access Review Images" ON storage.objects
    FOR SELECT USING (bucket_id = 'review-images');

-- 8.2 Private Read for sensitive verification documents (Trade License & NID)
DROP POLICY IF EXISTS "Private Read Verification Documents" ON storage.objects;
CREATE POLICY "Private Read Verification Documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'verification-documents' 
        AND auth.role() = 'authenticated'
    );

-- 8.3 Authenticated Uploads (INSERT)
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

DROP POLICY IF EXISTS "Auth Users Upload Verification Documents" ON storage.objects;
CREATE POLICY "Auth Users Upload Verification Documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'verification-documents' AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Auth Users Upload Review Images" ON storage.objects;
CREATE POLICY "Auth Users Upload Review Images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'review-images' AND auth.role() = 'authenticated'
    );

-- 8.4 Authenticated Updates (UPDATE / Upsert) - Critical for avatar & file replacements!
DROP POLICY IF EXISTS "Auth Users Update Avatars" ON storage.objects;
CREATE POLICY "Auth Users Update Avatars" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'avatars' AND auth.role() = 'authenticated'
    ) WITH CHECK (
        bucket_id = 'avatars' AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Auth Users Update Restaurant Images" ON storage.objects;
CREATE POLICY "Auth Users Update Restaurant Images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'restaurant-images' AND auth.role() = 'authenticated'
    ) WITH CHECK (
        bucket_id = 'restaurant-images' AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Auth Users Update Offer Images" ON storage.objects;
CREATE POLICY "Auth Users Update Offer Images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'offer-images' AND auth.role() = 'authenticated'
    ) WITH CHECK (
        bucket_id = 'offer-images' AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Auth Users Update Promo Banners" ON storage.objects;
CREATE POLICY "Auth Users Update Promo Banners" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'promo-banners' AND auth.role() = 'authenticated'
    ) WITH CHECK (
        bucket_id = 'promo-banners' AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Auth Users Update Review Images" ON storage.objects;
CREATE POLICY "Auth Users Update Review Images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'review-images' AND auth.role() = 'authenticated'
    ) WITH CHECK (
        bucket_id = 'review-images' AND auth.role() = 'authenticated'
    );

-- 8.5 Authenticated Deletes (DELETE)
DROP POLICY IF EXISTS "Auth Users Delete Media" ON storage.objects;
CREATE POLICY "Auth Users Delete Media" ON storage.objects
    FOR DELETE USING (auth.role() = 'authenticated');

-- ==============================================================================
-- 9. DEFAULT SEED DATA (Idempotent ON CONFLICT DO NOTHING)
-- ==============================================================================

-- 9.1 Default Promo Banners
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

-- 9.2 Default Platform Promo Codes
INSERT INTO public.vouchers (code, title, description, discount_type, discount_value, min_order_amount, is_platform_sponsored, is_super_saver_exclusive, valid_until)
VALUES 
    (
        'SAVEBITE50',
        'SaveBite Welcome Gift',
        '৳50 OFF on food orders above ৳150',
        'flat',
        50.0,
        150.0,
        true,
        false,
        timezone('utc'::text, now()) + interval '365 days'
    ),
    (
        'SAVE20',
        '20% Surplus Food Saver',
        '20% OFF on takeaway meals (Min ৳100, Max ৳80)',
        'percentage',
        20.0,
        100.0,
        true,
        false,
        timezone('utc'::text, now()) + interval '365 days'
    ),
    (
        'RESCUE30',
        'Evening Rescue Feast',
        '৳30 OFF on closing-hour clearance surplus (Min ৳120)',
        'flat',
        30.0,
        120.0,
        true,
        false,
        timezone('utc'::text, now()) + interval '365 days'
    )
ON CONFLICT (code) DO NOTHING;
