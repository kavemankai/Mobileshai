// The case. Full spoilers. {name} is replaced with the player's name.
// Story rules: grounded, no supernatural twist. Nina is the guide through what she left behind.
// Portrait moods: 'NINA~frightened|line'. Valid moods are the PORTRAITS keys in assets/manifest.ts.
// Suspects in order of suspicion: Owen (ch1-2), Claire (ch2), Daniel (arrives end of ch2, exposed in ch3).

import type { Chapter, Level, Line, PuzzleDef, SceneKey } from '../core/types';

export const CHAPTERS: Chapter[] = [
  { name: 'The Empty Reception', subtitle: 'Nina asked you to come in early. You were late.' },
  { name: 'Room Seventeen', subtitle: 'A false guest, a searched room, and a name from seven years ago.' },
  { name: 'The Missing Minutes', subtitle: 'The man fixing the locks is the one who broke them.' },
  { name: 'Before Dawn', subtitle: 'Find Nina. Keep the evidence. Get out.' },
];

const lines = (xs: string[]): Line[] => xs.map((x) => {
  const i = x.indexOf('|');
  return [x.slice(0, i), x.slice(i + 1)];
});

function L(ch: number, title: string, scene: SceneKey, task: string, intro: string[], reveal: string[], clue: [string, string], hints: [string, string], puzzle: PuzzleDef): Level {
  return { ch, title, scene, task, intro: lines(intro), reveal: lines(reveal), clue: { title: clue[0], text: clue[1] }, hints, puzzle };
}

const RECEPTION_CLUTTER = ['☕', '📎', '🖊️', '📚', '🛎️', '🗝️', '🧴', '📦', '🪴', '🗞️', '💡', '📞', '🧷', '✂️', '📒', '🗂️', '🕯️', '🧻', '📄', '💳'];
const RECORDS_CLUTTER = ['📁', '📂', '🗂️', '📦', '📚', '📄', '📎', '🖇️', '🗃️', '💾', '📠', '☕', '🗒️', '📰', '✏️', '🔩', '📌', '🕰️', '🗄️'];

