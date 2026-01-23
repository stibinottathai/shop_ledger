-- Add user_id column to transactions table
ALTER TABLE transactions 
ADD COLUMN user_id UUID REFERENCES auth.users(id);

-- Optional: Update existing records to belong to the current user 
-- (Replace 'YOUR_USER_ID' with your actual User ID from Supabase Authentication)
-- UPDATE transactions SET user_id = 'YOUR_USER_ID' WHERE user_id IS NULL;

-- Enable Row Level Security (RLS) if not already enabled
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to insert their own transactions
CREATE POLICY "Users can insert their own transactions" 
ON transactions FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Policy to allow users to view their own transactions
CREATE POLICY "Users can view their own transactions" 
ON transactions FOR SELECT 
USING (auth.uid() = user_id);

-- Policy to allow users to update their own transactions
CREATE POLICY "Users can update their own transactions" 
ON transactions FOR UPDATE 
USING (auth.uid() = user_id);

-- Policy to allow users to delete their own transactions
CREATE POLICY "Users can delete their own transactions" 
ON transactions FOR DELETE 
USING (auth.uid() = user_id);
