---
tipo: backlog
aliases:
  - Backlog
resumo: A memória do que foi adiado, por quê, e em que ciclo entrou.
status: ativo
criado: 2026-09-18
atualizado: 2026-09-18
tags:
  - pipeline/backlog
---

A única nota que atravessa ciclos. Cada ciclo lê daqui antes de cortar escopo e escreve aqui o que adiou. É esta nota — não as etapas — que liga ciclo → ciclo no grafo.

## Como usar

- O [[pipeline/stages/discover|discover]] **lê** antes de reconciliar: o que já está adiado muda o que vale a pena cortar de novo.
- O [[pipeline/stages/discover|discover]] **escreve** aqui todo não-objetivo que decidiu deixar de fora, com o motivo. Não-objetivo que não chega nesta nota é trabalho que vai ser re-descartado daqui a três ciclos.
- O [[pipeline/stages/verify|verify]] **escreve** aqui o que o veredito aceitou em aberto.

## Aberto

| Item | Entrou em | Por que ficou de fora | Espera por |
|---|---|---|---|
| — | — | — | — |

## Concluído

| Item | Entrou em | Saiu em |
|---|---|---|
| — | — | — |
