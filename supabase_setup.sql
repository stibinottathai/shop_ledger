-- Create expenses table
create table public.expenses (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone null,
  amount double precision not null,
  category text not null,
  payment_method text not null,
  date timestamp with time zone not null,
  notes text null,
  recurring text null,
  user_id uuid null default auth.uid (),
  constraint expenses_pkey primary key (id),
  constraint expenses_user_id_fkey foreign key (user_id) references auth.users (id) on delete cascade
) tablespace pg_default;

-- Add RLS policies (optional but recommended)
alter table public.expenses enable row level security;

create policy "Users can view their own expenses" on public.expenses
  for select using (auth.uid() = user_id);

create policy "Users can insert their own expenses" on public.expenses
  for insert with check (auth.uid() = user_id);

create policy "Users can update their own expenses" on public.expenses
  for update using (auth.uid() = user_id);

create policy "Users can delete their own expenses" on public.expenses
  for delete using (auth.uid() = user_id);
