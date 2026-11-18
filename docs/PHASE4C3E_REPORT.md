# Fase 4C.3E — Progresso e Percurso

Data: 18 de Novembro de 2026. Implementação Flutter efectiva; sem merge e sem início da Fase 4C.3F.

## 1. HEAD e branch

Base final 4C.3D: `ffc9b0b48da024c566c3ee2b5d47a636495bc840`, confirmada localmente e no remoto, com árvore limpa. Branch isolado: `feat/fase-4c3e-progresso-percurso`. A baseline passou 318/318 testes antes de alterações. O commit desta implementação e o estado final da CI ficam registados na secção 14; o HEAD final pode incluir a actualização documental dessa evidência.

Foram lidos AGENTS.md, contratos V2, Design System existente e 2.0, relatórios anteriores, matriz de contraste, acessibilidade, protótipos e plano C3. As restrições de domínio foram preservadas.

## 2. Auditoria das fontes

Ver [auditoria detalhada](ux/phase4c3e/AUDIT.md) e [preservação](ux/phase4c3e/preservation.json). A rota activa era ProgressScreen/ProgressPanel; a apresentação antiga em screens.dart não era o ecrã desta rota.

| Fonte | Informação utilizável | Limite |
| --- | --- | --- |
| Tasks | completed e completed_at | Reabertura/eliminação altera a visão actual; não é arquivo imutável |
| HabitCompletions | dia efectivamente registado | Sem hora; nome actual do hábito |
| StudySessions | completed e completed_at | Início planeado não prova realização |
| GoalProgress | valor e recorded_at | Sem unidade/nome históricos |
| Goals | estado, valor, alvo e unidade actuais | Estado concluído não fornece data de realização |
| ExperienceEvents | pontos, origem técnica e created | Reconhecimento separado; não duplicar actividade |
| Achievements | catálogo existente e unlocked_at | Sem novas conquistas/recompensas |

Datas ausentes ou inválidas não recebem datas substitutas; datas futuras ficam fora da cronologia apresentada. Não se usa criação, prazo ou início planeado como realização. Horas UTC seguem a convenção existente de Maputo; timestamps sem fuso mantêm a interpretação civil existente.

## 3. Alterações visuais reais

Progresso passa a usar PremiumScope, superfícies opacas, tipografia e papéis semânticos existentes. A primeira meta usa profundidade clay discreta; não há cartões aninhados, blur, glass decorativo ou dependências novas. O título duplicado foi removido. A rota e a navegação principal mantêm-se.

## 4. Hierarquia

Actividade recente dos últimos sete dias surge primeiro, inicialmente com três registos e expansão progressiva. Seguem-se evolução de metas numéricas, hábitos/estudo, acesso opcional ao Percurso e, secundariamente, histórico/indicadores e revisão. Estados vazio, carregamento, erro e repetição da leitura são distintos. As origens usam as rotas existentes, com nomes honestos: Ver meta ou Ver tarefas/hábitos/estudos, conforme a granularidade disponível.

## 5. Indicadores

Metas mostram valores, alvo e unidade actuais, com filtros Em curso/Alcançadas e acesso às restantes metas. Não há novos modos de metas, percentagens artificiais, produtividade ou sucesso inferidos. Hábitos e estudos mostram contagens observáveis. As sete contagens semanais preservam activityWeek; as antigas barras normalizadas relativas foram substituídas por texto explícito. Nenhum cálculo financeiro ou de domínio foi alterado.

## 6. Actividade e limites

Uma projecção de leitura reúne quatro fontes, usando identidade tabela/id, sem duplicar XP. Conclusões de tarefas reabertas deixam de figurar. Conclusões de estudo exigem o indicador concluído. Hábitos indicam explicitamente que a hora não foi registada. Registos de metas apresentam o valor efectivamente guardado sem atribuir uma unidade histórica desconhecida. Nomes e associações são os actuais, conforme aviso no ecrã.

Registos sem data válida têm divulgação própria, limitada inicialmente a vinte linhas, sem inventar cronologia. Existe indicação separada de datas futuras. A leitura não representa um arquivo completo de eventos eliminados.

## 7. Percurso

Modal opcional, com SafeArea, lista preguiçosa e vinte entradas por página. Linha estática agrupa apenas entradas do mesmo dia; ligações significam proximidade de calendário, não causalidade, importância ou dependência. Não existem constelações aleatórias, animação contínua ou novas recompensas. Filtros seleccionam sete dias ou todo o histórico datado disponível. O controlador de scroll é independente e começa no início; Fechar recebe foco inicial.

