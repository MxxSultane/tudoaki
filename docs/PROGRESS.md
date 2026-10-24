# Progresso — Tudo Aki

## Estado por fase
A fase principal é a consolidação do núcleo funcional (Fase 2), em paralelo com os controlos de qualidade da Fase 6.

| Fase | Estado | Entrega e pendências |
| --- | --- | --- |
| 1 — Fundação | Concluída para desenvolvimento | Arquitectura, tema, navegação e SQLite preparados. |
| 2 — Núcleo funcional | Implementado; validação real do MVP pendente | Hoje, tarefas, agenda, metas, submetas e etapas; lembretes e ciclo de reabertura Android ainda precisam de dispositivo. |
| 3 — Organização pessoal | Parcial | Hábitos, disciplinas e revisões; horários, avaliações e foco pendentes. |
| 4 — Áreas de vida | Parcial | Transacções, poupanças e bem-estar via hábitos; orçamentos e recorrência financeira pendentes. |
| 5 — Gamificação | Parcial | XP e níveis; catálogo de conquistas e gráficos pendentes. |
| 6 — Qualidade | Em curso | Análise, testes automatizados e APK; utilização, notificações e acessibilidade num dispositivo ainda pendentes. |

## Fundação e núcleo implementados
- Documentos de visão, requisitos, histórias, arquitectura, design e fases criados antes do código.
- Flutter 3.35.7 / Dart 3.9.2, Riverpod, GoRouter e Material 3; português, tema claro/escuro, cinco áreas principais.
- Drift/SQLite nativo, esquema v2 com 15 entidades e migração aditiva v1 → v2, chaves estrangeiras, índices, transacções e recusa de migrações desconhecidas.
- Metas com horizonte, métrica, prazo, edição e histórico; criação de acções associadas. Métricas de resultados independentes da conclusão de tarefas.
- Tarefas com prioridades, importância, disciplina, meta e data/hora; edição, reagendamento, conclusão, reabertura e eliminação.
- Agenda diária/semanal/mensal em lista; eventos com edição, recorrência diária/semanal e sinalização de sobreposição entre eventos.
- Hábitos com dias da semana, plano quando/então, pausa, registo e histórico.
- Disciplinas e trabalhos associados; revisões semanais/mensais persistidas.
- Receitas, despesas, contribuições e metas de poupança em centavos; resumo mensal em MZN.
- XP opcional e idempotente por tarefa e por hábito/dia, níveis e resumo textual de progresso.
- Boas-vindas ignoráveis, estados vazios, erros, exportação JSON pela partilha do sistema e eliminação confirmada dos dados.
- Adaptador Android para notificações com permissão a pedido, agendamento aproximado em Africa/Maputo e receptores de reinício. Notificações não foram validadas num dispositivo.

## Incremento 0.2.0 — concluído
- Submetas com relação à meta principal e sugestão de horizonte mensal/semanal; selector sem a própria meta nem descendentes e prevenção de ciclos também na base.
- Painel **Plano desta meta** com submetas, etapas e tarefas directamente associadas.
- Etapas com título, prazo opcional, edição, conclusão/reabertura e eliminação; confirmação descreve a preservação dos dados associados.
- Migração transaccional v1 → v2 e exportação JSON com a versão actual. Nenhuma dependência nova.
- Testes adicionais verificam hierarquias, ciclos, eliminação de pai, edição de etapas, exportação e abertura/migração/reabertura de um ficheiro v1. O novo teste de widget cria uma submeta, gere etapas e conclui uma tarefa sem modificar métricas indevidamente.

## Incremento 0.2.1 — identidade oficial
- Nome **Tudo Aki** e slogan **A tua vida, organizada num só lugar.** no cabeçalho, onboarding e documentação; nome oficial também no título da aplicação e na exportação.
- Identificador Flutter/Dart e nome Gradle `tudo_aki`; classes e namespace Android actualizados.
- Ícone com visto branco e fundo verde-petróleo, ícones adaptativo/monocromático e arranque com a mesma identidade.
- ID Android `mz.lifeos.lifeos` e ficheiro `lifeos.sqlite` preservados apenas para compatibilidade com instalações e dados anteriores; esquema v2 e funcionalidades inalterados.
- Teste do nome e slogan no fluxo inicial e teste de quebra de linhas do cabeçalho com texto a 200% em ambos os temas.

