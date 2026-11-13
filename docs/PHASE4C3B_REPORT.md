# Fase 4C.3B — Metas e formulário progressivo

**Alterações reais no Flutter. Sem migração, merge ou início da fase seguinte.** A criação continua numérica e explícita; os novos modos ficam bloqueados até decisão técnica própria.

## 1. Branch, HEAD e preparação

Base final 4C.3A confirmada local/remoto, árvore inicialmente limpa: **3b86f880e7a3ee5163bb1392d3001a76eff34c17**, branch feat/fase-4c3a-design-system-piloto. Criado directamente o branch **feat/fase-4c3b-metas-formulario**. A base inclui as correcções 4B e o piloto 4C.3A; não se voltou a uma base antiga.

Consultados AGENTS, V2_CONTRACTS, Design System 2.0, relatórios 4C.1 (README do respectivo pacote), 4C.2 e 4C.3A, GOALS, COMPATIBILITY, contraste/acessibilidade, protótipos e testes. Baseline efectivamente executada antes de alterar produção: **262/262 aprovados, sem falhas/ignorados/erros**, Flutter 3.35.7/Dart 3.9.2/Java 21. As capturas anteriores foram produzidas sobre essa base. Houve retoma do ambiente sem substituir alterações existentes.

## 2. Alterações visuais efectivas

Lista de Metas mantém filtros Activas/Alcançadas, selecção com visto/semântica, FAB directo, hierarquia e métricas reais do piloto. Acrescenta prazo absoluto ou Sem prazo e melhora os vazios com explicação contextual. Não acrescenta cartões dentro de cartões nem sombras em toda a lista.

O detalhe passa a adoptar PremiumScope, incluindo barra superior, botões, campos, foco e barras de progresso de 6 dp. Conserva Adicionar acção, Registar progresso, Editar meta, Criar submeta, Plano e Histórico. O plano auxiliar usa Sem etapas/Sem acções quando vazio, sem mudar a contagem ou criar um modo por etapas. Valores e data ganham leitura de corpo; o histórico continua baseado em GoalProgress real.

## 3. Formulário antes/depois

| Antes | Agora |
| --- | --- |
| Título, horizonte, unidade «unidades» e alvo 1 pré-preenchidos | Título/nome, prazo opcional em dias e acesso explícito a Medir com números; unidade e alvo vazios até escolha da pessoa |
| Prazo escondido nas opções | Prazo no primeiro nível, pré-visualização absoluta e remoção explícita |
| Guardar para qualquer contexto | Criar na criação de meta; Guardar na edição |
| Estilo antigo no editor de metas | Tema premium, título Inter 22, campos com foco independente, mensagem de erro e corpo rolável |
| Mais opções | Editor completo, com horizonte, descrição, área, associação à meta principal, valor inicial e selector absoluto de prazo |

[Comparações reais antes/depois](ux/phase4c3b/CAPTURES.md), incluindo imagens embebidas e matriz completa. A divulgação progressiva conserva os valores dos controladores quando recolhida. Abrir o editor completo não limpa o que foi escrito.

## 4. Simplificações implementadas

Na criação compacta, horizonte e metadados passam para o editor completo. A pessoa vê o nome, prazo opcional, instrução curta sobre medida, Medir com números, Editor completo e Criar. Ao escolher a medida, unidade e alvo aparecem sem valores fictícios; o inicial 0 é mostrado e pode ser alterado no editor completo. Não se exige descrição, categoria própria, associação ou prazo.

**Não é criação apenas com nome.** Submeter sem medida revela os campos necessários e explica o que falta; não grava uma meta com target=1/unit=unidades escondidos. Os campos obrigatórios são validados antes da gravação. O editor completo também exige medida explícita em novas metas.

## 5. Funcionalidades e dados preservados

Mesmo FAB, critérios de filtro, IDs, relações, criação/edição/submetas, horizonte herdado, métricas, plano auxiliar, tarefas e histórico. GoalPlan continua independente de Goals.current; updateMetric e o repositório não foram alterados. Registar 12 e depois 4 no detalhe conclui/reabre conforme a regra numérica existente, com dois registos de histórico e zero XP novo.

