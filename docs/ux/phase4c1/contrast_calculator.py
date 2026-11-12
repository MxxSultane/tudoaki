"""Documentation calculator only; does not import or modify the application.
Run from any directory: python3 docs/ux/phase4c1/contrast_calculator.py
"""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TOKENS = {
    'light': dict(background='#F7F8F5', surface='#FFFFFF', surfaceSoft='#E8EDE6',
                  clay='#E8EDE6', text='#202B29', textMuted='#5D6965',
                  action='#456C50', focus='#456C50', outline='#66736D',
                  accent='#9ECB8F', onAccent='#202B29', error='#9E2A2B',
                  errorSurface='#FCEAEA', decorationMineral='#ABAFB0'),
    'dark': dict(background='#18201D', surface='#202B29', surfaceSoft='#28352E',
                 clay='#28352E', text='#F2F5EF', textMuted='#BCC6BE',
                 action='#9ECB8F', focus='#9ECB8F', outline='#8E9D92',
                 accent='#9ECB8F', onAccent='#202B29', error='#FFB4AB',
                 errorSurface='#442629', decorationMineral='#ABAFB0'),
}


def rgb(value):
    return [int(value[i:i+2], 16) for i in (1, 3, 5)]


def compose(front, back, alpha):
    # sRGB channel compositing, nearest byte; no blur-dependent assumptions.
    return '#' + ''.join(f'{int(alpha*f+(1-alpha)*b+0.5):02X}'
                         for f, b in zip(rgb(front), rgb(back)))


def luminance(value):
    v = [c/255 for c in rgb(value)]
    v = [c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4 for c in v]
    return sum(c*w for c, w in zip(v, (.2126, .7152, .0722)))


def contrast(a, b):
    lo, hi = sorted((luminance(a), luminance(b)))
    return (hi+.05)/(lo+.05)


def build():
    approved = []
    for theme, tokens in TOKENS.items():
        layer = '#FFFFFF' if theme == 'light' else '#202B29'
        for base in ('background', 'surfaceSoft'):
            tokens['glassOver'+base[0].upper()+base[1:]] = compose(layer, tokens[base], .9)
        tokens['glass'] = tokens['glassOverSurfaceSoft']
        backgrounds = ('background', 'surface', 'surfaceSoft', 'clay', 'glass',
                       'glassOverBackground', 'glassOverSurfaceSoft')
        for back in backgrounds:
            for fore in ('text', 'textMuted', 'action', 'error'):
                approved.append((theme, fore, back, 'texto normal', 4.5))
            for fore in ('outline', 'focus'):
                approved.append((theme, fore, back, 'contorno/foco', 3.0))
        for fore in ('text', 'error'):
            approved.append((theme, fore, 'errorSurface', 'mensagem de erro', 4.5))
        approved.append((theme, 'onAccent', 'accent', 'botão/ícone/contorno interior', 4.5))
        approved.append((theme, 'action', 'surfaceSoft', 'barra numérica/checkbox', 3.0))
    rows = []
    for theme, fore, back, role, required in approved:
        t = TOKENS[theme]
        ratio = contrast(t[fore], t[back])
        assert ratio >= required, (theme, fore, back, role, ratio)
        rows.append(dict(theme=theme, foreground=fore, background=back,
                         fg_hex=t[fore], bg_hex=t[back], role=role,
                         required=required, ratio=round(ratio, 6), allowed=True))
    for theme, t in TOKENS.items():
        for back in ('background', 'surface', 'surfaceSoft', 'clay', 'glass'):
            assert contrast(t['text'], t[back]) >= 7
    return rows


