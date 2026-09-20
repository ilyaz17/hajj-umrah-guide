-- Hajj & Umrah Guide: foundational Supabase schema
create extension if not exists pgcrypto;
do $$ begin create type public.subscription_tier as enum ('free','lite','pro'); exception when duplicate_object then null; end $$;
do $$ begin create type public.ritual_category as enum ('tawaf','sai','arafat','muzdalifah','mina','jamarat','general'); exception when duplicate_object then null; end $$;

create table if not exists public.profiles (id uuid primary key default gen_random_uuid(), user_id uuid unique not null references auth.users(id) on delete cascade, full_name text, subscription_tier public.subscription_tier not null default 'free', pilgrimage_status text not null default 'planning', updated_at timestamptz not null default now());
create table if not exists public.rituals (id uuid primary key default gen_random_uuid(), title text not null, category public.ritual_category not null, step_order integer not null, latitude numeric(10,8) not null, longitude numeric(11,8) not null, radius_meters integer not null default 100, duas_json jsonb not null default '[]'::jsonb, tier_required public.subscription_tier not null default 'free');
create table if not exists public.user_progress (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, ritual_id uuid not null references public.rituals(id) on delete cascade, current_circuit integer not null default 0, completed boolean not null default false, updated_at timestamptz not null default now(), unique(user_id, ritual_id));

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$ begin insert into public.profiles (user_id, full_name) values (new.id, coalesce(new.raw_user_meta_data->>'full_name', '')); return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security; alter table public.rituals enable row level security; alter table public.user_progress enable row level security;
drop policy if exists "profiles own read" on public.profiles; create policy "profiles own read" on public.profiles for select using (auth.uid() = user_id);
drop policy if exists "profiles own update" on public.profiles; create policy "profiles own update" on public.profiles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "rituals public read" on public.rituals; create policy "rituals public read" on public.rituals for select using (true);
drop policy if exists "progress own read" on public.user_progress; create policy "progress own read" on public.user_progress for select using (auth.uid() = user_id);
drop policy if exists "progress own write" on public.user_progress; create policy "progress own write" on public.user_progress for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

insert into public.rituals (title, category, step_order, latitude, longitude, radius_meters, tier_required, duas_json) values
('Tawaf at the Kaaba','tawaf',1,21.422487,39.826206,150,'free','[{"title":"Remember Allah","translation":"Make sincere dhikr and dua in the language of your heart."}]'),
('Sa’i between Safa and Marwa','sai',2,21.422100,39.826000,250,'free','[{"title":"Safa and Marwa","translation":"Indeed, Safa and Marwa are among the symbols of Allah."}]'),
('Arafat','arafat',3,21.354800,39.984100,1200,'free','[]'),
('Muzdalifah','muzdalifah',4,21.389100,39.912600,900,'free','[]'),
('Jamarat','jamarat',5,21.413700,39.878900,500,'free','[]') on conflict (title) do nothing;
