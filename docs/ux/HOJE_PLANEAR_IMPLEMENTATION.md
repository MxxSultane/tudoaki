# Hoje e Planear — aceitação, dependências e aprovação

Documento complementar à [especificação UX](HOJE_PLANEAR_SPEC.md). Todos os critérios abaixo são de uma implementação futura, não resultados obtidos nesta Fase 3A.

## Cenários e critérios verificáveis

| ID / caso | Percurso e resultado a verificar |
| --- | --- |
| A01 Novo utilizador | Abrir Hoje com base vazia: orientação e + Tarefa visíveis, sem secções/cartões vazios. Abrir a criação sem tutorial, escrever «Comprar pão», Guardar: uma linha persistida, visível e com o teclado fechado. |
| A02 Adicionar rapidamente | Hoje → + Tarefa → título → Guardar. Teclado já activo, sem selector de tipo obrigatório, hora ou associação exigida. Dia contextual pode ser retirado; três etapas lógicas, não uma promessa de tempo medido. |
| A03 Planear antes de dormir | Em 10/11/2026 às 23:50, tocar Planear amanhã: ver 11 Nov, adicionar tarefa sem hora. Consultar Hoje não a mostra como pendente do dia 10; em 11 Nov passa a pertencer a Hoje, com o mesmo ID. Recalcular a data civil ao retomar a aplicação. |
| A04 Organizar a semana | Abrir Semana, escolher três dias e adicionar/escolher tarefas. Nenhuma hora é obrigatória. Mudar de semana e regressar preserva os registos; apenas consultar não escreve. Domingo 15 Nov sugere 16–22 Nov, podendo escolher a semana anterior. |
| A05 Sem data | Criar «Ler» em Sem data, guardar e reabrir: due continua NULL. Escolher 12 Nov move a mesma tarefa; Retirar dia repõe NULL, sem perder meta/disciplina. A contagem e a lista são actualizadas, sem duplicação. |
| A06 Concluir em Hoje | Marcar uma tarefa: sai de pendentes, entra em Concluídas hoje e conta uma vez. Desfazer/reabrir e concluir novamente mantém as regras de XP únicas. Falha SQLite não altera a interface para sucesso. |
| A07 Reagendar | Mover uma tarefa de 11 para 12 Nov e observar ambas as vistas: desaparece de uma e aparece noutra, uma linha/ID. Associação e created intactos. Timestamp mantém hora explicitamente; escolha apenas de dia remove hora/lembrete após indicação visível. |
| A08 Associar a meta | Criar/editar com meta opcional e disciplina opcional; mostrar as associações herdadas. Guardar mantém IDs/FKs. A tarefa aparece no plano da meta; concluí-la não muda a métrica medida. Sem associações também guarda. |
| A09 Muitos compromissos | Fixture com 50 tarefas e 20 compromissos no dia: Hoje resume os próximos dois e dá acesso aos vinte; todas as tarefas são alcançáveis. Sem scroll preso, texto truncado, duplicação ou botão sobre o último item. Perfil de desempenho em dispositivo antes de fixar um orçamento de tempo. |
| A10 Regresso após ausência | Com dez pendentes de dias anteriores, regressar uma semana depois: não alterar datas, não criar tarefas nem reduzir XP. Secção recuperável, sem mensagens de culpa. |
| A11 Guardar/continuar/cancelar | Duplo toque/IME não duplica gravação. Continuar a criar mantém a folha e aplica os defaults definidos na especificação; fechar descarta só o rascunho, nunca tarefas já guardadas. Erro conserva título/opcionais para repetir. |
| A12 Editar e voltar | Entrar por Hoje, Planear ou meta; editar um título e regressar ao mesmo contexto. ID, precisão da data, reminder, completed, meta e disciplina não alterados permanecem iguais. Descartar uma edição não escreve. |
| A13 Lembretes | Alterar título com lembrete ligado conserva configuração e actualiza o mesmo alarme. Dia sem hora/sem data cancela-o e fica desligado. Permissão recusada avisa sem perder a tarefa. Recuperar o lembrete nunca chama create outra vez. |
| A14 Precisão temporal | YYYY-MM-DD não se torna ISO à meia-noite; ISO explícito 00:00 continua com hora. Datas UTC/Maputo são agrupadas no dia correcto, incluindo mudança de dia durante suspensão. Eventos académicos mantêm origem e editor. |
| A15 Excepções e acessibilidade | Testar leitura/gravação falhada, registo eliminado durante edição, 360 px, texto a 200%, claro/escuro, teclado e leitor de ecrã. Foco entra no título e regressa à acção/item de origem; erro, selecção e confirmação são anunciados. |
| A16 Cobertura das áreas | Após activar futuramente os quatro destinos, abrir e regressar de Tarefas, Hábitos, Estudos, Finanças, Progresso, Revisões, Definições e Metas, incluindo os editores de eventos. Manter caminhos antigos necessários e comportamento Voltar aprovado. |

