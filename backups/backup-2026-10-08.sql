--
-- PostgreSQL database dump
--

\restrict q8wLaIZzPsRqDDbnLuWjoboJ3L1d3DTWynyUakUwzA8iVKnUsDmfLx8UPAbwBlJ

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
252	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-10-08	{"gastos": [], "demandas": [{"id": 3, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-06", "valor": 480, "status": "aguardando_pagamento", "cliente": "2 clientes Mayra ", "horario": "14:00:00", "projeto": "Penteado Social", "endereco": "Rua Gonçalves Dias, 30 – Funcionários", "descricao": "Precisam estar prontas até 19h Maquiagem 210,00\\nPenteado 200,00 \\nDeslocamento 80,00", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-06"], "diasConcluidos": [], "horarioTermino": "", "quantidadePessoas": 2, "valorDeslocamento": 0}, {"id": 2, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-07", "valor": 1480, "status": "aguardando_pagamento", "cliente": "Noiva Djeice", "horario": "10:00:00", "projeto": "Noiva", "endereco": "Av Otacílio Negrão de Lima 7180", "descricao": "Noiva mais mãe e ", "noEstudio": false, "contratoNome": "contrato_noiva_Djeice_Kellem_assinado.pdf", "contratoPath": "4c9add6f-2949-4539-8980-1ac9f840ff8e/2-1791430684871-contrato_noiva_Djeice_Kellem_assinado.pdf", "contratoTipo": "application/pdf", "dataGravacao": null, "datasGravacao": ["2026-10-07"], "diasConcluidos": ["2026-10-07"], "horarioTermino": "", "quantidadePessoas": 2, "valorDeslocamento": 0}, {"id": 6, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "confirmado", "cliente": "Joice", "horario": "12:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "13:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 7, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "confirmado", "cliente": "Emanuelle ", "horario": "13:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "14:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 9, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "confirmado", "cliente": "Penteado com bel", "horario": "17:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "18:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 8, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "pre_reserva", "cliente": "Glaucia ", "horario": "14:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "15:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 5, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-10", "valor": 200, "status": "confirmado", "cliente": "Leticia jordana ", "horario": "07:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-10"], "diasConcluidos": [], "horarioTermino": "08:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 10, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "status": "confirmado", "cliente": "Emanuelle Mota", "horario": "09:00:00", "projeto": "Penteado Social", "endereco": "", "descricao": "Com bel ", "noEstudio": true, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-11"], "diasConcluidos": [], "horarioTermino": "10:00:00", "quantidadePessoas": 1, "valorDeslocamento": 0}, {"id": 11, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "status": "confirmado", "cliente": "Aline souto", "horario": "11:30:00", "projeto": "Penteado Social", "endereco": "Rua Coronel Leri Santos, n 107. Apto 402. Bairro Planalto", "descricao": "Com Débora paisano ", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-11"], "diasConcluidos": [], "horarioTermino": "12:30:00", "quantidadePessoas": 1, "valorDeslocamento": 80}, {"id": 18, "comNF": false, "etapa": "Atendimento", "prazo": "2026-10-11", "valor": 200, "status": "confirmado", "cliente": "Ana Paula", "horario": "13:30:00", "projeto": "Penteado Social", "endereco": "Hilton Garden Inn Belo Horizonte", "descricao": "Com Débora paisano ", "noEstudio": false, "contratoNome": "", "contratoPath": null, "contratoTipo": "", "dataGravacao": null, "datasGravacao": ["2026-10-11"], "diasConcluidos": [], "horarioTermino": "14:30:00", "quantidadePessoas": 1, "valorDeslocamento": 70}], "financas": [{"id": 30, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Emanuelle Mota", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-11", "parcelaTotal": 2, "dataPagamento": "2026-09-07", "parcelaNumero": 1, "origemDemandaId": 10, "grupoParcelamento": "a067c6b9-54f1-4b76-a01b-3f0958dd79b9"}, {"id": 28, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Penteado com bel", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-09-15", "parcelaNumero": 1, "origemDemandaId": 9, "grupoParcelamento": "c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc"}, {"id": 23, "pago": true, "comNF": false, "valor": 1480, "eSinal": false, "cliente": "Noiva Djeice", "projeto": "Noiva", "valorBruto": 1480, "dataTrabalho": "2026-10-07", "parcelaTotal": 1, "dataPagamento": "2026-09-19", "parcelaNumero": 1, "origemDemandaId": 2, "grupoParcelamento": null}, {"id": 32, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Aline souto", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-11", "parcelaTotal": 2, "dataPagamento": "2026-09-30", "parcelaNumero": 1, "origemDemandaId": 11, "grupoParcelamento": "cd7dfaf3-802e-4bbd-9833-1497f7d76756"}, {"id": 9, "pago": true, "comNF": false, "valor": 50, "eSinal": false, "cliente": "Leticia jordana ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-06", "parcelaNumero": 1, "origemDemandaId": 5, "grupoParcelamento": "b8518c22-8dd8-4cde-a33e-12b292f664c7"}, {"id": 20, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Emanuelle ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-06", "parcelaNumero": 1, "origemDemandaId": 7, "grupoParcelamento": "d0926d6d-8927-4e50-9a48-02fe79d2f853"}, {"id": 24, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Glaucia ", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-07", "parcelaNumero": 1, "origemDemandaId": 8, "grupoParcelamento": "57505cda-4fd4-4cd4-a4a2-2a029ff3bd89"}, {"id": 25, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Glaucia ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-08", "parcelaNumero": 2, "origemDemandaId": 8, "grupoParcelamento": "57505cda-4fd4-4cd4-a4a2-2a029ff3bd89"}, {"id": 18, "pago": true, "comNF": false, "valor": 50, "eSinal": true, "cliente": "Joice", "projeto": "Penteado Social", "valorBruto": 50, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-08", "parcelaNumero": 1, "origemDemandaId": 6, "grupoParcelamento": "d427bf7e-6389-4439-a247-702414d51391"}, {"id": 29, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Penteado com bel", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-10", "parcelaNumero": 2, "origemDemandaId": 9, "grupoParcelamento": "c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc"}, {"id": 21, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Emanuelle ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-10", "parcelaNumero": 2, "origemDemandaId": 7, "grupoParcelamento": "d0926d6d-8927-4e50-9a48-02fe79d2f853"}, {"id": 19, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Joice", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-10", "parcelaNumero": 2, "origemDemandaId": 6, "grupoParcelamento": "d427bf7e-6389-4439-a247-702414d51391"}, {"id": 10, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Leticia jordana ", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-10", "parcelaTotal": 2, "dataPagamento": "2026-10-10", "parcelaNumero": 2, "origemDemandaId": 5, "grupoParcelamento": "b8518c22-8dd8-4cde-a33e-12b292f664c7"}, {"id": 33, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Aline souto", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-11", "parcelaTotal": 2, "dataPagamento": "2026-10-11", "parcelaNumero": 2, "origemDemandaId": 11, "grupoParcelamento": "cd7dfaf3-802e-4bbd-9833-1497f7d76756"}, {"id": 62, "pago": false, "comNF": false, "valor": 200, "eSinal": false, "cliente": "Ana Paula", "projeto": "Penteado Social", "valorBruto": 200, "dataTrabalho": "2026-10-11", "parcelaTotal": 1, "dataPagamento": "2026-10-11", "parcelaNumero": 1, "origemDemandaId": 18, "grupoParcelamento": null}, {"id": 31, "pago": false, "comNF": false, "valor": 150, "eSinal": false, "cliente": "Emanuelle Mota", "projeto": "Penteado Social", "valorBruto": 150, "dataTrabalho": "2026-10-11", "parcelaTotal": 2, "dataPagamento": "2026-10-11", "parcelaNumero": 2, "origemDemandaId": 10, "grupoParcelamento": "a067c6b9-54f1-4b76-a01b-3f0958dd79b9"}], "geradoEm": "2026-10-08T06:08:58.493Z"}	2026-10-08 04:11:51.315114+00
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
5	4c9add6f-2949-4539-8980-1ac9f840ff8e	Leticia jordana 	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}		200	f	2026-10-08 03:03:53.949799+00		f	1	07:00:00	08:00:00	0	\N	\N	\N	{}
6	4c9add6f-2949-4539-8980-1ac9f840ff8e	Joice	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}	Com bel	200	f	2026-10-08 03:25:20.441992+00		t	1	12:00:00	13:00:00	0	\N	\N	\N	{}
7	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle 	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}	Com bel 	200	f	2026-10-08 03:32:58.329759+00		t	1	13:00:00	14:00:00	0	\N	\N	\N	{}
2	4c9add6f-2949-4539-8980-1ac9f840ff8e	Noiva Djeice	Noiva	Atendimento	2026-10-07	aguardando_pagamento	\N	{2026-10-07}	Noiva mais mãe e 	1480	f	2026-10-06 00:55:16.948742+00	Av Otacílio Negrão de Lima 7180	f	2	10:00:00	\N	0	4c9add6f-2949-4539-8980-1ac9f840ff8e/2-1791430684871-contrato_noiva_Djeice_Kellem_assinado.pdf	contrato_noiva_Djeice_Kellem_assinado.pdf	application/pdf	{2026-10-07}
8	4c9add6f-2949-4539-8980-1ac9f840ff8e	Glaucia 	Penteado Social	Atendimento	2026-10-10	pre_reserva	\N	{2026-10-10}	Com bel 	200	f	2026-10-08 03:41:00.208497+00		t	1	14:00:00	15:00:00	0	\N	\N	\N	{}
9	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel	Penteado Social	Atendimento	2026-10-10	confirmado	\N	{2026-10-10}	Com bel	200	f	2026-10-08 03:42:39.785801+00		t	1	17:00:00	18:00:00	0	\N	\N	\N	{}
10	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle Mota	Penteado Social	Atendimento	2026-10-11	confirmado	\N	{2026-10-11}	Com bel 	200	f	2026-10-08 03:44:44.869025+00		t	1	09:00:00	10:00:00	0	\N	\N	\N	{}
11	4c9add6f-2949-4539-8980-1ac9f840ff8e	Aline souto	Penteado Social	Atendimento	2026-10-11	confirmado	\N	{2026-10-11}	Com Débora paisano 	200	f	2026-10-08 03:48:35.073926+00	Rua Coronel Leri Santos, n 107. Apto 402. Bairro Planalto	f	1	11:30:00	12:30:00	80	\N	\N	\N	{}
18	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana Paula	Penteado Social	Atendimento	2026-10-11	confirmado	\N	{2026-10-11}	Com Débora paisano 	200	f	2026-10-08 03:57:18.805791+00	Hilton Garden Inn Belo Horizonte	f	1	13:30:00	14:30:00	70	\N	\N	\N	{}
26	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	Atendimento	2026-10-16	confirmado	\N	{2026-10-16}		200	f	2026-10-08 11:07:56.908023+00		t	1	16:00:00	17:00:00	0	\N	\N	\N	{}
27	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	Atendimento	2026-10-17	confirmado	\N	{2026-10-17}		200	f	2026-10-08 11:09:28.207616+00		t	1	06:30:00	07:30:00	0	\N	\N	\N	{}
29	4c9add6f-2949-4539-8980-1ac9f840ff8e	Beatriz 	Penteado Social	Atendimento	2026-10-17	confirmado	\N	{2026-10-17}	Com bel 	200	f	2026-10-08 11:16:28.849472+00		t	1	18:00:00	19:00:00	0	\N	\N	\N	{}
28	4c9add6f-2949-4539-8980-1ac9f840ff8e	4 penteado com bel Igarapé 	Penteado Social	Atendimento	2026-10-17	confirmado	\N	{2026-10-17}		800	f	2026-10-08 11:14:43.727009+00	Igarapé 	f	5	09:30:00	16:30:00	200	\N	\N	\N	{}
30	4c9add6f-2949-4539-8980-1ac9f840ff8e	5 penteados com iara	Penteado Social	Atendimento	2026-10-18	confirmado	\N	{2026-10-18}	5 penteafos na Iara 	1000	f	2026-10-08 11:22:34.075904+00		f	1	07:00:00	12:00:00	0	\N	\N	\N	{}
31	4c9add6f-2949-4539-8980-1ac9f840ff8e	Sabrina 	Penteado Social	Atendimento	2026-10-24	pre_reserva	\N	{2026-10-24}	Com bel 	200	f	2026-10-08 11:23:37.644332+00		t	1	13:00:00	14:00:00	0	\N	\N	\N	{}
32	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana 	Penteado Social	Atendimento	2026-10-24	confirmado	\N	{2026-10-24}	Com bel 	200	f	2026-10-08 11:24:40.442469+00		t	1	14:30:00	15:30:00	0	\N	\N	\N	{}
33	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana 	Penteado Social	Atendimento	2026-10-24	confirmado	\N	{2026-10-24}	Com bel 	200	f	2026-10-08 11:24:41.196989+00		t	1	14:30:00	15:30:00	0	\N	\N	\N	{}
34	4c9add6f-2949-4539-8980-1ac9f840ff8e	Carol - civil	Penteado Social	Atendimento	2026-10-28	confirmado	\N	{2026-10-28}	Noiva civil com bel 	200	f	2026-10-08 11:29:44.081756+00		t	1	06:00:00	07:00:00	0	\N	\N	\N	{}
3	4c9add6f-2949-4539-8980-1ac9f840ff8e	2 clientes Mayra 	Penteado Social	Atendimento	2026-10-06	aguardando_pagamento	\N	{2026-10-06}	Precisam estar prontas até 19h Maquiagem 210,00\nPenteado 200,00 \nDeslocamento 80,00	480	f	2026-10-06 01:03:39.41186+00	Rua Gonçalves Dias, 30 – Funcionários	f	2	14:00:00	\N	0	\N	\N	\N	{}
\.


