# Critérios de aceitação, limites e ordem recomendada

## Revisão da especificação 4C.1

| Critério | Evidência documental | Estado nesta entrega |
| --- | --- | --- |
| Base final 4B validada, com três correcções | README: HEAD 79470b8, dois runs SUCCESS; branch isolado | Confirmado |
| Todos os pares de tokens calculados | CSV 578 pares, JSON 92 utilizações; calculador sRGB | Verificado matematicamente |
| Pares insuficientes corrigidos/proibidos | Whitelist fechada, cinco exemplos proibidos, sem branco/Sage | Especificado e calculado |
| Foco para todo controlo | ACCESSIBILITY: inventário e máquina de estados; anel 2 dp | Especificado; execução nativa pendente |
| Dimensão táctil | Todos ≥48 dp, FAB 56, espaçamento 8; unidades distinguidas | Especificado; widget futuro pendente |
| Hierarquia dos seis contextos | AUDIT, MODULES, FORMS, seis wireframes nos dois temas | Proposta completa |
| Divulgação progressiva | Formulários tarefa e meta; preservação explícita de campos | Especificado |
| Clay/glass legíveis | SURFACES, glass composto em dois fundos/tema, fallback sólido | Especificado e calculado; render Flutter pendente |
| Claro/escuro, 200%, ecrã pequeno | Tokens próprios, prancha redimensionável e requisitos 320/360/390 | Protótipo conceptual; não certifica Flutter |
| Compatibilidade documentada | GOALS e COMPATIBILITY: legado, modos ausentes no v5, serviços intactos | Bloqueios explícitos, sem migração |
| Limitações identificadas | Este documento e README | Sem alegação de conformidade integral |

A especificação pode ser revista como pacote de design. A recomendação para implementação visual é **condicional**: aprovação de produto, medição nativa e incrementos abaixo. A criação de modos de metas tem bloqueio adicional de arquitectura/dados; não deve ser tratada como tarefa puramente visual nem activada apenas por aprovar cores.

## Cenários obrigatórios da futura implementação

| Área | Cenários e resultado esperado |
| --- | --- |
| Contraste | Testes automatizados de todos os tokens usados por estado/tema; falhar se novo par não aprovado. Verificar glass composto e fallback; não aprovar por valor arredondado |
| Dimensões/foco | Widget tests ≥48×48 dp, Tab/Shift+Tab, Enter/Espaço, setas, foco restaurado, modal aninhado, anel não recortado. Todas as acções continuam acessíveis sem hover |
| Reflow | 320/360/390 dp, vertical/horizontal, 100/200%, teclado, SafeArea, texto/valores longos; zero overflow/perda de sinal ou rótulo; foco integralmente visível quando couber |
| Acessibilidade manual | TalkBack real, teclado físico, ordem/nome/função/valor, exploração por toque; movimento/transparência reduzidos. Contraste em dispositivo real, brilho/sol e desempenho |
| Hábitos / 4B | Criar ≥3 distintos, editar/concluir/reabrir; nenhum duplicado ou novo XP além das regras; botão permanece em lista preenchida |
| Tarefas / 3B–4B | Guardar/Guardar outra, erro/recusa de lembrete, bloqueio de duplo envio/fecho, rascunho e retorno; mesmo ID/due/created/relações; sem nova implementação TaskOperations |
| Binárias | Criar só com nome, sem %, concluir e reabrir explicitamente, falha mantém estado anterior, nenhum XP novo |
| Etapas | Sem etapas, 1/4 e 4/4, exclusão de etapa, editar nome/prazo, reabrir etapa em meta alcançada; não actualizar métrica/concluir silenciosamente |
| Numéricas/legado | initial não zero, valores abaixo/acima do intervalo, fracções, vírgula, NaN/infinito inválidos, histórico intacto, status conforme serviço; legado 0/1 não vira binário |
| Prazo meta | Vazio/1/30/3650; rejeitar 0/negativo/decimal; limite 2100; meia-noite; data civil versus timestamp; editar só nome mantém due exacto |
| Estudos | Avaliação/tarefa/sessão abrem origem certa; foco/retoma, disciplinas, horários, trabalhos e histórico acessíveis, sem duplicação de Agenda |
| Finanças | Mesmos totais/precisão por moeda/mês; registar/editar/excluir, poupança, orçamento, recorrência só após confirmar, não gerar ao abrir |
| Progresso | Actividade com/sem gamificação, zero/ausência de histórico, reabertura/eliminação, títulos indisponíveis; alternativa textual completa e sem novos eventos XP |
| Persistência futura | Migração aditiva sintética e round-trip aprovados antes de modos; nenhuma base real; dados/IDs/relações/histórico preservados ao abrir/cancelar |
| Regressão geral | Suite actual de 254 como base, análise/formatação e Actions pertinentes; Android debug não certifica instalação/actualização/assinatura |

## Ordem recomendada, ainda não autorizada

1. **Revisão de design e compreensão**: avaliar os seis contextos com pessoas novas, incluindo baixa visão/leitor de ecrã; confirmar terminologia e descoberta de capacidades. Resolver escolhas de metas/prazo e discriminar preferências de requisitos.
2. **Contrato técnico de metas em separado**: definir discriminador aditivo, envelope, operações de conclusão/reabertura, histórico, migração e exportação/restauro; aprovar antes de título-only durável. Sem conversão automática de legado.
3. **Fundamentos visuais/acessibilidade**: tokens, foco, alvos e estados em componentes isolados, com testes de contraste/widget e validação nativa; sem aplicar globalmente à Agenda/Tarefas.
4. **Piloto restrito de superfície plana**: um ecrã secundário e regressão de retorno/semântica, seguido de criação de tarefa com preservação integral 4B. Corrigir defeitos medidos antes de expandir efeitos.
5. **Metas e formulário novo**: só após o contrato técnico; três modos, legado, hierarquia e histórico. Validar com dados sintéticos e testes de reabertura.
6. **Estudos**: reorganizar entregas/disciplinas e retoma; preservar todos os editores e rotinas.
7. **Finanças**: tratamento próprio com igualdade de totais e acesso às funções, superfície plana. Não aproveitar a mudança para alterar cálculos.
8. **Progresso**: actividade real e lista acessível; experimentar painel visual opcional apenas após fontes/semânticas definidas. Percurso completo continua fora do âmbito.
9. **Revisão de conjunto e eventual distribuição**: teclado, leitores de ecrã, dispositivos, temas, 200%, desempenho, actualização/assinatura e risco de dados. Merge e distribuição dependem de autorização própria.

## Verificação executada nesta fase

Calculador: 92 utilizações aprovadas e 578 pares, sem falhas. Validação documental inclui links internos, parse XML de 12 SVGs, sintaxe Python/JavaScript do artefacto conceptual e correspondência de tokens. Comparação Git confirma alterações exclusivamente em docs/ux/phase4c1. Resultado mecânico final e limitações de preview são registados em WIREFRAMES.

Não foram executados novos testes Flutter, build, migração, ensaio sobre dados reais, instalação Android, TalkBack, teclado físico ou pesquisa com participantes nesta fase. Os resultados verdes da base não certificam estes protótipos. Não se afirma conformidade WCAG integral. Nenhum ficheiro existente de teste ou produção foi alterado; não houve merge nem implementação visual da app.
