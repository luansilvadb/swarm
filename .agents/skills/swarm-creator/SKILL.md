---
name: swarm-creator
description: Crie, melhore e extraia conhecimento para SKILLs de agentes baseadas em domínios, projetos ou codebase.
---

## FUNÇÃO E ESCOPO

Transforma um domínio, projeto ou codebase em uma SKILL acionável e suas unidades de conhecimento.

Use para criar, melhorar ou refatorar SKILLs e extrair padrões de projetos. Não use para executar tarefas do domínio ou substituir uma skill especializada.

## PRINCÍPIO

`DOMÍNIO → PERGUNTAS → LACUNAS → UNIDADES → ESTRUTURA → VALIDAÇÃO`

Cada unidade responde a uma pergunta cognitiva central. Crie arquivos por necessidade, não por numeração ou preenchimento estrutural.

## FLUXO

1. Defina objetivo, escopo, anti-escopo, entradas, saídas, regras, exceções e restrições.
2. Gere as perguntas que o agente deve responder para realizar o objetivo.
3. Compare com as unidades existentes; marque lacunas, redundâncias e conteúdo fora do escopo. Atualize, consolide ou remova unidades quando necessário; redundâncias, conteúdos fora do escopo e falhas na validação final ainda sem solução são ajustes pendentes.
4. Para cada lacuna, defina ou reutilize a categoria adequada e crie uma unidade.
5. Valide cada unidade. Repita os passos 2 a 5 enquanto houver lacunas ou ajustes pendentes.
6. Gere ou atualize `SKILL.md`, o índice de categorias e unidades e a ordem de injeção; valide a árvore completa. Se falhar, corrija a causa e retome os passos 2 a 6; se não for possível, sinalize e pare.

## VALIDAÇÃO DE UNIDADE

A unidade deve:

- responder a uma pergunta central;
- ser concreta, aplicável e estar no escopo;
- não duplicar outra unidade;
- declarar dependências e limites relevantes.

Se falhar, corrija ou recrie a unidade antes de continuar; se não for possível validá-la, sinalize-a e pare.

## PARADA

Pare quando não houver lacunas relevantes nem ajustes pendentes, quando uma iteração não gerar unidade nova nem resolver ajuste pendente, ou quando uma unidade não puder ser validada.

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

A SKILL criada ou atualizada deve declarar função, escopo, anti-escopo, organização das categorias, ordem de injeção, índice das categorias (propósito) e unidades (nome + pergunta), limites e critérios de parada. Não replique nela o conhecimento das unidades.

Categorias são apenas organizacionais e não entram na ordem de injeção. Injete `SKILL.md` primeiro e, depois, apenas as unidades relevantes e suas dependências, respeitando a ordem de dependência.

## TEMPLATE DA UNIDADE

```markdown
---
name: <slug>
description: <descrever a responsabilidade da unidade>
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
- `SKILL.md` da skill criada ou atualizada com função, escopo, anti-escopo, organização, índice das categorias (propósito) e unidades (nome + pergunta), ordem de injeção, limites e critérios de parada;
- nenhuma unidade inválida, arquivo vazio, duplicado ou fora do escopo.
