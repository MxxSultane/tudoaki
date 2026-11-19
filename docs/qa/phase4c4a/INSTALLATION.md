# APK debug — transferência e instalação segura

Este pacote destina-se a testes controlados. Não é release nem APK de produção. Nenhuma instalação foi executada pelo Codex nesta fase.

## Identificação

- Aplicação: `mz.lifeos.lifeos` (sem sufixo ou alteração de ID).
- Versão: `0.9.2`, versionCode `12`, conforme o projecto aprovado; não se aumentou a versão para contornar uma incompatibilidade.
- Android mínimo API 24 / Android 7; target API 36. APK universal: arm64-v8a, armeabi-v7a e x86_64.
- Modo debug, assinatura de desenvolvimento Android Debug, verificada por apksigner. A assinatura não é uma credencial de produção.
- O campo `launchable_activity` dos metadados identifica a actividade exacta; actualmente `mz.tudoaki.tudo_aki.MainActivity`.

**O certificado local e o do GitHub Actions podem diferir.** O nome Android Debug não demonstra igualdade das chaves. Builds CI em runners novos geram normalmente chaves debug diferentes. A chave efémera do runner não é entregue nem persistida: este APK não estabelece um canal de actualizações futuras com assinatura estável. Cada pacote tem `apk-metadata.json`, `apksigner.txt`, `aapt.txt` e `SHA256SUMS`; usar os ficheiros que acompanham o APK efectivamente descarregado. Não partilhar, exportar ou guardar keystores no repositório/artefacto.

