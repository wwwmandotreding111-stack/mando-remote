-- Allow each signed-in customer to read only their own profile,
-- so the website can restore the saved login session safely.
drop policy if exists "Customers can read their own profile" on public.customer_profiles;
create policy "Customers can read their own profile"
on public.customer_profiles
for select
to authenticated
using (id = auth.uid());
