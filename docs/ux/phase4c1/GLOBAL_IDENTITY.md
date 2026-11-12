# Adenda 4C.1 — identidade visual global

**Especificação e protótipos para revisão. Nenhuma implementação autorizada ou iniciada.** A identidade Visual e Premium abrange toda a Tudo aki, incluindo áreas secundárias, estados transitórios e componentes partilhados. A consistência é global; a intensidade da intervenção depende do problema de cada contexto.

## Referência e inspecção complementar

Adenda sobre `71dc8f4f2b9ceffce34b79f28641585d947fe567`, branch `docs/fase-4c1-design-system`, árvore inicialmente limpa. A base de produção continua **79470b80b683dcd2fa60cf2bf16531f884c87e8a**, final da 4B, com as correcções de hábitos, FAB de Metas e criação rápida. Os dois workflows verdes dessa base constam do [índice](README.md). Os 254 testes são evidência da 4B, não uma nova execução nesta adenda documental.

Inspeccionados os componentes activos TodayScreen, PlanningScreen/WeeklyPlannerScreen, TasksScreen/TaskRow, AgendaBrowser, HabitsScreen, AreasScreen/AreaScaffold, ReviewsScreen, SettingsScreen, shell/NavigationBar, WorkspaceData/WorkspacePage/InsetGroup/LegacySectionPage, Editor, QuickTaskSheet e os chamadores de diálogos/pickers. As auditorias 4B de Metas, Estudos, Finanças e Progresso continuam válidas; não se repetiu a investigação de defeitos resolvidos.

Fontes reais revistas para esta adenda: [Hoje 4A](../previews/phase4a/hoje-filled-light.png), [Planear Amanhã](../previews/phase3f/plan-tomorrow-light.png), [Tarefas](../previews/phase3f/tasks-light.png), [Agenda escura](../previews/phase3f/calendar-dark.png), [Hábitos escuros 4B](../previews/phase4b/after/habits-dark.png), [Mais](../previews/phase3f/more-light.png), [Definições](../previews/phase3f/settings-light.png) e [Revisões escuras](../previews/phase3f/reviews-dark.png). Imagens históricas são evidência de estrutura; não são capturas de uma implementação nova. Diálogos foram inspeccionados por código; as imagens novas desses estados são conceptuais.

## Três categorias de intervenção

| Categoria | Pode propor | Não permite por si só | Evidência de aceitação futura |
| --- | --- | --- | --- |
| **A — Actualização visual** | Tokens globais, tipografia, superfícies, contornos, foco, áreas de toque, ícones e espaçamento coerente, mantendo estrutura/ordem e comportamento | Mudar rota, fonte dos dados, ordenação, filtros, retorno, regras de escrita ou retirar acções | Mesmo percurso e mesmos registos/estados antes/depois; regressão visual e acessibilidade |
| **B — Simplificação de UX** | Reagrupar metadados, reduzir redundância, divulgação progressiva, acções secundárias nomeadas, sem perder funções | Esconder definitivamente campos, inferir valores, alterar regras de domínio ou introduzir automações | Inventário de capacidades e teste de descoberta das funções preservadas, rascunho e retorno |
| **C — Redesenho profundo** | Reformular a hierarquia de um ecrã com problema comprovado; repensar resumo/detalhes e acção principal | Reescrever modelos/serviços, cálculos, XP ou navegação principal sob pretexto de design | Comparação da hierarquia, tarefas de uso com pessoas, rastreabilidade de todas as capacidades e regressão de dados |

A categoria define a proposta, **não autorização de código**. Um ecrã pode ter A global e B pontual; C não se propaga automaticamente aos restantes. Ajustes de acessibilidade em fluxos aprovados precisam de evidência concreta e preservação do comportamento, não de um novo conceito de navegação.

## Mapa global de aplicação e auditoria

