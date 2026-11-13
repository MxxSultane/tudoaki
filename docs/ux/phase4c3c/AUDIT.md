# Estudos — auditoria e preservação 4C.3C

Auditoria do código e percurso real sobre 058ae625bbec82eb97c7eaf0f4eeca0414672f7f, antes das alterações. Complementa a auditoria 4B e a revisão 4C.2; não reabre a investigação dos restantes módulos.

| Capacidade activa | Código/dados | Acesso preservado nesta entrega |
| --- | --- | --- |
| Entrada Estudos | /academics, AreaScaffold, TudoAkiScreen, AcademicsPanel, dataProvider | Mesma rota e barra; novo AcademicsScreen dentro do conteúdo |
| Disciplinas | Subjects; showEditor Disciplina | Adicionar disciplina; expandir linha; editar directamente (botão abaixo da linha com texto ampliado) |
| Aulas recorrentes | ClassSchedules; academic_editor | Expandir disciplina → Adicionar aula; tocar numa aula para editar/eliminar no editor |
| Trabalhos | Tasks.subject_id, criação rápida, TaskRow, editor existente | Expandir disciplina → Adicionar trabalho; editar/concluir pelas linhas existentes; lista adicional reúne todos |
| Avaliações | Assessments; academic_editor | Nova avaliação directa; Adicionar avaliação na disciplina; tocar para editar/eliminar; checkbox concluir/reabrir; realizadas na lista adicional |
| Sessões planeadas | StudySessions; academic_editor | Planear estudo; Adicionar estudo por disciplina; pré-visualização da próxima e lista completa; tocar para editar quando ainda não iniciada; eliminar com confirmação |
| Foco | FocusTimerCard; study_repository | Abrir foco → Iniciar; destaque Retomar para sessão iniciada/pausada; Pausar/Retomar/Registar sessão; histórico e eliminação mantidos |
| Agenda/Planear | academicEventsForDay; consultas das mesmas entidades | Projecção de leitura; nenhuma cópia ou escrita ao navegar |
| XP | studyExperiencePoints=15; dailyRewardedStudySessions=3; preferência gamification | Mesma conclusão explícita/idempotente; explicação recolhida no fim, omitida com gamificação desligada |
| Carregamento/erro | dataProvider | Indicador de carga separado do vazio; mensagem e Tentar novamente |

**Sem entidades inventadas.** Trabalho continua a ser uma tarefa associada; Tasks.due continua NULL/dia/ISO com hora. O rótulo é «Dia da tarefa», nunca «prazo de entrega». A avaliação conserva a sua própria data/hora. Não há notas, aproveitamento, percentagem académica, produtividade, novos modos de estudo ou notificações de fim de foco. Minutos e contagens exibidos são derivados dos registos existentes.

**Antes:** introdução, botões, temporizador automático, explicação XP, sessões/histórico, avaliações/concluídas, tarefas chamadas prazos, disciplinas no fim. O temporizador e as explicações empurravam a organização académica para baixo.

**Agora:** identidade na barra; retoma compacta quando aplicável; até duas actividades pendentes nos próximos sete dias; disciplinas; próxima acção/sessão; sessões completas, histórico e todos os trabalhos/avaliações em secções rotuladas; informação de foco/XP no fim. A janela é uma pré-visualização, não um filtro destrutivo: atrasados, sem dia, mais distantes e concluídos continuam na lista adicional. Expandir disciplina mantém detalhe em linha; não existe nem se inventa uma rota de detalhe separada.

Não se acrescentam opções «avançadas» fictícias: os editores existentes continuam a disponibilizar todos os campos e eliminação. A navegação principal e os serviços de operação não foram redesenhados.
