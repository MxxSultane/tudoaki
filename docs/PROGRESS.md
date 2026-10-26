# Progresso — Tudo Aki

## Actualização 0.9.2 — Fase 6, fiabilidade Android
- Lembretes preservam instantes UTC e datas ISO com offset, convertendo para Maputo; datas sem offset mantêm a hora civil de Maputo. Segundos deixam de ser truncados pelo serviço.
- Datas passadas não pedem permissão. O prazo é verificado de novo depois do diálogo de permissão. Inicialização falhada pode ser repetida e chamadas simultâneas partilham a inicialização em curso.
- Ao reabrir uma tarefa, resultado falso do agendamento gera o mesmo aviso que uma falha nativa, preservando a alteração SQLite. Rótulo acessível passa a Reabrir nas tarefas concluídas. Converter uma tarefa para apenas dia não tenta agendar um lembrete.
- Onze testes novos: oito do canal de notificações Android simulado, dois de reabertura de tarefa com falha/recusa e um de pausa/retoma do ciclo de vida. O foco recupera o prazo após uma hora em segundo plano e só atribui XP após confirmação.
- **80 testes aprovados**, análise sem problemas e verificação SQL aprovada. Sem novos pacotes, tabelas ou migrações; identidade de instalação preservada.

APK debug 0.9.2+12 compilado; assinatura v2 verificada, versão e ID de instalação conferidos com aapt. SHA-256: `71a87e7d2d2c679dc6e23d13c610fcbe0be2af64bcfd90a98d0e2c96bc124bd5`.

A Fase 6 permanece em curso. Não há dispositivo/emulador Android ligado neste ambiente: entrega física, reinício do telefone, actualização e restrições de bateria ainda não foram executados. [Guião de validação](ANDROID_VALIDATION.md) preparado com passos e resultados esperados. Não foi adicionado um alarme de fim ao foco.


## Actualização 0.9.1 — ícone
Calendário preto com argola e visto verde-petróleo sobre fundo claro, usando a geometria do logótipo fornecido. Ícone vectorial Android 7, camadas adaptativas Android 8+ e máscara monocromática Android 13+. A zona segura foi verificada; o arranque nativo reutiliza a nova arte. Sem novos pacotes ou alterações aos dados.

APK debug 0.9.1+11 compilado, recursos conferidos com aapt e assinatura verificada. SHA-256: `3fb27550080a0049b7f989da5166cdec0342dee603d0931a6aed7ddbd2a4e381`. A bateria funcional mais recente continua a ser a da versão 0.9.0 (69 testes); não foi repetida para esta alteração de recursos.


## Entrega actual — planeamento semanal 0.9.0
- **Mais → Planear semana**, fora da navegação principal. Tipo Tarefas/Eventos no topo, cartões dos sete dias e uma única acção principal que adiciona ao dia seleccionado. Contagens e detalhes recolhidos para caber no telemóvel.
- Domingo sugere a segunda-feira seguinte; nos restantes dias abre a segunda-feira da semana actual. Navegação civil entre semanas e selector de data, preservando o dia da semana e respeitando 2000–2100.
- Eventos herdam o dia escolhido e duração inicial de uma hora; início/fim podem ser ajustados. Uma falha no formulário genérico, que ignorava initialDate nos eventos, foi reproduzida e corrigida.
- Tarefas podem ter apenas dia, com hora opcional. O formato YYYY-MM-DD em Tasks.due distingue Sem hora de uma tarefa marcada para 00:00. Edição, agenda, conflitos e exportação preservam a distinção; lembretes só ficam disponíveis com hora definida.
- Escolher pendente programa tarefas existentes sem duplicar IDs ou perder associações. Eventos, tarefas e compromissos académicos já existentes são lidos directamente da agenda. Guardar persiste imediatamente; cancelar e navegar não criam registos ou XP.
- Reutilização de formulários, repositório e tema; Cubit próprio para semana/dia/tipo. Sem novos pacotes, tabelas ou migrações; esquema v5 preservado.


Verificação 0.9.0 concluída: **69 testes aprovados**, incluindo oito testes novos (regras, reabertura/exportação e fluxos do planeador), análise sem problemas, formatação limpa e verificação SQL aprovada. Layout claro/escuro revisto visualmente e testado em 360 px com texto a 200%. APK debug 0.9.0+10 compilado; assinatura v2 e identidade confirmadas. SHA-256: `5d00688d84debf2ae717df9c622d52363d291520f0a7bb733a4f665581314b69`. Validação física Android continua pendente.


