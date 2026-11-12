# Fase 4C.2 — revisão visual, protótipos e validação UX

**Entrega de design e revisão especializada. Não implementada na aplicação.** Direcção Visual e Premium preservada; propostas continuam sujeitas a revisão/aprovação. Sem merge ou início de 4C.3.

## 1. HEAD, branch e preservação

HEAD inicial/local/remoto da 4C.1 confirmado: **ae0de841fe4a0be487ec2a246000770790df2689**, branch `docs/fase-4c1-design-system`, árvore limpa. Criado o branch isolado **docs/fase-4c2-revisao-ux** directamente desse HEAD. Código base continua **79470b80b683dcd2fa60cf2bf16531f884c87e8a**, entrega final 4B com hábitos múltiplos, FAB de Metas directo e criação rápida simplificada; não se voltou a uma base anterior.

Não se alteraram lib/, android/, SQLite v5/lifeos.sqlite, pubspec/lockfile, dependências, rotas, lógica de negócio, TaskOperations, finanças, dados ou XP. Também não se alteraram testes, ferramentas de produção, workflows ou ficheiros da 4C.1. Alterações limitadas a este relatório e docs/ux/phase4c2.

## 2. Documentos analisados

O [inventário com hashes](ux/phase4c2/review-sources.json) regista **83 artefactos** da 4C.1: 16 Markdown, sete artefactos técnicos de raiz, 12 SVGs e 48 PNGs. Foram lidos os textos/configurações/calculador, verificadas estruturas/dados e revista visualmente uma selecção representativa das imagens; inventariar/ler metadados de uma imagem não significa que todas foram inspeccionadas manualmente.

| Documento 4C.1 | Análise na 4C.2 |
| --- | --- |
| README.md | Base/CI herdada, âmbito global e ausência de aprovação implícita |
| AUDIT.md | Diagnóstico actual reutilizado, sem repetir a reprodução dos defeitos 4B |
| DESIGN_SYSTEM.md | Coerência de tokens/tipografia/estados e papéis das superfícies |
| CONTRAST_MATRIX.md | Pares, limites e papéis; distinguir texto de fronteira funcional |
| ACCESSIBILITY.md | Foco/toque/unidades, ordem e limites da verificação Web |
| SURFACES.md | Clay opaco, glass composto e fallback; evitar efeitos como informação |
| GOALS.md | Três modos, dias opcionais, legado e bloqueio de dados |
| MODULES.md | Hierarquia de Estudos/Finanças/Progresso e todas as capacidades secundárias |
| FORMS.md | Divulgação progressiva, contexto/rascunho/retorno e campos completos |
| WIREFRAMES.md | Fidelidade e limites das seis primeiras estruturas |
| COMPATIBILITY.md | Invariantes de dados, caminhos e funções preservadas |
| ACCEPTANCE.md | Gates e sequência futura, sem tomar planos como autorização |
| GLOBAL_IDENTITY.md | A/B/C por ecrã, fluxos aprovados e identidade em toda a app |
| GLOBAL_COMPONENTS.md | Componentes globais, toque, foco e transição |
| GLOBAL_CONTRAST.md | Mínimos por família e aliases; não só a cor de marca |
| GLOBAL_PROTOTYPES.md | Prancha, estados em falta e alcance real das verificações |

Artefactos técnicos analisados: tokens.json, contrast-approved.json, contrast-all-pairs.csv, contrast_calculator.py, global-validation.json, global.html e wireframes.html. Contratos anteriores considerados: AGENTS.md, V2_CONTRACTS.md, DESIGN_SYSTEM.md histórico, HOJE_PLANEAR_SPEC/IMPLEMENTATION, RESTORE_PLAN e relatórios 3B/3F/4A/4B. Indicações históricas de funcionalidade «futura» são conciliadas com o código e com os contratos já implementados; não se reintroduz uma proposta abandonada como comportamento aprovado.

## 3. Problemas identificados e decisões de revisão

A [revisão crítica](ux/phase4c2/DESIGN_REVIEW.md) lista 16 achados, prioridades, consequências e gates. Principais correcções de proposta:

