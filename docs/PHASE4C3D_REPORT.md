# Fase 4C.3D — Finanças premium no Flutter

Interface real reorganizada: mês/moeda, resumo compacto, Registar movimento, movimentos recentes e acesso explícito aos planos financeiros. Operações e cálculos preservados. Sem merge ou início de Progresso.

## 1. Branch e HEAD

Base final 4C.3C confirmada local/remoto: **49e1724319988ef66890f5742de8eea84692c112**, branch feat/fase-4c3c-estudos-premium, árvore inicialmente limpa. Criado directamente **feat/fase-4c3d-financas-premium**. O commit de implementação e os workflows são identificados na secção 13; o histórico do branch identifica o HEAD documental final.

Lidos AGENTS.md, V2_CONTRACTS.md, DESIGN_SYSTEM.md histórico e Design System 2.0, relatórios 4C.1/4C.2/4C.3A/4C.3B/4C.3C, auditoria 4C.1/4B, protótipos/revisão 4C.2, compatibilidade, componentes premium, código e testes financeiros. A restrição histórica de Fase 1 em AGENTS não substitui a autorização explícita desta implementação.

Baseline completa executada antes de alterar produção: **292/292 aprovados**, zero falhas/ignorados/erros. Flutter 3.35.7, Dart 3.9.2, Java 21. As capturas anteriores foram tentadas sobre essa base, antes das alterações de produção.

## 2. Auditoria do módulo anterior

[Auditoria e mapa de acessos/regras](ux/phase4c3d/AUDIT.md). Entrada real /finance → AreaScaffold → TudoAkiScreen → FinancePanel; dataProvider, finance_rules, finance_repository, Editor de forms.dart e FinancePlanEditor.

Existem receitas, despesas, contribuições, categorias por texto normalizado, quatro moedas, orçamentos por mês/categoria/moeda, metas de poupança e recorrências com confirmação/histórico. **Não existem contas bancárias, saldo bancário, câmbio ou campo separado de descrição de movimento.** O título é o texto descritivo existente; não se acrescentou uma entidade/campo para reproduzir o protótipo. SavingsGoals continua independente de Goals.

Antes, orçamentos, recorrências e poupanças precediam todos os movimentos. O aviso longo, o resumo e duas acções competiam no topo. Valores em trailing e cabeçalhos com acção lateral expunham problemas com texto ampliado. A matriz de esforço adicional confirmou esses problemas, apesar da baseline de testes passar.

## 3. Alterações visuais efectivas

Novo FinanceScreen aplica o PremiumScope existente ao conteúdo, incluindo barra superior na mesma rota. A página conserva o identificador Finanças e usa uma coluna rolável, margens 16/20 dp e os estilos Inter/Newsreader existentes, sem repetir um título de 34 dp.

Resumo numa superfície plana opaca; restantes listas abertas. Sem clay atrás dos números, cartões aninhados, glass, blur, gráficos decorativos ou sombras novas. O selector fechado mostra o código ISO integral; o menu conserva os nomes completos. Aviso curto **Sem conversão cambial** permanece visível antes do resumo.

Movimentos passam a título, data/categoria, tipo por texto, sinal e montante numa linha própria. FinanceAmount reutiliza exclusivamente formatMoney/Theme e o contorno premium; não é um motor monetário ou segundo Design System. Em valores que excedem a largura, disponibiliza scroll horizontal, barra visível, foco/setas e semântica com o valor completo e nome/código da moeda. Não reduz fontes nem usa ellipsis nos montantes.

Os editores existentes recebem foco/tema, rótulos legíveis, teclado decimal como sugestão de entrada e Cancelar explícito, sem introduzir gravação ou confirmação de rascunho novas. Tipo, data, categoria, associação à poupança, moeda e todos os campos/validações existentes continuam disponíveis. Não se esconderam campos financeiros importantes em opções avançadas.

## 4. Hierarquia antes/depois

