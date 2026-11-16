-- Voz Livre: banco de dados do painel do professor
-- Cole TUDO no Supabase: SQL Editor > New query > Run.
-- Pode rodar mais de uma vez sem problema.

-- ============ TABELAS ============

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default '',
  role text not null default 'student' check (role in ('student','teacher')),
  class_id uuid,
  is_minor boolean not null default false,
  guardian_name text,
  guardian_consent_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  code text not null unique,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.profiles
    add constraint profiles_class_fk foreign key (class_id) references public.classes(id) on delete set null;
exception when duplicate_object then null; end $$;

create table if not exists public.progress (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  done jsonb not null default '{}'::jsonb,
  scores jsonb not null default '{}'::jsonb,
  streak jsonb not null default '{}'::jsonb,
  vt jsonb,
  mode text,
  last_lesson text,
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id bigint generated always as identity primary key,
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);

-- ============ FUNÇÕES AUXILIARES ============

-- cria o perfil automaticamente quando alguém se cadastra
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  insert into public.progress (user_id) values (new.id) on conflict do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.is_teacher()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'teacher');
$$;

-- o usuário logado é professor da turma deste aluno?
create or replace function public.teaches(student uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles p join classes c on c.id = p.class_id
    where p.id = student and c.teacher_id = auth.uid()
  );
$$;

-- aluno entra na turma pelo código; devolve o nome da turma
create or replace function public.join_class(class_code text)
returns text language plpgsql security definer set search_path = public as $$
declare c record;
begin
  select id, name into c from classes where upper(code) = upper(trim(class_code));
  if not found then raise exception 'Código de turma não encontrado'; end if;
  update profiles set class_id = c.id where id = auth.uid();
  return c.name;
end $$;

-- professor cria turma com código aleatório de 6 letras
create or replace function public.create_class(class_name text)
returns table (id uuid, name text, code text) language plpgsql security definer set search_path = public as $$
#variable_conflict use_column
declare new_code text; i int;
begin
  if not public.is_teacher() then raise exception 'Apenas professores podem criar turmas'; end if;
  loop
    new_code := '';
    for i in 1..6 loop
      new_code := new_code || substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + floor(random()*32)::int, 1);
    end loop;
    exit when not exists (select 1 from classes c where c.code = new_code);
  end loop;
  return query insert into classes (teacher_id, name, code)
    values (auth.uid(), class_name, new_code) returning classes.id, classes.name, classes.code;
end $$;

-- ============ SEGURANÇA (RLS) ============

alter table public.profiles enable row level security;
alter table public.classes  enable row level security;
alter table public.progress enable row level security;
alter table public.messages enable row level security;

-- perfis
drop policy if exists "ver o próprio perfil" on public.profiles;
create policy "ver o próprio perfil" on public.profiles for select using (id = auth.uid());
drop policy if exists "professor vê seus alunos" on public.profiles;
create policy "professor vê seus alunos" on public.profiles for select using (public.teaches(id));
drop policy if exists "editar o próprio perfil" on public.profiles;
create policy "editar o próprio perfil" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
-- o aluno só pode mudar estes campos (não pode virar professor nem trocar de turma direto)
revoke update on public.profiles from authenticated, anon;
grant update (full_name, is_minor, guardian_name, guardian_consent_at) on public.profiles to authenticated;

-- turmas
drop policy if exists "professor vê suas turmas" on public.classes;
create policy "professor vê suas turmas" on public.classes for select using (teacher_id = auth.uid());
drop policy if exists "aluno vê a própria turma" on public.classes;
create policy "aluno vê a própria turma" on public.classes for select
  using (id = (select class_id from public.profiles where id = auth.uid()));
drop policy if exists "professor apaga suas turmas" on public.classes;
create policy "professor apaga suas turmas" on public.classes for delete using (teacher_id = auth.uid());

-- progresso
drop policy if exists "aluno lê o próprio progresso" on public.progress;
create policy "aluno lê o próprio progresso" on public.progress for select using (user_id = auth.uid());
drop policy if exists "aluno salva o próprio progresso" on public.progress;
create policy "aluno salva o próprio progresso" on public.progress for insert with check (user_id = auth.uid());
drop policy if exists "aluno atualiza o próprio progresso" on public.progress;
create policy "aluno atualiza o próprio progresso" on public.progress for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "professor vê progresso dos alunos" on public.progress;
create policy "professor vê progresso dos alunos" on public.progress for select using (public.teaches(user_id));

-- recados
drop policy if exists "professor envia recado" on public.messages;
create policy "professor envia recado" on public.messages for insert
  with check (teacher_id = auth.uid() and public.teaches(student_id));
drop policy if exists "ver recados" on public.messages;
create policy "ver recados" on public.messages for select using (teacher_id = auth.uid() or student_id = auth.uid());
drop policy if exists "aluno marca como lido" on public.messages;
create policy "aluno marca como lido" on public.messages for update using (student_id = auth.uid()) with check (student_id = auth.uid());
drop policy if exists "professor apaga recado" on public.messages;
create policy "professor apaga recado" on public.messages for delete using (teacher_id = auth.uid());
revoke update on public.messages from authenticated, anon;
grant update (read_at) on public.messages to authenticated;

grant execute on function public.join_class(text), public.create_class(text), public.is_teacher(), public.teaches(uuid) to authenticated;
revoke execute on function public.join_class(text), public.create_class(text) from anon;