| Contexto / fonte | Observação actual | Categoria proposta | Identidade aplicada | Estrutura e comportamento que não mudam |
| --- | --- | --- | --- | --- |
| Hoje — TodayScreen | Hierarquia já aprovada; criação integrada no cabeçalho em 4A | **A** | Tipografia/tokens comuns, linhas planas, foco e alvos; hábitos do resumo continuam linhas compactas | Cabeçalho e + com espaço próprio; Dia/Semana/Mês, compromissos, tarefas, anteriores, hábitos, concluídas e atalhos na ordem actual; sem dashboard de cartões, XP ou nova saudação |
| Planear dia/Amanhã/Sem data — PlanningScreen | Quatro vistas e criação contextual já funcionais | **A** | Controlo segmentado plano, dia legível, mesmos TaskRows e rodapé opaco | Hoje/Amanhã/Semana/Sem data, Escolher pendente, evento, reagendar mesmo ID, datas/horas/lembretes e feedback; não introduzir arrastar ou planeamento automático |
| Planear Semana — WeeklyPlannerScreen | Sete dias verticais e um expandido | **A** | Cartões de dia **planos**, contorno/foco comuns, estado seleccionado por marca e texto | Escolha Tarefas/Eventos, intervalo, sete dias, um expandido, rodapé e regra do domingo; não trocar por grelha ou carrossel |
| Tarefas — TasksScreen/TaskRow | Grupo de lista com Pendentes/Concluídas; ordenação existente | **A** | Grupo plano, checkbox e texto com pares comuns; edição reconhecível | Mesmos filtros/ordenação/ID e retorno via Mais; concluir/reabrir não perde nem duplica XP; não virar kanban ou grelha clay |
| Agenda completa e consulta em Hoje — AgendaBrowser | Dia/Semana/Mês, faixa de dias e horas; em /calendar há título repetido | **A**; redução do título duplicado apenas **B opcional**, separada | Calendário/listas planos e opacos; selecção, hoje e foco distintos | Períodos, pickers, blocos/tarefas sem hora, origens académicas, conflitos e criação contextual. A proposta base conserva a repetição de título e não muda a hierarquia; corrigir duplicação exige decisão B explícita |
| Hábitos — HabitsScreen | Tema legado; acesso Criar hábito corrigido em 4B | **A** | Clay subtil no contentor existente, checkbox e editar com alvos separados, pausa por texto | Criar em vazio/preenchido, editar, cue, dias, pausa, meta e contagens; sem novo streak, penalização, recompensa ou limite |
| Metas — GoalsScreen/GoalDetail | Lista simples; métrica universal no detalhe/formulário | **A+B** | GoalSummary clay selectivo; lista/detalhe numérico plano quando denso | FAB directo preservado; binário/etapas/numérico conforme GOALS, sem % artificial. Modos duráveis têm bloqueio de dados separado |
| Estudos — AcademicsPanel | Entregas/disciplinas afastadas por introdução, XP e sessões | **A+C** | Disciplinas clay, entregas e formulários planos; foco activo acessível | Reorganização definida em MODULES; mesmos editores de aulas/avaliações/trabalhos/sessões, mesmas associações e XP |
| Finanças — FinancePanel | Resumo/texto/entradas concorrentes antes de movimentos | **A+C** | Resumo, movimentos e formulários **planos**, números com contraste alto | Mês/moeda, totais, contribuições, orçamentos, recorrências manuais e poupanças; sem cambial ou métricas inventadas |
| Progresso — ProgressScreen | Cabeçalhos repetidos; XP e linhas diárias dominam | **A+C** | Actividade plana; destaque de meta clay; exploração glass opcional | Histórico real e lista equivalente, gamificação opcional, regras de XP; Percurso completo excluído |
| Mais — AreasScreen | Directório de nove entradas, acesso a Tarefas/Agenda | **A** | Lista plana, ícones coerentes quando úteis, margens e foco globais | Ordem/nomes/rotas das nove entradas; sem nova barra, hub de cartões, atalho que substitua uma entrada ou FAB adicional |
| Revisões — ReviewsScreen | Nova e expansões com quatro campos; data ISO visível | **A**; data localizada apenas **B opcional** | Folhas e expansões planas, título/legenda no mesmo sistema | Período, realizações, pendentes, obstáculos e próximos passos, criação e histórico; sem novas estatísticas; protótipo conserva ISO para não insinuar B aprovada |
| Definições — SettingsScreen | Tema/moeda/gamificação e dados locais | **A** | Controlos planos, descrições e avisos legíveis, acção destrutiva identificada | Seguir sistema/claro/escuro, moeda só para novos registos, gamificação, exportação e apagar com confirmação; sem prometer encriptação/restauro/conta |
| Detalhes de meta/submeta, foco de estudo, plano semanal legado | Entradas secundárias com estado/retorno próprios | **A**; B/C só no módulo expressamente identificado | Mesmo cabeçalho/Voltar/rodapé e componentes semânticos | Relações, métricas antigas, retorno/estado vivo, temporizador e operações existentes; não abrir novas rotas |
| Formulários completos de evento/hábito/etapa/revisão, editores académico/financeiro | Diferentes tipos abertos em folhas | **A** | Field/FormSheet e estados uniformes, sempre opacos | Todos os campos, validações, formatos, notificações e confirmação de eliminação; não aplicar o contrato novo de rascunho automaticamente ao Editor legado |
| Criação rápida de tarefa | 3B/4A/4B já simplificada | **A** | Estilo e acessibilidade comuns | Nome/dia opcional, Mais opções, Guardar outra, rascunho, rodapé/scroll e TaskOperations sem reconstrução |
| Criação de meta | Interface exige medidas cedo | **A+B** | Campos progressivos e acção Criar conforme FORMS | Dados legados intactos; modo binário/etapas não é uma migração implícita |
| Diálogos, pickers e selector Criar | AlertDialog, Date/TimePicker e folhas aninhadas | **A** | Superfície plana, foco seguro, acções/avisos completos; sem clay/glass | Conteúdo e consequência reais, ordem de modais, Voltar, cancelamento, guard e bloqueio de duplo envio |
| Carregamento/erro/vazio e mensagens | WorkspaceData/LegacySectionPage e feedback inline/snackbar | **A** | InlineStatus/EmptyState comuns, ícone+texto, foco coerente | Erro não vira zero/vazio; Tentar novamente conserva contexto; avisos de lembrete não se tornam falhas de gravação |