| Antes | Depois |
| --- | --- |
| Moeda, explicação longa, mês | Mês e moeda; aviso cambial curto |
| Quatro linhas de resumo abertas | Saldo dos movimentos e Ver composição rotulado com as três parcelas |
| Registar movimento e Criar poupança lado a lado | Registar movimento como acção principal |
| Orçamentos → recorrências → poupanças → movimentos | Movimentos do mês → Orçamentos/Poupanças/Recorrências, cada um com contagem e acesso de criação |
| Todos os movimentos no fim | Três recentes; Ver todos os movimentos revela os restantes no mesmo sítio |
| Montante comprimido no trailing | Montante separado, exacto e com acesso integral |

Ver composição mostra receitas, despesas e contribuições para poupança, com a fórmula explícita. Não se reclassificou contribuição como despesa nem se chamou lucro ou saldo de conta ao resultado. A composição não perde dados ao recolher.

Os três recentes mantêm a mesma ordenação por dia descendente; Ver todos não cria uma cópia de registos. Meses anteriores continuam acessíveis pelos controlos de período. As funcionalidades secundárias têm nome/contagem e acesso com uma expansão; uma regra mantém o seu próprio detalhe em expansão, tal como antes. O ecrã precisa de scroll em janelas pequenas/texto ampliado: não se promete mostrar todos os blocos simultaneamente no primeiro viewport.

## 5. Funcionalidades preservadas

Mesmo Editor Transacção/Poupança e FinancePlanEditor, mesmos repositórios, save/remove/initState e validações. Criação/edição/eliminação, cancelamento, relações, campos adicionais de origem recorrente, datas, precisão, IDs e histórico mantidos. [Verificação de preservação com hashes](ux/phase4c3d/preservation.json).

O bloco de filtros de mês/moeda, totais e consulta de orçamentos em FinancePanel é idêntico à base. Também permanecem intactos finance_rules, finance_repository, finance_providers, SQLite v5/lifeos.sqlite, TaskOperations, XP, Metas, Estudos, Hábitos, notificações, navegação principal, Android ID, dependências e lockfile. Não se alteraram os componentes/temas globais; os estilos adicionais são locais a Finanças ou condicionados aos dois tipos financeiros do editor partilhado.

## 6. Verificação da precisão financeira

Cêntimos inteiros por registo; parsing/validação em BigInt antes de converter para int; somas e formatação em BigInt. Intervalo de entrada existente: **1 a 9007199254740991 cêntimos**. Zero, negativos, letras, NaN, mais de duas casas decimais e excesso de intervalo continuam rejeitados sem escrita. Não se introduziu arredondamento ou conversão em double.

moneyProgress conserva o double que já usava exclusivamente na fracção gráfica limitada 0–1. Totais, valores de comparação, restante e rótulos continuam exactos. Não se usa essa fracção para guardar/recalcular dinheiro.

Oráculos das mesmas fixtures e regras da base, conferidos pelos testes e pelo bloco de cálculo inalterado:

| Contexto | Receitas (cêntimos) | Despesas | Contribuições | Saldo dos movimentos |
| --- | --- | --- | --- | --- |
| MZN — Novembro | 2500050 | 125050 | 100025 | 2274975 = 22.749,75 MT |
| USD — Novembro | 155050 | 55555 | 0 | 99495 = 994,95 USD |
| EUR — Novembro | 0 | 11001 | 0 | -11001 = -110,01 EUR |
| ZAR — Novembro | 0 | 12001 | 0 | -12001 = -120,01 ZAR |
| MZN — Outubro | 0 | 149999 | 5000 | -154999 = -1.549,99 MT |

No esforço de valor elevado, três entradas de 9007199254740991 cêntimos mais o resultado normal produzem exactamente **270.215.977.664.979,48 MT**, sem passar o total por double. O teste de edição grava o máximo permitido em cada uma das quatro moedas mantendo os restantes campos/ID. A reabertura de ficheiro SQLite sintético verifica dados, FKs e esquema v5.

## 7. Verificação das moedas

MZN/USD/EUR/ZAR conservados por registo. Mudar o selector só altera consulta e contexto de novas criações; não escreve a preferência nem relabela movimentos antigos. O editor mantém a moeda da origem, incluindo contribuições associadas a uma poupança. O aviso cambial não foi escondido numa expansão.

