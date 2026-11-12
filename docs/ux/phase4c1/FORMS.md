# Formulários — divulgação progressiva e compatibilidade

FormSheet plana e opaca, uma coluna, título curto, Cancelar/Voltar, campos com rótulo persistente e acção principal. Os wireframes são propostas de estrutura, não substituições de Editor ou QuickTaskSheet. A lista seguinte é requisito de preservação para uma futura implementação autorizada.

## Criar tarefa

Primeiro nível: **Nome** (rótulo proposto para o actual título; sem mudar chave title), Dia contextual opcional, associações herdadas visíveis, Guardar e Mais opções. Mostrar Sem data quando vazio; Retirar dia separado. Não herdar hora implícita nem confundir dia com um segundo prazo.

Preservar exactamente o fluxo 4B: Guardar e adicionar outra aparece com nome não vazio ou ao expandir opções; ao guardar outra mantém dia/meta/disciplina e limpa título, hora, lembrete, prioridade e importância, recolhe opções e repõe foco. Guardar fecha só após resposta. IME envia pela mesma operação protegida; duplo toque/fecho durante gravação não duplicam registos. Criar outra tarefa não altera a já guardada.

Mais opções revela hora, lembrete, prioridade Baixa/Normal/Alta, importante, meta e disciplina. O estado actual do lembrete e qualquer aviso relevante não devem ficar invisíveis ao recolher se afectarem a gravação. Tirar dia/hora desliga e cancela conforme o serviço existente; só dia+hora permite activar. Recusa de permissão guarda a tarefa e anuncia lembrete indisponível, sem oferecer repetir criação do mesmo registo.

Não mudar TaskOperations nem duplicar persistência para obter um novo aspecto. due conserva NULL / YYYY-MM-DD / ISO com hora. Editar usa o editor existente no mesmo ID, preservando created e campos não tocados. Cancelar limpo fecha; sujo confirma continuar/descartar; barreira/arrasto mantêm o contrato 3B; rascunho só em memória. Não criar Desfazer novo ou prometer recuperação após encerramento. Origem, filtro, associações e confirmação inline preservados.

## Criar meta

Primeiro nível: **Nome**, **Prazo opcional em dias**, pré-visualização absoluta quando preenchido, **Criar** e **Acompanhamento adicional**. Não pedir Métrica de sucesso e Valor pretendido como requisitos iniciais universais. Campo de prazo vazio é válido. Erro associa-se ao campo; só o nome é obrigatório no modo binário.

Acompanhamento adicional: grupo «Concluir quando alcançar / Por etapas / Com números». Sem escolha, binário. Por etapas: pode criar a meta sem etapas e acrescentá-las depois; nenhuma % provisória. Com números: revelar unidade, valor inicial e alvo, validar finitos e target > initial; novo actual = inicial, mantendo o contrato existente. Meta antiga conserva sempre a métrica visível no seu modo numérico, não a esconde como binária.

Mais detalhes: descrição, categoria/área, horizonte, meta principal com prevenção de ciclos, data absoluta alternativa e acesso ao editor completo; relações/histórico/etapas permanecem. O horizonte continua a ter valor compatível do modelo para novas metas, sem se tornar um campo obrigatório de decisão no primeiro nível; a futura fase técnica explicitará o valor por defeito antes de implementar. Não trocar o horizonte de metas antigas ao editar o nome.

Criar espera confirmação da persistência; erro mantém rascunho e não reenvia sozinho. Cancelar/Voltar: proposta de confirmação de rascunho sujo para o novo formulário, alinhada com tarefas. **O Editor completo actual ainda não tem este contrato**: não declarar que já existe nem alterar silenciosamente todos os editores. Tratar a mudança num incremento autorizado com testes próprios. Após criar, manter comportamento do FAB 4B: Metas/Activas com a nova meta visível; outros pontos de entrada preservam o seu retorno contratado.

A persistência durável dos modos e concluir/reabrir binário/etapas dependem da decisão descrita em GOALS. A criação simplificada de metas é proposta de produto com bloqueio técnico declarado, não uma alteração cosmética imediatamente implementável em v5.

## Estados e retorno comuns

| Situação | Resposta proposta / preservação |
| --- | --- |
| Nome vazio | Erro textual junto do campo após tentativa de envio; foco no campo, não só borda vermelha |
| A guardar | Bloquear novo envio/fecho, manter altura, anúncio único; nunca perder rascunho antes do resultado |
| Erro de escrita | Campos intactos, Tentar novamente explícito; não mudar ID nem inserir cópia por optimismo |
| Sucesso com aviso de lembrete | Registo salvo uma vez; aviso específico, não «erro ao guardar» genérico |
| Picker aninhado | Foco/Voltar no modal superior; cancelar picker não cancela todo o formulário |
| Opções recolhidas | Valores continuam presentes; contexto/aviso relevante resumido; recolher não limpa |
| Teclado e 200% | Scroll e acções acessíveis, sem fonte reduzida, mesma ordem de foco |
| Eliminar/editar legado | Manter os avisos e capacidades existentes; não prometer desfazer eliminação |

Não introduzir confirmação adicional em Guardar tarefa nem alterar os pontos globais Evento/Tarefa/Meta já preservados. Rótulo «Nome» pode ser avaliado com utilizadores; não autoriza renomear a coluna SQLite ou invalidar testes existentes.
