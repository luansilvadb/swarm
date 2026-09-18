---
tipo: estagio
aliases:
  - verify
tags:
  - pipeline/estagio
  - estagio/verify
---

> [!question] A pergunta única desta etapa
> O incremento atende aos critérios, e pode ser entregue?

Terceira etapa do pipeline, em **dois modos** que entram em momentos diferentes. É a única etapa com duas entradas, e é isso que a torna parcialmente paralela.

## Modo `plan`

- **Quando:** logo depois do [[pipeline/stages/discover|discover]], em paralelo com o [[pipeline/stages/build|build]].
- **Entra:** só o `increment-spec`.
- **Sai:** `test-plan.md` — conforme [[pipeline/templates/test-plan|o template]].
- **Especialista:** `test-designer`, sozinho.

A prova deriva dos critérios, nunca do código. É por isso que este modo não espera o código existir — se o desenhista precisasse do código para decidir o que testar, os critérios estariam fracos, e isso é um achado, não uma lacuna a disfarçar.

## Modo `gate`

- **Quando:** depois do build.
- **Entra:** o spec, o plano de teste e o `build-report`.
- **Sai:** `verdict.md` — conforme [[pipeline/templates/verdict|o template]].
- **Especialistas:** `test-executor`, `code-reviewer` e `release-guard`, os três em paralelo — leem material diferente e nenhum lê a saída do outro.

Quando eles discordam — plano verde contra uma revisão que achou um defeito real — **a revisão vence**. Teste passando prova que os critérios foram checados, não que o incremento está certo.

## Especialistas

| Especialista | Cuida de | Modo |
|---|---|---|
| `test-designer` | As verificações que provariam cada critério, desenhadas a partir do spec | `plan` |
| `test-executor` | Executá-las e registrar a evidência | `gate` |
| `code-reviewer` | O incremento lido como código: defeitos, riscos, quebras de convenção | `gate` |
| `release-guard` | Se o DoD foi cumprido, e o que exatamente sai | `gate` |

## Arestas

- **Depende de:** [[pipeline/stages/discover|discover]] (modo `plan`) e [[pipeline/stages/build|build]] (modo `gate`).
- **Alimenta:** você, via `verdict.md`, e o [[pipeline/backlog|backlog]], com o que o veredito aceitou em aberto. A etapa **Release** ainda não existe.
- **Coordenador:** `verify`, acionado por você. Sem modo informado, ele infere: sem `build-report`, é `plan`.

> [!warning] Esta etapa não conserta
> Um defeito volta para você como achado. `verify` que edita o incremento deixa de ser confiável para julgá-lo.
