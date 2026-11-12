# Acessibilidade — contrato revisto e alcance verificado

WCAG 2.2 AA e WCAG2ICT como referências; 2.4.13 é referência reforçada AAA, não requisito AA. O padrão interno de toque é **48×48 dp Flutter**, mais forte do que o mínimo 24×24 CSS px de WCAG 2.5.8. CSS px do browser, dp lógicos e píxeis físicos são diferentes; os ensaios desta fase usam CSS px. Não há alegação de conformidade integral.

## Componentes, foco e toque

| Componente | Mínimo dp proposto / disposição | Estado e semântica | Foco por teclado |
| --- | --- | --- | --- |
| Botão principal / secundário / Guardar outra | 48×48, altura intrínseca e texto integral; 8 entre acções; + 56×56 | Nome explícito, disabled/busy; primaryBorder 1 dp; sem mudar dimensão ao pressionar | Anel 2 dp + intervalo 2; foco interior onAccent no Sage; Enter/Espaço |
| Campo / moeda / período | Campo ≥56 de altura; opção/seta ≥48×48 | Rótulo persistente, ajuda e erro associado; moeda lida com valor | Tab/Shift+Tab; erro após envio foca primeiro inválido; setas do campo não sequestradas |
| Checkbox/radio/switch | Wrapper/rótulo ≥48×48; glifo 22–24 pode ser menor | checked/disabled, nome da acção, sem duplicar rótulo/linha | Espaço alterna; radio por setas nativas; foco não depende da cor |
| Linha editável e menu | ≥48 de altura, nome quebra; subacção 48×48 separada | Título, dia/origem e estado acessíveis; alvo não engloba checkbox com outra acção | Foco no alvo correcto, sem sobreposição com FAB/barra |
| Dia/selector de vista | Cada alvo ≥48×48; faixa horizontal pode deslocar | Data completa e seleccionado/hoje; sem data não vira meia-noite | Ordem lógica, selecção distinta de foco; picker nativo a validar |
| Navegação inferior | Quatro destinos, cada um ≥48×48, rótulo sempre visível; altura cresce a 200% | Hoje/Planear/Metas/Mais, seleccionado por forma+texto, sem quinto destino | Foco independente, anel interior quando necessário; sem recorte pelo bordo |
| Expansão / campos revelados | Cabeçalho ≥48 de altura, não só o chevron | expanded e nome/contagem verdadeiros; valores não se limpam ao recolher | Foco fica no disparador; campos seguintes entram na ordem |
| Diálogo | Acções ≥48×48, coluna em largura estreita ou texto ampliado | Nome e consequência completos, fundo inacessível enquanto modal | Acção segura inicialmente; ciclo dentro do modal, Esc/Voltar no superior; retorno ao disparador |
| Glass/mapa | Nenhuma informação depende de tocar no desenho; eventual nó interactivo teria 48×48 | Mapa decorativo com descrição, lista equivalente sempre consultável | Desenho não cria paragens sem função; lista dá todo o acesso |
| Erro/vazio/carregamento | Acção de recuperação ≥48×48 | Erro não anunciado como zero/vazio; status moderado e sem roubar foco | Tentar novamente mantém contexto; mensagem vinculada ao campo/área |

Ordem visual = ordem de foco/semântica. No formulário: cabeçalho/Cancelar → nome → dia/prazo → contexto herdado → opções reveladas → Guardar/Criar → Guardar outra quando disponível. No diálogo destrutivo, Cancelar/Continuar antes da consequência. Ao revelar campos numéricos, manter o foco no selector e deixar os campos na sequência seguinte; não saltar inesperadamente ao enviar.

## Viewport, texto 200% e teclado

Maquetas de 800 CSS px de altura com corpo rolável, rodapé e navegação em áreas próprias. Texto realista/valores longos, nomes e rótulos sem ellipsis obrigatório. A 200% botões crescem e modos podem passar a mais linhas; a barra inferior não esconde rótulos ou reduz fonte. O ensaio nativo terá de decidir se a quebra de «Planear» a 320 dp mantém leitura confortável; não prometer compreensão só por não haver overflow.

Teclado de 280 CSS px **simulado** em formulários; não desenha nem exercita uma IME Android. Ao focar um campo, scroll aproxima-o da área útil sem o deixar sob rodapé/FAB. O contrato 4A de fallback para uma superfície rolável em janelas muito baixas mantém-se: não substituir por uma barra fixa que provoque overflow em horizontal. O protótipo não ensaiou a matriz nativa horizontal/gestos e essa verificação é gate da 4C.3.

## Contraste, clay, glass e preferências

[CONTRAST.md](CONTRAST.md) e calculador verificam texto normal ≥4,5, gráficos relevantes ≥3 e text crítico ≥7 nos fundos especificados. Sombras clay são decorativas, sem opacidade do grupo. Glass: layer a 90% em background/surfaceSoft conhecidos, composição antes da luminância; sem confiar no blur. Alternativa surface sólida disponível e verificada no browser. Sem glass atrás de campos, barra ou valores financeiros.

Movimento reduzido e transparência reduzida são preferências diferentes. A maquete tem desenho estático e nenhuma informação depende de animação; reduced-motion desliga transições. A preferência de transparência, quando suportada, e a opção de revisão «Fundo sólido» removem o blur/layer. A futura implementação Flutter deve consultar os sinais realmente disponíveis e ter fallback sólido sem depender de uma API ausente. Nenhuma animação nova foi implementada na app.

## Evidência e limites

O registo [validation.json](validation.json) separa dimensões/viewport, foco, modal, nomes no Chromium, movimento e fallback. Uma árvore de acessibilidade Chromium com nomes correctos não é um ensaio TalkBack. O protótipo Web usa diálogo e ciclo de foco de demonstração; GoRouter, ModalNavigationGuard e FocusScope Flutter não foram alterados ou certificados.

Ainda necessários na implementação autorizada: testes widget de alvo/foco/ordem, contrastes dos pixels renderizados e estados, TalkBack real, teclado físico, IME, SafeArea, gestos, orientação horizontal, brilho/sol, desempenho do blur e actualização/assinatura. Preservar todos os testes de regressão 3B/4A/4B; testes automatizados não dispensam observação manual.
