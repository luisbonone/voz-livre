-- Voz Livre: o professor libera as aulas e passa a tarefa da semana para a turma
-- Rode DEPOIS do schema.sql. Cole tudo no SQL Editor > New query > Run.
-- Pode rodar mais de uma vez.

alter table public.classes add column if not exists guided boolean not null default true;   -- true = o professor libera as aulas
alter table public.classes add column if not exists released text[] not null default '{}'; -- aulas liberadas
alter table public.classes add column if not exists homework jsonb;                        -- tarefa da semana

-- o professor pode editar só as próprias turmas, e só estes campos
drop policy if exists "professor edita suas turmas" on public.classes;
create policy "professor edita suas turmas" on public.classes for update
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
revoke update on public.classes from authenticated, anon;
grant update (name, guided, released, homework) on public.classes to authenticated;
