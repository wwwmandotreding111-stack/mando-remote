alter table public.customer_profiles
add column if not exists admin_note text;

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

  update public.customer_profiles
  set admin_note = left(coalesce(p_note, ''), 500)
  where id = p_user_id
    and role = 'customer';

  if not found then
    raise exception 'الزبون غير موجود';
  end if;
end;
$$;

revoke all on function public.set_customer_admin_note(uuid, text) from public;
grant execute on function public.set_customer_admin_note(uuid, text) to authenticated;
