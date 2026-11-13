# Fase 4C.3C — Estudos premium no Flutter

Alteração efectiva da interface de Estudos, com o Design System existente e operações preservadas. Sem merge, migração ou início de Finanças/Progresso.

## 1. Branch e HEAD

Base final 4C.3B confirmada local/remoto: **058ae625bbec82eb97c7eaf0f4eeca0414672f7f**, árvore inicialmente limpa, branch feat/fase-4c3b-metas-formulario. Criado directamente **feat/fase-4c3c-estudos-premium**. O commit de implementação e os resultados finais de CI são registados na secção 11; o histórico do branch identifica o HEAD documental final.

Consultados AGENTS.md, V2_CONTRACTS, Design System 2.0, relatórios 4B/4C.1/4C.2/4C.3A/4C.3B, auditoria e protótipos de Estudos, compatibilidade, contraste/acessibilidade, componentes e contratos/testes académicos. Baseline executada antes das alterações: **272/272 aprovados**, sem falhas, ignorados ou erros. Flutter 3.35.7, Dart 3.9.2, Java 21. As capturas anteriores foram feitas antes de alterar produção.

## 2. Auditoria do módulo anterior

[Mapa das operações, entidades e acessos preservados](ux/phase4c3c/AUDIT.md). A entrada real era /academics → AreaScaffold → TudoAkiScreen → AcademicsPanel. Os trabalhos são Tasks com subject_id; disciplinas, aulas, avaliações e sessões têm as entidades existentes. Agenda/Planear projectam essas entidades sem duplicação. Não há modelo de notas nem indicadores de produtividade.

O módulo anterior colocava explicações, XP, sessões e avaliações antes das disciplinas. O foco aberto automaticamente ocupava o topo. A expressão «prazos» para tarefas não distinguia o dia de execução. Todos os dados continuam nos mesmos repositórios; não se alteraram regras para obter a nova apresentação.

## 3. Alterações visuais efectivas

AcademicsScreen integra o conteúdo real com PremiumScope. A rota conserva a mesma barra e os mesmos destinos. Superfícies planas predominam; o primeiro destaque útil de disciplina ou a retoma/temporizador usa clay opaco discreto. Sem superfícies premium aninhadas, gradientes, blur ou glass sem caso útil.

Tipografia Inter nos controlos/corpo e Newsreader nos títulos conforme o tema aprovado, respiros consistentes, contornos funcionais e foco visível. Trabalhos reutilizam TaskRow; avaliações e sessões passam a linhas legíveis com acções nomeadas, em vez de vários ícones comprimidos ao lado do título. Editores académicos recebem o mesmo tema/foco, mantendo os campos e operações.

## 4. Hierarquia antes/depois

| Antes | Depois |
| --- | --- |
| Introdução e explicação de XP no topo | Identificação na barra; explicação em Sobre o foco e XP no fim |
| Temporizador completo automático | Retoma compacta prioritária; temporizador ao pedir foco, com deslocação até à acção |
| Sessões/avaliações antes das disciplinas | Próximas actividades → Disciplinas → Sessão de estudo |
| Listas longas abertas | Até duas próximas actividades; restantes em secções com nome e contagem |
| Tarefas apresentadas como prazos | Dia da tarefa; datas de avaliação e de sessões identificadas separadamente |
| Vazios repetidos em cartões | Mensagens curtas e Adicionar disciplina como acção inicial |

A pré-visualização considera hoje até ao dia +7 inclusive, por data civil, ordena por data/hora e mostra no máximo duas entradas. A lista Trabalhos e avaliações mantém todas as datas, sem dia e concluídos. Uma sessão iniciada ou pausada tem Retomar foco no topo; abrir a vista não inicia, reinicia ou recompensa a sessão. A hierarquia é rolável: não se promete que todos os blocos caibam simultaneamente em 320 dp com texto a 200%.

## 5. Funcionalidades preservadas

Criação/edição/eliminação nos editores existentes; associação disciplina–trabalho; conclusão/reabertura de tarefas/avaliações; aulas recorrentes; planeamento, início, pausa, retoma, conclusão explícita, histórico e eliminação de sessões. As datas antigas e IDs não são regravados para adequar o visual.

