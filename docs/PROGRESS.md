# Progresso — Tudo Aki

## Estado por fase
A Fase 3 está implementada no escopo actual de organização pessoal/académica, com os controlos de qualidade da Fase 6 em curso. As Fases 4–5 continuam parciais.

| Fase | Estado | Entrega e pendências |
| --- | --- | --- |
| 1 — Fundação | Concluída para desenvolvimento | Arquitectura, tema, navegação e SQLite preparados. |
| 2 — Núcleo funcional | Implementado; validação real do MVP pendente | Hoje, tarefas, agenda, metas, submetas e etapas; lembretes e ciclo de reabertura Android ainda precisam de dispositivo. |
| 3 — Organização pessoal | Implementada no escopo actual; validação Android pendente | Hábitos, disciplinas, horários, avaliações, sessões de estudo, foco e revisões. |
| 4 — Áreas de vida | Parcial | Transacções, poupanças e bem-estar via hábitos; orçamentos e recorrência financeira pendentes. |
| 5 — Gamificação | Parcial | XP e níveis; catálogo de conquistas e gráficos pendentes. |
| 6 — Qualidade | Em curso | Análise, testes automatizados e APK; utilização, notificações e acessibilidade num dispositivo ainda pendentes. |

## Fundação e núcleo implementados
- Documentos de visão, requisitos, histórias, arquitectura, design e fases criados antes do código.
- Flutter 3.35.7 / Dart 3.9.2, Riverpod, GoRouter e Material 3; português, tema claro/escuro, cinco áreas principais.
- Drift/SQLite nativo, esquema v3 com 17 entidades e migrações aditivas v1/v2 → v3, chaves estrangeiras, índices, transacções e recusa de migrações desconhecidas.
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

## Incremento 0.3.0 — organização académica
- Horários semanais por disciplina com validade e local; avaliações com data/hora, duração e registo de realização; trabalhos ligados às disciplinas por tarefas.
- Sessões de estudo com duração configurável (1–180 min), foco persistido, pausa/retoma e confirmação da conclusão; histórico separado do planeamento.
- Aulas, avaliações e estudo participam na agenda diária/semanal/mensal e nos conflitos. Hoje apresenta o próximo compromisso académico e o acesso a uma sessão de foco activa.
- XP único por sessão, 15 pontos até três sessões premiadas por dia, opcional; todas as conclusões continuam no histórico.
- Migração v1/v2 → v3 preserva dados existentes e inicializa o estado de estudo. Exportação e eliminação total incluem os dados académicos. Apagar uma disciplina preserva tarefas, avaliações e estudo sem associação.
- Novos testes de regras, abertura/migração/reabertura, estado persistido, XP, eliminação e exportação. Testes de widgets exercitam a criação de aula/avaliação/estudo, pausa/retoma/conclusão em 360×800 e conflitos na agenda.
- O fim do foco não emite alarme em segundo plano. Recuperação testada em SQLite e widgets; suspensão/reabertura do processo Android ainda por testar num dispositivo.

## Verificação efectuada no ambiente
- `flutter pub get`: concluído, lockfile gerado e dependências instaladas.
- `dart format lib test`: executado.
- `flutter analyze`: sem problemas na verificação final concluída.
- `flutter test --reporter expanded`: **31 testes aprovados**, incluindo o fluxo de widget meta → tarefa associada → agendamento → conclusão → XP, recusa de versão futura da base, persistência em ficheiro após reabertura, hábitos, relações, dinheiro e recorrência.
- `python3 tool/check_schema.py`: SQL, relações, unicidade, centavos e reabertura aprovados.
- `flutter build apk --debug`: **aprovado**; APK em `build/app/outputs/flutter-apk/app-debug.apk` (149.5 MiB), Tudo Aki 0.3.0, Android 7.0+ (API 24), target API 36, ARM64/ARMv7/x86-64.
- `apksigner verify --verbose`: assinatura de depuração v2 verificada. O APK apresenta o nome Tudo Aki, uma única actividade no launcher e os ícones novos, mantendo o ID de instalação anterior. `aapt dump badging` confirmou identidade, versões, permissões e arquitecturas.
- SHA-256 do APK: `422b5e22ac1a226d7efe9c8b960eec2ff3e278cd70732fa49d43dd53cb1bbce6`.

## Ambiente e reprodução
`tool/setup.sh` fixa o Flutter por commit oficial e o Temurin JDK 21.0.13+9 por SHA-256, instala dependências com lockfile, prepara SQLite de testes e as ferramentas Android. `tool/env.sh` activa os caminhos. `tool/setup_android.sh` usa o checksum oficial da CLI e configura o proxy Java sem copiar credenciais. SDKs/caches ficam em `/workspace/.tools`, fora do repositório da aplicação. A instalação foi repetida com sucesso, com o lockfile respeitado. `install_script`, `start_skill` e o domínio `storage.googleapis.com` foram guardados no rascunho; isso não publica o ambiente.

A primeira tentativa de download do catálogo Flutter teve 403 e depois 404; a instalação pelo Git oficial funcionou. A ligação `libsqlite3.so` em `.tools/native` usa a biblioteca do sistema já existente. As pastas de estado Dart/Flutter/analisador/adb no directório pessoal precisaram de permissões de escrita específicas. O Gradle precisou de propriedades explícitas para usar o proxy do ambiente. O Java original não fornecia o compilador exigido pelo Gradle; foi instalado um JDK completo. O Temurin usa o repositório de certificados Java do sistema para confiar no proxy, com TLS verificado; o sdkmanager recebe os parâmetros de proxy explicitamente. Foram identificadas as APIs Android 34, 35 e 36, o NDK 27 e o CMake 3.22.1 exigidos pela aplicação/plugins. Nenhuma verificação TLS ou de pacotes foi desactivada.

## Pendências e limites
O MVP **ainda não está certificado num dispositivo Android**. Falta testar a entrega de lembretes e a persistência no ciclo de fecho/reabertura do processo Android; o teste existente valida SQLite em Linux. Sem dispositivo ligado e sem `/dev/kvm` neste ambiente.

Fases posteriores: edição de uma ocorrência isolada e excepções de recorrência; eventos que atravessam vários dias e conflitos com blocos de tarefas; categorias configuráveis; orçamentos e despesas recorrentes; moeda configurável; conquistas com catálogo; WOOP guiado; interesses no onboarding; backup/importação; suporte a outros fusos/DST e plataformas; verificação de acessibilidade em dispositivo.

O catálogo de conquistas continua sem interface; as etapas de metas e as sessões de estudo já dispõem de interface funcional. A grelha mensal avançada e os gráficos não fazem parte desta fundação. Não há analytics, conta, backend, sincronização bancária ou encriptação implementada.

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
