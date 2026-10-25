# tudoAki — sistema visual actual

O [AGENTS.md](../AGENTS.md) fornecido rege o esqueleto 0.7.0. O pedido actual (0.8.0) liga a interface aos dados e áreas reais; não há exemplos na aplicação.

| Papel | Claro | Escuro |
| --- | --- | --- |
| Fundo | `#F9FAFB` | `#18181B` |
| Cartões/barras | `#FFFFFF` / `#F3F4F6` | `#27272A` |
| Acento | `#0D9488` | `#10B981` |
| Texto | `#18181B` | `#F9FAFB` |
| Texto secundário | `#6B7280` | `#9CA3AF` |
| Divisores | `#E5E7EB` | `#3F3F46` |

Inter na interface; Newsreader nos títulos grandes. Escala: 34/700, 22/600, 16/400, 13/400. Fontes TTF incluídas localmente com licenças OFL; `google_fonts` não efectua pedidos de rede durante a utilização.

Margens laterais de 20 px; espaçamento em múltiplos de 8 px. Cartões com raio 16 e borda de 1 px, botões 14, campos 12, folhas 24. Elevação zero; sem gradientes, sombras fortes, banners ou ícones ornamentais.

Um único botão principal **+** nos três separadores. As folhas usam Guardar; páginas adicionais abrem sem FAB e têm no máximo uma acção principal. Navegação **Agenda / Metas / Tarefas**, com acento no ícone activo e texto neutro. O acento claro não atinge 4,5:1 para texto pequeno sobre branco, por isso não é usado nos rótulos. O símbolo + usa texto escuro sobre o acento, com contraste superior a 4,5:1.

Listas agrupadas, com separação por espaço e divisores discretos. Em texto ampliado, os títulos das entradas podem ocupar mais de uma linha para evitar cortes; a faixa de dias permite deslocação horizontal. Alvos de toque de pelo menos 44 px. O tema segue o sistema por defeito; a preferência existente pode ser alterada em Mais → Definições.

A navegação principal mantém Agenda/Metas/Tarefas. “Mais” abre um directório discreto de áreas; detalhes são empilhados com Voltar, sem duplicar a barra inferior. Métricas, acções de metas e formulários avançados ficam em detalhes/folhas. Após guardar, a navegação torna o registo visível sem banners de sucesso. Input e botões têm raios 12/14, bordas de 1 px e texto com contraste adequado também em foco.

## Planeamento semanal
O planeador abre em Mais e usa uma lista de sete cartões, com um dia expandido de cada vez. O tipo de criação fica no topo, sem filtrar ou esconder os compromissos do outro tipo. O rodapé mantém visíveis o dia escolhido e a única acção principal. Dias sem compromissos são identificados por texto, sem badges. Seleccionar outro dia aproxima o cartão com animação funcional de 250 ms/easeOutCubic. Tarefas não exigem hora; o formulário e os campos avançados reutilizam os componentes existentes.

## Ícone Android — 0.9.1
O símbolo do calendário de assets/logo/tudoaki-icon-outline-light.svg substitui o visto isolado anterior. Traços #18181B, acentos #0D9488 e fundo #F9FAFB, conforme a imagem aprovada. Recursos VectorDrawable preservam a geometria sem dependências adicionais. A camada adaptativa respeita a zona segura; o ícone temático usa uma máscara monocromática dedicada. O arranque nativo que reutiliza estes recursos acompanha a nova identidade.