Medição Linux debug, uma preparação e dez amostras: mediana da projecção 3,898 ms/100 registos, 8,182 ms/1 000 e 45,009 ms/10 000; máximos 4,161/33,195/63,104 ms. Apenas três linhas de actividade ficaram montadas na primeira apresentação. Ver [resultados e método](ux/phase4c3e/performance-results.json). O primeiro build inclui preparação de fontes, pelo que não é directamente comparável entre tamanhos. Não foi medido desempenho Android físico.

## 8. Alternativa textual

Linha e Lista usam o mesmo snapshot, ordenação, filtros, identidade e componente de entrada. A Lista remove apenas a decoração da linha. Datas, precisão disponível, valores e acessos à origem mantêm-se. A decoração não acrescenta informação sem equivalente textual.

## 9. Preservação de XP e dados

O leitor local consulta nove tabelas por carregamento e não chama operações de escrita, sincronização ou atribuição de XP. Filtros, Percurso, Lista e histórico não voltam a consultar nem alteram dados. Os testes com repositório que rejeita escritas e comparação integral das tabelas verificam isto, incluindo gamificação desligada. O retorno de uma origem invalida apenas este leitor para reflectir edições reais.

Limite importante: o dataProvider global já executava syncAchievements no arranque da aplicação. Esse comportamento existente não foi alterado. A garantia de leitura aplica-se ao leitor/componente Progresso isolado e à navegação a partir da aplicação já carregada; não se afirma que todo o arranque global passou a ser isento de escrita.

Catálogo de quatro conquistas, fórmulas, idempotência, regras e ledger de XP mantêm-se. Desligar gamificação oculta a apresentação sem apagar histórico. SQLite v5, lifeos.sqlite, modelos, repositórios, TaskOperations, notificações, Android ID, dependências e lock permanecem intactos. Só foram usados dados sintéticos nos ensaios.

## 10. Capturas antes/depois

[Comparações e índice completo](ux/phase4c3e/CAPTURES.md): 328 PNG do renderer Flutter, 164 pares com dimensões correspondentes, temas claro/escuro e larguras 320/360/390 a 100%/200%. Incluem vazio, preenchido, recente, metas, hábitos/estudo, indicadores, Percurso/Linha/Lista, legado, muitos registos, foco e gamificação desligada.

Vinte pares externos (Hoje, Planear, Metas, Tarefas, Finanças, Hábitos, Agenda, Estudos e formulários) são byte a byte idênticos. Ver [hashes e dimensões](ux/phase4c3e/visual-validation.json). Antes, funcionalidades inexistentes como Percurso são representadas pelo ponto de entrada antigo com os mesmos dados, sem fingir que existiam.

A captura inicial falhou em dois enquadramentos antigos por procura de conteúdo ainda não construído; o auxiliar foi corrigido e as capturas antigas completadas antes de modificar produção. A execução final passou 164/164 cenários. São capturas de testes Flutter, não fotografias de um dispositivo Android.

## 11. Contraste, foco e alvos

Os papéis aprovados foram reutilizados: mínimos claro/escuro de texto secundário 4,814/7,297:1, texto principal 12,292/11,644:1, acção 5,034/6,951:1 e contorno 4,173/4,508:1. Não foram criadas cores de domínio adicionais. Foco tem contorno de 2 dp com separação de 2 dp. Selecção, pressão, desactivação e erro reutilizam os componentes e estados existentes; expansão usa a cor de acção em ambos os estados.

Testes verificam alvos internos de pelo menos 48×48 dp, foco por teclado, semântica, preferências de movimento reduzido, temas e matriz de tamanhos/texto. A linha decorativa tem equivalente textual. A abertura a 320 dp/200% mantém a primeira actividade alcançável e visível. Não se declara conformidade integral WCAG: TalkBack, navegação assistida e desempenho em equipamento físico continuam por validar.

## 12. Testes

- Baseline: 318 aprovados.
- Suite final: **345 executados, 345 aprovados, zero falhas, ignorados ou erros de execução**.
- 27 novos testes cobrem fontes/datas/ausências/futuro, limites da projecção, leitura sem escrita, matriz de 12 combinações, origens, navegação, filtros, gamificação, erro/carregamento, foco, alvos e construção preguiçosa com 10 000 registos.
- 31 testes dirigidos (27 novos + quatro anteriores) passaram; as asserções de domínio anteriores permanecem. O teste visual das barras passou a verificar sete contagens textuais reais.
- Capturas: 164/164; benchmark: 1/1, fora da contagem canónica.
- dart format: sem alterações pendentes; flutter analyze: sem problemas. Os nove testes Python do processador de resultados também passaram.

