-- Setup completo do banco para o painel da Pâmela Mees Penteados
-- Rode este script inteiro de uma vez, no SQL Editor de um projeto Supabase NOVO.

-- Tabela de atendimentos
create table demandas (
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

-- Tabela financeira (a receber / concluídos)
create table financas (
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
  parcela_numero integer default 1,
  parcela_total integer default 1,
  grupo_parcelamento uuid,
  created_at timestamptz not null default now()
);

-- Tabela de gastos (ligados a um serviço)
create table gastos (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) default auth.uid(),
  projeto text not null,
  cliente text not null,
  descricao text not null,
  valor numeric not null default 0,
  data date not null,
  created_at timestamptz not null default now()
);

-- Tabela de backup diário
create table agenda_backups (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) default auth.uid(),
  data_referencia date not null,
  dados jsonb not null,
  atualizado_em timestamptz not null default now(),
  unique (user_id, data_referencia)
);

-- Segurança: cada usuário só vê e mexe nos próprios dados
alter table demandas enable row level security;
alter table financas enable row level security;
alter table gastos enable row level security;
alter table agenda_backups enable row level security;

create policy "cada usuario ve so seus dados - demandas" on demandas
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "cada usuario ve so seus dados - financas" on financas
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "cada usuario ve so seus dados - gastos" on gastos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "cada usuario ve so seus backups" on agenda_backups
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Sincronização em tempo real entre aparelhos
alter publication supabase_realtime add table demandas;
alter publication supabase_realtime add table financas;
alter publication supabase_realtime add table gastos;
