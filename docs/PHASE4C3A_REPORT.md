# Fase 4C.3A — Design System e primeiro piloto Flutter

**Implementação real em Hoje e na lista principal de Metas.** Piloto limitado, reversível por código, sem migração ou adopção indiscriminada. Sem merge; 4C.3B não iniciada.

## 1. HEAD, branch e baseline

Base final 4C.2 confirmada localmente e por `git ls-remote`: **4832e693aa40efb372086944f8240b94ddc93aa8**, branch `docs/fase-4c2-revisao-ux`, árvore limpa. Criado directamente desse commit o branch **feat/fase-4c3a-design-system-piloto**. Mantém a base 4B 79470b8, incluindo hábitos múltiplos, FAB directo de Metas e criação rápida.

Lidos AGENTS.md, V2_CONTRACTS, DESIGN_SYSTEM histórico, relatório 4B, README/relatório 4C.1 e respectivo Design System/SURFACES, relatório 4C.2, revisão, contraste/tokens, acessibilidade, índice/protótipos e plano C3.0–C3.V. O relatório da 4C.1 é `docs/ux/phase4c1/README.md`; não existe um PHASE4C1_REPORT.md de raiz.

Flutter **3.35.7**, Dart **3.9.2**, Java **21**. Antes de alterar produção: análise sem problemas e **254 executados/aprovados, zero falhas/ignorados/erros**. Capturas da base real antes das alterações, complementadas num checkout isolado do mesmo SHA para repetir a matriz final com o mesmo utilitário/fixtures. Nenhuma alteração do utilizador foi substituída.

## 2. Componentes implementados

| Componente | Implementação / âmbito |
| --- | --- |
| PremiumTokens | ThemeExtension semântica, dois temas, funções explícitas; sem ColorScheme.fromSeed para novos pares |
| buildPremiumTheme | Adaptador do ThemeData existente; Inter/Newsreader locais reutilizados; tokens, controlos, campos e estados preparados para adopção progressiva |
| PremiumScope | Adopção explícita no corpo de Hoje/lista de Metas e respectivos FABs. Conserva contexto anterior para abrir os editores existentes |
| PremiumFocusOutline | Anel 2 dp, intervalo 2 dp; observa foco descendente sem acrescentar paragem ao Tab ou alterar geometria |
| PremiumFilter | TextButton existente, estado seleccionado com visto, peso e fundo; MergeSemantics junta nome, papel, selecção e acção |
| PremiumSurface | Plano por defeito; clay opaco só no primeiro destaque da lista de metas; pressão muda contorno, sem deslocar conteúdo |
| Resumo de meta | Título legível, horizonte/categoria, barra e valor numéricos existentes, mesmo acesso ao detalhe |

O tema global MaterialApp e buildTodayTheme permanecem intactos. O shell conserva os quatro destinos/estado/guards. TaskRow só adopta separação/foco quando há PremiumTokens; fora do piloto devolve a apresentação anterior. Os editores continuam no tema anterior, incluindo o formulário de Metas. Campos do DS estão implementados no tema e ensaiados num catálogo widget, mas não foram impostos aos formulários de produção nesta entrega.

## 3. Tokens aplicados

| Papel | Claro | Escuro |
| --- | --- | --- |
| Fundo / superfície | #F7F8F5 / #FFFFFF | #18201D / #202B29 |
| Superfície suave / clay | #E8EDE6 | #28352E |
| Texto / secundário | #202B29 / #5D6965 | #F2F5EF / #BCC6BE |
| Acção / foco | #456C50 | #9ECB8F |
| Outline funcional | #66736D | #8E9D92 |
| Accent / onAccent | #9ECB8F / #202B29 | #9ECB8F / #202B29 |
| primaryBorder | #456C50 | #202B29 |
| Erro / superfície de erro | #9E2A2B / #FCEAEA | #FFB4AB / #442629 |

Tipografia: Newsreader 34/40 em títulos principais; Inter 22/29 em secções, 18/25 nos nomes de metas, corpo 16/24 e metadados 13/19. Texto não é reduzido para caber. Espaços 4/8/12/16/24/32; Hoje usa margem 16 em 320 dp, 20 nas dimensões maiores. Raios 12/14/16/20/24; elevação operacional zero.

