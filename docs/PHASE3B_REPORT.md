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
A preparação inicial continuou bloqueada por HTTP 403 de storage.googleapis.com. A primeira execução remota, [42781011054](https://github.com/MxxSultane/tudoaki/actions/runs/42781011054), falhou no passo agregado. O estado foi observado na página pública; os logs exigiam login e a API continuou a responder Forbidden.

Foi possível preparar Flutter local com a cache da imagem pública cirruslabs/flutter:3.35.7 em GHCR, sem executar o contentor nem alterar fontes do projecto. Digests das camadas conferidos antes de extrair; fontes Flutter locais na revisão oficial adc901062556672b4138e18a4dc62a4be8f4b3c2. flutter --version confirmou Flutter 3.35.7 e Dart 3.9.2. Este procedimento é preparação de ferramentas fora do repositório, não uma alteração de dependências da app.

flutter pub get --enforce-lockfile passou, sem alterar pubspec.yaml ou pubspec.lock. A reprodução local inicial encontrou três avisos: dois if sem chavetas e use_super_parameters num construtor de teste. Os 16 testes novos já passavam; só se corrigiram os três pontos de estilo, sem mudar critérios.

Resultados locais após correcção:
- dart format --output=none --set-exit-if-changed lib test: código 0, 74 ficheiros e zero alterações.
- flutter analyze --no-pub: código 0, sem problemas.
- flutter test --no-pub --reporter expanded: código 0, **122 aprovados, 0 falhados**, incluindo os 16 casos novos e todos os antigos. Duração observada 53 segundos.
- git diff --check, sintaxe YAML/shell e preservação das áreas protegidas aprovados.

CI da correcção: **ainda pendente de resultado observado**. Não declarar a fase validada até uma nova execução verde. A contagem acima é da suite local, não uma contagem remota inventada.

## Preservação e limites
Sem alterações em esquema SQLite v5/lifeos.sqlite, identificador Android, dependências, TaskOperations, XP/conquistas, finanças, navegação, rotas, Design System, Hoje/Planear, planeador semanal ou forms.dart. Não activa /plan nem remove formulários antigos. Não há acesso a bases reais ou migrações de produção.

Validação física do teclado, TalkBack/VoiceOver, suspensão e entrega real de lembretes continua pendente. Rascunhos não são persistidos e a criação rápida ainda só tem uma entrada. A implementação não resolve defeitos conhecidos de outras áreas. Sem merge automático; próxima fase apenas mediante aprovação.
