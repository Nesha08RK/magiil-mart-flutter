# Supabase Database Setup Guide for Admin Feature

## Quick Setup Instructions

This guide will help you set up the Supabase database to support both Admin and Customer features.

## Step 1: Create Products Table

Go to Supabase Dashboard → SQL Editor and run:

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  base_price INTEGER NOT NULL,
  base_unit TEXT NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  is_out_of_stock BOOLEAN NOT NULL DEFAULT FALSE,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Step 2: Ensure Profiles Table Has Role Column

### Option A: If profiles table doesn't exist yet
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'customer',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Option B: If profiles table exists (add role column)
```sql
ALTER TABLE profiles ADD COLUMN role TEXT NOT NULL DEFAULT 'customer';
```

## Step 3: Set Up Row Level Security (RLS)

### Enable RLS on products table
```sql
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
```

### Enable RLS on profiles table (if not already enabled)
```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
```

## Step 4: Create RLS Policies for Products Table

### Policy 1: Admin Full Access (Read and Write)
```sql
CREATE POLICY admin_all ON products
  FOR ALL
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  )
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );
```

### Policy 2: Customer Read-Only Access
```sql
CREATE POLICY customer_read ON products
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'customer'
    )
  );
```

## Step 5: Create RLS Policies for Profiles Table

### Policy 1: Users can read their own profile
```sql
CREATE POLICY user_read_own_profile ON profiles
  FOR SELECT
  USING (auth.uid() = id);
```

### Policy 2: Users can update their own profile
```sql
CREATE POLICY user_update_own_profile ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
```

### Policy 3: Users can insert their own profile
```sql
CREATE POLICY user_insert_profile ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);
```

## Step 6: Create Auth Trigger for Profiles

To automatically create a profile when a user signs up:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, role)
  VALUES (NEW.id, 'customer');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

## Step 7: Create Admin Users

In Supabase Dashboard:

1. Go to Authentication → Users
2. Create a new user for admin
3. Go to SQL Editor and update their role:

```sql
UPDATE profiles SET role = 'admin' WHERE id = '[ADMIN_USER_ID]';
```

Replace `[ADMIN_USER_ID]` with the actual UUID from the auth.users table.

## Step 8: Verify Setup

Run these queries to verify everything is set up correctly:

### Check products table structure
```sql
SELECT * FROM information_schema.columns 
WHERE table_name = 'products';
```

### Check profiles table structure
```sql
SELECT * FROM information_schema.columns 
WHERE table_name = 'profiles';
```

### Check RLS policies
```sql
SELECT tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('products', 'profiles');
```

### Check sample users and roles
```sql
SELECT id, email, (SELECT role FROM profiles WHERE id = auth.users.id) as role
FROM auth.users;
```

## Step 9: Insert Sample Data (Optional)

Add some sample products for testing:

```sql
INSERT INTO products (name, base_price, base_unit, stock, is_out_of_stock, category)
VALUES
  ('Tomato', 50, 'kg', 100, false, 'Vegetables'),
  ('Carrot', 40, 'kg', 80, false, 'Vegetables'),
  ('Apple', 120, 'kg', 50, false, 'Fruits'),
  ('Banana', 60, 'kg', 0, true, 'Fruits'),
  ('Rice', 200, 'kg', 200, false, 'Groceries'),
  ('Wheat Flour', 80, 'kg', 150, false, 'Groceries'),
  ('Milk', 100, 'L', 100, false, 'Groceries'),
  ('Oil', 180, 'L', 75, false, 'Groceries');
```

## Troubleshooting

### Issue: Admin can't see products
**Solution:** Check RLS policy for admin. Ensure:
- RLS is enabled on products table
- Admin role is set correctly in profiles table
- Policy references profiles table correctly

### Issue: Customers seeing admin data
**Solution:** 
- Verify RLS policies are correctly configured
- Ensure customer role is 'customer' (not 'Customer' or other variations)
- Check that USING clause has correct role check

### Issue: Role column doesn't exist
**Solution:**
- Add column: `ALTER TABLE profiles ADD COLUMN role TEXT NOT NULL DEFAULT 'customer';`
- Update existing users: `UPDATE profiles SET role = 'customer';`

### Issue: New users don't get role automatically
**Solution:**
- Create trigger as shown in Step 6
- Or set role manually when creating user

### Issue: "relation 'profiles' does not exist"
**Solution:**
- Create profiles table using Step 2, Option A
- Ensure table is created in public schema
- Verify name is exactly 'profiles' (lowercase)

## Important Notes

⚠️ **Case Sensitivity:**
- Role values must be lowercase: 'admin' or 'customer'
- Table names are case-sensitive in PostgreSQL

⚠️ **RLS Rules:**
- RLS is default-deny: if no policy matches, access is denied
- Make sure at least one policy matches your user role
- Test policies before deploying to production

⚠️ **Performance:**
- RLS policies with subqueries (like checking profiles table) can impact performance
- For large datasets, consider caching role in JWT claims
- Monitor query performance in Supabase dashboard

## Testing the Setup

### Test 1: Admin Access
1. Login as admin user
2. Check if you're routed to Admin Dashboard
3. Try to add/edit/delete a product
4. Verify changes are saved in Supabase

### Test 2: Customer Access
1. Login as customer user
2. Check if you're routed to Main Navigation
3. Try to browse products
4. Try to add out-of-stock product to cart (should fail)
5. Try to add in-stock product to cart (should succeed)

### Test 3: Access Control
1. Directly query Supabase from a customer client
2. Try to INSERT/UPDATE/DELETE on products table
3. Should receive permission denied error

## Next Steps

After database setup:

1. Update admin and customer users' roles in Supabase
2. Deploy the Flutter app
3. Test both admin and customer flows
4. Monitor Supabase logs for any RLS-related errors

## Support Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL ROLE Documentation](https://www.postgresql.org/docs/current/sql-createrole.html)
- [Supabase SQL Editor](https://app.supabase.com/)
