-- Chá de fraldas do Samuel Felipe
-- Execute no SQL Editor de um projeto Supabase novo.
-- Nunca coloque a chave service_role no site.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.gift_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  size text,
  description text,
  stock_total integer not null default 0 check (stock_total >= 0),
  stock_reserved integer not null default 0 check (stock_reserved >= 0),
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint gift_stock_valid check (stock_reserved <= stock_total)
);

create table if not exists public.gift_reservations (
  id uuid primary key default gen_random_uuid(),
  guest_name text not null check (char_length(trim(guest_name)) between 2 and 100),
  guest_phone text,
  status text not null default 'reserved'
    check (status in ('reserved','received','cancelled')),
  whatsapp_status text not null default 'pending'
    check (whatsapp_status in ('pending','reported_sent','checked')),
  guest_token uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gift_reservation_items (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.gift_reservations(id) on delete cascade,
  gift_item_id uuid not null references public.gift_items(id),
  item_name text not null,
  item_size text,
  quantity integer not null check (quantity between 1 and 30),
  unique (reservation_id, gift_item_id)
);

create index if not exists gift_reservations_created_at_idx
  on public.gift_reservations(created_at desc);
create index if not exists gift_reservation_items_reservation_idx
  on public.gift_reservation_items(reservation_id);

alter table public.admin_users enable row level security;
alter table public.gift_items enable row level security;
alter table public.gift_reservations enable row level security;
alter table public.gift_reservation_items enable row level security;

create or replace function public.is_gift_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $
  select exists (select 1 from public.admin_users where user_id = auth.uid());
$;
revoke all on function public.is_gift_admin() from public;
grant execute on function public.is_gift_admin() to authenticated;

drop policy if exists "Admins can read own admin record" on public.admin_users;
create policy "Admins can read own admin record" on public.admin_users
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "Public can view active gifts" on public.gift_items;
create policy "Public can view active gifts" on public.gift_items
  for select to anon, authenticated
  using (active = true);

drop policy if exists "Admins manage gifts" on public.gift_items;
create policy "Admins manage gifts" on public.gift_items
  for all to authenticated
  using (public.is_gift_admin())
  with check (public.is_gift_admin());

drop policy if exists "Admins view reservations" on public.gift_reservations;
create policy "Admins view reservations" on public.gift_reservations
  for select to authenticated
  using (public.is_gift_admin());

drop policy if exists "Admins update reservations" on public.gift_reservations;
create policy "Admins update reservations" on public.gift_reservations
  for update to authenticated
  using (public.is_gift_admin())
  with check (public.is_gift_admin());

drop policy if exists "Admins view reservation items" on public.gift_reservation_items;
create policy "Admins view reservation items" on public.gift_reservation_items
  for select to authenticated
  using (public.is_gift_admin());

-- Guests must reserve through this function. It locks stock rows to prevent
-- two guests from reserving the same final units at the same time.
create or replace function public.create_gift_reservation(
  p_guest_name text,
  p_guest_phone text,
  p_items jsonb
)
returns table (
  reservation_id uuid,
  guest_token uuid,
  reserved_items jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reservation_id uuid := gen_random_uuid();
  v_guest_token uuid := gen_random_uuid();
  v_item jsonb;
  v_gift_id uuid;
  v_qty integer;
  v_gift public.gift_items%rowtype;
  v_result jsonb := '[]'::jsonb;
  v_count integer := 0;
begin
  if p_guest_name is null or char_length(trim(p_guest_name)) not between 2 and 100 then
    raise exception 'Informe um nome válido.';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Escolha pelo menos um presente.';
  end if;
  if jsonb_array_length(p_items) > 30 then
    raise exception 'Limite de itens excedido.';
  end if;

  insert into public.gift_reservations(id, guest_name, guest_phone, guest_token)
  values (v_reservation_id, trim(p_guest_name), nullif(trim(p_guest_phone), ''), v_guest_token);

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_gift_id := (v_item->>'gift_item_id')::uuid;
    v_qty := (v_item->>'quantity')::integer;
    if v_qty is null or v_qty < 1 or v_qty > 30 then
      raise exception 'Quantidade inválida.';
    end if;

    select * into v_gift
      from public.gift_items
      where id = v_gift_id and active = true
      for update;

    if not found then
      raise exception 'Um dos presentes não está disponível.';
    end if;
    if v_gift.stock_total - v_gift.stock_reserved < v_qty then
      raise exception 'Estoque insuficiente para: %.', v_gift.name;
    end if;

    update public.gift_items
      set stock_reserved = stock_reserved + v_qty
      where id = v_gift_id;

    insert into public.gift_reservation_items(
      reservation_id, gift_item_id, item_name, item_size, quantity
    ) values (
      v_reservation_id, v_gift_id, v_gift.name, v_gift.size, v_qty
    );

    v_result := v_result || jsonb_build_array(jsonb_build_object(
      'name', v_gift.name, 'size', v_gift.size, 'quantity', v_qty
    ));
    v_count := v_count + 1;
  end loop;

  if v_count = 0 then
    raise exception 'Escolha pelo menos um presente.';
  end if;

  return query select v_reservation_id, v_guest_token, v_result;
end;
$$;

revoke all on function public.create_gift_reservation(text,text,jsonb) from public;
grant execute on function public.create_gift_reservation(text,text,jsonb) to anon, authenticated;

-- Only authenticated admins can change reservation status.
create or replace function public.set_gift_reservation_status(
  p_reservation_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_line record;
  v_old_status text;
begin
  if not public.is_gift_admin() then
    raise exception 'Acesso não autorizado.';
  end if;
  if p_status not in ('received','cancelled','reserved') then
    raise exception 'Status inválido.';
  end if;

  select status into v_old_status from public.gift_reservations
    where id = p_reservation_id for update;

  if not found then raise exception 'Reserva não encontrada.'; end if;
  if v_old_status = 'cancelled' and p_status <> 'cancelled' then
    raise exception 'Uma reserva cancelada não pode ser reativada; crie uma nova reserva.';
  end if;

  if p_status = 'cancelled' and v_old_status <> 'cancelled' then
    for v_line in
      select gift_item_id, quantity
      from public.gift_reservation_items
      where reservation_id = p_reservation_id
    loop
      update public.gift_items
        set stock_reserved = greatest(0, stock_reserved - v_line.quantity)
        where id = v_line.gift_item_id;
    end loop;
  end if;

  update public.gift_reservations
    set status = p_status, updated_at = now()
    where id = p_reservation_id;
end;
$$;

revoke all on function public.set_gift_reservation_status(uuid,text) from public;
grant execute on function public.set_gift_reservation_status(uuid,text) to authenticated;

-- Realtime for the parents' dashboard.
do $$
begin
  alter publication supabase_realtime add table public.gift_reservations;
exception when duplicate_object then null;
when undefined_object then null;
end $$;

-- After creating the parents' account in Supabase Auth, grant admin access:
-- insert into public.admin_users(user_id)
-- select id from auth.users where email = 'EMAIL_DOS_PAPAIS';
