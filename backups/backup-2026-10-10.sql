--
-- PostgreSQL database dump
--

\restrict 7Y1r2jeFqkI1eTDOh3E4rKZU90D9VvNVHH6rUcP7P00jBscahnSm2VSSaRiMc2x

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.11 (Ubuntu 17.11-1.pgdg24.04+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: fazer_backup_diario(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fazer_backup_diario() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  hoje date := (now() at time zone 'America/Sao_Paulo')::date;
begin
  insert into agenda_backups (user_id, data_referencia, dados, atualizado_em)
  select
    u.user_id,
    hoje,
    jsonb_build_object(
      'versao', 2,
      'geradoEm', now(),
      'demandas', coalesce((select jsonb_agg(to_jsonb(d) order by d.id) from demandas d where d.user_id = u.user_id), '[]'::jsonb),
      'financas', coalesce((select jsonb_agg(to_jsonb(f) order by f.id) from financas f where f.user_id = u.user_id), '[]'::jsonb),
      'gastos',   coalesce((select jsonb_agg(to_jsonb(g) order by g.id) from gastos g   where g.user_id = u.user_id), '[]'::jsonb)
    ),
    now()
  from (
    select user_id from demandas
    union select user_id from financas
    union select user_id from gastos
  ) u
  where u.user_id is not null
  on conflict (user_id, data_referencia)
  do update set dados = excluded.dados, atualizado_em = now();

  delete from agenda_backups where data_referencia < hoje - 60;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agenda_backups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agenda_backups (
    id bigint NOT NULL,
    user_id uuid DEFAULT auth.uid(),
    data_referencia date NOT NULL,
    dados jsonb NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: agenda_backups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.agenda_backups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.agenda_backups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: backup_emails_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.backup_emails_log (
    id bigint NOT NULL,
    user_id uuid,
    enviado_em timestamp with time zone DEFAULT now() NOT NULL,
    destino text,
    sucesso boolean DEFAULT false NOT NULL,
    detalhe text
);


--
-- Name: backup_emails_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.backup_emails_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.backup_emails_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: demandas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.demandas (
    id bigint NOT NULL,
    user_id uuid DEFAULT auth.uid(),
    cliente text NOT NULL,
    projeto text NOT NULL,
    etapa text NOT NULL,
    prazo date NOT NULL,
    status text NOT NULL,
    data_gravacao date,
    datas_gravacao date[] DEFAULT '{}'::date[],
    descricao text DEFAULT ''::text,
    valor numeric DEFAULT 0 NOT NULL,
    com_nf boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    endereco text DEFAULT ''::text,
    no_estudio boolean DEFAULT false,
    quantidade_pessoas integer DEFAULT 1,
    horario time without time zone,
    horario_termino time without time zone,
    valor_deslocamento numeric DEFAULT 0 NOT NULL,
    contrato_path text,
    contrato_nome text,
    contrato_tipo text,
    dias_concluidos date[] DEFAULT '{}'::date[]
);


--
-- Name: demandas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.demandas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.demandas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: financas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.financas (
    id bigint NOT NULL,
    user_id uuid DEFAULT auth.uid(),
    cliente text NOT NULL,
    projeto text NOT NULL,
    valor numeric DEFAULT 0 NOT NULL,
    valor_bruto numeric,
    com_nf boolean DEFAULT false NOT NULL,
    data_trabalho date NOT NULL,
    data_pagamento date NOT NULL,
    pago boolean DEFAULT false NOT NULL,
    origem_demanda_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    parcela_numero integer DEFAULT 1,
    parcela_total integer DEFAULT 1,
    grupo_parcelamento uuid,
    e_sinal boolean DEFAULT false NOT NULL
);


--
-- Name: financas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.financas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.financas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: gastos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gastos (
    id bigint NOT NULL,
    user_id uuid DEFAULT auth.uid(),
    projeto text NOT NULL,
    cliente text NOT NULL,
    descricao text NOT NULL,
    valor numeric DEFAULT 0 NOT NULL,
    data date NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    origem_demanda_id bigint,
    extra_tipo text,
    extra_nome text
);


--
-- Name: gastos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.gastos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.gastos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: agenda_backups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agenda_backups (id, user_id, data_referencia, dados, atualizado_em) FROM stdin;
1	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-05	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-06T02:38:57.466Z"}	2026-09-05 23:10:13.173448+00
83	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-07	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-08T02:22:06.862Z"}	2026-09-07 03:33:24.431133+00
188	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-10-05	{"gastos": [], "demandas": [{"id": 1, "comNF": false, "etapa": "Finalizado", "prazo": "2026-10-05", "valor": 280, "status": "aguardando_pagamento", "cliente": "1 Penteado ", "horario": "14:30:00", "projeto": "Penteado Social", "endereco": "", "descricao": "", "noEstudio": false, "dataGravacao": null, "datasGravacao": [], "quantidadePessoas": 1}, {"id": 3, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-06", "valor": 480, "status": "confirmado", "cliente": "2 clientes Mayra ", "horario": "14:00:00", "projeto": "Penteado Social", "endereco": "Rua Gonçalves Dias, 30 – Funcionários", "descricao": "Precisam estar prontas até 19h Maquiagem 210,00\\nPenteado 200,00 \\nDeslocamento 80,00", "noEstudio": false, "dataGravacao": null, "datasGravacao": ["2026-10-06"], "quantidadePessoas": 2}, {"id": 2, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-07", "valor": 1480, "status": "confirmado", "cliente": "Noiva Djeice", "horario": "10:00:00", "projeto": "Noiva", "endereco": "Av Otacílio Negrão de Lima 7180", "descricao": "Noiva mais mãe e ", "noEstudio": false, "dataGravacao": null, "datasGravacao": ["2026-10-07"], "quantidadePessoas": 2}], "financas": [], "geradoEm": "2026-10-06T01:04:50.204Z"}	2026-10-06 00:49:07.364836+00
161	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-09	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-09T21:05:28.079Z"}	2026-09-09 03:43:44.425257+00
182	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-20	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-21T01:44:05.110Z"}	2026-09-21 00:54:28.522397+00
184	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-09-20	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-21T01:46:43.093Z"}	2026-09-21 01:44:19.568013+00
187	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-09-21	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-21T14:26:28.472Z"}	2026-09-21 14:26:28.774329+00
131	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-08	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-08T22:47:12.742Z"}	2026-09-08 03:20:38.047247+00
45	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-06	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-07T00:59:54.321Z"}	2026-09-06 03:11:58.592647+00
201	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-10-06	{"gastos": [], "demandas": [{"id": 3, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-06", "valor": 480, "status": "confirmado", "cliente": "2 clientes Mayra ", "horario": "14:00:00", "projeto": "Penteado Social", "endereco": "Rua Gonçalves Dias, 30 – Funcionários", "descricao": "Precisam estar prontas até 19h Maquiagem 210,00\\nPenteado 200,00 \\nDeslocamento 80,00", "noEstudio": false, "dataGravacao": null, "datasGravacao": ["2026-10-06"], "quantidadePessoas": 2}, {"id": 2, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-07", "valor": 1480, "status": "confirmado", "cliente": "Noiva Djeice", "horario": "10:00:00", "projeto": "Noiva", "endereco": "Av Otacílio Negrão de Lima 7180", "descricao": "Noiva mais mãe e ", "noEstudio": false, "dataGravacao": null, "datasGravacao": ["2026-10-07"], "quantidadePessoas": 2}], "financas": [], "geradoEm": "2026-10-06T23:33:45.352Z"}	2026-10-06 23:15:16.184616+00
204	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-10-07	{"gastos": [], "demandas": [{"id": 3, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-06", "valor": 480, "status": "aguardando_pagamento", "cliente": "2 clientes Mayra ", "horario": "14:00:00", "projeto": "Penteado Social", "endereco": "Rua Gonçalves Dias, 30 – Funcionários", "descricao": "Precisam estar prontas até 19h Maquiagem 210,00\\nPenteado 200,00 \\nDeslocamento 80,00", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-06"], "diasConcluidos": [], "horarioTermino": "", "quantidadePessoas": 2, "valorDeslocamento": 0}, {"id": 2, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-07", "valor": 1480, "status": "confirmado", "cliente": "Noiva Djeice", "horario": "10:00:00", "projeto": "Noiva", "endereco": "Av Otacílio Negrão de Lima 7180", "descricao": "Noiva mais mãe e ", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-07"], "diasConcluidos": ["2026-10-07"], "horarioTermino": "", "quantidadePessoas": 2, "valorDeslocamento": 0}], "financas": [{"id": 1, "pago": false, "comNF": false, "valor": 1480, "cliente": "Noiva Djeice", "projeto": "Noiva", "valorBruto": 1480, "dataTrabalho": "2026-10-07", "parcelaTotal": 1, "dataPagamento": "2026-09-19", "parcelaNumero": 1, "origemDemandaId": 2, "grupoParcelamento": null}], "geradoEm": "2026-10-08T02:57:55.927Z"}	2026-10-08 00:52:24.074856+00
252	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-10-08	{"gastos": [], "demandas": [{"id": 3, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-06", "valor": 480, "status": "aguardando_pagamento", "cliente": "2 clientes Mayra ", "horario": "14:00:00", "projeto": "Penteado Social", "endereco": "Rua Gonçalves Dias, 30 – Funcionários", "descricao": "Precisam estar prontas até 19h Maquiagem 210,00\\nPenteado 200,00 \\nDeslocamento 80,00", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-06"], "diasConcluidos": [], "horarioTermino": "", "quantidadePessoas": 2, "valorDeslocamento": 0}, {"id": 2, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-07", "valor": 1480, "status": "aguardando_pagamento", "cliente": "Noiva Djeice", "horario": "10:00:00", "projeto": "Noiva", "endereco": "Av Otacílio Negrão de Lima 7180", "descricao": "Noiva mais mãe e ", "noEstudio": false, "contratoNome": "contrato_noiva_Djeice_Kellem_assinado.pdf", "contratoPath": "4c9add6f-2949-4539-8980-1ac9f840ff8e/2-1791430684871-contrato_noiva_Djeice_Kellem_assinado.pdf", "contratoTipo": "application/pdf", "dataGravacao": null, "datasGravacao": ["2026-10-07"], "diasConcluidos": ["2026-10-07"], "horarioTermino": "", "quantidadePessoas": 2, "valorDeslocamento": 0}, {"id": 7, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "confirmado", "cliente": "Emanuelle ", "horario": "13:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "14:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 8, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "pre_reserva", "cliente": "Glaucia ", "horario": "14:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "15:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 9, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "confirmado", "cliente": "Penteado com bel", "horario": "17:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "18:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 5, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "confirmado", "cliente": "Leticia jordana ", "horario": "07:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "08:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 6, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "confirmado", "cliente": "Joice", "horario": "12:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "13:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 11, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "status": "confirmado", "cliente": "Aline souto", "horario": "11:30:00", "projeto": "Penteado Social", "endereco": "Rua Coronel Leri Santos, n 107. Apto 402. Bairro Planalto", "descricao": "Com Débora paisano ", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-11"], "diasConcluidos": [], "horarioTermino": "12:30:00", "quantidadePessoas": 1, "valorDeslocamento": 80}, {"id": 18, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "status": "confirmado", "cliente": "Ana Paula", "horario": "13:30:00", "projeto": "Penteado Social", "endereco": "Hilton Garden Inn Belo Horizonte", "descricao": "Com Débora paisano ", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-11"], "diasConcluidos": [], "horarioTermino": "14:30:00", "quantidadePessoas": 1, "valorDeslocamento": 70}, {"id": 10, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "status": "confirmado", "cliente": "Emanuelle Mota", "horario": "09:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-11"], "diasConcluidos": [], "horarioTermino": "10:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 26, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-16", "valor": 200, "status": "confirmado", "cliente": "Penteado com bel ", "horario": "16:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-16"], "diasConcluidos": [], "horarioTermino": "17:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 29, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 200, "status": "confirmado", "cliente": "Beatriz ", "horario": "18:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-17"], "diasConcluidos": [], "horarioTermino": "19:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 28, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 800, "status": "confirmado", "cliente": "4 penteado com bel Igarapé ", "horario": "09:30:00", "projeto": "Penteado Social", "endereco": "Igarapé ", "descricao": "", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-17"], "diasConcluidos": [], "horarioTermino": "16:30:00", "quantidadePessoas": 5, "valorDeslocamento": 200}, {"id": 27, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 200, "status": "confirmado", "cliente": "Penteado com bel ", "horario": "06:30:00", "projeto": "Penteado Social", "endereco": "", "descricao": "", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-17"], "diasConcluidos": [], "horarioTermino": "07:30:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 30, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-18", "valor": 1000, "status": "confirmado", "cliente": "5 penteados com iara", "horario": "07:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "5 penteafos na Iara ", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-18"], "diasConcluidos": [], "horarioTermino": "12:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 31, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-24", "valor": 200, "status": "pre_reserva", "cliente": "Sabrina ", "horario": "13:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-24"], "diasConcluidos": [], "horarioTermino": "14:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 32, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-24", "valor": 200, "status": "confirmado", "cliente": "Ana ", "horario": "14:30:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-24"], "diasConcluidos": [], "horarioTermino": "15:30:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 33, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-24", "valor": 200, "status": "confirmado", "cliente": "Ana ", "horario": "14:30:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-24"], "diasConcluidos": [], "horarioTermino": "15:30:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 34, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-28", "valor": 200, "status": "confirmado", "cliente": "Carol - civil", "horario": "06:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Noiva civil com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-28"], "diasConcluidos": [], "horarioTermino": "07:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}], "financas": [{"id": 30, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Emanuelle Mota", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-11", "parcelaTotal": 2, "dataPagamento": "2026-09-07", "parcelaNumero": 1, "origemDemandaId": 10, "grupoParcelamento": "a067c6b9-54f1-4b76-a01b-3f0958dd79b9"}, {"id": 80, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Carol - civil", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-28", "parcelaTotal": 2, "dataPagamento": "2026-09-13", "parcelaNumero": 1, "origemDemandaId": 34, "grupoParcelamento": "cc9c95a7-7543-4a1b-bcd0-849cf5049c52"}, {"id": 28, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Penteado com bel", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-09-15", "parcelaNumero": 1, "origemDemandaId": 9, "grupoParcelamento": "c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc"}, {"id": 76, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Ana ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-24", "parcelaTotal": 2, "dataPagamento": "2026-09-16", "parcelaNumero": 1, "origemDemandaId": 33, "grupoParcelamento": "8cd64e45-a73d-483b-a112-7da443bea12a"}, {"id": 23, "pago": true, "comNF": false, "valor": 1480, "eSinal": false, "cliente": "Noiva Djeice", "projeto": "Noiva", "valorBruto": 1480, "dataTrabalho": "2026-10-07", "parcelaTotal": 1, "dataPagamento": "2026-09-19", "parcelaNumero": 1, "origemDemandaId": 2, "grupoParcelamento": null}, {"id": 74, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Sabrina ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-24", "parcelaTotal": 2, "dataPagamento": "2026-09-21", "parcelaNumero": 1, "origemDemandaId": 31, "grupoParcelamento": "81c44ead-e411-441c-8a14-ccab09afdfd9"}, {"id": 71, "pago": true, "comNF": false, "valor": 200, "eSinal": true, "cliente": "4 penteado com bel Igarapé ", "projeto": "Penteado Social", "valorBruto": 200, "dataTrabalho": "2026-10-17", "parcelaTotal": 2, "dataPagamento": "2026-09-22", "parcelaNumero": 1, "origemDemandaId": 28, "grupoParcelamento": "04939b8e-b128-44ba-a664-b04522f82090"}, {"id": 65, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Penteado com bel ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-17", "parcelaTotal": 2, "dataPagamento": "2026-09-23", "parcelaNumero": 1, "origemDemandaId": 27, "grupoParcelamento": "530b89e7-284d-415c-9bcc-4f88beeb4332"}, {"id": 69, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Beatriz ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-17", "parcelaTotal": 2, "dataPagamento": "2026-09-23", "parcelaNumero": 1, "origemDemandaId": 29, "grupoParcelamento": "0a0fe7f9-af5a-4550-8358-5572e33eecd3"}, {"id": 63, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Penteado com bel ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-16", "parcelaTotal": 2, "dataPagamento": "2026-09-23", "parcelaNumero": 1, "origemDemandaId": 26, "grupoParcelamento": "5a0065b4-6f3a-40a6-a0a1-0f14de05eb19"}, {"id": 32, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Aline souto", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-11", "parcelaTotal": 2, "dataPagamento": "2026-09-30", "parcelaNumero": 1, "origemDemandaId": 11, "grupoParcelamento": "cd7dfaf3-802e-4bbd-9833-1497f7d76756"}, {"id": 20, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Emanuelle ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-06", "parcelaNumero": 1, "origemDemandaId": 7, "grupoParcelamento": "d0926d6d-8927-4e50-9a48-02fe79d2f853"}, {"id": 9, "pago": true, "comNF": false, "valor": 50, "eSinal": false, "cliente": "Leticia jordana ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-06", "parcelaNumero": 1, "origemDemandaId": 5, "grupoParcelamento": "b8518c22-8dd8-4cde-a33e-12b292f664c7"}, {"id": 83, "pago": true, "comNF": false, "valor": 780, "eSinal": false, "cliente": "3 clientes Mayra ", "projeto": "Penteado Social", "valorBruto": 780, "dataTrabalho": "2026-10-06", "parcelaTotal": 1, "dataPagamento": "2026-10-07", "parcelaNumero": 1, "origemDemandaId": 3, "grupoParcelamento": null}, {"id": 24, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Glaucia ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-07", "parcelaNumero": 1, "origemDemandaId": 8, "grupoParcelamento": "57505cda-4fd4-4cd4-a4a2-2a029ff3bd89"}, {"id": 25, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Glaucia ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-08", "parcelaNumero": 2, "origemDemandaId": 8, "grupoParcelamento": "57505cda-4fd4-4cd4-a4a2-2a029ff3bd89"}, {"id": 18, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Joice", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-08", "parcelaNumero": 1, "origemDemandaId": 6, "grupoParcelamento": "d427bf7e-6389-4439-a247-702414d51391"}, {"id": 21, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Emanuelle ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-10", "parcelaNumero": 2, "origemDemandaId": 7, "grupoParcelamento": "d0926d6d-8927-4e50-9a48-02fe79d2f853"}, {"id": 29, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Penteado com bel", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-10", "parcelaNumero": 2, "origemDemandaId": 9, "grupoParcelamento": "c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc"}, {"id": 10, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Leticia jordana ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-10", "parcelaNumero": 2, "origemDemandaId": 5, "grupoParcelamento": "b8518c22-8dd8-4cde-a33e-12b292f664c7"}, {"id": 19, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Joice", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-10", "parcelaNumero": 2, "origemDemandaId": 6, "grupoParcelamento": "d427bf7e-6389-4439-a247-702414d51391"}, {"id": 31, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Emanuelle Mota", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-11", "parcelaTotal": 2, "dataPagamento": "2026-10-11", "parcelaNumero": 2, "origemDemandaId": 10, "grupoParcelamento": "a067c6b9-54f1-4b76-a01b-3f0958dd79b9"}, {"id": 33, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Aline souto", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-11", "parcelaTotal": 2, "dataPagamento": "2026-10-11", "parcelaNumero": 2, "origemDemandaId": 11, "grupoParcelamento": "cd7dfaf3-802e-4bbd-9833-1497f7d76756"}, {"id": 62, "pago": false, "comNF": false, "valor": 200, "eSinal": false, "cliente": "Ana Paula", "projeto": "Penteado Social", "valorBruto": 200, "dataTrabalho": "2026-10-11", "parcelaTotal": 1, "dataPagamento": "2026-10-11", "parcelaNumero": 1, "origemDemandaId": 18, "grupoParcelamento": null}, {"id": 64, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Penteado com bel ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-16", "parcelaTotal": 2, "dataPagamento": "2026-10-16", "parcelaNumero": 2, "origemDemandaId": 26, "grupoParcelamento": "5a0065b4-6f3a-40a6-a0a1-0f14de05eb19"}, {"id": 70, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Beatriz ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-17", "parcelaTotal": 2, "dataPagamento": "2026-10-17", "parcelaNumero": 2, "origemDemandaId": 29, "grupoParcelamento": "0a0fe7f9-af5a-4550-8358-5572e33eecd3"}, {"id": 72, "pago": false, "comNF": false, "valor": 600, "eSinal": false, "cliente": "4 penteado com bel Igarapé ", "projeto": "Penteado Social", "valorBruto": 600, "dataTrabalho": "2026-10-17", "parcelaTotal": 2, "dataPagamento": "2026-10-17", "parcelaNumero": 2, "origemDemandaId": 28, "grupoParcelamento": "04939b8e-b128-44ba-a664-b04522f82090"}, {"id": 66, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Penteado com bel ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-17", "parcelaTotal": 2, "dataPagamento": "2026-10-17", "parcelaNumero": 2, "origemDemandaId": 27, "grupoParcelamento": "530b89e7-284d-415c-9bcc-4f88beeb4332"}, {"id": 73, "pago": false, "comNF": false, "valor": 1000, "eSinal": false, "cliente": "5 penteados com iara", "projeto": "Penteado Social", "valorBruto": 1000, "dataTrabalho": "2026-10-18", "parcelaTotal": 1, "dataPagamento": "2026-10-18", "parcelaNumero": 1, "origemDemandaId": 30, "grupoParcelamento": null}, {"id": 77, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Ana ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-24", "parcelaTotal": 2, "dataPagamento": "2026-10-24", "parcelaNumero": 2, "origemDemandaId": 33, "grupoParcelamento": "8cd64e45-a73d-483b-a112-7da443bea12a"}, {"id": 75, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Sabrina ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-24", "parcelaTotal": 2, "dataPagamento": "2026-10-24", "parcelaNumero": 2, "origemDemandaId": 31, "grupoParcelamento": "81c44ead-e411-441c-8a14-ccab09afdfd9"}, {"id": 81, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Carol - civil", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-28", "parcelaTotal": 2, "dataPagamento": "2026-10-28", "parcelaNumero": 2, "origemDemandaId": 34, "grupoParcelamento": "cc9c95a7-7543-4a1b-bcd0-849cf5049c52"}], "geradoEm": "2026-10-08T22:01:38.859Z"}	2026-10-08 04:11:51.315114+00
338	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-10-09	{"gastos": [], "versao": 2, "demandas": [{"id": 2, "etapa": "Atendimento", "prazo": "2026-10-07", "valor": 1480, "com_nf": false, "status": "concluido", "cliente": "Noiva Djeice", "horario": "10:00:00", "projeto": "Noiva", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Av Otacílio Negrão de Lima 7180", "descricao": "Noiva mais mãe e ", "created_at": "2026-10-06T00:55:16.948742+00:00", "no_estudio": false, "contrato_nome": "contrato_noiva_Djeice_Kellem_assinado.pdf", "contrato_path": "4c9add6f-2949-4539-8980-1ac9f840ff8e/2-1791430684871-contrato_noiva_Djeice_Kellem_assinado.pdf", "contrato_tipo": "application/pdf", "data_gravacao": null, "datas_gravacao": ["2026-10-07"], "dias_concluidos": ["2026-10-07"], "horario_termino": null, "quantidade_pessoas": 2, "valor_deslocamento": 0}, {"id": 3, "etapa": "Atendimento", "prazo": "2026-10-06", "valor": 480, "com_nf": false, "status": "concluido", "cliente": "2 clientes Mayra ", "horario": "14:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Rua Gonçalves Dias, 30 – Funcionários", "descricao": "Precisam estar prontas até 19h Maquiagem 210,00\\nPenteado 200,00 \\nDeslocamento 80,00", "created_at": "2026-10-06T01:03:39.41186+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-06"], "dias_concluidos": [], "horario_termino": null, "quantidade_pessoas": 2, "valor_deslocamento": 0}, {"id": 5, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Leticia jordana ", "horario": "07:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "", "created_at": "2026-10-08T03:03:53.949799+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "08:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 6, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Joice", "horario": "12:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel", "created_at": "2026-10-08T03:25:20.441992+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "13:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 7, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Emanuelle ", "horario": "13:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T03:32:58.329759+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "14:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 8, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "pre_reserva", "cliente": "Glaucia ", "horario": "14:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T03:41:00.208497+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "15:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 9, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Penteado com bel", "horario": "17:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel", "created_at": "2026-10-08T03:42:39.785801+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "18:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 10, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Emanuelle Mota", "horario": "09:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T03:44:44.869025+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-11"], "dias_concluidos": [], "horario_termino": "10:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 11, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Aline souto", "horario": "11:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Rua Coronel Leri Santos, n 107. Apto 402. Bairro Planalto", "descricao": "Com Débora paisano ", "created_at": "2026-10-08T03:48:35.073926+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-11"], "dias_concluidos": [], "horario_termino": "12:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 80}, {"id": 18, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Ana Paula", "horario": "13:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Hilton Garden Inn Belo Horizonte", "descricao": "Com Débora paisano ", "created_at": "2026-10-08T03:57:18.805791+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-11"], "dias_concluidos": [], "horario_termino": "14:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 70}, {"id": 26, "etapa": "Atendimento", "prazo": "2026-10-16", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Penteado com bel ", "horario": "16:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "", "created_at": "2026-10-08T11:07:56.908023+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-16"], "dias_concluidos": [], "horario_termino": "17:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 27, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Penteado com bel ", "horario": "06:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "", "created_at": "2026-10-08T11:09:28.207616+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-17"], "dias_concluidos": [], "horario_termino": "07:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 28, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 800, "com_nf": false, "status": "confirmado", "cliente": "4 penteado com bel Igarapé ", "horario": "09:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Igarapé ", "descricao": "", "created_at": "2026-10-08T11:14:43.727009+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-17"], "dias_concluidos": [], "horario_termino": "16:30:00", "quantidade_pessoas": 5, "valor_deslocamento": 200}, {"id": 29, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Beatriz ", "horario": "18:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T11:16:28.849472+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-17"], "dias_concluidos": [], "horario_termino": "19:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 30, "etapa": "Atendimento", "prazo": "2026-10-18", "valor": 1000, "com_nf": false, "status": "confirmado", "cliente": "5 penteados com iara", "horario": "07:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "5 penteafos na Iara ", "created_at": "2026-10-08T11:22:34.075904+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-18"], "dias_concluidos": [], "horario_termino": "12:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 31, "etapa": "Atendimento", "prazo": "2026-10-24", "valor": 200, "com_nf": false, "status": "pre_reserva", "cliente": "Sabrina ", "horario": "13:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T11:23:37.644332+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-24"], "dias_concluidos": [], "horario_termino": "14:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 32, "etapa": "Atendimento", "prazo": "2026-10-24", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Ana ", "horario": "14:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T11:24:40.442469+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-24"], "dias_concluidos": [], "horario_termino": "15:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 33, "etapa": "Atendimento", "prazo": "2026-10-24", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Ana ", "horario": "14:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T11:24:41.196989+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-24"], "dias_concluidos": [], "horario_termino": "15:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 34, "etapa": "Atendimento", "prazo": "2026-10-28", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Carol - civil", "horario": "06:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Noiva civil com bel ", "created_at": "2026-10-08T11:29:44.081756+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-28"], "dias_concluidos": [], "horario_termino": "07:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}], "financas": [{"id": 9, "pago": true, "valor": 50, "com_nf": false, "cliente": "Leticia jordana ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:03:54.332505+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-06", "parcela_numero": 1, "origem_demanda_id": 5, "grupo_parcelamento": "b8518c22-8dd8-4cde-a33e-12b292f664c7"}, {"id": 10, "pago": false, "valor": 150, "com_nf": false, "cliente": "Leticia jordana ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:03:54.332505+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-10", "parcela_numero": 2, "origem_demanda_id": 5, "grupo_parcelamento": "b8518c22-8dd8-4cde-a33e-12b292f664c7"}, {"id": 18, "pago": true, "valor": 50, "com_nf": false, "cliente": "Joice", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:31:13.069802+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-08", "parcela_numero": 1, "origem_demanda_id": 6, "grupo_parcelamento": "d427bf7e-6389-4439-a247-702414d51391"}, {"id": 19, "pago": false, "valor": 150, "com_nf": false, "cliente": "Joice", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:31:13.069802+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-10", "parcela_numero": 2, "origem_demanda_id": 6, "grupo_parcelamento": "d427bf7e-6389-4439-a247-702414d51391"}, {"id": 20, "pago": true, "valor": 50, "com_nf": false, "cliente": "Emanuelle ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:32:58.581118+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-06", "parcela_numero": 1, "origem_demanda_id": 7, "grupo_parcelamento": "d0926d6d-8927-4e50-9a48-02fe79d2f853"}, {"id": 21, "pago": false, "valor": 150, "com_nf": false, "cliente": "Emanuelle ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:32:58.581118+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-10", "parcela_numero": 2, "origem_demanda_id": 7, "grupo_parcelamento": "d0926d6d-8927-4e50-9a48-02fe79d2f853"}, {"id": 23, "pago": true, "valor": 1480, "com_nf": false, "cliente": "Noiva Djeice", "e_sinal": false, "projeto": "Noiva", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:38:06.012894+00:00", "valor_bruto": 1480, "data_trabalho": "2026-10-07", "parcela_total": 1, "data_pagamento": "2026-09-19", "parcela_numero": 1, "origem_demanda_id": 2, "grupo_parcelamento": null}, {"id": 24, "pago": true, "valor": 50, "com_nf": false, "cliente": "Glaucia ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:41:00.5384+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-07", "parcela_numero": 1, "origem_demanda_id": 8, "grupo_parcelamento": "57505cda-4fd4-4cd4-a4a2-2a029ff3bd89"}, {"id": 25, "pago": false, "valor": 150, "com_nf": false, "cliente": "Glaucia ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:41:00.5384+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-08", "parcela_numero": 2, "origem_demanda_id": 8, "grupo_parcelamento": "57505cda-4fd4-4cd4-a4a2-2a029ff3bd89"}, {"id": 28, "pago": true, "valor": 50, "com_nf": false, "cliente": "Penteado com bel", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:43:01.408711+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-09-15", "parcela_numero": 1, "origem_demanda_id": 9, "grupo_parcelamento": "c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc"}, {"id": 29, "pago": false, "valor": 150, "com_nf": false, "cliente": "Penteado com bel", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:43:01.408711+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-10", "parcela_numero": 2, "origem_demanda_id": 9, "grupo_parcelamento": "c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc"}, {"id": 30, "pago": true, "valor": 50, "com_nf": false, "cliente": "Emanuelle Mota", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:44:45.672275+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-11", "parcela_total": 2, "data_pagamento": "2026-09-07", "parcela_numero": 1, "origem_demanda_id": 10, "grupo_parcelamento": "a067c6b9-54f1-4b76-a01b-3f0958dd79b9"}, {"id": 31, "pago": false, "valor": 150, "com_nf": false, "cliente": "Emanuelle Mota", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:44:45.672275+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-11", "parcela_total": 2, "data_pagamento": "2026-10-11", "parcela_numero": 2, "origem_demanda_id": 10, "grupo_parcelamento": "a067c6b9-54f1-4b76-a01b-3f0958dd79b9"}, {"id": 32, "pago": true, "valor": 50, "com_nf": false, "cliente": "Aline souto", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:48:35.312252+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-11", "parcela_total": 2, "data_pagamento": "2026-09-30", "parcela_numero": 1, "origem_demanda_id": 11, "grupo_parcelamento": "cd7dfaf3-802e-4bbd-9833-1497f7d76756"}, {"id": 33, "pago": false, "valor": 150, "com_nf": false, "cliente": "Aline souto", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:48:35.312252+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-11", "parcela_total": 2, "data_pagamento": "2026-10-11", "parcela_numero": 2, "origem_demanda_id": 11, "grupo_parcelamento": "cd7dfaf3-802e-4bbd-9833-1497f7d76756"}, {"id": 62, "pago": false, "valor": 200, "com_nf": false, "cliente": "Ana Paula", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T04:03:37.897808+00:00", "valor_bruto": 200, "data_trabalho": "2026-10-11", "parcela_total": 1, "data_pagamento": "2026-10-11", "parcela_numero": 1, "origem_demanda_id": 18, "grupo_parcelamento": null}, {"id": 63, "pago": true, "valor": 50, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:07:57.618244+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-16", "parcela_total": 2, "data_pagamento": "2026-09-23", "parcela_numero": 1, "origem_demanda_id": 26, "grupo_parcelamento": "5a0065b4-6f3a-40a6-a0a1-0f14de05eb19"}, {"id": 64, "pago": false, "valor": 150, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:07:57.618244+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-16", "parcela_total": 2, "data_pagamento": "2026-10-16", "parcela_numero": 2, "origem_demanda_id": 26, "grupo_parcelamento": "5a0065b4-6f3a-40a6-a0a1-0f14de05eb19"}, {"id": 65, "pago": true, "valor": 50, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:09:28.757193+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-09-23", "parcela_numero": 1, "origem_demanda_id": 27, "grupo_parcelamento": "530b89e7-284d-415c-9bcc-4f88beeb4332"}, {"id": 66, "pago": false, "valor": 150, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:09:28.757193+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-10-17", "parcela_numero": 2, "origem_demanda_id": 27, "grupo_parcelamento": "530b89e7-284d-415c-9bcc-4f88beeb4332"}, {"id": 69, "pago": true, "valor": 50, "com_nf": false, "cliente": "Beatriz ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:16:29.27987+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-09-23", "parcela_numero": 1, "origem_demanda_id": 29, "grupo_parcelamento": "0a0fe7f9-af5a-4550-8358-5572e33eecd3"}, {"id": 70, "pago": false, "valor": 150, "com_nf": false, "cliente": "Beatriz ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:16:29.27987+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-10-17", "parcela_numero": 2, "origem_demanda_id": 29, "grupo_parcelamento": "0a0fe7f9-af5a-4550-8358-5572e33eecd3"}, {"id": 71, "pago": true, "valor": 200, "com_nf": false, "cliente": "4 penteado com bel Igarapé ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:18:15.703929+00:00", "valor_bruto": 200, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-09-22", "parcela_numero": 1, "origem_demanda_id": 28, "grupo_parcelamento": "04939b8e-b128-44ba-a664-b04522f82090"}, {"id": 72, "pago": false, "valor": 600, "com_nf": false, "cliente": "4 penteado com bel Igarapé ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:18:15.703929+00:00", "valor_bruto": 600, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-10-17", "parcela_numero": 2, "origem_demanda_id": 28, "grupo_parcelamento": "04939b8e-b128-44ba-a664-b04522f82090"}, {"id": 73, "pago": false, "valor": 1000, "com_nf": false, "cliente": "5 penteados com iara", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:22:34.668625+00:00", "valor_bruto": 1000, "data_trabalho": "2026-10-18", "parcela_total": 1, "data_pagamento": "2026-10-18", "parcela_numero": 1, "origem_demanda_id": 30, "grupo_parcelamento": null}, {"id": 74, "pago": true, "valor": 50, "com_nf": false, "cliente": "Sabrina ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:23:38.097684+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-24", "parcela_total": 2, "data_pagamento": "2026-09-21", "parcela_numero": 1, "origem_demanda_id": 31, "grupo_parcelamento": "81c44ead-e411-441c-8a14-ccab09afdfd9"}, {"id": 75, "pago": false, "valor": 150, "com_nf": false, "cliente": "Sabrina ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:23:38.097684+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-24", "parcela_total": 2, "data_pagamento": "2026-10-24", "parcela_numero": 2, "origem_demanda_id": 31, "grupo_parcelamento": "81c44ead-e411-441c-8a14-ccab09afdfd9"}, {"id": 76, "pago": true, "valor": 50, "com_nf": false, "cliente": "Ana ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:24:41.576967+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-24", "parcela_total": 2, "data_pagamento": "2026-09-16", "parcela_numero": 1, "origem_demanda_id": 33, "grupo_parcelamento": "8cd64e45-a73d-483b-a112-7da443bea12a"}, {"id": 77, "pago": false, "valor": 150, "com_nf": false, "cliente": "Ana ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:24:41.576967+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-24", "parcela_total": 2, "data_pagamento": "2026-10-24", "parcela_numero": 2, "origem_demanda_id": 33, "grupo_parcelamento": "8cd64e45-a73d-483b-a112-7da443bea12a"}, {"id": 80, "pago": true, "valor": 50, "com_nf": false, "cliente": "Carol - civil", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:29:44.471819+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-28", "parcela_total": 2, "data_pagamento": "2026-09-13", "parcela_numero": 1, "origem_demanda_id": 34, "grupo_parcelamento": "cc9c95a7-7543-4a1b-bcd0-849cf5049c52"}, {"id": 81, "pago": false, "valor": 150, "com_nf": false, "cliente": "Carol - civil", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:29:44.471819+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-28", "parcela_total": 2, "data_pagamento": "2026-10-28", "parcela_numero": 2, "origem_demanda_id": 34, "grupo_parcelamento": "cc9c95a7-7543-4a1b-bcd0-849cf5049c52"}, {"id": 83, "pago": true, "valor": 780, "com_nf": false, "cliente": "3 clientes Mayra ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:31:53.366318+00:00", "valor_bruto": 780, "data_trabalho": "2026-10-06", "parcela_total": 1, "data_pagamento": "2026-10-07", "parcela_numero": 1, "origem_demanda_id": 3, "grupo_parcelamento": null}], "geradoEm": "2026-10-09T03:00:00.285493+00:00"}	2026-10-09 03:00:00.285493+00
339	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-10-10	{"gastos": [], "versao": 2, "demandas": [{"id": 2, "etapa": "Atendimento", "prazo": "2026-10-07", "valor": 1480, "com_nf": false, "status": "concluido", "cliente": "Noiva Djeice", "horario": "10:00:00", "projeto": "Noiva", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Av Otacílio Negrão de Lima 7180", "descricao": "Noiva, mae e avó ", "created_at": "2026-10-06T00:55:16.948742+00:00", "no_estudio": false, "contrato_nome": "contrato_noiva_Djeice_Kellem_assinado.pdf", "contrato_path": "4c9add6f-2949-4539-8980-1ac9f840ff8e/2-1791430684871-contrato_noiva_Djeice_Kellem_assinado.pdf", "contrato_tipo": "application/pdf", "data_gravacao": null, "datas_gravacao": ["2026-10-07"], "dias_concluidos": ["2026-10-07"], "horario_termino": null, "quantidade_pessoas": 2, "valor_deslocamento": 0}, {"id": 3, "etapa": "Atendimento", "prazo": "2026-10-06", "valor": 480, "com_nf": false, "status": "concluido", "cliente": "2 clientes Mayra ", "horario": "14:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Rua Gonçalves Dias, 30 – Funcionários", "descricao": "Precisam estar prontas até 19h Maquiagem 210,00\\nPenteado 200,00 \\nDeslocamento 80,00", "created_at": "2026-10-06T01:03:39.41186+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-06"], "dias_concluidos": [], "horario_termino": null, "quantidade_pessoas": 2, "valor_deslocamento": 0}, {"id": 5, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Leticia jordana ", "horario": "07:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "", "created_at": "2026-10-08T03:03:53.949799+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "08:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 6, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Joice", "horario": "12:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel", "created_at": "2026-10-08T03:25:20.441992+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "13:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 7, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Emanuelle ", "horario": "13:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T03:32:58.329759+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "14:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 8, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Glaucia ", "horario": "14:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T03:41:00.208497+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "15:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 9, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Penteado com bel", "horario": "17:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel", "created_at": "2026-10-08T03:42:39.785801+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-10"], "dias_concluidos": [], "horario_termino": "18:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 10, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Emanuelle Mota", "horario": "09:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T03:44:44.869025+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-11"], "dias_concluidos": [], "horario_termino": "10:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 11, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Aline souto", "horario": "11:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Rua Coronel Leri Santos, n 107. Apto 402. Bairro Planalto", "descricao": "Com Débora paisano ", "created_at": "2026-10-08T03:48:35.073926+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-11"], "dias_concluidos": [], "horario_termino": "12:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 80}, {"id": 18, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Ana Paula", "horario": "13:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Hilton Garden Inn Belo Horizonte", "descricao": "Com Débora paisano ", "created_at": "2026-10-08T03:57:18.805791+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-11"], "dias_concluidos": [], "horario_termino": "14:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 70}, {"id": 26, "etapa": "Atendimento", "prazo": "2026-10-16", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Penteado com bel ", "horario": "16:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "", "created_at": "2026-10-08T11:07:56.908023+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-16"], "dias_concluidos": [], "horario_termino": "17:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 27, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Penteado com bel ", "horario": "06:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "", "created_at": "2026-10-08T11:09:28.207616+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-17"], "dias_concluidos": [], "horario_termino": "07:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 28, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 800, "com_nf": false, "status": "confirmado", "cliente": "4 penteado com bel Igarapé ", "horario": "09:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Igarapé ", "descricao": "", "created_at": "2026-10-08T11:14:43.727009+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-17"], "dias_concluidos": [], "horario_termino": "16:30:00", "quantidade_pessoas": 5, "valor_deslocamento": 200}, {"id": 29, "etapa": "Atendimento", "prazo": "2026-10-17", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Beatriz ", "horario": "18:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T11:16:28.849472+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-17"], "dias_concluidos": [], "horario_termino": "19:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 30, "etapa": "Atendimento", "prazo": "2026-10-18", "valor": 1000, "com_nf": false, "status": "confirmado", "cliente": "5 penteados com iara", "horario": "07:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "5 penteafos na Iara ", "created_at": "2026-10-08T11:22:34.075904+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-18"], "dias_concluidos": [], "horario_termino": "12:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 31, "etapa": "Atendimento", "prazo": "2026-10-24", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Sabrina ", "horario": "13:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T11:23:37.644332+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-24"], "dias_concluidos": [], "horario_termino": "14:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 32, "etapa": "Atendimento", "prazo": "2026-10-24", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Ana ", "horario": "14:30:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Com bel ", "created_at": "2026-10-08T11:24:40.442469+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-24"], "dias_concluidos": [], "horario_termino": "15:30:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 34, "etapa": "Atendimento", "prazo": "2026-10-28", "valor": 200, "com_nf": false, "status": "confirmado", "cliente": "Carol - civil", "horario": "06:00:00", "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "", "descricao": "Noiva civil com bel ", "created_at": "2026-10-08T11:29:44.081756+00:00", "no_estudio": true, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-10-28"], "dias_concluidos": [], "horario_termino": "07:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}, {"id": 35, "etapa": "Atendimento", "prazo": "2026-11-01", "valor": 1190, "com_nf": false, "status": "concluido", "cliente": "Noiva Carol", "horario": "12:00:00", "projeto": "Noiva", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "endereco": "Otacílio Negrão de Lima 7630, Pampulha", "descricao": "Irei produzir Somente a noiva ", "created_at": "2026-10-09T03:15:47.049791+00:00", "no_estudio": false, "contrato_nome": null, "contrato_path": null, "contrato_tipo": null, "data_gravacao": null, "datas_gravacao": ["2026-11-01"], "dias_concluidos": [], "horario_termino": "16:00:00", "quantidade_pessoas": 1, "valor_deslocamento": 0}], "financas": [{"id": 9, "pago": true, "valor": 50, "com_nf": false, "cliente": "Leticia jordana ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:03:54.332505+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-06", "parcela_numero": 1, "origem_demanda_id": 5, "grupo_parcelamento": "b8518c22-8dd8-4cde-a33e-12b292f664c7"}, {"id": 10, "pago": false, "valor": 150, "com_nf": false, "cliente": "Leticia jordana ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:03:54.332505+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-10", "parcela_numero": 2, "origem_demanda_id": 5, "grupo_parcelamento": "b8518c22-8dd8-4cde-a33e-12b292f664c7"}, {"id": 18, "pago": true, "valor": 50, "com_nf": false, "cliente": "Joice", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:31:13.069802+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-08", "parcela_numero": 1, "origem_demanda_id": 6, "grupo_parcelamento": "d427bf7e-6389-4439-a247-702414d51391"}, {"id": 19, "pago": false, "valor": 150, "com_nf": false, "cliente": "Joice", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:31:13.069802+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-10", "parcela_numero": 2, "origem_demanda_id": 6, "grupo_parcelamento": "d427bf7e-6389-4439-a247-702414d51391"}, {"id": 20, "pago": true, "valor": 50, "com_nf": false, "cliente": "Emanuelle ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:32:58.581118+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-06", "parcela_numero": 1, "origem_demanda_id": 7, "grupo_parcelamento": "d0926d6d-8927-4e50-9a48-02fe79d2f853"}, {"id": 21, "pago": false, "valor": 150, "com_nf": false, "cliente": "Emanuelle ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:32:58.581118+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-10", "parcela_numero": 2, "origem_demanda_id": 7, "grupo_parcelamento": "d0926d6d-8927-4e50-9a48-02fe79d2f853"}, {"id": 28, "pago": true, "valor": 50, "com_nf": false, "cliente": "Penteado com bel", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:43:01.408711+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-09-15", "parcela_numero": 1, "origem_demanda_id": 9, "grupo_parcelamento": "c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc"}, {"id": 29, "pago": false, "valor": 150, "com_nf": false, "cliente": "Penteado com bel", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:43:01.408711+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-10", "parcela_numero": 2, "origem_demanda_id": 9, "grupo_parcelamento": "c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc"}, {"id": 30, "pago": true, "valor": 50, "com_nf": false, "cliente": "Emanuelle Mota", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:44:45.672275+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-11", "parcela_total": 2, "data_pagamento": "2026-09-07", "parcela_numero": 1, "origem_demanda_id": 10, "grupo_parcelamento": "a067c6b9-54f1-4b76-a01b-3f0958dd79b9"}, {"id": 31, "pago": false, "valor": 150, "com_nf": false, "cliente": "Emanuelle Mota", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:44:45.672275+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-11", "parcela_total": 2, "data_pagamento": "2026-10-11", "parcela_numero": 2, "origem_demanda_id": 10, "grupo_parcelamento": "a067c6b9-54f1-4b76-a01b-3f0958dd79b9"}, {"id": 32, "pago": true, "valor": 50, "com_nf": false, "cliente": "Aline souto", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:48:35.312252+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-11", "parcela_total": 2, "data_pagamento": "2026-09-30", "parcela_numero": 1, "origem_demanda_id": 11, "grupo_parcelamento": "cd7dfaf3-802e-4bbd-9833-1497f7d76756"}, {"id": 33, "pago": false, "valor": 150, "com_nf": false, "cliente": "Aline souto", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T03:48:35.312252+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-11", "parcela_total": 2, "data_pagamento": "2026-10-11", "parcela_numero": 2, "origem_demanda_id": 11, "grupo_parcelamento": "cd7dfaf3-802e-4bbd-9833-1497f7d76756"}, {"id": 63, "pago": true, "valor": 50, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:07:57.618244+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-16", "parcela_total": 2, "data_pagamento": "2026-09-23", "parcela_numero": 1, "origem_demanda_id": 26, "grupo_parcelamento": "5a0065b4-6f3a-40a6-a0a1-0f14de05eb19"}, {"id": 64, "pago": false, "valor": 150, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:07:57.618244+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-16", "parcela_total": 2, "data_pagamento": "2026-10-16", "parcela_numero": 2, "origem_demanda_id": 26, "grupo_parcelamento": "5a0065b4-6f3a-40a6-a0a1-0f14de05eb19"}, {"id": 65, "pago": true, "valor": 50, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:09:28.757193+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-09-23", "parcela_numero": 1, "origem_demanda_id": 27, "grupo_parcelamento": "530b89e7-284d-415c-9bcc-4f88beeb4332"}, {"id": 66, "pago": false, "valor": 150, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:09:28.757193+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-10-17", "parcela_numero": 2, "origem_demanda_id": 27, "grupo_parcelamento": "530b89e7-284d-415c-9bcc-4f88beeb4332"}, {"id": 69, "pago": true, "valor": 50, "com_nf": false, "cliente": "Beatriz ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:16:29.27987+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-09-23", "parcela_numero": 1, "origem_demanda_id": 29, "grupo_parcelamento": "0a0fe7f9-af5a-4550-8358-5572e33eecd3"}, {"id": 70, "pago": false, "valor": 150, "com_nf": false, "cliente": "Beatriz ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:16:29.27987+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-10-17", "parcela_numero": 2, "origem_demanda_id": 29, "grupo_parcelamento": "0a0fe7f9-af5a-4550-8358-5572e33eecd3"}, {"id": 71, "pago": true, "valor": 200, "com_nf": false, "cliente": "4 penteado com bel Igarapé ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:18:15.703929+00:00", "valor_bruto": 200, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-09-22", "parcela_numero": 1, "origem_demanda_id": 28, "grupo_parcelamento": "04939b8e-b128-44ba-a664-b04522f82090"}, {"id": 72, "pago": false, "valor": 600, "com_nf": false, "cliente": "4 penteado com bel Igarapé ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:18:15.703929+00:00", "valor_bruto": 600, "data_trabalho": "2026-10-17", "parcela_total": 2, "data_pagamento": "2026-10-17", "parcela_numero": 2, "origem_demanda_id": 28, "grupo_parcelamento": "04939b8e-b128-44ba-a664-b04522f82090"}, {"id": 73, "pago": false, "valor": 1000, "com_nf": false, "cliente": "5 penteados com iara", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:22:34.668625+00:00", "valor_bruto": 1000, "data_trabalho": "2026-10-18", "parcela_total": 1, "data_pagamento": "2026-10-18", "parcela_numero": 1, "origem_demanda_id": 30, "grupo_parcelamento": null}, {"id": 80, "pago": true, "valor": 50, "com_nf": false, "cliente": "Carol - civil", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:29:44.471819+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-28", "parcela_total": 2, "data_pagamento": "2026-09-13", "parcela_numero": 1, "origem_demanda_id": 34, "grupo_parcelamento": "cc9c95a7-7543-4a1b-bcd0-849cf5049c52"}, {"id": 81, "pago": false, "valor": 150, "com_nf": false, "cliente": "Carol - civil", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:29:44.471819+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-28", "parcela_total": 2, "data_pagamento": "2026-10-28", "parcela_numero": 2, "origem_demanda_id": 34, "grupo_parcelamento": "cc9c95a7-7543-4a1b-bcd0-849cf5049c52"}, {"id": 83, "pago": true, "valor": 780, "com_nf": false, "cliente": "3 clientes Mayra ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-08T11:31:53.366318+00:00", "valor_bruto": 780, "data_trabalho": "2026-10-06", "parcela_total": 1, "data_pagamento": "2026-10-07", "parcela_numero": 1, "origem_demanda_id": 3, "grupo_parcelamento": null}, {"id": 84, "pago": true, "valor": 50, "com_nf": false, "cliente": "Glaucia ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T03:05:42.677157+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-07", "parcela_numero": 1, "origem_demanda_id": 8, "grupo_parcelamento": "ae80e416-ead8-4615-919f-cc616d570460"}, {"id": 85, "pago": false, "valor": 150, "com_nf": false, "cliente": "Glaucia ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T03:05:42.677157+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-10", "parcela_total": 2, "data_pagamento": "2026-10-08", "parcela_numero": 2, "origem_demanda_id": 8, "grupo_parcelamento": "ae80e416-ead8-4615-919f-cc616d570460"}, {"id": 86, "pago": true, "valor": 50, "com_nf": false, "cliente": "Sabrina ", "e_sinal": true, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T03:05:54.974484+00:00", "valor_bruto": 50, "data_trabalho": "2026-10-24", "parcela_total": 2, "data_pagamento": "2026-09-21", "parcela_numero": 1, "origem_demanda_id": 31, "grupo_parcelamento": "f392d611-aa45-41da-ab3c-c65234e10a5b"}, {"id": 87, "pago": false, "valor": 150, "com_nf": false, "cliente": "Sabrina ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T03:05:54.974484+00:00", "valor_bruto": 150, "data_trabalho": "2026-10-24", "parcela_total": 2, "data_pagamento": "2026-10-24", "parcela_numero": 2, "origem_demanda_id": 31, "grupo_parcelamento": "f392d611-aa45-41da-ab3c-c65234e10a5b"}, {"id": 90, "pago": true, "valor": 1480, "com_nf": false, "cliente": "Noiva Djeice", "e_sinal": false, "projeto": "Noiva", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T03:07:38.286763+00:00", "valor_bruto": 1480, "data_trabalho": "2026-10-07", "parcela_total": 1, "data_pagamento": "2026-09-19", "parcela_numero": 1, "origem_demanda_id": 2, "grupo_parcelamento": null}, {"id": 92, "pago": true, "valor": 1190, "com_nf": false, "cliente": "Noiva Carol", "e_sinal": false, "projeto": "Noiva", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T03:18:09.601745+00:00", "valor_bruto": 1190, "data_trabalho": "2026-11-01", "parcela_total": 1, "data_pagamento": "2026-09-01", "parcela_numero": 1, "origem_demanda_id": 35, "grupo_parcelamento": null}, {"id": 93, "pago": true, "valor": 750, "com_nf": false, "cliente": "Débora passos ", "e_sinal": false, "projeto": "Curso de Penteados", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T03:19:22.644251+00:00", "valor_bruto": 750, "data_trabalho": "2026-09-02", "parcela_total": 1, "data_pagamento": "2026-09-02", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 96, "pago": true, "valor": 780, "com_nf": false, "cliente": "2 penteados com bel e 2 Iara ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:11:43.306081+00:00", "valor_bruto": 780, "data_trabalho": "2026-09-04", "parcela_total": 1, "data_pagamento": "2026-09-04", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 97, "pago": true, "valor": 380, "com_nf": false, "cliente": "2Penteados blossom ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:11:53.259824+00:00", "valor_bruto": 380, "data_trabalho": "2026-09-04", "parcela_total": 1, "data_pagamento": "2026-09-04", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 98, "pago": true, "valor": 1600, "com_nf": false, "cliente": "8 penteados no studio ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:13:18.954508+00:00", "valor_bruto": 1600, "data_trabalho": "2026-09-05", "parcela_total": 1, "data_pagamento": "2026-09-05", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 99, "pago": true, "valor": 1800, "com_nf": false, "cliente": "Noiva rayla + 4", "e_sinal": false, "projeto": "Noiva", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:15:03.963034+00:00", "valor_bruto": 1800, "data_trabalho": "2026-09-06", "parcela_total": 1, "data_pagamento": "2026-09-06", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 100, "pago": true, "valor": 950, "com_nf": false, "cliente": "Curso Sueli + penteado blossom ", "e_sinal": false, "projeto": "Curso de Penteados", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:16:06.495199+00:00", "valor_bruto": 950, "data_trabalho": "2026-09-09", "parcela_total": 1, "data_pagamento": "2026-09-09", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 101, "pago": true, "valor": 800, "com_nf": false, "cliente": "4 penteados ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:17:46.378147+00:00", "valor_bruto": 800, "data_trabalho": "2026-09-12", "parcela_total": 1, "data_pagamento": "2026-09-12", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 102, "pago": true, "valor": 400, "com_nf": false, "cliente": "2 clientes studio ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:18:33.380445+00:00", "valor_bruto": 400, "data_trabalho": "2026-09-13", "parcela_total": 1, "data_pagamento": "2026-09-13", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 103, "pago": true, "valor": 350, "com_nf": false, "cliente": "Penteado noiva Iara ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:19:20.301738+00:00", "valor_bruto": 350, "data_trabalho": "2026-09-15", "parcela_total": 1, "data_pagamento": "2026-09-15", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 104, "pago": true, "valor": 400, "com_nf": false, "cliente": "2 penteados Iara ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:20:04.334353+00:00", "valor_bruto": 400, "data_trabalho": "2026-09-18", "parcela_total": 1, "data_pagamento": "2026-09-18", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 105, "pago": true, "valor": 1800, "com_nf": false, "cliente": "9 penteados ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:21:09.833787+00:00", "valor_bruto": 1800, "data_trabalho": "2026-09-19", "parcela_total": 1, "data_pagamento": "2026-09-19", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 106, "pago": true, "valor": 550, "com_nf": false, "cliente": "3 penteados com bel ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:21:55.661256+00:00", "valor_bruto": 550, "data_trabalho": "2026-09-20", "parcela_total": 1, "data_pagamento": "2026-09-20", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 107, "pago": true, "valor": 200, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:22:25.500429+00:00", "valor_bruto": 200, "data_trabalho": "2026-09-24", "parcela_total": 1, "data_pagamento": "2026-09-24", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 108, "pago": true, "valor": 200, "com_nf": false, "cliente": "Penteado com bel ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:22:55.89218+00:00", "valor_bruto": 200, "data_trabalho": "2026-09-25", "parcela_total": 1, "data_pagamento": "2026-09-25", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 109, "pago": true, "valor": 1000, "com_nf": false, "cliente": "6 clientes ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:23:37.25665+00:00", "valor_bruto": 1000, "data_trabalho": "2026-09-26", "parcela_total": 1, "data_pagamento": "2026-09-26", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}, {"id": 110, "pago": true, "valor": 600, "com_nf": false, "cliente": "3 penteados ", "e_sinal": false, "projeto": "Penteado Social", "user_id": "4c9add6f-2949-4539-8980-1ac9f840ff8e", "created_at": "2026-10-09T22:24:25.363747+00:00", "valor_bruto": 600, "data_trabalho": "2026-09-27", "parcela_total": 1, "data_pagamento": "2026-09-27", "parcela_numero": 1, "origem_demanda_id": null, "grupo_parcelamento": null}], "geradoEm": "2026-10-10T03:00:00.223336+00:00"}	2026-10-10 03:00:00.223336+00
\.


