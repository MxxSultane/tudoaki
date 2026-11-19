# Fase 4C.3F — integração visual, acessibilidade e validação global

19 de Novembro de 2026. Correcções reais Flutter, sem merge, release, APK de produção ou novas funcionalidades. A evidência automatizada não substitui os gates físicos abaixo.

## 1. HEAD, branch e preparação

Origem final confirmada local/remoto: `feat/fase-4c3e-progresso-percurso`, **98d281385bd02ccd47ac97cafbc698efeb29682f**, árvore limpa. Criado directamente `feat/fase-4c3f-integracao-global`. Baseline **345/345**, zero falhas/ignorados/erros, antes de alterar produção. Flutter 3.35.7, Dart 3.9.2, Java 21; ambiente já preparado, sem dependências novas.

Lidos AGENTS.md, V2_CONTRACTS, DESIGN_SYSTEM histórico/2.0, relatórios 4B–4C.3E, compatibilidade/acessibilidade/contraste e plano C3 da 4C.2; consideradas as capturas/protótipos e auditorias anteriores, sem repetir a investigação de hábitos/finanças. Restrições históricas de fases anteriores não anulam a autorização de implementação desta fase.

Sequência preservada: 4C.3A `3b86f88`, 4C.3B `058ae62`, 4C.3C `49e1724`, 4C.3D `ffc9b0b`, 4C.3E `98d2813`, todos antepassados do branch actual. [Verificação estruturada](ux/phase4c3f/preservation.json). Commit de implementação publicado: **6890cb248ee67323a82c3f57c0b3430f86a5b43d**. A CI é registada na secção 10; o histórico do branch identifica o HEAD documental final.

## 2. Auditoria visual global

[Inventário, classes A–F e decisões](ux/phase4c3f/AUDIT.md). Foram inspeccionadas as rotas activas e componentes, em vez de tomar implementações legadas inactivas por ecrãs de produção. Hoje, Planear, Metas/formulário/detalhe, Estudos, Finanças, Progresso/Percurso, Tarefas, Agenda, Hábitos, Mais, Revisões/Definições, navegação, FABs, editores, diálogo de eliminação, carregamento, erro e mensagens existentes estão abrangidos por leitura e cenários automatizados. Notificações são verificadas pelas regras/testes existentes; o serviço não foi alterado nem se afirma entrega real num telefone.

Achados prioritários: rótulos da barra limitados a 130% apesar de escala pedida 200% (C); animação da barra ignora movimento reduzido (C); mistura de temas/contornos (A/C); espaçamento/caixa de Mais (A/B); editor legado sem foco independente/Cancelar explícito (A/C); erro sem scroll numa janela baixa (C); selector de aparência transborda na integração a 320/200 (C); entrada Progresso → Tarefas empilha o shell existente e provoca asserção de page keys (D). Não foram detectados dados corrompidos ou novas falhas de cálculo. Limites E/F existentes são bloqueios técnicos, não alterações silenciosas.

## 3. Correcções implementadas

- Shell, planeador semanal e AreaScaffold usam PremiumScope existente. Rotas, guardas, observadores e StatefulShellRoute.indexedStack mantêm-se.
- WorkspaceNavigationBar conserva NavigationBar/destinos nativos e a mesma callback. O estilo do rótulo aplica a escala pedida uma vez, desactivando apenas a segunda escala/clamp interna do Material; a 200%, 13 dp torna-se efectivamente 26 dp. Altura é medida pelo texto; ícones usam action/muted; foco tem contorno independente; movimento reduzido dá duração zero. Não se diminui fonte para caber.
- Mais passa de uma caixa com espaçamento excessivo para lista plana, título e foco por entrada. Nove acessos/textos mantidos.
- Editor partilhado reutiliza premium, título de 22, rótulos com quebra, mensagens de erro com até seis linhas e contorno independente dos campos. Tarefa/Evento/Hábito e outros editores legados recebem Cancelar explícito, com o mesmo cancelamento sem gravação. Não se reconstroem formulários nem operações.
- WorkspaceLoadState reúne carregamento e erro de leitura, com semântica e scroll em alturas baixas; mantém mensagens e repetição de leitura.
- Tarefas e Agenda usam PremiumFilter para visto e estado seleccionado acessível; critérios/ordenação não mudam.
- Definições permite altura variável, aparência expandida e código ISO fechado com nomes completos no menu de moeda; moedas/valores/regras intactos.
- Progresso usa a navegação de ramo existente para Tarefas/Metas, evitando empilhar uma segunda instância do shell. Detalhes e áreas fora do shell mantêm push/retorno e invalidação do leitor local.
- Na altura reduzida do planeador semanal, os mesmos sete dias e rodapé ficam numa lista rolável única. Nas alturas normais mantém-se o rodapé anterior. Movimento reduzido também se aplica à aproximação ao dia seleccionado.

