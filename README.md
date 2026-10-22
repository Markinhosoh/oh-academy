# OH! academy

Portal de estudos da **Escola de Vendas OH! Ótica**: trilha gamificada em 8 módulos para os vendedores das lojas OH! e parceiras.

## Situação

Fase 2: login individual, progresso, desbloqueio e XP salvos no Supabase (plano grátis). O painel Admin mostra os dados reais da equipe: tempo em cada passo, cliques nos visuais, quanto do podcast foi ouvido e notas do quiz. O Módulo 1 é o único montado; Biblioteca e Extras ainda usam a lista fixa.

Próximas fases:

1. Painel admin: subir materiais (PDF, áudio, vídeo do YouTube) e ver tempo e cliques de cada vendedor.
3. Conteúdo dos módulos 2 a 8, aos poucos, com piloto de 3 a 4 vendedores.
4. Lançamento, um módulo por semana.

## Publicação

Site estático no GitHub Pages: Settings → Pages → Deploy from a branch → `main` / `(root)`.

## Supabase

- `supabase/schema.sql`: cria tabelas, regras de acesso e a pasta privada `materiais`. Rode no SQL Editor do Supabase.
- Login: cada pessoa é cadastrada em Authentication → Users como `usuario@ohacademy.app`; no portal digita só `usuario`.
- Admin: `update public.perfis set papel = 'admin' where ...` (ver o guia).
- Podcast do Módulo 1: enviar `podcast-cultura-oh.mp3` para Storage → `materiais/m1/`. Sem ele, o player usa uma reprodução simulada.

## Arquivos

- `index.html`: o portal (HTML, CSS e JS num arquivo só). Visual escuro no estilo do app de metas da OH!: destaque grande no topo, fileiras de capas estilo Netflix e barra de abas embaixo.
- `assets/`: imagens usadas nas capas.
- `supabase/schema.sql`: estrutura do banco.
- `manifest.webmanifest` e `icons/`: permitem instalar o portal no celular como app.
