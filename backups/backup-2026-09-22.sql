--
-- PostgreSQL database dump
--

\restrict oxE7fGj9h6as6ARHm9wQ5MKDTYwfsxtLUy6FZmVE4ong726rz2bWg3KchOX5uSw

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
    horario time without time zone
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
    created_at timestamp with time zone DEFAULT now() NOT NULL
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
    created_at timestamp with time zone DEFAULT now() NOT NULL
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
161	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-09	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-09T21:05:28.079Z"}	2026-09-09 03:43:44.425257+00
182	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-20	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-21T01:44:05.110Z"}	2026-09-21 00:54:28.522397+00
184	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-09-20	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-21T01:46:43.093Z"}	2026-09-21 01:44:19.568013+00
187	4c9add6f-2949-4539-8980-1ac9f840ff8e	2026-09-21	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-21T14:26:28.472Z"}	2026-09-21 14:26:28.774329+00
131	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-08	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-08T22:47:12.742Z"}	2026-09-08 03:20:38.047247+00
45	1c9718fc-9a24-41fe-8dd7-e863fa6844ce	2026-09-06	{"gastos": [], "demandas": [], "financas": [], "geradoEm": "2026-09-07T00:59:54.321Z"}	2026-09-06 03:11:58.592647+00
\.


--
-- Data for Name: demandas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.demandas (id, user_id, cliente, projeto, etapa, prazo, status, data_gravacao, datas_gravacao, descricao, valor, com_nf, created_at, endereco, no_estudio, quantidade_pessoas, horario) FROM stdin;
\.


--
-- Data for Name: financas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.financas (id, user_id, cliente, projeto, valor, valor_bruto, com_nf, data_trabalho, data_pagamento, pago, origem_demanda_id, created_at) FROM stdin;
\.


--
-- Data for Name: gastos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.gastos (id, user_id, projeto, cliente, descricao, valor, data, created_at) FROM stdin;
\.


--
-- Name: agenda_backups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.agenda_backups_id_seq', 187, true);


--
-- Name: demandas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.demandas_id_seq', 1, false);


--
-- Name: financas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.financas_id_seq', 1, false);


--
-- Name: gastos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.gastos_id_seq', 1, false);


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
-- Name: gastos gastos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos
    ADD CONSTRAINT gastos_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: agenda_backups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agenda_backups ENABLE ROW LEVEL SECURITY;

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

\unrestrict oxE7fGj9h6as6ARHm9wQ5MKDTYwfsxtLUy6FZmVE4ong726rz2bWg3KchOX5uSw