export const LEVELS: Level[] = [
  // ───────────────────────── CHAPTER ONE · THE EMPTY RECEPTION ─────────────────────────
  L(0, 'Restore the Terminal', 'reception', 'Draw one line from the battery through every junction in order to the terminal. Fill every square.', [
    'NARRATOR|11:43 PM. Rain hammers the Mariner Motel. You were meant to be here at half past.',
    'NARRATOR|Nina asked you to come in early. “I need to show you something before Owen gets in tomorrow.” She didn’t say what.',
    'NARRATOR|The reception desk is empty. Her handbag is under it. Her keys. Her phone, face down, still charging.',
    'NARRATOR|The office phone rings.',
    'OWEN · PHONE|You’re late. Nina’s gone home. Lock the desk and do the night audit.',
    'YOU|Her car’s still out front.',
    'OWEN · PHONE|She got a lift. Don’t make this complicated.',
    'NARRATOR|He hangs up. The terminal is dead, and so are the lights behind the desk. Someone has pulled the main fuse.',
    'YOU|The backup battery panel. Nina showed me on Monday.',
  ], [
    'NARRATOR|The terminal hums awake. One line is still on screen.',
    'TERMINAL|ROOM 17 · CHECKED OUT 11:18 PM · AUTHORISED: NINA S.',
    'NARRATOR|Under the keyboard, a folded note in Nina’s handwriting.',
    'NINA · NOTE|{name}, Room 17 just checked out on my login. I watched it happen on the security monitor. It wasn’t me. Check the backup. N.',
    'YOU|She saw it happen. Then she came back here and wrote this. So where did she go?',
  ], ['The impossible checkout', 'Room 17 was checked out at 11:18 PM on Nina’s login. Nina’s note says she watched it on the security monitor and it wasn’t her.'],
  ['The line has to pass the numbers in order: 1, then 2, then 3. It can’t cross itself.', 'Snake along the rows: right along the top, back along the second row, and so on.'],
  { kind: 'zip', rows: 4, cols: 4, start: [0, 0], moves: 'RRRDLLLDRRRDLLL', marks: [0, 4, 9, 15], markLabels: ['BATTERY', 'RELAY', 'FUSE', 'TERMINAL'] }),

  L(0, 'The Night Register', 'reception', 'Search the reception desk. Find the four missing receipts, Nina’s spare key and the yellow sticky note.', [
    'NARRATOR|A warning flashes on the terminal: REGISTER DOES NOT MATCH PHYSICAL RECEIPTS.',
    'YOU|Nina filed every receipt the minute it printed. She was obsessive about it.',
    'NARRATOR|The desk looks like someone went through it fast and tried to make it look normal.',
  ], [
    'YOU|Room 17’s checkout receipt has Nina’s login on it, but no guest signature. Every other one is signed.',
    'NARRATOR|The sticky note is a list in Nina’s writing: “04 ✓  12 ✓  17 ✗ — who paid for this?”',
    'NARRATOR|A knock on the glass. A woman in a wet raincoat, hood up.',
    'CLAIRE|Is Nina here? She told me to wait in my room. That was an hour ago.',
    'YOU|Which room?',
    'CLAIRE~guarded|Twelve. Bennett. Is she here or not?',
    'NARRATOR|She doesn’t wait for an answer. She goes back out into the rain and doesn’t look at Room 17 as she passes it. Pointedly doesn’t.',
  ], ['The unsigned receipt', 'Room 17’s 11:18 PM checkout has no guest signature. Nina had flagged Room 17 as wrong. A guest in Room 12, “Bennett”, says Nina told her to wait.'],
  ['Receipts are small, curled and pale. There are four of them in different corners.', 'Check under the edges of things: one receipt is near the bottom left, one near the top right.'],
  { kind: 'hidden', scene: 'reception', clutter: 55, clutterGlyphs: RECEPTION_CLUTTER, targets: [
    { id: 'receipt', label: 'Receipts', glyph: '🧾', x: 14, y: 84 },
    { id: 'key', label: 'Nina’s spare key', glyph: '🔑', x: 62, y: 33 },
    { id: 'note', label: 'Yellow sticky note', glyph: '📝', x: 40, y: 58 },
  ], extra: { receipt: [[85, 12], [47, 26], [76, 71]] } }),

  L(0, 'The Security Cabinet', 'security', 'Open the jammed cabinet in stages. Each stage leaves you something you need for the next.', [
    'NARRATOR|The security office is unlocked. The main recorder has been pulled out of the rack. Cables hang loose.',
    'YOU|“Check the backup.” There’s a cabinet under the desk.',
    'NARRATOR|Someone has jammed its trays. They didn’t bother to hide the scratches.',
  ], [
    'NARRATOR|Under the false bottom, a removable drive with a green light still blinking.',
    'YOU|Whoever took the recorder missed this.',
    'NARRATOR|A label on the drive in Nina’s writing: “BACKUP. DON’T TELL O.”',
    'YOU|O. Owen.',
  ], ['Forgotten backup', 'A backup drive survived in the security cabinet. Nina labelled it “Don’t tell O.”'],
  ['The plate comes off first. Whatever is written behind it is for the next stage.', 'Set the sliders to 3, 1 and 4. Then press the one clean panel.'],
  { kind: 'box', name: 'Security cabinet', stages: [
    { type: 'screws', count: 4, plate: 'TRAY STOP PLATE', note: 'Scratched into the metal behind the plate: 3 · 1 · 4' },
    { type: 'sliders', targets: [3, 1, 4], clue: 'Three jammed tray stops, each with notches 0 to 4.', note: 'The trays slide free. The bottom drawer is shallower than the others.' },
    { type: 'press', count: 6, target: 4, clue: 'The shallow drawer is lined with dusty panels. One is clean, as if someone keeps lifting it.', note: 'A false bottom lifts out.' },
  ] }),

  L(0, 'The Missing Footage', 'security', 'Arrange the four camera feeds and switch each between wide and close until the path runs through all of them, in time order.', [
    'NARRATOR|The drive holds four camera clips with the timestamps stripped out.',
    'YOU|If I line the feeds up, I can follow whoever moved through them.',
  ], [
    'NARRATOR|11:12. Nina walks into this office. 11:18. On the reception feed, someone in a maintenance jacket leans over Nina’s terminal. Face turned away.',
    'NARRATOR|11:26. The staff door opens. 11:34. A grey van rolls toward the rear gate.',
    'YOU|She was in here, watching, while someone checked out Room 17 in her name.',
    'OWEN · PHONE|Are you in the security office? Don’t touch the recordings. I mean it. I’m coming in.',
    'YOU|How does he know where I am?',
  ], ['A second person at the desk', 'CCTV: Nina entered security at 11:12. At 11:18 a person in a maintenance jacket used her terminal. The staff door opened at 11:26; a grey van moved at 11:34. Owen ordered you not to touch the recordings.'],
  ['The path enters at the gold marker on the left of the top-left frame. Each frame needs the right zoom to bend the line where you need it.', 'Order: 11:12 top left (wide), 11:18 top right (close), 11:26 bottom right (wide), 11:34 bottom left (close).'],
  { kind: 'panels', rows: 2, cols: 2, start: { slot: 0, edge: 'W' }, end: { slot: 2, edge: 'S' }, order: ['a', 'b', 'c', 'd'], panels: [
    { id: 'a', label: '11:12 CORRIDOR', views: [{ name: 'wide', exits: ['W', 'E'], caption: 'Nina, walking fast' }, { name: 'close', exits: ['N', 'S'], caption: 'Her ID badge' }] },
    { id: 'b', label: '11:18 RECEPTION', views: [{ name: 'wide', exits: ['W', 'E'], caption: 'Empty desk' }, { name: 'close', exits: ['W', 'S'], caption: 'A jacket at the terminal' }] },
    { id: 'c', label: '11:26 STAFF DOOR', views: [{ name: 'wide', exits: ['N', 'W'], caption: 'Door swinging shut' }, { name: 'close', exits: ['E', 'S'], caption: 'Reader light: green' }] },
    { id: 'd', label: '11:34 REAR YARD', views: [{ name: 'wide', exits: ['N', 'S'], caption: 'Rain on the lens' }, { name: 'close', exits: ['E', 'S'], caption: 'Grey van, lights off' }] },
  ] }),

  L(0, 'The Tampered Reader', 'service', 'Search the service corridor and get the staff-door reader open.', [
    'NARRATOR|The service corridor smells of bleach and wet concrete. The staff-door reader hangs off the wall by one screw.',
    'YOU|Someone forced this. Recently.',
  ], [
    'NARRATOR|The reader’s little screen still holds its last entry.',
    'READER|11:26 PM · ACCESS GRANTED · NIGHT SHIFT',
    'YOU|NIGHT SHIFT. That’s my card. I didn’t get here until 11:43.',
    'NARRATOR|You pat your pocket. Your card is right there.',
  ], ['The impossible access', 'The staff door opened at 11:26 PM on the NIGHT SHIFT credential. That is your card, and you arrived at 11:43. Your card never left your pocket.'],
  ['Tap things to search them. Some things need something from your pockets first.', 'Torch from the fuse cupboard, use it on the dark alcove, then use the screwdriver on the reader.'],
  { kind: 'room', scene: 'service', goal: 'readerOpen', items: { torch: { label: 'Torch', icon: '🔦' }, screwdriver: { label: 'Screwdriver', icon: '🪛' } }, hotspots: [
    { id: 'fuse', label: 'Fuse cupboard', icon: '🗄️', x: 4, y: 6, w: 30, h: 18, text: 'The door sticks, then gives. A torch is clipped inside.', doneText: 'Fuses. One empty slot where the reception fuse should be.', gives: 'torch' },
    { id: 'alcove', label: 'Dark alcove', icon: '🌑', x: 62, y: 8, w: 32, h: 20, needs: 'torch', needsText: 'Too dark to see what’s back there.', text: 'The torch finds a toolbox shoved under the pipes. Inside: a flat screwdriver.', doneText: 'An empty toolbox.', gives: 'screwdriver' },
    { id: 'door', label: 'Staff door', icon: '🚪', x: 36, y: 30, w: 26, h: 22, text: 'Locked from this side. Fresh scuffs at the bottom, like something heavy was dragged through.' },
    { id: 'bucket', label: 'Mop bucket', icon: '🪣', x: 6, y: 58, w: 28, h: 16, text: 'Grey water. Someone mopped this floor tonight. Nobody mops the service corridor.' },
    { id: 'reader', label: 'Access reader', icon: '📟', x: 60, y: 56, w: 32, h: 20, needs: 'screwdriver', needsText: 'The casing is hanging off one screw. You need something to undo it.', text: 'Two turns and the casing swings open. The memory unit is intact.', sets: 'readerOpen' },
  ] }),

  L(0, 'The Backup Recorder', 'security', 'Rewire the backup recorder: one line through every numbered contact in order, filling the board.', [
    'NARRATOR|There’s a second file on Nina’s drive, audio only. The playback unit’s power line has been cut.',
    'YOU|Cut, not broken. Somebody didn’t want this heard.',
  ], [
    'NARRATOR|Static, then Nina’s voice, very close to the microphone.',
    'NINA · RECORDING~frightened|I’ve made copies. If anything happens to me, people will see what you did.',
    'NARRATOR|A man answers. The words are lost under the rain on the roof. Then a thud, and a long silence.',
    'YOU|She didn’t go home.',
    'NARRATOR|You call the police. The dispatcher is calm and slow.',
    'DISPATCH|The coast road’s flooded at the bridge. We’ll get a car to you as soon as it’s passable. Stay inside and keep this line open.',
  ], ['Nina’s last recording', 'A recording captures Nina telling a man she has made copies of something, then a struggle. Police are notified; the flooded bridge is holding them back.'],
  ['Start at 1 and keep the numbers in order. The line has to fill every square.', 'The board spirals: around the outside first, then inward to finish in the middle.'],
  { kind: 'zip', rows: 5, cols: 5, start: [0, 0], moves: 'RRRRDDDDLLLLUUURRRDDLLUR', marks: [0, 6, 13, 19, 24], markLabels: ['POWER', 'FUSE', 'AMP', 'HEAD', 'PLAY'] }),

  L(0, 'The Last Image', 'security', 'Make matches over the static to clear it. Uncover the whole frame.', [
    'NARRATOR|One frame from the rear camera survived, buried in digital noise.',
    'YOU|The van. I need to see who was in it.',
  ], [
    'NARRATOR|The frame clears. 11:34 PM. A grey van, two shapes in the cab. One is driving. The other is slumped against the window.',
    'NARRATOR|The plate is half in shadow. It ends in 61.',
    'YOU|The south gate camera would have caught it leaving. That camera’s “out of order”. Of course it is.',
  ], ['Two figures in the van', 'At 11:34 PM a grey van, plate ending 61, moved toward the rear gate. Two people in the cab; one not moving.'],
  ['Matches only clear the static under the tiles that match. Work the edges too.', 'Four in a row makes a line clearer. Line up a match with a line clearer to wipe a whole row or column.'],
  { kind: 'match3', size: 7, colors: 5, mask: ['.......', '.#####.', '.#####.', '.#####.', '.#####.', '.#####.', '.......'], reveal: { title: 'REAR CAM · 11:34 PM', lines: ['Grey van, lights off', 'Two in the cab', 'Plate: ••• •61'] } }),

  L(0, 'The Contradiction', 'security', 'Put tonight’s events in order. No times on the cards: use what you know.', [
    'NARRATOR|You pin everything you have to the corkboard beside the monitors.',
    'YOU|Owen says she went home. Nothing here says that. Let me lay it out properly.',
  ], [
    'NARRATOR|Laid out in order, there’s no room for Owen’s version. Nina was taken before you arrived. On your card.',
    'NARRATOR|Then the monitor chimes.',
    'SECURITY|ACCESS GRANTED · ROOM 17 · 12:09 AM · NIGHT SHIFT',
    'YOU|That’s my card. Again. I’m sitting right here.',
    'NARRATOR|Out in the corridor, the lights go off one by one.',
  ], ['A cloned identity', 'Your NIGHT SHIFT credential was used at 11:26 PM before you arrived, and again at 12:09 AM to enter Room 17 while you were in the security office. Someone has a copy of your card.'],
  ['Nina saw the checkout before she wrote the note. She was taken through the staff door.', 'Order: Nina enters security, the checkout, the note, the staff door, the van, you arrive.'],
  { kind: 'timeline', prompt: 'Tonight, earliest at the top.', order: ['a', 'b', 'c', 'd', 'e', 'f'], cards: [
    { id: 'a', title: 'Nina walks into the security office', detail: 'Corridor camera. She is carrying a folder and checking her watch.' },
    { id: 'b', title: 'A maintenance jacket checks out Room 17', detail: 'Reception camera. The terminal is still logged in as Nina.' },
    { id: 'c', title: 'Nina writes you a note', detail: '“I watched it happen on the security monitor.”' },
    { id: 'd', title: 'The staff door opens on your card', detail: 'The reader log. Nina’s recording ends around now.' },
    { id: 'e', title: 'The grey van rolls toward the gate', detail: 'Two people in the cab. One isn’t moving.' },
    { id: 'f', title: 'You walk in, late', detail: 'Rain, an empty desk, a handbag under it.' },
  ] }),

  // ───────────────────────── CHAPTER TWO · ROOM SEVENTEEN ─────────────────────────
  L(1, 'Through the Door', 'corridor17', 'Find the staff override code for Room 17 somewhere in this corridor.', [
    'NARRATOR|12:13 AM. The corridor outside Room 17 is dark apart from the ice machine’s glow.',
    'NARRATOR|The door is shut. Whoever used your card at 12:09 is either inside or long gone.',
    'YOU|There’s a staff keypad. Nina would know the code. Nina’s not here.',
  ], [
    'NARRATOR|The lock clicks. Room 17 has been torn apart. Drawers pulled out and dumped, mattress shoved off the base.',
    'NARRATOR|The bathroom is still wet. Cleaning fluid hangs in the air.',
    'YOU|Someone searched this room at 12:09. Looking for something they didn’t find, or they wouldn’t have made this much mess.',
    'NARRATOR|On the desk, the guest welcome card: MARTIN HALE. The bed hasn’t been slept in.',
  ], ['Room 17 was searched', 'Room 17 was torn apart at 12:09 AM by whoever has your cloned card. The registered guest, Martin Hale, never slept there.'],
  ['Nina’s note on the back says how the override is built. Look for the room number, then the time the checkout lied.', 'Move the cart, read the board, check under the mat. Room 17, checkout 11:18: 1718.'],
  { kind: 'room', scene: 'corridor17', goal: 'doorOpen', items: {}, keypad: { code: '1718', sets: 'doorOpen', label: 'ROOM 17 · STAFF OVERRIDE' }, hotspots: [
    { id: 'note', label: 'Back of Nina’s note', icon: '📝', x: 4, y: 6, w: 30, h: 16, text: 'In pencil on the back: “Staff override = the room, then the minute it lied.”' },
    { id: 'door', label: 'Room door', icon: '🚪', x: 38, y: 10, w: 26, h: 26, text: 'The brass number plate has been unscrewed. Two empty holes where it was.' },
    { id: 'mat', label: 'Door mat', icon: '🟫', x: 38, y: 40, w: 26, h: 12, text: 'Under the mat: the brass plate from the door. 1 7.' },
    { id: 'cart', label: 'Housekeeping cart', icon: '🧺', x: 66, y: 6, w: 30, h: 18, text: 'You roll the cart aside. Behind it, the housekeeping board.', doneText: 'Towels, soap, a clipboard with nothing on it.', sets: 'cartMoved' },
    { id: 'board', label: 'Housekeeping board', icon: '📋', x: 66, y: 28, w: 30, h: 18, visibleIf: 'cartMoved', text: 'Chalk, smudged: “R17 · OUT 11:18 · N.S.” Nina’s initials. Except Nina didn’t do it.' },
    { id: 'ice', label: 'Ice machine', icon: '🧊', x: 4, y: 58, w: 30, h: 16, text: 'It rattles. A puddle under it, and wet footprints leading to 17 and back.' },
    { id: 'keypad', label: 'Door keypad', icon: '🔢', x: 62, y: 58, w: 32, h: 16, text: '', keypad: true },
  ] }),

  L(1, 'The Hidden Vent', 'room17', 'Search Room 17 for whatever the intruder was looking for.', [
    'YOU|If Nina hid something in here, the person with my card didn’t find it. They’d have stopped tearing the place up.',
    'NARRATOR|Nina knew this motel better than anyone. She’d have left a mark only staff would notice.',
  ], [
    'NARRATOR|Taped inside the duct, a waterproof sleeve. In it, a microSD card.',
    'NARRATOR|On the sleeve, in marker: WARD · 18 OCT 2019.',
    'YOU|Seven years ago. What does a seven-year-old date have to do with tonight?',
    'NARRATOR|Outside, an engine idles in the car park. When you look through the curtain, it cuts out.',
  ], ['The WARD memory card', 'Nina hid a microSD card marked “WARD · 18 OCT 2019” in Room 17’s air vent. Whoever searched the room missed it.'],
  ['Nina leaves marks. Look at the window.', 'The windowsill scratch shows you the vent. The drawer has a coin; use the coin on the vent screws.'],
  { kind: 'room', scene: 'room17', goal: 'ventOpen', items: { coin: { label: '50c coin', icon: '🪙' } }, hotspots: [
    { id: 'drawer', label: 'Bedside drawer', icon: '🗄️', x: 4, y: 6, w: 28, h: 16, text: 'Pulled out and dumped on the carpet. In the mess, a fifty-cent coin.', doneText: 'Hotel notepad, a pen, a Bible with the bookmark ripped out.', gives: 'coin' },
    { id: 'sill', label: 'Windowsill', icon: '🪟', x: 36, y: 6, w: 28, h: 16, text: 'A pale scratch in the paint. Fresh. A tiny arrow pointing down and to the right.', sets: 'arrow' },
    { id: 'bed', label: 'Bed', icon: '🛏️', x: 66, y: 6, w: 30, h: 18, text: 'Mattress half off. They checked under it, inside the pillowcases, under the base.' },
    { id: 'bin', label: 'Bin', icon: '🗑️', x: 4, y: 56, w: 26, h: 16, text: 'Empty, fresh liner. Someone cleaned this room before someone else wrecked it.' },
    { id: 'bath', label: 'Bathroom', icon: '🚿', x: 34, y: 56, w: 26, h: 16, text: 'Shower still dripping. Bleach smell. The cabinet hangs open, empty.' },
    { id: 'vent', label: 'Air vent', icon: '🌀', x: 64, y: 56, w: 30, h: 16, visibleIf: 'arrow', needs: 'coin', needsText: 'The vent screws are slotted, painted over. A coin would turn them.', text: 'The screws give. Behind the grille, taped to the duct wall, a waterproof sleeve.', sets: 'ventOpen' },
  ] }),

  L(1, 'The Guest of Record', 'room17', 'Work out who stayed where and how they paid. Then you’ll know who paid for Room 17.', [
    'NARRATOR|In the desk drawer, carbon copies of tonight’s bookings. Three guests. The names and payments have been torn apart and mixed.',
    'YOU|Martin Hale booked 17 and never slept in it. Somebody paid for that room.',
  ], [
    'NARRATOR|Martin Hale paid with a prepaid card. The card’s top-up slip is stapled behind it: MARINER MOTEL · MAINTENANCE ACCOUNT.',
    'YOU|The motel paid for the fake guest. Only one person signs off on that account.',
    'NARRATOR|The door swings open. Owen Mercer, soaked, out of breath.',
    'OWEN|What are you doing in here? I told you to leave it.',
    'YOU|Your maintenance account paid for Room 17.',
    'OWEN|Contractors use that account. Half the trades on this coast use it. That proves nothing.',
    'NARRATOR|He looks at the torn-up room for a long moment and doesn’t ask what happened to it.',
  ], ['A false guest identity', 'The Room 17 booking under “Martin Hale” was paid with a prepaid card topped up from the motel’s maintenance account. Owen controls it, though he says contractors use it too.'],
  ['Okafor’s company paid for his room. Hale never touched cash.', 'Okafor: Room 04, company account. Hale: Room 17, prepaid card. Bennett: Room 12, cash.'],
  { kind: 'logic',
    categories: [{ name: 'Guest', items: ['Martin Hale', 'Claire Bennett', 'R. Okafor'] }, { name: 'Room', items: ['17', '12', '04'] }, { name: 'Payment', items: ['Prepaid', 'Cash', 'Company'] }],
    clues: [
      { text: 'R. Okafor’s stay was billed to his employer.', rule: { t: 'same', a: [0, 2], b: [2, 2] } },
      { text: 'Martin Hale never handled cash.', rule: { t: 'diff', a: [0, 0], b: [2, 1] } },
      { text: 'Whoever paid by prepaid card had the room Nina flagged.', rule: { t: 'same', a: [2, 0], b: [1, 0] } },
      { text: 'The guest in Room 04 didn’t pay in cash.', rule: { t: 'diff', a: [1, 2], b: [2, 1] } },
      { text: 'Claire Bennett asked for the room next to 17.' },
    ],
    solution: [[0, 0], [1, 1], [2, 2]] }),

  L(1, 'The Vehicle Trace', 'yard', 'Trace the van through the yard cameras, in order, filling every square. Where does it end?', [
    'NARRATOR|Owen follows you to the security office, dripping, saying nothing.',
    'YOU|The van went toward the rear gate at 11:34. The gate camera’s dead. But the yard cameras each caught a sliver.',
    'OWEN|You’re wasting your time. The van left. Everyone leaves.',
  ], [
    'NARRATOR|The route only works one way. The van never reached the gate. It looped back to the loading bay.',
    'YOU|The gate’s chained. It couldn’t have left. It’s still here.',
    'OWEN|Ask her what she was doing out there.',
    'NARRATOR|He points at the yard feed. At 11:30, a woman in a raincoat crosses the yard toward the loading bay. Claire.',
    'DISPATCH · PHONE|Checking in. Water’s still over the bridge. Are you safe where you are?',
    'YOU|I don’t know any more.',
  ], ['The van never left', 'The van’s route only fits one way: it looped back to the hidden loading bay. The rear gate was chained. Claire was on camera crossing the yard at 11:30.'],
  ['The gate cells are chained. The route has to end on the last number.', 'From the rear lot go up the left side, then weave right; finish along the bottom row at the loading bay.'],
  { kind: 'zip', rows: 5, cols: 6, start: [4, 0], moves: 'UUUURDDDRUUURRDLDRRDDLULDLL', marks: [0, 8, 14, 20, 27], markLabels: ['REAR LOT', 'CAM A', 'CAM B', 'CAM C', 'LOADING BAY'], wallLabels: { '0,5': 'GATE', '1,5': 'CHAIN' } }),

  L(1, 'The Dashcam Fragment', 'yard', 'Line up the dashcam frames with the yard map until the van’s route joins up, in order.', [
    'NARRATOR|In the loading bay, a dashcam sync box blinks on the wall. The van parked close enough to upload.',
    'NARRATOR|Claire is there, standing in the dark, as if she’s been waiting for you.',
    'CLAIRE|Nina texted me at 11:25. “Loading bay. Now.” By the time I got here, nobody was here.',
    'YOU|You were on camera at 11:30. Why didn’t you tell anyone?',
    'CLAIRE~angry|Tell who? The owner? Look at him.',
  ], [
    'NARRATOR|11:36. The van turns hard left behind the old laundry block and stops by a chained service door.',
    'YOU|They brought her back. She’s somewhere in this building.',
    'CLAIRE|The laundry’s been shut for years.',
    'YOU|How do you know that?',
    'CLAIRE|Because I’ve been coming here for years.',
  ], ['The rear-laundry turn', 'The dashcam puts the van behind the disused laundry block at 11:36 PM. Claire says Nina texted her at 11:25 to meet at the loading bay.'],
  ['The path enters the top-left frame from the left and leaves the top-right frame from the top.', 'Dashcam top left (wide), yard map bottom left (wide), laundry wall bottom right (wide), the turn top right (wide).'],
  { kind: 'panels', rows: 2, cols: 2, start: { slot: 0, edge: 'W' }, end: { slot: 1, edge: 'N' }, order: ['p', 'q', 'r', 't'], panels: [
    { id: 'p', label: 'DASHCAM 11:35', views: [{ name: 'wide', exits: ['W', 'S'], caption: 'Wipers, rear lot' }, { name: 'close', exits: ['W', 'E'], caption: 'Rain on glass' }] },
    { id: 'q', label: 'YARD MAP', views: [{ name: 'wide', exits: ['N', 'E'], caption: 'Lane past the bins' }, { name: 'close', exits: ['N', 'S'], caption: 'Bay markings' }] },
    { id: 'r', label: 'LAUNDRY WALL', views: [{ name: 'wide', exits: ['W', 'N'], caption: 'Brick, a chained door' }, { name: 'close', exits: ['E', 'S'], caption: 'Fresh tyre marks' }] },
    { id: 't', label: 'DASHCAM 11:36', views: [{ name: 'wide', exits: ['N', 'S'], caption: 'Hard left turn' }, { name: 'close', exits: ['W', 'S'], caption: 'Brake lights' }] },
  ] }),

  L(1, 'The Ward File', 'records', 'Search the records office for the five documents on Nina’s memory card list.', [
    'NARRATOR|The memory card holds a single text file. A list in Nina’s words: “Records office. Police report, insurance claim, maintenance request, archive log, the photo.”',
    'NARRATOR|The records office is a cupboard of boxes nobody has opened in years. Nearly nobody.',
  ], [
    'NARRATOR|Laid out together, the documents tell one story. 18 October 2019: Mara Ward, 31, killed by a hit-and-run at Kestrel Bend on the coast road below the motel.',
    'NARRATOR|The next day, the motel logged “driveway damage”. Three days later, an insurance claim for a company car was amended. Two weeks later, the road camera archive was marked destroyed.',
    'NARRATOR|The photo is of a woman laughing on a beach. On the back: “Mara, summer.”',
    'CLAIRE~grieving|Bennett is my married name. I was born Claire Ward. Mara was my sister.',
    'YOU|You booked in under your married name so they wouldn’t know you.',
    'CLAIRE~grieving|I used my own name once, two years ago. The next morning there was a note under my car wiper telling me to stop asking. Nina found the archive in March. She called me.',
  ], ['Mara Ward’s death', 'Mara Ward was killed by a hit-and-run at Kestrel Bend on 18 October 2019. The motel logged damage, amended an insurance claim and destroyed the road camera archive. Claire Bennett is Mara’s sister, born Claire Ward.'],
  ['The documents are scattered through the whole room, including the edges.', 'The archive log is a tape near the top left. The photo is low on the right.'],
  { kind: 'hidden', scene: 'records', clutter: 60, clutterGlyphs: RECORDS_CLUTTER, targets: [
    { id: 'police', label: 'Police report', glyph: '📋', x: 72, y: 22 },
    { id: 'insurance', label: 'Insurance claim', glyph: '📑', x: 27, y: 47 },
    { id: 'maint', label: 'Maintenance request', glyph: '🔧', x: 55, y: 64 },
    { id: 'archive', label: 'Archive log', glyph: '📼', x: 12, y: 15 },
    { id: 'photo', label: 'Photo of Mara', glyph: '🖼️', x: 86, y: 82 },
  ] }),

  L(1, 'The Sealed Recording', 'records', 'Open the cryptex Nina built for the audio file. The password is the place it happened.', [
    'NARRATOR|One more file on the card, locked behind a password prompt shaped like a cryptex. Seven letter rings.',
    'NINA · NOTE|For Claire. It’s where she fell.',
    'CLAIRE~grieving|She never let me listen to it. She said I should hear it with the police.',
  ], [
    'NARRATOR|October 2019. Two men on the line. One is unmistakably Owen.',
    'OWEN · RECORDING|I changed the insurance paperwork. You told me nobody was hurt.',
    'NARRATOR|The second voice is warped by water damage on the original tape.',
    'VOICE · RECORDING|Keep the road camera logs where they are, Owen. Nobody needs to see that road.',
    'NARRATOR|Owen is in the doorway. He has heard all of it.',
    'OWEN|I didn’t drive. I swear to God, I didn’t drive that car.',
    'NARRATOR|Headlights sweep the window. Boots on the wet steps, and a man in a Price Security jacket shakes off the rain.',
    'DANIEL|Owen called me about the dodgy door readers. Sounds like you’ve all had a night of it.',
    'NARRATOR|The intercom on the wall crackles. A woman’s voice, very faint. “...laundry... please...”',
    'YOU|That’s Nina. She’s alive.',
    'DANIEL|The laundry wing’s on the old generator. The readers back there will be dead too. I’ll go and get it running.',
    'NARRATOR|He goes, alone, into the service wing. Owen watches him leave and says nothing at all.',
  ], ['The cover-up recording', 'A 2019 recording has Owen admitting he changed insurance paperwork after being told “nobody was hurt”. The second man is unidentifiable. Nina is alive somewhere in the laundry. Daniel Price of Price Security has arrived.'],
  ['The police report names the exact spot. Open the case file below the cryptex.', 'Kestrel Bend. Spell KESTREL.'],
  { kind: 'cryptex', word: 'KESTREL', clue: 'Nina’s note: “It’s where she fell.” Seven letters.', rings: ['AKMRTB', 'OEINUS', 'TRSLPC', 'HTSNOB', 'ARTEKI', 'NEOAVR', 'SDLMYO'] }),

  // ───────────────────────── CHAPTER THREE · THE MISSING MINUTES ─────────────────────────
  L(2, 'The Spare Credential', 'security', 'Sort the keycards onto the racks. Three of a kind lock away. One card won’t have a home.', [
    'NARRATOR|The card rack in the security office is a jumble. Every key card the motel has ever issued, dumped back in any slot.',
    'YOU|Somebody has a copy of my card. If I sort these, the extra one should show itself.',
  ], [
    'NARRATOR|One NIGHT SHIFT card left over. Yours is in your pocket. This one is a clone, still warm from the encoder.',
    'NARRATOR|The reader audit on the terminal explains it. NIGHT SHIFT duplicated at 22:57, by an encoder registered to PRICE SECURITY SERVICES.',
    'YOU|Daniel. And he’s just walked into the service wing on his own.',
    'OWEN|I didn’t know he’d gone this far. I swear I didn’t.',
    'YOU|You knew something.',
    'NARRATOR|Owen doesn’t answer.',
  ], ['Who copied the card', 'A spare NIGHT SHIFT card was in the rack. The audit shows it was cloned at 10:57 PM by an encoder registered to Price Security Services: Daniel Price.'],
  ['Free up a whole rack early. Empty racks are what make the sort possible.', 'Clear the colours with no NIGHT SHIFT cards mixed in first, then gather the NIGHT SHIFT cards.'],
  { kind: 'goods', capacity: 3, leftover: 'N',
    types: { N: { label: 'NIGHT', color: '#e8b877' }, O: { label: 'OWNER', color: '#c8665a' }, H: { label: 'HOUSE', color: '#7fb7ad' }, C: { label: 'CONTR.', color: '#9a8fc9' }, G: { label: 'GUEST', color: '#d9d2c2' } },
    racks: [['N', 'O', 'H'], ['C', 'G', 'N'], ['O', 'C', 'H'], ['G', 'N', 'C'], ['H', 'G', 'O'], ['N', '', ''], ['', '', '']] }),

  L(2, 'The Flooded Corridor', 'service', 'Separate the floodwater, oil, sludge and rust into their own tanks so the pump will start.', [
    'NARRATOR|The corridor to the service wing is under ankle-deep water. The sump pump’s filter tanks are clogged with everything the storm brought in.',
    'YOU|Daniel went this way. He didn’t come back.',
  ], [
    'NARRATOR|The pump coughs and starts. Water drains away from the passage.',
    'NARRATOR|On the concrete, two long scuff marks run toward the laundry corridor. Like heels dragged.',
    'YOU|This is how they brought her in.',
    'NARRATOR|Wet boot prints on top of the scuff marks, fresher. Heading the same way.',
  ], ['A trail to the laundry', 'The drained corridor shows drag marks toward the laundry, with fresh boot prints over them.'],
  ['You can only pour onto the same liquid or into an empty tank. Use the empty tanks as holding space.', 'Undo is free. Fill one tank with one liquid at a time, starting with whatever is on top most often.'],
  { kind: 'water', capacity: 4,
    colors: { W: { label: 'Water', color: '#4f86a8' }, O: { label: 'Oil', color: '#2b2b2b' }, S: { label: 'Sludge', color: '#7a6a4a' }, R: { label: 'Rust', color: '#b0563a' } },
    tubes: ['WOSR', 'RSWO', 'OWRS', 'SROW', '', ''] }),

  L(2, 'The Archived Film', 'records', 'Order the surviving frames from the 2019 road camera.', [
    'NARRATOR|Back in the records office, a second copy of the destroyed archive. Owen kept it. Of course he did.',
    'OWEN|It’s in the bottom box. I couldn’t throw it away.',
    'NARRATOR|Six frames, no timestamps.',
  ], [
    'NARRATOR|In order, the frames show a motel company car taking Kestrel Bend too fast. The impact. The driver getting out and making a call.',
    'NARRATOR|The camera glare whites out the driver’s face in every frame.',
    'NARRATOR|Then a second vehicle. Owen’s ute. He walks to the car, not to Mara.',
    'YOU|You were there.',
    'OWEN|He rang me. I came. I didn’t drive that car.',
    'YOU|Then who did?',
    'OWEN|Not yet. Find Nina first. Please.',
  ], ['The 2019 sequence', 'The 2019 frames show a motel company car hitting Mara Ward, the driver calling someone, and Owen arriving afterwards. The driver’s face is hidden by glare.'],
  ['Think about what has to happen before what. The second vehicle arrives after the phone call.', 'Empty road, the car, impact, the driver gets out, Owen arrives, the car backs away.'],
  { kind: 'timeline', prompt: '18 October 2019, earliest at the top.', order: ['a', 'b', 'c', 'd', 'e', 'f'], cards: [
    { id: 'a', title: 'Headlights on a wet road', detail: 'Nothing in frame but a woman walking on the shoulder.' },
    { id: 'b', title: 'A car takes Kestrel Bend', detail: 'Motel livery on the door. Too fast for the wet.' },
    { id: 'c', title: 'Impact', detail: 'The windscreen whites out in the glare.' },
    { id: 'd', title: 'The driver gets out', detail: 'Kneels on the road, then stands and makes a phone call.' },
    { id: 'e', title: 'A second vehicle arrives', detail: 'Owen’s ute. He walks to the car, not to her.' },
    { id: 'f', title: 'The company car backs out of frame', detail: 'One headlight broken. Owen stays behind with a torch.' },
  ] }),

  L(2, 'The Owner’s Ledger', 'records', 'Fit the shredded ledger strips back into the page.', [
    'NARRATOR|Owen’s desk drawer holds a shredded page from a ledger marked SECURITY RETAINER. He didn’t shred it well.',
    'DISPATCH · PHONE|Water’s dropping at the bridge. Maybe forty minutes. Can you hold on?',
    'YOU|We’ll hold on.',
  ], [
    'NARRATOR|The page goes back together. Every October since 2020, a payment to Price Security Services. $8,000. Then $12,000.',
    'YOU|You’ve been paying him for seven years.',
    'OWEN|He said the original footage was still out there. That if it ever came out, I’d go down for the cover-up and he’d say I was driving.',
    'CLAIRE~angry|So you paid. And my sister stayed a hit-and-run.',
  ], ['Years of payments', 'The ledger shows Owen paying Price Security Services every October since 2020, $8,000 rising to $12,000. Owen says Daniel threatened to name him as the driver.'],
  ['The gold square on each strip is the corner you tap to place. Rotate before placing.', 'The square block goes top-middle-right. The long three-square strip runs down the left edge.'],
  { kind: 'blockfit', caption: 'SECURITY RETAINER · page 3', solution: ['AAABBC', 'DAEBBC', 'DEEECC', 'DFFGGH', 'FFGGHH'] }),

  L(2, 'The Emergency Intercom', 'service', 'Bring the old switchboard back to life and open the laundry intercom channel.', [
    'NARRATOR|Nina’s voice came through the obsolete laundry intercom. The switchboard for it is in the service wing, half dead.',
    'YOU|If I can make it work both ways, she can tell us where she is.',
  ], [
    'YOU · INTERCOM|Nina? It’s {name}. If you can hear me, knock twice.',
    'NARRATOR|Two knocks through the wall. Then her voice, hoarse.',
    'NINA · INTERCOM~frightened|{name}? You came. Behind the laundry, past the boiler. Daniel has the key.',
    'NINA · INTERCOM~frightened|He thinks you have my card. He’s coming back for you.',
    'NARRATOR|The line dies. Somewhere in the wing, a door closes softly.',
  ], ['Nina is in the laundry', 'Nina, over the intercom: she is locked behind the laundry past the boiler. Daniel has the key and thinks you have her memory card.'],
  ['Every lever flips its neighbours too. Then follow the patch chart exactly.', 'Patch speaker to line 3, mic to line 1, relay to emergency. Dial 4 7.'],
  { kind: 'box', name: 'Laundry switchboard', stages: [
    { type: 'levers', start: [1, 0, 0, 0, 1, 1, 0, 1, 0], clue: 'Emergency breakers. All nine have to be up. Each lever flips its neighbours too.', note: 'The board hums. A patch chart is taped inside the door.' },
    { type: 'patch', left: ['SPEAKER', 'MIC', 'RELAY'], right: ['LINE 1', 'LINE 3', 'EMERGENCY'], pairs: [1, 0, 2], clue: 'Chart: “Laundry intercom. Speaker on line 3, mic on line 1, relay to emergency.”', note: 'A channel readout flickers: LAUNDRY · CH 4-7.' },
    { type: 'dials', code: '47', clue: 'Tune the channel dial.', note: 'The line opens.' },
  ] }),

  L(2, 'The Contractor’s Case', 'service', 'Get into Daniel’s tool case.', [
    'NARRATOR|Behind the switchboard, a hard case with a Price Security sticker. Left where only a contractor would look.',
    'YOU|He was here. Whatever he’s carrying around tonight, the rest of it is in this.',
  ], [
    'NARRATOR|Inside: a card encoder, a blank card, an empty evidence sleeve the same size as Nina’s.',
    'NARRATOR|And a laundry override tag, warped by the heat from the boiler pipe it was stuffed behind.',
    'YOU|He cloned my card with this. Checked out 17 in Nina’s name. Searched 17 with my card. Every bit of it, him.',
  ], ['Daniel’s cloning equipment', 'Daniel’s case holds the encoder calibrated at 22:57, an empty evidence sleeve, and a heat-damaged laundry override tag.'],
  ['The bearing only stops at walls. The note from the maze is the combination.', 'Unscrew all five. Roll the bearing right, down, right, down. Then dial 2 2 5 7.'],
  { kind: 'box', name: 'Price Security tool case', stages: [
    { type: 'screws', count: 5, plate: 'ANTI-TAMPER PLATE', note: 'Under the plate, a ball-bearing maze. The lid release is in the far corner.' },
    { type: 'tilt', rows: ['######', '#S.#O#', '#....#', '#....#', '#.#.G#', '######'], clue: 'Roll the bearing into the release.', note: 'Click. Engraved under the inner lid: “Encoder calibrated 22:57.”' },
    { type: 'dials', code: '2257', clue: 'Four-digit wheel on the inner lid.', note: 'The case opens.' },
  ] }),

  L(2, 'The Only Explanation', 'security', 'Work out where everyone was at 11:26 and what they had. Then say who took Nina.', [
    'NARRATOR|Back in the security office. Owen in one corner, Claire in the other, the laundry intercom silent.',
    'CLAIRE~angry|He’s been paying a man to keep quiet about my sister. Why should we believe anything he says?',
    'OWEN|Because I’m the one who called Daniel tonight. I didn’t know what he’d do.',
    'YOU|Nobody says a name until I’ve checked it.',
  ], [
    'NARRATOR|Owen was on the phone to you. Claire was in Room 12. Daniel was in the service corridor with the encoder’s card.',
    'YOU|Daniel took her.',
    'OWEN|Daniel was driving in 2019. He rang me from the road. I came, I saw her, and I helped him hide it. I’ve hated myself every day since.',
    'OWEN|Nina found the archive. He thinks she has the only original. He locked her up until she tells him where it is.',
    'CLAIRE|And when she tells him?',
    'NARRATOR|Nobody answers. From the service wing, a heavy metallic bang. The laundry lights on the monitor go out.',
  ], ['Daniel identified', 'At 11:26, Owen was on the phone, Claire was in Room 12, and Daniel was in the service corridor with the cloned card. Owen confesses Daniel was the 2019 driver and that he helped cover it up.'],
  ['Owen’s phone call and Claire’s door log fix two people. The third is whoever is left.', 'Owen: office phone, master key. Claire: Room 12, rental keys. Daniel: service corridor, encoder. Accuse Daniel.'],
  { kind: 'logic',
    categories: [{ name: 'Suspect', items: ['Owen', 'Claire', 'Daniel'] }, { name: 'At 11:26', items: ['Phone', 'Room 12', 'Corridor'] }, { name: 'Carrying', items: ['Master key', 'Rental keys', 'Encoder'] }],
    clues: [
      { text: 'Phone records put Owen on the office line at 11:26.', rule: { t: 'same', a: [0, 0], b: [1, 0] } },
      { text: 'Claire’s door log shows her inside Room 12 until 11:40.', rule: { t: 'same', a: [0, 1], b: [1, 1] } },
      { text: 'Whoever was in the service corridor used the encoder’s card.', rule: { t: 'same', a: [1, 2], b: [2, 2] } },
      { text: 'The rental car keys never left Claire’s coat.', rule: { t: 'same', a: [0, 1], b: [2, 1] } },
    ],
    solution: [[0, 0], [1, 1], [2, 2]],
    accuse: { prompt: 'Who took Nina?', answer: 2, wrong: { 0: 'Owen was on the phone to you at 11:26. He lied about a lot, but not that.', 1: 'Claire’s door log has her in Room 12 the whole time.' } } }),

  // ───────────────────────── CHAPTER FOUR · BEFORE DAWN ─────────────────────────
  L(3, 'The Laundry Override', 'laundry', 'Find the missing digits of the override code and open the laundry door.', [
    'NARRATOR|12:54 AM. You and Claire reach the laundry entrance. Owen stays at the switchboard to keep the intercom alive.',
    'CLAIRE|Someone’s breathing in there. I can hear it.',
    'NARRATOR|Daniel’s override tag is heat-warped. The last two digits have melted away.',
  ], [
    'NARRATOR|The door opens on a wall of heat. Somewhere past the machines, the boiler roars.',
    'NINA · DISTANT~frightened|{name}? I’m here! Past the boiler!',
    'YOU|We’re coming. Keep talking.',
  ], ['Laundry entrance unlocked', 'The override code 6421 opened the outer laundry door. Nina is alive, past the boiler.'],
  ['The tag gives you the first two digits. The scorched log has the rest.', 'Gloves from the basket let you pick up the clipboard. The code is 6421.'],
  { kind: 'room', scene: 'laundry', goal: 'doorOpen', items: { gloves: { label: 'Work gloves', icon: '🧤' } }, keypad: { code: '6421', sets: 'doorOpen', label: 'LAUNDRY · MAINTENANCE OVERRIDE' }, hotspots: [
    { id: 'tag', label: 'Override tag', icon: '🏷️', x: 4, y: 6, w: 30, h: 16, text: 'From Daniel’s case. “LAUNDRY ACCESS · L-64”. The last two digits have melted.' },
    { id: 'basket', label: 'Laundry basket', icon: '🧺', x: 36, y: 6, w: 28, h: 16, text: 'Under a heap of mouldy towels: heavy work gloves.', doneText: 'Towels. Nothing else.', gives: 'gloves' },
    { id: 'clip', label: 'Clipboard on the steam pipe', icon: '📋', x: 66, y: 6, w: 30, h: 18, needs: 'gloves', needsText: 'It’s hanging on a steam pipe. Far too hot to touch bare-handed.', text: 'A scorched maintenance log. The last line: “Override reset, code ends …21.”' },
    { id: 'ext', label: 'Fire extinguisher', icon: '🧯', x: 4, y: 56, w: 28, h: 16, text: 'Last inspected 2019. Nobody has looked after this wing since.' },
    { id: 'door', label: 'Laundry door', icon: '🚪', x: 34, y: 34, w: 28, h: 20, text: 'Steel, warm to the touch. You can hear someone breathing on the other side.' },
    { id: 'keypad', label: 'Door keypad', icon: '🔢', x: 64, y: 56, w: 30, h: 16, text: '', keypad: true },
  ] }),

  L(3, 'The Boiler Bypass', 'laundry', 'Steer the pressure ball through the valve maze. It only stops at walls and has to stop on the gold valve.', [
    'NARRATOR|The boiler blocks the inner corridor. Its safety interlock has been bypassed, and the pressure door beyond it is sealed.',
    'CLAIRE|There’s a diagram on the panel. It’s a maze of valves.',
    'YOU|Open the wrong one and it vents steam into the corridor. Into her.',
  ], [
    'NARRATOR|The isolation valve thunks shut. The roar drops to a hiss, and the steam clears from the passage.',
    'NINA · DISTANT~frightened|He said he’d burn everything if the police came.',
    'YOU|The card’s safe. We copied it. Just stay back from the gate.',
  ], ['Safe access to the inner corridor', 'The boiler was isolated, so the inner corridor can be reached without venting steam.'],
  ['Holes send the ball back to the start. Count where each tilt would leave it before you move.', 'Right, down, left, down, right, down, right.'],
  { kind: 'tilt', caption: 'BOILER ISOLATION · valve diagram', rows: ['########', '#S.....#', '#..O#..#', '###....#', '#.....##', '#.###..#', '#.#.O.G#', '########'] }),

  L(3, 'The Last Barrier', 'laundry', 'Open the inner gate’s interlock, stage by stage. Nina can see more of it than you can.', [
    'NARRATOR|A steel safety gate across the last bay. Behind it, sitting on the floor with her back to a dryer, Nina.',
    'NINA~relieved|You came.',
    'YOU|I was late.',
    'NINA|You came. The interlock’s on your side. I’ve been staring at it for two hours. I’ll talk you through it.',
  ], [
    'NARRATOR|The gate grinds open. Nina gets up, unsteady, and holds onto your arm harder than she means to.',
    'NINA~frightened|He wanted the card. I told him I’d thrown it in the sea.',
    'CLAIRE~grieving|Nina. I’m so sorry.',
    'NINA|Don’t be. You’re about to see him get what he’s owed.',
    'NARRATOR|At the far end of the passage, a door slams.',
    'DANIEL · DISTANT|You’ve made a very stupid mistake, all of you.',
  ], ['Nina rescued', 'Nina is free. Daniel is still in the building and knows the evidence has been found.'],
  ['Levers flip their neighbours. Nina’s knocks are the slider positions.', 'Sliders 2, 4, 0, 3. The release lever is the scraped one.'],
  { kind: 'box', name: 'Inner gate interlock', stages: [
    { type: 'levers', start: [0, 1, 1, 0, 1, 1, 1, 0, 1], clue: 'Interlock breakers. All nine up to cut the magnetic lock.', note: 'The magnet lets go. Four bolts still hold the gate.' },
    { type: 'sliders', targets: [2, 4, 0, 3], clue: 'Nina knocks through the grate: two... four... none... three.', note: 'The bolts slide back. One release lever left.' },
    { type: 'press', count: 9, target: 2, clue: 'Nina: “The release is the one with the red paint scraped off.”', note: 'The gate grinds open.' },
  ] }),

  L(3, 'The Original Frame', 'records', 'Clear the corruption off Nina’s original copy of the 2019 frame.', [
    'NARRATOR|Nina pulls at the seam of her lanyard. A second microSD card drops into her palm.',
    'NINA|He took my phone. He didn’t think to take this. This is the original, before the archive was “destroyed”.',
    'CLAIRE|Will it show his face?',
    'NINA|One frame does. If we can clean it.',
  ], [
    'NARRATOR|The frame clears. Kestrel Bend, 12:41 AM, 18 October 2019. No glare on this copy.',
    'NARRATOR|Behind the wheel of the company car, staring straight ahead: Daniel Price.',
    'CLAIRE~grieving|Seven years. That’s the first time anyone’s let me see his face.',
    'NINA|Then let’s make sure everyone sees it. Security office. Now, before he gets to the switchboard.',
  ], ['The original frame', 'Nina’s original copy of the 2019 frame clearly shows Daniel Price driving the car that killed Mara Ward.'],
  ['Clear the edges early. The middle tends to clear itself with cascades.', 'Build line clearers with four in a row, then match them to wipe whole rows.'],
  { kind: 'match3', size: 7, colors: 5, mask: ['.#####.', '#######', '#######', '#######', '#######', '#######', '.#####.'], reveal: { title: 'KESTREL BEND · 12:41 AM', lines: ['18 OCT 2019 · original', 'Company car, no glare', 'Driver: DANIEL PRICE'] } }),

  L(3, 'The Emergency Uplink', 'security', 'Route the upload through every relay in order before Daniel cuts the power. Fill every square.', [
    'NARRATOR|Back in the security office. The dispatcher is still on the line, and there’s an emergency data link to the police server.',
    'DISPATCH|Send whatever you have. If it’s on our server, nobody can wipe it.',
    'NARRATOR|The lights flicker. Down the hall, the switchboard bangs. Daniel is cutting power one breaker at a time.',
    'NARRATOR|Then footsteps, and he is at the security office door. Nina and Claire throw their weight against it.',
    'DANIEL|Open the door. Let’s talk about this like adults.',
    'OWEN · DISTANT|Daniel! It’s done. Leave them alone.',
    'NARRATOR|Owen is in the corridor between Daniel and the door. For the first time in seven years, he doesn’t move.',
  ], [
    'DISPATCH|Received and time-stamped. Officers are over the bridge. Two minutes.',
    'NINA~relieved|He can’t take it back now.',
    'NARRATOR|In the corridor, Daniel stops pushing. Blue lights fill the rain-streaked window.',
  ], ['Evidence preserved off-site', 'Nina’s recording, the card audit and the original 2019 frame reached the police server. Officers are on site.'],
  ['The numbered relays have to be passed in order and the line must fill the board.', 'Along the top, back along row two, along row three, then down and weave through the bottom left, finishing up the left side.'],
  { kind: 'zip', rows: 6, cols: 6, start: [0, 0], moves: 'RRRRRDLLLLDRRRRDDDLUULDDLUULDDLUUUU', marks: [0, 7, 15, 22, 28, 35], markLabels: ['UPLINK', 'RELAY 1', 'RELAY 2', 'RELAY 3', 'RELAY 4', 'POLICE'] }),

  L(3, 'The Final Account', 'security', 'Give the dispatcher the whole chronology, earliest first.', [
    'NARRATOR|Officers fill the corridor. Daniel is face down on the wet carpet, cuffed, not saying anything at all.',
    'DISPATCH|For the statement: walk me through it in order. The crash, the cover-up, tonight.',
    'YOU|All of it. In order.',
  ], [
    'NARRATOR|The statement goes through. An officer reads it back to you, and it sounds like something that happened to someone else.',
    'NARRATOR|Owen sits in the back of a patrol car with the door open, hands in his lap. He nods to Claire. She doesn’t nod back. It’s not hers to give yet.',
    'CLAIRE~grieving|Mara went seven years without anyone hearing her.',
    'NINA~relieved|They’ll hear her now.',
    'NARRATOR|Dawn comes up grey over the flooded coast road. You and Nina stand at the reception desk. Her handbag is still under it.',
    'NINA~relieved|Come in early tomorrow. I’ll show you how the register actually works.',
    'YOU|Half past eleven?',
    'NINA~relieved|Half past eleven. Don’t be late.',
  ], ['Case closed', 'Nina is safe. Daniel Price is in custody for the abduction and the 2019 death of Mara Ward. Owen Mercer is being questioned over the cover-up. The evidence is safe off-site.'],
  ['The evidence board has every time you need. Seven years ago comes first, tonight comes last.', 'Crash, insurance change, first payment, card cloned, checkout, Nina taken, Room 17 searched, upload.'],
  { kind: 'timeline', prompt: 'The whole case, earliest at the top.', order: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'], cards: [
    { id: 'a', title: 'Mara Ward dies at Kestrel Bend', detail: 'The road camera was still working that night.' },
    { id: 'b', title: 'Owen changes the insurance paperwork', detail: '“You told me nobody was hurt.”' },
    { id: 'c', title: 'The first retainer payment', detail: 'The first October after the crash.' },
    { id: 'd', title: 'Daniel clones your NIGHT SHIFT card', detail: 'The encoder’s own clock: 22:57.' },
    { id: 'e', title: 'Room 17 is checked out on Nina’s login', detail: 'The checkout she watched on the monitor.' },
    { id: 'f', title: 'Nina is taken through the staff door', detail: 'Your cloned card opens it.' },
    { id: 'g', title: 'Room 17 is searched', detail: 'Your card again, while you sat in security.' },
    { id: 'h', title: 'The evidence reaches the police server', detail: 'Before dawn.' },
  ] }),
];