Normal, seleccionado, pressionado, foco, erro e desactivado têm funções distintas. Desactivado usa textMuted/surfaceSoft, sem opacidade global. Botão Sage tem primaryBorder; pressionar engrossa o contorno, foco mantém anel independente. Campo com erro e foco conserva mensagem/borda de erro e anel de foco externo quando composto com PremiumFocusOutline.

Clay: centro opaco, raio 20, sombra decorativa discreta (8% claro/16% escuro, deslocamento 0/3, blur 10); um único destaque, restantes filas planas. **Glass não foi acrescentado:** não existe um caso real necessário/seguro neste piloto; Progresso está excluído. Não há novo blur, animação de sombra ou dependência.

## 4. Alterações reais em Hoje e Metas

**Hoje:** mesma ordem Compromissos → Tarefas → pendentes anteriores → Hábitos → concluídas/atalhos. Dia/Semana/Mês usam o filtro com visto; data ganha corpo 16; ritmo entre secções passa a 24; tarefas têm separador discreto/foco; hábitos observam foco; + do cabeçalho tem contorno e anel. Acções, consultas, criação, conclusão, eventos e persistência mantêm as operações existentes. A vista de calendário volta ao tema anterior; não foi redesenhada.

**Metas:** Activas/Alcançadas mantêm o Cubit e critérios; lista individual com destaque clay único, títulos 18 e valores 16, barra 6 dp com mesmo goalProgress e semântica numérica. Os restantes itens são planos. Vazio usa mensagem existente e ícone decorativo excluído da semântica. FAB continua a abrir directamente o Editor de Meta, com todos os campos existentes.

Sem modos binário/etapas novos, inferência por unidade/alvo, alteração de progresso, formulário simplificado, operação de XP ou conversão de registos. Estudos, Finanças e Progresso não foram redesenhados.

## 5. Comparações visuais reais

[Índice completo antes/depois](ux/phase4c3a/CAPTURES.md) e [medições/hashes](ux/phase4c3a/visual-validation.json): **54 pares / 108 PNGs do renderer Flutter**, mesma engine/fontes, dados sintéticos e dimensões em cada par. Nenhum HTML ou mockup usado como captura.

Cobertura dos dois temas: Hoje vazio/preenchido e Metas vazias/preenchidas a 390×844/100%, 320×640/100% e 320×640/200%; foco do + e filtro; hábitos deslocados; hábitos e valores numéricos de Metas acessíveis por scroll a 200%. Inclui oito contextos de regressão e os formulários existentes.

A mudança visual é observável nas capturas normais de Hoje/Metas. Os 16 PNGs integrais dos oito contextos excluídos são idênticos byte a byte. O fundo das folhas mudou por mostrar o piloto, mas o conteúdo dos quatro formulários capturados é idêntico em pixels nas regiões documentadas. Não se declara igualdade de todos os estados possíveis só por estas amostras.

## 6. Resultados de contraste

[42 utilizações calculadas](ux/phase4c3a/contrast-results.json), alinhadas com a matriz 4C.2; testes Dart verificam os getters reais contra os tokens aprovados e usam Color.computeLuminance. Texto normal, incluindo erro/metadados, ≥4,5:1; os pares dos títulos grandes também passam 4,5; outline/foco ≥3:1 nos fundos usados. Texto principal ultrapassa 7:1.

| Par | Claro | Escuro |
| --- | --- | --- |
| Texto / fundo | 13,690:1 | 15,107:1 |
| Secundário / surfaceSoft | 4,814:1 | 7,297:1 |
| onAccent / accent | 7,917:1 | 7,917:1 |
| primaryBorder / accent | 3,242:1 | 7,917:1 |

Sem branco/Sage nem Mineral funcional. Barras e caixas de conclusão usam action contra fundos verificados, não transparência calculada por seed. Sombras são decorativas e não são usadas como fronteira. O cálculo de papéis e os testes não certificam todos os pixels anti-aliased, o SO ou conformidade integral WCAG.