Validação de compreensão proposta: observar cinco pessoas que nunca usaram a app, sem explicação de botões, a criar uma tarefa, planear amanhã e reagendar uma existente. Alvo a aprovar: quatro de cinco terminam cada percurso sem ajuda; medir erros e tempo. Para «Comprar pão», alvo exploratório de mediana até dez segundos após tocar + Tarefa; não declarar atingido sem observar. Estes números são metas de avaliação, não alegações de usabilidade já certificada.

## Correspondência com o código existente

| Requisito | Base encontrada | Trabalho futuro / esquema |
| --- | --- | --- |
| Uma tarefa em vários contextos | TaskOperations em lib/features/tasks/domain/task_operations.dart e TudoAkiRepository | Reutilizar create/edit/setCompleted/delete; não criar outra tabela/store. UI precisa de tratamento de foco, estado e resultados; v5 suficiente. |
| Reagendar/retirar dia | TaskOperations.reschedule(id, due) conserva o texto e desliga reminder para NULL/data sem hora | Para manter uma hora escolher explicitamente timestamp. Para mudar só o dia e manter um lembrete usar os valores correctos em edit; testar sem reactivar permissões por surpresa. V5 suficiente. |
| Projecções Hoje/Planear | dataProvider (snapshot das 20 tabelas), agendaItemsForDay e academicEventsForDay | Criar selectores coerentes de pendentes/concluídas/sem data e dia civil. A lista Hoje e a ordenação proposta exigem código novo; nenhuma tabela nova. Evitar armazenar cópias em Cubits. |
| Semana | WeeklyPlannerCubit e WeeklyPlannerScreen existentes | Reutilizar regra de domingo, selecção e dados; integrar no destino Planear sem clonar entidades ou inventar um plano semanal persistido. Controlo integrado de quatro vistas ainda não existe. |
| Destinos | AppDestination.today.path=/, plan.path=/plan, goals=/goals, more=/areas; AppRoutes conserva caminhos antigos | /plan ainda não é rota. Activar só com página funcional e aprovação. Contrato de contexto dia/vista pode usar estado/Cubit e parâmetros URI a definir; não há hoje query parameters aprovados para amanhã/semana. Não anunciar deep links Android novos. |
| Criação/edição | showEditor/Editor em forms.dart; campos/serialização e TaskWriteResult/falhas de lembrete | Actual tem selector de tipo antes do editor e defaults de data diferentes. A folha proposta, autofocus, continuação, confirmação de rascunho e retorno contextual exigem implementação futura; v5 suficiente. Não reenviar campos ocultos com defaults que apaguem dados existentes. |
| Confirmação e correcção | dataProvider invalidado pelo serviço; TaskRow conclui/reabre com feedback táctil | Linhas de confirmação, Desfazer e conservação de posição/foco são trabalho novo de UI. Reabrir usa regra actual e mantém XP. Não oferecer desfazer eliminação ou lote sem contrato adicional. |
| Hábitos/avaliações/estudo | HabitsScreen/buildHabitCards, AcademicsPanel, editores académicos e modelos de leitura | Reutilizar registos e operações; seleccionar a sessão ao entrar em Estudos exige adaptação de navegação futura. Sem nova associação automática avaliação→tarefa. |
| Independência de prazo e planeamento | Tasks tem apenas due; não há deadline/planned_date distintos | **Separação exige modelo/migração futura aprovada**, adaptação de exportação, eventual restauro e política para legado ambíguo. Não inferir significado do valor actual nem dizer que reagendar preserva um prazo separado. Excluir essa separação da primeira entrega v5. |
| Robustez e grandes volumes | Snapshot global, lista actual e operações por ID | Listas progressivas, relógio/lifecycle e medições precisam de código. TaskOperations.edit não confirma hoje que UPDATE afectou uma linha: o estado «já eliminada» exige guarda futura. Não assumir que isso está resolvido. |

Todos os ficheiros referidos existem na base 80576ed. São pontos de integração, não autorização para os alterar agora.

