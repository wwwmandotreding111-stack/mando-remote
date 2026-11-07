-- MANDO APPS: run once in Supabase SQL Editor
create table if not exists public.mando_apps (
 id uuid primary key default gen_random_uuid(),
 name text not null check (char_length(name) <= 50),
 version text,
 description text,
 icon_url text,
 file_path text not null,
 download_url text not null,
 size_label text,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
alter table public.mando_apps enable row level security;
drop policy if exists "Public can read active apps" on public.mando_apps;
create policy "Public can read active apps" on public.mando_apps for select using (is_active = true or public.is_admin());
drop policy if exists "Admins can insert apps" on public.mando_apps;
create policy "Admins can insert apps" on public.mando_apps for insert with check (public.is_admin());
drop policy if exists "Admins can delete apps" on public.mando_apps;
create policy "Admins can delete apps" on public.mando_apps for delete using (public.is_admin());
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('mando-apks','mando-apks',true,31457280,array['application/vnd.android.package-archive','application/octet-stream','image/png','image/jpeg','image/webp'])
on conflict (id) do update set public=true,file_size_limit=31457280,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "Public can download MANDO apps" on storage.objects;
create policy "Public can download MANDO apps" on storage.objects for select using (bucket_id='mando-apks');
drop policy if exists "Admins can upload MANDO apps" on storage.objects;
create policy "Admins can upload MANDO apps" on storage.objects for insert with check (bucket_id='mando-apks' and public.is_admin());
drop policy if exists "Admins can delete MANDO apps" on storage.objects;
create policy "Admins can delete MANDO apps" on storage.objects for delete using (bucket_id='mando-apks' and public.is_admin());