- Substituir documentos de conteúdo longo como substituto de telefone por frames de altura delimitada e scroll interno; separar overflow de visibilidade da acção.
- Completar vazio/preenchido, campos numéricos de meta, preview de prazo, controlo de moeda/mês e composição financeira.
- Reduzir relevo, caixas repetidas, títulos de grande dimensão e espaço uniforme que afastavam conteúdo útil; plano é a base, clay é acento e glass é opcional.
- Explicitar o contorno funcional do botão Sage: texto acessível não prova uma fronteira necessária. primaryBorder reutiliza Forest/Graphite, sem nova cor de marca.
- Não tratar Tasks.due como prazo de entrega automaticamente. Distinguir o dia da tarefa da data da avaliação e do prazo da meta.
- Colocar actividade/metas antes da representação visual em Progresso, sem métricas de produtividade ou XP novos.
- Tratar foco modal e compreensão por pessoas como verificações separadas; as propostas não ficam aprovadas só por estarem documentadas.

Hoje, Planear, Agenda e Tarefas mantêm a categoria A, sem redesenho profundo dos seus fluxos. Metas tem A/B com gate de dados. Estudos, Finanças e Progresso continuam candidatos A/C. A actualização visual global precede o redesenho dos módulos autorizados.

## 4. Protótipos / maquetas entregues

[Índice visual e prancha interactiva](ux/phase4c2/PROTOTYPES.md): **25 casos, dois temas, 50 imagens normais + quatro imagens a 200%/teclado simulado + duas pranchas de conjunto = 56 PNGs conceptuais**. Foram gerados por HTML/Chromium, não por Flutter. Não se apresentaram maquetas como implementação.

Cobertura: Hoje vazio/preenchido; Planear vazio/preenchido e Semana; Metas vazio/três acompanhamentos; Criar meta inicial e numérica expandida; detalhe binário e por etapas (propostas); Estudos vazio/preenchido/foco activo; Finanças vazio/com movimentos; Progresso vazio/preenchido/visual opcional; Criar tarefa em branco/preenchida/opções; Agenda e Tarefas como referências; catálogo de estados/foco. Capacidades secundárias preservadas têm entradas nomeadas, sem fingir que um editor Web grava na app.

Metas: Nome + prazo opcional em dias + Criar no primeiro nível. Nenhuma métrica ou alvo inicial universal. Binário usa Em curso/Alcançada; etapas usam contagem; numérico mostra valor/unidade reais. Campos existentes continuam nas opções. A solução durável dos novos modos não existe no v5 e continua explicitamente bloqueada por decisão técnica, sem conversão automática do legado.

## 5. Comparação actual / proposta

[COMPARISON.md](ux/phase4c2/COMPARISON.md) liga, por ecrã e tema, capturas reais históricas Flutter às novas propostas conceptuais e descreve as alterações. Não é um diff de pixels ou uma medição de desempenho entre aplicações: dimensões/datas/volumes sintéticos diferem.

Separadamente, a comparação automática com **o artefacto Web 4C.1** mediu 1255,1875 CSS px no contentor de Hoje, contra frame 800 CSS px agora; encontrou zero selects na maquete de Finanças anterior, substituídos por selector explícito e mês separado. São limitações/correcções dos protótipos, não regressões descobertas na aplicação de produção.

## 6. Matriz de contraste

[CONTRAST.md](ux/phase4c2/CONTRAST.md), [todos os pares](ux/phase4c2/contrast-all-pairs.csv), [resultados](ux/phase4c2/contrast-results.json) e [calculador](ux/phase4c2/contrast_calculator.py): **94 utilizações verificadas e 648 pares calculados**, sem falha dos limiares especificados. A passagem de 17 para 18 tokens por tema vem de um alias de papel, primaryBorder; a paleta de cores não mudou.

Texto normal ≥4,5:1, gráfico relevante ≥3:1; text crítico ≥7:1 nos fundos de leitura. Graphite/Sage: 7,917:1. Forest/Sage no contorno claro: 3,242:1. Branco/Sage (1,843:1) e Mineral/branco (2,213:1) continuam proibidos para usos funcionais insuficientes.