TaskOperations, academic_rules, study_repository, modelos, SQLite v5, lifeos.sqlite, XP, Metas, Finanças, Hábitos, notificações, identificador Android, dependências/lockfile e navegação principal permanecem preservados. O opt-in de tema do editor de TaskRow só é activado em Estudos; a adaptação do cabeçalho da criação rápida só actua num contexto premium com texto ampliado. Ver [verificação de preservação](ux/phase4c3c/preservation.json).

## 6. Componentes premium reutilizados

PremiumTokens, PremiumScope, PremiumSurface e PremiumFocusOutline existentes. Botões, campos, checkbox, ícones e expansões herdam os estados do tema aprovado. Sem segundo Design System, novos pacotes ou tokens divergentes. Os formulários académicos deixam rótulos e nomes de disciplina quebrar linha quando necessário; não se diminuiu a fonte para resolver o layout.

## 7. Capturas Flutter antes/depois

[Comparações e índice completo](ux/phase4c3c/CAPTURES.md). **200 PNG reais**, 100 por revisão: 84 de Estudos e 16 de contextos externos. Sete cenários académicos × claro/escuro × 320/360/390 dp × 100/200%. Incluem vazio, disciplinas/lista, trabalhos e avaliações, foco iniciado, detalhe em linha, criação de trabalho e temporizador com foco de teclado.

Mesmo relógio e fixtures sintéticas, mesmas dimensões e fontes locais. Renderer Flutter de testes, RepaintBoundary a 2×; sem HTML, colagem ou maquetas. O formulário a 200% usa insets de teclado simulados de 280 dp. As capturas externas cobrem Hoje, Planear, Metas, Tarefas, Finanças, Progresso, Hábitos e Agenda, nos dois temas. [Manifesto de dimensões e hashes](ux/phase4c3c/visual-validation.json).

## 8. Testes e resultados

Baseline 272. Acrescentados **20 testes**: 12 combinações de tema/largura/escala, dois percursos de foco com/sem gamificação, criação/edição de trabalho, navegação sem escrita, erro/retentativa, carga, histórico legado sem data e visibilidade da acção ao abrir foco. O teste académico existente foi adaptado para abrir a secção de actividades adicionais quando a data fica fora da pré-visualização; conserva as asserções de gravação e XP.

A matriz verifica ordem, semântica, dimensões, foco/Tab, movimento reduzido, ausência de barras sem métrica e de superfícies premium aninhadas, e igualdade dos dados antes/depois de leitura. O percurso de foco pausa após 10 segundos, regressa duas horas depois, retoma o tempo preservado e conclui explicitamente; uma segunda conclusão não duplica XP. O trabalho é criado com subject_id e editado mantendo ID/associação/dia NULL; o teste simula espaço de teclado a 200%.

Resultados finais locais e CI: ver secção 11 e [resumo estruturado](ux/phase4c3c/test-results.json). A suite existente de regras, persistência, tarefas, XP, Hoje, Planear e Metas permanece incluída. A execução intermédia detectou as 12 combinações sem o token explícito de expansão; após a correcção local, a matriz de 20 testes passou e a suite completa foi repetida. As 100 renderizações são uma execução separada, não somadas artificialmente à suite.

## 9. Contraste, foco e touch targets

Não se alterou a paleta. O indicador de expansão usa action explicitamente no tema local de Estudos, nos estados aberto e fechado; evita herdar Sage do ColorScheme no claro. A suite premium calcula luminância sobre os Color reais do Flutter e confere os tokens com a matriz 4C.2. Em background/surface/soft: texto secundário mínimo **4,814:1 claro / 7,297:1 escuro**; texto principal mínimo 12,292/11,644; acção/foco mínimo 5,034/6,951; outline mínimo 4,173/4,508. Texto Graphite/Sage 7,917:1; limite interior do botão Sage 3,242:1 claro e 7,917:1 escuro. [Matriz de referência](ux/phase4c2/CONTRAST.md) e [resultados dos tokens reutilizados](ux/phase4c3a/contrast-results.json).

Tema define alvos mínimos 48×48 dp, campos mínimos 56 dp, foco exterior de 2 dp com separação; selecção/pressão/erro/desactivação conservam distinção. Os testes medem adicionar/editar disciplina, checkbox e acções por disciplina nas 12 combinações, exercitam teclado/semântica e conferem o contorno. O temporizador recebe foco e desloca a sua acção para a área visível. Movimento reduzido elimina a animação de deslocação e de expansão.

