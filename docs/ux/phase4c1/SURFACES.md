# Claymorphism subtil e glassmorphism controlado

## Escolha de superfície

| Uso | Superfície | Limite |
| --- | --- | --- |
| Formulários, listas, movimentos, navegação e tabelas | Plana, surface/background | Sem blur/relevo; fundos opacos; bordas funcionais outline |
| Meta em destaque, hábito e disciplina | Clay: base opaca surfaceSoft, raio 20, padding 16 | Máximo um nível de relevo; não envolver uma lista inteira de cartões clay nem aninhar clay em clay |
| Percurso conceptual / painel decorativo especial | Glass calculado, com alternativa sólida | Nunca formulário, barra principal, saldo, erro, modal de confirmação ou lista de movimentos |

A identidade vem de tipografia, proporções e informação. Efeitos não comunicam estado, valor ou disponibilidade. Não transformar cada fila num objecto elevado.

## Receita clay proposta

Fundo **opaco** surfaceSoft. Texto text/textMuted e controlos com cores da whitelist, sem aplicar opacidade ao grupo. Raio 20 dp. Claro: sombra exterior Graphite 8%, deslocamento (0,3), blur 10, spread 0; brilho superior branco 45%, (0,-1), blur 2, apenas na borda interior. Escuro: sombra preta 16%, (0,3), blur 10; brilho darkInk 6%, (0,-1), blur 2. Estas misturas são decorativas e não ficam atrás do texto/controlos; não são pares funcionais aprovados. A borda outline mantém contraste se a forma for necessária para reconhecer o alvo.

Se houver efeito de relevo interior, limitá-lo a 1 dp junto à aresta, sem modificar a zona plana de leitura. Pressão não afunda texto nem muda a sua geometria; selecção/foco têm indicadores independentes. Máximo uma sombra suave e um brilho; sem gradiente na área de leitura. Sem animação das sombras.

## Receita glass proposta e calculada

Claro: layer #FFFFFF a alpha **0,90** sobre background ou surfaceSoft. Escuro: layer #202B29 a alpha **0,90** sobre background ou surfaceSoft. O CSV/Markdown de contraste calcula os dois fundos e o resultado composto por canal sRGB, antes da luminância. O token glass usa a composição sobre surfaceSoft como instância de referência; os dois casos são avaliados. Texto text/textMuted e outline são calculados contra cada composição; action/foco só se aprovado na whitelist.

Blur opcional 12 dp é decorativo; o cálculo não assume que blur aumenta contraste. Raio 20, borda outline quando funcional. A camada é isolada: nada de nó, texto ou imagem pode passar por trás da zona de leitura. Não aceitar fotografias, vídeo, gradientes animados ou uma constelação arbitrária como fundo efectivo. Um novo fundo exige nova composição/cálculo e nova aprovação. Não reduzir alpha durante animação mantendo texto visível.

Fallback sólido: surface no mesmo tema, com o mesmo conteúdo, espaçamento e ordem semântica. Activar se fundo não puder ser garantido, transparência/efeitos reduzidos, alto contraste ou limitação de desempenho. A preferência por glass nunca prevalece sobre legibilidade. A opção sólida deve continuar visualmente cuidada.

## Proibições e validação futura

Não usar branco sobre Sage, Mineral como texto/contorno essencial sobre branco, sombras como única fronteira, blur sobre formulários ou transparência do cartão inteiro. Não usar brilho para simular recompensa/XP. Sombra decorativa e cor de marca não dispensam cálculo dos pares funcionais.

Antes de implementação: comparar claro/escuro a 100/200%, medições de contraste dos pixels efectivamente renderizados e foco, leitura em sol/brilho reduzido, movimento/transparência reduzidos e desempenho em Android modesto. Não se certificou o efeito por renderização Flutter nesta fase.
