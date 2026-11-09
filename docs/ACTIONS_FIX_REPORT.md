# Correcção de Flutter validation — Fase 1

Base: e514553, branch prep/tudo-aki-2-fase-1. Não inicia a Fase 2.

## Formatação
Os três testes indicados tinham disposição de argumentos, indentação e vírgulas finais que não correspondiam ao formatador Dart. Foi executado o formatador oficial Dart SDK 3.9.2 apenas em:
- test/phase1_task_flows_test.dart
- test/phase1_v5_characterization_test.dart
- test/weekly_planner_widget_test.dart

Uma segunda passagem com --output=none --set-exit-if-changed terminou com código 0 e 3 ficheiros sem alterações. Verificação global, sem escrita, de lib e test: código 0, 60 ficheiros, 0 alterações. Comparação lexical confirmou tokens preservados, ignorando espaços, comentários e vírgulas finais opcionais; sem mudanças de lógica ou critérios.

O proxy continuou a bloquear storage.googleapis.com com 403. Foi obtido o SDK da imagem oficial Docker Hub library/dart:3.9.2-sdk para linux/amd64, sem executar o contentor. Manifest: sha256:3e66cf04d5ede710f73734d83c49fe5f598729f668c4405e182642be071633d0; camada SDK: sha256:19e8b7557068bfac0eba4dd938e4106f62ce53b7dfe00f994ef29ee540375007. Digest da camada validado antes da extracção. dart --version confirmou 3.9.2 stable. O CLI precisou de execução fora do sandbox para criar a configuração .dart-tool; a concessão de escrita isolada não resolveu o sistema de ficheiros só de leitura.

O formatador avisou que package:flutter_lints/flutter.yaml não estava resolvido, por faltarem dependências locais. Conseguiu analisar e formatar os ficheiros, e a verificação terminou com código 0. Isto não equivale a flutter analyze. **Não foram executados flutter test ou flutter analyze localmente nesta correcção.** Os resultados anteriores do Actions foram comunicados pelo utilizador, não reobservados aqui.

## Causa do AttributeError
O Python embutido chamava event.get imediatamente depois de json.loads. JSON válido não é necessariamente um dicionário: uma lista provoca exactamente o AttributeError reportado. Não foi disponibilizado o conteúdo bruto dessa linha, pelo que não se atribui um conteúdo específico à lista observada.

O processamento foi extraído para tool/summarize_flutter_tests.py e chamado pelo workflow. Aceita stream JSON-lines ou documento objecto/lista; listas são percorridas, dicionários de eventos são validados antes de aceder aos campos, e valores informativos são registados como diagnósticos. Payloads malformados de eventos reconhecidos são problemas de protocolo, não casos de teste inventados.

Conta conclusões visíveis por testID, sem duplicação, excluindo loaders hidden. Ignorados são apresentados separadamente dos executados. Falhas de casos provêm de testDone; eventos error associados a carregamento/runner ou sem conclusão válida são erros de execução. Exige conclusão final done, pelo menos um teste executado e consistência dos resultados. Suite vazia, só ignorados, truncada ou runner com erro não recebe sucesso.

Não há captura genérica de excepções. JSONDecodeError é tratado apenas para distinguir documentos/linhas e diagnósticos; erros de ficheiro ou programação continuam a falhar. Saída do resumo: 0 para sucesso validado; 1 para casos falhados; 2 para ausência/inconsistência/erro de execução. Códigos reais de format/analyze/test/lock continuam capturados sem substituição e summary é acrescentado a exit-codes.txt. O passo agrega qualquer código não zero em falha do job.

## Validação local
- YAML analisado com PyYAML; scripts run verificados com bash -n; Python verificado com ast.parse.
- python3 -m unittest discover -s tool -p 'test_summarize_flutter_tests.py' -v: **9 aprovados, 0 falhados**.
- Quatro simulações do passo shell (com comandos substitutos, sem Flutter): tudo aprovado; format=1/test=0; test=9; ausência de testes com test=0. Resultados agregados e exit-codes.txt corresponderam aos códigos reais simulados. Nenhuma execução vazia passou.
- Formatação oficial dos três ficheiros e verificação global lib/test aprovadas.
- git diff --check aprovado.
- pubspec.lock preservado: SHA-256 23ed8d6cbd75540a9cb82eaff5a0012eb24b40f823a7696f825a655ae4de833c.
- pubspec.yaml, lib/, android/, esquema SQLite, regras de XP e funcionalidades inalterados.

## Ficheiros da correcção
.github/workflows/flutter-validation.yml; os três testes Dart acima; tool/summarize_flutter_tests.py; tool/test_summarize_flutter_tests.py; docs/ACTIONS_FIX_REPORT.md.

O workflow passa a executar os nove testes Python antes da validação Flutter. Nova execução GitHub Actions pendente após o push. Não se declara CI verde, nem um número de testes Flutter aprovados nesta correcção. A aprovação para avançar continua com o utilizador.
