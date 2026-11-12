# Contraste — revisão 4C.2

Paleta preservada. Novo token **primaryBorder** é um alias: Forest no claro e Graphite no escuro. Cálculo sRGB WCAG com limiar 0,04045 e razão (Lmaior+0,05)/(Lmenor+0,05). Decisões com precisão integral; valores arredondados apenas na apresentação. «Passa» refere-se ao limiar matemático, não a aprovação de produto ou conformidade WCAG integral.

[Todos os pares](contrast-all-pairs.csv) · [94 utilizações calculadas](contrast-results.json) · [Tokens](tokens.json) · [Calculador](contrast_calculator.py). Executar `python3 -B docs/ux/phase4c2/contrast_calculator.py`. Nenhum pacote externo.

## Pares utilizados / candidatos permitidos

| Tema | Frente | Fundo | Papel | Mínimo | Calculado |
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
| light | primaryBorder #456C50 | accent #9ECB8F | contorno interior do botão Sage | 3:1 | 3.242:1 |
| dark | primaryBorder #202B29 | accent #9ECB8F | contorno interior do botão Sage | 3:1 | 7.917:1 |

## Limites do botão e pares proibidos

| Uso | Frente/fundo | Razão | Decisão |
| --- | --- | --- | --- |
| Texto branco sobre Sage | #FFFFFF/#9ECB8F | 1.843:1 | Proibido: falha 4,5 e 3 |
| Mineral como texto/limite essencial no branco | #ABAFB0/#FFFFFF | 2.213:1 | Proibido |
| Sage isolado para identificar o contorno no branco | #9ECB8F/#FFFFFF | 1.843:1 | 1,84 não garante o limiar de 3:1; usar contorno funcional |
| Contorno Forest contra Sage (claro) | #456C50/#9ECB8F | 3.242:1 | Passa 3:1 |
| Contorno Graphite contra Sage (escuro) | #202B29/#9ECB8F | 7.917:1 | Passa 3:1 |

O texto Graphite/Sage já passava; isso não demonstra por si só a identificação de uma fronteira necessária. A 4C.2 propõe contorno funcional de 1 dp (sem sombra) no botão Sage. No claro, Forest contrasta com Sage e com os fundos claros. No escuro, o contorno interior Graphite contrasta com Sage; o próprio preenchimento Sage identifica o botão contra o fundo escuro. Não se exige que o mesmo contorno interior também delimite o exterior escuro. Foco exterior continua em focus com separação 2 dp; foco e selecção não se confundem.

## Glass: cor efectiva e alternativa sólida

| Tema | Layer/alpha | Fundo efectivo | Composição | Texto | Metadados | Limite |
| --- | --- | --- | --- | --- | --- | --- |
| light | #FFFFFF / 0,90 | #F7F8F5 | #FEFEFE | 14.470:1 | 5.667:1 | 4.913:1 |
| light | #FFFFFF / 0,90 | #E8EDE6 | #FDFDFD | 14.347:1 | 5.619:1 | 4.871:1 |
| dark | #202B29 / 0,90 | #18201D | #1F2A28 | 13.438:1 | 8.422:1 | 5.203:1 |
| dark | #202B29 / 0,90 | #28352E | #212C2A | 13.085:1 | 8.201:1 | 5.066:1 |

A composição é feita por canal sRGB e arredondada ao byte antes da luminância. Layer isolada e blur não são usados como prova de contraste. O protótipo de mapa usa layer real a 90% sobre surfaceSoft fixo; o controlo de revisão «Fundo sólido» substitui-a por surface. Sem fotografia, animação de fundo ou texto por trás. Alternativa sólida fica disponível sempre. Movimento reduzido não é sinónimo de transparência reduzida: são condições verificadas separadamente.

## Clay e estados

Clay tem fundo opaco clay; texto/controlos usam os pares acima. Sombra decorativa Graphite 8% no claro e preta 16% no escuro, máximo blur 10 dp, sem modificar a zona de leitura. Não serve de limite funcional. Sem clay em listas de tarefas, finanças, barra, campos e diálogos. Seleccionado/hover/pressed/disabled reutilizam surfaceSoft, text/textMuted/action e outline; não há opacidade global que reduza contraste. Erro tem texto+ícone em error/errorSurface, e a borda de erro não substitui o foco.

**Resultado: 94 utilizações verificadas e 648 pares de tokens calculados.** Textos críticos text atingem pelo menos 7:1 nas superfícies de leitura. Todos os textos normais usados exigem 4,5:1; não se invoca a excepção de texto grande para rótulos de 16 dp. A verificação nativa de pixels, semântica e foco permanece pendente.
