# Auditoria global 4C.3F

Base 98d281385bd02ccd47ac97cafbc698efeb29682f, árvore limpa, branch criado directamente da 4C.3E. Inspecção de rotas activas, temas, composição, operações e testes anteriores; 336 capturas base, dois temas × três larguras × duas escalas × 28 cenários. As capturas são Flutter Linux, não Android físico. Os achados abaixo distinguem código observado de validação em dispositivo pendente.

| ID / classe | Âmbito e evidência | Decisão |
| --- | --- | --- |
| C01 — C | NavigationBar limita texto a 1,3; 200% produz 16,9 dp em vez de 26 dp no rótulo de 13. Novo teste falha. | Respeitar escala integral, altura calculada pelo texto e contorno de foco, conservando NavigationBar e destinos |
| C02 — C | Shell fixa 250 ms mesmo com disableAnimations. Novo teste falha. | Respeitar movimento reduzido |
| A01 — A/C | Shell/Planear/Tarefas/Mais recebem TodayTheme; restantes módulos PremiumScope. Campos/contornos/estados divergem. | Aplicar escopo premium à apresentação partilhada, sem alterar rotas/estado |
| A02 — A/B | Mais tem InsetGroup com 24 dp adicionais por entrada, caixa única e sem título; a 320/200 só cabem parcialmente três áreas. | Lista plana com margens/ritmo existentes e foco por entrada; conservar nove destinos e textos |
| C03 — A/C | Hábito/Evento/Tarefa no Editor mantêm tema antigo, sem contorno independente nos campos; novo teste falha. | Estilo premium e foco; Cancelar explícito nos editores que não o tinham, sem mexer nas operações |
| C04 — C | Erro do WorkspaceData e LegacySectionPage usa Column centrada sem scroll. Novo teste reduz altura para expor overflow. | Estado de leitura reutilizável, rolável, mensagem semântica e repetição acessível |
| C05 — C | Selector de moeda em Definições usa ellipsis e altura fixa; nome extenso a 200% não cabe. | Código ISO fechado, nomes completos no menu de altura variável; contrato monetário intacto |
| A03 — A/C | Agenda mantém filtros por peso apenas; Tarefas também não expõe selected na semântica. | Reutilizar PremiumFilter (visto + seleccionado) sem trocar critérios/ordem |
| D01 — D | Progresso → Tarefas empilha ramo do shell e gera asserção de chaves; percurso E falha também com app.dart da base. | Usar navegação existente do ramo para Tarefas/Metas, mantendo push em detalhes |
| C06 — C | Integração revela rodapés semanais/diários sem altura útil com barra 200%/insets de teclado. | Fallback rolável condicional, mesmos dias/dados/acções |
| E01 — E | dataProvider global sincroniza conquistas ao carregar; Progresso usa leitor próprio de leitura. | Preservar comportamento e registar bloqueio separado para qualquer mudança do contrato global |
| F01 — F | Progresso lê nove tabelas inteiras; paginação só na apresentação. | Medir utilitário existente com 100/1k/10k; SQL/persistência fora deste âmbito |
| Gate Android | Sem USB exposto; cliente ADB não consegue inicializar preferências no directório de utilizador protegido. Não há telefone acessível verificado. | Não alterar dados/assinatura/dispositivos; preparar roteiro exacto e manter gate físico aberto |

## Cobertura por área

Hoje: hierarquia/apresentação premium já aprovadas, fontes e FAB preservados; captura vazio/preenchido. Planear: amanhã e semana, rodapé contextual, datas e estado dos ramos. Metas: lista/filtros e criação numérica; detalhe/edição/histórico abrangidos pelos testes 4C.3B. Estudos: hierarquia/disciplinas/trabalhos/sessões preservadas, testes de pausa/retoma. Finanças: precisão/mês/moeda/recorrência preservadas, erros e cancelamento em testes anteriores. Progresso/Percurso: mesmas fontes e alternativa textual, testes de leitura sem escrita. Tarefas/Agenda: filtros, edição, semântica, navegação e associações. Hábitos: criação múltipla, pausa/registo/edição. Mais: nove acessos mantidos. Definições/Revisões: temas, moeda, avisos e dados preservados; componente legado apenas visual. Formulários/diálogos: Editor partilhado, criação rápida, editores académico/financeiro existentes; erros, carregamento e mensagens inline/snackbar auditados. Serviços de notificação e respectivas regras não são alterados.

A amostragem visual e a leitura de código não substituem testes de todas as combinações nem pesquisa com utilizadores novos. Nenhuma falha E/F autoriza mudar arquitectura ou regras silenciosamente.
