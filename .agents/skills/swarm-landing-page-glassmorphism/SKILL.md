---
name: swarm-landing-page-glassmorphism
description: Cria landing pages de alto nível visual, com estética contemporânea inspirada em sites premiados do Awwwards, combinando Glassmorphism refinado, tipografia editorial e expressiva, composição assimétrica, gradientes atmosféricos, microinterações, animções suaves e profundidade visual.
version: 0.1.0
---

# Landing Page Awwwards — Glassmorphism Premium

## Objetivo

Criar landing pages de alto nível visual, com estética contemporânea inspirada em sites premiados do Awwwards, combinando:

* Glassmorphism refinado
* Tipografia editorial e expressiva
* Composição assimétrica
* Gradientes atmosféricos
* Microinterações
* Animações suaves
* Profundidade visual
* Excelente hierarquia de informação
* Responsividade real
* Performance e acessibilidade

O resultado deve parecer um produto digital premium, não um template genérico.

---

## DNA Visual

### 1. Direção de arte

Usar uma composição predominantemente minimalista, sofisticada e tecnológica.

Características:

* Fundo escuro ou tonalidade neutra sofisticada
* Gradientes radiais grandes e difusos
* Elementos translúcidos sobrepostos
* Bordas extremamente sutis
* Tipografia grande e editorial
* Muito espaço negativo
* Cards com transparência e blur
* Elementos flutuantes
* Composição com profundidade
* Contraste controlado
* Poucos elementos, mas visualmente fortes

Evitar aparência excessivamente "tech startup template".

---

### 2. Glassmorphism

Aplicar glassmorphism com moderação.

Base visual:

```css
.glass {
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  border: 1px solid rgba(255, 255, 255, 0.12);
}
```

O efeito deve depender também do conteúdo existente atrás do vidro.

Não criar dezenas de cards de vidro.

Usar glassmorphism principalmente em:

* Navbar
* CTAs
* Cards estratégicos
* Elementos flutuantes
* Menus
* Componentes de destaque

Evitar:

* Blur exagerado
* Bordas brilhantes demais
* Gradientes neon indiscriminados
* Cards em excesso

---

## Layout

Usar grid de 12 colunas no desktop.

### Desktop

* Container máximo: 1200–1440px
* Grid: 12 colunas
* Gutter consistente
* Espaçamento baseado em múltiplos de 8px
* Hero com composição assimétrica
* Seções com alternância de ritmo visual

### Tablet

Adaptar o grid para 6–8 colunas.

### Mobile

Usar uma coluna principal.

Não simplesmente reduzir o desktop.

Recompor:

* Tipografia
* Espaçamentos
* Ordem dos elementos
* Imagens
* Cards
* Animações

---

## Hero

O hero deve causar impacto imediatamente.

Estrutura recomendada:

```text
NAVBAR

                 elemento visual
                 flutuante / 3D

PEQUENO LABEL

Headline gigantesco
com 2–4 linhas

Descrição curta

[ CTA PRINCIPAL ] [ CTA SECUNDÁRIO ]

                    pequeno indicador
                    de scroll
```

O headline deve ser o principal elemento visual.

Exemplo estrutural:

```html
<section class="hero">
  <nav>...</nav>

  <div class="hero-content">
    <span class="eyebrow">DIGITAL EXPERIENCE</span>

    <h1>
      Design that
      <em>moves</em>
      people.
    </h1>

    <p>
      Experiências digitais construídas para
      transformar atenção em conexão.
    </p>

    <div class="actions">
      <a class="button-primary">Explore</a>
      <a class="button-secondary">View work</a>
    </div>
  </div>

  <div class="hero-visual">
    ...
  </div>
</section>
```

O texto acima é apenas estrutural e não deve ser copiado literalmente.

---

## Tipografia

A tipografia deve funcionar como elemento de direção de arte.

Usar:

* Sans-serif contemporânea
* Variable fonts quando disponíveis
* Grande contraste entre headline e texto auxiliar
* Tracking negativo em headlines grandes
* Line-height compacto em títulos
* Corpo entre 16–18px

Exemplo:

```css
h1 {
  font-size: clamp(4rem, 9vw, 9rem);
  line-height: 0.88;
  letter-spacing: -0.07em;
  font-weight: 500;
}
```

Não usar tipografia excessivamente pesada em todos os elementos.

Criar contraste entre:

