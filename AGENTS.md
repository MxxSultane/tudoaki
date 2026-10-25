# tudoAki — Guia para o Codex

App móvel de **metas, tarefas e agenda**. Flutter (Dart). Duas plataformas, uma única base de código.
Língua da interface: **português europeu** (pré-AO90: "acção", "direcção", "contacto").

## 1. Princípio central: menos é mais
A app deve parecer uma app nativa da Apple: calma, clara, com muito espaço em branco.
Cada ecrã responde a **uma pergunta** e tem **uma acção principal**.

### Regras anti-poluição (obrigatórias)
1. **Um único botão principal por ecrã** (o "+" ou "Continuar"). O resto são acções discretas de texto.
2. **Máximo de 3 separadores** na barra inferior: Agenda, Metas, Tarefas.
3. **Sem gradientes, sem sombras fortes, sem bordas grossas.** Separar por espaço e por cartões planos com borda de 1 px.
4. **Sem ícones decorativos.** Um ícone só existe se substituir uma palavra ou ajudar a agir.
5. **Texto curto.** Títulos até 3 palavras; descrições até 1 linha.
6. **Listas em estilo "inset grouped"** (cartões agrupados com cantos arredondados), nunca tabelas densas.
7. **Estados vazios** com uma frase e um botão ("Ainda não tens tarefas. Criar tarefa").
8. **Nada de pop-ups, banners ou badges** a menos que sejam críticos.
9. **Informação avançada escondida** em ecrãs de detalhe ou folhas inferiores (bottom sheets).

## 2. Identidade visual
Logótipo: calendário com visto; uma argola e o visto em cor de acento. Ficheiros em `assets/logo/`.
Wordmark: "tudo" em peso 500 e "Aki" em peso 700 na cor de acento, fonte **Newsreader**.

### Cores (proporção 60 / 30 / 10)
| Papel | Claro | Escuro |
|---|---|---|
| Fundo (60%) | `#F9FAFB` | `#18181B` |
| Cartões e barras (30%) | `#FFFFFF` / `#F3F4F6` | `#27272A` |
| Acento (10%) | `#0D9488` (texto e botões) / `#10B981` (gráficos) | `#10B981` |
| Texto principal | `#18181B` | `#F9FAFB` |
| Texto secundário | `#6B7280` | `#9CA3AF` |
| Divisores | `#E5E7EB` | `#3F3F46` |

O acento aparece **só** em: botão principal, separador activo, visto de tarefa concluída, progresso de meta.
Nunca usar o acento em fundos grandes.

### Tipografia
- Corpo e interface: **Inter** (o mais próximo da SF Pro). Em iOS pode usar a fonte do sistema.
- Wordmark e títulos grandes: **Newsreader** (pacote `google_fonts`).
- Escala: título grande 34/700, título 22/600, corpo 16/400, legenda 13/400.

### Forma e movimento
- Grelha de **8 px**. Margens laterais de 20 px.
- Raios: cartões 16, botões 14, campos 12, folhas inferiores 24.
- Ícones de linha com traço de 1,5 a 2 px (ex.: pacote `lucide_icons` ou `cupertino_icons`).
- Animações de 200 a 300 ms, curva `easeOutCubic`. Sem animações decorativas.
- Feedback táctil leve (`HapticFeedback.selectionClick`) ao concluir tarefas.
- Áreas de toque de pelo menos 44×44 px.

## 3. Ecrãs
| Separador | Pergunta que responde | Conteúdo |
|---|---|---|
| **Agenda** | O que tenho hoje? | Título grande "Hoje", faixa de dias da semana, lista cronológica de eventos e tarefas |
| **Metas** | Para onde vou? | Lista de metas com barra de progresso fina; detalhe com tarefas associadas |
| **Tarefas** | O que falta fazer? | Lista simples com caixa de verificação; filtro "Pendentes / Concluídas" |

O botão "+" flutuante abre uma folha inferior com três opções: Evento, Tarefa, Meta.

## 4. Arquitectura
- Organização por funcionalidade: `lib/features/{agenda,goals,tasks}/` com `data`, `domain`, `presentation`.
- Tema centralizado em `lib/core/theme/` (cores, tipografia, `ThemeData` claro e escuro).
- Gestão de estado: BLoC ou Cubit (um por funcionalidade). Preferir Cubit pela simplicidade.
- Persistência local primeiro (ex.: Drift ou Hive); a sincronização na nuvem fica para depois.
- Modo escuro automático segundo o sistema (`ThemeMode.system`).
- Sem dependências desnecessárias. Justificar cada pacote novo em uma linha.

## 5. Tema em Dart (ponto de partida)
```dart
import 'package:flutter/material.dart';

class AppColors {
  static const bgLight = Color(0xFFF9FAFB);
  static const cardLight = Color(0xFFFFFFFF);
  static const inkLight = Color(0xFF18181B);
  static const mutedLight = Color(0xFF6B7280);
  static const lineLight = Color(0xFFE5E7EB);
  static const accentLight = Color(0xFF0D9488);

  static const bgDark = Color(0xFF18181B);
  static const cardDark = Color(0xFF27272A);
  static const inkDark = Color(0xFFF9FAFB);
  static const mutedDark = Color(0xFF9CA3AF);
  static const lineDark = Color(0xFF3F3F46);
  static const accentDark = Color(0xFF10B981);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final bg = dark ? AppColors.bgDark : AppColors.bgLight;
  final card = dark ? AppColors.cardDark : AppColors.cardLight;
  final ink = dark ? AppColors.inkDark : AppColors.inkLight;
  final acc = dark ? AppColors.accentDark : AppColors.accentLight;
  final line = dark ? AppColors.lineDark : AppColors.lineLight;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(seedColor: acc, brightness: b)
        .copyWith(primary: acc, surface: card, onSurface: ink),
    cardTheme: CardThemeData(
      color: card, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: line),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
      foregroundColor: ink,
    ),
    dividerColor: line,
  );
}
```

## 6. Assets do logótipo
Pacote em `assets/logo/` (usar `flutter_svg` para SVG):
- `tudoaki-icon-outline-light.svg` / `-dark.svg`: símbolo principal na app.
- `tudoaki-icon-solid-light.svg` / `-dark.svg`: versão para tamanhos pequenos.
- `tudoaki-app-icon-1024.png`: ícone da app (usar `flutter_launcher_icons`).

## 7. Definição de "pronto"
- Funciona em modo claro e escuro.
- Cada ecrã tem uma só acção principal.
- Sem texto cortado em ecrãs pequenos (ex.: 360 px de largura).
- Contraste do texto de pelo menos 4,5:1.
- Nenhum elemento decorativo que possa ser removido sem perda de significado.

---

## Prompt inicial (colar no Codex)
> Lê o `AGENTS.md` e cria o esqueleto da app Flutter **tudoAki**: tema claro e escuro com as cores e tipografia do guia, barra inferior com 3 separadores (Agenda, Metas, Tarefas) e ecrã "Hoje" com lista de exemplo e botão "+" que abre uma folha inferior (Evento, Tarefa, Meta). Segue as regras anti-poluição à letra: um único botão principal por ecrã, sem gradientes nem sombras fortes, muito espaço em branco, estilo das apps da Apple. Não implementes mais nada além disto. No fim, lista os pacotes que adicionaste e porquê.
