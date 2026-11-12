// Design artefact validation only. Requires local Playwright + Chromium.
// Serve repository root with python3 -m http.server 8765 --bind 127.0.0.1.
const {chromium}=require('playwright'),fs=require('fs'),path=require('path');
(async()=>{
 const root=__dirname, browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
 try{
 const page=await browser.newPage({viewport:{width:1360,height:1100},deviceScaleFactor:2});
 const pageErrors=[];page.on('pageerror',x=>pageErrors.push(x.message));
 await page.goto('http://127.0.0.1:8765/docs/ux/phase4c2/prototypes.html');await page.evaluate(()=>document.fonts.ready);
 const scenes=await page.locator('.review').evaluateAll(xs=>xs.map(x=>({slug:x.id,title:x.getAttribute('aria-label')})));
 const violations=[],checks=[];
 for(const theme of ['light','dark'])for(const width of ['320','360','390'])for(const scale of ['1','2']){
  await page.selectOption('#theme',theme);await page.selectOption('#width',width);await page.selectOption('#scale',scale);
  const result=await page.locator('.review').evaluateAll(xs=>xs.map(x=>{
   const d=x.querySelector('.device'),sc=d.querySelector('.content'),r=d.getBoundingClientRect();
   const small=[...d.querySelectorAll('button,select,.textinput,summary,.checktarget,.switchlabel')].filter(el=>{const z=el.getBoundingClientRect();return z.width>0&&z.height>0&&(z.width<47.9||z.height<47.9)}).map(el=>el.id||el.textContent.trim().slice(0,35));
   const nav=d.querySelector('.bottomnav'),n=nav?.getBoundingClientRect();
   const action=d.querySelector('.footeraction'),a=action?.getBoundingClientRect();
   const fab=d.querySelector('.fab'),f=fab?.getBoundingClientRect();
   return {id:x.id,overflow:d.scrollWidth>d.clientWidth+1||sc.scrollWidth>sc.clientWidth+1,small,wrongHeight:Math.abs(r.height-800)>1,hiddenNav:n&&(n.bottom>r.bottom+1||n.top<r.top),hiddenAction:a&&(a.bottom>r.bottom+1||a.top<r.top),hiddenFab:f&&(f.bottom>r.bottom+1||f.top<r.top)};
  }).filter(x=>x.overflow||x.small.length||x.wrongHeight||x.hiddenNav||x.hiddenAction||x.hiddenFab));
  if(result.length)violations.push({theme,width,scale,result});checks.push({theme,width,scale});
 }
 if(violations.length){fs.writeFileSync(path.join(root,'layout-failures.json'),JSON.stringify(violations,null,2));throw Error(JSON.stringify(violations).slice(0,2000));}
 await page.selectOption('#width','360');await page.selectOption('#scale','1');
 fs.mkdirSync(path.join(root,'previews'),{recursive:true});
 for(const theme of ['light','dark']){
  await page.selectOption('#theme',theme);
  await page.locator('.content').evaluateAll(xs=>xs.forEach(x=>x.scrollTop=0));
  for(const s of scenes)await page.locator('#'+s.slug).screenshot({path:path.join(root,'previews',s.slug+'-'+theme+'.png')});
 }
 // 4B discovery and explicit validation remain visible in the task prototype.
 const task=page.locator('#task-empty');
 if(await task.locator('.another').isVisible())throw Error('another initially visible');
 await task.locator('[data-title]').fill('Uma tarefa de teste');
 if(!await task.locator('.another').isVisible())throw Error('another absent with title');
 await task.locator('[data-title]').fill('');await task.locator('summary').click();await task.locator('.another').waitFor({state:'visible'});
 if(!await task.locator('.another').isVisible())throw Error('another absent with advanced options');
 // New goal starts without an artificial numeric requirement.
 const goal=page.locator('#meta-form');await goal.locator('.submit').click();
 if(await goal.locator('[data-title]').getAttribute('aria-invalid')!=='true')throw Error('name validation');
 await goal.locator('[data-title]').fill('Enviar candidatura');await goal.locator('[data-days]').fill('30');
 if(!(await goal.locator('.date-preview').innerText()).includes('12/12')&&!(await goal.locator('.date-preview').innerText()).includes('dez'))throw Error('absolute date');
 await goal.locator('summary').first().click();await goal.locator('[data-mode][value=numeric]').check();
 if(!await goal.locator('[data-target]').isVisible())throw Error('numeric fields absent');
 await goal.locator('[data-unit]').fill('livros');await goal.locator('[data-target]').fill('0');await goal.locator('.submit').click();
 if(!(await goal.locator('.form-error').innerText()).includes('superar'))throw Error('target validation');
 await goal.locator('[data-target]').fill('12');await goal.locator('.submit').click();
 if(!(await page.locator('#simulation').innerText()).includes('Nenhum dado'))throw Error('simulation');
 // Keyboard, viewport and simulated IME (not a native keyboard).
 const focusChecks=[];
 for(const theme of ['light','dark'])for(const scale of ['1','2']){
  await page.selectOption('#theme',theme);await page.selectOption('#scale',scale);await page.check('#keyboard');
  const f=page.locator('#task-advanced [data-title]');await f.focus();await page.keyboard.press('Tab');await page.keyboard.press('Shift+Tab');await page.waitForTimeout(40);
  const state=await f.evaluate(x=>{const a=x.getBoundingClientRect(),v=x.closest('.content').getBoundingClientRect(),s=getComputedStyle(x);return {width:s.outlineWidth,style:s.outlineStyle,within:a.top>=v.top-1&&a.bottom<=v.bottom+1}});
  if(state.width!=='2px'||state.style!=='solid'||!state.within)throw Error('focus/keyboard '+JSON.stringify(state));focusChecks.push({theme,scale,...state});
 }
 let visibleFormFocusTargets=0;
 for(const id of ['task-advanced','meta-numeric']){
  const controls=page.locator('#'+id+' .content input:not([type=radio]):not([disabled]),#'+id+' .content select,#'+id+' .content summary');
  for(let i=0;i<await controls.count();i++){
   const el=controls.nth(i);if(!await el.isVisible())continue;await el.focus();await page.waitForTimeout(25);
   const ok=await el.evaluate(x=>{const a=x.getBoundingClientRect(),v=x.closest('.content').getBoundingClientRect();return a.top>=v.top-1&&a.bottom<=v.bottom+1});
   if(!ok)throw Error('focused form control hidden '+id+' '+i);visibleFormFocusTargets++;
  }
 }
 await page.uncheck('#keyboard');await page.selectOption('#scale','1');
 const cancel=page.locator('#task-filled .sheetheading button');await cancel.click();
 if(!await page.locator('#discard').isVisible())throw Error('dirty modal');
 if(!(await page.evaluate(()=>document.activeElement.textContent)).includes('Continuar'))throw Error('safe initial focus');
 await page.keyboard.press('Shift+Tab');if(!await page.evaluate(()=>document.activeElement.closest('dialog')!==null))throw Error('modal focus escaped');
 await page.keyboard.press('Escape');if(await page.locator('#discard').isVisible())throw Error('Escape');
 if(!await cancel.evaluate(x=>x===document.activeElement))throw Error('focus restoration');
 // Stage counting never completes the goal by itself.
 const stages=page.locator('#meta-steps .checktarget input');for(let i=0;i<await stages.count();i++)await stages.nth(i).check();
 if(!await page.locator('#meta-steps [data-step-complete]').isVisible())throw Error('stage completion option');
 if(!(await page.locator('#meta-steps .statusline').innerText()).includes('4 de 4'))throw Error('stage count');
 // Transparent and solid modes are independently inspectable.
 await page.check('#solid');const solid=await page.locator('#progresso-map .glass').evaluate(x=>({bg:getComputedStyle(x).backgroundColor,blur:getComputedStyle(x).backdropFilter}));
 if(solid.blur!=='none')throw Error('solid fallback');await page.uncheck('#solid');
 await page.emulateMedia({reducedMotion:'reduce'});
 if(!await page.evaluate(()=>matchMedia('(prefers-reduced-motion: reduce)').matches))throw Error('reduced motion');
 const motion=await page.locator('#progresso-map .glass').evaluate(x=>({animation:getComputedStyle(x).animationDuration,transition:getComputedStyle(x).transitionDuration}));
 if(motion.animation!=='0s'||motion.transition!=='0s')throw Error('motion');await page.emulateMedia({reducedMotion:'no-preference'});
 const cdp=await page.context().newCDPSession(page),ax=await cdp.send('Accessibility.getFullAXTree');
 const names=ax.nodes.filter(x=>!x.ignored).map(x=>x.name?.value||'');if(!names.includes('Nome da meta')||!names.includes('Prazo opcional em dias'))throw Error('accessible names');
 // Stress images at 200% with a simulated 280 px keyboard.
 await page.selectOption('#width','320');await page.selectOption('#scale','2');await page.check('#keyboard');
 for(const theme of ['light','dark']){await page.selectOption('#theme',theme);for(const slug of ['task-advanced','meta-numeric'])await page.locator('#'+slug).screenshot({path:path.join(root,'previews',slug+'-200-keyboard-'+theme+'.png')});}
 await page.uncheck('#keyboard');await page.selectOption('#scale','1');await page.selectOption('#width','360');
 // Observed differences with 4C.1, without altering its files.
 const before=await browser.newPage({viewport:{width:1360,height:1100}});await before.goto('http://127.0.0.1:8765/docs/ux/phase4c1/global.html');
 const baseline=await before.evaluate(()=>({todayDocumentHeight:document.querySelector('#hoje .device').getBoundingClientRect().height,financeSelects:document.querySelectorAll('#financas select').length,goalInputs:document.querySelectorAll('#meta input').length}));await before.close();
 await page.selectOption('#screen','meta-form');if(await page.locator('.review:visible').count()!==1)throw Error('case selector');await page.selectOption('#screen','all');await page.reload();await page.evaluate(()=>document.fonts.ready);
 await page.setViewportSize({width:2000,height:1100});
 await page.locator('.review').evaluateAll(xs=>xs.forEach(x=>x.hidden=!['hoje-filled','planear-filled','metas-filled','meta-form','estudos-filled','financas-filled','progresso-filled','task-empty','agenda','tarefas'].includes(x.id)));
 await page.locator('.content').evaluateAll(xs=>xs.forEach(x=>x.scrollTop=0));
 for(const theme of ['light','dark']){await page.selectOption('#theme',theme);await page.locator('.grid').screenshot({path:path.join(root,'previews','overview-'+theme+'.png'),scale:'css'});}
 if(pageErrors.length)throw Error(pageErrors.join('\n'));
 const result={scope:'conceptual browser prototype; not Flutter; no participant research',cases:scenes.length,combinations:checks.length,viewportChecks:scenes.length*checks.length,png:scenes.length*2+6,caseSelector:true,layoutViolations:violations,pageErrors,focusChecks,visibleFormFocusTargets,solidFallback:solid,reducedMotion:motion,chromiumAccessibleNames:true,baseline4c1:baseline,appTestsRun:false,participants:0,nativeValidationPending:true};
 fs.writeFileSync(path.join(root,'validation.json'),JSON.stringify(result,null,2)+'\n');fs.writeFileSync(path.join(root,'cases.json'),JSON.stringify(scenes,null,2)+'\n');console.log(JSON.stringify(result));
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
