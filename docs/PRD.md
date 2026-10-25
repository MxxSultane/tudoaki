# Requisitos e prioridades
## Must (MVP)
Arranque sem conta; cinco áreas Hoje/Agenda/Metas/Progresso/Perfil; tarefas com edição, prioridade, prazo e associação a meta; eventos; metas com métricas e acções; hábitos e histórico; SQLite offline; lembretes locais mediante permissão Android; estados vazios; eliminação de dados; testes.
## Should
Recorrência diária/semanal, revisões, transacções, poupanças, orçamentos e recorrências financeiras, exportação JSON, modo escuro, disciplinas, horários de aulas, avaliações e foco configurável.
## Could / fases posteriores
Calendário mensal avançado, edição de instância recorrente, subtarefas, WOOP guiado, ciclos automáticos de foco/descanso, gráficos avançados de tendências, backups, personalização de categorias, conquistas extensas.
## Regras
Concluir uma tarefa não altera automaticamente a métrica da meta. XP é opcional e idempotente; reabrir/concluir a mesma tarefa não soma XP novamente. Hábitos pausados preservam histórico. Sem dados de demonstração injectados.
## Critério de entrega
MVP só pode ser declarado concluído após testes do fluxo criar meta → associar e agendar tarefa → lembrete → concluir → reabrir com dados preservados, incluindo num dispositivo Android. Limitações e funcionalidades por implementar constam em PROGRESS.md.

## Organização académica — versão 0.3.0
- Horários semanais com disciplina obrigatória, horas de início/fim no mesmo dia, local opcional e validade por datas civis; avaliações com tipo, data/hora e duração; sessões de estudo com disciplina opcional.
- Aulas, avaliações e blocos planeados de estudo aparecem na agenda e participam na detecção de conflitos. Trabalhos associados a disciplinas continuam a usar tarefas.
- Foco de 1–180 minutos, com pausa, retoma e confirmação depois do prazo. Só uma sessão pode estar em curso; a regra existe na base e no repositório. Não se edita uma sessão iniciada/concluída; pode ser eliminada com confirmação.
- XP idempotente: 15 por sessão de foco confirmada, até três sessões premiadas por dia local; registos adicionais são preservados. Desactivar gamificação mantém o estudo e o histórico sem XP.
- Sem alarme de fim de foco em segundo plano nesta versão. Tempo recuperado por prazo UTC, incluindo ao reabrir a base; funcionamento real em suspensão Android ainda não certificado.

## Planeamento financeiro — versão 0.4.0
- Orçamento único por mês/categoria normalizada, com limite positivo, despesas realizadas e restante exactos. Alterar um orçamento não altera movimentos.
- Movimentos manuais com data editável e metas de poupança editáveis. Contribuições preservadas sem associação quando a meta é apagada.
- Regras semanais/mensais/anuais de receita ou despesa, com período de validade e activação. Nenhum movimento automático: datas/valores são revistos antes de confirmação explícita, até 24 ocorrências por lote.
- Registo único por regra/vencimento; um ledger conserva vencimentos mesmo quando o movimento correspondente foi eliminado. Eliminar a regra preserva os movimentos financeiros.
- Alterações não reescrevem histórico; revisões impedem confirmar uma pré-visualização desactualizada. O calendário de uma regra com registos é preservado.
- Montantes individuais em centavos inteiros e somas com BigInt, sem conversão monetária por double. Na versão 0.4.0, MZN era a única moeda; a versão 0.6.0 acrescenta denominação por registo.

## Progresso — versão 0.5.0
Gráfico de actividade dos sete dias civis mais recentes com contagens por área e semântica acessível. Quatro conquistas persistentes reconhecem o histórico de XP sem pontos adicionais ou exigência de dias consecutivos. Gamificação desactivada oculta conquistas e suspende novos reconhecimentos; o gráfico funcional permanece disponível.

## Moedas — versão 0.6.0
MZN/USD/EUR/ZAR configuráveis para novos registos, com duas casas decimais. Cada movimento, orçamento, poupança e regra preserva a sua denominação. Consultas e totais são separados por moeda; contribuições incompatíveis são recusadas. O histórico anterior permanece MZN. Sem câmbio automático.

## Integração — versão 0.8.0
O pedido actual recupera as funcionalidades na nova interface: três separadores com dados reais, criação/edição/conclusão, detalhe de metas e acesso Mais aos módulos pessoais. Não voltar a introduzir cinco separadores ou dados de exemplo. Preservar os dados de instalações anteriores e mostrar imediatamente o registo criado. Formulários devem preservar campos avançados quando ocultos.

## Planeamento semanal — versão 0.9.0
Função secundária em Mais, adaptada ao telemóvel, com escolha de tipo e um dia de cada vez. Domingo sugere a próxima semana. O plano resulta dos eventos/tarefas reais, com gravação por formulário e inclusão dos registos existentes. Tarefas aceitam dia sem hora; pendentes podem ser programadas sem cópia. Não acrescentar separadores, notificações de domingo ou dependências.