Glass avaliado depois de composição a 90% sobre background/surfaceSoft, nos dois temas; o blur não conta como aumento de contraste. Fallback sólido verificado no browser. Clay mantém centro opaco; sombras são decorativas. O cálculo cobre os tokens/papéis propostos, não certifica todos os pixels, popups do SO, anti-aliasing ou conforto de leitura no telefone.

## 7. Foco, toque e acessibilidade

[ACCESSIBILITY.md](ux/phase4c2/ACCESSIBILITY.md) define alvo interno mínimo 48×48 dp, + de 56×56, campos ≥56 de altura, rótulos integrais e anel 2 dp com separação. Foco é distinto de seleccionado/pressionado/erro/desactivado. CSS px de protótipo não equivalem a dp nem a píxeis físicos.

Ensaios finais de browser, em [validation.json](ux/phase4c2/validation.json):

- **25 × 12 = 300 verificações de viewport** (claro/escuro × 320/360/390 CSS px × texto 100/200%); zero violações de overflow, dimensão medida ou posição de barra/rodapé/FAB nos critérios do script.
- Foco de 2 CSS px e campo dentro da área útil com teclado simulado nos quatro casos tema/escala; mais **13 controlos de formulário focados e visíveis** no cenário de esforço escuro/200%.
- Nome/prazo/alvo, descoberta de Guardar outra, contagem de etapas sem concluir automaticamente a meta, retorno do foco, Tab/Shift+Tab e Esc no diálogo Web.
- Nomes acessíveis presentes na árvore Chromium, movimento reduzido sem animação/transição e alternativa sólida sem blur; nenhum erro JavaScript final.

Falhas intermédias não foram ocultadas: o primeiro ensaio de visibilidade de Guardar outra verificava antes do evento toggle terminar; passou com espera pela condição visível. O ensaio do diálogo revelou saída do foco do ciclo de acções; acrescentou-se ciclo explícito no **protótipo Web**, mantendo Esc/retorno. A repetição final passou. Nenhuma dessas alterações foi aplicada aos diálogos/FocusScope Flutter.

Sem ensaio TalkBack, teclado físico/IME/gestos Android, SafeArea real, orientação horizontal nativa, brilho/sol ou desempenho do blur. Não se declara conformidade WCAG integral com base nestes protótipos.

## 8. Avaliação da simplicidade / validação UX

[UX_REVIEW.md](ux/phase4c2/UX_REVIEW.md) responde às oito perguntas do pedido por ecrã: finalidade, acção principal, informação/repetição, passos, opções, identidade e dados realistas. A avaliação é especializada, não uma estatística de compreensão. Não se mediram tempo, taxa de sucesso ou satisfação de utilizadores.

Conclusão da revisão: manter os fluxos aprovados e reduzir a complexidade por contexto. A criação simples de meta elimina requisitos numéricos universais, mas a criação numérica passa a ter uma divulgação adicional — não alegar «menos passos para todos». Finanças/Estudos/Progresso têm hierarquia candidata mais focada; a descoberta das funções recolhidas precisa de observação real.

[RESEARCH_PLAN.md](ux/phase4c2/RESEARCH_PLAN.md) entrega tarefas, amostra formativa proposta, registo e critérios de decisão. Participantes observados: **0**; nenhum contacto foi efectuado. A compreensão imediata, a preferência premium e a descoberta sem tutorial permanecem hipóteses a validar.

## 9. Matriz de compatibilidade

[COMPATIBILITY.md](ux/phase4c2/COMPATIBILITY.md) cobre temas/fluxos/dados, campos ocultos, 3B/4A/4B, metas antigas, modos novos, estudos, finanças e progresso. Nenhuma abertura/reorganização deve escrever dados. Sem percentagens artificiais, inferência de modo, migração ou reinterpretação de datas legadas nesta fase.

Se 4C.3 for autorizada só como visual mantendo v5 intacto, adoptar A e as metas numéricas existentes; **não activar os modos novos nem Criar apenas com nome sem contrato de armazenamento aprovado**. O bloqueio não impede adoptar o DS ou rever os restantes módulos.

