-- MANDO REMOTE: customer management and online presence
alter table public.customer_profiles add column if not exists last_seen_at timestamptz;
drop policy if exists "Admins can view all customer profiles" on public.customer_profiles;
create policy "Admins can view all customer profiles" on public.customer_profiles
for select to authenticated using (public.is_admin());
create or replace function public.touch_my_presence()
returns void language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null then return; end if;
  update public.customer_profiles set last_seen_at=now()
  where id=auth.uid() and active=true;
end;
$$;
revoke all on function public.touch_my_presence() from public;
grant execute on function public.touch_my_presence() to authenticated;