A edição sem alterar métricas/prazo preserva initial/current/target/unit/status/created/due, descrição/área e relações. Strings antigas não são aparadas se não foram modificadas. Um status antigo divergente não é recalculado ao editar apenas o nome; alterar alvo mantém a derivação existente. Horizonte antigo personalizado permanece seleccionável. O teste de ficheiro sintético confirma reabertura com precisão/fuso originais e histórico intacto.

## 6. Decisões sobre prazo em dias

Implementado sem migração: vazio = NULL; inteiro positivo; 1 = amanhã. Usa aritmética de calendário UTC apenas para compor a data civil a partir do dia local do input, sem N×24h ou conversão de fuso. Grava **YYYY-MM-DD absoluto** em Goals.due.

A data é calculada quando o número é alterado e a pré-visualização é mantida ao guardar, mesmo se o relógio atravessar a meia-noite. Reabrir mostra o prazo absoluto e não reinicia uma contagem. Alterar prazo é explícito; Retirar prazo grava NULL. O selector absoluto do editor completo continua acessível e partilha o mesmo rascunho; remover/alterar num ponto actualiza a apresentação no outro.

Mantido o limite do selector já existente: **01/01/2100**, sem impor o limite proposto de 3650 dias. Zero, negativos, decimais, texto e números fora do intervalo geram mensagem. Datas antigas não tocadas mantêm a **string exacta**, incluindo hora/fuso/fracções. A formatação do legado conserva a semântica DateTime.parse/DateFormat anterior; não converte o armazenamento ao abrir. Não são criados lembretes.

## 7. Contrato técnico dos três modos

[GOAL_MODES_CONTRACT.md](ux/phase4c3b/GOAL_MODES_CONTRACT.md): modelo proposto, operações, histórico, conclusão/reabertura, compatibilidade, alternativas de migração, testes de integridade e riscos.

NULL num eventual discriminador significaria legado numérico. Nenhum modo é inferido por alvo, unidade ou etapas antigas. Binary/steps não são apresentados como activos. O contrato recomenda métricas ausentes para esses modos e explica que apenas acrescentar uma coluna não elimina o NOT NULL/CHECK numérico: a decisão de relaxar restrições/reconstruir tabela, ou aceitar um envelope numérico explícito, exige aprovação separada. Nenhuma alternativa foi implementada.

## 8. Limitações de armazenamento

| Campo | Razão técnica / escolha de interface |
| --- | --- |
| title/created | NOT NULL; conteúdo não vazio é validação adicional da interface; created fornecido pela operação |
| target | NOT NULL, sem default, CHECK(target > initial); não permite omitir uma métrica |
| initial/current | NOT NULL com default 0; criação mostra inicial e usa-o como resultado inicial, sem histórico fabricado |
| unit | NOT NULL com default SQLite «unidades»; interface agora exige unidade explícita e não usa esse default para fingir uma escolha |
| horizon/category/description/status | Defaults existentes; não são exigências de entrada obrigatória pela pessoa |
| due/parent_id | Opcionais; sem prazo/associação é válido |

O repositório save faz INSERT/UPDATE dos campos recebidos, sem inventar target. SQLite v5, tabelas, FKs, triggers e modelos continuam intactos. Nenhuma migração foi escrita ou executada em dados reais.

## 9. Testes, contraste e acessibilidade

Dez testes novos cobrem dias civis/limites, quatro combinações claro/escuro × texto 100/200% em 320×640, teclado simulado, foco e alvos, criação explícita, meia-noite, edição/remoção de prazo, legado/reabertura e progresso no detalhe. Os testes antigos de criação foram adaptados para introduzir uma métrica real e usar Criar; mantêm verificações de relações, conclusão e reabertura. Não se conservaram defaults fictícios apenas para manter testes verdes.