## 4. Compatibilidade entre módulos

Hoje conserva ordem, FAB e fontes; Planear conserva modos, contexto, selecção e semana; Tarefas conserva associações, CRUD, reagendamento, notificações e XP; Agenda conserva eventos/fontes académicas e formatos de datas. Metas permanece exclusivamente numérica, com formulário, histórico e conclusão/reabertura existentes. Estudos/Finanças/Progresso mantêm as apresentações implementadas em C–E e respectivas operações.

[Preservação](ux/phase4c3f/preservation.json): Android/identificador, SQLite v5/lifeos.sqlite, schema/repositórios/modelos, TaskOperations, regras financeiras/académicas/XP, focus_timer, serviços de notificações, contratos de navegação, providers, dependências e lockfile intactos relativamente à base desta fase. A alteração em app.dart é apresentação do shell, não registo de rotas. Nenhum dado real foi aberto, migrado ou limpo.

## 5. Percursos funcionais testados

São testes widget de integração com a aplicação/repositórios reais e SQLite sintético, não instrumentação Android. A cobertura combina sequências já existentes com os novos casos; não se afirma que cada letra corresponde a um único teste monolítico.

| Percurso | Evidência na suite executada | Efeitos verificados |
| --- | --- | --- |
| A — Tarefas | phase3f_task_journey, task_delete_flow, task_operations e planning_screen | Criar/editar/reagendar/concluir/reabrir/eliminar, mesmos ID/created/relações, notificações e XP idempotente |
| B — Metas | phase4c3b_goals, goal_planning_widget, goal_planning, repository | Criação numérica explícita; edição; valores/histórico; conclusão/reabertura pela regra existente; reabertura de SQLite sintético com legado exacto |
| C — Estudos | academics_widget, phase4c3c_studies e focus_lifecycle | Disciplina/associações, trabalho criado/editado, sessões, pausa/retoma/conclusão explícita, limites e idempotência XP |
| D — Finanças | phase4c3d_finance, finance_widget, currency/finance | Receita/despesa, moeda/mês, edição exacta, totais, revisão/cancelar/confirmar/segunda revisão de recorrências e reabertura sintética |
| E — Progresso | Novo caso journey E em phase4c3f_global; phase4c3e_progress | Criar/concluir tarefa pela UI, observar actividade, abrir Percurso, Linha/Lista, Ver tarefas e Ver todas as metas; sem nova escrita ou XP; fontes/datas reais |
| F — Hábitos | phase4b e legacy_modules | Três hábitos distintos, registo/consulta/edição, saída/regresso e fecho/reabertura SQLite; XP diário único |
| G — Planeamento | phase3f_task_journey, phase4c3c_studies, planning_screen/dates e navigation_v2 | Trabalho/tarefa criado em Estudos/Hoje, consulta cruzada, reagendamento e contexto/associações preservados |

Novo caso adicional verifica Planear → Todas as tarefas; esse caminho já passou sem erro e não foi alterado. Novo caso semanal verifica os sete dias e criação/cancelamento a 320/200. Doze novos casos percorrem as áreas com snapshots integrais antes/depois e verificam ausência de alterações ao consultar/navegar. Não foram inventadas entidades bancárias, metas binárias/por etapas ou data de realização ausente.

## 6. Acessibilidade

[Contraste calculado dos papéis usados](ux/phase4c3f/contrast-results.json): ink/muted/action ≥4,5:1 e outline ≥3:1 em background/surface/soft, ambos os temas; reutilização da matriz aprovada, sem nova paleta. Testes premium anteriores continuam a verificar todos os getters/estados. Os cálculos são de cores opacas especificadas; não certificam todos os pixels de todos os ecrãs.

