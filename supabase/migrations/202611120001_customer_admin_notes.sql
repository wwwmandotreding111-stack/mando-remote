create table if not exists public.customer_admin_notes (
  user_id uuid primary key references public.customer_profiles(id) on delete cascade,
  note text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.customer_admin_notes enable row level security;

drop policy if exists "Admins can read customer admin notes" on public.customer_admin_notes;
create policy "Admins can read customer admin notes"
on public.customer_admin_notes
for select
to authenticated
using (public.is_admin());

create or replace function public.set_customer_admin_note(
  p_user_id uuid,
  p_note text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'غير مصرح';
  end if;

  if not exists (
    select 1 from public.customer_profiles
    where id = p_user_id and role = 'customer'
  ) then
    raise exception 'الزبون غير موجود';
  end if;

  insert into public.customer_admin_notes(user_id, note, updated_at)
  values (p_user_id, left(coalesce(p_note, ''), 500), now())
  on conflict (user_id)
  do update set note = excluded.note, updated_at = now();
end;
$$;

revoke all on function public.set_customer_admin_note(uuid, text) from public;
grant execute on function public.set_customer_admin_note(uuid, text) to authenticated;

notify pgrst, 'reload schema';