## Verificação efectuada no ambiente
- `flutter pub get`: concluído, lockfile gerado e dependências instaladas.
- `dart format lib test`: executado.
- `flutter analyze`: sem problemas na verificação final concluída.
- `flutter test --reporter expanded`: **20 testes aprovados**, incluindo o fluxo de widget meta → tarefa associada → agendamento → conclusão → XP, recusa de versão futura da base, persistência em ficheiro após reabertura, hábitos, relações, dinheiro e recorrência.
- `python3 tool/check_schema.py`: SQL, relações, unicidade, centavos e reabertura aprovados.
- `flutter build apk --debug`: **aprovado**; APK em `build/app/outputs/flutter-apk/app-debug.apk` (149.4 MiB), Tudo Aki 0.2.1, Android 7.0+ (API 24), target API 36, ARM64/ARMv7/x86-64.
- `apksigner verify --verbose`: assinatura de depuração v2 verificada. O APK apresenta o nome Tudo Aki, uma única actividade no launcher e os ícones novos, mantendo o ID de instalação anterior. `aapt dump badging` confirmou identidade, versões, permissões e arquitecturas.
- SHA-256 do APK: `36f715af982e57f207135bfe663f309a33c54bdaef522661a664e4a0e92bc203`.

## Ambiente e reprodução
`tool/setup.sh` fixa o Flutter por commit oficial e o Temurin JDK 21.0.13+9 por SHA-256, instala dependências com lockfile, prepara SQLite de testes e as ferramentas Android. `tool/env.sh` activa os caminhos. `tool/setup_android.sh` usa o checksum oficial da CLI e configura o proxy Java sem copiar credenciais. SDKs/caches ficam em `/workspace/.tools`, fora do repositório da aplicação. A instalação foi repetida com sucesso, com o lockfile respeitado. `install_script`, `start_skill` e o domínio `storage.googleapis.com` foram guardados no rascunho; isso não publica o ambiente.

A primeira tentativa de download do catálogo Flutter teve 403 e depois 404; a instalação pelo Git oficial funcionou. A ligação `libsqlite3.so` em `.tools/native` usa a biblioteca do sistema já existente. As pastas de estado Dart/Flutter/analisador/adb no directório pessoal precisaram de permissões de escrita específicas. O Gradle precisou de propriedades explícitas para usar o proxy do ambiente. O Java original não fornecia o compilador exigido pelo Gradle; foi instalado um JDK completo. O Temurin usa o repositório de certificados Java do sistema para confiar no proxy, com TLS verificado; o sdkmanager recebe os parâmetros de proxy explicitamente. Foram identificadas as APIs Android 34, 35 e 36, o NDK 27 e o CMake 3.22.1 exigidos pela aplicação/plugins. Nenhuma verificação TLS ou de pacotes foi desactivada.

## Pendências e limites
O MVP **ainda não está certificado num dispositivo Android**. Falta testar a entrega de lembretes e a persistência no ciclo de fecho/reabertura do processo Android; o teste existente valida SQLite em Linux. Sem dispositivo ligado e sem `/dev/kvm` neste ambiente.

Fases posteriores: edição de uma ocorrência isolada e excepções de recorrência; eventos que atravessam vários dias e conflitos com blocos de tarefas; categorias configuráveis; horários e avaliações académicas dedicados; sessões de estudo e temporizador de foco; orçamentos e despesas recorrentes; moeda configurável; conquistas com catálogo; WOOP guiado; interesses no onboarding; backup/importação; suporte a outros fusos/DST e plataformas; verificação de acessibilidade em dispositivo.

Há tabelas preparadas para sessões de estudo e conquistas, mas isso não constitui funcionalidades disponíveis na interface. As etapas de metas já dispõem de interface funcional. A grelha mensal avançada e os gráficos não fazem parte desta fundação. Não há analytics, conta, backend, sincronização bancária ou encriptação implementada.

## Execução
```bash
cd /workspace/tudoaki
source tool/env.sh
flutter analyze
flutter test
flutter devices
flutter run -d <dispositivo-android>
flutter build apk --debug
```

Um build de distribuição requer uma chave de assinatura configurada separadamente. A publicação do ambiente cloud é independente dos commits no GitHub. A configuração reutilizável deve ser revista e guardada nas definições do ambiente antes da publicação.