## Riscos e pré-condições
- Datas legadas podem ter sido usadas como prazo: designar «Dia» não resolve essa ambiguidade. A primeira entrega mantém uma só data e só a modifica por acção explícita, com linguagem que não prometa prazo independente. Sem migração nesta proposta inicial.
- O modelo de agenda actual só inclui o dia inicial de eventos; a continuação após meia-noite e seus conflitos precisa de correcção/testes com aprovação própria antes de prometer cobertura completa. Não esconder o compromisso nem duplicá-lo na tabela para o contornar.
- Permissões, alarmes aproximados e gravação SQLite têm resultados distintos. Não há transacção distribuída; cancelamento falhado ao eliminar continua a impedir eliminação. Qualquer mudança dessa regra exige decisão própria.
- Seleccionar Sem data ou data sem hora desliga reminder: guardar/desfazer ou regressar ao editor não deve reactivá-lo silenciosamente. Importância/prioridade e relações existentes não podem desaparecer ao fechar opções avançadas.
- O relógio e a conversão civil não são uniformes em todos os módulos; escolher uma política única (Maputo como referência inicial) e testar UTC, fronteira de dia e regresso da suspensão. Não prometer suporte global a fusos/DST sem trabalho adicional.
- Rascunho em memória pode perder-se ao encerrar o processo. Rascunho durável, histórico detalhado, ordem manual e prazo separado são fora da primeira entrega; podem exigir persistência nova e contratos próprios, ainda não definidos.
- O snapshot global pode tornar grandes históricos lentos. Medir e limitar o trabalho de apresentação sem misturar uma reescrita de persistência/estado com a primeira mudança visual.
- A regra de data sugerida, ordenação, confirmação ao descartar e retorno ao contexto são mudanças funcionais futuras face ao editor actual. Só devem entrar após aprovação da especificação e testes; esta fase não corrige os defeitos auditados.

## Decisões que precisam de aprovação

| Decisão | Proposta concreta |
| --- | --- |
| D1 Data na primeira entrega | Uma única data associada, apresentada como Dia, hora opcional; prazo final separado adiado até modelo/migração próprios. |
| D2 Estrutura de Hoje | Ordem e limites da tabela UX: dois próximos compromissos, tarefas sem limite fixo, secção recolhida de dias anteriores, até três hábitos, concluídas por completed_at. Ordenação por importância/prioridade antes da hora. |
| D3 Rascunho e continuação | Confirmar descarte só se há alterações; guardar apenas por acção explícita. Continuar mantém dia/associações visíveis e repõe os restantes opcionais. Rascunho durável excluído. |
| D4 Confirmação e retorno | Manter a origem após guardar; nova linha ou confirmação inline com Ver quando fora da vista. Desfazer conclusão sem retirar XP; não prometer desfazer eliminação. |
| D5 Acesso e estado | Hoje/Planear/Metas/Mais; Tarefas em Mais. Planear abre Hoje na primeira visita, preserva selecção na sessão e mantém a sugestão semanal actual de domingo. Definir navegação contextual e compatibilidade antes de activar /plan. |
| D6 Linguagem temporal | «De dias anteriores», sem penalização nem reagendamento automático. Uma hora passada hoje não gera estado de dia atrasado. |
| D7 Visual e validação | Paleta semântica aprovada como referência, tema escuro por definir, alvos 48 px e avaliação sem tutorial com os alvos propostos. |
| D8 Correcções prévias | Autorizar separadamente as guardas de tarefa eliminada, fronteiras de datas/eventos entre dias e consistência do relógio; não as incluir implicitamente numa alteração estética. |

## Implementação em incrementos pequenos — apenas proposta

| Incremento | Entrega e condição para avançar |
| --- | --- |
| 3B.1 — Contratos visuais e dados de leitura | Após aprovação de D1–D8, fechar tokens/acessibilidade/tema escuro, ordenação e contexto dia/vista; acrescentar testes dos casos A03/A07/A14. Correcções prévias aprovadas em alterações separadas. Nenhuma barra nova até haver destinos funcionais. |
| 3B.2 — Folha de tarefas | Criar a folha funcional sobre TaskOperations e reutilizar campos existentes; testar A01/A02/A08/A11–A13/A15. Integrar por pontos aprovados sem activar simultaneamente os quatro destinos. Manter editores antigos acessíveis até verificar equivalência. |
| 3B.3 — Planear funcional | Integrar dia/semana/sem data, consultas académicas e reagendamento no mesmo store. Testar A03–A05/A07/A09/A14 antes de registar/activar /plan para utilizadores. |
| 3B.4 — Hoje e transição da barra | Construir Hoje, confirmar que os quatro destinos e a entrada Tarefas estão completos; só então activar a barra aprovada. Preservar caminhos anteriores e Voltar; testar A06/A10/A16 e regressões das fases 2A–2C. |
| 3B.5 — Validação de uso | Android real: teclado, foco, suspensão, notificações e actualização com dados. Observar primeiras utilizações, medir A09 e alvos de compreensão antes de declarar experiência pronta. |

Cada incremento exige PR, CI observada, demonstração do fluxo e revisão; não fazer merge automático. Se testes de navegação aprovados para três separadores precisarem de evoluir na activação visual, explicitar a mudança esperada e manter a cobertura dos caminhos e dados antigos; não apagar critérios de persistência para obter verde. A Fase 3B não está iniciada.
