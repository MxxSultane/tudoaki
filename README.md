# LifeOS
Gestão pessoal offline em Flutter: Hoje, Agenda, Metas, Progresso e Perfil. Interface em português, tema claro/escuro, Drift/SQLite e nenhuma conta obrigatória.

## Estado
APK de depuração compilado: `build/app/outputs/flutter-apk/app-debug.apk` (Android 7.0+). Análise sem problemas e 13 testes aprovados. Lembretes e comportamento num dispositivo real ainda não certificados.

Consulte [docs/PROGRESS.md](docs/PROGRESS.md) para separar implementação, verificações e funcionalidades pendentes. O código não contém dados de demonstração nem credenciais.

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
