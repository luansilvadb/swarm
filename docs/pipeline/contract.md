---
tipo: contrato
aliases:
  - Contrato do pipeline
tags:
  - pipeline/contrato
---

Contrato do pipeline: onde cada etapa começa e termina, o que atravessa cada aresta, e como toda nota deste vault é escrita. Fonte única — uma etapa que mude de fronteira edita **esta nota**, nunca o próprio `SKILL.md`.

Os coordenadores leem esta nota em tempo de execução, então ela é escrita para humano e agente ao mesmo tempo. As três regras que geram esta forma, e o que ela recusa, estão em [[pipeline/paradigm|paradigma]].

## Etapas

| Etapa | Coordenador | A pergunta única que responde | Artefato que sai |
|---|---|---|---|
| [[pipeline/stages/discover\|discover]] | `discover` | O que construir, para quem, e o que conta como pronto? | `increment-spec.md` |
| [[pipeline/stages/build\|build]] | `build` | Como o incremento é construído, com estrutura sólida e conforme os critérios? | `build-report.md` |
| [[pipeline/stages/verify\|verify]] | `verify` | O incremento atende aos critérios, e pode ser entregue? | `test-plan.md`, `verdict.md` |

Adiadas, viram etapa quando o pipeline crescer: **Release** (deploy, release notes) e **Retrospectiva** (ações de processo). Até lá, o release é uma decisão sua a partir do `verdict.md`.

Transversais, nunca etapas: remoção de impedimento, terminologia. Uma disciplina que roda em toda etapa ou em nenhuma não é etapa — promovê-la quebra a responsabilidade única da etapa ao lado.

## Arestas

Só dependências reais. Uma etapa pode começar assim que os artefatos de entrada existem.

```
recon ──▶ discover ──┬──▶ build ──────┐
  (condicional)      │                ├──▶ verify (gate)
                     └──▶ verify (plan) ┘
```

Duas consequências, porque um pipeline desenhado como cadeia serial perde as duas:

- **`verify` tem duas entradas, não uma.** O modo `plan` roda só com o `increment-spec`, portanto é paralelo ao `build`, não posterior a ele. O modo `gate` precisa do `build-report`. A prova deriva dos critérios, nunca do código — é exatamente por isso que ela não precisa esperar.
- **Itens de backlog são nós independentes.** Dentro do `build`, a implementação de um item não é entrada de outro, porque o `discover` cortou assim. Eles se abrem em leque.
- **Greenfield e brownfield não são pipelines diferentes.** É uma aresta condicional: o `recon` roda quando o repositório já tem código, e não roda quando não tem. Etapas, artefatos e critérios de conclusão são os mesmos — muda só a entrada do `discover`.

## Artefatos de handoff

Cada etapa escreve uma nota de handoff; as etapas seguintes leem essa nota em vez de re-derivar o conteúdo.

```
<ciclo>/recon.md             discover escreve      spec + build leem      (condicional)
<ciclo>/increment-spec.md    discover escreve      build + verify (plan) leem
<ciclo>/build-report.md      build escreve         verify (gate) lê
<ciclo>/test-plan.md         verify (plan) escreve verify (gate) lê
<ciclo>/verdict.md           verify (gate) escreve você lê
```

Pasta do ciclo: `docs/pipeline/cycles/<nome-do-ciclo>/`.

Uma nota mais atravessa todos os ciclos: [[pipeline/backlog|o backlog]], em `docs/pipeline/backlog.md`. O `discover` lê antes de cortar escopo e escreve nela o que ficou de fora; o `verify` escreve nela o que aceitou em aberto. É a aresta **ciclo → ciclo** — sem ela cada ciclo é uma ilha no grafo.

Um artefato é um contrato: uma etapa não pode omitir em silêncio uma seção que a etapa seguinte lê. Se o contrato precisa mudar, mude esta nota primeiro, depois a etapa.

## Formato das notas

### Propriedades

```yaml
---
tipo: spec                  # ciclo | recon | spec | plano | build | veredito | estagio | contrato | paradigma | backlog | home
ciclo: 2026-09-checkout
estagio: "[[pipeline/stages/discover]]"
status: rascunho            # rascunho | em-revisao | pronto | bloqueado | superado
criado: 2026-09-18
atualizado: 2026-09-18
depende_de: []
alimenta:
  - "[[pipeline/cycles/2026-09-checkout/build-report|build-report]]"
tags:
  - pipeline/spec
  - estagio/discover
  - ciclo/2026-09-checkout
---
```

`estagio`, `depende_de` e `alimenta` são **as arestas do grafo**: são eles que desenham as dependências. Escreva-os sempre como wikilink entre aspas.

### Links

