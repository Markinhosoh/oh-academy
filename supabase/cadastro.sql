-- OH! academy: cadastro de vendedores pelo próprio portal (aba Admin → Acessos da equipe)
-- Cole tudo no SQL Editor do Supabase e clique em Run, uma vez. Pode rodar de novo sem estragar nada.
-- Depois disso o admin cria logins, troca senhas e desativa acessos sem abrir o Supabase.

-- Lista de acessos para o admin: nome, loja, usuário de login e último acesso
create or replace function public.admin_acessos()
returns table (id uuid, nome text, loja text, usuario text, papel text, ativo boolean, ultimo_login timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.eh_admin() then raise exception 'Só o admin pode ver os acessos.'; end if;
  return query
    select p.id, p.nome, p.loja, split_part(u.email::text, '@', 1), p.papel, p.ativo, u.last_sign_in_at
    from public.perfis p join auth.users u on u.id = p.id
    order by p.ativo desc, p.nome;
end;
$$;

-- Cria o login de um vendedor (usuario@ohacademy.app) já confirmado, com nome e loja
create or replace function public.admin_criar_acesso(p_usuario text, p_nome text, p_loja text, p_senha text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid := gen_random_uuid();
  v_usuario text := lower(trim(p_usuario));
  v_email text;
  v_instancia uuid;
begin
  if not public.eh_admin() then raise exception 'Só o admin pode criar acessos.'; end if;
  if v_usuario !~ '^[a-z0-9]+([._-][a-z0-9]+)*$' then raise exception 'Usuário inválido: use letras, números e ponto (ex.: ana.centro).'; end if;
  if coalesce(trim(p_nome), '') = '' then raise exception 'Informe o nome.'; end if;
  if length(coalesce(p_senha, '')) < 6 then raise exception 'A senha precisa ter pelo menos 6 caracteres.'; end if;
  v_email := v_usuario || '@ohacademy.app';
  if exists (select 1 from auth.users where lower(email) = v_email) then raise exception 'O usuário % já existe.', v_usuario; end if;
  select coalesce((select instance_id from auth.users limit 1), '00000000-0000-0000-0000-000000000000') into v_instancia;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) values (
    v_instancia, v_id, 'authenticated', 'authenticated', v_email,
    extensions.crypt(p_senha, extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('nome', trim(p_nome), 'loja', nullif(trim(p_loja), '')),
    now(), now(), '', '', '', ''
  );
  insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  values (gen_random_uuid(), v_id, v_id::text,
    jsonb_build_object('sub', v_id::text, 'email', v_email, 'email_verified', true),
    'email', now(), now(), now());

  -- O gatilho ao_criar_usuario já cria o perfil; aqui garante nome e loja certinhos
  insert into public.perfis (id, nome, loja) values (v_id, trim(p_nome), nullif(trim(p_loja), ''))
  on conflict (id) do update set nome = excluded.nome, loja = excluded.loja;
  return v_id;
end;
$$;

-- Troca a senha de alguém (quando o vendedor esquece)
create or replace function public.admin_trocar_senha(p_id uuid, p_senha text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.eh_admin() then raise exception 'Só o admin pode trocar senhas.'; end if;
  if length(coalesce(p_senha, '')) < 6 then raise exception 'A senha precisa ter pelo menos 6 caracteres.'; end if;
  update auth.users set encrypted_password = extensions.crypt(p_senha, extensions.gen_salt('bf')), updated_at = now()
  where id = p_id;
  if not found then raise exception 'Usuário não encontrado.'; end if;
end;
$$;

-- Só quem está logado chama; dentro de cada função, só o admin passa
revoke all on function public.admin_acessos() from public, anon;
revoke all on function public.admin_criar_acesso(text, text, text, text) from public, anon;
revoke all on function public.admin_trocar_senha(uuid, text) from public, anon;
grant execute on function public.admin_acessos() to authenticated;
grant execute on function public.admin_criar_acesso(text, text, text, text) to authenticated;
grant execute on function public.admin_trocar_senha(uuid, text) to authenticated;
