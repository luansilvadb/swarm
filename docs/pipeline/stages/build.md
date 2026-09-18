---
tipo: estagio
aliases:
  - build
tags:
  - pipeline/estagio
  - estagio/build
---

> [!question] A pergunta única desta etapa
> Como o incremento é construído, com estrutura sólida e conforme os critérios?

Segunda etapa do pipeline. Consome o spec e produz um incremento funcionando, mais as decisões estruturais que um leitor futuro teria de deduzir do diff.

## Entra

- `increment-spec.md` do ciclo. Sem ele, a etapa para: o ciclo não passou pelo [[pipeline/stages/discover|discover]], e construir a partir de um resumo verbal é como os critérios se perdem.
- `recon.md`, quando existe. As convenções em vigor descem para cada implementer — uma segunda convenção ao lado da primeira é a coisa mais cara que esta etapa pode produzir.
- `ux-spec.md`, quando existe. Os estados já são critérios; o `ui-designer` decide como apresentá-los, nunca quais existem.
- O repositório. Os especialistas trabalham nele diretamente.

## Sai

- `build-report.md` — conforme [[pipeline/templates/build-report|o template]].

## Especialistas

| Especialista | Cuida de | Quando roda |
|---|---|---|
| `architect` | Decisões estruturais e as alternativas rejeitadas | primeiro, lendo só o spec |
| `contract-designer` | O contrato na fronteira que o incremento toca | junto do architect, e só se há fronteira |
| `ui-designer` | Composição, componentes e adesão ao sistema de design | depois da estrutura, e só se há interface de usuário |
| `implementer` | Um item de backlog, até os critérios dele | em leque, um por item, todos juntos |

O leque é o ponto: os itens são independentes por construção — o `discover` cortou assim — então um não espera o outro.

Cada implementer roda o laço do TDD dentro do seu item: escreve a verificação, vê falhar, depois faz passar. O primeiro vermelho vai para o `build-report` — é a única evidência de que a verificação consegue falhar.

## Arestas

- **Depende de:** [[pipeline/stages/discover|discover]], via `increment-spec`.
- **Alimenta:** [[pipeline/stages/verify|verify]] no modo `gate`. Não alimenta o modo `plan`, que já rodou.
- **Coordenador:** `build`, acionado por você.
