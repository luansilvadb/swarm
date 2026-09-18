---
tipo: veredito
resumo: <uma linha: o veredito e o que o sustenta>
ciclo: <nome-do-ciclo>
estagio: "[[pipeline/stages/verify]]"
status: rascunho
criado: {{date}}
atualizado: {{date}}
depende_de:
  - "[[pipeline/cycles/<nome-do-ciclo>/increment-spec|increment-spec]]"
  - "[[pipeline/cycles/<nome-do-ciclo>/build-report|build-report]]"
  - "[[pipeline/cycles/<nome-do-ciclo>/test-plan|test-plan]]"
alimenta: []
tags:
  - pipeline/veredito
  - estagio/verify
  - ciclo/<nome-do-ciclo>
---

> [!success] Ship
> ou
> [!danger] Não ship

Troque o callout acima pelo veredito real. Uma palavra, sem hedge — "provavelmente ok" não é veredito.

## Resumo

## Veredito

A palavra, e o que a sustenta em três linhas.

## Evidência

Resultado de cada verificação do [[pipeline/cycles/<nome-do-ciclo>/test-plan|plano]]. Falha é registrada como falha; verificação pulada é registrada como pulada, com o motivo.

| Verificação | Resultado | Comando |
|---|---|---|
| V1 | | |

> [!quote] Saída relevante
> cole aqui a saída bruta que importa

## Achados da revisão

Cada achado: o que é, onde, por que importa, confiança. Depois do veredito, o que foi corrigido e o que foi aceito com o motivo.

- 

## Definition of Done

Item por item: atendido, não atendido, ou não aplicável — com o que estabelece isso. Não checado não é atendido.

| Item | Situação | O que estabelece |
|---|---|---|
| | | |

## Rollback

Como isto sai, e em quanto tempo. "Reverteríamos" só é resposta onde reverter é de fato seguro.

## Aberto

> [!todo] Aceito em aberto
> - 