* Display
* Labels
* Body
* Metadata

---

## Paleta

A paleta deve ser pequena.

Base possível:

```text
Background
Surface
Surface glass
Primary text
Secondary text
Accent
```

O accent pode ser:

* Azul elétrico
* Lilás
* Verde ácido
* Magenta
* Laranja
* Ciano

Usar apenas uma cor dominante de destaque.

Gradientes devem ser atmosféricos, não decorativos gratuitamente.

---

## Profundidade

Criar profundidade usando:

1. Transparência
2. Blur
3. Gradientes
4. Escala
5. Sobreposição
6. Movimento
7. Luz

Não depender de sombras pesadas.

### Proibido

```css
box-shadow: 0 30px 80px rgba(...);
```

em praticamente todos os elementos.

A profundidade deve parecer criada pela luz e pela composição.

---

## Motion Design

A página deve ter sensação de movimento.

Adicionar:

* Fade-in progressivo
* Reveal de headlines
* Parallax extremamente sutil
* Hover magnético em CTAs
* Elementos flutuantes
* Movimento lento de gradientes
* Scroll reveal
* Transições de 300–800ms

Exemplo:

```css
.element {
  transition:
    transform 600ms cubic-bezier(.16, 1, .3, 1),
    opacity 400ms ease;
}
```

Evitar animações:

* rápidas demais
* constantes demais
* chamativas sem propósito
* que prejudiquem leitura

Respeitar:

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Microinterações

Botões devem responder ao cursor.

Exemplo conceitual:

```text
NORMAL
    ↓
hover
    ↓
leve deslocamento
+ alteração de luminosidade
+ mudança sutil do background
```

Não transformar cada interação em uma animação chamativa.

---

## Seções

Uma landing page completa pode utilizar:

### 01 — Hero

Impacto visual imediato.

### 02 — Manifesto

Texto curto e grande.

### 03 — Feature / Product

Demonstração visual do produto.

### 04 — Showcase

Projetos, funcionalidades ou resultados.

### 05 — Social proof

Clientes, métricas ou depoimentos.

### 06 — Interactive feature

Elemento que permita interação.

### 07 — CTA

Grande fechamento visual.

### 08 — Footer

Minimalista e editorial.

Cada seção deve ter identidade própria sem quebrar a linguagem visual geral.

---

## Cards

Cards não devem formar uma grade genérica de dashboard.

Preferir:

* Cards assimétricos
* Tamanhos variados
* Sobreposição
* Cards parcialmente fora do grid
* Conteúdo visual
* Muito espaço interno

Evitar:

```text
[ Card ] [ Card ] [ Card ]
[ Card ] [ Card ] [ Card ]
[ Card ] [ Card ] [ Card ]
```

quando não houver necessidade funcional.

---

## Imagens e elementos 3D

Quando houver elementos visuais:

* Usar composição abstrata
* Objetos translúcidos
* Formas orgânicas
* Objetos 3D minimalistas
* Texturas discretas
* Imagens editoriais

Nunca copiar logos, marcas ou assets específicos das referências.

---

## Navbar

A navbar deve ser discreta.

Possível composição:

```text
[LOGO/TIPO]                 [LINK] [LINK] [LINK] [CTA]
```

Pode utilizar glassmorphism:

```css
nav {
  position: fixed;
  top: 24px;
  left: 50%;
  transform: translateX(-50%);
  width: min(calc(100% - 48px), 1200px);

  background: rgba(255,255,255,.05);
  backdrop-filter: blur(20px);

  border: 1px solid rgba(255,255,255,.1);
  border-radius: 999px;
}
```

A marca utilizada no projeto deve ser original.

---

## Contraste e acessibilidade

O visual premium nunca deve comprometer legibilidade.

Garantir:

* Contraste mínimo WCAG AA
* Estados de foco visíveis
* Navegação por teclado
* Textos legíveis sobre backgrounds complexos
* `aria-label` quando necessário
* HTML semântico
* `prefers-reduced-motion`

Não usar texto cinza excessivamente escuro sobre superfícies claras ou branco de baixa opacidade sobre fundos complexos quando isso prejudicar a leitura.

---

## Espaçamento

Utilizar 8px como unidade base.

Exemplo:

```text
8
16
24
32
48
64
80
96
128
160
```

Evitar valores arbitrários sem necessidade.

---

## Responsividade

A página deve ser concebida para:

