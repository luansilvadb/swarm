---
tipo: home
aliases:
  - Home
tags:
  - pipeline/home
---

# Pipeline de desenvolvimento

> [!abstract] Um ciclo por incremento entregável
> [[pipeline/stages/discover|discover]] → [[pipeline/stages/build|build]] → [[pipeline/stages/verify|verify]]. Cada etapa tem um coordenador que despacha seus especialistas.

## Navegação

- [[pipeline/paradigm|Paradigma]] — as três regras que geram o pipeline, e o que ele recusa
- [[pipeline/contract|Contrato do pipeline]] — fronteiras das etapas, artefatos de handoff e o formato de toda nota deste vault
- [[pipeline/backlog|Backlog]] — a memória do que foi adiado; a única nota que atravessa ciclos
- [[pipeline/stages/discover|discover]] · [[pipeline/stages/build|build]] · [[pipeline/stages/verify|verify]]
- Templates em `pipeline/templates/` — configure o plugin core **Templates** para apontar para essa pasta

## Como abrir

Vault = esta pasta (`docs/`). O melhor filtro do graph view é `-path:templates`, para os templates não entrarem no grafo.

## Ciclos

Cada ciclo é uma pasta em `pipeline/cycles/` com uma nota-hub `cycle.md`. É a **nota-hub**, não a pasta, que aparece no grafo — pasta não é nó.

A aba de tags (`#pipeline/ciclo`) lista todos os ciclos:

```
#pipeline/ciclo
```
