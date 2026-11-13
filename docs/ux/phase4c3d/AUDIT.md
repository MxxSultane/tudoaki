# Finanças — auditoria anterior à implementação 4C.3D

Base: 49e1724319988ef66890f5742de8eea84692c112, HEAD local/remoto final 4C.3C. Baseline executada: 292/292 aprovados. Complementa a auditoria 4B/4C.1 e a revisão 4C.2; o código activo é a fonte das capacidades existentes.

| Capacidade activa | Fonte / regra | Acesso a preservar |
| --- | --- | --- |
| Ecrã principal | /finance → AreaScaffold → TudoAkiScreen → FinancePanel; dataProvider | Mesma rota secundária/Voltar, sem novo destino principal |
| Período | monthKey; mês inicial do financeClockProvider; limites 2000–2100 | Mês anterior/seguinte e selector de data; mudar contexto não escreve |
| Moedas | MZN, USD, EUR, ZAR; currency por registo; preferência apenas para novos registos | Selector de consulta e moeda de novas criações; edição mantém moeda original; sem conversão |
| Resumo mensal | transactionTotal em BigInt; income − expense − saving no mês/moeda | Saldo dos movimentos, receitas, despesas e contribuições; não representa saldo bancário |
| Movimentos / histórico | FinancialTransactions; ordenação day descendente dentro do mês | Registar movimento; tocar para editar/eliminar; meses anteriores pelo mesmo selector |
| Campos de movimento | Editor Transacção em forms.dart: título, dia, valor, tipo, categoria, savings_id quando saving; moeda fixa do contexto/origem | Mesmo editor e save/remove; cancelamento sem escrita; aviso para origem recorrente |
| Categorias | Texto; cleanCategory/categoryKey; não existe catálogo persistente de categorias | Campo Categoria preservado; normalização e associação por categoria continuam iguais |
| Orçamentos | Budgets: mês/categoria normalizada/moeda únicos; budgetSpent só expense desse mês/moeda/categoria | Criar/editar/eliminar; despesas/limite/restante/barra; eliminar não apaga movimentos |
| Poupanças | SavingsGoals, target_cents; soma de contribuições associadas em todos os meses da mesma moeda | Criar/editar/eliminar; contribuição pelo editor existente; eliminar preserva movimentos sem associação; independente de Goals |
| Recorrências | RecurringTransactions, RecurringOccurrences; finance_repository/rules | Criar/editar/pausar/eliminar; rever vencimentos e confirmar explicitamente; histórico de ocorrências |
| Confirmação recorrente | previewRecurring sem escrita; recordRecurring após confirmação; lotes até 24; revisão/idempotência | Cancelar não grava; nenhuma emissão ao abrir/navegar/expandir; apagar movimento preserva vencimento registado |
| Calendário de regra já registada | Frequência/início bloqueados após ocorrências; revisão de regra validada no repositório | Editor conserva bloqueios e mensagem; editar não reescreve movimentos antigos |
| Precisão | amount/target/limit em cêntimos inteiros; moneyCents valida com BigInt antes de int; formatMoney sem double | 1–9007199254740991 cêntimos por input; zero/negativos/>2 decimais inválidos; sem arredondamento novo |
| Barras | moneyProgress converte para double exclusivamente para fracção visual limitada 0–1 | Mesmo valor gráfico; totais e rótulos continuam exactos em BigInt |
| Carga/erro | dataProvider e contentor; erro distinto de vazio | Carregamento, retentativa, vazio do mês/moeda; não fabricar zeros após erro |

**Ausente do modelo:** contas/saldos bancários, câmbio, transferências entre contas, importação bancária, campo separado de descrição de movimento, novas operações de investimento ou previsão. O título é o texto descritivo existente; não se acrescenta um campo fictício para completar o protótipo. Não se unificam SavingsGoals e Goals.

**Antes:** moeda/aviso longo, mês, quatro linhas de resumo, Registar movimento e Criar poupança com peso próximo, orçamentos, recorrências, poupanças, movimentos no fim. Valores em trailing de ListTile e cabeçalhos com acção lateral são candidatos a overflow em 320 dp/200%.

**Decisão:** contexto mês/moeda; resumo plano compacto e composição divulgada; Registar movimento; movimentos recentes e acesso à lista completa do mês; três secções secundárias nomeadas com contagem e criação. Valor longo nunca abreviado ou convertido: leitura completa com deslocação horizontal explícita quando a largura não permite uma linha, moeda identificável e semântica integral.

Invariantes: preservar finance_rules.dart, finance_repository.dart, finance_providers.dart, base/schema v5, moneyCents, operações save/remove dos editores, tipos/campos/datas/IDs e relações. Só apresentação e acesso progressivo. Sem operações financeiras novas nem geração de movimentos implícita.
