# Plano incremental

**Âmbito actual (0.9.2):** avançar a Fase 6 com correcções nos lembretes Android e testes de ciclo de vida, preservando o planeamento semanal e a interface funcional. O pedido actual substitui a limitação anterior ao esqueleto.
1. Fundação: documentos, Flutter/Android, tema, router, esquema v1, repositório.
2. Núcleo: tarefas/metas/eventos/agenda/Hoje e armazenamento real.
3. Organização: hábitos, disciplinas, horários, avaliações, estudo com foco e revisões implementados no escopo actual; validar também num dispositivo.
4. Áreas: transacções, poupanças, orçamentos, recorrências e hábitos de bem-estar implementados, incluindo MZN/USD/EUR/ZAR com denominação por registo.
5. Motivação: XP idempotente, níveis, quatro conquistas persistentes e gráfico semanal implementados; evoluir catálogo/tendências após utilização real.
6. Qualidade: testes de regras/persistência/widgets, análise, APK e testes em Android.

Cada fase exige registar os resultados reais em PROGRESS.md. Código escrito não equivale a comportamento validado. A rede/SDK bloqueados não justificam declarar testes aprovados.

## Incremento 0.2.0 — planeamento de metas
Concluídos: hierarquia de submetas, gestão de etapas e tarefas no plano da meta, migração v1 → v2, protecção contra ciclos e teste do fluxo pela interface. Ver PROGRESS.md para as verificações e limitações de Android.

## Incremento 0.2.1 — identidade Tudo Aki
Nome oficial e slogan aplicados à interface, onboarding, launcher, arranque, exportação e documentação. Identificador Flutter/Dart `tudo_aki`, namespace Android actualizado e IDs de instalação/armazenamento preservados para compatibilidade. Funcionalidades e metodologias permanecem as definidas no plano.

## Incremento 0.3.0 — organização pessoal/académica
Horários por disciplina, avaliações, sessões de estudo, integração na agenda e foco persistido com pausa/retoma/conclusão. Migração v3 e testes de recuperação, limites de XP, privacidade e conflitos. O próximo incremento funcional é a consolidação da área financeira (orçamentos e movimentos recorrentes); a validação física Android continua pendente na Fase 6.

## Incremento 0.4.0 — planeamento financeiro
Orçamentos mensais, revisão/confirmação de movimentos recorrentes, datas editáveis, gestão de poupanças e cálculo/validação monetária exactos. Migração v4 e testes de regressão, consentimento de registo, idempotência, histórico e interface em 360×800. Ficam para os próximos incrementos moeda configurável, conquistas/gráficos e a validação física Android.

## Incremento 0.5.0 — progresso e conquistas
Quatro conquistas do histórico de XP, reconhecimento retroactivo sem XP adicional, preferência respeitada e gráfico acessível dos últimos sete dias. Mantém esquema v4 e nenhuma dependência nova. Neste incremento, moeda configurável e verificação física Android ficaram pendentes; a moeda foi tratada no incremento 0.6.0.

## Incremento 0.6.0 — moedas
Preferência para novos registos e consulta por moeda; preservação de MZN no histórico, migração v5, orçamentos independentes e contribuições/recorrências com denominação consistente. A validação física Android permanece pendente; seguem melhorias de planeamento e recuperação de dados conforme os requisitos.

## Incremento 0.8.0 — integração harmónica
Núcleo funcional na interface nova, formulários compactos, detalhes de metas e acesso Mais aos módulos de hábitos, estudos, finanças, progresso, revisões e definições. Preservar esquema/dados e verificar navegação, persistência real, regras e acessibilidade. Continuam pendentes os itens explicitamente futuros e a validação física Android.

## Incremento 0.9.0 — planear ao domingo
Entrada em Mais, semana seguinte por defeito ao domingo, sete dias em cartões, tipo de criação no topo e formulários compactos. Permitir tarefas sem hora, reutilizar pendentes e reflectir tudo na agenda, sem duplicar entidades. Validar limites de datas, ausência de falsos conflitos, persistência e layouts em 360 px/200% de texto.

## Incremento 0.9.2 — fiabilidade Android
Correcção de conversão UTC/Maputo, datas passadas e inicialização dos lembretes; aviso de agendamento falhado ao reabrir tarefas. Testes do canal nativo simulado e do ciclo de vida do foco. A validação automatizada não substitui a entrega real de notificações: seguir ANDROID_VALIDATION.md num dispositivo antes de fechar a Fase 6.