Pacote canónico: [APK debug em ZIP](https://github.com/MxxSultane/tudoaki/actions/runs/44515990323/artifacts/14526515741), expiração 26/11/2026 às 13:39:27 Africa/Maputo. [Metadados CI](apk-ci.json) identificam checksum e certificado. Os certificados CI e local desta entrega foram comparados e são diferentes; um destes APKs não pode ser usado para actualizar o outro só por ambos serem debug. A pasta local `/workspace/work/phase4c4a/local-apk/` é uma compilação independente; não misturar o seu certificado/checksum com o pacote CI. O APK de compilação encontra-se em `/workspace/tudoaki/build/app/outputs/flutter-apk/app-debug.apk`. O artefacto GitHub tem retenção de sete dias; após expirar, um novo build deve ser novamente inspeccionado e pode ter outra assinatura.

## Compilar e inspeccionar

Toolchain validada: Flutter 3.35.7 (`adc901062556672b4138e18a4dc62a4be8f4b3c2`), Dart 3.9.2, Java Temurin 21, Android build-tools 35.0.0. O script de ambiente abaixo é próprio desta máquina; noutro computador configurar os mesmos SDKs e ANDROID_HOME sem alterar o projecto.

```sh
cd /workspace/tudoaki
source tool/env.sh
export XDG_CONFIG_HOME=/workspace/.tools/config
flutter build apk --debug --no-pub
python3 tool/inspect_android_apk.py build/app/outputs/flutter-apk/app-debug.apk --output-directory /workspace/work/phase4c4a/local-apk
```

O inspector exige assinatura válida, um certificado, ID correcto e APK debuggable; rejeita APK de produção ou fonte/configuração que difira do HEAD. Copia o APK e gera metadados/checksum. Não instala, assina, altera configuração, gera chaves ou toca nos dados de um telefone. `source_head` identifica o checkout inspeccionado; a sequência compilar→inspeccionar no workflow associa-o ao build, não se trata de uma atestação criptográfica isolada do código; os hashes das árvores lib/android permitem comparar o código quando commits posteriores só acrescentam documentação. Não é uma garantia de instalação nem compatibilidade com um aparelho ainda desconhecido.

## Antes de instalar

1. Usar um dispositivo de testes e dados sintéticos. Registar modelo, API, serial num registo privado, pacote/versão existente e estado de autorização ADB. Seleccionar explicitamente `-s SERIAL`; não operar sobre um destino implícito se houver vários dispositivos.
2. Descarregar o ZIP do artefacto canónico e extraí-lo numa pasta própria. Confirmar o checksum e os metadados desse pacote:

```sh
sha256sum -c SHA256SUMS
"$ANDROID_HOME/build-tools/35.0.0/apksigner" verify --verbose --print-certs app-debug.apk
"$ANDROID_HOME/build-tools/35.0.0/aapt" dump badging app-debug.apk
adb devices -l
adb -s SERIAL shell getprop ro.product.model
adb -s SERIAL shell getprop ro.build.version.release
adb -s SERIAL shell getprop ro.build.version.sdk
adb -s SERIAL shell pm path mz.lifeos.lifeos
adb -s SERIAL shell dumpsys package mz.lifeos.lifeos
```

Em PowerShell, `Get-FileHash .\app-debug.apk -Algorithm SHA256` permite comparar o SHA-256 com SHA256SUMS. Não usar o hash do ZIP como se fosse o hash do APK.

3. Se a aplicação já existir, guardar exportação JSON pela interface e inventário visual dos dados de teste. A exportação serve para comparação; não se promete importação/restauro que a app não oferece. Não eliminar ou substituir `lifeos.sqlite`.
4. Inspeccionar o certificado instalado. `pm path` devolve `package:/.../base.apk`; copiar **apenas o caminho real indicado** (sem `package:`), com leitura, e comparar com o APK de testes:

```sh
adb -s SERIAL pull CAMINHO_REAL_DO_BASE_APK installed-base.apk
"$ANDROID_HOME/build-tools/35.0.0/apksigner" verify --print-certs installed-base.apk
"$ANDROID_HOME/build-tools/35.0.0/aapt" dump badging installed-base.apk
```

Comparar SHA-256 do certificado, ID e versionCode. Se não for possível ler/verificar a instalação existente, parar antes de actualizar. Se o certificado diferir, **não instalar, desinstalar, limpar dados ou trocar a assinatura**. As opções seguras são conservar a instalação e usar outro telefone de testes sem esse pacote, ou solicitar ao responsável um build de teste assinado com a chave compatível, sem partilhar a chave. Não alterar o ID para contornar o conflito. Se a versão instalada for superior a 12, parar e obter um plano de versão autorizado; não usar downgrade.

Não foi detectada uma incompatibilidade concreta nesta fase: o certificado instalado é desconhecido, pois não há dispositivo acessível. A compatibilidade permanece pendente.

## Instalar só após o preflight

Instalação nova, apenas num telefone de testes onde o pacote não existe:

```sh
adb -s SERIAL install app-debug.apk
```

Actualização, apenas após confirmar assinatura/versão compatíveis e inventário dos dados controlados:

```sh
adb -s SERIAL install -r app-debug.apk
```

Não usar `-d`, `uninstall`, `pm clear`, root ou substituição de ficheiros de dados. O instalador tem de terminar com sucesso; recolher a mensagem literal se falhar. Igualdade de assinatura permite tentar uma actualização, mas só a comparação antes/depois demonstra preservação de dados. Permissão de instalar apps desconhecidas e autorização USB devem ser dadas conscientemente no dispositivo, sem enfraquecer políticas de gestão.

Abrir a aplicação pelo ícone; registar dados e comparar exportações por tabelas/IDs/valores, ignorando só o timestamp do envelope. Se houver suspeita de perda/duplicação, parar novas escritas, guardar evidência e abrir incidente. Não executar migração improvisada nem restauração destrutiva.

## Ensaio controlado de reinstalação compatível

Num telefone de testes inicialmente sem este pacote, pode instalar-se o APK canónico, criar o conjunto sintético A–J, exportar os dados, verificar novamente certificado/versão e aplicar **o mesmo APK** com `install -r`. Comparar os dados depois. Este controlo exercita a reinstalação Android sem limpeza e com assinatura conhecida; não demonstra actualização a partir de uma instalação de produção de outro certificado nem uma migração entre esquemas. Como lib/android/dependências não mudaram na 4C.4A, não se fabrica uma versão funcional diferente para este ensaio. Uma actualização a partir de outro APK anterior só pode ser ensaiada com o seu certificado compatível efectivamente verificado.
