# Validação Android

Guião da Fase 6, versão 0.9.2. **Execução física pendente**: o ambiente de desenvolvimento não tem telefone nem emulador Android ligado. Os testes automatizados simulam o canal de notificações e o ciclo de vida Flutter; não certificam a entrega pelo sistema.

## Preparação
No Android Studio, parar a app, actualizar main, executar `flutter pub get` e voltar a executar `lib/main.dart`. Instalar por cima da aplicação anterior, com a mesma assinatura. Preservar `mz.lifeos.lifeos` e os dados; não desinstalar nem limpar armazenamento para testar uma actualização.

Se o pull parar por causa de `pubspec.lock`, guardar primeiro esse ficheiro com `git stash push -m "Guardar lock local" -- pubspec.lock` e repetir `git pull --ff-only origin main`. Não reaplicar o lock antigo após actualizar.

## Casos a executar
| Caso | Passos | Resultado esperado |
| --- | --- | --- |
| Actualização | Criar tarefa/meta/evento na versão anterior, fechar e instalar a nova com a mesma assinatura. | Dados e associações preservados, novo ícone e três separadores. |
| Permissão | Criar tarefa com hora futura, abrir Mais opções e activar Lembrete local; recusar a permissão Android 13+. | Tarefa guardada, aviso de lembrete indisponível; sem falha da app. Autorizar nas definições Android e voltar a guardar permite tentar de novo. |
| Entrega | Com notificações autorizadas, programar uma tarefa para alguns minutos depois e deixar a app em segundo plano. | Notificação com o título correcto. O alarme é aproximado e o Android pode atrasá-lo em repouso. Registar hora prevista e efectiva. |
| Editar/concluir | Reagendar um lembrete; depois concluir a tarefa antes da nova hora. | Alarme anterior substituído ao editar e cancelado ao concluir; tarefa continua guardada. |
| Reabrir | Reabrir tarefa com lembrete e data futura; repetir com data já passada. | Na futura, tentar agendar; na passada, preservar a tarefa e indicar indisponibilidade, sem pedir permissão só para uma data passada. |
| Sem hora | No planeador criar tarefa só com dia; abrir Mais opções. | Lembrete indisponível até definir uma hora; não se agenda à meia-noite. |
| Reiniciar telefone | Programar tarefa futura com lembrete, reiniciar normalmente o telefone e aguardar. | Receptor de arranque repõe o alarme. Confirmar também após actualizar a app. Encerramento forçado nas definições Android é distinto de fechar a janela e pode bloquear alarmes até reabrir a app. |
| Foco | Iniciar foco, mudar de app e regressar depois do prazo; repetir fechando e reabrindo o processo. | Contagem recuperada do prazo SQLite, sem XP automático; confirmação da sessão atribui XP uma única vez. Pausa mantém o tempo restante. Não há alarme de fim em segundo plano. |
| Acessibilidade | Claro/escuro, largura pequena, texto a 200%, TalkBack, teclado aberto nos formulários. | Acções acessíveis, possibilidade de deslocar o conteúdo e distinção entre Concluir/Reabrir. |

## Registo
Para cada caso, anotar versão da app, modelo, versão Android, permissões, restrições de bateria, hora de Maputo e resultado observado. Registar falhas com os passos exactos e logs sem dados pessoais. Só marcar a validação física como concluída depois de executar estes casos; actualmente permanece pendente.
