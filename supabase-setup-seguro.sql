-- Versão segura do setup: pode rodar quantas vezes quiser, sem erro.

create table if not exists demandas (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) default auth.uid(),
  cliente text not null,
  projeto text not null,
  etapa text not null,
  prazo date not null,
  horario time,
  status text not null,
  data_gravacao date,
  datas_gravacao date[] default '{}',
  descricao text default '',
  endereco text default '',
  no_estudio boolean default false,
  quantidade_pessoas integer default 1,
  valor numeric not null default 0,
  com_nf boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists financas (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) default auth.uid(),
  cliente text not null,
  projeto text not null,
  valor numeric not null default 0,
  valor_bruto numeric,
  com_nf boolean not null default false,
  data_trabalho date not null,
  data_pagamento date not null,
  pago boolean not null default false,
  origem_demanda_id bigint references demandas(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists gastos (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) default auth.uid(),
  projeto text not null,
  cliente text not null,
  descricao text not null,
  valor numeric not null default 0,
  data date not null,
  created_at timestamptz not null default now()
);

create table if not exists agenda_backups (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) default auth.uid(),
  data_referencia date not null,
  dados jsonb not null,
  atualizado_em timestamptz not null default now(),
  unique (user_id, data_referencia)
);

-- Caso as tabelas já existissem sem essas colunas (de uma tentativa anterior)
alter table demandas add column if not exists horario time;
alter table demandas add column if not exists descricao text default '';
alter table demandas add column if not exists endereco text default '';
alter table demandas add column if not exists no_estudio boolean default false;
alter table demandas add column if not exists quantidade_pessoas integer default 1;
alter table demandas add column if not exists datas_gravacao date[] default '{}';

alter table demandas enable row level security;
alter table financas enable row level security;
alter table gastos enable row level security;
alter table agenda_backups enable row level security;

drop policy if exists "cada usuario ve so seus dados - demandas" on demandas;
create policy "cada usuario ve so seus dados - demandas" on demandas
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "cada usuario ve so seus dados - financas" on financas;
create policy "cada usuario ve so seus dados - financas" on financas
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "cada usuario ve so seus dados - gastos" on gastos;
create policy "cada usuario ve so seus dados - gastos" on gastos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "cada usuario ve so seus backups" on agenda_backups;
create policy "cada usuario ve so seus backups" on agenda_backups
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

do $$
begin
  alter publication supabase_realtime add table demandas;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table financas;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table gastos;
exception when duplicate_object then null;
end $$;