```text
Mobile
Tablet
Desktop
Wide Desktop
```

No mobile:

* Reduzir efeitos de blur quando necessário
* Simplificar elementos decorativos
* Evitar overflow horizontal
* Reorganizar composição
* Reduzir escala tipográfica
* Preservar impacto visual
* Manter CTAs acessíveis

Nunca entregar um desktop simplesmente comprimido.

---

## Performance

Priorizar:

* CSS moderno
* SVG quando apropriado
* Imagens otimizadas
* Lazy loading
* `transform` e `opacity` para animações
* Evitar efeitos caros desnecessários
* Evitar múltiplos elementos gigantes com `backdrop-filter`

A estética deve continuar sofisticada mesmo em dispositivos menos potentes.

---

## Stack padrão

Quando nenhuma stack for especificada:

```text
HTML
CSS
JavaScript
```

Quando React for solicitado:

```text
React
CSS Modules ou CSS
```

Quando uma aplicação moderna for solicitada:

```text
Next.js
React
Tailwind CSS
```

Não adicionar frameworks apenas por adicionar.

---

## Qualidade visual

Antes de finalizar, verificar:

### Hierarquia

* O usuário sabe onde olhar primeiro?
* O headline domina o hero?
* Os CTAs são claros?

### Composição

* Existe equilíbrio entre vazio e conteúdo?
* O grid está sendo respeitado?
* Existem elementos com profundidade?

### Glassmorphism

* O vidro está sendo usado estrategicamente?
* O blur não está excessivo?
* Existe conteúdo visível através das superfícies?

### Motion

* As animações têm propósito?
* O movimento é elegante?
* Existe suporte a reduced motion?

### Responsividade

* O layout funciona em 375px?
* Funciona em tablet?
* Funciona em telas grandes?

### Acessibilidade

* Contraste AA?
* Foco visível?
* Navegação por teclado?
* HTML semântico?

### Diferenciação

* Parece um projeto customizado?
* Evita estética genérica de template?
* A direção de arte possui uma ideia visual clara?

---

## Restrições permanentes

NÃO:

* Usar sombras pesadas
* Usar glassmorphism em todos os componentes
* Criar excesso de gradientes neon
* Usar grids genéricos de cards
* Copiar marcas ou logos das referências
* Copiar textos específicos das referências
* Sacrificar contraste pela estética
* Criar animações sem propósito
* Usar espaçamento inconsistente
* Entregar apenas desktop
* Criar uma interface visualmente bonita, mas semanticamente inacessível

SIM:

* Espaçamento baseado em 8px
* Contraste mínimo AA
* Glassmorphism seletivo
* Grid de 12 colunas no desktop
* Tipografia expressiva
* Composição assimétrica
* Motion refinado
* Profundidade através de luz, transparência e sobreposição
* Responsividade real
* Acessibilidade
* Performance

---

## Referências de DNA visual

### Exemplo 1 — Hero editorial

```text
[ NAVBAR GLASS ]

                    ◯ objeto abstrato
                  ╱
              ┌─────────┐
              │  GLASS  │
              └─────────┘

SMALL LABEL

A MASSIVE
VISUAL
STATEMENT.

Descrição curta.

[ EXPLORE → ]

                         01 / 04
```

**Razão:** composição assimétrica, headline dominante, elemento visual flutuante e grande uso de espaço negativo.

---

### Exemplo 2 — Product showcase

```text
              PRODUCT
               EXPERIENCE

      ┌─────────────────────────┐
      │                         │
      │      interface           │
      │       glass              │
      │                         │
      └─────────────────────────┘

 01                    02
 Intelligent           Fluid
 Interface             Motion
```

**Razão:** um objeto principal domina a composição enquanto informações secundárias criam ritmo visual.

---

### Exemplo 3 — CTA final

```text
────────────────────────────────

READY TO
CREATE
SOMETHING
EXTRAORDINARY?

             [ START A PROJECT ↗ ]

────────────────────────────────
```

**Razão:** encerramento tipográfico forte, simples e memorável, sem depender de elementos decorativos excessivos.

---

## Regra principal

A landing page deve parecer uma experiência digital cuidadosamente dirigida por um designer, e não uma coleção de componentes.

Priorizar:

**Direção de arte → Hierarquia → Composição → Interação → Conteúdo → Detalhes.**

O resultado final deve equilibrar impacto visual, usabilidade, acessibilidade e performance.
