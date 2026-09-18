---
tipo: recon
resumo: O estado atual do sistema que este incremento vai tocar.
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
  - pipeline/recon
  - estagio/discover
  - ciclo/<nome-do-ciclo>
---

> [!question] Só existe quando o repositório já tem código
> O que já existe, o que não pode quebrar, e que convenções já estão em vigor.

## Resumo

## O que já existe

Módulos, endpoints, schemas, jobs, dados — e qualquer tentativa parcial que alguém começou e abandonou.

## Convenções em vigor

Como este código nomeia, divide módulos, trata erro e testa. Nomear é o que permite às etapas seguintes seguirem a convenção em vez de inventarem uma segunda ao lado da primeira.

## O que não pode quebrar

## Já quebrado ou morto

O que já estava quebrado antes, para não ser confundido com algo que este incremento causou.

## Por onde começar a ler