Novos testes medem rótulos da barra à escala integral, alvos ≥48×48, contorno focado de 2 dp, movimento reduzido, foco/Tab, campos/erros, cancelamento, teclado simulado, scroll e compatibilidade 320/360/390 × 100/200 × claro/escuro. Semântica nativa de destinos, estado seleccionado de filtros e texto equivalente do Percurso mantidos. SafeArea e guardas de modais não foram removidos.

Na barra de quatro destinos a 320/200, os rótulos podem quebrar naturalmente; não se ocultam nem se reduz a escala. A compreensão dessa quebra e a ordem de leitura TalkBack necessitam de validação física/humana. Ensaiou-se também erro em janela horizontal curta; não se declara ensaio exaustivo de todas as orientações/IMEs. WCAG 2.2 AA é referência, não certificação automática.

## 7. Android

Build debug local aprovado: **assembleDebug final 31,7 s**, Flutter 3.35.7/Java 21. Artefacto local ignorado pelo Git; sem publicação de APK de produção ou release. O workflow Android remoto é registado na secção 10.

Não há telefone físico acessível confirmado: /dev/bus/usb não está exposto, e ADB abortou ao tentar inicializar preferências no directório de utilizador protegido. Não se alterou HOME, permissões, assinatura, instalação ou dados para contornar esse limite. Não se considera a falha de enumeração prova de que não existe um dispositivo fora deste ambiente.

[Roteiro manual exacto](ux/phase4c3f/ANDROID_MANUAL_QA.md): compatibilidade de assinatura antes de actualizar, preservação de dados v5, TalkBack, IME/teclado real, escalas, interrupção/retoma, notificações, gestos/SafeArea e medição de desempenho. Gate físico permanece aberto.

## 8. Desempenho e estabilidade

[Resultados/método](ux/phase4c3f/performance-results.json): Linux Flutter debug, uma preparação e dez amostras, dados sintéticos em memória, com outras validações concorrentes no ambiente. Projecção mediana: **5,686 ms/100**, **7,148 ms/1 000**, **50,798 ms/10 000**; máximos 32,514/41,458/97,807 ms. Primeira construção inclui fontes (1712,215/309,387/141,883 ms), não é medida de frames nem directamente comparável entre tamanhos.

A primeira vista monta três linhas de actividade; o teste de 10 000 registos verifica delegados preguiçosos de 20→40 no Percurso. Nove leituras por carregamento; alternar filtros/vistas não reconsulta o repositório. Navegação, abertura/fecho de modais, scroll, erro/repetição, estado dos ramos e interrupção/retoma lógica de foco são abrangidos pelos testes. Não se mediram p95 de resposta, memória, consumo ou jank Android: devem ser recolhidos no roteiro físico. Sem blur ou animação contínua novos.

## 9. Capturas antes/depois

[Índice navegável e comparações](ux/phase4c3f/CAPTURES.md), [hashes/dimensões](ux/phase4c3f/visual-validation.json): **672 PNG, 336 pares**, mesmos dados/relógio/dimensões. 28 cenários × dois temas × três larguras × duas escalas, incluindo todos os módulos principais, Mais/barra, vazio/preenchido, editores, foco, erro/carregamento, diálogo real de eliminação e teclado simulado na criação rápida a 200%.

A baseline foi recolhida antes de modificar produção; doze casos de hábito tiveram correcção do contexto do auxiliar e foram completados nessa base. As doze capturas de foco da barra foram recolhidas novamente numa worktree isolada do HEAD base com foco no destino correcto. Não se substituíram imagens antigas por código novo. A primeira matriz posterior encontrou dois overflows semanais, corrigidos antes da execução estrita final. As capturas não são maquetas/HTML nem teste Android físico. A revisão manual amostrou imagens representativas; a matriz automatizada não equivale a inspeccionar manualmente todos os PNG.

## 10. Testes e GitHub Actions