## Histórico — integração funcional 0.8.0
O pedido mais recente autoriza ligar o esqueleto aos dados reais e recuperar as áreas do produto original. Mantêm-se três separadores, temas e tipografia do guia; o limite anterior a um esqueleto já não é o âmbito actual.

- **Agenda:** dados reais, datas seleccionáveis, modos Dia/Semana/Mês em lista, mistura cronológica de eventos/tarefas/estudo/aulas/avaliações, recorrências e conflitos. “O meu dia” recolhe prioridades, rotinas, próximo compromisso e metas. Tarefas sem data ficam numa secção recolhida.
- **Metas:** lista leve, filtros Activas/Alcançadas, detalhe com métricas, registo de progresso em folha, edição, submetas, etapas, tarefas e histórico. Concluir tarefas não altera a métrica.
- **Tarefas:** filtros Pendentes/Concluídas, edição ao tocar, agendamento, prioridade/importância e associações avançadas, conclusão/reabertura com XP idempotente e feedback táctil.
- **Criação:** + → Evento/Tarefa/Meta abre formulários reais; os campos avançados ficam em “Mais opções”. Guardar mostra o novo registo na área adequada, com filtro/dia ajustados. Cancelar não cria dados.
- **Mais:** hábitos/bem-estar, estudos/foco, finanças multimoeda, progresso/conquistas, revisões e definições acessíveis sem novos separadores. Módulos existentes partilham o mesmo repositório; cabeçalhos repetidos e botões principais duplicados foram retirados destas rotas.
- **Dados:** esquema v5 e compatibilidade de instalação/SQLite preservados; sem migração destrutiva ou dados fictícios. A entrada volta a abrir a base existente. Riverpod mantém os dados partilhados; três Cubits tratam data/modo e filtros de cada separador. Única dependência nova: flutter_bloc 9.1.1.
- **Qualidade:** teste da app cria meta anual, associa/programa tarefa, conclui/edita, regista resultado, cria/edita evento semanal e reabre SQLite. Testes verificam todas as áreas, uma acção principal por página e layouts de 360 px nos dois temas até 200% de texto. Regras novas cobrem mistura cronológica, fronteiras de conflitos e limites de navegação.

Verificação concluída: **61 testes aprovados**, `flutter analyze` sem problemas, formatação sem alterações, verificação SQL v1 → v5 aprovada, layouts reais revistos em claro/escuro, APK debug 0.8.0+9 compilado e assinatura v2 verificada. `aapt` confirmou tudoAki e ID de instalação preservado, API mínima 24 e target 36. SHA-256 do APK: `bc10c7feceb1ba3be5e35b6660465301c46fc819821a96f73b0434c8252da5eb`.

A integração recupera as funções já implementadas. Não declara concluídos o WOOP guiado, interesses no onboarding, categorias de calendário, excepções por ocorrência, backup/importação ou a certificação Android. As limitações de foco, notificações e outros fusos continuam válidas.


## Histórico — esqueleto 0.7.0
O pedido mais recente redefine a interface activa para o esqueleto descrito em [AGENTS.md](../AGENTS.md): temas claro/escuro, três separadores, Hoje com exemplos e folha Evento/Tarefa/Meta. Metas e Tarefas são estados vazios. Nenhum formulário ou funcionalidade adicional foi implementado. O código anterior foi preservado, sem ligação à entrada actual nem abertura da base de dados pelo esqueleto.

Tema centralizado, Inter/Newsreader locais via google_fonts, cartões planos, botão + único e navegação Agenda/Metas/Tarefas. O nome apresentado pela aplicação é tudoAki e o identificador técnico continua tudo_aki. A versão Android existente foi preservada; a criação da plataforma iOS não faz parte deste pedido.

Verificação 0.7.0: `flutter analyze` sem problemas; **57 testes aprovados**, incluindo os três novos testes do esqueleto; layouts claro/escuro revistos visualmente em 360 px; APK debug compilado e assinatura v2 verificada. `aapt` confirmou nome tudoAki, versão 0.7.0+8, Android mínimo 24 e target 36. SHA-256: `9c5d894d315c402fd4db0c6b5b49f5af53cc6c21ccd37891da3e8a4b57d69088`. Testes em dispositivo Android real continuam pendentes.

Os resultados e fases abaixo são históricos das versões até 0.6.0; não descrevem a navegação actual.

## Histórico até 0.6.0

## Estado por fase
A Fase 3 está implementada no escopo actual e a Fase 4 foi consolidada com orçamentos e recorrências. A Fase 5 inclui agora conquistas e um gráfico semanal; a Fase 4 inclui moeda configurável; a validação física da Fase 6 está pendente.

