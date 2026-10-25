# tudoAki — sistema visual actual

O [AGENTS.md](../AGENTS.md) fornecido rege o esqueleto 0.7.0. O pedido actual limita a entrega aos temas, três separadores, Hoje com exemplos e folha de criação.

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

Um único botão principal **+** por ecrã. Navegação **Agenda / Metas / Tarefas**, com acento no ícone activo e texto neutro. O acento claro não atinge 4,5:1 para texto pequeno sobre branco, por isso não é usado nos rótulos. O símbolo + usa texto escuro sobre o acento, com contraste superior a 4,5:1.

Listas agrupadas, com separação por espaço e divisores discretos. Em texto ampliado, os títulos das entradas podem ocupar mais de uma linha para evitar cortes; a faixa de dias permite deslocação horizontal. Alvos de toque de pelo menos 44 px. Temas seguem o sistema, sem selector adicional.