def main():
    rows = build()
    (ROOT/'tokens.json').write_text(json.dumps(TOKENS, indent=2)+'\n')
    (ROOT/'contrast-approved.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2)+'\n')
    with (ROOT/'contrast-all-pairs.csv').open('w', newline='') as f:
        out = csv.writer(f)
        out.writerow(['theme', 'foreground', 'background', 'fg_hex', 'bg_hex',
                      'ratio', 'text_4_5', 'large_or_graphic_3', 'preferred_7', 'approved_roles'])
        for theme, t in TOKENS.items():
            for fore, a in t.items():
                for back, b in t.items():
                    r = contrast(a, b)
                    roles = '; '.join(x['role'] for x in rows if x['theme'] == theme
                                      and x['foreground'] == fore and x['background'] == back)
                    out.writerow([theme, fore, back, a, b, f'{r:.6f}', r >= 4.5,
                                  r >= 3, r >= 7, roles or 'not approved'])
    text = ['# Matriz de contraste — proposta calculada', '',
            'Cálculo WCAG sRGB: canal normalizado; linearizar com limiar 0,04045; '
            'L = 0,2126 R + 0,7152 G + 0,0722 B; razão = (L maior + 0,05)/(L menor + 0,05). '
            'Decisão com precisão integral, sem arredondar para aprovar. Tabela a três casas apenas para leitura.', '',
            'Executar `python3 docs/ux/phase4c1/contrast_calculator.py`. Sem pacotes externos. '
            'Os asserts verificam todos os pares aprovados e a preferência 7:1 de text nas superfícies de leitura.', '',
            '[CSV de todos os pares](contrast-all-pairs.csv) inclui os dois sentidos e os pares iguais '
            '(não são utilizações autorizadas). [JSON aprovado](contrast-approved.json) especifica função e limiar; '
            '[tokens](tokens.json) inclui aliases e cores compostas. **Qualquer uso não incluído na whitelist é proibido '
            'até cálculo/revisão**, mesmo se o CSV passar numericamente. Não há texto normal autorizado apenas a 3:1.', '',
            '## Whitelist exaustiva de utilizações funcionais', '',
            '| Tema | Frente / hex | Fundo / hex | Função | Exigido | Calculado |',
            '| --- | --- | --- | --- | --- | --- |']
    for x in rows:
        text.append(f"| {x['theme']} | {x['foreground']} {x['fg_hex']} | {x['background']} {x['bg_hex']} | {x['role']} | {x['required']}:1 | {x['ratio']:.3f}:1 |")
    text += ['', '## Pares proibidos de referência', '',
             '| Frente | Fundo | Razão | Restrição |', '| --- | --- | --- | --- |']
    for a, b, reason in [('#FFFFFF', '#9ECB8F', 'Texto branco em Sage: falha 4,5 e 3'),
                          ('#9ECB8F', '#FFFFFF', 'Sage como texto/ícone essencial em branco: falha'),
                          ('#ABAFB0', '#FFFFFF', 'Mineral como texto ou contorno funcional em branco: falha'),
                          ('#456C50', '#202B29', 'Forest como texto no fundo Graphite: usar action escuro Sage'),
                          ('#5D6965', '#9ECB8F', 'Texto secundário sobre botão Sage: usar onAccent')]:
        text.append(f'| {a} | {b} | {contrast(a,b):.3f}:1 | {reason} |')
    text += ['', '## Composição glass antes da luminância', '',
             'C = alpha × layer + (1 − alpha) × fundo efectivo, por canal sRGB, '
             'arredondamento ao byte mais próximo. Alpha 0,90; texto/controlos permanecem opacos. '
             'Não estimar contraste da layer isolada. Fundo só pode ser background ou surfaceSoft; '
             'uma imagem/gradiente arbitrário invalida esta autorização. Fallback sólido surface.', '',
             '| Tema | Layer | Alpha | Fundo efectivo | Resultado |', '| --- | --- | --- | --- | --- |']
    for theme, t in TOKENS.items():
        layer = '#FFFFFF' if theme == 'light' else '#202B29'
        for base in ('background', 'surfaceSoft'):
            text.append(f"| {theme} | {layer} | 0,90 | {t[base]} ({base}) | {compose(layer,t[base],.9)} |")
    text += ['', '## Efeitos decorativos clay: composição de referência', '',
             'Valores a alpha máximo junto à aresta, não contraste funcional: sombras/bordos esbatem com blur. '
             'Não passam sob texto, foco ou glifos. Nada na interface pode depender da visibilidade destes efeitos.', '',
             '| Efeito | Layer / alpha | Fundo | Cor composta | Contraste aresta/fundo |',
             '| --- | --- | --- | --- | --- |']
    for name, a, alpha, b in [('sombra clara', '#202B29', .08, '#F7F8F5'),
                             ('brilho claro', '#FFFFFF', .45, '#E8EDE6'),
                             ('sombra escura', '#000000', .16, '#18201D'),
                             ('brilho escuro', '#F2F5EF', .06, '#28352E')]:
        c = compose(a, b, alpha)
        text.append(f'| {name} | {a} / {alpha} | {b} | {c} | {contrast(c,b):.3f}:1 |')
    text += ['', '## Alcance da verificação', '',
             f'{len(rows)} utilizações funcionais aprovadas; todos os pares de tokens nos dois temas calculados no CSV. '
             'text supera 7:1 nos fundos de leitura especificados. Mineral é decorativo. '
             'Estados pressionado/hover/seleccionado/busy/disabled reutilizam os mesmos fundos e pares, '
             'sem overlays não calculados. Erro usa error/text sobre errorSurface; o foco exterior '
             'assenta no fundo pai, não sobre errorSurface. O anel interno do botão usa onAccent/ accent.', '',
             'Cálculo de especificação não é ensaio de pixels Flutter, anti-aliasing, cores do SO, '
             'foco real, leitor de ecrã ou conformidade WCAG integral. Confirmar a renderização futura.']
    (ROOT/'CONTRAST_MATRIX.md').write_text('\n'.join(text)+'\n')
    print(f'{len(rows)} approved uses; {sum(len(t)**2 for t in TOKENS.values())} token pairs calculated; all checks passed')


if __name__ == '__main__':
    main()