Testes antigos de moeda continuam a verificar preferência futura, imutabilidade e associação compatível; testes novos criam/editam nas quatro moedas e comparam totais isolados. Não se somam moedas nem se apresenta um total convertido. O selector fechado usa ISO para evitar perder o código a 200%; o menu mostra Metical/Dólar americano/Euro/Rand e respectivos códigos. Valores têm semântica com nome e código, não apenas a abreviatura MT.

## 8. Orçamentos, poupanças e recorrências

Orçamentos mantêm categoria normalizada/mês/moeda, unicidade e apenas despesas elegíveis. Fixture: limite 200000, despesas 125050, restante **74950 cêntimos**. Eliminar limite não elimina movimentos. Cada valor tem rótulo próprio; barra/percentagem conservam a fórmula existente.

Poupanças mantêm alvo e contribuições em **todos os meses**, da mesma moeda e associação. Fixture: 100025 + 5000 = **105025 cêntimos**, inalterado ao consultar outro mês. Criar, editar, contribuir e eliminar continuam disponíveis; eliminar preserva contribuições sem ligação. O teste antigo de histórico órfão permanece aprovado.

Recorrências continuam a exigir Rever vencimentos → confirmação explícita. Abrir, expandir, cancelar e navegar não emitem movimentos. Mantidos lotes até 24, revisão da regra, idempotência, pausa, bloqueio de início/frequência após ocorrências e histórico (até 12 vencimentos recentes por regra, como antes, incluindo movimento eliminado). Na fixture, Outubro já registado é preservado e Novembro só entra após confirmação; repetir a revisão não duplica.

A confirmação recebeu uma largura de conteúdo delimitada e montantes em linhas próprias, para suportar o novo componente sem erro de dimensões intrínsecas. Na revisão manual a 320 dp/200%, o total ainda ficava abaixo da área visível: o título passou a Rever registo e o total passou para o início do conteúdo. Um teste verifica que o montante total é atingível/visível antes de confirmar, além das verificações de cancelamento/idempotência. Chamadas previewRecurring/recordRecurring e guardas de confirmação permanecem as existentes.

## 9. Capturas reais Flutter

[Comparações e índice completo](ux/phase4c3d/CAPTURES.md) · [Manifesto](ux/phase4c3d/visual-validation.json). **336 PNG reais**: 160 antes, 164 depois, 12 detalhes posteriores dos valores longos. Há **160 pares** com os mesmos dados/relógio/dimensões, incluindo 20 pares externos byte a byte iguais.

Cobertura financeira: vazio, preenchido/resumo, outra moeda, mês vazio, valores longos, registar, editar, erro, orçamento, poupança, recorrência/histórico e confirmação. Cada cenário tem claro/escuro, 320/360/390 dp e 100/200%. Registo/erro ampliados incluem insets de teclado simulados de 280 dp. As 12 vistas extra tornam visível a leitura/foco dos valores longos.

**Limite anterior documentado:** a matriz adicional de 164 casos teve 26 falhas sobre a base (22 com PNG e quatro sem frame válido). A suite baseline de 292 não falhou. Os quatro casos de valor elevado/200% não puderam ser capturados devido à falha de layout de ListTile; não se fabricaram imagens nem se contam esses casos como pares aprovados. [Diagnósticos e casos exactos](ux/phase4c3d/BASELINE_RENDER_ERRORS.md). A matriz posterior passou integralmente.

Renderer Flutter de testes, fontes locais, SQLite sintético, DPR lógico 1 e PNG a 2×. Sem HTML, maquetas ou montagens. Contextos externos: Hoje, Planear, Metas, Tarefas, Progresso, Hábitos, Agenda, Estudos, editor de tarefa e criação de meta. A identidade de hashes vale para as fixtures capturadas, não para todos os estados possíveis.

## 10. Contraste, foco e alvos tácteis

Mesmos tokens aprovados, conferidos com Color.computeLuminance na suite premium. Nas superfícies background/surface/soft: texto secundário mínimo **4,814:1 claro / 7,297:1 escuro**; principal mínimo 12,292/11,644; action/foco mínimo 5,034/6,951; outline mínimo 4,173/4,508. Graphite/Sage 7,917:1; contorno interior do botão 3,242:1 claro / 7,917:1 escuro. [Matriz de referência](ux/phase4c2/CONTRAST.md).

