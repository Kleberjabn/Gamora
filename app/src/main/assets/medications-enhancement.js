(function(){
  'use strict';
  var KEY='gamoravet_full_v8';
  var editId=0;
  var lastRendered='';

  function $(id){return document.getElementById(id)}
  function load(){try{return JSON.parse(localStorage.getItem(KEY))||{}}catch(e){return{}}}
  function save(s){localStorage.setItem(KEY,JSON.stringify(s))}
  function esc(v){return String(v==null?'':v).replace(/[&<>"']/g,function(m){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]})}
  function petName(state,id){var p=(state.pets||[]).find(function(x){return Number(x.id)===Number(id)});return p?p.name:'pet'}
  function notifId(id,offset){return Math.abs((Number(id)%2000000000)+offset)}
  function bridge(){return window.GamoraVetAndroid||null}
  function cancelMedAlarm(id){try{var b=bridge();if(b)b.cancelNotification(notifId(id,100000000))}catch(e){}}
  function nextMedMs(time){var p=String(time||'').split(':'),d=new Date();d.setHours(Number(p[0]||0),Number(p[1]||0),0,0);if(d.getTime()<=Date.now())d.setDate(d.getDate()+1);return d.getTime()}
  function scheduleMed(m,state){try{var b=bridge();if(b&&m.time)b.scheduleNotification(notifId(m.id,100000000),nextMedMs(m.time),'GamoraVet • Hora do medicamento',m.name+(m.dose?' — '+m.dose:'')+' para '+petName(state,m.petId))}catch(e){}}
  function dateKey(d){var x=d||new Date();return x.getFullYear()+'-'+String(x.getMonth()+1).padStart(2,'0')+'-'+String(x.getDate()).padStart(2,'0')}
  function nowText(){return new Date().toLocaleString('pt-BR')}
  function toast(msg){var t=$('toast');if(!t)return;t.textContent=msg;t.style.display='block';setTimeout(function(){t.style.display='none'},1800)}
  function currentConfirmation(state,medId){var day=dateKey();return (state.medAdministrations||[]).find(function(a){return Number(a.medId)===Number(medId)&&a.dateKey===day})}
  function renderHistoryFromStorage(){
    var list=$('historyList');if(!list)return;
    var state=load(),items=(state.history||[]).slice().sort(function(a,b){return Number(b.id||0)-Number(a.id||0)});
    list.innerHTML=items.map(function(x){return '<div class="card"><b>'+esc(x.title||'Registro de saúde')+'</b><div class="small">'+esc(x.date||'')+'</div><div>'+esc(x.note||'')+'</div></div>'}).join('')||'<div class="card empty">Nenhum registro de saúde.</div>';
    if($('rHistory'))$('rHistory').textContent=items.length;
  }

  function ensureForm(){
    var saveBtn=$('saveMed');if(!saveBtn)return false;
    if(!$('medEditId')){var hidden=document.createElement('input');hidden.type='hidden';hidden.id='medEditId';saveBtn.parentNode.insertBefore(hidden,saveBtn)}
    if(!$('cancelMedEdit')){var cancel=document.createElement('button');cancel.id='cancelMedEdit';cancel.className='btn ghost';cancel.type='button';cancel.textContent='Cancelar edição';cancel.style.display='none';cancel.style.marginLeft='8px';saveBtn.insertAdjacentElement('afterend',cancel);cancel.onclick=clearForm}
    saveBtn.onclick=saveMedication;return true;
  }
  function clearForm(){editId=0;if($('medEditId'))$('medEditId').value='';if($('medName'))$('medName').value='';if($('medDose'))$('medDose').value='';if($('medTime'))$('medTime').value='';if($('saveMed'))$('saveMed').textContent='Salvar e ativar lembrete';if($('cancelMedEdit'))$('cancelMedEdit').style.display='none'}
  function saveMedication(){
    var state=load();state.meds=state.meds||[];state.audit=state.audit||[];
    if(!(state.pets||[]).length){if(window.showView)window.showView('pets');return}
    var name=$('medName').value.trim(),dose=$('medDose').value.trim(),time=$('medTime').value,petId=Number($('medPet').value);if(!name||!time){toast('Informe medicamento e horário');return}
    var id=Number(($('medEditId')&&$('medEditId').value)||editId||0);
    if(id){var m=state.meds.find(function(x){return Number(x.id)===id});if(!m)return;cancelMedAlarm(m.id);m.petId=petId;m.name=name;m.dose=dose;m.time=time;scheduleMed(m,state);state.audit.unshift({id:Date.now(),at:nowText(),action:'Medicação editada: '+name});toast('Medicação atualizada e lembrete reagendado')}
    else{var med={id:Date.now(),petId:petId,name:name,dose:dose,time:time};state.meds.push(med);scheduleMed(med,state);state.audit.unshift({id:Date.now()+1,at:nowText(),action:'Medicação cadastrada: '+name});toast('Medicação salva e lembrete ativado')}
    save(state);clearForm();renderMeds();
  }
  window.editMed=function(id){var state=load(),m=(state.meds||[]).find(function(x){return Number(x.id)===Number(id)});if(!m)return;editId=Number(id);ensureForm();$('medEditId').value=String(id);$('medPet').value=String(m.petId);$('medName').value=m.name||'';$('medDose').value=m.dose||'';$('medTime').value=m.time||'';$('saveMed').textContent='Salvar alterações';$('cancelMedEdit').style.display='inline-block';window.scrollTo(0,0)};
  window.removeMed=function(id){var state=load();state.meds=state.meds||[];state.audit=state.audit||[];var m=state.meds.find(function(x){return Number(x.id)===Number(id)});if(!m)return;if(!confirm('Remover '+m.name+'?'))return;cancelMedAlarm(id);state.meds=state.meds.filter(function(x){return Number(x.id)!==Number(id)});state.audit.unshift({id:Date.now(),at:nowText(),action:'Medicação removida: '+m.name});save(state);clearForm();renderMeds();toast('Medicação removida')};
  window.confirmMedDose=function(id){
    var state=load();state.meds=state.meds||[];state.medAdministrations=state.medAdministrations||[];state.history=state.history||[];state.audit=state.audit||[];
    var m=state.meds.find(function(x){return Number(x.id)===Number(id)});if(!m)return;if(currentConfirmation(state,id)){toast('Esta dose já foi confirmada hoje');return}
    var now=new Date(),aid=Date.now(),confirmedText=now.toLocaleString('pt-BR'),pet=petName(state,m.petId);
    state.medAdministrations.unshift({id:aid,medId:m.id,petId:m.petId,name:m.name,dose:m.dose,time:m.time,dateKey:dateKey(now),confirmedAt:now.toISOString(),confirmedAtText:confirmedText});
    state.history.unshift({id:aid+1,source:'medication',medAdministrationId:aid,petId:m.petId,medId:m.id,title:'💊 Dose administrada: '+m.name,date:dateKey(now),note:'Pet: '+pet+(m.dose?' • Dose: '+m.dose:'')+' • Previsto: '+m.time+' • Administrado: '+confirmedText,status:'administrado'});
    state.audit.unshift({id:aid+2,at:confirmedText,action:'Dose confirmada: '+m.name});save(state);renderMeds();renderHistoryFromStorage();toast('Dose administrada registrada no histórico');
  };
  window.undoMedDose=function(id){
    var state=load();state.medAdministrations=state.medAdministrations||[];state.history=state.history||[];state.audit=state.audit||[];var c=currentConfirmation(state,id);if(!c)return;var m=(state.meds||[]).find(function(x){return Number(x.id)===Number(id)});
    state.medAdministrations=state.medAdministrations.filter(function(a){return Number(a.id)!==Number(c.id)});state.history=state.history.filter(function(h){return Number(h.medAdministrationId)!==Number(c.id)});state.audit.unshift({id:Date.now(),at:nowText(),action:'Confirmação de dose desfeita: '+(m?m.name:'medicamento')});save(state);renderMeds();renderHistoryFromStorage();toast('Confirmação desfeita e histórico atualizado');
  };
  function renderMeds(){var list=$('medList');if(!list)return;var state=load(),meds=(state.meds||[]).slice().sort(function(a,b){return String(a.time).localeCompare(String(b.time))});var html=meds.map(function(m){var c=currentConfirmation(state,m.id);var status=c?'<div class="status" style="margin-top:8px">✅ Dose administrada • '+esc(c.confirmedAtText)+'</div>':'<div class="small" style="margin-top:8px">Pendente para hoje</div>';var action=c?'<button class="btn ghost" onclick="undoMedDose('+m.id+')">Desfazer confirmação</button>':'<button class="btn" onclick="confirmMedDose('+m.id+')">✓ Confirmar dose</button>';return '<div class="card"><div><b>💊 '+esc(m.name)+'</b><div class="small">'+esc(petName(state,m.petId))+' • '+esc(m.dose)+' • '+esc(m.time)+'</div>'+status+'</div><div class="btn-row">'+action+'<button class="btn secondary" onclick="editMed('+m.id+')">Editar</button><button class="btn danger" onclick="removeMed('+m.id+')">Remover</button></div></div>'}).join('')||'<div class="card empty">Nenhuma medicação.</div>';if(list.innerHTML!==html){lastRendered=html;list.innerHTML=html}}
  function start(){if(!ensureForm()){setTimeout(start,100);return}renderMeds();renderHistoryFromStorage();var list=$('medList');if(list){new MutationObserver(function(){setTimeout(renderMeds,0)}).observe(list,{childList:true,subtree:true})}document.addEventListener('click',function(e){var med=e.target.closest&&e.target.closest('[data-view="meds"],button[onclick*="showView(\'meds\')"]');if(med)setTimeout(renderMeds,30);var hist=e.target.closest&&e.target.closest('[data-view="history"],button[onclick*="showView(\'history\')"]');if(hist)setTimeout(renderHistoryFromStorage,30)},true)}
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start);else start();
})();
