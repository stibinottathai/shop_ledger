# RLS Testing Guide - Shop Ledger

## Purpose
Verify that Row Level Security policies prevent users from accessing each other's data.

## Prerequisites
- ✅ RLS policies have been applied (run `supabase_rls_policies.sql`)
- ✅ App is running on a device/emulator

---

## Test Plan

### Step 1: Create Test Accounts

Create two test user accounts in your app:

**Test User A:**
- Email: `test_user_a@example.com`
- Password: `TestPass123!`

**Test User B:**
- Email: `test_user_b@example.com`
- Password: `TestPass123!`

### Step 2: Add Data as User A

Login as **Test User A** and create:
- 2 customers (e.g., "Customer A1", "Customer A2")
- 3 items (e.g., "Rice A", "Oil A", "Sugar A")
- 2 expenses (e.g., "Rent", "Electricity")
- 1 supplier (e.g., "Supplier A")
- 2 transactions for Customer A1

**Expected:** All data saves successfully.

### Step 3: Verify User A's Data

While still logged in as **Test User A**:
- ✅ Can see all 2 customers
- ✅ Can see all 3 items
- ✅ Can see all 2 expenses
- ✅ Can see 1 supplier
- ✅ Can see transactions for Customer A1

### Step 4: Switch to User B

Logout and login as **Test User B**.

**Expected:** 
- ❌ Should see NO customers
- ❌ Should see NO items
- ❌ Should see NO expenses
- ❌ Should see NO suppliers
- ❌ Should see NO transactions

**This confirms RLS is working!**

### Step 5: Add Data as User B

While logged in as **Test User B**, create:
- 1 customer (e.g., "Customer B1")
- 2 items (e.g., "Rice B", "Oil B")
- 1 expense (e.g., "Salary")

**Expected:** All data saves successfully.

### Step 6: Verify Data Isolation

While still as **Test User B**:
- ✅ Can see ONLY Customer B1 (not A1, A2)
- ✅ Can see ONLY 2 items (Rice B, Oil B)
- ✅ Can see ONLY 1 expense (Salary)
- ❌ Cannot see User A's data

### Step 7: Test Transactions

As **Test User B**, try to create a transaction:
- Select Customer B1
- Create a sale

**Expected:** Transaction saves successfully.

Now, check transactions list:
- ✅ Should see ONLY transactions for Customer B1
- ❌ Should NOT see User A's transactions

### Step 8: Switch Back to User A

Logout and login as **Test User A** again.

**Expected:**
- ✅ Still sees all original data (2 customers, 3 items, etc.)
- ❌ Does NOT see User B's data

---

## Troubleshooting

### If User B Can See User A's Data

**Problem:** RLS policies not applied or not working.

**Solution:**
1. Check if RLS is enabled:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename IN ('items', 'customers', 'transactions', 'expenses', 'suppliers');
   ```
   All should show `rowsecurity = true`

2. Re-run the RLS policies SQL script

3. Check for any errors in Supabase logs

### If User A Cannot See Their Own Data

**Problem:** Policies too restrictive or auth.uid() not working.

**Solution:**
1. Verify you're logged in (check `auth.uid()` in SQL Editor)
2. Check if `user_id` column exists and is populated
3. Run this query to debug:
   ```sql
   SELECT id, name, user_id, auth.uid() as current_user
   FROM items;
   ```

### If Creating Data Fails

**Problem:** INSERT policy blocking.

**Solution:**
1. Check app is setting `user_id` correctly:
   ```dart
   final user = supabase.auth.currentUser;
   await supabase.from('items').insert({
     'user_id': user.id,  // Must be included!
     'name': 'Test',
     // ... other fields
   });
   ```

2. Verify INSERT policy exists for the table

---

## Success Criteria

✅ **RLS is working correctly if:**
- User A cannot see User B's data
- User B cannot see User A's data
- Each user can only CRUD their own data
- Transactions properly check customer ownership
- No errors occur during normal app usage

---

## Additional Verification (SQL)

Run these queries in Supabase SQL Editor as different users:

```sql
-- Check current user
SELECT auth.uid() as my_user_id;

-- Check items (should only show current user's items)
SELECT id, name, user_id FROM items;

-- Check customers (should only show current user's customers)
SELECT id, name, user_id FROM customers;

-- Check transactions (should only show transactions for current user's customers)
SELECT t.id, t.amount, c.name as customer_name, c.user_id
FROM transactions t
JOIN customers c ON c.id = t.customer_id;
```

---

## Final Checklist

Before releasing to Play Store:

- [ ] Completed all test steps above
- [ ] Verified data isolation between users
- [ ] Tested all CRUD operations work
- [ ] No errors in app logs
- [ ] No errors in Supabase logs
- [ ] Tested on clean install (new user)
- [ ] Tested with multiple concurrent users
