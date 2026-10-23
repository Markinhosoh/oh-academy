# OH! academy

Portal de estudos da **Escola de Vendas OH! Ótica**: trilha gamificada em 8 módulos para os vendedores das lojas OH! e parceiras.

## Situação

Login individual, progresso, desbloqueio e XP salvos no Supabase (plano grátis). Os 8 módulos têm materiais (19 no total), todos no formato do "Propósito no Balcão": leia, ouça o podcast ou treine no balcão, reflita. Cada material libera depois do anterior e vale 50 XP; concluir todos os materiais de um módulo dá +100 XP, a medalha e libera o próximo módulo. O painel Admin mostra, material por material, tempo, cliques nos visuais e quanto do podcast foi ouvido.

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
- Podcasts: ficam na pasta privada Storage → `materiais`, com o mesmo nome usado na página do material:
  - `m1/podcast-cultura-oh.mp3`, `m1/podcast-psicologia-atendimento.mp3`, `m1/podcast-autoimagem-vendedor.mp3`
  - `m2/podcast-corpo-vende.mp3`, `m3/podcast-investigando-necessidades.mp3`, `m4/podcast-formato-de-vida.mp3`
  - Os módulos 5 a 8 ainda não têm podcast; os materiais deles usam o treino de balcão na etapa 2.

  Enquanto um MP3 não estiver lá, o material avisa que o áudio ainda está chegando.

## Arquivos

- `index.html`: o portal (HTML, CSS e JS num arquivo só). Visual escuro no estilo do app de metas da OH!: destaque grande no topo, fileiras de capas estilo Netflix e barra de abas embaixo.
- `materiais/mN/material-K.html`: as páginas dos materiais. O portal abre cada uma em tela cheia; `materiais/ponte.js` liga a página ao portal (progresso por pessoa, XP, podcast do Supabase e registro de uso). A lista dos materiais fica em `MATS`, no `index.html`.
- `extras/resenhas/`: resenhas do Clube de Leitura OH! (PDF + capa em webp), listadas em `EXT` na aba Extras.
- `assets/`: imagens usadas nas capas.
- `supabase/schema.sql`: estrutura do banco.
- `manifest.webmanifest` e `icons/`: permitem instalar o portal no celular como app.
