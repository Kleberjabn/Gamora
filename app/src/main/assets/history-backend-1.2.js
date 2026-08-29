(function(){'use strict';
var pending={},seq=0,remote=[];
function bridge(){return window.GamoraVetAndroid&&typeof window.GamoraVetAndroid.dataRequest==='function'}
function req(action,payload){return new Promise(function(resolve,reject){if(!bridge())return reject(new Error('Sincronização indisponível.'));var id='hist_'+Date.now()+'_'+(++seq);pending[id]={resolve:resolve,reject:reject};try{window.GamoraVetAndroid.dataRequest(id,action,JSON.stringify(payload||{}));}catch(e){delete pending[id];reject(e);}})}
function parse(body){if(!body)return null;try{return JSON.parse(body)}catch(e){return body}}
function err(body,status){var x=parse(body),m=x&&typeof x==='object'?(x.message||x.error_description||x.error||x.details):null;return new Error(m||('Falha ao consultar histórico [código '+status+']'));}
function esc(v){return String(v==null?'':v).replace(/[&<>"']/g,function(m){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]})}
function state(){try{return JSON.parse(localStorage.getItem('gamoravet_full_v8'))||{}}catch(e){return{}}}
function pets(){var s=state();return s.pets||[]}
function petName(id){var p=pets().find(function(x){return String(x.backendId||x.id)===String(id)});return p?p.name:'Pet'}
function meds(){return window.GamoraVetMeds12&&window.GamoraVetMeds12.getRemoteMedications?window.GamoraVetMeds12.getRemoteMedications():[]}
function medName(id){var m=meds().find(function(x){return String(x.id)===String(id)});return m?m.name:'Medicamento'}
function statusPt(s){return s==='administered'?'Administrado':s==='snoozed'?'Adiado':s==='skipped'?'Pulado':s==='missed'?'Dose não registrada':s||'Registrado'}
function when(v){if(!v)return'';var d=new Date(v);return isNaN(d.getTime())?String(v):d.toLocaleString('pt-BR')}
function remoteCards(){return remote.map(function(x){return'<div class="card gv-remote-history"><div><b>💊 '+esc(medName(x.medication_id))+'</b><div class="small">🐾 '+esc(petName(x.pet_id))+' • '+esc(when(x.recorded_at))+'</div><div style="margin-top:6px"><span class="badge">'+esc(statusPt(x.status))+'</span> <span style="font-weight:800;color:#087f72">☁ Sincronizado com sua conta</span></div>'+(x.notes?'<div style="margin-top:8px">'+esc(x.notes)+'</div>':'')+'</div></div>'}).join('')}
function render(){var list=document.getElementById('historyList');if(!list)return;list.querySelectorAll('.gv-remote-history').forEach(function(n){n.remove()});if(!remote.length)return;list.insertAdjacentHTML('afterbegin',remoteCards());var r=document.getElementById('rHistory');if(r){var local=(state().history||[]).length;r.textContent=local+remote.length;}}
async function load(){try{var x=await req('listMedicationAdministrations',{});remote=Array.isArray(x)?x:[];render();}catch(e){console.warn('GamoraVet history sync:',e.message)}}
window.GamoraVetHistory12={onNativeResult:function(id,status,body){var p=pending[id];if(!p)return;delete pending[id];if(status>=200&&status<300)p.resolve(parse(body));else p.reject(err(body,status));},refresh:load};
function start(){if(!bridge()){setTimeout(start,200);return}load();document.addEventListener('click',function(e){var h=e.target.closest&&e.target.closest('[data-view="history"],button[onclick*="showView(\'history\')"],button[onclick*="showView(\'reports\')"]');if(h)setTimeout(load,80)},true);document.addEventListener('gamoravet:medication-administration-recorded',function(){setTimeout(load,80)});}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start);else start();
})();