| Fase | Estado | Entrega e pendências |
| --- | --- | --- |
| 1 — Fundação | Concluída para desenvolvimento | Arquitectura, tema, navegação e SQLite preparados. |
| 2 — Núcleo funcional | Implementado; validação real do MVP pendente | Hoje, tarefas, agenda, metas, submetas e etapas; lembretes e ciclo de reabertura Android ainda precisam de dispositivo. |
| 3 — Organização pessoal | Implementada no escopo actual; validação Android pendente | Hábitos, disciplinas, horários, avaliações, sessões de estudo, foco e revisões. |
| 4 — Áreas de vida | Implementada no escopo actual | Transacções, poupanças, orçamentos e recorrências por moeda (MZN/USD/EUR/ZAR), bem-estar via hábitos. |
| 5 — Gamificação | Incremento funcional implementado | XP, níveis, quatro conquistas persistentes e gráfico semanal com contagens; catálogo ampliado e gráficos de tendências ficam para evolução. |
| 6 — Qualidade | Em curso | Análise, testes automatizados e APK; utilização, notificações e acessibilidade num dispositivo ainda pendentes. |

## Fundação e núcleo implementados
- Documentos de visão, requisitos, histórias, arquitectura, design e fases criados antes do código.
- Flutter 3.35.7 / Dart 3.9.2, Riverpod, GoRouter e Material 3; português, tema claro/escuro, cinco áreas principais.
- Drift/SQLite nativo, esquema v5 com 20 entidades e migrações transaccionais v1/v2/v3/v4 → v5, chaves estrangeiras, índices, transacções e recusa de migrações desconhecidas.
- Metas com horizonte, métrica, prazo, edição e histórico; criação de acções associadas. Métricas de resultados independentes da conclusão de tarefas.
- Tarefas com prioridades, importância, disciplina, meta e data/hora; edição, reagendamento, conclusão, reabertura e eliminação.
- Agenda diária/semanal/mensal em lista; eventos com edição, recorrência diária/semanal e sinalização de sobreposição entre eventos.
- Hábitos com dias da semana, plano quando/então, pausa, registo e histórico.
- Disciplinas e trabalhos associados; revisões semanais/mensais persistidas.
- Receitas, despesas, contribuições e metas de poupança em centavos; resumos mensais separados por moeda.
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

## Incremento 0.4.0 — planeamento financeiro
- Orçamentos por categoria/mês, despesas realizadas e restante; navegação mensal e categorias normalizadas sem reescrever movimentos.
- Regras recorrentes semanais/mensais/anuais, com revisão e confirmação explícita. Nenhuma entrada criada ao abrir a página; lotes até 24 e calendário sem deriva de fins de mês.
- Registos idempotentes por regra/vencimento; pré-visualizações desactualizadas/futuras recusadas. Movimentos eliminados não são recriados; eliminar a regra preserva o histórico monetário.
- Datas de movimentos editáveis e gestão de metas/contribuições de poupança. Eliminar uma meta preserva contribuições sem associação.
- Parser, somas e formatação monetária exactos, com BigInt antes de validar limites. Um teste reproduziu overflow de entrada muito grande; a correcção rejeita a entrada em vez de a transformar num valor pequeno.
- Migração v1/v2/v3 → v4, exportação e eliminação total com os novos dados. Sem novas dependências; moeda MZN mantida.
- Testes de regras e migração e três fluxos de widgets em 360×800: orçamento/despesa/mês, revisão/confirmar/eliminar recorrências e poupança/contribuições. Corrigido overflow visual dos selectores em ecrãs pequenos.

## Incremento 0.5.0 — progresso e conquistas
- Quatro conquistas persistentes, derivadas de origens únicas do histórico de XP, sem recompensa adicional; sincronização transaccional e idempotente antes de carregar os dados. Reconhecimento retroactivo com data do marco; desactivar gamificação oculta/suspende reconhecimento sem apagar história.
- Gráfico de sete dias com barras e contagens por área, incluindo dias sem actividade. Instantes UTC são agrupados pela data de Maputo; datas civis antigas são preservadas. Tarefas reabertas e registos apagados deixam de contar no gráfico.
- Resumo conta metas alcançadas apenas pelo estado completed. Esquema v4 preservado; exportação e eliminação já incluem conquistas.
- Quatro testes adicionais: reconhecimento/reabertura/exportação/reset, gamificação desactivada/reactivada, fronteiras de datas e exclusões, e widget de 360 px com texto a 200%.

