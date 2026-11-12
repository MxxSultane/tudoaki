# Matriz de contraste — proposta calculada

Cálculo WCAG sRGB: canal normalizado; linearizar com limiar 0,04045; L = 0,2126 R + 0,7152 G + 0,0722 B; razão = (L maior + 0,05)/(L menor + 0,05). Decisão com precisão integral, sem arredondar para aprovar. Tabela a três casas apenas para leitura.

Executar `python3 docs/ux/phase4c1/contrast_calculator.py`. Sem pacotes externos. Os asserts verificam todos os pares aprovados e a preferência 7:1 de text nas superfícies de leitura.

[CSV de todos os pares](contrast-all-pairs.csv) inclui os dois sentidos e os pares iguais (não são utilizações autorizadas). [JSON aprovado](contrast-approved.json) especifica função e limiar; [tokens](tokens.json) inclui aliases e cores compostas. **Qualquer uso não incluído na whitelist é proibido até cálculo/revisão**, mesmo se o CSV passar numericamente. Não há texto normal autorizado apenas a 3:1.

## Whitelist exaustiva de utilizações funcionais

| Tema | Frente / hex | Fundo / hex | Função | Exigido | Calculado |
| --- | --- | --- | --- | --- | --- |
| light | text #202B29 | background #F7F8F5 | texto normal | 4.5:1 | 13.690:1 |
| light | textMuted #5D6965 | background #F7F8F5 | texto normal | 4.5:1 | 5.362:1 |
| light | action #456C50 | background #F7F8F5 | texto normal | 4.5:1 | 5.606:1 |
| light | error #9E2A2B | background #F7F8F5 | texto normal | 4.5:1 | 6.986:1 |
| light | outline #66736D | background #F7F8F5 | contorno/foco | 3.0:1 | 4.648:1 |
| light | focus #456C50 | background #F7F8F5 | contorno/foco | 3.0:1 | 5.606:1 |
| light | text #202B29 | surface #FFFFFF | texto normal | 4.5:1 | 14.594:1 |
| light | textMuted #5D6965 | surface #FFFFFF | texto normal | 4.5:1 | 5.716:1 |
| light | action #456C50 | surface #FFFFFF | texto normal | 4.5:1 | 5.976:1 |
| light | error #9E2A2B | surface #FFFFFF | texto normal | 4.5:1 | 7.447:1 |
| light | outline #66736D | surface #FFFFFF | contorno/foco | 3.0:1 | 4.955:1 |
| light | focus #456C50 | surface #FFFFFF | contorno/foco | 3.0:1 | 5.976:1 |
| light | text #202B29 | surfaceSoft #E8EDE6 | texto normal | 4.5:1 | 12.292:1 |
| light | textMuted #5D6965 | surfaceSoft #E8EDE6 | texto normal | 4.5:1 | 4.814:1 |
| light | action #456C50 | surfaceSoft #E8EDE6 | texto normal | 4.5:1 | 5.034:1 |
| light | error #9E2A2B | surfaceSoft #E8EDE6 | texto normal | 4.5:1 | 6.272:1 |
| light | outline #66736D | surfaceSoft #E8EDE6 | contorno/foco | 3.0:1 | 4.173:1 |
| light | focus #456C50 | surfaceSoft #E8EDE6 | contorno/foco | 3.0:1 | 5.034:1 |
| light | text #202B29 | clay #E8EDE6 | texto normal | 4.5:1 | 12.292:1 |
| light | textMuted #5D6965 | clay #E8EDE6 | texto normal | 4.5:1 | 4.814:1 |
| light | action #456C50 | clay #E8EDE6 | texto normal | 4.5:1 | 5.034:1 |
| light | error #9E2A2B | clay #E8EDE6 | texto normal | 4.5:1 | 6.272:1 |
| light | outline #66736D | clay #E8EDE6 | contorno/foco | 3.0:1 | 4.173:1 |
| light | focus #456C50 | clay #E8EDE6 | contorno/foco | 3.0:1 | 5.034:1 |
| light | text #202B29 | glass #FDFDFD | texto normal | 4.5:1 | 14.347:1 |
| light | textMuted #5D6965 | glass #FDFDFD | texto normal | 4.5:1 | 5.619:1 |
| light | action #456C50 | glass #FDFDFD | texto normal | 4.5:1 | 5.875:1 |
| light | error #9E2A2B | glass #FDFDFD | texto normal | 4.5:1 | 7.321:1 |
| light | outline #66736D | glass #FDFDFD | contorno/foco | 3.0:1 | 4.871:1 |
| light | focus #456C50 | glass #FDFDFD | contorno/foco | 3.0:1 | 5.875:1 |
| light | text #202B29 | glassOverBackground #FEFEFE | texto normal | 4.5:1 | 14.470:1 |
| light | textMuted #5D6965 | glassOverBackground #FEFEFE | texto normal | 4.5:1 | 5.667:1 |
| light | action #456C50 | glassOverBackground #FEFEFE | texto normal | 4.5:1 | 5.926:1 |
| light | error #9E2A2B | glassOverBackground #FEFEFE | texto normal | 4.5:1 | 7.384:1 |
| light | outline #66736D | glassOverBackground #FEFEFE | contorno/foco | 3.0:1 | 4.913:1 |
| light | focus #456C50 | glassOverBackground #FEFEFE | contorno/foco | 3.0:1 | 5.926:1 |
| light | text #202B29 | glassOverSurfaceSoft #FDFDFD | texto normal | 4.5:1 | 14.347:1 |
| light | textMuted #5D6965 | glassOverSurfaceSoft #FDFDFD | texto normal | 4.5:1 | 5.619:1 |
| light | action #456C50 | glassOverSurfaceSoft #FDFDFD | texto normal | 4.5:1 | 5.875:1 |
| light | error #9E2A2B | glassOverSurfaceSoft #FDFDFD | texto normal | 4.5:1 | 7.321:1 |
| light | outline #66736D | glassOverSurfaceSoft #FDFDFD | contorno/foco | 3.0:1 | 4.871:1 |
| light | focus #456C50 | glassOverSurfaceSoft #FDFDFD | contorno/foco | 3.0:1 | 5.875:1 |
| light | text #202B29 | errorSurface #FCEAEA | mensagem de erro | 4.5:1 | 12.576:1 |
| light | error #9E2A2B | errorSurface #FCEAEA | mensagem de erro | 4.5:1 | 6.417:1 |
| light | onAccent #202B29 | accent #9ECB8F | botão/ícone/contorno interior | 4.5:1 | 7.917:1 |
| light | action #456C50 | surfaceSoft #E8EDE6 | barra numérica/checkbox | 3.0:1 | 5.034:1 |
| dark | text #F2F5EF | background #18201D | texto normal | 4.5:1 | 15.107:1 |
| dark | textMuted #BCC6BE | background #18201D | texto normal | 4.5:1 | 9.468:1 |
| dark | action #9ECB8F | background #18201D | texto normal | 4.5:1 | 9.019:1 |
| dark | error #FFB4AB | background #18201D | texto normal | 4.5:1 | 9.792:1 |
| dark | outline #8E9D92 | background #18201D | contorno/foco | 3.0:1 | 5.849:1 |
| dark | focus #9ECB8F | background #18201D | contorno/foco | 3.0:1 | 9.019:1 |
| dark | text #F2F5EF | surface #202B29 | texto normal | 4.5:1 | 13.261:1 |
| dark | textMuted #BCC6BE | surface #202B29 | texto normal | 4.5:1 | 8.311:1 |
| dark | action #9ECB8F | surface #202B29 | texto normal | 4.5:1 | 7.917:1 |
| dark | error #FFB4AB | surface #202B29 | texto normal | 4.5:1 | 8.595:1 |
| dark | outline #8E9D92 | surface #202B29 | contorno/foco | 3.0:1 | 5.134:1 |
| dark | focus #9ECB8F | surface #202B29 | contorno/foco | 3.0:1 | 7.917:1 |
| dark | text #F2F5EF | surfaceSoft #28352E | texto normal | 4.5:1 | 11.644:1 |
| dark | textMuted #BCC6BE | surfaceSoft #28352E | texto normal | 4.5:1 | 7.297:1 |
| dark | action #9ECB8F | surfaceSoft #28352E | texto normal | 4.5:1 | 6.951:1 |
| dark | error #FFB4AB | surfaceSoft #28352E | texto normal | 4.5:1 | 7.547:1 |
| dark | outline #8E9D92 | surfaceSoft #28352E | contorno/foco | 3.0:1 | 4.508:1 |
| dark | focus #9ECB8F | surfaceSoft #28352E | contorno/foco | 3.0:1 | 6.951:1 |
| dark | text #F2F5EF | clay #28352E | texto normal | 4.5:1 | 11.644:1 |
| dark | textMuted #BCC6BE | clay #28352E | texto normal | 4.5:1 | 7.297:1 |
| dark | action #9ECB8F | clay #28352E | texto normal | 4.5:1 | 6.951:1 |
| dark | error #FFB4AB | clay #28352E | texto normal | 4.5:1 | 7.547:1 |
| dark | outline #8E9D92 | clay #28352E | contorno/foco | 3.0:1 | 4.508:1 |
| dark | focus #9ECB8F | clay #28352E | contorno/foco | 3.0:1 | 6.951:1 |
| dark | text #F2F5EF | glass #212C2A | texto normal | 4.5:1 | 13.085:1 |
| dark | textMuted #BCC6BE | glass #212C2A | texto normal | 4.5:1 | 8.201:1 |
| dark | action #9ECB8F | glass #212C2A | texto normal | 4.5:1 | 7.812:1 |
| dark | error #FFB4AB | glass #212C2A | texto normal | 4.5:1 | 8.481:1 |
| dark | outline #8E9D92 | glass #212C2A | contorno/foco | 3.0:1 | 5.066:1 |
| dark | focus #9ECB8F | glass #212C2A | contorno/foco | 3.0:1 | 7.812:1 |
| dark | text #F2F5EF | glassOverBackground #1F2A28 | texto normal | 4.5:1 | 13.438:1 |
| dark | textMuted #BCC6BE | glassOverBackground #1F2A28 | texto normal | 4.5:1 | 8.422:1 |
| dark | action #9ECB8F | glassOverBackground #1F2A28 | texto normal | 4.5:1 | 8.023:1 |
| dark | error #FFB4AB | glassOverBackground #1F2A28 | texto normal | 4.5:1 | 8.710:1 |
| dark | outline #8E9D92 | glassOverBackground #1F2A28 | contorno/foco | 3.0:1 | 5.203:1 |
| dark | focus #9ECB8F | glassOverBackground #1F2A28 | contorno/foco | 3.0:1 | 8.023:1 |
| dark | text #F2F5EF | glassOverSurfaceSoft #212C2A | texto normal | 4.5:1 | 13.085:1 |
| dark | textMuted #BCC6BE | glassOverSurfaceSoft #212C2A | texto normal | 4.5:1 | 8.201:1 |
| dark | action #9ECB8F | glassOverSurfaceSoft #212C2A | texto normal | 4.5:1 | 7.812:1 |
| dark | error #FFB4AB | glassOverSurfaceSoft #212C2A | texto normal | 4.5:1 | 8.481:1 |
| dark | outline #8E9D92 | glassOverSurfaceSoft #212C2A | contorno/foco | 3.0:1 | 5.066:1 |
| dark | focus #9ECB8F | glassOverSurfaceSoft #212C2A | contorno/foco | 3.0:1 | 7.812:1 |
| dark | text #F2F5EF | errorSurface #442629 | mensagem de erro | 4.5:1 | 12.271:1 |
| dark | error #FFB4AB | errorSurface #442629 | mensagem de erro | 4.5:1 | 7.954:1 |
| dark | onAccent #202B29 | accent #9ECB8F | botão/ícone/contorno interior | 4.5:1 | 7.917:1 |
| dark | action #9ECB8F | surfaceSoft #28352E | barra numérica/checkbox | 3.0:1 | 6.951:1 |

