# Foco, toque, semântica e adaptação

## Cobertura em toda a aplicação

O inventário abaixo aplica-se a todas as rotas, não só aos módulos em redesenho. [GLOBAL_COMPONENTS.md](GLOBAL_COMPONENTS.md) explicita ordem de foco e alvos de Agenda, Planear, Hoje, Tarefas, Hábitos, barra inferior, todos os editores e diálogos. [GLOBAL_CONTRAST.md](GLOBAL_CONTRAST.md) liga estes componentes à matriz calculada.

## Referência e unidades

WCAG 2.2 AA: 1.4.3 texto 4,5:1 / grande 3:1, 1.4.11 gráficos/controlos relevantes 3:1, 1.4.4 ampliação, 1.4.10 reflow, 2.1.1 teclado, 2.4.3 ordem, 2.4.7 foco visível, 2.4.11 foco não totalmente encoberto (mínimo), 2.5.8 tamanho de alvo, 4.1.2 nome/função/valor e 4.1.3 mensagens de estado. Referência reforçada: 2.4.13 (AAA), não exigência AA. Consultar [WCAG 2.2](https://www.w3.org/TR/WCAG22/). Para uma app nativa, usar também a orientação [WCAG2ICT](https://www.w3.org/TR/wcag2ict-22/); não chamar a uma simples conversão de dp uma certificação Web.

**dp Flutter** aqui significa unidade lógica de layout; píxeis físicos dependem do devicePixelRatio. **CSS px** é a unidade de layout dos protótipos Web; não é píxel físico e não garante um dp em todos os contextos. O mínimo AA 2.5.8 é 24×24 CSS px com excepções, não 48 dp. A Tudo aki adopta um requisito interno mais forte: **48×48 dp em todos os controlos**, incluindo dias de calendário, caixas de conclusão e ícones. Não se propõe excepção <48; qualquer futura excepção <44 exige justificação e alternativa acessível, sem reduzir o critério AA aplicável. O ícone visual pode ter 20–24 dp; a área activável/semântica não.

## Contrato de foco

Anel 2 dp contínuo, afastamento 2 dp, sem ser cortado por clip do cartão; reservar 4 dp exteriores e rolar o item completamente para a área útil. action contra background/surface/soft conforme matriz. Em Sage usar também contorno interno onAccent, evitando um anel Sage sobre Sage no escuro. A borda de erro não substitui o foco. O anel não depende de sombra; selecção usa visto/forma e rótulo, pressão usa contorno, desactivação tem semântica distinta.

Tab/Shift+Tab percorrem ordem de leitura; Enter/Espaço activam botões e toggles; setas deslocam selecção em grupos nativos (dias, modos/radio), sem sequestrar setas de edição de texto; Esc/Voltar fecha primeiro o picker/diálogo superior, respeitando rascunho/guard. Não criar armadilhas de foco. Ao abrir folha: foco no nome se for acção explícita de criação; leitor anuncia o título. Ao fechar: regressar ao disparador, ou ao cabeçalho/lista se foi removido. Erro após envio move para o primeiro campo inválido e anuncia mensagem sem repetir a página.

Ordem dos formulários: título/nome → dia/prazo → associações herdadas → Mais opções/Acompanhamento → campos revelados → acção principal → acção secundária quando visível. O acesso Cancelar deve ser alcançável na ordem inicial do cabeçalho. Não alterar a ordem visual com CSS/Flutter mantendo outra ordem semântica. Ao expandir: foco mantém-se no disparador, campos seguintes entram na sequência; ao recolher com foco num descendente, devolver ao disparador. Tooltip não é a única instrução disponível.

## Inventário de controlos e alvos

| Controlo | Dimensão mínima dp / separação | Foco e activação | Nome, função, valor / resultado |
| --- | --- | --- | --- |
| Primário/secundário/Guardar outra | 48 de altura e largura; preferir 56 nos formulários; 8 entre acções | Anel 2+2, Enter/Espaço; sem duplo envio | Rótulo integral; enabled/busy; confirmação inline |
| FAB de Metas | 56×56; 8 livres e espaço no layout | Anel exterior + interior; retorno ao disparador | «Criar meta», botão; abre directamente formulário |
| Voltar, editar, eliminar, menu, setas de mês | 48×48; 8 entre ícones | Anel 2+2; tooltip ao foco/hover | Verbo + objecto («Editar sessão Revisão»); eliminação confirma |
| Caixa de hábito/etapa/tarefa, switch pausa | 48×48 por alvo; rótulo pode ampliar o mesmo alvo | Anel 2+2; Espaço alterna uma vez | Nome + checked/paused/disabled; não duplicar com ListTile pai activável |
| Navegação principal | ≥48 de largura/altura por destino, rótulo visível; 4 destinos | Foco independente da selecção; setas só segundo comportamento nativo | Nome/destino/seleccionado; bloqueada durante modal conforme guard |
| Activas/Alcançadas, modo de meta, chips | ≥48×48 por opção, 8 entre grupos | Anel; radio/tab nativo e setas dentro do grupo | Grupo nomeado, seleccionado; sem cor como único sinal |
| Cabeçalho expansível | ≥48 de altura e largura, toda a linha | Anel, Enter/Espaço | «Disciplinas, 3, recolhido/expandido» |
| Campo nome/número e selector de moeda | ≥56 de altura e 48 largura, largura útil; rótulo persistente | Borda+anel; teclado adequado; sem enviar ao navegar | Nome, ajuda, valor, erro; moeda lida com o valor |
| Dia/data/hora/Retirar dia | ≥48×48, grelha pode reflow/rolar com rótulo | Dia focado visível; setas/picker nativo; Retirar separado | Data completa e seleccionado; sem hora implícita |
| Registar progresso / Concluir meta / Reabrir | ≥48×48, 8 entre acções | Anel e confirmação quando há consequência | Resultado explícito, valor/unidade se numérico; não «Aumentar» sem referência |
| Linha tocável de meta/movimento/entrega | ≥48 de altura, sem altura máxima | Anel em redor da linha; subacções independentes fora do alvo pai | Nome, estado, prazo/origem; resumo não duplica textos filhos |
| Nó de constelação conceptual | 48×48, sem sobreposição | Ordem cronológica, Enter abre detalhe | Data/tipo verificado; lista equivalente sempre disponível |
| Tentar novamente / selector de período / Ver todos | ≥48×48 | Anel, retorno preserva contexto | Acção concreta, resultado/estado anunciado |

Barras informativas, valores e ilustrações decorativas não são controlos de foco; se um gráfico passar a ser interactivo, recebe o contrato de nó/linha. O foco de um controlo desactivado sai da sequência de Tab; o leitor pode encontrar a razão no contexto, sem botão fingidamente activável.

## 200%, ecrãs pequenos e teclado

Validar 320, 360 e 390 dp em vertical e horizontal, ambos os temas, texto 100/200%, SafeArea, navegação por gestos/3 botões e teclado visível. Campos e rótulos crescem; acções passam a coluna; secções não fazem overflow horizontal. Valores monetários não desaparecem nem perdem sinal/unidade; prefixo «MZN»/«MT» deve continuar identificável. Título longo quebra em linhas; o campo pode rolar texto horizontal durante edição, mas nunca substitui a leitura integral semântica.

Rodapé segue o contrato 4A: campos roláveis e botões acessíveis; quando a altura útil não suporta separação, toda a folha rola. Acrescentar espaço inferior real, não sobrepor alvos. scroll para foco inclui teclado, barra e quaisquer acções sobrepostas. Requisito interno: controlo focado **inteiramente** visível sempre que caiba na área útil (mais forte do que 2.4.11 mínimo); se for maior, manter visíveis rótulo, posição de edição e acesso ao resto por scroll. Não reduzir fonte para resolver.

Leitor de ecrã: títulos semânticos, ordem lógica, nomes únicos, erro associado ao campo, rótulo anunciado antes do valor, ausência de duplicação de cartões/filhos, estados checked/expanded/selected e mensagens liveRegion moderadas. Glass/linhas decorativas excluídos; actividade tem alternativa textual. Testar TalkBack real, exploração por toque e teclado físico; VoiceOver quando houver plataforma preparada.

## Movimento e contraste

Não bloquear funções com animações desactivadas. Sem flash ou indicadores contínuos decorativos. Alto contraste/reduzir transparência, quando disponíveis no sistema, forçam fundo sólido. Na ausência de API fiável, o glass tem fundo sólido seguro como comportamento por defeito. Nenhum foco passa em cima de fotografia ou conteúdo de cor desconhecida. Contraste matemático não valida nomes acessíveis, contraste de ícones renderizados nem conforto visual real.
