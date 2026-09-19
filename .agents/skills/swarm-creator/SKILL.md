---
name: swarm-creator
description: Cria, refatora e extrai conhecimento para SKILLs de agentes.
---

## FUNÇÃO E ESCOPO

Transforma um domínio, projeto ou codebase em uma SKILL acionável e suas unidades de conhecimento.

Use para criar, refatorar ou reorganizar SKILLs e extrair padrões de projetos. Não use para executar tarefas do domínio ou substituir uma skill especializada.

## PRINCÍPIO

`DOMÍNIO → PERGUNTAS → LACUNAS → UNIDADES → ESTRUTURA → VALIDAÇÃO`

Cada unidade responde a uma pergunta cognitiva central. Crie arquivos por necessidade, não por numeração ou preenchimento estrutural.

## FLUXO

1. Defina objetivo, escopo, anti-escopo, entradas, saídas, regras, exceções e restrições.
2. Liste as perguntas do agente e compare-as com as unidades existentes; marque lacunas, redundâncias e conteúdo fora do escopo.
3. Para cada lacuna, crie uma unidade com uma única responsabilidade e nome/localização coerentes. Inclua dependências, limites e exemplos somente quando úteis.
4. Valide cada unidade. Repita enquanto houver lacunas relevantes, respeitando **PARADA**.
5. Gere ou atualize `SKILL.md`, o índice de unidades e a ordem de injeção; valide a árvore completa.

## VALIDAÇÃO DE UNIDADE

A unidade deve:

- responder a uma pergunta central;
- ser concreta, aplicável e estar no escopo;
- não duplicar outra unidade;
- declarar dependências e limites relevantes.

Se falhar, refaça até 3 vezes; depois sinalize a unidade e pare.

## PARADA

Pare quando não houver lacunas relevantes, uma iteração não gerar unidade nova e não redundante, forem atingidas 10 iterações ou uma unidade continuar inválida após 3 tentativas. O critério é semântico; 10 é apenas o limite máximo.

## ESTRUTURA

```text
skills/<skill-name>/
├── SKILL.md
├── <categoria>/
│   └── <unidade>.md
└── ...
```

Enquanto houver lacunas relevantes no domínio, crie apenas as categorias e unidades necessárias, cada uma com propósito claro.

## SKILL.md

Deve declarar função, escopo, anti-escopo, organização, ordem de injeção, índice das unidades (nome + pergunta), limites e critérios de parada. Não replique nele o conhecimento das unidades.

Injete `SKILL.md` primeiro, depois unidades sem dependências e, por fim, as dependentes. Sem dependências, selecione apenas as unidades relevantes à tarefa.

## TEMPLATE DA UNIDADE

```markdown
---
name: <slug>
description: <pergunta que a unidade responde>
---

## PERGUNTA
<uma única pergunta central>

## RESPOSTA
<regras, critérios, procedimentos ou conhecimento acionável>

## DEPENDÊNCIAS (se houver)
- <unidade>: <o que fornece>

## LIMITES (se houver)
- <restrição ou anti-uso>

## EXEMPLO (se necessário)
<exemplo curto>
```

## VALIDAÇÃO FINAL

- cobertura suficiente e sem redundância;
- uma responsabilidade por unidade;
- categorias e arquivos justificados;
- dependências e injeção claras;
- `SKILL.md` com escopo, anti-escopo e limites;
- nenhum arquivo vazio, duplicado ou fora do escopo.
