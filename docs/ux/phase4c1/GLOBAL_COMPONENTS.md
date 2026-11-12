# Componentes globais — aplicação dos tokens, foco e toque

Complementa DESIGN_SYSTEM, ACCESSIBILITY e SURFACES. Os nomes são contratos de design; não são classes novas. A mesma máquina de estados é usada em todos os módulos, incluindo widgets legados activos. A actualização visual não deve substituir serviços nem inventar uma segunda biblioteca por módulo.

## Matriz global de componentes

| Componente / instância actual | Utilização global | Pares de contraste autorizados | Foco / estado | Alvo mínimo Flutter |
| --- | --- | --- | --- | --- |
| PageHeading / AppBar — WorkspacePage, AreaScaffold, LegacySectionPage | Hoje, áreas secundárias, detalhes | text e textMuted sobre background/surface | Cabeçalho sem foco; Voltar com anel 2+2 | Voltar/menu 48×48 dp |
| BottomNavigation — NavigationBar | Quatro destinos principais, Tarefas em Mais | action/text/textMuted sobre surface; foco focus/surface | Forma+texto para selecção; anel independente; bloqueada em modal | Cada destino ≥48×48; altura cresce com rótulo |
| CreateAction — botão no cabeçalho/FAB/rodapé | Hoje, Metas, Planear, Tarefas, Agenda | onAccent/accent; foco exterior focus/fundo pai, interno onAccent/accent | Localização e percurso existentes preservados; busy impede repetição | + de cabeçalho/FAB 56×56; rodapé ≥48 |
| TaskRow / PlannerTaskTile / CommitmentRow | Hoje, Planear, Tarefas, Agenda, detalhe de meta/Estudos | text/textMuted em background/surface; outline identifica caixa | Conclusão checked + nome, linha editável independente; data/hora/origem integrais | Checkbox 48×48; linha ≥48 de altura; menu 48×48 |
| DayStrip / PeriodPicker / ModeSelector | Agenda, Planear, diálogos de datas/horas | action e text em surfaceSoft para seleccionado; outline/fundo na fronteira | Hoje, seleccionado e foco têm marcadores distintos; radio/tab/picker nativo, sem mudar algoritmo | Dia/intervalo/seta/opção ≥48×48 |
| WeekDayPanel / InsetGroup / SectionDisclosure | Sete dias de Planear, lista Tarefas, Mais, Revisões | text/textMuted sobre surface; outline funcional sobre fundo | Um dia expandido mantém contrato; ícone expandido + semântica; foco no cabeçalho | Cabeçalho e expansão ≥48; espaço para anel |
| HabitTile / SubjectTile / GoalSummary clay | Hábitos, disciplinas, metas em destaque | text/textMuted/action/outline sobre clay | Checked/pausa/modo por texto; foco não depende da sombra | Cada acção independente 48×48; cartão cresce |
| Field / Dropdown / Switch / FormSheet | Todos os editores, Definições, reagendamento | text/textMuted/outline sobre surface; hover/disabled sobre surfaceSoft | Rótulo permanente; anel 2 dp, erro ícone+texto; dropdown aberto mantém foco | Campo ≥56 de altura; item/switch/Retirar ≥48×48 |
| Dialog / ConfirmAction | Descartar rascunho, eliminar, apagar dados, recorrências | text/textMuted sobre surface; destrutivo error/errorSurface com contorno error | Foco inicial na acção segura; modal isola fundo; recuperar disparador ao cancelar | Botões ≥48×48, separados 8 dp; coluna a 200% |
| InlineStatus / SnackBar / Retry | Todas as áreas | text sobre surface/surfaceSoft; erro error/errorSurface | Anúncio moderado, sem roubar foco; acção nomeada; nunca duplicar registo por aviso | Tentar novamente/acção ≥48×48 |
| GlassPanel / ActivityAlternative | Exploração opcional de Progresso | text/textMuted/outline contra glass composto aprovado | Decoração fora da semântica; acções ficam na lista equivalente, sem tocar em pontos pequenos | Acção/nó interactivo, se autorizado, 48×48 |
| Empty / Loading | WorkspaceData e LegacySectionPage em qualquer rota | text/textMuted em background/surface | Nome de estado, erro distinto de vazio; sem shimmer obrigatório | Acção de criação/recuperação ≥48×48 |

Na barra inferior, um anel interior de 2 dp com espaço de 2 dp para o limite pode substituir o anel exterior para evitar recorte no bordo da área segura; mantém contraste, distinção da selecção e alvo integral. O protótipo representa esta variante com contorno interior, sem certificar o desenho nativo.

