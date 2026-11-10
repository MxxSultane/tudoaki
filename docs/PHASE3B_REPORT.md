# Fase 3B — criação rápida de tarefas

## Base e âmbito
Branch feat/fase-3b-criacao-rapida, derivado de 8c036392289d1b4f068059b42d50c4e96c225d7b (contratos 3A). A última base de código é 80576edb4bcd82b28aa8cb91147ad9a5d065be0f: entre ambos só há três documentos. CI verde dessa base confirmado pelo utilizador e observado na página pública Actions (run 42772226886). Os contratos são aplicados com os ajustes explícitos do pedido 3B: uma só data, guardar explícito, preservar origem/navegação/XP, nenhum novo Desfazer ou correcção alheia.

## Ponto de entrada e comportamento visual
Única integração: Mais → Estudos → expandir disciplina → Adicionar trabalho. Reutiliza a associação existente à disciplina e mantém o ecrã/expansão de origem depois de guardar. Não substitui + → Tarefa, Adicionar acção, o planeador ou qualquer edição. Editar a tarefa criada continua a abrir Editor de forms.dart.

showQuickTaskSheet é reutilizável, aceita initialDate (dia civil), goalId e subjectId. Não serve para editar. A folha usa o tema existente, uma coluna deslocável com margem 20, título, Cancelar e campo Título focado com teclado. Dia contextual é visível e alterável/retirável; nunca herda uma hora implícita. NULL sem data, YYYY-MM-DD sem hora e ISO com hora explícita são serializados nos campos já suportados, sem novo prazo.

Mais opções revela hora/lembrete, prioridade 0/1/2 (Baixa/Normal/Alta), importante e associações opcionais a meta/disciplina. Associações herdadas aparecem também na zona compacta. Remover dia/hora desliga o lembrete. Só dia+hora permite activar lembrete; TaskOperations continua a coordenar as permissões/agendamento, sem reimplementar persistência ou XP. Guardar usa um único botão principal; Guardar e adicionar outra é uma acção secundária.

Guardar/IME: valida título, bloqueia alterações e duplo envio enquanto aguarda create. Só fecha após resposta. A origem mostra uma confirmação inline acessível: Tarefa guardada, ou Tarefa guardada; lembrete indisponível. Não muda de rota/filtro e não cria um banner de sucesso. Falha de agendamento não é tratada como falha SQLite nem oferece criar outra vez a mesma tarefa. Falha de gravação mantém rascunho/campos e permite tentar de novo.

Guardar e adicionar outra: mantém dia, meta e disciplina; limpa título, hora, lembrete, prioridade e importância, recolhe opções e repõe foco/teclado. A confirmação fica na folha até à próxima gravação. Cada tarefa guardada tem ID próprio; cancelar um rascunho posterior não apaga as anteriores. Ao fechar, devolve o último TaskWriteResult para a confirmação de origem.

Cancelar/Voltar sem mudanças fecha sem escrita. Com mudanças, pede confirmação; continuar conserva o rascunho e descartar não escreve. Durante gravação, fechar está bloqueado. Toque na barreira e arrastar para fechar estão deliberadamente desactivados: usar Cancelar ou Voltar permite controlar perda de dados. Rascunho só em memória; não se promete recuperação após encerramento do processo. Sem Desfazer novo.

## Ficheiros
- Novo lib/features/tasks/presentation/quick_task_sheet.dart: componente e função de abertura.
- Modificado lib/features/academics/academics_panel.dart: só o callback Adicionar trabalho e confirmação inline na disciplina de origem.
- Novos test/quick_task_sheet_test.dart e test/quick_task_entry_test.dart.
- Modificado .github/workflows/flutter-validation.yml: só acrescenta o branch ao disparo push, sem mudar comandos/critérios.
- Novo docs/PHASE3B_REPORT.md.

## Testes
Catorze casos de componente: foco/teclado e título, data contextual sem hora implícita, mudança de dia, campos opcionais/associações, retirar dia/hora/lembrete, recusa do agendamento, guardar outra mantendo só contexto, cancelar limpo, descartar alterações, erro de gravação com repetição, bloqueio de duplo toque/IME/fecho, descarte após gravação anterior, fecho limpo após criação continuada e layout claro/escuro em 360 px, texto 200% e teclado simulado.

Dois casos de integração pelo ponto real em Estudos: sucesso e lembrete recusado; verificam subject_id, rota /academics, confirmação, tarefa visível e editor completo preservado. Bases SQLite em memória, serviço TaskOperations real, lembretes simulados; teste de duplo envio usa apenas um bloqueio de espera em torno do serviço. Testes antigos inalterados.

## Validação e CI
Formatação oficial Dart 3.9.2 aplicada; verificação lib/test com 74 ficheiros, zero alterações, código 0. Há aviso de flutter_lints não resolvido porque não existem dependências locais. flutter analyze --no-pub e flutter test --no-pub tentados, mas o bootstrap parou com HTTP 403 de storage.googleapis.com antes de analisar/carregar testes. Não foram executados testes Flutter localmente.

Estado inicial da CI desta implementação: **pendente de execução observada**, não validado. A API GitHub continua a responder Forbidden; a página pública Actions permite observar estados. Registar o run e os resultados observados antes de declarar a fase validada.

## Preservação e limites
Sem alterações em esquema SQLite v5/lifeos.sqlite, identificador Android, dependências, TaskOperations, XP/conquistas, finanças, navegação, rotas, Design System, Hoje/Planear, planeador semanal ou forms.dart. Não activa /plan nem remove formulários antigos. Não há acesso a bases reais ou migrações de produção.

Validação física do teclado, TalkBack/VoiceOver, suspensão e entrega real de lembretes continua pendente. Rascunhos não são persistidos e a criação rápida ainda só tem uma entrada. A implementação não resolve defeitos conhecidos de outras áreas. Sem merge automático; próxima fase apenas mediante aprovação.
