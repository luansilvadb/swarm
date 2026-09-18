---
tipo: estagio
aliases:
  - discover
tags:
  - pipeline/estagio
  - estagio/discover
---

> [!question] A pergunta única desta etapa
> O que construir, para quem, e o que conta como pronto?

Primeira etapa do pipeline. Transforma um problema em um escopo construível, com critérios afiados o bastante para que as etapas seguintes nunca precisem perguntar o que foi combinado.

## Entra

- Um problema. Pode chegar cru: um ticket, uma reclamação, uma métrica, um objetivo.
- O nome do ciclo, que vira a pasta em `pipeline/cycles/`.
- O repositório, quando ele já tem código. É a única coisa que muda entre greenfield e brownfield: com código existente o `recon` roda, sem ele não há estado atual a descobrir.

## Sai

- `recon.md` — o estado atual, conforme [[pipeline/templates/recon|o template]]. Só quando o repositório já tem código.
- `increment-spec.md` — conforme [[pipeline/templates/increment-spec|o template]].
- `cycle.md` — a nota-hub do ciclo, criada na primeira execução. Sem ela o ciclo não existe no grafo.
- Uma linha em [[pipeline/backlog|backlog]] para cada fatia que ficou de fora, com o motivo.

## Especialistas

| Especialista | Cuida de | Quando roda |
|---|---|---|
| `recon` | O estado atual, o que não pode quebrar, as convenções em vigor | antes de tudo, e só se o repo já tem código |
| `problem-framer` | Quem sofre, a evidência, o custo de não agir | em paralelo com o shaper |
| `solution-shaper` | Incrementos candidatos como fatias verticais, com valor e prioridade | em paralelo com o framer |
| `criteria-writer` | DoR, DoD e critérios de aceite por item | depois do incremento reconciliado |

Um ciclo pequeno dispensa o framer. Um ajuste de uma linha precisa só do `criteria-writer`.

## Arestas

- **Depende de:** nada. É a entrada do pipeline. O `recon` é uma aresta condicional de entrada, não uma etapa.
- **Alimenta:** [[pipeline/stages/build|build]] (via `increment-spec`) e [[pipeline/stages/verify|verify]] no modo `plan`, que roda em paralelo ao build. Alimenta também o [[pipeline/backlog|backlog]] com o que ficou de fora — é o que liga este ciclo aos próximos.
- **Coordenador:** `discover`, acionado por você.
