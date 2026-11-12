# Contraste — cobertura global por família de componentes

A adenda reutiliza os mesmos tokens, superfícies opacas e composições glass. Não introduz cores funcionais adicionais. A [matriz integral](CONTRAST_MATRIX.md) continua a calcular 578 pares e a verificar 92 utilizações. Esta tabela adicional calcula o pior caso de cada família nos dois temas; a decisão usa precisão integral, não a razão arredondada.

| Tema | Função em toda a app | Frente | Fundos abrangidos | Mínimo calculado | Exigido |
| --- | --- | --- | --- | --- | --- |
| light | Texto principal / valor crítico | text | background, surface, surfaceSoft, clay, glass | 12.292:1 (clay) | 7:1 |
| light | Metadados / inactivo | textMuted | background, surface, surfaceSoft, clay, glass | 4.814:1 (clay) | 4.5:1 |
| light | Texto de acção / seleccionado | action | background, surface, surfaceSoft, clay, glass | 5.034:1 (clay) | 4.5:1 |
| light | Limite funcional / ícone essencial | outline | background, surface, surfaceSoft, clay, glass | 4.173:1 (clay) | 3:1 |
| light | Foco exterior | focus | background, surface, surfaceSoft, clay, glass | 5.034:1 (clay) | 3:1 |
| light | Texto, visto e foco interior em Sage | onAccent | accent | 7.917:1 (accent) | 4.5:1 |
| light | Erro / contorno destrutivo | error | errorSurface, background, surface | 6.417:1 (errorSurface) | 4.5:1 |
| dark | Texto principal / valor crítico | text | background, surface, surfaceSoft, clay, glass | 11.644:1 (clay) | 7:1 |
| dark | Metadados / inactivo | textMuted | background, surface, surfaceSoft, clay, glass | 7.297:1 (clay) | 4.5:1 |
| dark | Texto de acção / seleccionado | action | background, surface, surfaceSoft, clay, glass | 6.951:1 (clay) | 4.5:1 |
| dark | Limite funcional / ícone essencial | outline | background, surface, surfaceSoft, clay, glass | 4.508:1 (clay) | 3:1 |
| dark | Foco exterior | focus | background, surface, surfaceSoft, clay, glass | 6.951:1 (clay) | 3:1 |
| dark | Texto, visto e foco interior em Sage | onAccent | accent | 7.917:1 (accent) | 4.5:1 |
| dark | Erro / contorno destrutivo | error | errorSurface, background, surface | 7.954:1 (errorSurface) | 4.5:1 |

## Correspondência com os ecrãs e estados

| Instância global | Famílias da tabela | Estado com distinção adicional |
| --- | --- | --- |
| Hoje, Planear, Tarefas e Agenda | Texto principal, metadados, acção, limite, foco | Caixa checked, data seleccionada/hoje, expansão e filtro por forma/texto |
| Mais, Revisões e Definições | Texto principal, metadados, acção, limite, foco | Dropdown/switch/expansão e avisos nomeados |
| Hábitos, disciplinas e metas clay | Mesmas famílias contra clay | Pausa por texto, edição nomeada, estado de meta por modo |
| Barra inferior e acções globais | Texto/acção/metadados contra surface; onAccent em botão Sage | Rótulo + indicador de selecção; foco independente |
| Todos os formulários e diálogos | Texto/metadados/limite/foco; erro/errorSurface; onAccent/accent | Campo inválido com mensagem, modal nomeado, Cancelar/Descartar/Eliminar explícitos |
| Estado desactivado / busy | textMuted/surfaceSoft e nome do estado | Sem opacidade global nem activação; a indisponibilidade não depende só de cor |
| Painel de Progresso glass | Texto/metadados/limite em glass composto | Lista textual equivalente e alternativa sólida surface |

Os nomes de componentes não permitem usar cores fora da whitelist. Quando um token é alias exacto de outro (por exemplo clay=surfaceSoft), aplica-se a mesma função/razão; isso não permite trocar foreground/background arbitrariamente. Texto normal não usa a excepção de 3:1 para texto grande. Mineral e sombras são decorativos, nunca fronteiras essenciais.

O checkbox conceptual usa visto onAccent sobre accent; o contorno interior também usa onAccent. A identificação por visto e nome permanece, sem depender apenas da cor do preenchimento. O anel exterior usa focus sobre o fundo pai. O botão destrutivo usa error/errorSurface e contorno error, não um novo vermelho de preenchimento sem cálculo.

Glass continua limitado à layer/fundos calculados em CONTRAST_MATRIX e SURFACES. As imagens dos protótipos mostram uma representação da cor composta, não um teste de blur Flutter. Não se lê informação essencial por trás de uma barreira/modal. Pares proibidos (branco/Sage, Mineral/branco e outros) continuam proibidos em todos os módulos.

Cálculos não certificam contraste dos pixels nativos, desenho de ícones, foco real ou conformidade WCAG integral. A verificação futura tem de medir os componentes efectivamente renderizados, incluindo brilho, texto ampliado e modo escuro.
