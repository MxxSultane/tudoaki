# Tudo aki 2.0 — contrato de evolução

## Âmbito e estado
A Tudo aki é um organizador completo de vida pessoal: tarefas, agenda, metas, hábitos, estudos, finanças, planeamento e progresso. Deve ser intuitiva sem tutoriais, agradável e visualmente premium. Português europeu, preferindo a grafia pré-AO90. Identificador Dart: `tudo_aki`.

**Produção de referência:** 0.9.2+12, commit 9283217; três separadores Agenda/Metas/Tarefas. A direcção 2.0 abaixo é aprovada como contrato, ainda não implementada.

**Fase 1:** apenas documentação e novos testes. Não redesenhar ecrãs, mudar navegação de produção, esquema, regras financeiras, XP/conquistas, identificadores ou comportamentos. Não avançar para a Fase 2 sem aprovação explícita do utilizador. Não eliminar classes antigas sem provar a ausência de utilizações; screens.dart ainda suporta áreas activas.

## Preservação obrigatória
- Trabalhar num branch isolado; não modificar main directamente.
- Manter Android `applicationId = mz.lifeos.lifeos`, compatibilidade da actividade e continuidade da assinatura nas actualizações. Manter `lifeos.sqlite` no directório actual e esquema v5 nesta fase.
- Preservar IDs, relações, precisão de datas, valores monetários, XP e conquistas. Não executar migrações destrutivas nem operações sobre dados reais.
- Tasks.due mantém o contrato actual: NULL sem data; YYYY-MM-DD dia sem hora; ISO com hora. Data planeada e prazo de entrega são conceitos distintos para a 2.0; ainda não há campos independentes. Não reinterpretar o histórico.
- Testes usam SQLite em memória ou ficheiros temporários sintéticos; nunca TudoAkiDatabase.local(). Uma cópia Git protege código, não os dados dos dispositivos.

## Produto 2.0 — navegação e tarefas
- Destinos previstos: **Hoje, Planear, Metas, Mais**. Percurso é acessível na aplicação, sem separador obrigatório. Preservar acesso à lista de Tarefas e a todas as áreas; não eliminar funções para reduzir a navegação.
- Planeamento manual e opcional: amanhã, qualquer dia ou semana. Permitir tarefas sem data e reagendar as existentes preservando ID, sem cópias em Hoje/Planear/Tarefas.
- Só o título da tarefa é obrigatório. Dia, hora, lembrete, prioridade e associações são opcionais. Um dia seleccionado no contexto pode ser preenchido automaticamente.
- Criação rápida em painel inferior; após guardar, tornar a tarefa imediatamente visível. Edição reutiliza o registo. Prever correcção/desfazer quando aplicável, sem prometer desfazer onde ainda não existe.
- Metas têm associações opcionais a tarefas e outras áreas. Concluir uma tarefa não altera automaticamente a métrica da meta.

## Identidade visual futura
Sage #9ECB8F; Mineral #ABAFB0; verde profundo #456C50; grafite #202B29; fundo claro #F7F8F5; superfície suave #E8EDE6.
Usar tokens semânticos e WCAG AA: texto normal 4,5:1, texto grande 3:1, elementos essenciais da interface 3:1. Não usar Sage ou Mineral como texto normal sobre branco. Definir e verificar separadamente o tema escuro; não inferir cores sem validação.

Identidade sofisticada, expressiva e com personalidade: tipografia e detalhes cuidados, hierarquia clara, espaço de leitura e efeitos moderados. Manter uma acção principal por contexto, informação avançada progressiva e estados vazios accionáveis. Evitar gradientes gratuitos, sombras fortes, bordas grossas e ícones sem função. O cuidado visual não deve comprometer a usabilidade.

Inter e Newsreader locais continuam a base disponível; assets em assets/fonts e assets/logo. Não instalar pacotes de SVG/ícones por sugestão histórica sem necessidade demonstrada. Cores e recursos nativos actuais permanecem inalterados nesta fase.

## Percurso — contrato futuro
Linha temporal ramificada, constelações, marcos pessoais, capítulos de evolução, animações discretas e identidade Sage & Graphite. Não usar XP como única fonte histórica. Não inventar títulos ou acções ausentes dos registos legados. Não penalizar descanso/ausência; respeitar a preferência de gamificação. Preservar XP e conquistas actuais nesta fase. Representações visuais precisam de alternativa textual acessível e respeito por movimento reduzido.

## Arquitectura e qualidade
Flutter/Dart, Riverpod para dados/serviços, Cubits para selecções efémeras, GoRouter, Drift/SQLite com SQL explícito. Não migrar o estado ou o armazenamento por preferência pessoal. Reutilizar regras existentes e centralizar o tema em lib/core/theme. Sem dependências desnecessárias.

Executar quando o ambiente estiver preparado: flutter analyze --no-pub; flutter test --no-pub; flutter build apk --debug --no-pub. Registar a referência antes das alterações e os resultados posteriores, sem ocultar falhas. Distinguir testes novos não executados de testes aprovados. Não consolidar defeitos conhecidos como requisitos; documentar a regressão desejada.

Validar claro/escuro, 360 px, texto a 200%, contraste, TalkBack, teclado e áreas de toque. Execução automatizada não certifica notificações, reinício, assinatura/actualização ou dados de um telefone. iOS/web não estão preparados na referência actual.

Documentos da Fase 1: docs/V2_CONTRACTS.md, docs/RESTORE_PLAN.md e docs/PHASE1_REPORT.md.
