-- Voz Livre: gravações dos alunos para o professor ouvir e comentar
-- Rode DEPOIS do schema.sql. Cole tudo no SQL Editor > New query > Run.
-- Pode rodar mais de uma vez.

-- tabela das gravações
create table if not exists public.recordings (
  id bigint generated always as identity primary key,
  student_id uuid not null references public.profiles(id) on delete cascade,
  lesson_id text,
  path text not null,
  duration_s real,
  is_exam boolean not null default false,
  created_at timestamptz not null default now(),
  teacher_comment text check (teacher_comment is null or char_length(teacher_comment) <= 1000),
  approved boolean,
  reviewed_at timestamptz
);
create index if not exists recordings_student_idx on public.recordings(student_id, created_at desc);

alter table public.recordings enable row level security;

drop policy if exists "aluno envia gravação" on public.recordings;
create policy "aluno envia gravação" on public.recordings for insert
  with check (student_id = auth.uid() and split_part(path, '/', 1) = auth.uid()::text);
drop policy if exists "aluno vê suas gravações" on public.recordings;
create policy "aluno vê suas gravações" on public.recordings for select using (student_id = auth.uid());
drop policy if exists "aluno apaga sua gravação" on public.recordings;
create policy "aluno apaga sua gravação" on public.recordings for delete using (student_id = auth.uid());
drop policy if exists "professor vê gravações dos alunos" on public.recordings;
create policy "professor vê gravações dos alunos" on public.recordings for select using (public.teaches(student_id));
drop policy if exists "professor comenta gravação" on public.recordings;
create policy "professor comenta gravação" on public.recordings for update
  using (public.teaches(student_id)) with check (public.teaches(student_id));
revoke update on public.recordings from authenticated, anon;
grant update (teacher_comment, approved, reviewed_at) on public.recordings to authenticated;

-- armazenamento dos arquivos de áudio (privado)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('recordings', 'recordings', false, 5242880, array['audio/webm','audio/mp4','audio/ogg','audio/mpeg','audio/aac'])
on conflict (id) do update set public = false, file_size_limit = 5242880,
  allowed_mime_types = array['audio/webm','audio/mp4','audio/ogg','audio/mpeg','audio/aac'];

-- cada aluno grava só na própria pasta; o professor ouve as pastas dos seus alunos
drop policy if exists "aluno envia áudio" on storage.objects;
create policy "aluno envia áudio" on storage.objects for insert to authenticated
  with check (bucket_id = 'recordings' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "aluno e professor ouvem áudio" on storage.objects;
create policy "aluno e professor ouvem áudio" on storage.objects for select to authenticated
  using (bucket_id = 'recordings' and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.teaches(((storage.foldername(name))[1])::uuid)));
drop policy if exists "aluno apaga áudio" on storage.objects;
create policy "aluno apaga áudio" on storage.objects for delete to authenticated
  using (bucket_id = 'recordings' and (storage.foldername(name))[1] = auth.uid()::text);