--
-- Data for Name: financas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.financas (id, user_id, cliente, projeto, valor, valor_bruto, com_nf, data_trabalho, data_pagamento, pago, origem_demanda_id, created_at, parcela_numero, parcela_total, grupo_parcelamento, e_sinal) FROM stdin;
10	4c9add6f-2949-4539-8980-1ac9f840ff8e	Leticia jordana 	Penteado Social	150	150	f	2026-10-10	2026-10-10	f	5	2026-10-08 03:03:54.332505+00	2	2	b8518c22-8dd8-4cde-a33e-12b292f664c7	f
9	4c9add6f-2949-4539-8980-1ac9f840ff8e	Leticia jordana 	Penteado Social	50	50	f	2026-10-10	2026-10-06	t	5	2026-10-08 03:03:54.332505+00	1	2	b8518c22-8dd8-4cde-a33e-12b292f664c7	f
19	4c9add6f-2949-4539-8980-1ac9f840ff8e	Joice	Penteado Social	150	150	f	2026-10-10	2026-10-10	f	6	2026-10-08 03:31:13.069802+00	2	2	d427bf7e-6389-4439-a247-702414d51391	f
18	4c9add6f-2949-4539-8980-1ac9f840ff8e	Joice	Penteado Social	50	50	f	2026-10-10	2026-10-08	t	6	2026-10-08 03:31:13.069802+00	1	2	d427bf7e-6389-4439-a247-702414d51391	t
21	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle 	Penteado Social	150	150	f	2026-10-10	2026-10-10	f	7	2026-10-08 03:32:58.581118+00	2	2	d0926d6d-8927-4e50-9a48-02fe79d2f853	f
20	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle 	Penteado Social	50	50	f	2026-10-10	2026-10-06	t	7	2026-10-08 03:32:58.581118+00	1	2	d0926d6d-8927-4e50-9a48-02fe79d2f853	t
23	4c9add6f-2949-4539-8980-1ac9f840ff8e	Noiva Djeice	Noiva	1480	1480	f	2026-10-07	2026-09-19	t	2	2026-10-08 03:38:06.012894+00	1	1	\N	f
25	4c9add6f-2949-4539-8980-1ac9f840ff8e	Glaucia 	Penteado Social	150	150	f	2026-10-10	2026-10-08	f	8	2026-10-08 03:41:00.5384+00	2	2	57505cda-4fd4-4cd4-a4a2-2a029ff3bd89	f
24	4c9add6f-2949-4539-8980-1ac9f840ff8e	Glaucia 	Penteado Social	50	50	f	2026-10-10	2026-10-07	t	8	2026-10-08 03:41:00.5384+00	1	2	57505cda-4fd4-4cd4-a4a2-2a029ff3bd89	t
29	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel	Penteado Social	150	150	f	2026-10-10	2026-10-10	f	9	2026-10-08 03:43:01.408711+00	2	2	c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc	f
28	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel	Penteado Social	50	50	f	2026-10-10	2026-09-15	t	9	2026-10-08 03:43:01.408711+00	1	2	c24d7b4f-c7ff-4a0b-99ae-8e2451c07fcc	t
31	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle Mota	Penteado Social	150	150	f	2026-10-11	2026-10-11	f	10	2026-10-08 03:44:45.672275+00	2	2	a067c6b9-54f1-4b76-a01b-3f0958dd79b9	f
30	4c9add6f-2949-4539-8980-1ac9f840ff8e	Emanuelle Mota	Penteado Social	50	50	f	2026-10-11	2026-09-07	t	10	2026-10-08 03:44:45.672275+00	1	2	a067c6b9-54f1-4b76-a01b-3f0958dd79b9	t
33	4c9add6f-2949-4539-8980-1ac9f840ff8e	Aline souto	Penteado Social	150	150	f	2026-10-11	2026-10-11	f	11	2026-10-08 03:48:35.312252+00	2	2	cd7dfaf3-802e-4bbd-9833-1497f7d76756	f
62	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana Paula	Penteado Social	200	200	f	2026-10-11	2026-10-11	f	18	2026-10-08 04:03:37.897808+00	1	1	\N	f
64	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	150	150	f	2026-10-16	2026-10-16	f	26	2026-10-08 11:07:57.618244+00	2	2	5a0065b4-6f3a-40a6-a0a1-0f14de05eb19	f
32	4c9add6f-2949-4539-8980-1ac9f840ff8e	Aline souto	Penteado Social	50	50	f	2026-10-11	2026-09-30	t	11	2026-10-08 03:48:35.312252+00	1	2	cd7dfaf3-802e-4bbd-9833-1497f7d76756	t
66	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	150	150	f	2026-10-17	2026-10-17	f	27	2026-10-08 11:09:28.757193+00	2	2	530b89e7-284d-415c-9bcc-4f88beeb4332	f
70	4c9add6f-2949-4539-8980-1ac9f840ff8e	Beatriz 	Penteado Social	150	150	f	2026-10-17	2026-10-17	f	29	2026-10-08 11:16:29.27987+00	2	2	0a0fe7f9-af5a-4550-8358-5572e33eecd3	f
72	4c9add6f-2949-4539-8980-1ac9f840ff8e	4 penteado com bel Igarapé 	Penteado Social	600	600	f	2026-10-17	2026-10-17	f	28	2026-10-08 11:18:15.703929+00	2	2	04939b8e-b128-44ba-a664-b04522f82090	f
73	4c9add6f-2949-4539-8980-1ac9f840ff8e	5 penteados com iara	Penteado Social	1000	1000	f	2026-10-18	2026-10-18	f	30	2026-10-08 11:22:34.668625+00	1	1	\N	f
75	4c9add6f-2949-4539-8980-1ac9f840ff8e	Sabrina 	Penteado Social	150	150	f	2026-10-24	2026-10-24	f	31	2026-10-08 11:23:38.097684+00	2	2	81c44ead-e411-441c-8a14-ccab09afdfd9	f
77	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana 	Penteado Social	150	150	f	2026-10-24	2026-10-24	f	33	2026-10-08 11:24:41.576967+00	2	2	8cd64e45-a73d-483b-a112-7da443bea12a	f
79	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana 	Penteado Social	150	150	f	2026-10-24	2026-10-24	f	32	2026-10-08 11:24:41.642093+00	2	2	6f6c88ea-f15b-4109-ab55-16dd56fe3c9e	f
78	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana 	Penteado Social	50	50	f	2026-10-24	2026-09-16	t	32	2026-10-08 11:24:41.642093+00	1	2	6f6c88ea-f15b-4109-ab55-16dd56fe3c9e	t
74	4c9add6f-2949-4539-8980-1ac9f840ff8e	Sabrina 	Penteado Social	50	50	f	2026-10-24	2026-09-21	t	31	2026-10-08 11:23:38.097684+00	1	2	81c44ead-e411-441c-8a14-ccab09afdfd9	t
63	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	50	50	f	2026-10-16	2026-09-23	t	26	2026-10-08 11:07:57.618244+00	1	2	5a0065b4-6f3a-40a6-a0a1-0f14de05eb19	t
65	4c9add6f-2949-4539-8980-1ac9f840ff8e	Penteado com bel 	Penteado Social	50	50	f	2026-10-17	2026-09-23	t	27	2026-10-08 11:09:28.757193+00	1	2	530b89e7-284d-415c-9bcc-4f88beeb4332	t
69	4c9add6f-2949-4539-8980-1ac9f840ff8e	Beatriz 	Penteado Social	50	50	f	2026-10-17	2026-09-23	t	29	2026-10-08 11:16:29.27987+00	1	2	0a0fe7f9-af5a-4550-8358-5572e33eecd3	t
76	4c9add6f-2949-4539-8980-1ac9f840ff8e	Ana 	Penteado Social	50	50	f	2026-10-24	2026-09-16	t	33	2026-10-08 11:24:41.576967+00	1	2	8cd64e45-a73d-483b-a112-7da443bea12a	t
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

SELECT pg_catalog.setval('public.agenda_backups_id_seq', 334, true);


--
-- Name: backup_emails_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.backup_emails_log_id_seq', 1, true);


--
-- Name: demandas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.demandas_id_seq', 34, true);


--
-- Name: financas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.financas_id_seq', 83, true);


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

\unrestrict q8wLaIZzPsRqDDbnLuWjoboJ3L1d3DTWynyUakUwzA8iVKnUsDmfLx8UPAbwBlJ

