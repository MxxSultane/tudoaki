# Design System 2.0 — proposta normativa

## Âmbito global da identidade

Esta especificação abrange toda a aplicação. A [adenda global](GLOBAL_IDENTITY.md) define A/B/C por ecrã, incluindo os fluxos aprovados; os [componentes globais](GLOBAL_COMPONENTS.md) aplicam a mesma identidade a navegação, calendários, formulários e diálogos. O [conjunto global de protótipos](GLOBAL_PROTOTYPES.md) é a referência de avaliação conjunta. Não se limita aos quatro módulos inicialmente auditados.

Esta especificação acrescenta uma direcção futura ao [sistema actual](../../DESIGN_SYSTEM.md), sem o substituir em produção. A matriz e tokens JSON são a fonte das cores propostas; o código Flutter actual continua a ser a fonte do comportamento existente.

## Princípios e tokens

Uma acção principal por contexto; dados antes de decoração; informação progressiva sem esconder riscos essenciais. Conteúdo em português europeu, preferindo a grafia pré-AO90; rótulos concretos, sem métricas de produtividade inventadas. Usar a escala do sistema, não bloquear o tamanho de letra.

| Token | Claro | Escuro | Utilização |
| --- | --- | --- | --- |
| background | #F7F8F5 | #18201D | Fundo da página |
| surface | #FFFFFF | #202B29 | Formulário, navegação, lista e folha |
| surfaceSoft / clay | #E8EDE6 | #28352E | Pressão/hover suave, destaque especial clay |
| text | #202B29 | #F2F5EF | Nome, corpo, valores críticos |
| textMuted | #5D6965 | #BCC6BE | Metadados legíveis; nunca reduzir opacidade |
| action / focus | #456C50 | #9ECB8F | Acção textual, estado seleccionado, foco exterior |
| outline | #66736D | #8E9D92 | Contorno funcional e limites essenciais |
| accent | #9ECB8F | #9ECB8F | Botão principal; não texto sobre branco |
| onAccent | #202B29 | #202B29 | Texto/ícone do botão Sage, nos dois temas |
| error | #9E2A2B | #FFB4AB | Ícone + mensagem de erro |
| errorSurface | #FCEAEA | #442629 | Erro inline; sem transparência |
| decorationMineral | #ABAFB0 | #ABAFB0 | Detalhe sem significado; não informação ou limite funcional |
| glass | Composição branca 90% sobre surfaceSoft | Graphite 90% sobre surfaceSoft | Apenas painel decorativo nas condições de SURFACES |

Forest/Sage indicam acção conforme o tema, não sucesso financeiro. Informação e sucesso usam text/action com ícone e rótulo; não precisam de novas cores. Vermelho é para erro real, não ausência de actividade. Divisores decorativos podem usar surfaceSoft; contornos que identificam controlos usam outline. A aparência desactivada usa textMuted sobre surfaceSoft e rótulo/contexto, sem opacidade global.

A whitelist de [CONTRAST_MATRIX.md](CONTRAST_MATRIX.md) é fechada: uma nova combinação precisa de cálculo antes de entrar na proposta. Os pares numéricos no CSV não são autorização semântica automática. Os valores críticos usam text (meta interna 7:1); texto de erro claro atinge AA, mas não a preferência 7:1, por isso valores financeiros críticos permanecem text.

## Tipografia e dimensão

Inter Regular/Medium/SemiBold/Bold e Newsreader Bold locais; sem downloads ou novas fontes. Evitar títulos em maiúsculas. Números monetários alinhados à direita só quando a largura permitir, com leitura semântica contínua.

| Estilo | Família / peso | Tamanho lógico / entrelinha | Uso |
| --- | --- | --- | --- |
| Display | Newsreader 700 | 34 / 40 | Um título de página, máximo um por viewport; não repetir AppBar |
| Section | Inter 600 | 22 / 29 | Secções |
| Item | Inter 600 | 18 / 25 | Meta/disciplina; pode quebrar |
| Body | Inter 400 | 16 / 24 | Corpo, campos, valores |
| Action | Inter 600 | 16 / 24 | Botões e opções |
| Caption | Inter 400–500 | 13 / 19 | Metadados não essenciais isolados; nunca texto de erro ou valores críticos |

Estas dimensões são propostas em unidades lógicas Flutter; não estabelecer altura fixa pelo tamanho inicial. Escala 200% mantém texto integral e botões com altura intrínseca. Não usar auto-redução de fonte, ellipsis para informação necessária ou truncagem de rótulos. Texto grande WCAG tem limiares em pontos/CSS equivalentes; não presumir que «18 dp bold» qualifica: **todos os rótulos propostos usam pares que passam 4,5:1**.