Expansões usam action aberto/fechado no tema local; barra de deslocação dos valores usa outline. Valores críticos usam texto principal, sem opacidade, vermelho/verde como único indicador ou Sage como texto no branco. Tipos e sinais permanecem explícitos.

Botões/campos reutilizam mínimos 48×48/56 dp e estados de foco/pressão/erro/desactivação. Testes medem selector, mês, registo e acções secundárias nas 12 combinações de tema/largura/escala. Exercitam foco/Tab, contorno 2 dp, semântica do valor/moeda, setas para valor longo e layout dos campos de contribuição/associação. A animação de expansão fica a zero com movimento reduzido.

Scroll/SafeArea dos contentores preservados; criação/edição e erros exercitados a 200% com espaço de teclado simulado. Não se declara conformidade integral WCAG: ordem falada, IME real, interacção física e leitura em Android ainda precisam de ensaio em dispositivo.

## 11. Testes e resultados

Baseline **292**. Acrescentados **26 testes**: matriz 12; criação/edição exacta/cancelamento por moeda 4; entrada inválida/zero; filtros de mês/moeda e poupança acumulada; recorrências/revisão/confirmar/repetir/bloqueio; valores longos/semântica/teclado; erro/retentativa; carregamento; navegação/formulários/consulta da lista completa sem escrita; rótulos e associação longa; editores de orçamento/recorrência a 200%; reabertura sintética com precisão/FKs.

Os cinco testes widget financeiros/moeda existentes foram adaptados à expansão das secções e aos montantes separados, preservando as asserções de valores, IDs, moeda, datas, eliminação, histórico e confirmação. A selecção do movimento no teste de recorrência passou a identificar a linha de movimento antes do detalhe da regra, conforme a nova ordem. Os restantes testes existentes permanecem na suite completa.

Passagem dirigida final: **31/31 aprovados** (26 novos + cinco existentes). Matriz posterior **164/164** e detalhes **12/12** aprovados, executados separadamente da suite. **Suite completa final: 318/318 aprovados, zero falhas/ignorados/erros; dart format: 111 ficheiros, zero alterações (lib/test + utilitário); flutter analyze sem problemas; nove testes Python do processamento de resultados aprovados.** Build local aprovado. CI registada na secção 13 e em [test-results.json](ux/phase4c3d/test-results.json).

As execuções intermédias expuseram as falhas antigas de layout, o conflito de LayoutBuilder com as dimensões intrínsecas do diálogo de confirmação e as expectativas antigas de listas abertas/texto combinado. Foram corrigidos e repetidos os testes relevantes; não se suprimiram excepções na renderização posterior. Houve também uma correcção no código de um novo teste de geometria antes de este compilar; não é apresentada como defeito da aplicação.

## 12. Build Android

`flutter build apk --debug --no-pub` local concluído com êxito, **11,9 s** no assembleDebug final, Flutter 3.35.7/Java 21. APK não adicionado ao Git nem publicado. Android ID/configuração/dependências/lockfile intactos. CI na secção seguinte. Build não certifica actualização/assinatura num telefone com dados reais.

## 13. GitHub Actions

Implementação final publicada em **df7a840677e07ae41c6e2eae67d0513f43af466d**, incluindo a correcção do total visível e do estado das deslocações. Ambos os workflows de push concluídos com **success** neste SHA:

