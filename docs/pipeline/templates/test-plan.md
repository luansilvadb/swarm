---
tipo: plano
resumo: <uma linha: o que este plano prova>
ciclo: <nome-do-ciclo>
estagio: "[[pipeline/stages/verify]]"
status: rascunho
criado: {{date}}
atualizado: {{date}}
depende_de:
  - "[[pipeline/cycles/<nome-do-ciclo>/increment-spec|increment-spec]]"
alimenta:
  - "[[pipeline/cycles/<nome-do-ciclo>/verdict|verdict]]"
tags:
  - pipeline/plano
  - estagio/verify
  - ciclo/<nome-do-ciclo>
---

Escrito pelo modo `plan`, a partir de
![[pipeline/cycles/<nome-do-ciclo>/increment-spec#Critérios de aceite]]

## Resumo

## Verificações

Uma por critério. `V` mapeia para `C`: critério sem verificação é lacuna, e a lacuna vai para a seção abaixo.

- **V1** (C1) — <verificação> · *camada:* unidade | integração | ponta a ponta · *falha quando:* <condição>
- **V2** (C2) — <verificação> · *camada:* · *falha quando:*

## Lacunas

> [!warning] Critérios que não dá para verificar como estão escritos
> - <critério> — <o que o tornaria verificável>