SafeArea e scroll dos contentores existentes são preservados. Insets de teclado simulados, texto a 200% e janelas pequenas são verificados no renderer; a ordem falada, contraste de cada pixel composto e teclado real precisam de verificação em dispositivo. Não se declara conformidade integral WCAG.

## 10. Build Android

Build debug local com Flutter 3.35.7/Java 21, sem novos pacotes ou alteração de configuração Android. O artefacto local não foi adicionado ao Git nem publicado. Resultado definitivo e CI na secção seguinte. Não foi feito ensaio de actualização/assinatura sobre telefone com dados reais.

## 11. GitHub Actions

Pendente de publicação do commit e observação dos dois workflows. As únicas alterações aos workflows acrescentam este branch às listas de push; comandos, verificações e permissões permanecem iguais.

## 12. Ficheiros modificados

Produção: lib/features/academics/academics_screen.dart (novo contentor), academics_panel.dart (hierarquia e linhas), academic_editor.dart (apresentação acessível), focus_timer.dart (superfície e foco), lib/features/screens.dart (despacho), lib/app/app.dart (tema da área), lib/features/tasks/presentation/task_row.dart (tema opt-in), quick_task_sheet.dart (cabeçalho responsivo só no contexto afectado).

Testes: test/academics_widget_test.dart, phase4c3c_studies_test.dart e phase4c3c_focus_visibility_test.dart. Evidência: tool/capture_academics.dart, docs/PHASE4C3C_REPORT.md, docs/ux/phase4c3c/* e docs/ux/previews/phase4c3c/*.png. CI: os dois ficheiros existentes de validação Flutter/Android, exclusivamente para activar o branch. A lista exacta consta do diff do commit.

## 13. Regressões detectadas e corrigidas

- A imagem real mostrou o indicador de expansão aberto em Sage sobre a superfície clara, abaixo de 3:1. Um teste reproduziu a ausência de cor funcional explícita. O tema local de Estudos passa a usar action aberto/fechado, sem alterar expansões de outros módulos. A matriz verifica ambos os papéis nas 12 combinações.

- Com texto a 200%, o cabeçalho Nova tarefa competia com Cancelar; passou a duas linhas no contexto premium ampliado. As acções Guardar e restantes campos continuam iguais.
- O título longo de disciplina e rótulos de campos perdiam espaço; edição da disciplina passa para botão abaixo a 200%, rótulos/itens podem quebrar linha. Nenhuma redução de fonte.
- Abrir foco a partir de uma sessão mais abaixo inseria o temporizador acima do viewport. Um teste falhou antes da correcção; agora desloca/foca a acção, respeitando movimento reduzido.
- Um histórico legado sem completed_at mostrava start como se fosse conclusão. Um teste reproduziu o problema. A apresentação agora diz Data de conclusão não registada e identifica separadamente a data planeada, sem inventar ou gravar uma conclusão.
- O teste antigo procurava uma avaliação de data distante na lista aberta; foi adaptado à divulgação progressiva, sem remover a verificação da operação.

## 14. Limitações

Renderer de teste e SQLite sintético não substituem TalkBack, IME, teclado físico, desempenho, áreas de sistema e restauração por morte do processo num Android real. A retoma persistida/idempotência já testadas não constituem certificação desses cenários no telefone. Foco não emite alarme em segundo plano, conforme o comportamento existente.

A lista de disciplinas continua em linha; não foi criada navegação de detalhe. Próximas actividades é apenas um resumo, sem modo de prazo separado para trabalhos. A edição da disciplina usa o formulário partilhado actual; não se reconstruíram os restantes formulários ou módulos. As capturas externas são uma amostra de estados, não prova de todas as combinações visuais possíveis.

## 15. Recomendação para 4C.3D

Rever as comparações reais e validar num dispositivo Android com TalkBack, teclado aberto, texto ampliado e interrupção/retoma antes de alargar a aplicação dos componentes. Manter a separação entre dia de tarefa e eventual prazo académico; qualquer novo modelo exige decisão própria. O próximo módulo deve partir da auditoria aprovada e preservar as suas regras. **4C.3D, Finanças e Progresso não foram iniciados; dependem de autorização explícita.**
