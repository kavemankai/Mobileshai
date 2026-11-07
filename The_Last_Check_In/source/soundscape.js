// Original procedural score and foley. One persistent graph, bounded transient voices.
const PREF_KEY='last-check-in-settings-v1';
const preferences={master:.65,music:.3,ambience:.45,effects:.65,muted:false,motion:matchMedia('(prefers-reduced-motion: reduce)').matches,text:1};
try{Object.assign(preferences,JSON.parse(localStorage.getItem(PREF_KEY))||{});}catch(e){}
function savePreferences(){try{localStorage.setItem(PREF_KEY,JSON.stringify(preferences));}catch(e){}}
const sound={ctx:null,enabled:!preferences.muted,buses:{},voices:[],location:'',chapter:-1};
function mix(){if(!sound.ctx)return;const now=sound.ctx.currentTime;for(const name of ['master','music','ambience','effects'])sound.buses[name].gain.setTargetAtTime(name==='master'&&(!sound.enabled||preferences.muted)?0:preferences[name],now,.12);}
function unlockAudio(){
 try{if(!sound.ctx){const C=window.AudioContext||window.webkitAudioContext;if(!C)return;const c=sound.ctx=new C();for(const name of ['master','music','ambience','effects']){sound.buses[name]=c.createGain();sound.buses[name].gain.value=name==='master'&&(!sound.enabled||preferences.muted)?0:preferences[name];}sound.buses.master.connect(c.destination);for(const n of ['music','ambience','effects'])sound.buses[n].connect(sound.buses.master);mix();
 const buffer=c.createBuffer(1,c.sampleRate*3,c.sampleRate),d=buffer.getChannelData(0);let brown=0;for(let i=0;i<d.length;i++){brown=(brown+Math.random()*.04-.02)/1.02;d[i]=brown*2;}
 const noise=c.createBufferSource();noise.buffer=buffer;noise.loop=true;const filter=c.createBiquadFilter();filter.type='lowpass';filter.frequency.value=1300;const g=c.createGain();g.gain.value=.55;noise.connect(filter).connect(g).connect(sound.buses.ambience);noise.start();sound.weather=filter;
 // Beat frequencies and slow modulation supply a seamless evolving suspense bed.
 sound.pads=[];for(let i=0;i<4;i++){const o=c.createOscillator(),v=c.createGain(),lfo=c.createOscillator(),depth=c.createGain();o.type='sine';o.frequency.value=[55,82.41,110.2,164.81][i];v.gain.value=.025;lfo.frequency.value=.045+i*.018;depth.gain.value=.013;lfo.connect(depth).connect(v.gain);o.connect(v).connect(sound.buses.music);o.start();lfo.start();sound.pads.push(o);}
 }if(sound.ctx.state==='suspended'&&!document.hidden)sound.ctx.resume();}catch(e){}
}
function audioScene(loc,ch=0,ending=false){if(!sound.ctx||sound.location===loc&&sound.chapter===ch)return;sound.location=loc;sound.chapter=ch;const c=sound.ctx,now=c.currentTime;sound.weather.frequency.setTargetAtTime(({exterior:2200,yard:1900,room:750,security:450,service:1050,laundry:650,records:300,reception:950})[loc]||650,now,1.5);sound.pads.forEach((o,i)=>o.frequency.setTargetAtTime((ending?[65.41,98,130.81,164.81]:[55,82.41,110.2,146.83])[i]*(ch===3&&!ending?1.05946:1),now,2));}
function sfx(note='tap'){
 unlockAudio();if(!sound.ctx||!sound.enabled||preferences.muted)return;const c=sound.ctx,now=c.currentTime;
 const spec={tap:[310,.07,'sine'],key:[760,.09,'sine'],bad:[95,.24,'sawtooth'],switch:[210,.12,'triangle'],paper:[1100,.07,'triangle'],metal:[1700,.19,'triangle'],phone:[880,.5,'sine'],static:[67,.28,'sawtooth'],power:[120,.48,'triangle'],clue:[523.25,.65,'sine'],success:[523.25,.4,'sine'],door:[62,.35,'triangle']};
 const [f,duration,type]=spec[note]||spec.tap;for(let i=0;i<(note==='clue'||note==='phone'?2:1);i++){const o=c.createOscillator(),g=c.createGain();o.type=type;o.frequency.setValueAtTime(f*(i?1.5:1),now);o.frequency.exponentialRampToValueAtTime(note==='power'?440:Math.max(30,f*.65),now+duration);g.gain.setValueAtTime(.0001,now);g.gain.exponentialRampToValueAtTime(.07,now+.008);g.gain.exponentialRampToValueAtTime(.0001,now+duration);o.connect(g).connect(sound.buses.effects);o.start(now);o.stop(now+duration+.02);o.onended=()=>{o.disconnect();g.disconnect();};}
}
document.addEventListener('visibilitychange',()=>{if(sound.ctx){if(document.hidden)sound.ctx.suspend();else if(sound.enabled)sound.ctx.resume();}});
document.addEventListener('pointerdown',unlockAudio,{once:true});
document.addEventListener('keydown',unlockAudio,{once:true});
