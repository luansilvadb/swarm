---
tipo: build
resumo: <uma linha: o que foi construído>
ciclo: <nome-do-ciclo>
estagio: "[[pipeline/stages/build]]"
status: rascunho
criado: {{date}}
atualizado: {{date}}
depende_de:
  - "[[pipeline/cycles/<nome-do-ciclo>/increment-spec|increment-spec]]"
alimenta:
  - "[[pipeline/cycles/<nome-do-ciclo>/verdict|verdict]]"
tags:
  - pipeline/build
  - estagio/build
  - ciclo/<nome-do-ciclo>
---

> [!abstract] <uma linha: o que foi construído>

## Resumo

## Decisões estruturais

Cada decisão: a escolha, a alternativa rejeitada, o motivo, e o que faria reconsiderar. Decisão com uma opção só não é decisão.

- **D1** — <escolha>. *Rejeitado:* <alternativa>. *Motivo:* . *Revisitar se:* .

## Itens

Todo item do spec aparece aqui: implementado, ou bloqueado com o motivo. Item sumido em silêncio é a falha que esta seção existe para pegar.

| Item | Status | Arquivos | Primeiro vermelho |
|---|---|---|---|
| I1 | implementado | | `<comando>` falhou por <motivo> |

## Como executar

> [!tip] O necessário para rodar o incremento
> Comando, ponto de entrada, setup e variáveis. Quem verifica não deve precisar perguntar.

## Suspeitas

> [!warning] Onde olhar primeiro
> - 
