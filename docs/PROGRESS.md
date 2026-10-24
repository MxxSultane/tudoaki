# Progresso — LifeOS

## Fundação e núcleo implementados
- Documentos de visão, requisitos, histórias, arquitectura, design e fases criados antes do código.
- Flutter 3.35.7 / Dart 3.9.2, Riverpod, GoRouter e Material 3; português, tema claro/escuro, cinco áreas principais.
- Drift/SQLite nativo, esquema v1 com 15 entidades, chaves estrangeiras, índices, transacções e recusa de migrações desconhecidas.
- Metas com horizonte, métrica, prazo, edição e histórico; criação de acções associadas. Métricas de resultados independentes da conclusão de tarefas.
- Tarefas com prioridades, importância, disciplina, meta e data/hora; edição, reagendamento, conclusão, reabertura e eliminação.
- Agenda diária/semanal/mensal em lista; eventos com edição, recorrência diária/semanal e sinalização de sobreposição entre eventos.
- Hábitos com dias da semana, plano quando/então, pausa, registo e histórico.
- Disciplinas e trabalhos associados; revisões semanais/mensais persistidas.
- Receitas, despesas, contribuições e metas de poupança em centavos; resumo mensal em MZN.
- XP opcional e idempotente por tarefa e por hábito/dia, níveis e resumo textual de progresso.
- Boas-vindas ignoráveis, estados vazios, erros, exportação JSON pela partilha do sistema e eliminação confirmada dos dados.
- Adaptador Android para notificações com permissão a pedido, agendamento aproximado em Africa/Maputo e receptores de reinício. Notificações não foram validadas num dispositivo.

## Verificação efectuada no ambiente
- `flutter pub get`: concluído, lockfile gerado e dependências instaladas.
- `dart format lib test`: executado.
- `flutter analyze`: sem problemas na verificação final concluída.
- `flutter test --reporter expanded`: **13 testes aprovados**, incluindo o fluxo de widget meta → tarefa associada → agendamento → conclusão → XP, recusa de versão futura da base, persistência em ficheiro após reabertura, hábitos, relações, dinheiro e recorrência.
- `python3 tool/check_schema.py`: SQL, relações, unicidade, centavos e reabertura aprovados.
- `flutter build apk --debug`: **aprovado**; APK em `build/app/outputs/flutter-apk/app-debug.apk` (149.4 MiB), LifeOS 0.1.0, Android 7.0+ (API 24), target API 36, ARM64/ARMv7/x86-64.
- `apksigner verify --verbose`: assinatura de depuração v2 verificada. `aapt dump badging` confirmou identidade, versões, permissões e arquitecturas.
- SHA-256 do APK: `8578b1d79e1b098ea6a5d2de69c5a220e805ad82c956dc774fd82f44e58dfd98`.

## Ambiente e reprodução
`tool/setup.sh` fixa o Flutter por commit oficial e o Temurin JDK 21.0.13+9 por SHA-256, instala dependências com lockfile, prepara SQLite de testes e as ferramentas Android. `tool/env.sh` activa os caminhos. `tool/setup_android.sh` usa o checksum oficial da CLI e configura o proxy Java sem copiar credenciais. SDKs/caches ficam em `/workspace/.tools`, fora do repositório da aplicação. A instalação foi repetida com sucesso, com o lockfile respeitado. `install_script`, `start_skill` e o domínio `storage.googleapis.com` foram guardados no rascunho; isso não publica o ambiente.

A primeira tentativa de download do catálogo Flutter teve 403 e depois 404; a instalação pelo Git oficial funcionou. A ligação `libsqlite3.so` em `.tools/native` usa a biblioteca do sistema já existente. As pastas de estado Dart/Flutter/analisador/adb no directório pessoal precisaram de permissões de escrita específicas. O Gradle precisou de propriedades explícitas para usar o proxy do ambiente. O Java original não fornecia o compilador exigido pelo Gradle; foi instalado um JDK completo. O Temurin usa o repositório de certificados Java do sistema para confiar no proxy, com TLS verificado; o sdkmanager recebe os parâmetros de proxy explicitamente. Foram identificadas as APIs Android 34, 35 e 36, o NDK 27 e o CMake 3.22.1 exigidos pela aplicação/plugins. Nenhuma verificação TLS ou de pacotes foi desactivada.

## Pendências e limites
O MVP **ainda não está certificado num dispositivo Android**. Falta testar a entrega de lembretes e a persistência no ciclo de fecho/reabertura do processo Android; o teste existente valida SQLite em Linux. Sem dispositivo ligado e sem `/dev/kvm` neste ambiente.

Fases posteriores: hierarquia de submetas e marcos com UI; edição de uma ocorrência isolada e excepções de recorrência; eventos que atravessam vários dias e conflitos com blocos de tarefas; categorias configuráveis; horários e avaliações académicas dedicados; sessões de estudo e temporizador de foco; orçamentos e despesas recorrentes; moeda configurável; conquistas com catálogo; WOOP guiado; interesses no onboarding; backup/importação; suporte a outros fusos/DST e plataformas; verificação de acessibilidade em dispositivo.

Há tabelas preparadas para marcos, sessões de estudo e conquistas, mas isso não constitui funcionalidades disponíveis na interface. A grelha mensal avançada e os gráficos não fazem parte desta fundação. Não há analytics, conta, backend, sincronização bancária ou encriptação implementada.

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
