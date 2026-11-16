-- Voz Livre: desativar e remover alunos da turma
-- Rode uma vez no Supabase: SQL Editor > New query > cole tudo > Run.
-- Pode rodar de novo sem problema.

-- Quando preenchido, o aluno está desativado (o progresso continua guardado)
alter table public.profiles add column if not exists deactivated_at timestamptz;

-- Professor desativa ou reativa um aluno da turma dele
create or replace function public.set_student_active(student uuid, active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.teaches(student) then
    raise exception 'Apenas o professor da turma pode desativar o aluno';
  end if;
  update profiles set deactivated_at = case when active then null else now() end where id = student;
end $$;

-- Professor remove um aluno da turma dele (a conta e o progresso do aluno continuam existindo)
create or replace function public.remove_student(student uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.teaches(student) then
    raise exception 'Apenas o professor da turma pode remover o aluno';
  end if;
  update profiles set class_id = null, deactivated_at = null where id = student;
end $$;

revoke execute on function public.set_student_active(uuid, boolean), public.remove_student(uuid) from public, anon;
grant execute on function public.set_student_active(uuid, boolean), public.remove_student(uuid) to authenticated;
