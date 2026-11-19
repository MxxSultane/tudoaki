from pathlib import Path
import json,struct,hashlib,subprocess
root=Path(__file__).resolve().parents[1]; evidence=root/'docs/ux/phase4c3f'; base='98d281385bd02ccd47ac97cafbc698efeb29682f'
previews=root/'docs/ux/previews/phase4c3f'
pairs=[]
for p in sorted((previews/'before').glob('*.png')):
 q=previews/'after'/p.name
 assert q.exists(),q
 def info(f):
  raw=f.read_bytes(); w,h=struct.unpack('>II',raw[16:24]);return {'width':w,'height':h,'sha256':hashlib.sha256(raw).hexdigest()}
 a,b=info(p),info(q);assert (a['width'],a['height'])==(b['width'],b['height']),p
 pairs.append({'name':p.name,'before':a,'after':b,'identical':a==b})
assert len(pairs)==336,len(pairs)
(evidence/'visual-validation.json').write_text(json.dumps({'base':base,'renderer':'Flutter Linux debug; PNG at 2x logical size','fixed_clock':'2026-11-18T10:30:00','pairs':pairs,'pair_count':336,'png_count':672,'not_android_physical':True},indent=2)+'\n')
lines=['# Capturas Flutter — integração global','', '336 pares / 672 PNG. Renderer Flutter Linux, não HTML nem Android físico. Mesmos dados sintéticos, relógio 18/11/2026 10:30, fontes, temas e dimensões em cada par. O relógio da fixture é fixo e não a data de entrega. DPR lógico 1; exportação PNG 2×.','', 'Matriz: 28 cenários × claro/escuro × 320×640, 360×800, 390×844 × texto 100/200%. Teclado de 280 dp simulado nos cenários quick-keyboard com texto a 200%; não é uma IME. Foco nav-focus é solicitado ao destino Mais, nos dois estados da implementação. Erros de leitura/loading são injectados; não gravam dados reais.','', 'A recolha inicial encontrou 12 falhas do auxiliar de criação de hábito (contexto fora do shell); as 12 capturas foram completadas com o contexto correcto antes de alterar produção. O foco da barra foi recolhido novamente numa worktree isolada do HEAD base. A primeira matriz depois encontrou overflow semanal em dois casos, corrigido antes da execução final estrita.','', '## Comparações seleccionadas','']
for name in ['hoje-filled-light.png','plan-tomorrow-dark.png','plan-week-320-200-light.png','goals-light.png','academics-filled-dark.png','finance-filled-light.png','progress-filled-dark.png','progress-timeline-320-200-light.png','tasks-light.png','calendar-dark.png','habits-light.png','more-320-200-light.png','editor-320-200-dark.png','quick-keyboard-320-200-light.png','nav-focus-dark.png','read-error-320-200-light.png']:
 lines += ['### '+name,'',f'Antes | Depois','--- | ---',f'![Antes](../previews/phase4c3f/before/{name}) | ![Depois](../previews/phase4c3f/after/{name})','']
lines+=['## Índice completo','','Cenário | Antes | Depois','--- | --- | ---']
for pair in pairs:
 n=pair['name'];lines.append(f'{n} | [Abrir](../previews/phase4c3f/before/{n}) | [Abrir](../previews/phase4c3f/after/{n})')
lines+=['','## Reprodução','','```sh','source tool/env.sh','export XDG_CONFIG_HOME=/workspace/.tools/config','flutter test --no-pub --dart-define=QUALITY_OUTPUT=docs/ux/previews/phase4c3f/after --dart-define=QUALITY_STRICT=true tool/capture_global.dart --reporter expanded','```','','Para repetir a base, usar uma worktree em '+base+' com o mesmo utilitário e fixtures, resolver dependências offline sem mudar o lockfile e mudar apenas QUALITY_OUTPUT. Não substituir produção nem dados reais para produzir capturas.']
(evidence/'CAPTURES.md').write_text('\n'.join(lines)+'\n')
protected=['android','pubspec.yaml','pubspec.lock','lib/core/database','lib/core/notifications','lib/features/tasks/domain','lib/features/finance/finance_rules.dart','lib/features/finance/finance_repository.dart','lib/features/finance/finance_providers.dart','lib/features/academics/academic_rules.dart','lib/features/academics/study_repository.dart','lib/features/academics/focus_timer.dart','lib/features/progress/progress_rules.dart','lib/app/navigation','lib/app/providers.dart','lib/features/goals/domain','lib/features/habits']
checks=[{'path':p,'unchanged':not subprocess.check_output(['git','diff','--name-only',base,'--',p],cwd=root).strip()} for p in protected];assert all(x['unchanged'] for x in checks)
ancestors={}
for name,sha in [('4C.3A','3b86f88'),('4C.3B','058ae62'),('4C.3C','49e1724'),('4C.3D','ffc9b0b'),('4C.3E',base)]:
 ancestors[name]={'commit':subprocess.check_output(['git','rev-parse',sha],cwd=root,text=True).strip(),'ancestor':subprocess.call(['git','merge-base','--is-ancestor',sha,'HEAD'],cwd=root)==0}
(evidence/'preservation.json').write_text(json.dumps({'base':base,'protected':checks,'ancestors':ancestors,'main':subprocess.check_output(['git','rev-parse','origin/main'],cwd=root,text=True).strip(),'no_migrations':True,'real_data_used':False,'production_release':False,'merge':False},indent=2)+'\n')
# Luminance of roles actually used, across all three opaque backgrounds.
def lum(h):
 c=[int(h[i:i+2],16)/255 for i in (0,2,4)];return sum(v*w for v,w in zip([v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in c],[.2126,.7152,.0722]))
colours={'light':{'background':'F7F8F5','surface':'FFFFFF','soft':'E8EDE6','ink':'202B29','muted':'5D6965','action':'456C50','outline':'66736D'},'dark':{'background':'18201D','surface':'202B29','soft':'28352E','ink':'F2F5EF','muted':'BCC6BE','action':'9ECB8F','outline':'8E9D92'}}
contrast=[]
for theme,c in colours.items():
 for fg in ['ink','muted','action','outline']:
  for bg in ['background','surface','soft']:
   a,b=sorted([lum(c[fg]),lum(c[bg])]);ratio=(b+.05)/(a+.05);threshold=3 if fg=='outline' else 4.5;assert ratio>=threshold
   contrast.append({'theme':theme,'foreground':fg,'background':bg,'ratio':round(ratio,3),'threshold':threshold,'pass':ratio>=threshold})
(evidence/'contrast-results.json').write_text(json.dumps(contrast,indent=2)+'\n')
print('336 pairs; protected paths unchanged; all contrast pairs pass')
