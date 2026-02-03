-- ================================================
-- Row Level Security (RLS) Policies for Shop Ledger
-- ================================================
-- Execute this script in your Supabase SQL Editor
-- Dashboard → SQL Editor → New query → Paste and Run
-- ================================================

-- ================================================
-- 1. ITEMS TABLE
-- ================================================

-- Enable RLS
ALTER TABLE items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any (prevents errors on re-run)
DROP POLICY IF EXISTS "Users can view own items" ON items;
DROP POLICY IF EXISTS "Users can insert own items" ON items;
DROP POLICY IF EXISTS "Users can update own items" ON items;
DROP POLICY IF EXISTS "Users can delete own items" ON items;

-- Policy: Users can view their own items
CREATE POLICY "Users can view own items"
ON items FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own items
CREATE POLICY "Users can insert own items"
ON items FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own items
CREATE POLICY "Users can update own items"
ON items FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own items
CREATE POLICY "Users can delete own items"
ON items FOR DELETE
USING (auth.uid() = user_id);


-- ================================================
-- 2. CUSTOMERS TABLE
-- ================================================

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own customers" ON customers;
DROP POLICY IF EXISTS "Users can insert own customers" ON customers;
DROP POLICY IF EXISTS "Users can update own customers" ON customers;
DROP POLICY IF EXISTS "Users can delete own customers" ON customers;

-- Policy: Users can view their own customers
CREATE POLICY "Users can view own customers"
ON customers FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own customers
CREATE POLICY "Users can insert own customers"
ON customers FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own customers
CREATE POLICY "Users can update own customers"
ON customers FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own customers
CREATE POLICY "Users can delete own customers"
ON customers FOR DELETE
USING (auth.uid() = user_id);


-- ================================================
-- 3. TRANSACTIONS TABLE
-- ================================================

-- Enable RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can update own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can delete own transactions" ON transactions;

-- Policy: Users can view transactions for their customers
-- This joins with customers table to check ownership
CREATE POLICY "Users can view own transactions"
ON transactions FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.id = transactions.customer_id
    AND customers.user_id = auth.uid()
  )
);

-- Policy: Users can insert transactions for their customers
CREATE POLICY "Users can insert own transactions"
ON transactions FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.id = transactions.customer_id
    AND customers.user_id = auth.uid()
  )
);

-- Policy: Users can update their own transactions
CREATE POLICY "Users can update own transactions"
ON transactions FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.id = transactions.customer_id
    AND customers.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.id = transactions.customer_id
    AND customers.user_id = auth.uid()
  )
);

-- Policy: Users can delete their own transactions
CREATE POLICY "Users can delete own transactions"
ON transactions FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM customers
    WHERE customers.id = transactions.customer_id
    AND customers.user_id = auth.uid()
  )
);


-- ================================================
-- 4. EXPENSES TABLE
-- ================================================

-- Enable RLS
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can insert own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can update own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can delete own expenses" ON expenses;

-- Policy: Users can view their own expenses
CREATE POLICY "Users can view own expenses"
ON expenses FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own expenses
CREATE POLICY "Users can insert own expenses"
ON expenses FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own expenses
CREATE POLICY "Users can update own expenses"
ON expenses FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own expenses
CREATE POLICY "Users can delete own expenses"
ON expenses FOR DELETE
USING (auth.uid() = user_id);


-- ================================================
-- 5. SUPPLIERS TABLE
-- ================================================

-- Enable RLS
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own suppliers" ON suppliers;
DROP POLICY IF EXISTS "Users can insert own suppliers" ON suppliers;
DROP POLICY IF EXISTS "Users can update own suppliers" ON suppliers;
DROP POLICY IF EXISTS "Users can delete own suppliers" ON suppliers;

-- Policy: Users can view their own suppliers
CREATE POLICY "Users can view own suppliers"
ON suppliers FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own suppliers
CREATE POLICY "Users can insert own suppliers"
ON suppliers FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own suppliers
CREATE POLICY "Users can update own suppliers"
ON suppliers FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own suppliers
CREATE POLICY "Users can delete own suppliers"
ON suppliers FOR DELETE
USING (auth.uid() = user_id);


-- ================================================
-- VERIFICATION QUERIES
-- ================================================
-- Run these to verify RLS is enabled on all tables

SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename IN ('items', 'customers', 'transactions', 'expenses', 'suppliers')
AND schemaname = 'public';

-- Should show rowsecurity = true for all tables

-- List all policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename IN ('items', 'customers', 'transactions', 'expenses', 'suppliers')
ORDER BY tablename, cmd;

-- ================================================
-- SUCCESS MESSAGE
-- ================================================
-- If this script runs without errors, RLS is now enabled!
-- Test with multiple user accounts to verify isolation.