PremiumTokens/PremiumScope/componentes 4C.3A são reutilizados. Texto usa pares ≥4,5:1; outline/foco/action e cursor/handles usam os papéis funcionais ≥3:1. Os seis testes de DS existentes verificam os getters/papéis com Color.computeLuminance e texto 200%; a matriz 4C.3A/4C.2 continua a referência, sem cores funcionais novas. Campos/botões/checkbox têm mínimo 48 dp; os testes reais medem nome, prazo, alvo e Criar. Foco de campo tem anel exterior de 2 dp/intervalo 2, independente do erro. Validação foca o primeiro campo inválido e aproxima-o da área útil.

| Verificação final local | Resultado |
| --- | --- |
| dart format, lib/test/utilitário | Sem diferenças após formatação |
| flutter analyze --no-pub | Sem problemas (18,4 s) |
| Suite Flutter completa, código final congelado | **272 executados, 272 aprovados, 0 falhas, 0 ignorados, 0 erros**, runner/processador código 0; 182,5 s |
| Novos testes | 10 aprovados, incluídos nos 272 |
| Capturas | 56 antes + 56 depois; fora da contagem da suite |
| Processador de resultados Python | 9 testes aprovados |
| check_schema.py | Aprovado, apenas fixtures sintéticas |
| flutter build apk --debug --no-pub | Aprovado, 18,9 s; mz.lifeos.lifeos / 0.9.2+12 preservados |

APK SHA-256 local: `a39c279baee74ab1f9cc4d1f2100faac4c306b5a038b1493e482946e4d2ee920`. Sem distribuição/instalação. [Resultados](ux/phase4c3b/test-results.json) · [Preservação/documentos](ux/phase4c3b/document-validation.json) · [Contrastes de referência verificados pelos testes](ux/phase4c3a/contrast-results.json).

## 10. GitHub Actions

Os dois workflows existentes incluem agora o branch 4C.3B no trigger push, sem enfraquecer comandos, versões, preservação ou critérios. Sem upload/distribuição de APK.

Código final da correcção de integridade: **b8b1800d8e069432153e47d780affe3b68ef9197**, validado no commit documental **fa241a8f4575e90fdc10f1d36aecfffcc386a6fc**, cujo código/testes/workflows são idênticos. Resultados observados directamente pela API GitHub:

