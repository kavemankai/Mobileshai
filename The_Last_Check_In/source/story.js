'use strict';
const CHAPTERS=[
 {name:'THE EMPTY RECEPTION',subtitle:'Someone has vanished, and the night register is lying.'},
 {name:'ROOM SEVENTEEN',subtitle:'A false guest. An older crime. A reason to disappear.'},
 {name:'THE MISSING MINUTES',subtitle:'The evidence survived. So did the person who buried it.'},
 {name:'BEFORE DAWN',subtitle:'Find Nina. Preserve the truth. Get out.'}
];
const L=(ch,title,loc,kind,task,intro,reveal,clueTitle,clueText,extra={})=>({ch,title,loc,kind,task,intro:intro.map(x=>x.split('|')),reveal:reveal.map(x=>x.split('|')),clue:{title:clueTitle,text:clueText},...extra});
const LEVELS=[
L(0,'Restore the Terminal','reception','circuit','Rotate the connectors to carry backup power from the battery to the reception terminal.',[
'NARRATOR|11:43 PM. Rain lashes the windows of the Mariner Motel. Nina’s shift should have ended ten minutes ago.',
'NARRATOR|Her handbag, phone, and car keys are behind the empty reception desk. The office telephone rings.',
'OWEN · PHONE|You’re late. Nina’s gone home. Just lock up the desk.',
'YOU|Her car’s still outside.',
'OWEN · PHONE|She got a lift. I’ll explain tomorrow.',
'NARRATOR|He hangs up. Beneath the keyboard is a folded note: “Room 17 checked out at 11:18. That’s impossible. Check the cameras.”',
'YOU|The terminal’s dead. Maybe the backup panel still works.'
],[
'NARRATOR|Power runs through the circuit. The reception monitor flickers awake.',
'TERMINAL|ROOM 17 — CHECKED OUT 11:18 PM — AUTHORISED: NINA S.',
'YOU|Her own account? Why leave a warning about a checkout she approved?'
],'The impossible checkout','Room 17 was checked out at 11:18 PM using Nina’s account, despite her handwritten warning.',{route:'A',hint:['Every live connector must join the next one. Start at the battery on the left.','Follow the five active tiles: across, up, right, down, and out.']}),
L(0,'The Night Register','reception','sort','Arrange the physical receipts from earliest to latest to reveal the inconsistent entry.',[
'NARRATOR|A yellow alert flashes: REGISTER DOES NOT MATCH PHYSICAL RECEIPTS.',
'YOU|Nina always filed these in order. Someone’s moved them.',
'NARRATOR|Four receipts have been pulled from the register and stuffed beneath the cash drawer.'
],[
'YOU|The checkout receipt has Nina’s login, but no signed departure slip.',
'NARRATOR|A guest knocks on the reception glass. A woman in a raincoat waits under the awning.',
'CLAIRE|Is Nina working? She told me not to leave until she checked something.',
'YOU|What was she checking?',
'CLAIRE|Rooms that were apparently empty... but weren’t.'
],'The unsigned receipt','The 11:18 PM checkout for Room 17 has no guest signature. A guest in Room 12 confirms Nina was investigating false checkouts.',{items:[['a','10:43 PM · Room 04','Guest checked in'],['b','11:02 PM · Room 12','Cash payment processed'],['c','11:18 PM · Room 17','Unsigned checkout'],['d','11:26 PM · Staff office','Maintenance log printed']],hint:['Sort by the time stamped on each receipt.','The first receipt is Room 04 at 10:43 PM.']}),
L(0,'The Security Cabinet','security','slide','Slide the storage trays to open a path to the cabinet key.',[
'NARRATOR|The security office is unlocked. A recorder stands dark behind a glass-fronted cabinet.',
'YOU|The key’s in the sliding tray. Someone’s jammed it shut.',
'NARRATOR|Shift the trays into their numbered positions to free the lower-right compartment.'
],[
'NARRATOR|The cabinet opens. A removable backup drive is still connected.',
'YOU|Someone pulled the primary recorder, but missed this one.',
'NARRATOR|A torn label on the cabinet reads: “Service access logs — keep for audit.”'
],'Forgotten backup','A removable security backup drive survived even though the main recording system was tampered with.',{tileLabels:['KEY','TRAY','LOCK','CAM','HALL','EXIT','DOOR','LOG'],scramble:13,hint:['Tap a tile beside the empty space to slide it.','Put the numbered trays in order from 1 at top-left to 8 at bottom-centre.']}),
L(0,'The Missing Footage','security','sort','Reconstruct the CCTV log in chronological order.',[
'NARRATOR|Four camera segments survived, but their index is scrambled.',
'YOU|The timestamps should tell me what happened first.',
'NARRATOR|The footage starts with Nina entering the security office and ends with a vehicle moving near the rear gate.'
],[
'NARRATOR|The reconstructed footage plays. At 11:18 someone at reception uses Nina’s still-open terminal.',
'YOU|Nina was in here at 11:12. Whoever checked out Room 17 wasn’t her.',
'NARRATOR|The figure at reception wears a maintenance jacket, face obscured by the camera angle.',
'OWEN · PHONE|Have you been in the security office? Don’t touch the recordings. I’m coming down.'
],'A second person at the desk','The CCTV sequence places Nina in security at 11:12, while a maintenance-jacketed person operates her terminal at 11:18.',{items:[['a','11:12 PM · Corridor','Nina enters security office'],['b','11:18 PM · Reception','Unknown figure at the terminal'],['c','11:26 PM · Service','Staff door opens'],['d','11:34 PM · Rear yard','Grey van moves toward gate']],hint:['All four clips have an embedded time.','The correct order is 11:12, 11:18, 11:26, then 11:34.']}),
L(0,'The Tampered Reader','service','screws','Remove the exposed fasteners in order to open the damaged access reader.',[
'NARRATOR|The service door reader hangs crookedly from its housing.',
'YOU|Someone opened this after it was sealed for maintenance.',
'NARRATOR|A series of overlapping retaining plates protects the memory unit.'
],[
'NARRATOR|The casing falls free. Its display retains the last staff credential.',
'READER|11:26 PM — ACCESS GRANTED — NIGHT SHIFT',
'YOU|That’s the credential name on my card. But I arrived at 11:43.',
'NARRATOR|A distant metallic impact echoes from the service wing.'
],'The impossible access','The service corridor was opened at 11:26 PM using a NIGHT SHIFT credential, 17 minutes before the player arrived.',{bolts:5,hint:['Remove the screws on top of the overlapping plates first.','The bright outermost screw can be removed first; work toward the centre.']}),
L(0,'The Backup Recorder','security','circuit','Reconnect the recorder’s damaged power circuit.',[
'NARRATOR|The backup recorder contains one audio track that never reached the main system.',
'YOU|The cable was deliberately cut. I can bypass it with the spare connectors.',
'NARRATOR|The playback lights are dark; the rain suddenly seems very loud.'
],[
'NARRATOR|A woman’s voice crackles through the speaker. It is Nina.',
'NINA · RECORDING|You weren’t supposed to find it.',
'NARRATOR|A man answers, too faintly to identify. Then a heavy thud. Silence.',
'YOU|Nina didn’t go home. I’m calling the police.',
'NARRATOR|Dispatch takes the report, but flooding has blocked the coastal road. Help is on its way.'
],'Nina’s last recording','A backup audio recording captures Nina confronting an unidentified man before a struggle. Police have been notified.',{route:'B',hint:['Connect the battery to the recorder without leaving a gap.','Trace the powered line around the lower-left tiles, then up to the top row.']}),
L(0,'The Last Image','security','slide','Slide the damaged image fragments back into their correct positions.',[
'NARRATOR|One final still from the rear camera is broken into digital blocks.',
'YOU|I need to see who was in that van.',
'NARRATOR|An outline of the vehicle can be made out between scrambled strips.'
],[
'NARRATOR|The restored image shows a grey van at 11:34 PM. There are two silhouettes in the cabin.',
'YOU|One is driving. The other is slumped in the passenger seat.',
'NARRATOR|The van’s registration ends in 61. The south gate camera is conveniently missing.'
],'Two figures in the van','At 11:34 PM, a grey van with registration ending 61 moved toward the rear gate. Two occupants were visible.',{tileLabels:['VAN','CAB','GLASS','RAIN','SIDE','WHEEL','GATE','PLATE'],scramble:19,hint:['Each tap moves an adjacent fragment into the empty space.','Restore fragments 1–8 in reading order.']}),
L(0,'The Contradiction','security','match','Match each recorded event to the evidence that proves it happened.',[
'NARRATOR|The evidence no longer fits Owen’s story. You pin the most important findings beside the security monitor.',
'YOU|The timing matters. There has to be a connection.',
'NARRATOR|Match each event to its supporting record.'
],[
'NARRATOR|The case timeline updates. The NIGHT SHIFT credential used at 11:26 is assigned to you.',
'YOU|But my card is in my pocket...',
'NARRATOR|The security monitor chimes: ACCESS GRANTED — ROOM 17 — 12:09 AM.',
'YOU|Someone just used my card again.',
'NARRATOR|Outside the security office, the corridor light goes out.']
,'A cloned identity','The NIGHT SHIFT credential is assigned to the player, yet it was used before arrival and again while the player remained in the security office.',{pairs:[['11:18 · False checkout','Unsigned Room 17 receipt'],['11:26 · Staff door','NIGHT SHIFT access log'],['11:34 · Rear vehicle','Van footage, plate ending 61']],hint:['An event pairs with the record that directly documents it.','Match 11:26 to the NIGHT SHIFT access log.']}),
// CHAPTER TWO
L(1,'Through the Door','room','keypad','Enter the four-digit room override Nina encoded in her note.',[
'NARRATOR|12:13 AM. The passage to Room 17 is empty. The guest’s keycard slot is sealed.',
'YOU|Nina underlined two parts of her note: “Room 17” and “11:18”.',
'NARRATOR|A pencilled instruction appears on the back: “Room + checkout minutes”.'
],[
'NARRATOR|The lock releases. Room 17 smells of fresh cleaning fluid, but the bathroom is still damp.',
'YOU|Someone cleaned in a hurry.',
'NARRATOR|The motel’s guest welcome card bears the name MARTIN HALE. The bed has not been slept in.'
],'Room 17 was staged','Room 17 was cleaned recently, although its recorded guest never slept there. The guest name is Martin Hale.',{code:'1718',codeClue:'Nina’s note: “Room 17 checked out at 11:18.” On the reverse: “Room + checkout minutes.”',hint:['Combine the room number with the final two digits of checkout time.','Enter 1 7 1 8.']}),
L(1,'The Hidden Vent','room','screws','Open the vent Nina marked without damaging the contents.',[
'NARRATOR|A pale scratch beneath the windowsill forms a tiny arrow pointing to an air vent.',
'YOU|Nina left another mark. She wanted somebody to find this.',
'NARRATOR|The vent cover has overlapping screws and a delicate latch.'
],[
'NARRATOR|Behind the vent is a waterproof sleeve containing a microSD card.',
'NARRATOR|On the sleeve: WARD — 18 OCT 2019.',
'YOU|Why would a seven-year-old incident be hidden in a motel room?',
'NARRATOR|A vehicle engine idles outside. It stops when you look through the curtain.'
],'The WARD memory card','Nina hid a microSD card marked “WARD — 18 OCT 2019” in Room 17’s ventilation duct.',{bolts:6,hint:['Some screws sit behind others. Start with the ones unobstructed.','Follow the visible screw heads from the upper plate inward.']}),
L(1,'The Guest of Record','room','match','Match the names on motel documents with the records that connect them.',[
'NARRATOR|Three names keep appearing on the paperwork: Martin Hale, Daniel Price and Claire Bennett.',
'YOU|I need to know which records belong together.',
'NARRATOR|Receipts, contractor invoices and a booking slip are scattered across the desk.'
],[
'NARRATOR|Martin Hale’s room charge was paid with a card belonging to PRICE SECURITY SERVICES.',
'YOU|Daniel Price. The contractor who fitted the motel’s access readers.',
'NARRATOR|Room 12 was paid in cash by Claire Bennett, who specifically asked about Room 17.'
],'A false guest identity','The Room 17 booking under Martin Hale was paid for by Daniel Price’s security company.',{pairs:[['Martin Hale','Room 17 guest receipt'],['Daniel Price','Price Security Services invoice'],['Claire Bennett','Room 12 cash booking']],hint:['Look for each name printed on its own corresponding paperwork.','Martin Hale matches the Room 17 guest receipt.']}),
L(1,'The Vehicle Trace','yard','parking','Use the yard movement model to clear a route for the grey van.',[
'NARRATOR|The yard camera cannot show the south gate. It can show where all the parked vehicles were.',
'YOU|If I reconstruct the available route, I’ll know whether the van could have left.',
'NARRATOR|On the security map, select a vehicle and use the arrows to slide it within its lane.'
],[
'NARRATOR|With the yard layout reconstructed, the van’s supposed exit route makes no sense.',
'YOU|It could reach the south lane, but the gate was chained. It must have doubled back.',
'NARRATOR|The back of the site contains a loading bay obscured from both main cameras.'
],'The van never left','The grey van likely returned to the motel’s hidden loading bay rather than departing through the chained south gate.',{cars:[{id:'X',x:0,y:2,len:2,dir:'h',target:true},{id:'A',x:2,y:0,len:3,dir:'v'},{id:'B',x:4,y:0,len:3,dir:'v'},{id:'C',x:0,y:0,len:2,dir:'h'},{id:'D',x:2,y:3,len:2,dir:'h'},{id:'F',x:4,y:4,len:2,dir:'h'}],hint:['Move the grey vehicles to create a clear horizontal lane for the gold van.','Clear columns in front of the gold van before sliding it right.']}),
L(1,'The Dashcam Fragment','yard','slide','Restore the obscured still from the van’s own camera.',[
'NARRATOR|A dashcam sync station in the loading bay contains a partial image from 11:36 PM.',
'YOU|The van’s own camera caught the turn.',
'NARRATOR|The corrupted still breaks into fragments whenever it loads.'
],[
'NARRATOR|The repaired frame shows the van turning left behind the laundry block.',
'YOU|They brought somebody back here.',
'NARRATOR|A chained corridor leads from the loading bay to the disused service wing.'
],'The rear-laundry turn','A dashcam fragment places the grey van near the rear laundry entrance at 11:36 PM.',{tileLabels:['TURN','LIGHT','WIPER','WALL','BAY','LANE','VAN','LAUNDRY'],scramble:17,hint:['Use the empty square to shift adjacent pieces.','Move each numbered fragment to its corresponding position.']}),
L(1,'The Ward File','records','sort','Sort the incident documents into the order they were created.',[
'NARRATOR|The microSD card holds scans of a police report, an insurance claim and motel maintenance notes.',
'YOU|They’re all about someone called Mara Ward.',
'NARRATOR|Arrange the documents by date to uncover what was filed—and what was changed.'
],[
'NARRATOR|Mara Ward died following a hit-and-run on the coastal road on 18 October 2019.',
'CLAIRE|Bennett is my married name. I was born Claire Ward. Mara was my sister.',
'YOU|You checked in under another name?',
'CLAIRE|I tried using my own name once. Someone warned me to stop asking questions.',
'NARRATOR|Nina contacted Claire after discovering an old security archive.'
],'Mara Ward’s death','Mara Ward was killed in a 2019 hit-and-run. Claire Bennett is her sister, Claire Ward, investigating the disappearance of evidence.',{items:[['a','18 OCT 2019 · Police','Collision reported'],['b','19 OCT 2019 · Motel','Driveway maintenance request'],['c','21 OCT 2019 · Insurance','Damage claim amended'],['d','02 NOV 2019 · Archive','CCTV archive marked destroyed']],hint:['Compare the dates at the start of each document.','The police report from 18 October comes first.']}),
L(1,'The Sealed Recording','records','keypad','Open the evidence archive using the incident year.',[
'NARRATOR|The card includes a locked audio archive marked WARD / INCIDENT YEAR.',
'CLAIRE|Nina said she had proof the motel knew what happened.',
'YOU|The code prompt says four-digit incident year.'
],[
'OWEN · RECORDING|I changed the insurance paperwork, Daniel. You told me nobody was hurt.',
'DANIEL · RECORDING|Keep the camera logs where they are, Owen. Nobody needs to see the road.',
'NARRATOR|Owen helped conceal the old collision. But the recording doesn’t prove who was driving.',
'NARRATOR|A crackle comes through the building intercom. A faint female voice says, “...laundry... please...”',
'YOU|Nina’s alive. Somewhere behind the service wing.'
],'The cover-up recording','A 2019 recording implicates Owen Mercer and Daniel Price in suppressing evidence of Mara Ward’s death. A weak intercom call suggests Nina is alive.',{code:'2019',codeClue:'Evidence archive: WARD / 18 OCT 2019. Access code: INCIDENT YEAR (four digits).',hint:['The lock uses the year of Mara Ward’s fatal collision.','Enter 2 0 1 9.']}),
// CHAPTER THREE
L(2,'The Spare Credential','security','match','Connect the access events to the staff and maintenance credentials.',[
'NARRATOR|Daniel Price installed the motel’s new electronic readers last month.',
'YOU|He could have made a second card with the same identifier.',
'NARRATOR|The contractor audit lists three cards and their associated authorisations.'
],[
'NARRATOR|The NIGHT SHIFT identifier was duplicated by a contractor tool at 10:57 PM.',
'YOU|That explains why it registered before I arrived.',
'NARRATOR|The duplication token was issued to PRICE SECURITY SERVICES.'
],'Who copied the card','A contractor tool assigned to Daniel Price’s company duplicated the NIGHT SHIFT credential at 10:57 PM.',{pairs:[['NIGHT SHIFT','Player’s assigned credential'],['CONTRACTOR 02','Price Security Services'],['OWNER MASTER','Owen Mercer']],hint:['Match the credential labels to the assignment ledger.','CONTRACTOR 02 belongs to Price Security Services.']}),
L(2,'The Flooded Corridor','service','circuit','Restore the drainage controls to reach the service wing.',[
'NARRATOR|The storm has flooded the corridor beyond the loading bay.',
'YOU|The drainage controls are here, but the power routing is broken.',
'NARRATOR|A faded diagram shows the battery line feeding the pump controller.'
],[
'NARRATOR|The emergency pump starts. Water drains from the service passage.',
'NARRATOR|Scuff marks run along the floor toward a locked laundry corridor.',
'YOU|Someone dragged a heavy load through here recently.'
],'A trail to the laundry','The service corridor shows fresh drag marks leading towards the disused laundry rooms.',{route:'B',hint:['Start at the battery and follow the indicated live path.','The route turns down through the lower tiles before returning to the output.']}),
L(2,'The Archived Film','records','sort','Put the four surviving 2019 camera records in chronological order.',[
'NARRATOR|A second copy of the 2019 footage survived on the old service archive.',
'YOU|Four timestamps. They cover the minutes around Mara’s death.',
'NARRATOR|Rebuild the sequence before opening the images.'
],[
'NARRATOR|The sequence shows Daniel Price driving the motel company car. Mara walks along the shoulder.',
'NARRATOR|The car strikes her. Daniel gets out, calls Owen, then moves the vehicle.',
'YOU|Daniel was the driver.',
'NARRATOR|The original video is still damaged, but its sequence is clear.'
],'The driver in 2019','Recovered records identify Daniel Price as the driver involved in Mara Ward’s fatal collision. Owen subsequently helped conceal it.',{items:[['a','12:36 AM · Approach','Company car turns onto coastal road'],['b','12:41 AM · Collision','Car strikes pedestrian'],['c','12:42 AM · Driver','Daniel exits the driver’s seat'],['d','12:45 AM · Office','Owen arrives and inspects damage']],hint:['The footage runs from approach to collision to aftermath.','Order by time: 12:36, 12:41, 12:42, 12:45.']}),
L(2,'The Owner’s Ledger','records','sort','Reorder payments to expose the recurring transfer pattern.',[
'NARRATOR|Owen’s office contains a ledger marked SECURITY RETAINER.',
'CLAIRE|Nina said the payments always happened after the yearly insurance review.',
'YOU|Someone’s mixed the entries. I’ll put the dates back in order.'
],[
'NARRATOR|Every October, Owen paid Daniel an unusually large “maintenance” fee.',
'YOU|He was paying to keep Daniel quiet.',
'CLAIRE|Then Owen has been afraid of him for years.',
'NARRATOR|A message arrives from Owen: “I’m at the front. Please, let me explain.”'
],'Years of payments','The motel’s ledger records repeated large October payments from Owen Mercer to Daniel Price’s business after the 2019 crash.',{items:[['a','OCT 2020','Retainer: $8,000'],['b','OCT 2021','Retainer: $8,000'],['c','OCT 2023','Retainer: $12,000'],['d','OCT 2025','Retainer: $12,000']],hint:['Sort the ledger entries from oldest to newest year.','Start with October 2020 and end with October 2025.']}),
L(2,'The Emergency Intercom','service','circuit','Reroute power to the emergency intercom outside the laundry.',[
'NARRATOR|Nina’s faint message came over the obsolete laundry intercom.',
'YOU|If I can make it transmit both ways, she might hear me.',
'NARRATOR|The electrical switchboard still has an emergency supply.'
],[
'YOU · INTERCOM|Nina? If you can hear me, knock twice.',
'NARRATOR|Two knocks carry through the wall.',
'NINA · INTERCOM|Behind the laundry door... Daniel has the key... he’s coming back.',
'NARRATOR|The line goes dead. Footsteps sound in the hall.'
],'Nina is in the laundry','Nina confirms she is locked behind the disused laundry door and names Daniel as her captor.',{route:'A',hint:['There is one unbroken line across the panel.','Turn from the battery upward, then across the upper tiles and down.']}),
L(2,'The Contractor’s Case','service','screws','Remove the case’s security plates to inspect the contents.',[
'NARRATOR|A contractor’s tool case is tucked behind the service switchboard.',
'YOU|Price Security Services. He left this where nobody would look.',
'NARRATOR|The metal cover is secured with overlapping anti-tamper plates.'
],[
'NARRATOR|Inside are a programmable keycard writer, a second NIGHT SHIFT card and an empty evidence sleeve.',
'YOU|He used my cloned credential. And he’s still searching for Nina’s memory card.',
'NARRATOR|The tool case also contains a laundry door override tag.'
],'Daniel’s cloning equipment','Daniel Price’s case contains a card encoder and a duplicate NIGHT SHIFT credential, directly linking him to the forged access events.',{bolts:6,hint:['The screw heads on top of each plate become accessible first.','Start with the outer plate fasteners and work inward.']}),
L(2,'The Only Explanation','security','match','Connect the three decisive pieces of evidence to the responsible person or act.',[
'NARRATOR|Owen arrives, pale and dripping rainwater. Claire keeps her distance.',
'OWEN|I hid what happened in 2019. That was my doing. But I didn’t take Nina.',
'YOU|Then tell me who did.',
'OWEN|Daniel. Nina found the old recording. He knew she’d shown Claire.',
'NARRATOR|Before trusting him, assemble the physical evidence.'
],[
'NARRATOR|The records independently place Daniel behind the false booking, duplicate credential and abduction.',
'OWEN|He thinks she has the only original footage. He locked her away until she tells him where it is.',
'YOU|We have the copy. But we still need Nina.',
'NARRATOR|From the service hall comes a sharp metallic bang. The laundry lights go out.'
],'Daniel identified','The booking, duplicate credential and Nina’s testimony independently identify Daniel Price as the person who abducted her.',{pairs:[['Room 17 alias','Price Security payment card'],['Cloned NIGHT SHIFT','Daniel’s card encoder'],['Laundry kidnapping','Nina’s intercom testimony']],hint:['Pair each suspicious event with direct corroborating evidence.','The cloned NIGHT SHIFT card matches Daniel’s encoder.']}),
// CHAPTER FOUR
L(3,'The Laundry Override','laundry','keypad','Use the maintenance override printed on the contractor tag.',[
'NARRATOR|12:54 AM. You and Claire reach the disused laundry entrance.',
'CLAIRE|The door’s electrified. I can hear someone inside.',
'YOU|Daniel’s tool case has an override tag. L-6421.',
'NARRATOR|The keypad accepts the four digits after the L.'
],[
'NARRATOR|The outer door unlocks. A burst of hot air rolls through the opening.',
'NINA · DISTANT|I’m here! Please hurry!',
'YOU|We’re coming. Keep talking to us.'
],'Laundry entrance unlocked','The maintenance override opened the outer laundry door. Nina is still alive beyond the boiler room.',{code:'6421',codeClue:'Contractor maintenance tag: LAUNDRY ACCESS · L-6421. Enter the four numerals after L.',hint:['Read the four digits following “L-” on the contractor tag.','Enter 6 4 2 1.']}),
L(3,'The Boiler Bypass','laundry','circuit','Reconnect the isolation control so the pressure door can be opened safely.',[
'NARRATOR|A steaming boiler blocks the inner corridor. The safety interlock has been bypassed.',
'YOU|The pressure door will stay sealed until the isolation valve gets power.',
'CLAIRE|The diagram is still intact on the panel.'
],[
'NARRATOR|The isolation valve engages. Steam clears from the passage.',
'NINA · DISTANT|He told me he’d destroy everything if the police arrived.',
'YOU|We already backed up the card. Just stay away from the door.'
],'Safe access to the inner corridor','The boiler was isolated, allowing access to the inner laundry corridor without opening a pressurised door.',{route:'B',hint:['The battery must reach the valve control through the live connectors.','Follow the lower route back towards the upper-right output.']}),
L(3,'The Last Barrier','laundry','slide','Rearrange the jammed lock segments to release the inner safety gate.',[
'NARRATOR|The final gate is blocked by a damaged mechanical interlock.',
'YOU|These segments are out of position. The gate won’t release.',
'NINA · DISTANT|I can hear you. Daniel took my phone. Please don’t leave.'
],[
'NARRATOR|The gate slides free. Nina stumbles out, shaken but able to walk.',
'NINA|He wanted the card. I told him it was gone.',
'NARRATOR|A door slams at the far end of the passage.',
'DANIEL · DISTANT|You’ve made a terrible mistake.'
],'Nina rescued','Nina has been freed from the laundry. Daniel Price is still on the property and knows the evidence was recovered.',{tileLabels:['GATE','BOLT','SPRING','GUIDE','LOCK','PLATE','RAIL','RELEASE'],scramble:22,hint:['Use the empty square to move lock segments one at a time.','Restore all eight segments in numerical sequence.']}),
L(3,'The Original Frame','records','slide','Rebuild the final undamaged video frame from the 2019 recording.',[
'NARRATOR|Nina shows you a hidden duplicate of the last surviving camera frame.',
'NINA|I made another backup. Daniel was looking for the wrong card.',
'YOU|The one we found proves the timeline. This one can prove who was behind the wheel.'
],[
'NARRATOR|The repaired frame clearly shows Daniel Price behind the steering wheel of the company car.',
'CLAIRE|That’s the first image of him they’ve ever let me see.',
'NINA|Send it to the police before he reaches the switchboard.'
],'The original frame','The restored original video frame clearly identifies Daniel Price driving the car involved in Mara Ward’s fatal collision.',{tileLabels:['ROAD','FACE','WHEEL','CAR','TIME','GLASS','DRIVER','PLATE'],scramble:25,hint:['Only slide tiles into the empty cell.','Place fragments 1 through 8 in their correct reading order.']}),
L(3,'The Emergency Uplink','security','match','Match the physical evidence feeds to the three emergency upload channels.',[
'NARRATOR|The police dispatcher is still connected on an emergency data link.',
'YOU|The upload board needs each file routed to the right channel.',
'DANIEL · DISTANT|I can shut this whole system down!',
'NARRATOR|Match each evidence source to its secure destination.'
],[
'DISPATCH|Evidence received and time-stamped. Officers are entering the service road.',
'NINA|He can’t erase it now.',
'NARRATOR|Footsteps race towards the switchboard. The backup screen remains green.',
'YOU|We’re staying here. The police are almost through the gate.'
],'Evidence preserved off-site','The CCTV, duplicate-card audit and original 2019 frame have been transferred to the police evidence server.',{pairs:[['2019 video','Digital evidence channel'],['Card-access audit','Security log channel'],['Nina’s recording','Witness audio channel']],hint:['The destinations name the type of evidence they accept.','Nina’s recording belongs in the witness audio channel.']}),
L(3,'The Final Account','security','sort','Put the decisive six events into chronological order to complete the case statement.',[
'NARRATOR|The dispatcher requests a final sequence of events while officers approach.',
'DISPATCH|Confirm the chronology: the original death, the cover-up, and tonight’s abduction.',
'YOU|We have everything. The order will show how it all connects.',
'NARRATOR|Reconstruct the six key events, from earliest to latest.'
],[
'NARRATOR|The statement is transmitted. Officers enter the laundry corridor and confront Daniel.',
'DISPATCH|Suspect detained. We have Nina and two witnesses safe.',
'CLAIRE|Mara spent seven years without anyone hearing the truth.',
'NINA|Someone finally listened.',
'NARRATOR|As morning breaks over the flooded coastline, investigators take Owen in for questioning about the cover-up.',
'NARRATOR|The records are preserved. The investigation can now proceed without the motel controlling the story.'
],'Case closed','Nina was rescued; Daniel was detained; the recovered evidence exposed the 2019 collision, Owen’s cover-up, and the events at the motel.',{items:[['a','18 OCT 2019','Daniel’s car strikes Mara Ward'],['b','LATE 2019','Owen and Daniel conceal the footage'],['c','2020–2025','Owen makes recurring payments'],['d','EARLIER TONIGHT','Nina locates the old evidence'],['e','11:26 PM TONIGHT','Daniel uses the cloned credential'],['f','BEFORE DAWN','Nina rescued and evidence transmitted']],hint:['First order events by year, then the events of tonight.','The 2019 collision comes first; the evidence upload comes last.']})
];
