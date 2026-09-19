---
name: graph-thinking
description: Use this skill ONLY when the user explicitly asks the agent to "think in graphs", "pensar em grafos", "raciocínio em grafo", "graph thinking", "otimizar como um grafo", or explicitly asks the agent to apply this skill (or any similarly explicit request to structure reasoning as nodes/edges for efficiency). Do NOT trigger this proactively on ordinary complex tasks — only on an explicit, unambiguous request. When triggered, it restructures the internal reasoning process (and, if another skill is being used, that skill's own workflow) into a node/edge graph — inspired by how attention works as message-passing on a graph — to find what can run in parallel, what is a genuine dependency vs. artificial sequencing, and what information can be computed once and reused, instead of processing everything as one long serial chain.
---

# Graph Thinking

Uma "meta-habilidade": não resolve tarefas por si só, mas reestrutura *como* o agente aborda qualquer tarefa (ou qualquer outra skill em uso), para ganhar eficiência.

## De onde vem a ideia

Vem de como a atenção em transformers funciona: cada nó (token) tem um estado privado e, em vez de processar tudo em série (como uma RNN, que é um grafo longo e fino, lento e difícil de otimizar), o transformer intercala duas fases:

1. **Fase de comunicação** — cada nó emite uma *query* (o que ele está procurando), uma *key* (o que ele tem a oferecer) e um *value* (o que ele efetivamente vai passar adiante). A informação flui só pelas arestas que realmente importam — não por todo mundo em sequência.
2. **Fase de computação** — de posse do que precisava, cada nó processa sua atualização de forma independente (e, portanto, em paralelo com os outros nós).

O resultado é um grafo raso e largo (shallow & wide) em vez de longo e fino — o que é mais rápido, mais fácil de otimizar e evita retrabalho.

Esta skill pega essa mesma lógica e aplica ao *raciocínio do agente sobre uma tarefa*, não a tokens.

## Quando usar

Só quando o pedido for explícito (ver `description`). Se o usuário não pediu isso de forma clara, não aplique — siga o fluxo normal.

Isso vale também quando o usuário pedir para aplicar "pensamento em grafo" a uma tarefa que já usaria outra skill (ex.: "use pensamento em grafo para gerar essa planilha"). Nesse caso, aplique o processo abaixo à *própria skill* que seria usada, antes de executá-la.

## O processo (interno — não precisa expor ao usuário, a menos que ele peça para ver o grafo)

### 1. Mapear os nós
Decomponha a tarefa em unidades atômicas: subtarefas, entidades, arquivos, seções, ou — se outra skill está em jogo — os passos dessa skill. Cada nó deve ser algo que poderia, em princípio, ser resolvido isoladamente.

### 2. Mapear as arestas (dependências reais)
Para cada nó, pergunte: "o que este nó *realmente* precisa saber de outro nó para ser resolvido?" Só desenhe uma aresta quando há uma dependência genuína (a saída de um nó é entrada necessária de outro). Sequenciamento que existe só por hábito ou por como o pedido foi escrito, não por necessidade real, não vira aresta.

Um erro comum: tratar toda a tarefa como uma cadeia serial (nó 1 → nó 2 → nó 3 → ...) quando, na real, vários nós não dependem uns dos outros e só parecem sequenciais porque foram listados em ordem.

### 3. Fase de comunicação
Para cada nó com arestas de entrada, identifique rapidamente:
- **Query**: o que ele precisa dos outros nós.
- **Key/Value**: o que os nós vizinhos têm para oferecer que responde a essa query.

Isso serve para achar **hubs** — informações ou resultados que múltiplos nós vão precisar. Calcule esses hubs uma vez só e reutilize (deixe de recomputar a mesma coisa em nós diferentes).

### 4. Fase de computação
Agora resolva os nós:
- Nós **sem arestas entre si** (independentes) → resolva-os "em paralelo" (ou seja: trate-os como um lote, não force uma ordem artificial entre eles no raciocínio ou na execução de ferramentas).
- Nós com arestas reais → respeite a ordem mínima necessária, mas não mais que isso.
- Evite grafos longos e finos: se você notar uma cadeia de 6+ passos estritamente seriais, pare e pergunte se alguns desses passos realmente dependem do anterior ou se foram apenas escritos em sequência.

### 5. Executar e responder
Execute o plano resultante (que pode envolver chamadas de ferramentas em paralelo quando o ambiente permitir, ou simplesmente uma ordem de raciocínio mais enxuta) e entregue a resposta normalmente — no formato que a tarefa pediria de qualquer forma. Não é necessário mostrar o grafo ao usuário, a menos que ele peça explicitamente para ver a decomposição.

## Exemplo rápido

Pedido: "Pense em grafos e me ajude a planejar o lançamento de um produto: preciso do texto do site, das artes para redes sociais, de um comunicado de imprensa e de uma planilha de orçamento."

- **Nós**: texto do site, artes, comunicado de imprensa, planilha de orçamento.
- **Arestas reais**: o comunicado de imprensa e o texto do site provavelmente compartilham o mesmo *hub* de informação (posicionamento do produto, nome, data de lançamento) — computar isso uma vez, não duas. A planilha de orçamento não depende de nenhum dos outros três.
- **Comunicação**: extrair o "hub" (posicionamento/nome/data) uma única vez logo no início.
- **Computação**: os quatro nós, uma vez que o hub existe, podem ser produzidos de forma independente (não há necessidade de escrever o site, depois esperar, depois escrever o comunicado sequencialmente só por hábito).
- **Resultado**: Agente entrega os quatro artefatos sem tratar isso como uma cadeia de 4 passos seriais, e sem redigitar o posicionamento do produto quatro vezes com o risco de inconsistência.

## Aplicando isso a outra skill

Se o usuário pedir pensamento em grafo *em conjunto* com outra skill (ex. pptx, xlsx, docx, ou uma skill de domínio), antes de seguir os passos dessa skill ao pé da letra:
1. Liste os passos da skill como nós.
2. Marque quais passos realmente dependem da saída de um passo anterior vs. quais só estão na mesma lista por convenção.
3. Reagrupe/reordene mentalmente para eliminar dependências falsas, depois execute a skill normalmente (respeitando o que a skill exige de fato, como formato de arquivo ou ferramentas obrigatórias) sobre esse plano mais enxuto.

Nunca pule etapas que a outra skill descreve como obrigatórias (ex. "sempre view o SKILL.md antes de criar o arquivo") só porque parecem seriais — essas são dependências reais de ferramenta/ambiente, não sequenciamento artificial.
