# Contratos da Tudo aki 2.0

Estado: direcção aprovada; implementação futura. Referência de produção: 0.9.2+12 / 9283217. Esta Fase 1 não altera produção.

## Experiência
Organizador completo e imediato, sem exigir tutoriais. Preservar tarefas, agenda, metas, hábitos, estudos, finanças, revisões e progresso. Navegação prevista: Hoje / Planear / Metas / Mais. Tarefas mantém acesso explícito a definir no desenho; Percurso não exige um quinto destino. A barra actual com três destinos continua em produção até uma fase aprovada de navegação.

## Uma tarefa, vários contextos
Tasks é a fonte única. Reagendar e editar preservam ID, created, associações e campos não modificados. Hoje, Planear, Tarefas, Metas e Estudos apresentam vistas dos mesmos registos. Cancelar um formulário não escreve. Guardar torna o resultado visível; permitir correcção/desfazer conforme a operação e com contrato a aprovar antes de implementar.

Só título obrigatório na criação rápida em folha inferior; data, hora, lembrete, prioridade e associações opcionais. Sem data é válido. O contexto do planeador pode fornecer dia; não transformar esse contexto em obrigação universal. Planear amanhã, outro dia e semana é manual/opcional; não criar tarefas nem compromissos automaticamente.

## Data planeada e prazo
**Data planeada:** quando a pessoa pretende actuar. **Prazo de entrega:** limite para entregar/concluir. Podem diferir; planear não deve apagar o prazo.
Actualmente só Tasks.due serve os dois usos e a agenda. Não adicionar campos nem recategorizar dados nesta fase. Manter NULL, data civil YYYY-MM-DD e ISO com hora. Antes de mudar, aprovar política para o legado: não inferir qual dos dois significados o utilizador pretendia. Preservar o valor original e testar limites, fusos e lembretes. Duração não existe nas tarefas actuais; não a inventar.

## Associações e resultados
Tarefa pode ligar-se opcionalmente a meta e disciplina; hábito pode ligar-se a meta. Metas suportam hierarquia sem ciclos, etapas e métricas manuais. Avaliações e estudos partilham disciplinas, sem ligação directa actual à tarefa/meta. Eventos pessoais são independentes. Associações futuras a outras áreas precisam de modelo aprovado; não converter silenciosamente avaliações em tarefas nem metas de poupança em Goals.

## Percurso
Linha temporal ramificada, constelações, marcos e capítulos. Identidade Sage & Graphite e movimento discreto. Sem penalizar descanso ou ausência. Manter alternativa textual e suporte a movimento reduzido.
ExperienceEvents guarda source/points/created, não títulos completos. Com gamificação desactivada, acções não geram XP; estudos adicionais ao limite não geram XP. Logo, XP não é uma linha temporal completa. GoalProgress, HabitCompletions e StudySessions também têm semânticas próprias, incluindo eliminação/reabertura. Definir histórico de actividade antes de criar constelações; não fabricar detalhes ausentes. Reconhecimento acumulado e estado actual são métricas diferentes.

Regras a preservar: tarefa 10 XP uma vez por ID; hábito 5 XP uma vez por hábito/dia; foco 15 XP até três sessões recompensadas/dia; nível 1 + XP ~/ 100; quatro conquistas idempotentes, sem XP extra. Desactivar preserva histórico e suspende atribuição/reconhecimento. Esta fase não muda estas regras.

## Critérios futuros de aceitação
- Percursos principais compreensíveis sem explicação prévia: testar com pessoas novas, não presumir.
- Sem duplicações após reagendamento e sem perda de relações ou precisão de data.
- Acesso a todas as áreas com criação disponível em estados vazios e preenchidos.
- Uma acção principal por contexto, opções avançadas progressivas, edição previsível.
- Claro/escuro, 360 px, texto a 200%, TalkBack, teclado e contraste AA.
- Evolução de esquema apenas aditiva e testada em cópias sintéticas; actualização Android validada com assinatura compatível.
