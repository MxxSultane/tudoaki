"""Reproducible design-only contrast review. No application imports or writes."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / 'phase4c1'


def rgb(value):
    return [int(value[i:i+2], 16) for i in (1, 3, 5)]


def luminance(value):
    c = [v/255 for v in rgb(value)]
    c = [v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in c]
    return sum(v*w for v, w in zip(c, (.2126, .7152, .0722)))


def contrast(a, b):
    lo, hi = sorted((luminance(a), luminance(b)))
    return (hi+.05)/(lo+.05)


def compose(front, back, alpha):
    return '#' + ''.join(f'{int(alpha*f+(1-alpha)*b+.5):02X}'
                         for f, b in zip(rgb(front), rgb(back)))


def main():
    tokens = json.loads((SOURCE/'tokens.json').read_text())
    inherited = json.loads((SOURCE/'contrast-approved.json').read_text())
    uses = [(x['theme'], x['foreground'], x['background'], x['role'], x['required'])
            for x in inherited]
    for theme, t in tokens.items():
        t['primaryBorder'] = t['action'] if theme == 'light' else t['onAccent']
        uses.append((theme, 'primaryBorder', 'accent', 'contorno interior do botão Sage', 3))
    results = []
    for theme, fg, bg, role, minimum in uses:
        t = tokens[theme]
        ratio = contrast(t[fg], t[bg])
        assert ratio >= minimum, (theme, fg, bg, role, ratio)
        results.append(dict(theme=theme, foreground=fg, background=bg,
                            fg_hex=t[fg], bg_hex=t[bg], role=role, minimum=minimum,
                            ratio=ratio, passes=True))
    for t in tokens.values():
        for bg in ('background', 'surface', 'surfaceSoft', 'clay', 'glass'):
            assert contrast(t['text'], t[bg]) >= 7
    (ROOT/'tokens.json').write_text(json.dumps(tokens, indent=2)+'\n')
    (ROOT/'contrast-results.json').write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n')
    with (ROOT/'contrast-all-pairs.csv').open('w', newline='') as f:
        out = csv.writer(f, lineterminator='\n')
        out.writerow(['theme', 'foreground', 'background', 'fg_hex', 'bg_hex',
                      'ratio', 'text_4_5', 'large_graphic_3', 'preferred_7', 'permitted_roles'])
        for theme, t in tokens.items():
            for a, x in t.items():
                for b, y in t.items():
                    v = contrast(x, y)
                    roles = '; '.join(z['role'] for z in results if z['theme'] == theme
                                      and z['foreground'] == a and z['background'] == b)
                    out.writerow([theme, a, b, x, y, f'{v:.8f}', v >= 4.5, v >= 3,
                                  v >= 7, roles or 'not permitted'])
    md=['# Contraste — revisão 4C.2', '',
        'Paleta preservada. Novo token **primaryBorder** é um alias: Forest no claro e Graphite no escuro. '
        'Cálculo sRGB WCAG com limiar 0,04045 e razão (Lmaior+0,05)/(Lmenor+0,05). '
        'Decisões com precisão integral; valores arredondados apenas na apresentação. '
        '«Passa» refere-se ao limiar matemático, não a aprovação de produto ou conformidade WCAG integral.', '',
        '[Todos os pares](contrast-all-pairs.csv) · [94 utilizações calculadas](contrast-results.json) · '
        '[Tokens](tokens.json) · [Calculador](contrast_calculator.py). '
        'Executar `python3 -B docs/ux/phase4c2/contrast_calculator.py`. Nenhum pacote externo.', '',
        '## Pares utilizados / candidatos permitidos', '',
        '| Tema | Frente | Fundo | Papel | Mínimo | Calculado |',
        '| --- | --- | --- | --- | --- | --- |']
    for x in results:
        md.append(f"| {x['theme']} | {x['foreground']} {x['fg_hex']} | {x['background']} {x['bg_hex']} | {x['role']} | {x['minimum']}:1 | {x['ratio']:.3f}:1 |")
    md += ['', '## Limites do botão e pares proibidos', '',
           '| Uso | Frente/fundo | Razão | Decisão |', '| --- | --- | --- | --- |']
    for name, a, b, decision in [
        ('Texto branco sobre Sage', '#FFFFFF', '#9ECB8F', 'Proibido: falha 4,5 e 3'),
        ('Mineral como texto/limite essencial no branco', '#ABAFB0', '#FFFFFF', 'Proibido'),
        ('Sage isolado para identificar o contorno no branco', '#9ECB8F', '#FFFFFF', '1,84 não garante o limiar de 3:1; usar contorno funcional'),
        ('Contorno Forest contra Sage (claro)', '#456C50', '#9ECB8F', 'Passa 3:1'),
        ('Contorno Graphite contra Sage (escuro)', '#202B29', '#9ECB8F', 'Passa 3:1')]:
        md.append(f'| {name} | {a}/{b} | {contrast(a,b):.3f}:1 | {decision} |')
    md += ['', 'O texto Graphite/Sage já passava; isso não demonstra por si só a identificação de uma fronteira necessária. '
           'A 4C.2 propõe contorno funcional de 1 dp (sem sombra) no botão Sage. '
           'No claro, Forest contrasta com Sage e com os fundos claros. No escuro, o contorno interior Graphite '
           'contrasta com Sage; o próprio preenchimento Sage identifica o botão contra o fundo escuro. '
           'Não se exige que o mesmo contorno interior também delimite o exterior escuro. '
           'Foco exterior continua em focus com separação 2 dp; foco e selecção não se confundem.', '',
           '## Glass: cor efectiva e alternativa sólida', '',
           '| Tema | Layer/alpha | Fundo efectivo | Composição | Texto | Metadados | Limite |',
           '| --- | --- | --- | --- | --- | --- | --- |']
    for theme, t in tokens.items():
        layer = '#FFFFFF' if theme == 'light' else '#202B29'
        for bg in ('background', 'surfaceSoft'):
            color = compose(layer, t[bg], .9)
            ratios = [contrast(t[k], color) for k in ('text', 'textMuted', 'outline')]
            assert ratios[0] >= 4.5 and ratios[1] >= 4.5 and ratios[2] >= 3
            md.append(f'| {theme} | {layer} / 0,90 | {t[bg]} | {color} | {ratios[0]:.3f}:1 | {ratios[1]:.3f}:1 | {ratios[2]:.3f}:1 |')
    md += ['', 'A composição é feita por canal sRGB e arredondada ao byte antes da luminância. '
           'Layer isolada e blur não são usados como prova de contraste. O protótipo de mapa usa layer real a 90% '
           'sobre surfaceSoft fixo; o controlo de revisão «Fundo sólido» substitui-a por surface. '
           'Sem fotografia, animação de fundo ou texto por trás. Alternativa sólida fica disponível sempre. '
           'Movimento reduzido não é sinónimo de transparência reduzida: são condições verificadas separadamente.', '',
           '## Clay e estados', '',
           'Clay tem fundo opaco clay; texto/controlos usam os pares acima. Sombra decorativa '
           'Graphite 8% no claro e preta 16% no escuro, máximo blur 10 dp, sem modificar a zona de leitura. '
           'Não serve de limite funcional. Sem clay em listas de tarefas, finanças, barra, campos e diálogos. '
           'Seleccionado/hover/pressed/disabled reutilizam surfaceSoft, text/textMuted/action e outline; '
           'não há opacidade global que reduza contraste. Erro tem texto+ícone em error/errorSurface, '
           'e a borda de erro não substitui o foco.', '',
           f'**Resultado: {len(results)} utilizações verificadas e {sum(len(t)**2 for t in tokens.values())} pares de tokens calculados.** '
           'Textos críticos text atingem pelo menos 7:1 nas superfícies de leitura. '
           'Todos os textos normais usados exigem 4,5:1; não se invoca a excepção de texto grande para rótulos de 16 dp. '
           'A verificação nativa de pixels, semântica e foco permanece pendente.']
    (ROOT/'CONTRAST.md').write_text('\n'.join(md)+'\n')
    print(f'{len(results)} uses pass; {sum(len(t)**2 for t in tokens.values())} pairs calculated')


if __name__ == '__main__':
    main()