Espaços: 4, 8, 12, 16, 24, 32 dp; margem lateral 20 dp a partir de 360, 16 dp a 320. Conteúdo máximo 720 dp; uma coluna até 599 dp; a partir de 600 pode haver duas colunas somente em resumos, nunca ordem de leitura ambígua. Campo/botão com altura mínima 56/48 dp, crescendo com o texto; separação mínima 8 dp entre acções independentes. Ícones 20/24 dp dentro de alvos 48 dp. Sem grelha rígida de cartões para listas longas.

Raios: campo 12, botão 14, cartão normal 16, clay 20, folha 24 no topo. Elevação operacional zero; clay/glass têm receitas limitadas em SURFACES. Borda funcional 1 dp; foco 2 dp e selecção 2 dp. Não usar sombra para identificar um controlo.

## Catálogo de componentes reutilizáveis propostos

Nomes descrevem contratos futuros, não novas classes implementadas.

| Componente | Composição / contrato |
| --- | --- |
| PageHeading | Um título + contextualização curta; voltar 48 dp nas áreas secundárias |
| SectionDisclosure | Cabeçalho expansível com nome, contagem real e estado expandido; alvos 48 dp |
| PrimaryAction / SecondaryAction / IconAction | Mesma máquina de estados e foco em ACCESSIBILITY; ícone isolado exige nome/tooltip |
| Field / OptionalDay / DeadlineDays | Rótulo persistente, ajuda, erro abaixo; Sem data/Retirar data; nenhum placeholder como único nome |
| FormSheet | Cabeçalho, corpo rolável, acção principal acessível, teclado e descarte preservados |
| GoalSummary | Nome, modo, prazo se existir, estado/resultado e próximo passo; clay opcional; não acumular várias acções dentro de um alvo de cartão |
| SubjectTile / HabitTile | Identidade clay moderada, nome e informação útil; conclusão/pausa/edição com alvos separados |
| MovementRow / UpcomingRow | Superfície plana, texto primário/secundário, origem, sinal/moeda ou data; edição por acção nomeada |
| ActivityWeek / ProgressValue | Contagens/resultados com alternativa textual; barra só para valor numérico significativo |
| InlineStatus / EmptyState / LoadingState | Mensagem junto do conteúdo, acção de recuperação contextual; anúncio sem roubar foco |

## Estados comuns

| Estado | Representação e comportamento |
| --- | --- |
| Normal | Plano; borda outline quando necessária; rótulo completo |
| Hover | Fundo surfaceSoft, sem depender de hover para descobrir acções |
| Pressionado | Contorno 2 dp + alteração breve de superfície; botão Sage mantém accent/onAccent, sem mistura de cores |
| Foco | Anel exterior action 2 dp, intervalo 2 dp de fundo pai; no botão preenchido, contorno interno onAccent; não desloca layout |
| Seleccionado | Visto/indicador geométrico + texto/semântica; preenchimento soft; não confundir com foco |
| Erro | error + ícone + mensagem; nome do campo mantido; descrição semântica e foco no primeiro erro após envio |
| Desactivado | surfaceSoft + textMuted + razão quando não óbvia; sem evento activável, sem reduzir opacidade de toda a árvore |
| A guardar | Mesmas dimensões, texto «A guardar…», progresso sem duplicação de anúncios, bloqueio de duplo envio |
| Sucesso | Resultado inline no contexto, não banner global; não alterar XP/estado por animação |

Sem estado novo obtido por overlay translúcido de cor não calculado. O estado pressionado não precisa de movimento. Se um componente pertence a mais de um estado, erro conserva a mensagem, foco conserva o anel, busy bloqueia activação e mantém o anúncio. A precedência lógica é disabled/busy > activação; foco e erro são informação simultânea.

## Estados vazios, erro, carregamento e ilustração

Vazio: título curto, explicação apenas se necessária e uma acção contextual (Criar meta, Adicionar disciplina, Registar movimento); nunca um zero fabricado que pareça falha. Erro de leitura distingue-se de vazio; Tentar novamente preserva filtros/rascunho. Erro de gravação mantém campos e não oferece duplicar um registo já guardado. Skeleton sem shimmer por defeito; região anuncia «A carregar» uma vez. Não substituir nomes/dados carregados por valores fictícios.

Ilustrações opcionais abstractas, no máximo uma no vazio ou no Percurso; removidas da árvore semântica se decorativas. Não contêm texto/valores únicos nem representam progresso inexistente. Ícones Material já disponíveis, 24 dp, traço consistente; não adicionar biblioteca. Ícone relevante precisa de contraste 3:1 e nome acessível.

## Movimento

120–180 ms para feedback de controlo, 200–250 ms para folha/expansão funcional. Sem parallax, brilho contínuo, partículas ou rebotes; sem animação que permita inferir recompensa inexistente. Ao activar movimento reduzido/disableAnimations, transição instantânea ou fade opcional de até 80 ms, nenhum deslocamento decorativo; todas as acções, ordem e informações permanecem. Confirmar comportamento em Flutter futuro, não apenas no protótipo CSS.