--
-- Data for Name: backup_emails_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.backup_emails_log (id, user_id, enviado_em, destino, sucesso, detalhe) FROM stdin;
1	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-10-08 04:38:19.139016+00	pamelaelba@hotmail.com	t	10 atendimentos
\.


--
-- Data for Name: demandas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.demandas (id, user_id, cliente, projeto, etapa, prazo, status, data_gravacao, datas_gravacao, descricao, valor, com_nf, created_at, endereco, no_estudio, quantidade_pessoas, horario, horario_termino, valor_deslocamento, contrato_path, contrato_nome, contrato_tipo, dias_concluidos) FROM stdin;
35	4c9add6f-2949-4539-8980-1ac9f840ff8e	Noiva Carol	Noiva	Atendimento	2026-11-01	concluido	\N	{2026-11-01}	Irei produzir Somente a noiva 	1190	f	2026-10-09 03:15:47.049791+00	Otacílio Negrão de Lima 7630, Pampulha	f	1	12:00:00	16:00:00	0	\N	\N	\N	{}
5	4c9add6f-2949-4539-8980-1ac9f840ff8e	Leticia jordana 	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}		200	f	2026-10-08 03:03:53.949799+00		f	1	07:00:00	08:00:00	0	\N	\N	\N	{}
6	4c9add6f-2949-4539-8980-1ac9f840ff8e	Joice	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}	Com bel	200	f	2026-10-08 03:25:20.441992+00		t	1	12:00:00	13:00:00	0	\N	\N	\N	{}
7	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle 	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}	Com bel 	200	f	2026-10-08 03:32:58.329759+00		t	1	13:00:00	14:00:00	0	\N	\N	\N	{}
9	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}	Com bel	200	f	2026-10-08 03:42:39.785801+00		t	1	17:00:00	18:00:00	0	\N	\N	\N	{}
10	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle Mota	Penteado Social	Atendimento	2026-10-11	confirmado	\N	{2026-10-11}	Com bel 	200	f	2026-10-08 03:44:44.869025+00		t	1	09:00:00	10:00:00	0	\N	\N	\N	{}
11	4c9add6f-2949-4539-8980-1ac9f840ff8e	Aline souto	Penteado Social	Atendimento	2026-10-11	confirmado	\N	{2026-10-11}	Com Débora paisano 	200	f	2026-10-08 03:48:35.073926+00	Rua Coronel Leri Santos, n 107. Apto 402. Bairro Planalto	f	1	11:30:00	12:30:00	80	\N	\N	\N	{}
18	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana Paula	Penteado Social	Atendimento	2026-10-11	confirmado	\N	{2026-10-11}	Com Débora paisano 	200	f	2026-10-08 03:57:18.805791+00	Hilton Garden Inn Belo Horizonte	f	1	13:30:00	14:30:00	70	\N	\N	\N	{}
26	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	Atendimento	2026-10-16	confirmado	\N	{2026-10-16}		200	f	2026-10-08 11:07:56.908023+00		t	1	16:00:00	17:00:00	0	\N	\N	\N	{}
27	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	Atendimento	2026-10-17	confirmado	\N	{2026-10-17}		200	f	2026-10-08 11:09:28.207616+00		t	1	06:30:00	07:30:00	0	\N	\N	\N	{}
29	4c9add6f-2949-4539-8980-1ac9f840ff8e	Beatriz 	Penteado Social	Atendimento	2026-10-17	confirmado	\N	{2026-10-17}	Com bel 	200	f	2026-10-08 11:16:28.849472+00		t	1	18:00:00	19:00:00	0	\N	\N	\N	{}
28	4c9add6f-2949-4539-8980-1ac9f840ff8e	4 penteado com bel Igarapé 	Penteado Social	Atendimento	2026-10-17	confirmado	\N	{2026-10-17}		800	f	2026-10-08 11:14:43.727009+00	Igarapé 	f	5	09:30:00	16:30:00	200	\N	\N	\N	{}
30	4c9add6f-2949-4539-8980-1ac9f840ff8e	5 penteados com iara	Penteado Social	Atendimento	2026-10-18	confirmado	\N	{2026-10-18}	5 penteafos na Iara 	1000	f	2026-10-08 11:22:34.075904+00		f	1	07:00:00	12:00:00	0	\N	\N	\N	{}
32	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana 	Penteado Social	Atendimento	2026-10-24	confirmado	\N	{2026-10-24}	Com bel 	200	f	2026-10-08 11:24:40.442469+00		t	1	14:30:00	15:30:00	0	\N	\N	\N	{}
34	4c9add6f-2949-4539-8980-1ac9f840ff8e	Carol - civil	Penteado Social	Atendimento	2026-10-28	confirmado	\N	{2026-10-28}	Noiva civil com bel 	200	f	2026-10-08 11:29:44.081756+00		t	1	06:00:00	07:00:00	0	\N	\N	\N	{}
3	4c9add6f-2949-4539-8980-1ac9f840ff8e	2 clientes Mayra 	Penteado Social	Atendimento	2026-10-06	concluido	\N	{2026-10-06}	Precisam estar prontas até 19h Maquiagem 210,00\nPenteado 200,00 \nDeslocamento 80,00	480	f	2026-10-06 01:03:39.41186+00	Rua Gonçalves Dias, 30 – Funcionários	f	2	14:00:00	\N	0	\N	\N	\N	{}
8	4c9add6f-2949-4539-8980-1ac9f840ff8e	Glaucia 	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}	Com bel 	200	f	2026-10-08 03:41:00.208497+00		t	1	14:00:00	15:00:00	0	\N	\N	\N	{}
31	4c9add6f-2949-4539-8980-1ac9f840ff8e	Sabrina 	Penteado Social	Atendimento	2026-10-24	confirmado	\N	{2026-10-24}	Com bel 	200	f	2026-10-08 11:23:37.644332+00		t	1	13:00:00	14:00:00	0	\N	\N	\N	{}
2	4c9add6f-2949-4539-8980-1ac9f840ff8e	Noiva Djeice	Noiva	Atendimento	2026-10-07	concluido	\N	{2026-10-07}	Noiva, mae e avó 	1480	f	2026-10-06 00:55:16.948742+00	Av Otacílio Negrão de Lima 7180	f	2	10:00:00	\N	0	4c9add6f-2949-4539-8980-1ac9f840ff8e/2-1791430684871-contrato_noiva_Djeice_Kellem_assinado.pdf	contrato_noiva_Djeice_Kellem_assinado.pdf	application/pdf	{2026-10-07}
\.


