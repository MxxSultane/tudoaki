# Fase 4A — correcções de UX e APK de testes

## Origem e âmbito

Origem: branch `qa/fase-3f-integracao`, HEAD **d8cf8813f5061675544e28cd2543bdac99f2520d**, árvore limpa. Antes de alterar código confirmou-se a CI desse SHA: [Flutter validation 42983443127](https://github.com/MxxSultane/tudoaki/actions/runs/42983443127) e [Android debug validation 42983443170](https://github.com/MxxSultane/tudoaki/actions/runs/42983443170), ambas COMPLETED/SUCCESS. Branch isolado: `fix/fase-4a-ux-android`.

Consultados AGENTS.md, DESIGN_SYSTEM.md, PHASE3F_REPORT.md e contratos anteriores de Hoje/Planear/criação rápida. Inspeccionadas as capturas originais. O pedido 4A autoriza apenas estas duas correcções e o APK debug interno; não autoriza a Fase 4B.

## Causas e correcções

**Hoje:** o FAB do Scaffold era sobreposto à lista inteira. Padding no fim da lista permite chegar ao último item, mas não impede que acções intermédias passem atrás do botão. O «+» passa a integrar o cabeçalho existente de Hoje; na consulta de calendário fica ao lado de Voltar a Hoje. É um elemento com espaço próprio no layout, que se desloca com o cabeçalho em vez de flutuar sobre as linhas. O atalho Adicionar tarefa, o selector Evento/Tarefa/Meta, a data contextual e o guard permanecem. Durante modais, o botão é removido (não apenas transparente), mantendo uma caixa de 56×56 para estabilizar o cabeçalho e preservar as expectativas antigas de protecção. O padding compensatório antigo de 112 dp passa a 24 dp. Não há nova faixa fixa nem perda de altura permanente da lista; SafeArea/barra/teclado continuam geridos pelo shell. O botão do cabeçalho não participa em Hero (`heroTag: null`), evitando a colisão com os FABs dos outros ramos retidos no indexedStack, detectada pelo teste de aplicação existente. Os outros destinos conservam a composição anterior.

**Criação rápida:** o corte observado não era necessariamente um overflow intrínseco do texto. O teste inicial que apenas verificava `didExceedMaxLines` e fazia scroll passava também na base antiga; não detectava o corte do primeiro viewport com teclado. As acções estavam na mesma superfície deslocável que todos os campos. Agora existe um rodapé de acções separado dos campos: a legenda secundária permite até três linhas, centradas, com alvo mínimo 48×48 e padding vertical. A acção principal mantém a hierarquia preenchida. Em largura a partir de 600 dp os botões dispõem-se lado a lado. Em janelas excepcionalmente baixas, incluindo transições de teclado/fecho, todo o conteúdo pode deslocar-se numa única superfície, evitando overflow; o limiar acompanha a escala de texto e a largura. Guardar e Guardar e adicionar outra continuam a chamar exactamente as mesmas operações, sem alterar validação, persistência ou retorno.

Uma tentativa inicial de faixa fixa em Hoje foi rejeitada: reduzia o viewport de calendário e fazia falhar um teste antigo de visibilidade de compromisso. O cabeçalho integrado preserva esse teste. Durante a implementação a matriz detectou overflow transitório no fecho em horizontal; foi corrigido com essa adaptação de altura. Uma verificação inicial de limites por selecção incluía espaços finais de linha, que podem ultrapassar a largura do parágrafo; o teste final verifica as caixas das palavras visíveis, sem enfraquecer o critério de texto integral.

## Ficheiros alterados

- `lib/app/app.dart`: injecção da acção no cabeçalho apenas em Hoje; mesma criação/guard.
- `lib/features/agenda/presentation/today_screen.dart`: coloca a acção no cabeçalho/linha de regresso e retira o padding compensatório antigo.
- `lib/features/tasks/presentation/quick_task_sheet.dart`: organização responsiva de campos/acções, sem alterar lógica de gravação.
- `test/phase4a_responsive_test.dart`: 60 casos de regressão com SQLite em memória e dados sintéticos.
- `tool/capture_quality.dart`: destino de saída configurável e opção de mostrar a acção de hábitos por scroll; comportamento por defeito anterior preservado.
- `.github/workflows/flutter-validation.yml`: acrescenta o branch, sem remover verificações.
- `.github/workflows/android-debug-validation.yml`: acrescenta o branch e disponibilização opcional do APK de testes no workflow existente.
- `docs/ux/previews/phase4a/` e este relatório: evidência real e entrega.

Não se alteraram SQLite v5, lifeos.sqlite, TaskOperations, dependências/lockfile, XP, notificações, finanças, identificador Android, assinatura de produção, navegação principal, Metas ou módulos antigos. Não há migrações, restauro ou novos serviços. Não foram modificados testes anteriores.

## Capturas reais antes/depois

PNG produzidos pelo renderer Flutter, com as mesmas fixtures/relógio dos diagnósticos 3F; não são imagens artificiais. Os ficheiros históricos não foram sobrescritos.

| Estado | Antes (3F) | Depois (4A) |
| --- | --- | --- |
| Hoje preenchido claro, 390×844 | [Antes](ux/previews/phase3f/hoje-filled-light.png) | [Depois](ux/previews/phase4a/hoje-filled-light.png) |
| Hoje preenchido escuro | [Antes](ux/previews/phase3f/hoje-filled-dark.png) | [Depois](ux/previews/phase4a/hoje-filled-dark.png) |
| Folha/teclado/200%, claro, 360×800 | [Antes](ux/previews/phase3f/quick-keyboard-200-light.png) | [Depois](ux/previews/phase4a/quick-keyboard-200-light.png) |
| Folha/teclado/200%, escuro | [Antes](ux/previews/phase3f/quick-keyboard-200-dark.png) | [Depois](ux/previews/phase4a/quick-keyboard-200-dark.png) |

Hoje mantém a deslocação: «Ver hábitos» pode ficar abaixo do primeiro viewport consoante o conteúdo, mas deixa de poder passar atrás do FAB. As imagens adicionais em `phase4a/habits/` mostram a acção depois de deslocar a lista, nos dois temas. Os testes verificam a sua posição e abertura real.

Reprodução:

```bash
source tool/env.sh
flutter test --no-pub tool/capture_quality.dart --dart-define=QUALITY_OUTPUT=docs/ux/previews/phase4a --name 'hoje-filled-light|hoje-filled-dark|quick-keyboard-200-light|quick-keyboard-200-dark'
flutter test --no-pub tool/capture_quality.dart --dart-define=QUALITY_OUTPUT=docs/ux/previews/phase4a/habits --dart-define=QUALITY_SCROLL_HABITS=true --name 'hoje-filled-light|hoje-filled-dark'
```

## Testes e validação local

Flutter **3.35.7**, revisão adc901062556672b4138e18a4dc62a4be8f4b3c2; Dart **3.9.2**. SDK já preparado, sem instalar/actualizar pacotes.

60 novos casos: 36 para Hoje (320/360/390 dp × escala 100/200% × claro/escuro × 0/2/30 tarefas) e 24 para a folha (as mesmas larguras/escalas/temas × vertical/horizontal). Há SafeArea simulada, barra inferior e teclado de 280 dp em vertical/100 em horizontal. Verificam acção no cabeçalho, ausência de sobreposição com Ver hábitos e separação da barra, acesso e abertura de Hábitos, selector global de criação, legenda integral no viewport vertical antes de scroll, limites das palavras, alvo táctil, guardar outra, guardar/fechar e cancelamento sem nova escrita. Lembretes usam o fake de plataforma existente; as operações de tarefas e SQLite em memória são reais.

A primeira solução só de quebra de linha não detectava/resolvia o corte de viewport; foi substituída pelo rodapé adaptável. As falhas intermédias da nova matriz não foram escondidas nem aceites como resultado final. O teste geométrico de Hoje falhou ao executar contra o layout antigo. **Validação local final: 247 executados, 247 aprovados, 0 falhados, 0 ignorados e 0 erros de execução** (187 anteriores intactos + 60 novos), código 0 no runner e no processador. `flutter analyze --no-pub`: código 0, No issues found. Formatação: código 0, 96 ficheiros, 0 alterações. Seis capturas finais: 4+2 casos de renderização aprovados; não são somados aos 247 testes. Os nove testes existentes do processador Python passaram; YAML/bash/diff e comparação das áreas protegidas passaram. Logs finais: `/workspace/4a-complete*`.

Comandos: `dart format --output=none --set-exit-if-changed lib test tool/capture_quality.dart`, `flutter analyze --no-pub`, `flutter test --no-pub --machine`, processador de resultados existente; YAML e `bash -n` nos workflows; comparação das áreas protegidas e `git diff --check`. Logs completos locais em `/workspace/4a-*.log`/JSONL.

## APK interno e GitHub Actions

Reutiliza-se **Android debug validation**, com Flutter/Dart/Java/SDK/NDK e Gradle documentados. Compila `flutter build apk --debug --no-pub`, exige `test -s` no APK e preservação de pubspec/lockfile/android. Permissões permanecem **contents: read**. Não há Google Play, release, mudança de assinatura de produção, segredos, credenciais ou serviços externos.

Modo preferido: `workflow_dispatch` com o input booleano **disponibilizar_apk=true**, por defeito falso. O APK só é carregado depois de sucesso do build e da verificação de preservação. Retenção: **7 dias**. Nome: **tudo-aki-debug-<SHA completo>**, contendo `app-debug.apk` num ZIP do GitHub.

Limitação confirmada: o workflow Android ainda não existe em main (ficheiro remoto HTTP 404); sem integração aprovada, o botão Run workflow pode não aparecer. Além disso, a API GitHub respondeu Forbidden neste ambiente. Para disponibilizar já esta entrega sem fazer merge, existe uma alternativa explícita: apenas um push neste branch cujo commit final contenha **[apk-testes]** solicita o artefacto. Pushes normais continuam a compilar e a guardar só logs. A entrega usa essa opção; não é publicação geral a cada commit. Não se alteraram os critérios de falha.

Resultados separados de Flutter validation e Android debug validation, execução e identificação concreta do artefacto: a registar após execução observada. Não se declara aprovação remota antes disso.

### Como obter e testar

1. Iniciar sessão no GitHub e abrir Tudoaki → **Actions → Android debug validation**.
2. Abrir a execução aprovada do branch `fix/fase-4a-ux-android` indicada na entrega.
3. Em **Artifacts**, descarregar **tudo-aki-debug-<SHA>** e extrair o ZIP. O ficheiro a instalar é `app-debug.apk`.
4. Usar preferencialmente um emulador ou telefone/perfil de testes. Permitir a instalação dessa origem quando o Android a solicitar.
5. Exercitar Hoje vazio/preenchido/muitas tarefas, deslocar até Ver hábitos, abrir/cancelar criação, guardar e guardar outra, teclado, rotação, tema escuro e tamanho de letra máximo.

Quando o workflow estiver registado no branch predefinido por integração revista, também será possível usar **Run workflow**, escolher o branch e activar o input, sem criar commits. Não se efectuou essa integração automaticamente.

Um artefacto num repositório público não constitui um canal privado de acesso; não contém dados de utilizadores nem credenciais. Destina-se exclusivamente à avaliação interna e não é uma versão pública pronta para distribuição.

## Limitações, dados e recomendação

Sem Android SDK/emulador/dispositivo local acessível: o build será verificado no runner. Não foram executados testes físicos, TalkBack, IME/gestos nativos, entrega de notificações ou instalação/actualização por cima da aplicação anterior. O teclado e as áreas seguras dos testes são simulações Flutter. As capturas são representativas, não uma certificação de todos os telefones.

O APK debug de um runner pode ter uma chave debug diferente da instalação existente. Se o Android recusar actualizar por assinatura incompatível, **não desinstalar uma app com dados para contornar o erro**: usar um ambiente de testes separado. Não há restauro/importação nesta entrega. Os riscos conhecidos de datas, concorrência e backup continuam documentados em 3F, sem correcções alheias.

Recomenda-se a primeira ronda Android num ambiente separado, confirmando as duas correcções e os fluxos existentes; a autorização de distribuição/actualização de utilizadores exige validação adicional. Sem merge automático e sem início da Fase 4B.