## 7. Foco, toque, semântica e movimento

Testes de componente em 320×640, claro/escuro e texto 100/200% medem botões/campos/checkbox ≥48×48; FAB real de Hoje medido 56×56; filtros e linhas também medidos no piloto real. Altura cresce com o texto. Anel exterior 2 dp + 2 de intervalo, sem deslocamento de layout; foco e selecção não se confundem. Os casos `*-focus` registam foco real do Flutter, não contornos pintados sobre imagens.

Ensaiados: activação por Enter, Tab, mudança de foco, erro simultâneo com foco, botão desactivado, foco visível, nomes/selecção de filtros no mesmo nó, valor semântico do progresso e título longo. Os testes de regressão existentes continuam a verificar os percursos de tarefa/entrada/retorno.

MediaQuery.disableAnimations desliga as novas transições dos botões e a expansão dentro do tema piloto; superfícies e anel são estáticos. Não se acrescentou animação decorativa. A navegação/editores excluídos preservam a implementação anterior; não se afirma uma auditoria integral do movimento de toda a aplicação.

## 8. Testes e CI

Baseline: 254/254. Oito novos testes: dois de tokens/contraste/estados e quatro combinações widget (tema × texto) em premium_design_system_test; dois de regressão no piloto (tema × 320 dp/200%), leitura de métricas com initial diferente de zero, filtros, FAB directo, contexto legado e snapshot de dados inalterado.

Resultados finais locais e GitHub Actions: consolidados após execução, abaixo. Não contar os renders de tool/capture_pilot como testes da suite.

| Verificação local | Resultado |
| --- | --- |
| dart format (lib/test/utilitário) | Sem diferenças após formatação |
| flutter analyze --no-pub | Sem problemas, 28,3 s |
| flutter test --no-pub --machine | **262 executados, 262 aprovados, 0 falhas, 0 ignorados, 0 erros**, runner e processador código 0; 254,5 s |
| Novos testes de DS/piloto | 8 aprovados, incluídos nos 262 |
| Captura antes / depois | 54 + 54 renders aprovados, fora da suite |
| Preservação de ficheiros protegidos | Diff sem alterações |
| Processador de resultados Python | 9 testes aprovados |
| check_schema.py | Aprovado, apenas dados sintéticos |

Código de implementação publicado em **3f8d81e8bed60bb0915c0751937d9d6d588a2039**. Resultados observados directamente pela API GitHub:

