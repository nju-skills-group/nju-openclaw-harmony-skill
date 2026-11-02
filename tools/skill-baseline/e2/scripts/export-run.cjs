// OpenClaw 2026.10.3 SQLite layout; Node 24+ required. Export stays private until reviewed.
const fs=require('node:fs'),path=require('node:path');
const {DatabaseSync}=require('node:sqlite');
const {zstdDecompressSync}=require('node:zlib');
if(!process.argv[2])throw new Error('Usage: node export-run.cjs <private-run-directory>');
const root=path.resolve(process.argv[2]);
const read=p=>JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''));
const run=read(path.join(root,'run.json')),response=read(path.join(root,'response.json'));
const db=new DatabaseSync(path.join(root,'state/agents/main/agent/openclaw-agent.sqlite'),{readOnly:true});
const rows=db.prepare('SELECT seq,event_json,event_zstd FROM transcript_events WHERE session_id=? ORDER BY seq').all(run.sessionId);
const trace=rows.map(r=>({seq:r.seq,event:JSON.parse(r.event_json||zstdDecompressSync(r.event_zstd).toString('utf8'))})).filter(x=>x.event.type==='message').map(({seq,event})=>{
 const m=event.message;return {seq,timestamp:event.timestamp,role:m.role,toolName:m.toolName,toolCallId:m.toolCallId,isError:m.isError,details:m.details,content:Array.isArray(m.content)?m.content.filter(c=>['text','toolCall'].includes(c.type)):m.content};
});db.close();
function scrubString(s){
 for(const [p,label] of [[root,'<RUN_ROOT>'],[process.env.USERPROFILE,'<USER_HOME>']]){
  if(!p)continue;
  for(const n of [1,2,4,8])s=s.split(p.replaceAll('\\','\\'.repeat(n))).join(label);
  s=s.split(p.replaceAll('\\','/')).join(label);
 }
 return s;
}
function scrub(v){if(typeof v==='string')return scrubString(v);if(Array.isArray(v))return v.map(scrub);if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).map(([k,x])=>[k,scrub(x)]));return v;}
const meta=response.meta||response.result?.meta;
if(!meta?.agentMeta?.terminalReceipt)throw new Error('Missing terminal receipt; do not label run verified.');
const files={'trace.json':scrub(trace),'receipt.json':scrub({...run,terminalReceipt:meta.agentMeta.terminalReceipt,toolSummary:meta.toolSummary,agentDurationMs:meta.durationMs}), 'answer.json':scrub({text:meta.finalAssistantVisibleText||response.payloads?.[0]?.text||''})};
for(const value of Object.values(files)){
 const s=JSON.stringify(value);
 for(const [key,secret] of Object.entries(process.env))if(/(?:KEY|TOKEN|SECRET|PASSWORD)/i.test(key)&&secret&&secret.length>8&&s.includes(secret))throw new Error('Credential-like environment value in export; stopped before writing.');
}
const dest=path.join(root,'export');fs.mkdirSync(dest,{recursive:true});
for(const [name,value] of Object.entries(files))fs.writeFileSync(path.join(dest,name),JSON.stringify(value,null,2)+'\n');
console.log('Export candidates saved in private run directory. Review and redact before publishing:',dest);
