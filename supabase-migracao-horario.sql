-- Adiciona horário do atendimento, e atualiza status existentes para o novo
-- fluxo (Pré Reserva / Confirmado). Rode se o banco já existia antes.
alter table demandas add column if not exists horario time;

-- Ajusta quaisquer status antigos (do fluxo anterior) para o novo padrão
update demandas set status = 'pre_reserva' where status not in ('pre_reserva', 'confirmado');
