# Propostas por módulo — sem redesenho implementado

As constatações estão em AUDIT e na 4B. Aqui definem-se hierarquia, acesso e limites futuros. Manter as rotas actuais: Estudos/Finanças/Progresso no navigator secundário com Voltar; Metas no shell. Não acrescentar destino à barra Hoje/Planear/Metas/Mais.

## Estudos

Ordem: título único → retoma de foco se existir → próximas entregas (trabalhos e avaliações com origem explícita) → disciplinas → sessões de estudo e histórico recolhíveis. Data/prazo e tipo antes de estatísticas de XP. Não duplicar grelha horária da Agenda; «Ver na Agenda» é consulta aos mesmos registos, dependente do encaminhamento existente, sem nova rota prometida. A entrada de trabalho continua a tarefa real ligada à disciplina.

Uma acção principal normal: **Planear estudo**. «Nova avaliação» e «Adicionar disciplina» são acções textuais próximas da respectiva secção; horários/aulas, trabalhos, avaliações, edição e eliminação ficam nos detalhes da disciplina. Durante foco activo, a acção principal passa a **Retomar sessão**; Planear estudo mantém acesso secundário. O temporizador não pausa ou conclui ao navegar; nenhum novo XP por abrir/reabrir.

SubjectTile clay: nome, próxima entrega quando existir, contagem contextual de trabalhos pendentes verificável. Se não houver entrega, não inventar «em dia». UpcomingRow plana: data, nome, origem (avaliação/tarefa), disciplina; tocar abre o editor da origem. Estado «Sem prazo» não vira zero dias. Sessões com editar/iniciar/eliminar em acções nomeadas, sem comprimir o nome entre três ícones em linha a 200%.

Vazio: adicionar disciplina e planear estudo continuam disponíveis mesmo sem dados. Erro de leitura não mostra «Nenhuma entrega». Foco activo tem estado textual acessível, timer não anuncia cada segundo ao leitor. Manter histórico/retoma/pausa e edição de sessões, disciplinas, aulas, avaliações e trabalhos. Reorganização não muda academic_rules, study_repository, limites de XP, datas ou ordenação financeira.

## Finanças

Ordem: título → mês e moeda com alvos 48 dp → resumo compacto → **Registar movimento** → movimentos recentes → acesso progressivo a orçamentos, poupanças, recorrências e histórico. Apresentar Entradas (Receitas), Saídas (Despesas) como linguagem de interface, conservando os tipos existentes. «Saldo dos movimentos» não é saldo bancário, lucro, fluxo de caixa completo ou previsão.

Resumo plano: valores e moeda, sem clay/glass por trás de números. Receitas, despesas e contribuições para poupança continuam categorias distintas; o acesso aos cinco valores do resumo actual fica em «Ver composição». Não esconder contribuições nem incluí-las noutro total por conveniência visual. A fórmula permanece a de finance_rules. Movimentos: sinal, tipo por texto, título, dia e moeda; não depender de cor. Nunca somar moedas diferentes nem mostrar um total convertido.

Moeda e aviso curto «Sem conversão cambial» sempre identificáveis; explicação maior expandida. Mudar moeda conserva o selector existente e a semântica de novos registos; não altera moeda de registos antigos. Registo rápido abre editor suportado, não cria novo caminho de escrita. Poupanças preservam associação/moeda, não passam a Goals.

Recorrências continuam a exigir revisão e confirmação de vencimentos; a página não gera movimentos ao abrir. Orçamentos mantêm mês/categoria/moeda e cálculo. Histórico/edição/eliminação dos movimentos, contribuições, metas de poupança, orçamentos e regras devem continuar descobríveis a partir do primeiro ecrã em no máximo uma expansão e uma entrada de detalhe.

Vazio distingue «Sem movimentos nesta moeda/mês» de ausência global ou falha. Erro preserva mês/moeda, sem zerar valores já lidos. Valor longo a 200% quebra a linha antes do número, não dentro do sinal/número com perda da moeda. Sem gráfico circular decorativo ou métricas de negócio que os dados não suportem.

## Progresso

Um único título; ordem: actividade real da última semana → metas em evolução → hábitos/histórico → conquistas e XP opcionais. Sem nova métrica agregada de «vida concluída». Consultar é a intenção principal: **não introduzir um botão principal artificial**. «Fazer uma revisão» mantém-se secundário.

ActivityWeek resume as mesmas contagens de activityWeek; expandir revela dias/tipos e lista textual. Sem actividade, «Sem actividade registada neste período», sem penalizar descanso. Metas por modo usam o resultado verdadeiro; hábitos mostram registos do período, sem streak punitivo novo. Informação é actual, sujeita às eliminações/reaberturas existentes, não auditoria imutável.

Exploração visual conceptual: pequeno conjunto de nós/linhas para actividade disponível, com glass controlado apenas no painel decorativo e lista textual equivalente sempre ao lado/abaixo. Um nó representa uma categoria/data comprovada; se não houver título histórico, usar «Registo de hábito · 12 Nov», não inventar o nome eliminado. Não desenhar trajectos completos da vida, marcos automáticos ou constelações com eventos inexistentes. O Percurso completo fica excluído.

ExperienceEvents é reconhecimento incompleto: com gamificação desligada e sessões além do limite pode faltar XP. Não usar XP como única fonte do histórico. Goals/GoalProgress, HabitCompletions, Tasks e StudySessions não têm todos as mesmas datas/semânticas; a futura camada de leitura deve declará-las antes de combinar. Ausência de eventos não prova ausência de actividade. Não inventar eventos «criação de meta» se created não comprovar mais do que isso.

Conquistas/nível respeitam gamificação; desactivar não elimina histórico nem recalcula XP. Os quatro catálogos e regras mantêm-se. Com movimento reduzido o mapa é estático; se a transparência/fundo não for seguro, superfície sólida. A lista é suficiente para todas as consultas sem depender de animação ou de tocar em pontos pequenos.
