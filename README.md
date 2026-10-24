# Tudo Aki

**A tua vida, organizada num só lugar.**

Identificador Flutter/Dart: `tudo_aki`.

Gestão pessoal offline em Flutter: Hoje, Agenda, Metas, Progresso e Perfil. Interface em português, tema claro/escuro, Drift/SQLite e nenhuma conta obrigatória.

## Estado
APK de depuração compilado: `build/app/outputs/flutter-apk/app-debug.apk` (Android 7.0+). Análise sem problemas e 45 testes aprovados. Lembretes e comportamento num dispositivo real ainda não certificados.

Consulte [docs/PROGRESS.md](docs/PROGRESS.md) para separar implementação, verificações e funcionalidades pendentes. O código não contém dados de demonstração nem credenciais.

## Fase actual
Organização pessoal/académica da Fase 3 implementada no escopo actual; área financeira da Fase 4 consolidada com orçamentos e recorrências. Moeda configurável, conquistas e gráficos ainda estão pendentes, assim como a validação real da Fase 6. A fundação está concluída; lembretes e utilização real em Android continuam por validar. O estado de cada fase consta em `docs/PROGRESS.md`.

## Novidades da versão 0.4.0 — planeamento financeiro
Em **Perfil → Finanças**, escolha o mês e defina orçamentos por categoria. As despesas registadas actualizam o valor utilizado e o restante; receitas e contribuições de poupança não são contadas como despesas. Categorias ignoram diferenças de maiúsculas e espaços. Pode editar a data dos movimentos, ajustar metas de poupança e registar contribuições directamente na meta.

Crie regras de receita/despesa semanal, mensal ou anual. **Rever vencimentos** apresenta datas e valores (até 24 por lote); só **Confirmar registo** cria os movimentos. Abrir a aplicação não cria entradas. Os fins de mês mantêm o dia de referência: 31 de Janeiro → último dia de Fevereiro → 31 de Março. Regras pausadas não geram registos; alterações aplicam-se apenas a movimentos ainda não criados. Depois de usar um calendário, encerre a regra e crie outra para mudar frequência ou data inicial.

A confirmação repetida não duplica movimentos. Eliminar um movimento não o recria na revisão seguinte; eliminar uma regra preserva os movimentos existentes. Os valores e limites são guardados em centavos inteiros; somas e formatação preservam os centavos mesmo para totais muito grandes. Os orçamentos são referências ajustáveis, sem integração bancária. A moeda continua MZN.

A base v1/v2/v3 é migrada para v4, preservando o estudo e os dados existentes. Não foram acrescentadas dependências.

## Novidades da versão 0.3.0 — organização académica
Em **Perfil → Estudos**, pode criar/editar disciplinas, horários de aulas semanais com período de validade e local, avaliações e sessões de estudo. A agenda reúne aulas, avaliações, estudo e eventos pessoais e sinaliza sobreposições. Os trabalhos continuam ligados às disciplinas pelas tarefas existentes.

O foco tem duração configurável de **1 a 180 minutos** (25 por defeito), pausa e retoma. O prazo UTC e o tempo restante são guardados em SQLite; ao voltar à aplicação, o contador é recuperado. Quando o tempo termina, confirme **Registar sessão concluída**. O histórico preserva os registos; a gamificação opcional reconhece 15 XP por sessão, até três por dia, sem duplicar recompensas.

A aplicação não emite um alarme de fim de foco em segundo plano. A recuperação foi testada em SQLite e widgets; suspensão/fecho e notificações no Android real ainda precisam de validação num dispositivo. A base v1/v2 é migrada para v3 sem apagar dados. Aulas editadas alteram o horário semanal dentro do período definido; sessões já iniciadas preservam o seu registo e não podem ser replaneadas.

## Novidades da versão 0.2.1 — identidade oficial
Nome público, título, onboarding e launcher: **Tudo Aki**. O slogan provisório é **A tua vida, organizada num só lugar.** O pacote Dart e o projecto Gradle chamam-se `tudo_aki`; o namespace Android é `mz.tudoaki.tudo_aki`. Ícones e arranque usam um visto branco com fundo verde-petróleo, incluindo ícone adaptativo e variante monocromática.

