-- Add missing columns to items table
ALTER TABLE public.items 
ADD COLUMN IF NOT EXISTS barcode text,
ADD COLUMN IF NOT EXISTS unit text DEFAULT 'kg';