## Gramática visual de toda a aplicação

A mesma semântica cromática, fontes Inter/Newsreader locais, escala tipográfica, margens, raios, ícones e máquina de estados aplica-se a **todas** as rotas. Não manter uma paleta teal nas áreas secundárias e Sage no shell como duas identidades finais. A transição futura pode ser incremental, mas os componentes de destino partilham o contrato; não criar temas independentes por módulo.

**Plano é a base:** navegação inferior, AppBar, folhas, diálogos, calendários, listas de tarefas, entregas, movimentos, preferências e tabelas. Fundo background, contentor surface quando necessário; grupos planos podem manter o contorno existente. Não substituir todos os grupos por cartões novos. Sem glass na barra ou formulários, sem dock flutuante ou texto financeiro em relevo.

**Clay é acento de conteúdo:** meta em destaque, cartões de hábitos existentes e disciplinas. Mantém base opaca e leitura plana no centro; relevo apenas nas arestas, sem cartões clay aninhados. Em Hoje, hábitos continuam linhas compactas para preservar a experiência; a identidade clay é vista na área Hábitos, não imposta ao resumo. Nos detalhes densos, preferir plano ao mesmo elemento decorativo repetido.

**Glass é uma experiência especial opcional:** painel conceptual de Percurso em Progresso, apenas com os fundos calculados e lista equivalente. Não constitui uma terceira paleta nem um convite a aplicar blur em todos os ecrãs. Fallback sólido obrigatório nas condições já definidas. A aplicação deve continuar reconhecível e premium sem transparência.

O contraste [calculado](CONTRAST_MATRIX.md) e a [matriz global de componentes](GLOBAL_COMPONENTS.md) aplicam-se aos três tipos de intervenção. Não foram introduzidas novas cores funcionais pela adenda. Estado seleccionado, focado, pressionado, erro e desactivado têm forma/texto/semântica, não apenas cor.

## Navegação inferior e continuidade

Manter **Hoje / Planear / Metas / Mais**, nessa ordem, ícones de função e rótulos sempre visíveis. Navegação plana surface, nunca glass/clay. Alvo de cada destino ≥48×48 dp; quatro colunas de largura disponível; crescimento vertical para rótulos ampliados sem cortar ou reduzir a fonte. A 320 dp com margens de conteúdo, a barra conserva a largura total da área segura; não herda a margem de 20 dp da lista. Não esconder rótulos a 200%, nem criar uma quinta aba.

Selecção: ícone action, rótulo text com peso 600 e indicador de forma; foco exterior independente em action com 2 dp e intervalo 2 dp. Estado não seleccionado textMuted. O protótipo usa um pequeno traço para tornar o estado distinguível sem cor; é actualização visual, não novo destino. Índice/rota, estado vivo dos ramos e comportamento ao voltar/reseleccionar Mais permanecem. Durante modal, fundo fora da sequência de foco e barra bloqueada pelo guard; o protótipo não altera GoRouter.

Hoje conserva + **no cabeçalho** e o atalho Adicionar tarefa; Planear conserva o rodapé contextual; Metas conserva FAB directo; Tarefas e Agenda conservam os pontos globais existentes; áreas secundárias sem FAB continuam sem FAB. Um estilo comum de botão não significa uniformizar o percurso de criação.

## Transição futura e limites de aprovação

A aprovação desta adenda deve permitir avaliar a identidade como conjunto pelos [protótipos globais](GLOBAL_PROTOTYPES.md), **não aprovar implementação**. Uma futura autorização pode seleccionar A/B/C por linha da matriz. Começar por componentes isolados e estados; aplicar A com regressão dos fluxos aprovados; tratar B e C em entregas próprias, com rastreabilidade de capacidades. Não confundir a adopção global de tokens com uma alteração global de todos os layouts num único commit.

Preservar SQLite v5/lifeos.sqlite, identificador Android, dependências, dados reais, XP, finanças, TaskOperations e rotas. O bloqueio técnico dos modos de meta, os riscos de temporalidade/concorrência/restauro e as limitações de validação nativa permanecem explícitos. Sem código de produção, migração, novos testes Flutter, merge ou Percurso completo nesta etapa.