## Pares proibidos de referência

| Frente | Fundo | Razão | Restrição |
| --- | --- | --- | --- |
| #FFFFFF | #9ECB8F | 1.843:1 | Texto branco em Sage: falha 4,5 e 3 |
| #9ECB8F | #FFFFFF | 1.843:1 | Sage como texto/ícone essencial em branco: falha |
| #ABAFB0 | #FFFFFF | 2.213:1 | Mineral como texto ou contorno funcional em branco: falha |
| #456C50 | #202B29 | 2.442:1 | Forest como texto no fundo Graphite: usar action escuro Sage |
| #5D6965 | #9ECB8F | 3.101:1 | Texto secundário sobre botão Sage: usar onAccent |

## Composição glass antes da luminância

C = alpha × layer + (1 − alpha) × fundo efectivo, por canal sRGB, arredondamento ao byte mais próximo. Alpha 0,90; texto/controlos permanecem opacos. Não estimar contraste da layer isolada. Fundo só pode ser background ou surfaceSoft; uma imagem/gradiente arbitrário invalida esta autorização. Fallback sólido surface.

| Tema | Layer | Alpha | Fundo efectivo | Resultado |
| --- | --- | --- | --- | --- |
| light | #FFFFFF | 0,90 | #F7F8F5 (background) | #FEFEFE |
| light | #FFFFFF | 0,90 | #E8EDE6 (surfaceSoft) | #FDFDFD |
| dark | #202B29 | 0,90 | #18201D (background) | #1F2A28 |
| dark | #202B29 | 0,90 | #28352E (surfaceSoft) | #212C2A |