- [Flutter validation — 43499373232](https://github.com/MxxSultane/tudoaki/actions/runs/43499373232): **318 executados/aprovados**, zero falhas/ignorados/erros; format=0, analyze=0, test=0, lock=0; nove testes Python aprovados. Formatação de lib/test: 110 ficheiros, zero alterações; o comando local inclui também o utilitário e conta 111.
- [Android debug validation — 43499373116](https://github.com/MxxSultane/tudoaki/actions/runs/43499373116): compilação debug e preservação do projecto aprovadas; publicação do APK não executada.

O fecho documental subsequente só actualiza este relatório e test-results.json, sem alterar código, testes, capturas ou workflows relativamente ao SHA validado. O HEAD documental volta a accionar os dois workflows, consultáveis no branch. Sem merge automático. Acrescentado apenas este branch às listas de push existentes; não se reduziram verificações nem permissões.

## 14. Ficheiros modificados

Produção: lib/features/finance/finance_screen.dart e finance_amount.dart (novos), finance_panel.dart, finance_editor.dart, lib/features/forms.dart (apresentação condicionada aos tipos financeiros), lib/features/screens.dart (despacho) e lib/app/app.dart (tema da área). Sem alterações às operações save/remove/initState, repositórios ou regras.

Testes/diagnóstico: test/phase4c3d_finance_test.dart, test/support/finance_fixture.dart, test/finance_widget_test.dart, test/currency_widget_test.dart e tool/capture_finance.dart. Documentação/evidência: este relatório, docs/ux/phase4c3d/* e docs/ux/previews/phase4c3d/*. Workflows Flutter/Android: só activação do branch. A lista exacta consta do diff do commit.

## 15. Regressões encontradas e corrigidas

- O esforço adicional de expandir um orçamento de valor elevado reproduziu uma colisão de PageStorage entre estado booleano da expansão e deslocação numérica, causando erro de tipos. Cada expansão recebeu uma PageStorageKey própria e os valores horizontais usam posições efémeras sem guardar scroll nesse armazenamento. O teste verifica que um novo valor começa no início; não se alterou persistência financeira.

- A revisão visual posterior detectou que o total da confirmação ficava fora do primeiro viewport a 320 dp/200%, embora o layout já não lançasse excepção. Um teste de hit testing do montante falhou antes da correcção e passou depois: total no início e título mais curto. Mantidos os mesmos vencimentos, moeda, montantes e confirmação obrigatória. As capturas e a suite completa foram repetidas sobre esta correcção.

- Baseline de esforço: cabeçalhos/valores em trailing causavam overflow a 320 dp/200%, e quatro casos elevados não completavam layout. Linhas abertas com montante separado e acesso horizontal explícito resolvem sem reduzir fonte ou alterar cêntimos.
- Selector fechado cortava o código da moeda ampliado; código ISO passa a ficar integralmente visível, mantendo nomes completos no menu.
- O novo componente monetário com LayoutBuilder revelou conflito de dimensões intrínsecas na confirmação, em quatro casos intermédios. Conteúdo do diálogo agora tem largura delimitada; a confirmação/operação permanece igual e a matriz final passa.
- A chave externa do componente monetário foi posicionada no contentor de semântica para permitir testar directamente o rótulo completo; os valores e controlos preservam a alternativa textual.
- Testes antigos pressupunham montantes combinados, todas as listas abertas e a linha de movimento por último. As expectativas foram adaptadas à nova apresentação sem retirar verificações de integridade.

## 16. Limitações

Não houve execução num telefone, TalkBack, IME real, teclado físico ou ensaio de instalação/actualização com dados reais. O teclado simulado valida insets/scroll, não o comportamento de um IME específico. Não se declara certificação WCAG integral ou desempenho medido em dispositivo.

Valores excepcionalmente longos exigem deslocação horizontal; todos os dígitos permanecem disponíveis e a moeda é indicada também fora da linha deslocável, com semântica integral. Não se promete apresentar um montante arbitrariamente longo numa única largura de 320 dp a 200%.

Quatro frames anteriores não eram renderizáveis: a evidência regista o erro em vez de inventar uma comparação. As capturas externas cobrem os estados indicados. Não se implementaram contas, câmbio, novas operações, descrição financeira separada, migração ou redesign de Progresso.

## 17. Recomendações para 4C.3E

Rever os frames reais e validar leitura monetária, descoberta da composição/planos e correcção de lançamentos num Android com TalkBack, teclado aberto e texto ampliado. Manter os testes de precisão/moeda e o bloco de cálculo como invariantes ao evoluir apresentação.

Progresso deve partir da auditoria aprovada e das fontes reais, respeitando as limitações de XP/histórico; não inferir uma métrica agregada de vida. **4C.3E/Progresso não foram iniciados e dependem de aprovação explícita. Sem merge automático.**
