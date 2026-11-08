# Importação e restauro — proposta futura

**Não implementado nem executado.** Exportação actual: TudoAkiRepository.exportJson, objecto JSON com schemaVersion, exportedAt e 20 listas definidas em exportTables. Partilhado como texto; não há contrato actual de ficheiro, checksum ou restauro. Backup Android desactivado. Git não é backup dos dados do telefone; não houve acesso a dispositivos nesta fase.

## Compatibilidade
Suportar inicialmente apenas exportação v5 com estrutura completa validada. Rejeitar versões futuras e desconhecidas sem escrever. Compatibilidade v1–v4 requer adaptadores independentes e fixtures; a existência de migrações SQLite não valida automaticamente JSON antigo. Versões futuras devem declarar formato/exportação separadamente do esquema quando necessário. exportedAt é informativo, não prova autenticidade.

## Validação antes de escrever
Limitar tamanho, número de registos, profundidade e comprimentos; validar UTF-8, JSON objecto, listas, campos, tipos e duplicados. Não converter IDs ou centavos através de double. Rejeitar formatos não reconhecidos com erro por tabela/campo, sem expor conteúdo pessoal em logs. Tratar campos futuros desconhecidos com política explícita por versão, sem os descartar silenciosamente.

Validar IDs positivos e únicos por tabela, chaves textuais de Achievements/ExperienceEvents, preferências singleton id=1, referências e ausência de ciclos nas metas. Validar enums, booleanos, limites, números finitos, valores monetários positivos e moedas suportadas. Respeitar datas civis, timestamps, precisão de Tasks.due e histórico de XP, sem recalcular pontos ou datas de conquistas. Verificar UNIQUE hábito/dia, orçamento/categoria/mês/moeda, regra/dia e uma única sessão de foco em curso. Contribuições e poupanças têm de partilhar moeda.

Nunca interpolar SQL recebido no ficheiro; usar listas de campos permitidos e parâmetros. Não assumir que a saída da própria app é fiável depois de o ficheiro ser editado.

## IDs, relações e duplicação
Proposta inicial: restauro completo em instalação vazia ou substituição integral com confirmação explícita e cópia de recuperação consistente do estado anterior. Não mesclar automaticamente. Reimportar não deve acrescentar linhas ao estado anterior. Preservar IDs, fontes de XP, códigos de conquistas e relações; não usar save() genérico sem adaptação, porque id fornecido faz UPDATE e não INSERT.

Importar com dependências controladas: criar metas primeiro sem parent_id e repor hierarquia após inserir todas; inserir FinancialTransactions sem recurring_id e RecurringOccurrences sem transaction_id, depois repor as referências circulares quando todos os destinos existirem. Validar integridade final antes do commit. Manter foreign_keys activas; não retirar triggers para aceitar dados inválidos. Adaptador dedicado deve especificar a ordem exacta e ser testado.

Restabelecer sequências AUTOINCREMENT acima dos IDs importados. Ao substituir uma base existente, considerar também a maior sequência anterior para evitar reutilizar IDs de alarmes antigos. Uma futura mesclagem exigiria remapeamento de todas as FKs e fontes de XP; comparação de títulos não identifica duplicados com segurança.

## Falhas e recuperação
1. Fazer parsing e validação completos sem modificar a base activa.
2. Preparar uma base temporária e validar foreign_key_check, integridade, contagens, totais por moeda, IDs e histórico.
3. Preservar uma cópia SQLite consistente anterior via mecanismo adequado, fechando ligação/checkpoint se necessário; não copiar só o ficheiro principal de uma base aberta com WAL.
4. Suspender novas escritas durante a substituição. Definir transacção ou troca de ficheiro recuperável com marcador de estado e recuperação após interrupção. Nunca apagar a cópia anterior antes de confirmar reabertura.
5. Operações de notificações não fazem parte da transacção SQLite: cancelar alarmes antigos e reconciliar os futuros só após o restauro confirmado. Pedir permissão quando aplicável; datas passadas não agendam. Se falhar, conservar dados restaurados e informar/repetir a reconciliação.
6. Decidir com aprovação como tratar foco activo importado: o prazo UTC pode estar ultrapassado. Não concluir nem atribuir XP automaticamente.

Não prometer restauro seguro até implementar e testar este protocolo. A exportação sequencial actual não garante um snapshot global sob escritas concorrentes; estabilizar a exportação antes de a usar como garantia de recuperação.

## Testes necessários
Round-trip v5 nas 20 tabelas, IDs não sequenciais, hierarquia, relações circulares financeiras, datas sem hora, todas as moedas, XP/conquistas e preferências. Ficheiros truncados, grandes, malformados, versão futura, tabelas ausentes, FKs órfãs, ciclos, chaves duplicadas, moedas incompatíveis, NaN/infinito e inteiros fora do intervalo.

Interrupção em cada etapa, falha de disco/permissão, rollback/reabertura, WAL, repetição da importação, preservação das sequências, notificações antigas/futuras e foco activo. Verificar que uma importação recusada não muda qualquer dado. Testar cópia anterior e recuperação num Android real, incluindo assinatura de actualização.
