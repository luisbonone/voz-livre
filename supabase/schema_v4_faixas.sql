-- Voz Livre: faixas etárias (Criança, Jovem, Adulto)
-- Rode uma vez no Supabase: SQL Editor > New query > cole tudo > Run.
-- Pode rodar de novo sem problema.

-- Data de nascimento do aluno e faixa escolhida pelo professor (vazia = automática pela idade)
alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists age_band text;
do $$ begin
  alter table public.profiles add constraint profiles_age_band_chk check (age_band in ('kid','teen','adult'));
exception when duplicate_object then null; end $$;

-- O aluno pode gravar a própria data de nascimento (a faixa ele não pode mudar)
grant update (full_name, is_minor, guardian_name, guardian_consent_at, birth_date) on public.profiles to authenticated;

-- O professor muda a faixa só dos alunos das turmas dele
create or replace function public.set_student_band(student uuid, band text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.teaches(student) then
    raise exception 'Apenas o professor da turma pode mudar a faixa do aluno';
  end if;
  if band is not null and band not in ('kid','teen','adult') then
    raise exception 'Faixa inválida';
  end if;
  update profiles set age_band = band where id = student;
end $$;
revoke execute on function public.set_student_band(uuid, text) from public, anon;
grant execute on function public.set_student_band(uuid, text) to authenticated;
