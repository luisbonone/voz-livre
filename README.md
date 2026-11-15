# Voz Livre

Protótipo de app para aprender a cantar, para crianças e adultos. Funciona no navegador do computador e do celular, e pode ser instalado como app (PWA).

- **Modo Criança e Adulto**, com escolha de voz grave ou aguda.
- **Trilha de 14 aulas** em 3 unidades (Fundamentos, Afinação, Cantando louvores), liberadas uma de cada vez, com estrelas e dias seguidos de prática.
- **Canarinho Davi:** personagem que guia as crianças, fala as instruções (voz do navegador), reage à afinação e comemora os acertos.
- **Siga a melodia:** as notas passam na tela e o aluno canta no ritmo; nota de afinação de 0 a 100 em cada exercício e recorde de tempo afinado na nota longa.
- **Louvores** com melodias de hinos em domínio público.
- **Afinação com microfone:** o app ouve a voz do aluno (Web Audio API, detecção de altura por autocorrelação) e mostra se está acima, abaixo ou na nota.

Tudo está em `index.html`, sem dependências nem etapa de build. Para rodar localmente, sirva a pasta por HTTP (por exemplo `python3 -m http.server`) e abra `http://localhost:8000`. O microfone exige HTTPS ou localhost.
