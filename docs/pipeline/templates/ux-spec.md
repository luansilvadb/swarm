---
tipo: ux
resumo: <uma linha: o que o usuário faz e vê neste incremento>
ciclo: <nome-do-ciclo>
estagio: "[[pipeline/stages/discover]]"
status: rascunho
criado: {{date}}
atualizado: {{date}}
depende_de: []
alimenta:
  - "[[pipeline/cycles/<nome-do-ciclo>/increment-spec|increment-spec]]"
  - "[[pipeline/cycles/<nome-do-ciclo>/build-report|build-report]]"
tags:
  - pipeline/ux
  - estagio/discover
  - ciclo/<nome-do-ciclo>
---

> [!question] Só existe quando o incremento tem interface de usuário
> O que o usuário faz, o que ele vê em cada estado, e o que ele lê.

Nasce da mesma reconciliação que o `increment-spec`, e vem antes dele: os estados daqui viram critérios de aceite lá.

## Resumo

## Fluxo

## Estados

Um por coisa que o usuário vê. Cada linha vira critério de aceite — nomeie o caso que falha.

| Estado | O que o usuário vê | Falha quando |
|---|---|---|
| vazio | | |
| carregando | | |
| completo | | |
| parcial | | |
| erro | | |

## O que o usuário lê

## Acessibilidade

## O que o usuário nunca deve ver