## Estados observáveis nos protótipos globais

Catálogo próprio com normal, hover/pressão via rato, foco por teclado, seleccionado/checked, desactivado, erro com mensagem e «A guardar…». Botões usam superfície opaca; não há overlay cromático novo. Foco com anel exterior de 2 CSS px no protótipo é apenas representação do contrato **2 dp Flutter**. Textos e ícones usam os pares já calculados; iconografia dos esboços é conceptual, sem introduzir biblioteca.

Normal: contorno outline. Hover: surfaceSoft. Pressão: contorno reforçado, sem afundar texto. Seleccionado: forma/visto e rótulo. Foco: action, 2 dp e separação 2 dp, visível ao teclado; não se confunde com a borda de erro. Desactivado: textMuted/surfaceSoft, sem opacidade geral; não activável. Busy: mensagem, sem novo envio. Erro: error sobre errorSurface + ícone e texto, foco do campo mantém-se. Um componente em erro pode estar focado; o anel exterior assenta no fundo pai normal, não num fundo desconhecido.

O botão destrutivo usa error/errorSurface para texto e contorno, ambos já cobertos pelos cálculos, não onAccent num fundo vermelho não calculado. O contorno error também distingue o botão do fundo surface. Não usar cor sozinha para significar eliminar: o verbo e o objecto são explícitos. Diálogos não têm clay ou glass. Nos protótipos são mostrados isoladamente, sem fingir uma barreira nativa ou alterar os contratos de fecho do Editor legado.

## Diálogos e formulários: conteúdo antes de aparência

Descartar: «Só o rascunho actual será descartado»; Continuar a editar versus Descartar, preservando tarefas já guardadas. Eliminar meta: manter aviso de que etapas/histórico serão removidos e tarefas/hábitos/submetas preservados sem ligação. Apagar dados: consequência irreversível e exportação não apresentada como restauro garantido. Confirmações financeiras conservam revisão de vencimentos, não uma aprovação automática ao abrir.

Foco inicial deve ir para Cancelar/Continuar nas acções destrutivas, sem activação automática; picker aninhado fecha primeiro; resultado devolve o foco ao disparador ou a um local estável se o registo deixou de existir. Barra/FAB fora do modal não ficam activáveis ou na sequência de teclado. Este é contrato proposto de acessibilidade, não afirmação de que todos os AlertDialogs actuais já o cumprem.

Os formulários de evento, hábito, etapa, revisão, disciplina/avaliação/horário/sessão, transacção/poupança/orçamento/recorrência, edição completa de tarefa/meta e reagendamento partilham os mesmos tokens, foco e dimensões. A sua lista de campos, validações, enums, formatos, cancelamento e retorno não se unifica à força. O contrato específico 3B/4A/4B continua prioritário na criação rápida.

## Cobertura de contraste global

Consultar [CONTRAST_MATRIX.md](CONTRAST_MATRIX.md): **578 pares, 92 utilizações funcionais**. A adenda não cria cores ou combinações funcionais adicionais. [GLOBAL_CONTRAST.md](GLOBAL_CONTRAST.md) apresenta os mínimos calculados para as famílias usadas nos novos ecrãs e a correspondência por componente. Shadows clay são decorativas; glass é composto antes da luminância. Mineral continua sem papel funcional de texto ou fronteira essencial.

## Dimensões e ordem de foco dos novos contextos

Hoje: + do cabeçalho → modos → Ver dia → compromissos → Adicionar tarefa/linhas → expansões/hábitos → atalhos; ordem visual e semântica coincidem. Planear: vistas → filtro → data/período → linhas/acções → rodapé. Agenda: Voltar quando secundária → período/modo → faixa de dias → linhas; consulta não escreve. Tarefas: filtros → caixas/linhas → +; Hábitos: Criar hábito → conclusão/edição de cada registo. Mais: nove entradas pela ordem actual. Definições: aparência → moeda → gamificação → exportar → apagar.

Todos os alvos mínimos internos são 48×48 dp, independentemente de ícone visual 20/24 dp. Separação de 8 dp entre acções independentes; a barra inferior pode ter alvos contíguos largos e sem sobreposição, em vez de margens que tornem cada destino pequeno. Não cabeçar grelhas de calendário com sete alvos de 48 dentro de 280 dp: conservar deslocação horizontal da faixa ou solução acessível nativa; não encolher os dias. Calendarização 320/200%, foco visível, SafeArea e teclado exigem teste Flutter futuro, não apenas browser.
