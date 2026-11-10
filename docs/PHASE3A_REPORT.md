# Fase 3A — especificação de Hoje e Planear

## Origem
Branch inicial refactor/fase-2c-navegacao, HEAD 80576edb4bcd82b28aa8cb91147ad9a5d065be0f, árvore limpa; HEAD remoto conferido igual. CI verde da Fase 2C confirmado pelo utilizador, sem nova observação de execução nesta fase. Branch de documentação: docs/fase-3a-hoje-planear.

## Entrega
- [Especificação funcional e UX](ux/HOJE_PLANEAR_SPEC.md): hierarquia justificada de Hoje, integração Hoje/Amanhã/Semana/Sem data em Planear, criação/edição/continuação/descarte, estados excepcionais e princípios visuais.
- [Aceitação e implementação futura](ux/HOJE_PLANEAR_IMPLEMENTATION.md): dezasseis cenários verificáveis, os dez casos de utilização pedidos, mapeamento para o código existente, riscos, oito decisões para aprovação e cinco incrementos pequenos propostos.

As propostas incluem acesso à lista global de Tarefas e todas as áreas existentes; não eliminam funcionalidades. Confirmam que o dia planeado e o prazo final não têm campos independentes na base actual. O comportamento proposto, incluindo nova ordenação e confirmação de rascunho, não foi implementado nem deve ser confundido com a produção.

## Verificação
Inspeccionados TaskOperations, AppRoutes/AppDestination, providers, esquema Tasks, modelo da agenda, planeador semanal, editor e relatórios anteriores. Caminhos de integração correspondem a ficheiros existentes. Ligações Markdown locais e integridade do diff verificadas. Apenas três documentos criados; lib/, android/, assets/, test/, tool/, workflow e dependências idênticos a 80576ed. Nenhuma migração ou acesso a dados reais.

Não foram executados Flutter analyze/test/build: não há alterações de código nesta fase. Não se apresentam protótipos visuais nem resultados de testes de usabilidade; contraste real, compreensão, tempos e desempenho da experiência futura permanecem por validar. Os alvos quantitativos são propostas, não medições.

## Aprovação e próxima fase
Rever D1–D8 no documento de implementação, especialmente a data única v5, composição de Hoje, retorno ao contexto e lugar de Tarefas. Proposta de próxima etapa: fechar estes contratos e a validação visual/acessível antes de implementar a folha e os novos ecrãs em incrementos separados. Não activar /plan, nova barra, componentes ou esquema nesta entrega. A Fase 3B não foi iniciada; sem merge automático.
