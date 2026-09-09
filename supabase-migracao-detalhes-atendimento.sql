-- Adiciona endereço, opção de estúdio próprio e quantidade de pessoas atendidas
alter table demandas add column if not exists endereco text default '';
alter table demandas add column if not exists no_estudio boolean default false;
alter table demandas add column if not exists quantidade_pessoas integer default 1;