--
-- Data for Name: financas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.financas (id, user_id, cliente, projeto, valor, valor_bruto, com_nf, data_trabalho, data_pagamento, pago, origem_demanda_id, created_at, parcela_numero, parcela_total, grupo_parcelamento, e_sinal) FROM stdin;
84	4c9add6f-2949-4539-8980-1ac9f840ff8e	Glaucia 	Penteado Social	50	50	f	2026-10-10	2026-10-07	t	8	2026-10-09 03:05:42.677157+00	1	2	ae80e416-ead8-4615-919f-cc616d570460	t
85	4c9add6f-2949-4539-8980-1ac9f840ff8e	Glaucia 	Penteado Social	150	150	f	2026-10-10	2026-10-08	f	8	2026-10-09 03:05:42.677157+00	2	2	ae80e416-ead8-4615-919f-cc616d570460	f
86	4c9add6f-2949-4539-8980-1ac9f840ff8e	Sabrina 	Penteado Social	50	50	f	2026-10-24	2026-09-21	t	31	2026-10-09 03:05:54.974484+00	1	2	f392d611-aa45-41da-ab3c-c65234e10a5b	t
87	4c9add6f-2949-4539-8980-1ac9f840ff8e	Sabrina 	Penteado Social	150	150	f	2026-10-24	2026-10-24	f	31	2026-10-09 03:05:54.974484+00	2	2	f392d611-aa45-41da-ab3c-c65234e10a5b	f
90	4c9add6f-2949-4539-8980-1ac9f840ff8e	Noiva Djeice	Noiva	1480	1480	f	2026-10-07	2026-09-19	t	2	2026-10-09 03:07:38.286763+00	1	1	\N	f
92	4c9add6f-2949-4539-8980-1ac9f840ff8e	Noiva Carol	Noiva	1190	1190	f	2026-11-01	2026-09-01	t	35	2026-10-09 03:18:09.601745+00	1	1	\N	f
10	4c9add6f-2949-4539-8980-1ac9f840ff8e	Leticia jordana 	Penteado Social	150	150	f	2026-10-10	2026-10-10	f	5	2026-10-08 03:03:54.332505+00	2	2	b8518c22-8dd8-4cde-a33e-12b292f664c7	f
93	4c9add6f-2949-4539-8980-1ac9f840ff8e	Débora passos 	Curso de Penteados	750	750	f	2026-09-02	2026-09-02	t	\N	2026-10-09 03:19:22.644251+00	1	1	\N	f
9	4c9add6f-2949-4539-8980-1ac9f840ff8e	Leticia jordana 	Penteado Social	50	50	f	2026-10-10	2026-10-06	t	5	2026-10-08 03:03:54.332505+00	1	2	b8518c22-8dd8-4cde-a33e-12b292f664c7	f
96	4c9add6f-2949-4539-8980-1ac9f840ff8e	2 penteados com bel e 2 Iara 	Penteado Social	780	780	f	2026-09-04	2026-09-04	t	\N	2026-10-09 22:11:43.306081+00	1	1	\N	f
97	4c9add6f-2949-4539-8980-1ac9f840ff8e	2Penteados blossom 	Penteado Social	380	380	f	2026-09-04	2026-09-04	t	\N	2026-10-09 22:11:53.259824+00	1	1	\N	f
19	4c9add6f-2949-4539-8980-1ac9f840ff8e	Joice	Penteado Social	150	150	f	2026-10-10	2026-10-10	f	6	2026-10-08 03:31:13.069802+00	2	2	d427bf7e-6389-4439-a247-702414d51391	f
18	4c9add6f-2949-4539-8980-1ac9f840ff8e	Joice	Penteado Social	50	50	f	2026-10-10	2026-10-08	t	6	2026-10-08 03:31:13.069802+00	1	2	d427bf7e-6389-4439-a247-702414d51391	t
21	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle 	Penteado Social	150	150	f	2026-10-10	2026-10-10	f	7	2026-10-08 03:32:58.581118+00	2	2	d0926d6d-8927-4e50-9a48-02fe79d2f853	f
20	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle 	Penteado Social	50	50	f	2026-10-10	2026-10-06	t	7	2026-10-08 03:32:58.581118+00	1	2	d0926d6d-8927-4e50-9a48-02fe79d2f853	t
98	4c9add6f-2949-4539-8980-1ac9f840ff8e	8 penteados no studio 	Penteado Social	1600	1600	f	2026-09-05	2026-09-05	t	\N	2026-10-09 22:13:18.954508+00	1	1	\N	f
99	4c9add6f-2949-4539-8980-1ac9f840ff8e	Noiva rayla + 4	Noiva	1800	1800	f	2026-09-06	2026-09-06	t	\N	2026-10-09 22:15:03.963034+00	1	1	\N	f
100	4c9add6f-2949-4539-8980-1ac9f840ff8e	Curso Sueli + penteado blossom 	Curso de Penteados	950	950	f	2026-09-09	2026-09-09	t	\N	2026-10-09 22:16:06.495199+00	1	1	\N	f
101	4c9add6f-2949-4539-8980-1ac9f840ff8e	4 penteados 	Penteado Social	800	800	f	2026-09-12	2026-09-12	t	\N	2026-10-09 22:17:46.378147+00	1	1	\N	f
29	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel	Penteado Social	150	150	f	2026-10-10	2026-10-10	f	9	2026-10-08 03:43:01.408711+00	2	2	c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc	f
28	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel	Penteado Social	50	50	f	2026-10-10	2026-09-15	t	9	2026-10-08 03:43:01.408711+00	1	2	c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc	t
31	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle Mota	Penteado Social	150	150	f	2026-10-11	2026-10-11	f	10	2026-10-08 03:44:45.672275+00	2	2	a067c6b9-54f1-4b76-a01b-3f0958dd79b9	f
30	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle Mota	Penteado Social	50	50	f	2026-10-11	2026-09-07	t	10	2026-10-08 03:44:45.672275+00	1	2	a067c6b9-54f1-4b76-a01b-3f0958dd79b9	t
33	4c9add6f-2949-4539-8980-1ac9f840ff8e	Aline souto	Penteado Social	150	150	f	2026-10-11	2026-10-11	f	11	2026-10-08 03:48:35.312252+00	2	2	cd7dfaf3-802e-4bbd-9833-1497f7d76756	f
102	4c9add6f-2949-4539-8980-1ac9f840ff8e	2 clientes studio 	Penteado Social	400	400	f	2026-09-13	2026-09-13	t	\N	2026-10-09 22:18:33.380445+00	1	1	\N	f
103	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado noiva Iara 	Penteado Social	350	350	f	2026-09-15	2026-09-15	t	\N	2026-10-09 22:19:20.301738+00	1	1	\N	f
104	4c9add6f-2949-4539-8980-1ac9f840ff8e	2 penteados Iara 	Penteado Social	400	400	f	2026-09-18	2026-09-18	t	\N	2026-10-09 22:20:04.334353+00	1	1	\N	f
105	4c9add6f-2949-4539-8980-1ac9f840ff8e	9 penteados 	Penteado Social	1800	1800	f	2026-09-19	2026-09-19	t	\N	2026-10-09 22:21:09.833787+00	1	1	\N	f
106	4c9add6f-2949-4539-8980-1ac9f840ff8e	3 penteados com bel 	Penteado Social	550	550	f	2026-09-20	2026-09-20	t	\N	2026-10-09 22:21:55.661256+00	1	1	\N	f
107	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	200	200	f	2026-09-24	2026-09-24	t	\N	2026-10-09 22:22:25.500429+00	1	1	\N	f
108	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	200	200	f	2026-09-25	2026-09-25	t	\N	2026-10-09 22:22:55.89218+00	1	1	\N	f
109	4c9add6f-2949-4539-8980-1ac9f840ff8e	6 clientes 	Penteado Social	1000	1000	f	2026-09-26	2026-09-26	t	\N	2026-10-09 22:23:37.25665+00	1	1	\N	f
110	4c9add6f-2949-4539-8980-1ac9f840ff8e	3 penteados 	Penteado Social	600	600	f	2026-09-27	2026-09-27	t	\N	2026-10-09 22:24:25.363747+00	1	1	\N	f
64	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	150	150	f	2026-10-16	2026-10-16	f	26	2026-10-08 11:07:57.618244+00	2	2	5a0065b4-6f3a-40a6-a0a1-0f14de05eb19	f
32	4c9add6f-2949-4539-8980-1ac9f840ff8e	Aline souto	Penteado Social	50	50	f	2026-10-11	2026-09-30	t	11	2026-10-08 03:48:35.312252+00	1	2	cd7dfaf3-802e-4bbd-9833-1497f7d76756	t
66	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	150	150	f	2026-10-17	2026-10-17	f	27	2026-10-08 11:09:28.757193+00	2	2	530b89e7-284d-415c-9bcc-4f88beeb4332	f
70	4c9add6f-2949-4539-8980-1ac9f840ff8e	Beatriz 	Penteado Social	150	150	f	2026-10-17	2026-10-17	f	29	2026-10-08 11:16:29.27987+00	2	2	0a0fe7f9-af5a-4550-8358-5572e33eecd3	f
72	4c9add6f-2949-4539-8980-1ac9f840ff8e	4 penteado com bel Igarapé 	Penteado Social	600	600	f	2026-10-17	2026-10-17	f	28	2026-10-08 11:18:15.703929+00	2	2	04939b8e-b128-44ba-a664-b04522f82090	f
73	4c9add6f-2949-4539-8980-1ac9f840ff8e	5 penteados com iara	Penteado Social	1000	1000	f	2026-10-18	2026-10-18	f	30	2026-10-08 11:22:34.668625+00	1	1	\N	f
63	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	50	50	f	2026-10-16	2026-09-23	t	26	2026-10-08 11:07:57.618244+00	1	2	5a0065b4-6f3a-40a6-a0a1-0f14de05eb19	t
65	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	50	50	f	2026-10-17	2026-09-23	t	27	2026-10-08 11:09:28.757193+00	1	2	530b89e7-284d-415c-9bcc-4f88beeb4332	t
69	4c9add6f-2949-4539-8980-1ac9f840ff8e	Beatriz 	Penteado Social	50	50	f	2026-10-17	2026-09-23	t	29	2026-10-08 11:16:29.27987+00	1	2	0a0fe7f9-af5a-4550-8358-5572e33eecd3	t
71	4c9add6f-2949-4539-8980-1ac9f840ff8e	4 penteado com bel Igarapé 	Penteado Social	200	200	f	2026-10-17	2026-09-22	t	28	2026-10-08 11:18:15.703929+00	1	2	04939b8e-b128-44ba-a664-b04522f82090	t
81	4c9add6f-2949-4539-8980-1ac9f840ff8e	Carol - civil	Penteado Social	150	150	f	2026-10-28	2026-10-28	f	34	2026-10-08 11:29:44.471819+00	2	2	cc9c95a7-7543-4a1b-bcd0-849cf5049c52	f
83	4c9add6f-2949-4539-8980-1ac9f840ff8e	3 clientes Mayra 	Penteado Social	780	780	f	2026-10-06	2026-10-07	t	3	2026-10-08 11:31:53.366318+00	1	1	\N	f
80	4c9add6f-2949-4539-8980-1ac9f840ff8e	Carol - civil	Penteado Social	50	50	f	2026-10-28	2026-09-13	t	34	2026-10-08 11:29:44.471819+00	1	2	cc9c95a7-7543-4a1b-bcd0-849cf5049c52	t
\.