| Workflow | Execução | Resultado |
| --- | --- | --- |
| Flutter validation | [43474379059](https://github.com/MxxSultane/tudoaki/actions/runs/43474379059) | COMPLETED / SUCCESS |
| Android debug validation | [43474379043](https://github.com/MxxSultane/tudoaki/actions/runs/43474379043) | COMPLETED / SUCCESS |

A validação inclui os rótulos a 200% e a protecção de métricas recolhidas. A contagem 272 vem do runner local machine, não é inferida da cor da CI. O push de b8b1800 recebeu erro transitório do GitHub após actualizar a referência; confirmou-se o SHA remoto e o commit documental seguinte disparou as validações acima. Não se considerou o push equivalente a CI aprovada. O commit documental de entrega mantém o código validado intacto.

## 11. Capturas reais Flutter

**56 pares / 112 PNGs**: Metas vazias/preenchidas, Criar, Editar, detalhe numérico, medida revelada, editor completo, foco e erro nos dois temas, a 390×844/100%, 320×640/100% e 320×640/200%; mais teclado simulado a 200%. Mesmos dados/dimensões por par, engine/fontes locais e relógio fixo. [Índice](ux/phase4c3b/CAPTURES.md) · [Hashes/dimensões](ux/phase4c3b/visual-validation.json).

Não são HTML nem screenshots de telefone físico. A zona de teclado usa viewInsets de 280 dp, não uma IME real. Campos e acções continuam acessíveis por deslocação; a 200% não cabem todos simultaneamente no primeiro viewport. Não foram sobrescritas imagens de fases anteriores.

## 12. Ficheiros modificados

- lib/features/forms.dart: adaptação condicionada a Meta, medida explícita, divulgação, prazo e preservação de dados.
- lib/features/goals/goal_deadline.dart: adaptador de prazo civil e formatação compatível.
- lib/features/goals/presentation/goals_screen.dart e goal_detail.dart: apresentação de lista/detalhe.
- lib/features/goals/goal_plan.dart: rótulos vazios auxiliares, sem mudar operações.
- lib/core/theme/premium_theme.dart: barra superior e cursor/handles semânticos, dentro do tema aprovado.
- lib/app/app.dart: âmbito premium do detalhe; caminhos/destinos/guards intactos.
- test/phase4c3b_goals_test.dart: dez testes novos; app_test, goal_planning_widget, phase4b e phase4c3a_pilot: adaptação às escolhas/âmbito agora autorizados.
- tool/capture_goals.dart: utilitário diagnóstico de capturas sintéticas.
- .github/workflows/flutter-validation.yml e android-debug-validation.yml: apenas inscrição do branch.
- Este relatório, docs/ux/phase4c3b e docs/ux/previews/phase4c3b: contrato/evidência.

Sem alterações de Android/applicationId, dependências/lockfile, database/schema, lifeos.sqlite, TaskOperations, XP, finanças, hábitos, notificações ou navegação principal. Nenhuma operação sobre dados reais.

## 13. Riscos e regressões

As primeiras capturas falharam por usar /goals/id em vez da rota real /goal/id; o utilitário foi corrigido e os casos repetidos. A preparação inicial do utilitário também produziu avisos de código morto/bloco sem chavetas, corrigidos antes da análise final.

Testes antigos pressupunham defaults métricos e que a associação à meta principal estivesse sempre no primeiro viewport; foram actualizados para escolher a medida e deslocar até à associação, mantendo a verificação. Um finder de TextButton não encontrava a variante .icon; o controlo passou a botão textual mais simples. A verificação do tema do formulário mede agora o campo descendente real, pois PremiumScope é aplicado dentro do Editor. Falhas intermédias não foram contadas como aprovação.

A edição antiga reserializava due e recalculava status mesmo ao renomear; o caminho de Meta agora preserva valores não tocados. O selector de data completo e o prazo em dias foram sincronizados para não mostrarem rascunhos contraditórios. A revisão de imagem corrigiu a barra superior e os vazios do plano auxiliar. A inspecção a 200% detectou abreviação do rótulo do prazo pelo labelText nativo; os campos de Meta usam agora rótulos Text com quebra de linha. O teste verifica o RenderParagraph real sem excesso de linhas nem overflow por ellipsis, e as capturas foram repetidas.

Uma execução intermédia apanhou um teste actualizado com código anterior compilado enquanto havia alterações em curso. Não foi aceite como resultado final: os testes dirigidos passaram e a suite foi repetida com código congelado. A amostragem visual de nove imagens de oito contextos fora de Metas ficou idêntica byte a byte à base ([registo](ux/phase4c3b/other-modules-validation.json)); isso não certifica todos os estados.

Um teste adicional reproduziu gravação de initial/current=-Infinity após recolher o editor completo: o validator do campo deixava de participar e o CHECK SQLite aceitava o valor. A operação de Meta agora verifica parsing e finitude de inicial/alvo antes de qualquer gravação, com erro em português. O teste falhou antes da correcção e passou depois, sem gravação; a protecção não depende de o campo estar montado.

Sem conformidade WCAG integral declarada. TalkBack real, IME/teclado físico, dispositivo Android, luz/desempenho e instalação/actualização/assinatura não foram certificados. A criação exige uma escolha numérica adicional enquanto o modelo v5 o exigir; essa limitação é explícita e não foi escondida sob percentagens.

## 14. Próxima etapa

Rever os pares reais e testar em dispositivo com TalkBack/IME, principalmente editor completo e teclado a 200%. Decidir separadamente o contrato de modos e de eventual migração; só depois projectar criação apenas com nome. Não activar modos por etapas/binário através de convenções em campos antigos. Uma futura autorização deve delimitar os módulos e operações seguintes.

**Sem merge automático, sem alteração de esquema e sem início da fase seguinte sem aprovação.**
