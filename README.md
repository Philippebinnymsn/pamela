# Painel de Atendimentos — Pâmela Mees Penteados

App de gestao de atendimentos, agenda e financeiro, para negocio de beleza.
Construido a partir da mesma base (React + Supabase) do painel do Norman,
com layout, cores e terminologia proprios.

## 1. Configure um Supabase NOVO (projeto proprio, independente)

1. Crie uma conta gratis em supabase.com e um projeto NOVO (nao use o mesmo
   projeto do Norman - os dados devem ficar completamente separados).
2. Va em "SQL Editor" -> "New query", cole o conteudo de supabase-setup.sql
   (nesta pasta) e clique em Run. Isso cria as 4 tabelas de uma vez.
3. Va em "Project Settings" -> "API", copie o "Project URL" e a chave
   "anon public".
4. Copie o arquivo .env.example para um novo arquivo chamado .env, e cole
   os dois valores.

## 2. Testar no computador

npm install
npm run dev

## 3. Login

Nao ha usuario/senha fixos - a tela inicial tem "Entrar" e "Criar conta".
Crie uma conta com o e-mail que a Pamela for usar.

## 4. Publicar (Vercel)

Mesmo processo do outro projeto: GitHub -> Vercel -> Add New Project ->
configurar as duas variaveis de ambiente (VITE_SUPABASE_URL e
VITE_SUPABASE_ANON_KEY) -> Deploy.

## 5. O que e diferente do painel do Norman

- Visual: fundo claro (marfim), tipografia Manrope, cor de destaque vinho
  (#7A2E3D) no lugar do preto com amarelo/vermelho/verde.
- Termos: "Atendimentos" no lugar de "Demandas", etapas adaptadas
  (Consulta, Planejamento, Atendimento, Pos-atendimento, Retorno,
  Finalizado), "Servico" no lugar de "Projeto".
- Logo: um monograma "PM" em CSS, ja que ainda nao existe uma logo real da
  marca. Quando tiver uma logo de verdade, troque o bloco marcado com "PM"
  em src/App.jsx por uma tag <img>.
- Toda a logica (Supabase, calculo de status, exportacao em PDF, backup
  diario, exclusao com confirmacao) e identica ao painel original.

## Estrutura

src/
  App.jsx            -> todo o painel
  supabaseClient.js   -> conexao com o banco de dados (deste projeto Supabase)
  main.jsx
  index.css
supabase-setup.sql    -> script unico para criar todo o banco
