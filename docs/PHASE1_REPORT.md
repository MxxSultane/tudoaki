# Tudo aki 2.0 — Fase 1: protecção, contratos e preparação

## Referência e isolamento
Data: 8 de Novembro de 2026 (Maputo). Branch inicial encontrado: `work`, HEAD `9283217523f9952221c98996b56a90b1fbe383dd`, árvore limpa, versão 0.9.2+12. Branch de trabalho criado: `prep/tudo-aki-2-fase-1`. Não foram feitas alterações directamente em main ou work.

## Alterações
Contratos futuros de produto e design, mantendo explícita a diferença entre estado entregue e direcção 2.0. Proposta de importação/restauro sem implementação. Seis novos casos de caracterização (três parametrizações de persistência e três fluxos de widgets); testes anteriores preservados.

## Referência de execução, antes das alterações
| Comando pedido | Resultado observado |
| --- | --- |
| flutter analyze --no-pub | Não executou: flutter: command not found (127) |
| flutter test --no-pub | Não executou: flutter: command not found (127) |
| flutter build apk --debug --no-pub | Não executou: flutter: command not found (127) |

O script tool/env.sh foi carregado, mas /workspace/.tools/flutter não existe neste ambiente. Flutter e Dart não estão no PATH; .dart_tool/package_config.json não está disponível. Não instalei ferramentas ou dependências. Não há resultado novo de análise, execução dos testes, formatação Dart ou compilação. Não foi possível identificar falhas funcionais pré-existentes por execução. Os 80 testes aprovados na documentação são resultados históricos da entrega 0.9.2; os seis novos casos estão **não executados**, não aprovados.

## Matriz de caracterização
| Contrato | Cobertura existente | Cobertura acrescentada |
| --- | --- | --- |
| Criar/editar/concluir/reabrir tarefa | app_test, repository_test | phase1_task_flows: criação só com título, cancelar sem escrita, editar campos compactos, concluir/reabrir por navegação real |
| ID e relações ao reagendar | weekly_planner_widget_test, goal_planning_test | novo caso no planeador: pendente com meta/disciplina, reagendamento date-only, mesmo ID/created e uma única linha |
| Lembretes | reminders_test, task_reminders_widget_test | serviço de gravação simulado confirma mesmo ID/título/hora ao editar; cancelar ao concluir e reagendar ao reabrir; sem chamadas Android reais |
| Compatibilidade v5 | currency_test, academics_test, repository_test | phase1_v5_characterization: fixture sintética de esquema actual, abrir v5 sem mudança do catálogo SQL; comparar exportação das 20 tabelas e integridade de FKs |
| Precisão de data | weekly_planner_test | três casos NULL, YYYY-MM-DD e ISO com hora, preservando os demais campos após escrita/reabertura |
| Navegação actual | app_test, weekly_planner_widget_test | criar em Tarefas, filtros Pendentes/Concluídas e navegação semanal sem escritas; três destinos actuais, não os quatro futuros |
| XP/conquistas | repository_test, progress_test, academics_test | completar/reabrir mantém primeira atribuição de 10 XP e conquista first_task; métrica de meta independente |

A fixture v5 é criada pelas declarações actuais num ficheiro temporário; não é cópia de dispositivo nem demonstra compatibilidade com bases corrompidas. Testes existentes continuam a proteger migrações anteriores. Esta fase não executou migrações, nem sequer nos fixtures, porque os testes não puderam arrancar.

## Defeitos conhecidos: regressões a criar na fase que os corrigir
Não transformar estas limitações em expectativas desejadas ou testes skip que aparentem cobertura:
- Hábitos: criar o primeiro e o segundo pela navegação real, ambos visíveis. Hoje a segunda criação não tem entrada visível.
- Calendário: evento que atravessa meia-noite deve aparecer na continuação e participar nos conflitos do dia seguinte.
- Limites: abrir selectores para datas válidas até 31/12/2100; editor actual limita a 01/01/2100.
- Acessibilidade: filtros devem anunciar selecção; testar semântica e TalkBack.
- Revisões: edição/eliminação com confirmação depois de aprovar a exposição destas acções.
- Primeira utilização: validar planeamento de amanhã, descoberta e hora opcional sem tutoriais. A actual diferença de data/hora por entrada não foi fixada como requisito.

## Riscos pendentes
Sem restauro, exportação não garante recuperação. Exportação actual lê tabelas sequencialmente; proposta futura deve garantir consistência. Sem validação física de notificações, assinatura/actualização, fecho do processo e acessibilidade. IDs de XP não contêm títulos; Percurso precisa de contrato histórico próprio. Hábitos/Estudos/Finanças/Revisões/Definições ainda dependem de screens.dart. Ver RESTORE_PLAN.md e auditoria anterior.

## Verificação de âmbito
Diff restrito a documentação e testes; nenhuma alteração em lib/, android/, assets/, pubspec.yaml, pubspec.lock ou tool/. Preservados applicationId mz.lifeos.lifeos, lifeos.sqlite, esquema v5, regras financeiras, XP/conquistas e versão da aplicação. Nenhum dado real ou dispositivo aberto. Isto confirma ausência de alterações de produção nesta fase, não certifica protecção dos dados dos telefones.

## Ficheiros da entrega
Modificados: AGENTS.md; README.md; docs/ARCHITECTURE.md; docs/DESIGN_SYSTEM.md; docs/IMPLEMENTATION_PLAN.md; docs/PRD.md; docs/PRODUCT_VISION.md; docs/PROGRESS.md; docs/USER_STORIES.md; test/weekly_planner_widget_test.dart.

Novos: docs/V2_CONTRACTS.md; docs/RESTORE_PLAN.md; docs/PHASE1_REPORT.md; test/phase1_v5_characterization_test.dart; test/phase1_task_flows_test.dart.

## Próximo passo
Preparar um ambiente Flutter e executar os três comandos --no-pub, com dependências previamente disponíveis; se faltarem, obter autorização de preparação. Rever/corrigir os testes novos com base em falhas reais, sem enfraquecer contratos. Só depois da validação e aprovação explícita iniciar a Fase 2: extracção interna gradual das áreas activas e coordenação de operações, sem redesenho automático. Fase 2 não iniciada.
