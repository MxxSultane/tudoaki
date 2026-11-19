# Fase 4C.4A — preparação e validação Android real

19 de Novembro de 2026. **APK e roteiro preparados; validação física Android não executada.** Sem funcionalidades novas, merge, migrações ou release.

## 1. HEAD e branch

Base aprovada confirmada localmente e no remoto: **38086977b0dfe62c147ecb32ba4a48af858a2d1a**, branch `feat/fase-4c3f-integracao-global`, árvore inicialmente limpa. Criado directamente **test/fase-4c4a-validacao-android**.

Lidos AGENTS.md, V2_CONTRACTS.md, relatório 4C.3F, ANDROID_MANUAL_QA.md, contratos de persistência/navegação, Gradle/manifest, assinatura debug efectiva, testes e workflows. Reexecutada a baseline: **367/367**, sem alterações de produção. O commit de preparação e a CI são identificados na secção 11; o histórico do branch identifica o HEAD documental final.

## 2. APK e instalação

[Instruções completas](qa/phase4c4a/INSTALLATION.md). Compilação local executada com:

```sh
source tool/env.sh
export XDG_CONFIG_HOME=/workspace/.tools/config
flutter build apk --debug --no-pub
python3 tool/inspect_android_apk.py build/app/outputs/flutter-apk/app-debug.apk --output-directory /workspace/work/phase4c4a/local-apk
```

| Propriedade | Resultado verificado localmente |
| --- | --- |
| Flutter | 3.35.7, revisão adc901062556672b4138e18a4dc62a4be8f4b3c2 |
| Dart | 3.9.2 |
| Java | Temurin OpenJDK 21.0.13+9 LTS |
| APK de compilação | /workspace/tudoaki/build/app/outputs/flutter-apk/app-debug.apk |
| Pacote local inspeccionado | /workspace/work/phase4c4a/local-apk/app-debug.apk |
| Application ID | mz.lifeos.lifeos |
| Versão | 0.9.2, versionCode 12; não alterados |
| Android | minSdk 24 / Android 7; targetSdk 36 |
| ABIs | arm64-v8a, armeabi-v7a, x86_64 |
| Modo | debug, debuggable confirmado pelo manifesto |
| Assinatura | Android Debug, RSA 2048; apksigner verificou assinatura v2 |
| Dimensão local | 187039861 bytes |
| APK SHA-256 local | 84c2ed115e4c28bce2fcc7d2beab5a21e19a5eaffad12fd4ab6ceb9653b00bc6 |
| Certificado SHA-256 local | ea75c11172c7f568031f7e09c4698b9e63f3242016652c3668d69bbe74feb5c6 |

[Metadados locais](qa/phase4c4a/apk-local.json) e [verificação da assinatura](qa/phase4c4a/apksigner-local.txt). Build local aprovado em **8,1 s**. Uma assinatura válida e manifesto coerente permitem preparar o pacote para instalação, mas **não equivalem a uma instalação executada**.

