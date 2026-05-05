-- ==========================================
-- RAMESH COLLECTION | SUPABASE SCHEMA
-- ==========================================

-- 1. Tables Creation
CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category TEXT NOT NULL,
  image_url TEXT,
  stock INTEGER DEFAULT 0,
  badge TEXT
);

CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  full_name TEXT,
  email TEXT
);

CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  user_id UUID REFERENCES auth.users ON DELETE SET NULL,
  items JSONB NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  payment_id TEXT,
  shipping_address TEXT,
  customer_name TEXT,
  customer_phone TEXT
);

-- 2. Constraints & Cleanup
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE orders ADD CONSTRAINT orders_status_check 
  CHECK (status IN ('pending', 'accepted', 'in_transit', 'shipped', 'cancelled'));

-- 3. Row Level Security (RLS)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Product Policies
DROP POLICY IF EXISTS "Public View Products" ON products;
CREATE POLICY "Public View Products" ON products FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin Manage Products" ON products;
CREATE POLICY "Admin Manage Products" ON products FOR ALL USING (true);

-- Profile Policies
DROP POLICY IF EXISTS "Public View Profiles" ON profiles;
CREATE POLICY "Public View Profiles" ON profiles FOR SELECT USING (true);

-- Order Policies
DROP POLICY IF EXISTS "Public Read Orders" ON orders;
CREATE POLICY "Public Read Orders" ON orders FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users Insert Orders" ON orders;
CREATE POLICY "Users Insert Orders" ON orders FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users Cancel Own Orders" ON orders;
CREATE POLICY "Users Cancel Own Orders" ON orders 
FOR UPDATE USING (
  auth.uid() = user_id AND status IN ('pending', 'accepted')
) WITH CHECK (
  status = 'cancelled'
);

DROP POLICY IF EXISTS "Admin Manage Orders" ON orders;
CREATE POLICY "Admin Manage Orders" ON orders FOR ALL USING (true);

-- 4. Storage Configuration
-- Ensure 'products' bucket exists
INSERT INTO storage.buckets (id, name, public) 
VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
DROP POLICY IF EXISTS "Storage Public View" ON storage.objects;
CREATE POLICY "Storage Public View" ON storage.objects FOR SELECT USING (bucket_id = 'products');

DROP POLICY IF EXISTS "Storage Admin Management" ON storage.objects;
CREATE POLICY "Storage Admin Management" ON storage.objects FOR ALL USING (bucket_id = 'products');