## Incremento 0.6.0 — moedas com denominação preservada
- Preferência MZN/USD/EUR/ZAR para novos registos e selector de consulta/criação na área financeira. Cada valor guarda a moeda; somas, limites, contribuições e recorrências são separados por moeda, sem câmbio.
- Migração transaccional v1/v2/v3/v4 → v5: valores antigos recebem MZN independentemente da preferência antiga sem interface. Orçamentos passam a ter unicidade por mês/categoria/moeda, com IDs e centavos preservados.
- Triggers impedem alterar a moeda de registos existentes e associar uma contribuição a poupança noutra moeda. Recorrências mantêm a denominação da regra; edição, eliminação de associações, exportação e reset preservam as regras definidas.
- Sete testes novos: migração v4/reabertura com histórico/foco/conquistas; preferências/imutabilidade; orçamentos por moeda; contribuições incompatíveis; recorrências após mudar preferência; dois fluxos de interface em 360×800.

## Verificação efectuada no ambiente
- `flutter pub get`: concluído, lockfile gerado e dependências instaladas.
- `dart format lib test`: executado.
- `flutter analyze`: sem problemas na verificação final concluída.
- `flutter test --reporter expanded`: **56 testes aprovados**, incluindo o fluxo de widget meta → tarefa associada → agendamento → conclusão → XP, recusa de versão futura da base, persistência em ficheiro após reabertura, hábitos, relações, dinheiro e recorrência.
- `python3 tool/check_schema.py`: SQL, relações, unicidade, centavos e reabertura aprovados.
- `flutter build apk --debug`: **aprovado**; APK em `build/app/outputs/flutter-apk/app-debug.apk` (149.5 MiB), Tudo Aki 0.6.0, Android 7.0+ (API 24), target API 36, ARM64/ARMv7/x86-64.
- `apksigner verify --verbose`: assinatura de depuração v2 verificada. O APK apresenta o nome Tudo Aki, uma única actividade no launcher e os ícones novos, mantendo o ID de instalação anterior. `aapt dump badging` confirmou identidade, versões, permissões e arquitecturas.
- SHA-256 do APK: `c02db9de58920d35ea691dfa4c9c88c7c11428bc37eddd03cebd815a1322116e`.

## Ambiente e reprodução
`tool/setup.sh` fixa o Flutter por commit oficial e o Temurin JDK 21.0.13+9 por SHA-256, instala dependências com lockfile, prepara SQLite de testes e as ferramentas Android. `tool/env.sh` activa os caminhos. `tool/setup_android.sh` usa o checksum oficial da CLI e configura o proxy Java sem copiar credenciais. SDKs/caches ficam em `/workspace/.tools`, fora do repositório da aplicação. A instalação foi repetida com sucesso, com o lockfile respeitado. `install_script`, `start_skill` e o domínio `storage.googleapis.com` foram guardados no rascunho; isso não publica o ambiente.

A primeira tentativa de download do catálogo Flutter teve 403 e depois 404; a instalação pelo Git oficial funcionou. A ligação `libsqlite3.so` em `.tools/native` usa a biblioteca do sistema já existente. As pastas de estado Dart/Flutter/analisador/adb no directório pessoal precisaram de permissões de escrita específicas. O Gradle precisou de propriedades explícitas para usar o proxy do ambiente. O Java original não fornecia o compilador exigido pelo Gradle; foi instalado um JDK completo. O Temurin usa o repositório de certificados Java do sistema para confiar no proxy, com TLS verificado; o sdkmanager recebe os parâmetros de proxy explicitamente. Foram identificadas as APIs Android 34, 35 e 36, o NDK 27 e o CMake 3.22.1 exigidos pela aplicação/plugins. Nenhuma verificação TLS ou de pacotes foi desactivada.

## Pendências e limites
O MVP **ainda não está certificado num dispositivo Android**. Falta testar a entrega de lembretes e a persistência no ciclo de fecho/reabertura do processo Android; o teste existente valida SQLite em Linux. Sem dispositivo ligado e sem `/dev/kvm` neste ambiente.

Fases posteriores: edição de uma ocorrência isolada e excepções de recorrência; eventos que atravessam vários dias e conflitos com blocos de tarefas; categorias configuráveis; outras moedas além de MZN/USD/EUR/ZAR; catálogo ampliado de conquistas; WOOP guiado; interesses no onboarding; backup/importação; suporte a outros fusos/DST e plataformas; verificação de acessibilidade em dispositivo.

Quatro conquistas e o gráfico semanal dispõem de interface funcional. A grelha mensal avançada e outros gráficos de tendências continuam pendentes. Não há analytics, conta, backend, sincronização bancária ou encriptação implementada.

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