O ID de instalação Android `mz.lifeos.lifeos` e o ficheiro local `lifeos.sqlite` são mantidos apenas como identificadores internos de compatibilidade. Isso permite actualizar instalações anteriores e continuar a usar os seus dados. Não são nomes apresentados na interface. O repositório GitHub e a pasta de checkout continuam a ser `tudoaki`.

## Novidades da versão 0.2.0
- Crie submetas a partir de uma meta: anual → mensal → semanal.
- Abra **Plano desta meta** para consultar as submetas, gerir etapas com prazo e concluir tarefas associadas.
- Crie, edite, conclua/reabra e elimine etapas sem alterar automaticamente os resultados medidos.
- A base de dados v1 é migrada para v2, preservando os dados existentes. Eliminar uma meta preserva as suas submetas e tarefas; as etapas e o histórico dessa meta são eliminados mediante confirmação.

Se já clonou o projecto, execute `git pull` e `flutter pub get` e volte a executar a aplicação no Android Studio.

## Abrir no Android Studio
1. Instale o Flutter **3.35.7**, o Android Studio e os plugins **Flutter** e **Dart**. Configure o caminho do Flutter SDK no Android Studio.
2. Clone o projecto e obtenha as dependências:

```bash
git clone https://github.com/MxxSultane/tudoaki.git
cd tudoaki
flutter pub get
```

3. No Android Studio, escolha **Open** e abra a pasta `tudoaki`, que contém `pubspec.yaml`.
4. Use um JDK completo 21 para o Gradle. Instale pelo SDK Manager as APIs Android **34, 35 e 36**, Build Tools **35.0.0**, NDK **27.0.12077973** e CMake **3.22.1**. O Gradle também pode instalar componentes em falta após aceitar as respectivas licenças.
5. Inicie um emulador Android 7.0+ ou ligue um telefone com depuração USB. Seleccione o dispositivo, abra `lib/main.dart` e carregue em **Run**.

Também pode executar `flutter run` no terminal. O Android Studio/Flutter gera `android/local.properties` com os caminhos da sua máquina. Os scripts `tool/setup*.sh` e `tool/env.sh` são específicos do ambiente cloud em `/workspace`; não os execute na sua máquina local.

## Ambiente cloud
Flutter stable 3.35.7 (Dart 3.9), Temurin JDK 21.0.13+9 e Android SDK/NDK para APK/dispositivo (instalados pelo script). Sem backend, Firebase ou credenciais. O script usa o repositório oficial do Flutter, fixado por commit; o próprio Flutter obtém os seus artefactos oficiais. Não desactive verificações TLS ou de pacotes.

```bash
cd /workspace/tudoaki
bash tool/setup.sh
source tool/env.sh
flutter analyze
flutter test
```

Com um dispositivo Android ligado e autorizado:

```bash
flutter devices
flutter run -d <dispositivo-android>
flutter build apk --debug
```

`python3 tool/check_schema.py` é uma verificação suplementar de SQL. Não substitui testes Dart, widgets ou Android. Não execute `dart format .` durante onboarding sem rever alterações; para desenvolvimento, `dart format lib test` formata o código da aplicação.

## Estrutura
- `lib/app/`: tema, router e providers.
- `lib/core/database/`: esquema v1, persistência e regras transaccionais.
- `lib/core/notifications/`: lembretes Android, Africa/Maputo.
- `lib/features/`: ecrãs e formulários.
- `test/`: regras, SQLite e navegação.
- `docs/`: produto, arquitectura, plano e evidências.

## Privacidade e limites
A base é local e não é encriptada pela aplicação. Exportar abre a partilha do sistema; escolha um destino seguro. Apagar dados pede confirmação. Os lembretes dependem da permissão Android, são aproximados e usam o fuso de Maputo. Dados financeiros são guardados em centavos inteiros. Sem integração bancária.