Baseline 345/345. **22 testes novos**: matriz global 12, editores Tarefa/Evento/Hábito nos dois temas 6, erro horizontal curto 1, percurso E integrado 1, semana 320/200 1 e Planear→Tarefas 1. Os testes anteriores de Planear reproduzem também o caso de teclado residual. Os 22 passaram na execução dirigida; **suite final local: 367/367, zero falhas, ignorados ou erros de execução**. A execução dirigida de regressões passou 56/56. Formatação local: 120 ficheiros, zero alterações; flutter analyze: sem problemas; nove testes Python do processador aprovados.

Capturas estritas finais: 336/336; foco dirigido: 12/12; benchmark separado: 1/1. Estes ensaios auxiliares não são somados à contagem canónica da suite. Formatação, análise, processamento dos resultados, suite e CI ficam também no [resumo estruturado](ux/phase4c3f/test-results.json).

Os dois workflows existentes receberam apenas este branch nas listas de push, sem reduzir verificações, mudar permissões ou publicar release. Commit de implementação **6890cb248ee67323a82c3f57c0b3430f86a5b43d**, com ambos os workflows concluídos com sucesso:

- [Flutter validation — 44503822474](https://github.com/MxxSultane/tudoaki/actions/runs/44503822474): 367/367, zero falhas/ignorados/erros; 118 ficheiros de lib/test sem alterações de formato; análise sem problemas; format=0 analyze=0 test=0 lock=0.
- [Android debug validation — 44503822426](https://github.com/MxxSultane/tudoaki/actions/runs/44503822426): compilação debug e verificações de preservação aprovadas, sem release.

O fecho posterior altera exclusivamente documentação/evidência, preservando produção/testes/capturas do SHA validado. O HEAD documental volta a accionar os dois workflows; [consultar execuções do branch](https://github.com/MxxSultane/tudoaki/actions?query=branch%3Afeat%2Ffase-4c3f-integracao-global). O histórico Git identifica o HEAD final sem introduzir uma auto-referência de commit no seu próprio conteúdo.

## 11. Ficheiros modificados

Produção: app/app.dart; novos core/widgets/workspace_navigation_bar.dart e workspace_load_state.dart; workspace_page.dart e legacy_section_page.dart; agenda_browser.dart; areas_screen.dart; forms.dart; progress_screen.dart; settings_screen.dart; tasks_screen.dart; planning_screen.dart e weekly_planner_screen.dart.

Verificação: novo test/phase4c3f_global_test.dart; ajustes de âmbito em test/task_delete_flow_test.dart, test/weekly_planner_widget_test.dart e test/phase4c3a_pilot_test.dart; tool/capture_global.dart; parâmetro opcional de saída em tool/benchmark_progress.dart (default anterior preservado); tool/validate_global_evidence.py. Evidência: este relatório, docs/ux/phase4c3f e docs/ux/previews/phase4c3f. CI: flutter-validation.yml e android-debug-validation.yml, só branch. Três testes de apresentação anteriores foram ajustados ao âmbito autorizado: foco/Cancelamento no diálogo exacto, scroll para um evento real e tema premium em Planear. As verificações de dados/negócio nesses testes foram preservadas.

## 12. Regressões corrigidas

Reprodução vermelha confirma limite 130%/movimento da barra, ausência de tema/foco no editor e erro sem scroll. O percurso E reproduziu asserção de chaves de página também com app.dart da base: a origem de ramo do shell não podia ser novamente empilhada; a correcção usa a navegação existente para esse ramo. Detalhes não foram convertidos indiscriminadamente em navegação sem retorno.

Três problemas foram revelados pela própria integração: o rodapé diário com insets de teclado ainda presentes, aparência em Definições a 320/200 e rodapé semanal quando a barra passou a respeitar a escala integral. Foram corrigidos com regressão automatizada; as capturas foram repetidas. Uma procura inicial do foco por InkWell falhou por o destino usar outro widget interno; passou a usar o contexto do rótulo, sem tratar essa falha do auxiliar como defeito do produto. O contexto de captura de hábito também foi corrigido. A primeira suite completa intermédia terminou com 360/367: os sete casos correspondiam aos dois temas do teclado, Cancelar ambíguo, evento ainda fora do viewport, dois temas do antigo limite de âmbito do piloto e overflow semanal. Após correcções e ajustes de selecção/âmbito explicitados, 56/56 testes dirigidos passaram. Uma execução anterior à estabilização foi interrompida e não é usada como evidência final. Nenhuma destas falhas intermédias foi contada como aprovação.

## 13. Limitações

Não houve Android físico, instalação/actualização compatível, TalkBack, IME/teclado real, notificações reais, brilho/sol, profiling mobile ou estudo com pessoas novas. Renderer/testes widget não provam esses resultados. Uma fase técnica concluída não significa aprovação de distribuição final.

Rótulos da barra estreita ampliada quebram; avaliar compreensão. Listas/editores legados mantêm as capacidades e operações existentes; não se promete novo descarte universal de rascunhos. A revisão de screenshots é amostrada. Não se afirma que todos os estados possíveis de todos os editores foram fotografados, nem conformidade WCAG integral. A fonte histórica de Progresso conserva os limites documentados na 4C.3E.

## 14. Bloqueios técnicos

- **E01:** sincronização global preexistente de conquistas ao ler dataProvider. Leitor Progresso continua separado e sem escritas; tornar todo o arranque global puramente de leitura exige decisão específica, sem mudar regras nesta fase.
- **F01:** nove tabelas completas em memória no Progresso; paginação só visual. Qualquer paginação SQL, novo índice ou contrato de histórico deve ser trabalho autorizado separado, suportado por medições físicas.
- **Dados de Metas:** modos binário/por etapas e qualquer discriminador/migração continuam bloqueados; não activados.
- **Android físico/assinatura:** sem dispositivo e certificados compatíveis verificados não se pode aprovar actualização, acessibilidade real ou desempenho mobile.

## 15. Proposta de integração Git

Destino proposto: **main**, que no remoto continua em **9283217523f9952221c98996b56a90b1fbe383dd**; não se partiu dele para implementar esta fase. A diferença acumulada inclui preparação, 4B, design e 4C.3A–F; não é um patch apenas visual de F. A lista de antepassados/hashes está na preservação e o diff completo deve ser revisto antes de integrar. O [inventário do commit de implementação](ux/phase4c3f/integration-diff.json) regista 2 194 ficheiros acumulados face a main (51 em lib e 2 088 de documentação/evidência), versus 705 nesta fase (13 em lib). Estes números identificam o SHA de implementação, não incluem o fecho documental posterior.

Recomenda-se PR do branch actual para main com todos os commits já encadeados (3f8d81e, afdd6fa e correcções de métricas, b0635e8, a2e808b/df7a840, 691696a e implementação F), sem cherry-pick parcial nem squash que esconda os gates. Verificar CI no HEAD final, invariantes protegidas e teste manual Android antes de aprovar versão candidata. Não se abriu release nem se executou merge.

Riscos: adopção partilhada do tema pode revelar estados ainda não amostrados; barra ampliada reduz altura útil; dados/históricos legados têm limites; Android físico pendente. Reversão: reverter o commit de F para regressar visualmente a 98d2813, mantendo schema/contratos intactos; antes de distribuir, validar compatibilidade da versão e assinatura. Não restaurar um ficheiro SQLite antigo nem prometer que Git recupera dados de utilizadores. Para integração acumulada, preferir revert do merge pelo responsável após revisão, sem reset destrutivo de main.

## 16. Critérios de aceitação da versão candidata

| Critério | Estado desta entrega |
| --- | --- |
| Base 4C.3E e sequência A–E, branch isolado e dados protegidos | Confirmado |
| Correcções Flutter reais e evidência antes/depois | Confirmado; 336 pares |
| Regressões/foco/alvos/texto/temas e percursos sintéticos | 367/367 na suite completa; 22 novos testes; CI na secção 10 |
| Build Android debug | Aprovado localmente; CI na secção 10 |
| Actualização sem perda de dados/assinatura | Pendente em dispositivo de testes compatível |
| TalkBack, teclado/IME, orientações/gestos e compreensão | Gate manual pendente |
| Desempenho Android representativo | Gate manual pendente; medição Linux explicitada |
| Revisão/integração/release | Não executadas; dependem de decisão do responsável |

A entrega fornece uma candidata técnica para revisão, sem certificar versão final. Não iniciar funcionalidades novas, merge ou publicação sem aprovação específica.