- Sempre **caminho completo + texto de exibição**: `[[pipeline/cycles/2026-09-checkout/verdict|veredito]]`. Nunca o nome solto — todo ciclo tem uma nota `verdict`, e o link ambíguo aponta para a nota errada sem avisar.
- Dentro de tabela, escape o pipe: `[[pipeline/stages/build\|build]]`.
- Link para âncora quando o alvo é uma seção: `[[pipeline/cycles/x/increment-spec#Critérios de aceite|critérios]]`.

### Tags

| Tag | Em |
|---|---|
| `#pipeline/ciclo` | nota-hub do ciclo |
| `#pipeline/recon` · `#pipeline/spec` · `#pipeline/plano` · `#pipeline/build` · `#pipeline/veredito` | os artefatos do ciclo |
| `#pipeline/estagio` · `#pipeline/contrato` | notas fixas |
| `#estagio/discover` · `#estagio/build` · `#estagio/verify` | toda nota do estágio |
| `#ciclo/<nome-do-ciclo>` | toda nota do ciclo |

O par tag + wikilink não é duplicação: a tag é a faceta que colore e filtra o grafo, o wikilink é a aresta. Cada um tem um trabalho.

### Callouts

| Callout | Uso |
|---|---|
| `> [!question]` | a pergunta única da etapa, no topo da nota |
| `> [!warning]` | não-objetivos; critério que não dá para verificar |
| `> [!success]` / `> [!danger]` | veredito **ship** / **não ship** |
| `> [!quote]` | evidência bruta (saída de comando, log) |
| `> [!todo]` | o que ficou aberto |

### Embutir, nunca copiar

Os critérios de aceite vivem só no `increment-spec`. Quem precisa deles embute:

```
![[pipeline/cycles/x/increment-spec#Critérios de aceite]]
```

Assim a seção é viva: corrigir a origem corrige todos os lugares. Copiar cria duas versões que divergem na primeira edição.

### Títulos fixos

Cada tipo de nota tem um conjunto fixo de `##`, para os embeds e os links de âncora apontarem sempre para o mesmo lugar.

| Tipo | Seções |
|---|---|
| `recon` | Resumo · O que já existe · Convenções em vigor · O que não pode quebrar · Já quebrado ou morto · Por onde começar a ler |
| `increment-spec` | Resumo · Problema · Incremento · Critérios de aceite · Não-objetivos · Definition of Ready · Definition of Done |
| `test-plan` | Resumo · Verificações · Lacunas |
| `build-report` | Resumo · Decisões estruturais · Itens · Como executar · Suspeitas |
| `verdict` | Resumo · Veredito · Evidência · Achados da revisão · Definition of Done · Rollback · Aberto |
| `cycle` | Incremento · Artefatos · Linha do tempo |

### Idioma

As notas deste vault são escritas **em português** — é a wiki do time. Os nomes de arquivo e as tags usam o vocabulário em inglês das etapas (`discover`, `build`, `verify`), porque é o mesmo vocabulário que os coordenadores usam. Os prompts dos especialistas estão em inglês: o coordenador integra o retorno deles e escreve a nota em português.

O resumo de uma linha de um artefato é a propriedade `resumo`, não um callout: propriedade é filtrável, callout não. O `[!success]` e o `[!danger]` continuam existindo porque carregam *o veredito*, não o resumo.

## Recuperação (RAG)

O vault **é** o corpus. Não existe uma segunda cópia "em formato para IA" — o formato acima é ao mesmo tempo o que se lê e o que se indexa.

- **Um chunk por nota.** Os `##` fixos de cada tipo são as fronteiras de chunk — por isso não se inventa seção. Seção fora do vocabulário vira um chunk que nenhum filtro alcança.
- **Filtrar antes de buscar.** `tipo`, `estagio`, `ciclo` e `status` são metadados: a busca começa restringindo o conjunto, o que corta a maior parte do ruído antes de qualquer similaridade semântica.
- **O gancho de recuperação é a propriedade `resumo`** — é o que responde "esta nota trata do quê?" sem abrir o corpo.
- **Uma pergunta por nota**, como no grafo: nota que responde duas perguntas recupera mal as duas.

O repositório é o segundo corpus, e é ele que sustenta o brownfield. Sem indexá-lo, o agente trabalha em legado tendo de ser reapresentado ao sistema a cada ciclo.

## Execução

Você aciona um coordenador pelo nome; o coordenador despacha os próprios especialistas como subagentes. Nada mais alcança um especialista — eles são arquivos `.md` dentro de `specialists/`, sem descrição e sem gatilho próprio. Um coordenador nunca aciona o coordenador de outra etapa; **você** move o ciclo entre as etapas.