## 10. Plano detalhado para 4C.3

[IMPLEMENTATION_PLAN.md](ux/phase4c2/IMPLEMENTATION_PLAN.md): incrementos C3.0–C3.V, componentes/ficheiros reais, dependências, risco, testes e aceitação por módulo. Sequência: baseline/autorização → tokens → controlos/foco → shells/componentes → A nos fluxos aprovados/áreas secundárias → Estudos C → Finanças C → Progresso C → validação nativa de conjunto. Metas B segue gate técnico próprio.

Reutilizar tema/arquitectura/serviços existentes, tool/capture_quality.dart e fixtures sintéticas, sem dependências novas por conveniência. Cada etapa tem comparação visual, regressão pertinente, suite/Actions antes de entregar e revisão; sem merge automático. Não se iniciou qualquer incremento.

## 11. Questões que exigem aprovação

| ID | Decisão concreta para uma futura autorização | Recomendação da revisão / consequência |
| --- | --- | --- |
| D01 | Adoptar as alterações de densidade/tipografia/primaryBorder e a aplicação A global? | Adoptar como candidato a piloto isolado com contraste/foco; não refazer os fluxos aprovados |
| D02 | Autorizar B de Metas e contrato de dados para três modos? | Separar a decisão visual da decisão de esquema/operações/histórico; sem esta autorização manter numérico legado |
| D03 | Confirmar prazo em dias (1=amanhã, vazio sem prazo, 1–3650, data absoluta) e comportamento à meia-noite? | Aprovar explicitamente antes de gravar; edição preserva due exacto se não tocado; não reiniciar N dias ao reabrir |
| D04 | Confirmar conclusão/reabertura de meta por etapas? | Última etapa oferece acção explícita; não altera meta/XP automaticamente; definir operações e histórico no contrato técnico |
| D05 | Aprovar C de Estudos/Finanças/Progresso, incluindo localização das funções secundárias? | Entregas/disciplinas/foco, resumo/movimentos e actividade/metas primeiro; testar descoberta sem perder capacidades |
| D06 | Activar mapa glass opcional ou manter só lista na primeira implementação? | Lista primeiro; mapa apenas após fontes/contraste/fallback/desempenho, sem Percurso completo |
| D07 | Remover título duplicado de Agenda/localizar datas de Revisões? | B pontual separada, não incluída automaticamente na adopção A |
| D08 | Autorizar pesquisa com participantes e validar os limiares propostos? | Ronda formativa sem dados reais; não chamar aos ensaios de browser validação de compreensão |

Nenhuma opção foi considerada aprovada por silêncio ou por constar da 4C.1/4C.2. A aprovação de 4C.3 deve indicar incrementos e limites; não autoriza merge/distribuição automaticamente.

## 12. Resultados finais e limitações

Concluídos: revisão documental, propostas visuais dos contextos pedidos/estados, comparação actual/proposta, contraste calculado, ensaios de browser, compatibilidade e plano progressivo. Verificações documentais finais: links/JSON/sintaxe/PNGs e diff de áreas protegidas; registo em [document-validation.json](ux/phase4c2/document-validation.json).

Não executados nesta fase: testes Flutter novos, build APK, Actions para código novo, migração, dados reais, pesquisa com participantes ou validação Android nativa. Os **254 testes e dois workflows verdes** pertencem à base 4B, registados na 4C.1; não se reutilizam como prova de implementação dos protótipos.

Os artefactos disponíveis permitem maquetas HTML verificáveis com fontes locais, tokens e frames delimitados. A fidelidade é de hierarquia/estados/componentes e fluxos propostos; não equivalência de pixels/gestos/IME/navegação/serviços Flutter. Se a revisão exigir aparência nativa exacta, essa parte permanece pendente de um protótipo Flutter isolado ou da implementação explicitamente autorizada, não substituída por descrições vagas.

Sem alterações de produção, dependências ou lógica de negócio. Sem merge automático. **A Fase 4C.3 não foi iniciada e depende de aprovação explícita.**
