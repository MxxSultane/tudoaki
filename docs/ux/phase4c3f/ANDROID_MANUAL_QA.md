# Validação Android física — gate da versão candidata

**Não executada nesta máquina.** Não há USB exposto e a enumeração ADB falhou ao tentar criar preferências no directório de utilizador protegido. Não se ligou, instalou, desinstalou ou limpou qualquer telefone. Build/renderização Flutter Linux não substituem estes ensaios.

## Preparação segura

1. Usar telefone de testes com dados sintéticos e autorização do proprietário; registar modelo, Android/API, resolução, escala, orientação, modo de navegação e versão instalada. Não usar dados reais como fixture.
2. Confirmar a identidade `mz.lifeos.lifeos`, versão e certificados da aplicação instalada e do APK de teste. Inspeccionar `adb devices -l`, `adb shell dumpsys package mz.lifeos.lifeos` e `apksigner verify --print-certs <apk>`. Se assinaturas diferirem, **parar a actualização**, sem desinstalar, trocar assinatura ou limpar armazenamento.
3. Preparar uma versão de testes anterior compatível, com a mesma assinatura e SQLite v5. Criar tarefas (sem dia/dia/hora), relações, hábitos, metas numéricas/histórico, disciplina/sessão e receitas/despesas em moedas diferentes. Guardar exportação JSON e contagens. O export inclui metadados variáveis; comparar tabelas/IDs/valores e não o timestamp do envelope.
4. Só após compatibilidade confirmada, instalar por actualização `adb install -r <apk-debug-de-teste>`. Sem release, Play Store, flags de downgrade ou `pm clear`. Se o aparelho tiver a aplicação real e a assinatura de testes não corresponder, usar outro dispositivo de testes; não substituir a app.

## Roteiro e evidência obrigatória

| Ensaio | Passos exactos | Aceitação / evidência |
| --- | --- | --- |
| Actualização | Comparar export/tabelas antes/depois; abrir dados antigos e voltar | IDs, FKs, due exacto, cêntimos/moeda, XP e histórico iguais; versão de esquema 5 |
| Tarefas A | Hoje → Adicionar tarefa; guardar; Mais → Tarefas → editar; reagendar em Planear; concluir/reabrir/concluir; eliminar com confirmação | Mesmo ID até eliminar; sem duplicação de XP; lembrete revisto/cancelado conforme regra existente |
| Metas B | Criar com métrica e alvo explícitos; editar nome; registar valor abaixo/acima do alvo; consultar histórico; voltar a valor abaixo | Apenas modo numérico; histórico e valores correctos; conclusão/reabertura existentes, sem XP inventado |
| Estudos C | Mais → Estudos → Adicionar disciplina; criar trabalho na disciplina; editar; criar/iniciar sessão; pausar; sair; aguardar; retomar e concluir explicitamente | Trabalho conserva subject_id/ID; pausa não consome tempo; retoma não atribui XP; conclusão idempotente |
| Finanças D | Receita e despesa; mudar mês/moeda; editar; rever recorrência; cancelar; voltar a rever/confirmar uma vez | Totais por moeda exactos; cancelar não grava; segunda confirmação não duplica vencimento |
| Progresso E | Concluir tarefa; Mais → Progresso; consultar actividade; Percurso; Linha/Lista; Ver tarefas; repetir com Ver todas as metas | Mesmas entradas/datas/valores; sem erro de stack; nenhuma escrita/XP por consulta |
| Hábitos F | Criar três hábitos; registar um; sair/voltar; editar; reabrir/registar no mesmo dia | Todos visíveis/persistidos; XP diário único; pausa preservada |
| Planeamento G | Criar trabalho em Estudos; consultar Tarefas/Hoje/Planear sem dia; reagendar para amanhã; voltar à disciplina | Mesmo ID/associações e sem cópia/contexto perdido |
| IME e rascunho | Com teclado real, abrir criação rápida, opções avançadas, título longo, Guardar outra; Voltar e confirmação de descarte | Campos/acções alcançáveis, rascunho/contexto conforme contrato; sem gravação ao cancelar |
| TalkBack | Percorrer quatro destinos, nove áreas, filtros, checkbox, campos/erros, dropdown, valores financeiros, actividade e Linha/Lista | Nomes, papel/estado, ordem, sem duplicações; desenho sem paragens inúteis; erro compreensível |
| Texto/tema/foco | Claro/escuro, 100/200%, 320/360/390 equivalentes; teclado físico Tab/Shift+Tab/Enter/Espaço; alternar orientação | Alvos ≥48, foco visível, nenhum recorte/overflow; verificar compreensão de rótulos que quebram na barra estreita |
| SafeArea/gestos | Navegação por gestos e três botões, teclado aberto, rotação; fechar modal superior e voltar aos ramos | Acções fora de recortes; Voltar respeita modal; estado dos ramos preservado |
| Interrupção | Foco a correr/pausado: background, bloqueio de ecrã, chamada simulada; retomar; abrir tema | Mesmo estado persistido; sem conclusão/XP automático |
| Notificações | Autorizar/recusar permissão; criar/editar/reagendar/concluir tarefa com lembrete em futuro válido; reiniciar dispositivo | Sem prometer entrega se sistema bloqueia; conferir cancelamento/reagendamento real |
| Desempenho | APK profile separado com assinatura compatível, DevTools Timeline; 100/1k/10k registos sintéticos; abrir/scroll/Linha/Lista/diálogo cinco vezes por cenário | Registar p50/p95 de frames, raster/UI, abertura, consultas, memória, jank, temperatura e bateria; sem limiar ou aprovação inventados |

Guardar capturas/vídeo, logs sem dados pessoais, resultado por linha, versão/SHA e assinatura. Falhas de integridade ou necessidade de mudar contratos abrem tarefas técnicas; não se resolvem com migrações improvisadas. Sem evidência física, o gate permanece pendente e não se declara versão final ou certificação WCAG.