--
-- Data for Name: gastos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.gastos (id, user_id, projeto, cliente, descricao, valor, data, created_at, origem_demanda_id, extra_tipo, extra_nome) FROM stdin;
\.


--
-- Name: agenda_backups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.agenda_backups_id_seq', 339, true);


--
-- Name: backup_emails_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.backup_emails_log_id_seq', 1, true);


--
-- Name: demandas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.demandas_id_seq', 35, true);


--
-- Name: financas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.financas_id_seq', 110, true);


--
-- Name: gastos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.gastos_id_seq', 2, true);


--
-- Name: agenda_backups agenda_backups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agenda_backups
    ADD CONSTRAINT agenda_backups_pkey PRIMARY KEY (id);


--
-- Name: agenda_backups agenda_backups_user_id_data_referencia_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agenda_backups
    ADD CONSTRAINT agenda_backups_user_id_data_referencia_key UNIQUE (user_id, data_referencia);


--
-- Name: backup_emails_log backup_emails_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backup_emails_log
    ADD CONSTRAINT backup_emails_log_pkey PRIMARY KEY (id);


--
-- Name: demandas demandas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandas
    ADD CONSTRAINT demandas_pkey PRIMARY KEY (id);


--
-- Name: financas financas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financas
    ADD CONSTRAINT financas_pkey PRIMARY KEY (id);


