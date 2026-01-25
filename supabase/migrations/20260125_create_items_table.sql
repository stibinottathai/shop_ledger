-- Create items table
create table if not exists public.items (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  price_per_kg numeric not null default 0,
  total_quantity numeric,
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.items enable row level security;

-- Policies
create policy "Users can view their own items"
on public.items for select
using (auth.uid() = user_id);

create policy "Users can insert their own items"
on public.items for insert
with check (auth.uid() = user_id);

create policy "Users can update their own items"
on public.items for update
using (auth.uid() = user_id);

create policy "Users can delete their own items"
on public.items for delete
using (auth.uid() = user_id);