A disponibilização canónica pelo GitHub Actions inclui `app-debug.apk`, `apk-metadata.json`, `apksigner.txt`, `aapt.txt` e `SHA256SUMS`, com retenção de sete dias. [Descarregar o ZIP canónico](https://github.com/MxxSultane/tudoaki/actions/runs/44515990323/artifacts/14526515741); execução e identidade na secção 11. Não se adiciona um binário de 187 MB ao Git nem se publica release.

**Não confundir assinaturas:** o APK CI é um build independente do APK local; os certificados/checksums são diferentes nos dois pacotes verificados desta entrega. A chave debug efémera de um runner novo não estabelece um canal de actualizações com chave estável. Usar os metadados que acompanham o ficheiro efectivamente descarregado, sem publicar chaves privadas ou substituir a assinatura de uma instalação existente.

Antes de instalar, inspeccionar o pacote/versão/certificado instalado com leitura, inventariar dados controlados e comparar o SHA-256 do certificado. Se forem diferentes, desconhecidos ou a versão instalada for superior, **parar**. Opções seguras: conservar a instalação e usar outro telefone de testes sem esse pacote, ou obter do responsável um build com assinatura compatível. Não alterar applicationId, desinstalar, limpar armazenamento, usar downgrade ou copiar SQLite por cima.

Instalação nova só num telefone de testes sem o pacote: `adb -s SERIAL install app-debug.apk`. Actualização só depois do preflight: `adb -s SERIAL install -r app-debug.apk`. O guia também descreve um controlo de reinstalação do mesmo APK com dados sintéticos; esse ensaio não valida uma versão de produção de outra assinatura.

## 3. Dispositivo e ambiente

[Disponibilidade observada](qa/phase4c4a/device-availability.json): ambiente Cloud Linux activo; `/dev/bus/usb` não exposto; cliente ADB abortou ao tentar criar `/home/agent/.android` num sistema de ficheiros protegido; ligação de leitura ao servidor ADB local na porta 5037 recusada. Não há telefone acessível confirmado neste ambiente. Isto não afirma que não exista equipamento fora dele.

Nenhum modelo/versão Android/IME/TalkBack de aparelho foi inventado. Não se alterou HOME ou permissões do sistema para contornar o impedimento, não se instalou a aplicação nem se limpou qualquer dado. A toolchain de compilação não é um dispositivo Android.

## 4. Percursos e resultados

[Roteiro exacto A–J](qa/phase4c4a/DEVICE_TEST_PLAN.md) e [registo CSV](qa/phase4c4a/results.csv), com esperado, observado, problemas, reprodução, gravidade, evidência, aparelho/build e operador/data. O conjunto sintético inclui IDs/relações, moeda, data civil D/D+1 e expectativa de XP conforme as operações efectivamente realizadas.

| Percurso físico | Estado | Observado / evidência |
| --- | --- | --- |
| A — Criar, editar, concluir e reabrir tarefa | Não executado | Sem dispositivo; nenhum resultado observado |
| B — Planear amanhã e consultar Hoje | Não executado | Guia distingue D e D+1 sem duplicar tarefas |
| C — Meta numérica, edição e progresso | Não executado | Sem dispositivo; modo numérico preservado |
| D — Disciplina e trabalho associado | Não executado | Sem dispositivo |
| E — Receita, despesa e totais | Não executado | Sem dispositivo; valores controlados e cêntimos definidos no guia |
| F — Vários hábitos e registo | Não executado | Sem dispositivo |
| G — Progresso e Percurso | Não executado | Sem dispositivo; Linha/Lista e origem incluídas no guia |
| H — Hoje/Planear/Metas/Mais | Não executado | Sem dispositivo; estado dos ramos/modal incluído |
| I — Formulários com IME Android | Não executado | Não se substitui por teclado simulado Flutter |
| J — Fecho/interrupção/reabertura e dados | Não executado | Sem dispositivo; sessão pausada/configurações incluídas |

Os testes Flutter existentes foram reexecutados na secção 11. Não são registados como percursos Android realizados. Não existem problemas físicos observados cuja gravidade possa ser atribuída; isso não significa ausência de problemas.

## 5. TalkBack e teclado

**Pendentes em Android real:** TalkBack/ordem de leitura/nomes, foco, alvos tácteis, IME/teclado físico, texto ampliado, contraste em contexto, SafeArea, movimento reduzido e ambos os temas. O roteiro inclui barra inferior a 200%, compreensão dos rótulos que quebram e registo da escala efectiva não linear do Android quando aplicável.

Não se chama 320/360/390 dp a um aparelho sem medir a largura, não se confunde árvore semântica Flutter com TalkBack e não se declara certificação WCAG. Os resultados automatizados anteriores mantêm valor próprio, sem preencher as células físicas pendentes.

## 6. Desempenho

**Sem medições Android.** [Plano de medição](qa/phase4c4a/PERFORMANCE_PLAN.md) preparado para abertura fria/quente, scroll, mudança de módulos, formulários, Progresso/Percurso com volume extenso, memória e frames lentas/jank. Exige modelo/API, build/certificado, volume real, amostras, ferramentas, UI/raster e Hz do dispositivo.

APK debug destina-se primeiro a testes funcionais; análise de desempenho deve usar build profile com assinatura compatível verificada, sem alterar o projecto para contornar incompatibilidade. Nenhum benchmark Linux debug é usado como prova de desempenho Android. Volumes extensos sem fixture segura ficam bloqueados, sem inventar uma API de seed/importação em produção ou sobrescrever dados reais.

## 7. Preservação de dados

[Verificação Git](qa/phase4c4a/preservation.json): lib/, android/, assets/, pubspec.yaml/lock e contratos preservados face a 3808697. SQLite v5/lifeos.sqlite, repositórios/modelos, TaskOperations, XP/conquistas, cálculos financeiros, regras académicas, sessões, notificações, rotas/guardas e identificador não foram alterados.

Os 367 testes incluem persistência sintética/legado/precisão/XP; a actualização física compatível **não foi ensaiada**. O procedimento preparado compara todas as tabelas, IDs/FKs, datas exactas, valores/moedas, histórico e configurações antes/depois. Uma exportação JSON é evidência de comparação, não promessa de importação/restauro. O timestamp do envelope pode variar; diferenças de dados exigem explicação.

Sem operações sobre dados de telefone, instalações, desinstalações, limpeza ou migrações. Compatibilidade com uma instalação existente permanece desconhecida até ler o certificado/versão desse aparelho.

## 8. Problemas encontrados

1. Acesso a Android real indisponível pelos meios verificados, com erro ADB e ausência de USB exposto/servidor acessível.
2. Assinatura da instalação existente desconhecida. Certificados locais e CI podem divergir; não assumir compatibilidade pelo DN Android Debug. Versão instalada >12 também exigiria plano autorizado, sem downgrade.
3. Artefactos de testes expiram após sete dias e os próximos builds podem ter outro certificado; o APK CI verificado tem assinatura diferente do APK local. Não se promete distribuição permanente ou actualização futura com chave estável.

Não foi reproduzido um defeito novo da aplicação Android nesta fase. Não se atribui aprovação aos cenários não executados.

## 9. Correcções efectuadas

**Nenhuma correcção de produção**, por não haver problema da aplicação reproduzido nesta fase. Sem redesign, funcionalidades ou alteração de contratos.

Preparação técnica: novo inspector Python de APK, que valida ID/debuggable/assinatura/certificado, verifica fonte/configuração limpa e produz checksum/proveniência; quatro testes do inspector rejeitam pacote de produção, ID incorrecto e certificado ambíguo e verificam que metadados não afirmam instalação. Fecho de ficheiros ajustado antes da execução final sem ResourceWarning. Ferramentas não instalam ou assinam.

Workflows existentes: branch habilitado para validação; quatro testes do inspector além dos nove testes do processador; inspecção/cópia do APK e upload debug de sete dias apenas por pedido explícito (`[apk-testes]` neste branch ou opção workflow_dispatch existente). Logs comuns incluem metadados, não o APK. Permissões, toolchain e verificações anteriores preservadas.

## 10. Capturas Android

**Nenhuma captura ou vídeo Android real nesta fase.** O guia fornece comandos de recolha com dados sintéticos e registo de evidência por cenário. As capturas do renderer Flutter da 4C.3F não são reapresentadas como Android físico nem substituídas por maquetas.

## 11. Testes Flutter, APK e CI

Local: **367 executados/aprovados**, zero falhas/ignorados/erros; dart format 118 ficheiros sem alterações; flutter analyze sem problemas; APK debug compilado em 8,1 s e apksigner/aapt verificaram o ficheiro real. Quatro testes unitários do inspector aprovados, separados da contagem Flutter. [Resumo estruturado](qa/phase4c4a/test-results.json).

Commit de preparação: **45553d8c0bd8b9c5e99244419f258a16d38c838c**. Resultados remotos efectivamente observados:

- [Flutter validation — sucesso](https://github.com/MxxSultane/tudoaki/actions/runs/44515990205): 367/367; análise sem problemas; format=0 analyze=0 test=0 lock=0; nove testes do processador e quatro do inspector aprovados.
- [Android debug validation — sucesso](https://github.com/MxxSultane/tudoaki/actions/runs/44515990323): compilação em 221,2 s, assinatura/manifesto/proveniência verificados, preservação confirmada e upload do pacote de testes.

### APK canónico entregue

**[Descarregar APK debug e metadados (ZIP)](https://github.com/MxxSultane/tudoaki/actions/runs/44515990323/artifacts/14526515741)**. Artefacto `14526515741`, `tudo-aki-debug-45553d8c0bd8b9c5e99244419f258a16d38c838c`; ZIP 82727704 bytes. Requer acesso ao GitHub para descarregar artefactos. Expira em **26/11/2026 às 13:39:27, Africa/Maputo**.

- APK dentro do ZIP: `app-debug.apk`, **160674168 bytes**.
- SHA-256 do APK: `78cc4fe635308b7e54603ee6f4092b8cad24552d881651590de4ced8c004f77e`.
- SHA-256 do certificado CI: `cc46ba3e4522477042dba20a215b50e09936b480af2e872622a3e6183d214214`.
- SHA-256 do ZIP, diferente do APK: `1217192d013df67c00f559251ed8f04b06f79f7b0a8522eb93b84aabb90dbab0`.

[Identidade e proveniência completas](qa/phase4c4a/apk-ci.json). Toolchain CI: Flutter 3.35.7, Dart 3.9.2, Temurin 21.0.13+9. As árvores lib/android/assets e hashes de dependências correspondem à fonte aprovada; não se presume reprodução binária idêntica entre ambientes. A dimensão e assinatura CI diferem do build local documentado na secção 2: não misturar os seus ficheiros de verificação.

O commit documental posterior só consolida resultados. Volta a validar o branch, mas não disponibiliza outro APK, pois não contém o marcador explícito de upload. Usar o artefacto pinado acima, não metadados de outro build ou os logs de uma execução posterior. [Execuções do HEAD final](https://github.com/MxxSultane/tudoaki/actions?query=branch%3Atest%2Ffase-4c4a-validacao-android). Nenhum resultado de compilação é declarado como ensaio físico.

## 12. Limitações

Sem aparelho, instalação/actualização, TalkBack/IME real, interrupção Android, dados após actualização, notificações reais ou profiling mobile. O APK foi compilado e inspeccionado, mas não instalado. A assinatura debug não certifica compatibilidade com produção. O roteiro/CSV são preparação, não resultados. Uma build CI pode ter outra assinatura que a local; comparar sempre o pacote correcto.

## 13. Bloqueios

- Telefone de testes acessível e autorizado, API ≥24, com dados controlados.
- Certificado/versão instalados e compatibilidade confirmados antes de actualizar.
- Execução A–J/acessibilidade/desempenho e evidência preenchida por operador real.
- Eventual harness de grande volume, se necessário, requer preparação segura separada; sem novas entidades de produção.
- Qualquer necessidade de migração/contrato/regra de negócio deve ser submetida a aprovação, sem correcção silenciosa.

## 14. Recomendação para integração

Entregar o APK de testes e realizar o preflight num telefone controlado; executar A–J, acessibilidade e medições, comparar dados e preencher o CSV. Se surgir um problema reproduzido, isolar correcção com regressão e manter os gates de dados. Não aprovar validação Android concluída, integração final ou release apenas com a CI/renderer.

A preparação está pronta para execução quando houver equipamento. **Validação Android real permanece pendente. Sem merge automático, release ou início de funcionalidades novas.**
