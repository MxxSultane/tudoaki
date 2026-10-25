# tudoAki

**A tua vida, organizada num só lugar.**

Aplicação Flutter offline para agenda, metas, tarefas e áreas pessoais. Identificador técnico: `tudo_aki`. Temas claro/escuro, Inter e Newsreader locais, cartões planos e três separadores.

## Versão 0.9.0 — planeamento semanal
A nova interface está ligada à base de dados real. Não há listas de demonstração na aplicação. Os dados guardados nas versões anteriores são recuperados automaticamente.

| Entrada | O que permite fazer |
| --- | --- |
| **Agenda** | Consultar dias, semanas e meses em lista; seleccionar datas; criar/editar eventos e recorrências; ver tarefas, aulas, avaliações e estudo por ordem cronológica, com conflitos sinalizados. |
| **Metas** | Criar/editar metas anuais, trimestrais, mensais e semanais; abrir detalhes; criar submetas, etapas e acções; registar resultados e consultar o histórico. |
| **Tarefas** | Criar, editar, programar, concluir e reabrir tarefas; filtrar pendentes/concluídas; associar metas e disciplinas; definir prioridade, importância e lembrete. |

O **+** abre **Evento / Tarefa / Meta**, com formulários reais. “Mais opções” revela os campos avançados. Ao guardar, a app mostra a área correspondente; um novo evento abre no dia escolhido e uma nova tarefa fica visível em Pendentes.

Em **Agenda → O meu dia**, consulte o próximo compromisso, três prioridades (incluindo tarefas em atraso), rotinas e metas. O painel começa recolhido para manter a agenda calma. As tarefas organizam acções; o resultado de uma meta continua a ser registado separadamente.

## Planear semana
Em **Mais → Planear semana**, organiza a semana num ecrã próprio:

1. Escolhe **Tarefas** ou **Eventos** no topo e toca num dos sete dias.
2. Usa **Adicionar tarefa** ou **Adicionar evento**. As tarefas precisam apenas de título e dia; **Definir hora** é opcional. Os eventos começam com uma hora de duração, ajustável no formulário.
3. Toca em **Guardar**. O registo fica imediatamente na agenda e o planeador mostra o dia escolhido.

Ao domingo, a abertura sugere a semana seguinte (segunda a domingo). Nos restantes dias, abre a semana actual. As setas e a data permitem consultar outras semanas. Os compromissos e tarefas existentes, incluindo aulas e estudo, aparecem no seu dia.

**Escolher pendente** permite programar uma tarefa ainda sem data, preservando o seu registo e associações. Tocar num item permite editar; eventos recorrentes indicam que a alteração abrange a série. Tarefas sem hora aparecem como **Sem hora**, sem gerar falsos conflitos à meia-noite. A funcionalidade está sempre disponível, sem alertas automáticos ao domingo.

## Mais áreas
A acção discreta **Mais**, nos três separadores, abre o planeador semanal e:

- **Hábitos:** frequência, plano quando/então, registo diário, pausa e bem-estar.
- **Estudos:** disciplinas, horários, avaliações, trabalhos e foco com pausa/retoma persistidas.
- **Finanças:** receitas/despesas, poupanças, orçamentos e recorrências confirmadas manualmente; MZN/USD/EUR/ZAR separados, com valores exactos.
- **Progresso:** XP opcional, níveis, quatro conquistas e gráfico semanal com unidades legíveis.
- **Revisões:** reflexões semanais e mensais guardadas localmente.
- **Definições:** tema, moeda, gamificação, exportação JSON e eliminação confirmada de dados.

Estas áreas abrem em páginas de detalhe com botão Voltar, sem acrescentar separadores nem repetir o botão +. As acções secundárias são discretas. O esquema v5, o ID Android de instalação e o ficheiro SQLite foram mantidos para preservar dados.

## Pacotes
Sem novos pacotes em 0.9.0.

- Acrescentado em 0.8.0: `flutter_bloc` **9.1.1**, para Cubits de selecção da agenda e filtros de metas/tarefas, conforme o guia. Riverpod mantém os repositórios e snapshots partilhados já existentes.
- `google_fonts` **6.3.3**, acrescentado em 0.7.0, usa Inter e Newsreader incluídas no APK. Sem pedidos de fontes durante a utilização; licenças OFL em `assets/fonts/`.

## Abrir no Android Studio
Instale Flutter **3.35.7**, os plugins Flutter/Dart e um JDK completo **21**. Abra a pasta que contém `pubspec.yaml`.

```bash
git pull --ff-only origin main
flutter pub get
flutter run -t lib/main.dart
```

Pare a execução anterior antes de iniciar de novo. Não desinstale a app nem apague os dados para actualizar.

Se o Git bloquear a actualização apenas por alterações locais em `pubspec.lock`, guarde-as primeiro:

```bash
git stash push -m "pubspec.lock local" -- pubspec.lock
git pull --ff-only origin main
flutter pub get
```

O SDK Manager deve disponibilizar APIs **34, 35 e 36**, Build Tools **35.0.0**, NDK **27.0.12077973** e CMake **3.22.1**. Android mínimo: **7.0**. O Gradle pode instalar componentes em falta depois de aceitar as licenças. `android/local.properties` é gerado com os caminhos locais.

Os scripts `tool/setup*.sh` e `tool/env.sh` são específicos do ambiente cloud em `/workspace`; não os execute na sua máquina local. A plataforma iOS não foi criada ou validada nesta entrega.

## Verificação e limites
```bash
flutter analyze
flutter test
flutter build apk --debug
```

**Verificado nesta versão:** 69 testes aprovados, análise sem problemas e APK debug compilado com assinatura verificada.

Os testes cobrem dados, migrações e fluxos reais da interface, incluindo reabrir um ficheiro SQLite com meta/tarefa/evento e recuperar o progresso. Os temas são verificados em 360 px com texto até 200%.

Notificações e suspensão/fecho do processo ainda precisam de validação num dispositivo Android real. O foco não emite alarme de fim em segundo plano. A agenda mensal é uma lista; excepções de recorrência, categorias de calendário, WOOP guiado, interesses no onboarding e backup/importação continuam no plano. A aplicação não implementa encriptação, bancos, backend ou analytics. Consulte [docs/PROGRESS.md](docs/PROGRESS.md).
