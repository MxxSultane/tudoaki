# Roteiro Android real — A a J

**Estado: preparado, não executado.** Preencher [results.csv](results.csv), sem substituir resultados desconhecidos por aprovados. Ver [instalação segura](INSTALLATION.md) e roteiro 4C.3F para os gates anteriores. Este documento usa a numeração A–J da 4C.4A.

## Sessão de teste

Registar: operador/data, SHA e SHA-256 do APK, certificado, modelo/API/Android, largura lógica/resolução/densidade, escala de texto efectiva, orientação, IME/versão, TalkBack/versão, modo de navegação e modo de compilação. Guardar serial em registo privado. Estado inicial: dispositivo controlado sem dados pessoais; preferência de moeda MZN e gamificação ligada, tema claro; guardar valores originais das preferências do telefone antes de os alterar.

Usar dia civil **D** do telefone no início e D+1 calculado pelo calendário; registar fuso. Não hardcodificar a data desta entrega. Se a sessão atravessar meia-noite, registar esse facto e recalcular expectativas sem alterar datas antigas.

Dados sintéticos sugeridos: tarefa «QA4A tarefa», meta «QA4A leitura» (livros, inicial 0, alvo 12), disciplina «QA4A Matemática», trabalho «QA4A apresentação», hábitos «QA4A Ler», «QA4A Caminhar», «QA4A Rever», receita 2000,50 MT e despesa 350,25 MT, ambas no mês/moeda testados. Anotar IDs pelo export JSON e não apenas nomes; não duplicar fixtures numa repetição sem identificar a nova sessão.

| ID | Passos na interface | Resultado esperado |
| --- | --- | --- |
| A | Hoje → Adicionar tarefa; título QA4A tarefa; Guardar. Mais → Tarefas; editar o título; Guardar. Concluir → reabrir → concluir → reabrir. | Mesmo ID/created/relações e uma só tarefa; estado muda; apenas um evento de 10 XP por ID com gamificação ligada. Rascunho cancelado não grava. |
| B | Planear → Amanhã; criar tarefa «QA4A amanhã» ou reagendar a tarefa A para D+1. Voltar a Hoje em D e consultar Tarefas/Planear Amanhã; consultar D+1 na Agenda. | D+1 guardado exactamente, sem cópia. Não aparece como tarefa do dia D só por ter sido criada hoje. Aparece no dia correcto e mantém ID/associações; não se confunde prazo com planeamento. |
| C | Metas → +; nome QA4A leitura; Medir com números; livros/12/inicial 0; Criar. Abrir, editar nome, guardar; registar valor 3; consultar histórico. | Meta numérica, current 3, target 12, unidade livros; histórico real datado. Editar não apaga prazo/histórico. Não activar modo binário/etapas nem adicionar XP por registar valor. |
| D | Mais → Estudos → Adicionar disciplina; criar QA4A Matemática. Abrir disciplina → Adicionar trabalho; título QA4A apresentação; Guardar. Editar o trabalho. | Uma disciplina, trabalho em Tasks com subject_id correcto; mesmo ID após edição. Sem data é válido; consultar Tarefas confirma a mesma entidade, não cópia. |
| E | Mais → Finanças; no mesmo mês/MZN registar receita 2000,50 e despesa 350,25; consultar os dois movimentos e totais. Mudar mês/moeda e voltar. | 200050 e 35025 cêntimos, resultado 165025 cêntimos/1650,25 MT neste conjunto isolado. Sem soma entre moedas/conversão; trocar filtros não altera os movimentos. Comparar com baseline se houver outros registos de teste. |
| F | Mais → Hábitos; criar três títulos distintos; registar cada um no dia D. Sair/voltar, editar o primeiro, retirar e voltar a registar no mesmo dia. | Todos persistidos; três registos no estado final; cinco XP por hábito/dia uma vez. Não desaparece o acesso a criar após o primeiro. |
| G | Mais → Progresso; observar conclusão registada e hábitos/valor de meta conforme estado final. Abrir Percurso → Linha/Lista → origem. | Mesmos registos/valores/datas nas duas vistas; tarefa reaberta não é falsa conclusão actual; hora ausente explicitada. Consulta/filtros não duplicam XP ou escrevem progresso. Origem válida abre sem erro de navegação. |
| H | Alternar Hoje → Planear → Metas → Mais → Planear; repetir com dia/modo seleccionado, scroll e filtros alterados. Abrir folha e pressionar Voltar. | Quatro destinos e nove acessos de Mais mantidos; estado dos ramos conforme contrato. Modal superior fecha primeiro; não perde contexto nem executa acção ao tocar em conteúdo bloqueado. |
| I | Abrir criação rápida e editores de tarefa/meta/hábito/finanças/estudo. Com IME real aberto escrever título longo, números com vírgula, activar opções, gerar erro válido, deslocar até Guardar/Cancelar/Guardar outra. | Rótulo e erro legíveis, foco não oculto, scroll e acções alcançáveis. Guardar outra mantém contexto previsto; cancelar/descarte segue o comportamento existente, sem gravação oculta. Não presumir descarte universal no editor legado. |
| J | Guardar dados e exportação. Criar sessão de foco controlada, iniciar e pausar; anotar estado/tempo restante. Background/retoma, bloquear/desbloquear, fechar e abrir pelo ícone; opcionalmente terminar processo em dispositivo de testes. Comparar dados/export e preferências. Repetir depois de uma actualização compatível. | Tarefas, metas, disciplinas, valores/moedas, hábitos, XP e configurações preservados; sessão pausada não reinicia nem conclui sozinha. Foco a correr usa a regra persistida de tempo, não pausa implícita. Sem novo XP por retomar/consultar. |

