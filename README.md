# tudoAki

Esqueleto visual Flutter conforme o [AGENTS.md](AGENTS.md) fornecido: uma interface calma, com espaço em branco, sem gradientes e sem sombras fortes. Identificador técnico: `tudo_aki`.

## Entrega actual — 0.7.0
- Temas claro e escuro automáticos pelo sistema, com a paleta do guia.
- Inter para interface e Newsreader para títulos grandes; fontes incluídas localmente, sem pedidos de rede durante a utilização.
- Exactamente três separadores: **Agenda**, **Metas**, **Tarefas**.
- Agenda abre em **Hoje**, com uma semana e três entradas estáticas de exemplo, explicitamente identificadas como exemplo.
- Um único botão principal, **+**, abre a folha **Evento / Tarefa / Meta**. Tocar numa opção fecha a folha; não há formulários ou criação de dados nesta entrega.
- Metas e Tarefas têm apenas títulos e estados vazios. Não há onboarding, filtros, detalhes ou outras áreas na navegação actual.

O código de versões anteriores permanece no repositório, mas não está ligado à entrada actual da aplicação. O esqueleto não abre nem altera a base de dados existente. Os documentos de fases anteriores são um registo histórico, não o âmbito desta entrega.

## Pacotes adicionados
- `google_fonts` **6.3.3**: aplicar Inter e Newsreader conforme o guia. Descarregamento em execução desactivado; os ficheiros TTF e as licenças SIL OFL estão em `assets/fonts/`.

Não foram acrescentados outros pacotes. O GoRouter já existente gere os três destinos. Os ecrãs são estáticos e não requerem Cubits ou novas camadas de dados/domínio nesta entrega. Os logótipos fornecidos estão em `assets/logo/`; não foi acrescentado um pacote de SVG ou de geração de ícones.

## Estrutura do esqueleto
- `lib/core/theme/`: cores, tipografia e temas.
- `lib/core/widgets/skeleton_page.dart`: margens e listas agrupadas.
- `lib/features/{agenda,goals,tasks}/presentation/`: os três ecrãs.
- `lib/app/app.dart`: navegação e folha inferior.

## Abrir no Android Studio
Instale Flutter **3.35.7**, os plugins Flutter/Dart e um JDK completo **21**. Abra a pasta do projecto que contém `pubspec.yaml`.

```bash
git pull
flutter pub get
flutter run
```

Pare e volte a executar a aplicação após actualizar. O Android Studio gera `android/local.properties` com os caminhos locais. O SDK Manager deve disponibilizar APIs **34, 35 e 36**, Build Tools **35.0.0**, NDK **27.0.12077973** e CMake **3.22.1**; o Gradle pode instalar componentes em falta depois de aceitar as licenças. Android mínimo: **7.0**.

Os scripts `tool/setup*.sh` e `tool/env.sh` são específicos do ambiente cloud em `/workspace`; não os execute na sua máquina local. O projecto Android existente foi preservado; não foi criada nem validada uma plataforma iOS nesta entrega.

## Verificação
```bash
flutter analyze
flutter test
flutter build apk --debug
```

**Verificado:** análise sem problemas, 57 testes aprovados e APK debug compilado com assinatura verificada.

Os testes do esqueleto verificam os três destinos, a folha sem formulários, um só botão principal, a paleta/escala tipográfica, contraste textual mínimo de 4,5:1 e ausência de overflow em 360 px nos dois temas com texto até 200%. A utilização num dispositivo Android real continua por validar.
