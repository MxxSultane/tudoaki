# Fase 1.1 — ambiente e validação

## Base inspeccionada
Branch prep/tudo-aki-2-fase-1, commit bb85104850e4d5644d8e3124495179280ab88666, árvore limpa antes da preparação. Lidos AGENTS.md, README.md, tool/setup.sh, tool/setup_jdk.sh, tool/setup_android.sh, tool/env.sh, pubspec.yaml e lockfile. Nenhuma funcionalidade 2.0 implementada.

## Ferramentas
- Flutter: fontes oficiais 3.35.7 obtidas por Git, revisão adc901062556672b4138e18a4dc62a4be8f4b3c2 conferida. Não operacional: bootstrap não conseguiu obter o Dart.
- Dart esperado: 3.9.2, fornecido pelo Flutter 3.35.7. Não instalado/executado; não é uma versão validada localmente.
- Java inicial: OpenJDK Runtime 21.0.12.1; javac não encontrado.
- JDK preparado: Eclipse Temurin 21.0.13+9, java e javac 21.0.13 executados. Download oficial verificado pelo SHA-256 já definido em tool/setup_jdk.sh.
- Android SDK, NDK e CMake: não disponíveis nos caminhos documentados. Setup interrompido antes dessa etapa. Build não tentado, conforme a condição de disponibilidade do SDK.
- Ligação libsqlite3.so preparada em /workspace/.tools/native, apontando para a biblioteca do sistema, conforme o script existente.

## Causa concreta do bloqueio
bash tool/setup.sh obteve Flutter e JDK, mas parou no primeiro arranque Flutter. O proxy rejeitou o túnel HTTPS para storage.googleapis.com com HTTP 403 (curl 56). O download necessário era flutter_infra_release/flutter/035316565ad77281a75305515e4682e6c4c6f7ca/dart-sdk-linux-x64.zip. TLS não foi desactivado e não foi usado um mirror não verificado. Uma sondagem HTTPS ao mesmo domínio confirmou o bloqueio.

Depois de carregar tool/env.sh, os comandos pedidos foram tentados individualmente. Todos os executáveis Flutter/Dart pararam no mesmo bootstrap; portanto não há diagnóstico de compilação ou análise do código decorrente destas tentativas. O erro secundário return do script interno do Flutter surge após a recusa de rede e não é um erro da aplicação.

## Resultados locais
| Comando | Resultado |
| --- | --- |
| bash tool/setup.sh | Falhou, código 1; download Dart bloqueado por HTTP 403 |
| flutter --version | Código 1; bootstrap bloqueado |
| flutter pub get | Código 1; bootstrap bloqueado; resolução não iniciada |
| dart format --output=none --set-exit-if-changed lib test | Código 1; formatter não arrancou |
| flutter analyze | Código 1; analisador não arrancou |
| flutter test | Código 1; runner não arrancou |
| flutter build apk --debug | Não executado: SDK Android ausente e Flutter não operacional |
| git diff --check | Aprovado; verificação de espaços Git, não formatação Dart |

**Testes executados: 0. Aprovados: 0. Falhados como casos de teste: 0.** A execução da suite falhou antes de carregar testes. Os 80 casos antigos e os seis casos novos continuam sem revalidação nesta fase. Não interpretar zero casos falhados como suite aprovada. Não foi gerado APK.

Logs completos: [setup](validation/phase11/setup.txt), [versão](validation/phase11/version.txt), [pub get](validation/phase11/pub-get.txt), [formatação](validation/phase11/format.txt), [análise](validation/phase11/analyze.txt), [testes](validation/phase11/test.txt), [códigos de saída](validation/phase11/results.json).

## Dependências e código preservados
Versões resolvidas inspeccionadas: Riverpod 2.6.1, flutter_bloc 9.1.1, GoRouter 16.3.0, Drift 2.31.0, sqlite3_flutter_libs 0.5.42, flutter_local_notifications 19.5.0 e google_fonts 6.3.3. Não se efectuou actualização de pacotes.

SHA-256 antes/depois:
- pubspec.yaml: c7d73e08bf2296d3faba94b7697f3f5309c5c91d9fd8240ce9ef4879ddc0fe19
- pubspec.lock: 23ed8d6cbd75540a9cb82eaff5a0012eb24b40f823a7696f825a655ae4de833c

Não foram corrigidos testes por suposição, nem alterados testes antigos, lib/, android/, assets/, tool/, esquema v5 ou regras de produção. Nenhuma base de dispositivo aberta.

## Alternativa reproduzível: GitHub Actions
Workflow .github/workflows/flutter-validation.yml em Ubuntu 24.04, com Flutter 3.35.7 por revisão exacta e confirmação Dart 3.9.2. Instala biblioteca SQLite de testes, usa pub get --enforce-lockfile e verifica que os manifests não mudaram. Executa formatação, análise e testes, mesmo quando um desses três passos falha, agregando os códigos de saída para não ocultar falhas. Guarda logs e contagens; não publica APK, não distribui nem faz deploy. Não usa scripts cloud com caminhos /workspace no runner.

Disparos: push em main ou no branch de preparação, pull_request e execução manual. O workflow faz apenas análise/testes, sem build Android. Abrir o separador Actions do repositório e seleccionar Flutter validation; o push deste branch também pode disparar uma execução se Actions estiver autorizado no repositório.

**Workflow ainda não validado por execução observada.** A tentativa de consulta remota com gh falhou: credencial GH_TOKEN inválida e API GraphQL Forbidden. Não foi substituída nem exposta a credencial. Não há contagens remotas confirmadas ou afirmação de CI verde. A execução requer acesso do runner a GitHub, storage.googleapis.com e pub.dev, e Actions habilitado no repositório.

## Ficheiros alterados e verificações locais
Modificados: README.md e docs/PROGRESS.md.
Novos: .github/workflows/flutter-validation.yml, docs/PHASE11_REPORT.md e sete logs em docs/validation/phase11: setup.txt, version.txt, pub-get.txt, format.txt, analyze.txt, test.txt, results.json.

YAML analisado com PyYAML, scripts run verificados com bash -n e sintaxe Python embutida verificada com ast.parse. Estas verificações não executam Actions nem substituem Dart/Flutter. git diff --check aprovado. Comparação contra bb85104 confirma ausência de alterações em lib/, android/, assets/, test/, tool/ e manifests de dependências.

## Recomendação
Não avançar ainda para a Fase 2. Primeiro obter uma execução verde do workflow, corrigir apenas os novos testes se houver erros comprovados e executar o APK num ambiente Android preparado. Se surgir defeito de produção, registar ficheiro, causa e proposta para aprovação antes de o corrigir. Permanecem os problemas conhecidos da auditoria; não foram reproduzidos nem alterados nesta fase. Validação física, restauro e comportamento noutros fusos continuam pendentes.
