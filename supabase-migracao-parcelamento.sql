-- Suporte a pagamentos parcelados
alter table financas add column if not exists parcela_numero integer default 1;
alter table financas add column if not exists parcela_total integer default 1;
alter table financas add column if not exists grupo_parcelamento uuid;

-- Ajusta status antigos (do fluxo anterior, só Pré Reserva/Confirmado) para
-- continuarem válidos no novo esquema de status.
update demandas set status = 'pre_reserva' where status not in ('pre_reserva', 'confirmado', 'aguardando_pagamento', 'concluido');
