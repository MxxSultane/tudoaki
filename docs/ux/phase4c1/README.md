# Tudo aki 2.0 — Fase 4C.1

**Especificação para revisão — 12 de Novembro de 2026. Direcção B: visual e premium. Não implementada.** Público: jovens que estudam, trabalham e empreendem. A interface deve tornar evidente o próximo gesto, sem tutorial; esta hipótese ainda precisa de investigação com pessoas.

## Base confirmada

Branch de especificação: `docs/fase-4c1-design-system`, criado directamente de **79470b80b683dcd2fa60cf2bf16531f884c87e8a**, HEAD final remoto da Fase 4B, com árvore limpa. Esse HEAD contém 038c0ce (hábitos, FAB directo de Metas e divulgação progressiva da criação rápida) e a consolidação documental 4B. Não se partiu de f3ff7a9 nem de uma base anterior às correcções.

Validação do próprio HEAD 79470b8 observada pela API GitHub nesta fase:

| Workflow | Execução | Estado |
| --- | --- | --- |
| Flutter validation | [43291645106](https://github.com/MxxSultane/tudoaki/actions/runs/43291645106) | COMPLETED / SUCCESS |
| Android debug validation | [43291644938](https://github.com/MxxSultane/tudoaki/actions/runs/43291644938) | COMPLETED / SUCCESS |

Os **254 testes** são o resultado local registado na 4B; não se declara uma nova execução Flutter nesta fase documental. As correcções da base são invariantes. Não se modificam lib/, android/, testes existentes, rotas, modelos, SQLite, dependências, serviços, dados ou XP.

## Adenda — identidade global

A identidade abrange **toda a aplicação**, com propostas A (visual), B (simplificação) e C (redesenho profundo) por contexto. Começar por [GLOBAL_IDENTITY.md](GLOBAL_IDENTITY.md), [GLOBAL_PROTOTYPES.md](GLOBAL_PROTOTYPES.md), [prancha global](global.html), [componentes/foco/toque](GLOBAL_COMPONENTS.md) e [contraste global](GLOBAL_CONTRAST.md). Hoje, Planear, Tarefas e Agenda conservam os fluxos aprovados; Estudos, Finanças e Progresso são os candidatos a C. A aprovação de design não autoriza alterações de código.

## Entrega e percurso de leitura

| Pedido | Documento |
| --- | --- |
| 1. Auditoria actual | [AUDIT.md](AUDIT.md) |
| 2. Design System 2.0 | [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) |
| 3. Matriz calculada | [CONTRAST_MATRIX.md](CONTRAST_MATRIX.md), [CSV completo](contrast-all-pairs.csv), [tokens](tokens.json), [calculador](contrast_calculator.py) |
| 4. Foco e áreas de toque | [ACCESSIBILITY.md](ACCESSIBILITY.md) |
| 5. Clay e glass | [SURFACES.md](SURFACES.md) |
| 6–9. Metas, Estudos, Finanças e Progresso | [GOALS.md](GOALS.md), [MODULES.md](MODULES.md) |
| 10. Formulários | [FORMS.md](FORMS.md) |
| 11. Wireframes dos seis contextos | [WIREFRAMES.md](WIREFRAMES.md), [prancha conceptual HTML](wireframes.html) e SVGs em wireframes/ |
| 12. Compatibilidade | [COMPATIBILITY.md](COMPATIBILITY.md) |
| 13–14. Aceitação e ordem futura | [ACCEPTANCE.md](ACCEPTANCE.md) |

Os SVGs e a prancha HTML são **protótipos conceptuais**, com exemplos fictícios; não são capturas Flutter, implementação visual da aplicação nem prova de conformidade WCAG. As capturas reais continuam em [4B/after](../previews/phase4b/after/) e [3F](../previews/phase3f/). Nenhuma imagem histórica foi sobrescrita.

## Decisões desta proposta

- Híbrido: superfícies planas operacionais; clay subtil em destaques de metas/hábitos/disciplinas; glass apenas decorativo e controlado no Percurso conceptual.
- Inter/Newsreader locais, paleta Sage/Forest/Mineral/Graphite, tokens semânticos por tema; nenhum pacote novo.
- 48×48 dp como mínimo interno sem excepções propostas, foco de 2 dp, reflow e texto a 200%.
- Acompanhamento binário por defeito em **novas** metas sem métrica, etapas por contagem real e números só quando escolhidos. **Retira-se a sugestão de 0–100% da secção propositiva da 4B**; o relatório histórico não é reescrito.
- Metas antigas mantêm métrica, prazo, histórico e relações. A selecção durável de modo exige desenho aditivo de dados e autorização próprios; não pode ser disfarçada de mudança apenas visual.

## Verificação e limites

Verificação documental: cálculos sRGB reproduzíveis, whitelist de pares por função, verificação de links locais, XML dos wireframes, correspondência com os tokens e comparação Git das áreas protegidas. Resultados em [ACCEPTANCE.md](ACCEPTANCE.md). Auditoria reutiliza 4B e complementa apenas lacunas de modo de metas, foco, composição de cor e estados.

WCAG 2.2 AA é referência de requisitos, não certificação obtida. Faltam execução Flutter futura, leitores de ecrã, teclado físico, dispositivos reais e investigação de compreensão. A fase pode ser entregue para revisão de design; não autoriza implementação, migração, merge ou Percurso completo.