## Efeitos decorativos clay: composição de referência

Valores a alpha máximo junto à aresta, não contraste funcional: sombras/bordos esbatem com blur. Não passam sob texto, foco ou glifos. Nada na interface pode depender da visibilidade destes efeitos.

| Efeito | Layer / alpha | Fundo | Cor composta | Contraste aresta/fundo |
| --- | --- | --- | --- | --- |
| sombra clara | #202B29 / 0.08 | #F7F8F5 | #E6E8E5 | 1.156:1 |
| brilho claro | #FFFFFF / 0.45 | #E8EDE6 | #F2F5F1 | 1.080:1 |
| sombra escura | #000000 / 0.16 | #18201D | #141B18 | 1.053:1 |
| brilho escuro | #F2F5EF / 0.06 | #28352E | #34413A | 1.198:1 |

## Alcance da verificação

92 utilizações funcionais aprovadas; todos os pares de tokens nos dois temas calculados no CSV. text supera 7:1 nos fundos de leitura especificados. Mineral é decorativo. Estados pressionado/hover/seleccionado/busy/disabled reutilizam os mesmos fundos e pares, sem overlays não calculados. Erro usa error/text sobre errorSurface; o foco exterior assenta no fundo pai, não sobre errorSurface. O anel interno do botão usa onAccent/ accent.

Cálculo de especificação não é ensaio de pixels Flutter, anti-aliasing, cores do SO, foco real, leitor de ecrã ou conformidade WCAG integral. Confirmar a renderização futura.