[Evidência estruturada](ux/phase4c3e/test-results.json). Os comandos de reprodução das capturas estão no respectivo índice. A suite completa foi executada com flutter test --no-pub --machine e validada pelo processador de resultados existente.

## 13. Build Android

flutter build apk --debug --no-pub passou; execução final local de 14,3 s com toolchain já preparada. Não se alteraram configuração Android, identificador nem dependências. O build prova compilação; não substitui ensaios físicos de acessibilidade ou desempenho.

## 14. GitHub Actions

Commit de implementação publicado: `691696ae99c47e31e845cee9378a1fd1ca6bfd25`.

- [Flutter validation — sucesso](https://github.com/MxxSultane/tudoaki/actions/runs/44405406201): 345/345 testes; zero falhas/ignorados/erros; 115 ficheiros formatados sem alterações; análise sem problemas; format=0 analyze=0 test=0 lock=0.
- [Android debug validation — sucesso](https://github.com/MxxSultane/tudoaki/actions/runs/44405406207): APK debug compilado e preservação do projecto confirmada.

Os dois workflows existentes receberam exclusivamente o novo branch na lista de push; os passos e permissões não foram alterados. Este relatório é actualizado num commit documental posterior; os resultados do HEAD desse branch podem ser consultados na [lista de execuções](https://github.com/MxxSultane/tudoaki/actions?query=branch%3Afeat%2Ffase-4c3e-progresso-percurso). Não há merge automático.

## 15. Ficheiros modificados

Produção: lib/app/app.dart (escopo visual apenas em /progress); progress_screen.dart; progress_panel.dart; novos progress_activity.dart, progress_read_provider.dart e progress_journey.dart em lib/features/progress. Regras em progress_rules.dart intactas.

Verificação: test/progress_test.dart, novos test/phase4c3e_progress_test.dart e test/support/progress_fixture.dart; tool/capture_progress.dart e tool/benchmark_progress.dart. Entrega: este relatório, docs/ux/phase4c3e, capturas docs/ux/previews/phase4c3e. CI: os dois ficheiros de workflows, apenas elegibilidade do branch.

## 16. Regressões encontradas e corrigidas

A primeira versão dos controlos de Percurso ocupava demasiado espaço a 320 dp/200%, escondendo a primeira actividade. Um teste reproduziu a situação; selectores compactos, legenda curta e data abreviada corrigiram-na, com verificação posterior. O modal recebeu controlador próprio e foco inicial seguro para não herdar posição da página de origem.

Falhas intermédias dos auxiliares (procura antes da construção preguiçosa, comparação de exportação com timestamp variável e espera de escrita de ficheiro em relógio de teste) foram corrigidas sem alterar regras de produto. Um conflito de construtor const com campo calculado e uma regra de formatação foram resolvidos antes da suite final. Não foram detectadas regressões funcionais na suite completa ou diferenças nas vinte capturas externas.

## 17. Limitações

A memória contém os nove conjuntos lidos; a paginação é de apresentação, não SQL. A ordenação cresce com o volume de dados; 10 000 registos foram medidos apenas em Linux debug. Não há polling contínuo. A lista de metas inicial apresenta três, com acesso à lista existente; registos sem data têm limite de apresentação e acesso às respectivas origens. Nomes actuais, reaberturas e eliminações impedem prometer um diário histórico imutável. Não há equivalência entre número de registos e produtividade ou sucesso.

A aplicação global mantém a sincronização preexistente de conquistas no arranque. Acessibilidade física/TalkBack e perfil de desempenho Android permanecem pendentes. As comparações externas cobrem os cenários seleccionados, não todas as combinações possíveis da aplicação.

## 18. Recomendação para 4C.3F

Após aprovação, priorizar validação em Android físico (TalkBack, teclado, escalas, contraste em contexto e profiling), compreensão da distinção entre actividade e XP e volumes reais. Qualquer revisão do contrato global de sincronização no arranque ou paginação SQL deve constituir trabalho separado, com autorização e testes de domínio. Não iniciar 4C.3F nesta entrega.