| Workflow | Execução no SHA de implementação | Resultado |
| --- | --- | --- |
| Flutter validation | [43309769002](https://github.com/MxxSultane/tudoaki/actions/runs/43309769002) | COMPLETED / SUCCESS |
| Android debug validation | [43309769164](https://github.com/MxxSultane/tudoaki/actions/runs/43309769164) | COMPLETED / SUCCESS |

A contagem 262 vem do JSON machine local, não é inferida da cor do workflow. O commit documental de entrega apenas consolida resultados/evidência; o código Flutter, os testes e os workflows mantêm-se exactamente iguais aos deste SHA validado.

Os workflows existentes só receberam o nome do novo branch no trigger push. Nenhum comando/critério de validação, versão, lockfile ou regra de publicação de APK foi enfraquecido. Sem distribuição de APK nesta fase.

## 9. Build Android

`flutter build apk --debug --no-pub` aprovado localmente, 22,9 s. APK não vazio; aapt confirmou **mz.lifeos.lifeos**, versionName **0.9.2**, versionCode **12**. JAVA_HOME/limites Gradle locais já preparados na 4B, sem alteração de android/. Não é build release nem prova de instalação, assinatura/actualização ou notificações.

APK SHA-256 local: `18175c883efab24aae9d684002c8d60f14a79c4e24889015a37d737c79565f7e`. Artefacto local não distribuído.

## 10. Ficheiros modificados

- lib/core/theme/premium_tokens.dart e premium_theme.dart: novos tokens/adaptador/âmbito.
- lib/core/widgets/premium_components.dart: foco, filtro e superfície.
- lib/features/agenda/presentation/today_screen.dart: adopção visual de Hoje.
- lib/features/goals/presentation/goals_screen.dart: lista de Metas, mesmos dados/acções.
- lib/features/tasks/presentation/task_row.dart: apresentação condicional ao piloto; editor conserva contexto anterior.
- lib/app/app.dart: apresentação dos FABs envolvidos e contexto de criação; rotas/guards/destinos preservados.
- test/premium_design_system_test.dart e phase4c3a_pilot_test.dart: oito testes novos.
- tool/capture_pilot.dart: captura diagnóstica com fixtures/relógio fixos e saída separada.
- .github/workflows/flutter-validation.yml e android-debug-validation.yml: apenas inscrição do branch.
- docs/PHASE4C3A_REPORT.md, docs/ux/phase4c3a e docs/ux/previews/phase4c3a: evidência desta entrega.

Sem alteração de android/, pubspec.yaml/lockfile, schema/database, lifeos.sqlite, TaskOperations, modelos/Cubits/operações de metas, regras de hábitos, XP, cálculos financeiros, notificações ou navegação principal. Nenhuma operação sobre dados reais. A preservação é verificada por diff da base e por suite, não apenas declarada; [verificação documental e de preservação](ux/phase4c3a/document-validation.json).

## 11. Regressões encontradas e corrigidas

1. O primeiro teste de semântica do filtro encontrou selecção no nó pai e acção/nome no botão: juntou-se com MergeSemantics. O teste agora exige nome, papel, seleccionado e acção num nó; passou nos dois temas.
2. A herança de um tema de piloto poderia atingir os editores abertos a partir dos controlos. PremiumScope retém o contexto anterior; FAB de Meta e TaskRow usam-no, sem tocar forms.dart/TaskOperations. Teste de âmbito e comparação de pixels confirmam a separação.
3. O utilitário inicial tentou focar o contexto exterior de FAB/TextButton, que não era o nó focável interno; a captura falhou e foi corrigida para focar o descendente. Uma tentativa usou FocusState, que não é público; substituída por Focus.of no descendente. São falhas da ferramenta de captura, não bugs de produção.
4. O primeiro teste novo construiu fontes antes de inicializar a binding; corrigida a preparação. A verificação do anel passou a aguardar o frame de propagação de foco com pumpAndSettle, em vez de ler antes da reconstrução. Nenhuma falha intermédia foi contada como aprovação.

Sem regressão funcional observada na suite final. As amostras de regressão visual fora do piloto mantiveram igualdade integral; isso não substitui revisão manual de todos os percursos.

## 12. Limitações

Sem telefone físico, TalkBack real, teclado físico/IME Android, luz solar ou medição de desempenho em equipamento modesto. Os PNGs vêm do engine Flutter em testes; não de emulador/screenshot Android. Há scroll real: texto a 200% não obriga todo o ecrã a caber no primeiro viewport e palavras muito longas podem quebrar; verificar conforto de leitura em dispositivo.

Sem glass, transparência ou redesign de módulos fora do piloto. Tokens/campos preparados não significam adopção visual global concluída. Não houve pesquisa com participantes nesta fase nem se declara conformidade integral WCAG. O APK não foi distribuído/instalado; dados reais, assinatura e continuidade de actualização não foram exercitados.

## 13. Recomendação para 4C.3B

Rever os pares de capturas e validar Hoje/Metas num dispositivo de testes: TalkBack, teclado/gestos, escala máxima, luz e descoberta dos controlos. Se o piloto for aprovado, avançar em incremento próprio para os próximos componentes/áreas autorizados, reutilizando os tokens semânticos e mantendo comparação/regressão por módulo. Não estender o tema automaticamente a todos os formulários ou ao shell.

Manter modos novos de Metas e qualquer contrato de dados num gate separado; a aprovação deste piloto não autoriza migração, novos modos ou mudanças de XP. Estudos/Finanças/Progresso continuam a exigir autorização de âmbito por incremento. **Sem merge automático; 4C.3B aguarda aprovação explícita.**