--
-- Name: gastos gastos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos
    ADD CONSTRAINT gastos_pkey PRIMARY KEY (id);


--
-- Name: agenda_backups agenda_backups_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agenda_backups
    ADD CONSTRAINT agenda_backups_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: demandas demandas_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandas
    ADD CONSTRAINT demandas_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: financas financas_origem_demanda_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financas
    ADD CONSTRAINT financas_origem_demanda_id_fkey FOREIGN KEY (origem_demanda_id) REFERENCES public.demandas(id) ON DELETE CASCADE;


--
-- Name: financas financas_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financas
    ADD CONSTRAINT financas_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: gastos gastos_origem_demanda_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos
    ADD CONSTRAINT gastos_origem_demanda_id_fkey FOREIGN KEY (origem_demanda_id) REFERENCES public.demandas(id) ON DELETE CASCADE;


--
-- Name: gastos gastos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos
    ADD CONSTRAINT gastos_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: agenda_backups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agenda_backups ENABLE ROW LEVEL SECURITY;

--
-- Name: backup_emails_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.backup_emails_log ENABLE ROW LEVEL SECURITY;

--
-- Name: agenda_backups cada usuario ve so seus backups; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "cada usuario ve so seus backups" ON public.agenda_backups USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: demandas cada usuario ve so seus dados - demandas; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "cada usuario ve so seus dados - demandas" ON public.demandas USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: financas cada usuario ve so seus dados - financas; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "cada usuario ve so seus dados - financas" ON public.financas USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: gastos cada usuario ve so seus dados - gastos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "cada usuario ve so seus dados - gastos" ON public.gastos USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: demandas; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.demandas ENABLE ROW LEVEL SECURITY;

--
-- Name: financas; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.financas ENABLE ROW LEVEL SECURITY;

--
-- Name: gastos; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.gastos ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict 7Y1r2jeFqkI1eTDOh3E4rKZU90D9VvNVHH6rUcP7P00jBscahnSm2VSSaRiMc2x

