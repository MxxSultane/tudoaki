# Medição Android — pendente de dispositivo

Não há resultados Android nesta fase. Tempos Linux debug de fases anteriores não são prova de abertura, scroll, memória ou jank num telefone. O APK debug entregue serve primeiro para percursos funcionais; não permite aprovar desempenho de distribuição.

## Ambiente e dados

Registar modelo/SoC/RAM, Android/API, bateria/temperatura, resolução/densidade/Hz, modo de navegação, app/serviços concorrentes, modo debug/profile, certificado, SHA/checksum, quantidade real de tarefas/hábitos/GoalProgress/sessões/XP e método/ferramentas. Conservar o mesmo conjunto ao comparar builds. Separar primeira execução, arranque frio, quente e dados vazios/preenchidos.

Para estudar custo Flutter, preparar posteriormente um build **profile**, com a mesma revisão e assinatura compatível verificada, usando `flutter run --profile -d SERIAL` ou APK profile inspeccionado antes de instalar. A passagem para profile não autoriza substituir uma instalação de outra assinatura nem mudar o identificador. Não foi preparado/instalado um profile nesta fase, pois não há aparelho acessível. Não usar modo debug como substituto silencioso de uma medição profile.

Volumes sugeridos: 100/1000/10000 registos reais dos modelos suportados, exclusivamente sintéticos. Registar o volume efectivamente disponível; não o inferir pelo tamanho do JSON. Para volumes impraticáveis de introduzir pela UI, preparar um harness de teste separado e aprovado; não inventar importação, API de seed em produção ou copiar SQLite por cima de dados pessoais. Sem tal fixture segura, a linha de grande volume fica bloqueada, não aprovada.

## Protocolo

| Medida | Método | Registo |
| --- | --- | --- |
| Abertura | Em telefone de testes, fechar app e abrir pelo ícone; vídeo/Timeline até primeiro ecrã utilizável. Fazer 5 preparações e pelo menos 20 amostras independentes por cenário; separar frio/quente. | Mediana/p95/amostras e critério de "utilizável"; não confundir actividade nativa criada com primeiro frame Flutter interactivo |
| Scroll | DevTools Performance em profile, 15 s do mesmo gesto/lista e mesmo conjunto; 5 repetições; exportar trace | Tempos UI/raster, frames lentos, p95/jank, Hz/orçamento de frame real do dispositivo |
| Módulos | Mesmo percurso Hoje→Planear→Metas→Mais→Estudos→Finanças→Progresso, 20 ciclos controlados | Tempo até conteúdo/acções disponíveis, erros e consultas observadas; distinguir consulta/IO de raster |
| Formulários | Abrir/fechar criação rápida e editores com/sem IME, mesmos dados, 20 vezes | Latência, frames UI/raster, foco/scroll e falhas; não contar animação/teclado como consulta repetida sem evidência |
| Histórico/Percurso | 100/1k/10k quando disponíveis, abrir Progresso, carregar mais, Linha/Lista, filtros e origem | Tempo/memória/frame timings e quantidade montada, nenhuma escrita ou XP por apresentação |
| Memória | DevTools Memory e `adb -s SERIAL shell dumpsys meminfo mz.lifeos.lifeos`, no início/pós-percurso/após 20 ciclos | PSS/heap/nativo/raster, GC, crescimento persistente e ferramenta/instante; não comparar unidades diferentes |

Comandos auxiliares só em dispositivo de testes validado:

```sh
adb -s SERIAL shell am force-stop mz.lifeos.lifeos
adb -s SERIAL shell am start -W -n mz.lifeos.lifeos/mz.tudoaki.tudo_aki.MainActivity
adb -s SERIAL shell dumpsys meminfo mz.lifeos.lifeos
adb -s SERIAL shell dumpsys gfxinfo mz.lifeos.lifeos framestats
```

`force-stop` não limpa dados, mas interrompe a aplicação/notificações até nova abertura; distinguir esse ensaio de background/retoma normal. `am start -W` mede a abertura da actividade Android, não todo o tempo até a UI Flutter estar pronta. `gfxinfo` é auxiliar e pode não representar integralmente as frames Flutter; exportar também Timeline UI/raster do engine. Não instalar root, alterar assinatura, limpar dados ou desligar políticas para obter métricas.

Definir gates quantitativos com o responsável depois de medir o aparelho representativo; não inventar um limiar para declarar sucesso. Anexar raw samples/traces e ambiente, incluindo variação térmica e interferência. Se a causa exigir SQL/paginação/novos contratos, abrir bloqueio técnico separado, sem alterar a arquitectura nesta preparação.
