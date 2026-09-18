---
tipo: paradigma
aliases:
  - Paradigma
resumo: Três regras geram o pipeline inteiro — contrato, nó, evidência. O resto é consequência.
status: pronto
criado: 2026-09-18
atualizado: 2026-09-18
tags:
  - pipeline/paradigma
---

Três regras geram tudo o que este pipeline faz. Onze pedidos foram reduzidos a elas — Scrum, spec-driven, wiki, Obsidian, grafo, TDD, orquestrador, especialistas, RAG, greenfield, brownfield. O resto é consequência, e tratar consequência como item de checklist é o overhead que este paradigma existe para evitar.

## As três regras

### 1. O contrato precede o trabalho

Todo artefato é um contrato. O spec é o contrato com quem pediu; os critérios de aceite, com quem verifica; o plano de teste, com a prova; o veredito, com o release. Nada é construído antes do contrato que o governa existir — e isso vale igualmente para o código: a verificação de um item nasce antes do código do item.

Daqui saem spec-driven development, TDD e a wiki. São a mesma regra em altitudes diferentes.

### 2. Um nó, uma pergunta

Etapa, coordenador, especialista e tipo de nota respondem cada um exatamente **uma** pergunta. Um nó que responde duas vira dois nós no grafo e nenhum na cabeça de quem lê.

Daqui saem a estrutura de orquestrador e especialistas, a responsabilidade única, a legibilidade do grafo — e a precisão da recuperação: nó com uma pergunta tem metadados limpos.

### 3. O ciclo fecha por evidência

Não por calendário. O ciclo começa quando um problema entra e termina quando o veredito diz *ship* com evidência anexada. Nenhuma data fecha o ciclo, nenhuma cerimônia o move.

Daqui saem o incremento, o DoR/DoD e a aresta de retroalimentação: o que não foi atendido volta para o backlog e alimenta o próximo corte de escopo.

## De onde cada pedido foi absorvido

| Pedido | Onde vive |
|---|---|
| Scrum | regra 3 — incremento, DoR/DoD, ciclo. O timebox morreu. |
| Spec-driven | regra 1 — o spec precede o trabalho |
| TDD | regra 1, dentro do `build`: vermelho → verde, por verificação |
| Wiki | regra 1 — o contrato mora numa nota |
| Obsidian | o substrato onde as notas vivem |
| Grafo | regra 2 — as arestas são `estagio`, `depende_de`, `alimenta` |
| Orquestrador / líder | regra 2 — o coordenador é o líder da etapa |
| Especialistas | regra 2 — cada especialista é um nó |
| RAG | consumidor da regra 1 — o vault *é* o corpus |
| Greenfield | aresta condicional: sem código existente, o `recon` não roda |
| Brownfield | aresta condicional: com código existente, o `recon` roda e o spec nasce ancorado |

## O que o paradigma recusa

Overhead é o que sobra quando o paradigma não sabe dizer não.

- **Cerimônia sem artefato.** Daily, velocity, burndown, planning poker. Os gates deste pipeline produzem nota; reunião que não produz não existe.
- **Papel sem pergunta própria.** Você é o product owner e o stakeholder; o coordenador é o líder técnico da etapa; os especialistas são o time. Não existe agente de Scrum Master.
- **Documento sem consumidor.** Nada de documento "para depois" — o que ninguém lê não é escrito.
- **Timebox.** O ciclo fecha por evidência, não por data.
- **Fork greenfield/brownfield.** Uma aresta condicional, não dois pipelines.
- **Reformatar a wiki para a IA.** O vault *é* o corpus. Duas formatações são duas verdades.

## Onde isto é aplicado

- [[pipeline/contract|Contrato]] — as fronteiras, os artefatos e o formato que sustentam as três regras
- [[pipeline/backlog|Backlog]] — a aresta ciclo → ciclo
- [[pipeline/stages/discover|discover]] · [[pipeline/stages/build|build]] · [[pipeline/stages/verify|verify]]