No conjunto isolado, A gera 10 XP e F gera 15 XP; B/C/D/E e consultas não acrescentam XP. Se A terminar reaberta, o reconhecimento continua persistido, mas a actividade actual de conclusão não deve ser inventada. Registar quaisquer sessões concluídas ou outras acções que expliquem XP adicional; não forçar um total ignorando a fixture real. Conquistas mantêm o catálogo/regras existentes, sem XP extra.

## Acessibilidade real

Executar nos dois temas e texto normal/ampliado até 200% ou máximo real disponível. Registar a escala efectiva: Android recente pode usar escala não linear; um valor de preferência não prova a dimensão renderizada de todos os rótulos. Registar a largura real, sem chamar 320/360/390 dp a um aparelho que não tem essa configuração.

- TalkBack: ler todos os destinos/áreas, títulos, filtros seleccionados, checkbox, botões de ícone, campos obrigatórios, erros, moedas/valores, datas sem hora e Linha/Lista. Registar nome/papel/estado, ordem, duplicações e pontos inacessíveis. Decorativos não devem criar passos inúteis.
- Barra inferior a 200%: todos os rótulos e destinos presentes, toque/foco separados, ordem Hoje/Planear/Metas/Mais, selecção compreensível e leitura íntegra. Avaliar com uma pessoa se a quebra de linha prejudica compreensão; não aprovar só por não haver overflow.
- Foco: com teclado físico/virtual disponível, Tab/Shift+Tab/Enter/Espaço; contorno visível, retorno após modal, acção segura no diálogo. Registar qualquer controlo sem foco perceptível.
- Toque: verificar bounds em dp com Layout Inspector/acessibilidade Android quando disponíveis e tentativa real; ícone pequeno não implica alvo pequeno. Padrão interno ≥48×48 dp.
- IME/SafeArea: repetir I com teclado aberto, gestos e três botões; orientações suportadas, recortes e barras do sistema. Não desactivar protecções do telefone para conseguir um resultado.
- Contraste em contexto: inspeccionar texto normal/estados e controlos essenciais em fundos reais; referências 4,5:1 texto e 3:1 não textual. Registar captura sem compressão e ferramenta/método; matriz de tokens anterior não substitui verificação em contexto.
- Movimento reduzido: activar a preferência real disponível, anotar como foi activada e repetir navegação/expansões/Percurso. Não confundir menor animação com transparência; não inventar uma preferência do sistema inexistente.

Matriz mínima: tema claro/escuro × normal/ampliado × retrato/horizontal suportado. Cobrir TalkBack e IME em cada tema; dispositivos/larguras adicionais ficam explicitamente pendentes se não existirem. Não declarar certificação WCAG.

## Preservação por actualização

Cumprir o preflight de assinatura/versão em INSTALLATION.md. Com dados controlados, exportar antes/depois e comparar todas as tabelas, IDs/FKs, datas exactas, valores monetários e moeda, GoalProgress, HabitCompletions, StudySessions, ExperienceEvents, Achievements e UserPreferences. Ignorar apenas metadados de exportação variáveis; explicar alterações esperadas pela operação de teste, nunca diferenças de dados sem causa.

`lifeos.sqlite` permanece no local existente e schema v5. Não copiar uma base antiga por cima, executar SQL no telefone real, limpar armazenamento ou remover a app. Igualdade de arquivos Git não prova preservação de dados num telefone.

## Evidência e gravidade

Preencher observado, problemas, passos efectivamente realizados, severidade, data/operador, SHA e evidência em cada linha do CSV. Estados: NÃO EXECUTADO, BLOQUEADO, APROVADO, REPROVADO. Severidade só para um problema observado: S0 perda/integridade de dados; S1 impede percurso essencial; S2 dificulta utilização/acessibilidade; S3 cosmético. Acrescentar reprodução curta, esperado/observado e captura/vídeo reais. Não criar maquetas como evidência.

Capturas opcionais, só após confirmar dados sintéticos e destino:

```sh
adb -s SERIAL exec-out screencap -p > android-qa-cenario.png
adb -s SERIAL shell screenrecord /sdcard/qa4a-video.mp4
adb -s SERIAL pull /sdcard/qa4a-video.mp4
```

A gravação usa um ficheiro de teste próprio; não apagar conteúdos preexistentes para libertar espaço. Guardar logs sem dados pessoais e IDs de dispositivo fora do relatório público.
