-- OH! academy: estrutura do banco no Supabase
-- Cole tudo no SQL Editor e clique em Run. Pode rodar de novo sem estragar nada.

-- 1. Perfis: um por funcionário (nome, loja e papel)
create table if not exists public.perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  loja text,
  papel text not null default 'vendedor' check (papel in ('vendedor', 'admin')),
  ativo boolean not null default true,
  criado_em timestamptz not null default now()
);

-- Diz se quem está logado é admin (usado nas regras de acesso abaixo)
create or replace function public.eh_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfis where id = auth.uid() and papel = 'admin' and ativo);
$$;

-- Cria o perfil sozinho quando um usuário é cadastrado em Authentication
create or replace function public.novo_usuario()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.perfis (id, nome, loja)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'loja'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists ao_criar_usuario on auth.users;
create trigger ao_criar_usuario after insert on auth.users
  for each row execute function public.novo_usuario();

-- Perfis de usuários já cadastrados antes deste script
insert into public.perfis (id, nome)
select id, split_part(email, '@', 1) from auth.users
on conflict (id) do nothing;

-- 2. Progresso: cada passo concluído (aula, áudio, quiz) e o XP ganho
create table if not exists public.progresso (
  usuario_id uuid not null default auth.uid() references public.perfis(id) on delete cascade,
  modulo int not null check (modulo between 1 and 8),
  passo text not null,
  xp int not null default 0,
  nota int,
  concluido_em timestamptz not null default now(),
  primary key (usuario_id, modulo, passo)
);

-- 3. Eventos: tempo em cada material e cliques em visuais e áudios (relatório do admin)
create table if not exists public.eventos (
  id bigint generated always as identity primary key,
  usuario_id uuid not null default auth.uid() references public.perfis(id) on delete cascade,
  tipo text not null,
  modulo int,
  material text,
  segundos int,
  dados jsonb,
  criado_em timestamptz not null default now()
);
create index if not exists eventos_usuario_idx on public.eventos (usuario_id, criado_em);

-- 4. Conteúdos de cada módulo (PDF, áudio, vídeo do YouTube, resumo)
create table if not exists public.conteudos (
  id uuid primary key default gen_random_uuid(),
  modulo int not null check (modulo between 1 and 8),
  tipo text not null check (tipo in ('pdf', 'audio', 'video', 'resumo')),
  titulo text not null,
  descricao text,
  arquivo text,
  link text,
  ordem int not null default 0,
  publicado boolean not null default true,
  criado_em timestamptz not null default now()
);

-- 5. Links extras (notícias, sites, YouTube, materiais complementares)
create table if not exists public.links_extras (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  link text not null,
  categoria text not null default 'site' check (categoria in ('noticia', 'site', 'video', 'material')),
  descricao text,
  publicado boolean not null default true,
  criado_em timestamptz not null default now()
);

-- 6. Regras de acesso: cada vendedor vê só o que é dele; o admin vê tudo
alter table public.perfis enable row level security;
alter table public.progresso enable row level security;
alter table public.eventos enable row level security;
alter table public.conteudos enable row level security;
alter table public.links_extras enable row level security;

drop policy if exists "ver perfil" on public.perfis;
create policy "ver perfil" on public.perfis for select to authenticated
  using (id = auth.uid() or public.eh_admin());
drop policy if exists "admin edita perfis" on public.perfis;
create policy "admin edita perfis" on public.perfis for update to authenticated
  using (public.eh_admin()) with check (public.eh_admin());

drop policy if exists "ver progresso" on public.progresso;
create policy "ver progresso" on public.progresso for select to authenticated
  using (usuario_id = auth.uid() or public.eh_admin());
drop policy if exists "registrar progresso" on public.progresso;
create policy "registrar progresso" on public.progresso for insert to authenticated
  with check (usuario_id = auth.uid());

drop policy if exists "ver eventos" on public.eventos;
create policy "ver eventos" on public.eventos for select to authenticated
  using (usuario_id = auth.uid() or public.eh_admin());
drop policy if exists "registrar eventos" on public.eventos;
create policy "registrar eventos" on public.eventos for insert to authenticated
  with check (usuario_id = auth.uid());

drop policy if exists "ver conteudos" on public.conteudos;
create policy "ver conteudos" on public.conteudos for select to authenticated
  using (publicado or public.eh_admin());
drop policy if exists "admin gerencia conteudos" on public.conteudos;
create policy "admin gerencia conteudos" on public.conteudos for all to authenticated
  using (public.eh_admin()) with check (public.eh_admin());

drop policy if exists "ver links" on public.links_extras;
create policy "ver links" on public.links_extras for select to authenticated
  using (publicado or public.eh_admin());
drop policy if exists "admin gerencia links" on public.links_extras;
create policy "admin gerencia links" on public.links_extras for all to authenticated
  using (public.eh_admin()) with check (public.eh_admin());

-- 7. Pasta privada de arquivos (PDFs e áudios): só quem tem login baixa, só o admin sobe
insert into storage.buckets (id, name, public)
values ('materiais', 'materiais', false)
on conflict (id) do nothing;

drop policy if exists "equipe baixa materiais" on storage.objects;
create policy "equipe baixa materiais" on storage.objects for select to authenticated
  using (bucket_id = 'materiais');
drop policy if exists "admin sobe materiais" on storage.objects;
create policy "admin sobe materiais" on storage.objects for insert to authenticated
  with check (bucket_id = 'materiais' and public.eh_admin());
drop policy if exists "admin altera materiais" on storage.objects;
create policy "admin altera materiais" on storage.objects for update to authenticated
  using (bucket_id = 'materiais' and public.eh_admin());
drop policy if exists "admin apaga materiais" on storage.objects;
create policy "admin apaga materiais" on storage.objects for delete to authenticated
  using (bucket_id = 'materiais' and public.eh_admin());
