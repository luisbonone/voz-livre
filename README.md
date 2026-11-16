# Voz Livre

Protótipo de app para aprender a cantar, para crianças e adultos. Funciona no navegador do computador e do celular, e pode ser instalado como app (PWA).

- **Modo Criança e Adulto**, com escolha de voz grave ou aguda.
- **Teste de voz:** descobre a extensão e a classificação (baixo, tenor, contralto, soprano) e ajusta o tom de todas as aulas.
- **Curso em 5 níveis** (Iniciante, Básico, Intermediário, Avançado, Ministério). Níveis 1 a 3 prontos: 43 aulas com postura, saúde vocal, teoria, treino de ouvido, escalas, apoio, registros e passagem, extensão, ritmo, leitura de cifra e partitura, louvores e provas de nível.
- **Aquecimento do dia** de 5 minutos no tom da voz do aluno, liberadas uma de cada vez, com estrelas e dias seguidos de prática.
- **Canarinho Davi:** personagem que guia as crianças, fala as instruções (voz do navegador), reage à afinação e comemora os acertos.
- **Siga a melodia:** as notas passam na tela e o aluno canta no ritmo; nota de afinação de 0 a 100 em cada exercício e recorde de tempo afinado na nota longa.
- **Louvores** com melodias de hinos em domínio público e letra na tela, sílaba por sílaba: Cristo me ama, Preciosa Graça e Doxologia.
- **Expressão:** dicção (trava-línguas e texto bíblico) e dinâmica (suave e forte, medido pelo microfone).
- **Afinação com microfone:** o app ouve a voz do aluno (Web Audio API, detecção de altura por autocorrelação) e mostra se está acima, abaixo ou na nota.

Tudo está em `index.html`, sem dependências nem etapa de build. Para rodar localmente, sirva a pasta por HTTP (por exemplo `python3 -m http.server`) e abra `http://localhost:8000`. O microfone exige HTTPS ou localhost.

## Contas e painel do professor

O app usa o [Supabase](https://supabase.com) para as contas dos alunos, o progresso salvo na nuvem e o painel do professor.

1. No Supabase, rode `supabase/schema.sql` e depois `supabase/schema_v2_gravacoes.sql` em **SQL Editor**.
2. Para tornar uma conta professor, rode: `update public.profiles set role = 'teacher' where email = 'EMAIL_DO_PROFESSOR';`
3. A URL do projeto e a chave pública (anon) ficam no topo do script em `index.html` (`SUPA_URL` e `SUPA_KEY`).
