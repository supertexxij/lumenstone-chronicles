# Lumenstone Chronicles (Godot 4)

A **downloadable** RuneScape-style open-world learning RPG for Christian / creationist **Grade 3** homeschool.

Built with **Godot 4.3** + **GDScript**. **Weeks 1–36** (Campaigns I–IV, full year) are playable: traditional math (not Common Core), language arts, creation science, US/Texas history, and Bible memory/virtues.

Reference quest/item data also lives in `/workspace/lumenstone-game/` (browser prototype) and curriculum notes in `/workspace/lumenstone-curriculum/` — this Godot project is the native desktop build.

## Godot binary

Official Godot **4.3.stable** Linux x86_64 (standard / GDScript):

```
/workspace/tools/godot/Godot_v4.3-stable_linux.x86_64
```

Convenience symlink: `/workspace/tools/godot/godot`

Export templates installed at:
`~/.local/share/godot/export_templates/4.3.stable/`

## Run from source (Ubuntu / Linux)

```bash
/workspace/tools/godot/godot --path /workspace/lumenstone-godot
```

Headless smoke:

```bash
/workspace/tools/godot/godot --headless --path /workspace/lumenstone-godot --quit-after 120
```

## Play the exported builds

Prefer **GitHub Releases** (binaries are large; `builds/` is gitignored):

https://github.com/supertexxij/lumenstone-chronicles/releases

### Linux / Ubuntu (local export)

```bash
chmod +x /workspace/lumenstone-godot/builds/linux/LumenstoneChronicles.x86_64
/workspace/lumenstone-godot/builds/linux/LumenstoneChronicles.x86_64
```

The `.pck` is **embedded** in the binary (single file).

### Windows (local export)

```
builds/windows/LumenstoneChronicles.exe
```

Double-click `LumenstoneChronicles.exe` (pck embedded).

If SmartScreen warns on an unsigned build, choose “More info” → “Run anyway” (local family build).

## Re-export

```bash
GODOT=/workspace/tools/godot/Godot_v4.3-stable_linux.x86_64

# Linux
$GODOT --headless --path /workspace/lumenstone-godot \
  --export-release "Linux/X11" \
  /workspace/lumenstone-godot/builds/linux/LumenstoneChronicles.x86_64

# Windows (from this Linux box — templates already installed)
$GODOT --headless --path /workspace/lumenstone-godot \
  --export-release "Windows Desktop" \
  /workspace/lumenstone-godot/builds/windows/LumenstoneChronicles.exe
```

Presets: `export_presets.cfg` (`Linux/X11`, `Windows Desktop`).

> Note: Windows export may print a harmless warning about `rcedit` / version resources if wine+rcedit is missing. The `.exe` still runs.

## Controls

| Action | Input |
|--------|--------|
| Move | **Click** ground (yellow ring), or **WASD** / arrows |
| Rotate camera | **Q** / **E**, or right-drag |
| Zoom camera | **Scroll wheel**, or **=** / **-** (also **]** / **[**) |
| Talk to NPC | **Click** NPC, or walk near and press **F** |
| Inventory / equip | **I** or HUD button |
| Quest journal | **J** or HUD button |
| Wardrobe | **C** or HUD button |
| Mute audio | **M** or HUD button |
| Enter guild hall | Walk into glowing **Enter** door · exit via blue glow indoors |
| Soft travel | **T** menu · **H** Fountain · **N** Glade · **B** Ridge · **G** Prayer Garden · **L** Lookout Rock · **K** Mill Bridge · **O** Cedar Hollow · **P** Willow Bend · **Y** Reed Pool · **U** Quiet Cross · **X** Stone Arch · **Z** Amber Knoll · **6** Birch Rest · **7** Fern Dell · **8** Heather Heath · **9** Thistle Rise · **0** Maple Copse · **1–5** halls (outdoors only) |
| Eat best food | **V** / **F1** — highest-heal pantry item off cooldown (Bread / Water / Trail Rations / Honey Cake / Hearty Stew) |
| Combat | **Click** enemy · auto-attack ~0.7s tick · walk away to leave · yellow soft-aggro warning then pull · first-fight tip toast |
| Parent dashboard | **Parent** · PIN default `1234` (changeable; type **RESET** twice to restore) |
| Save slots in-game | **Saves** on HUD · switch / rename / clear without wiping parent PIN |

Camera is elevated oblique (RuneScape-like) with zoom. Minimap (corner) + compass (top) aid village/wilds orientation. Soft defeat respawns at the village fountain; unlocks and gear are kept.

## Campaign content (Weeks 1–36 — Campaigns I–IV)

**Unlock rule:** Week 1 is available immediately. Week **N+1** unlocks after mastering that week’s **Friday Raid Review** (or after mastering **4+** quests in week N as a soft fallback). Locked quests appear greyed on NPC lists. Max unlock for the full year is **week 36**.

### Campaign I — *Kindling the Lamps* (Weeks 1–9)

| Week | Theme | Guild focus |
|------|--------|-------------|
| **1** | *The First Lumen* | Place value; +/− facts; sentences; Creation Days 1–2; maps US/Texas; Genesis 1:1 & Wonder |
| **2** | *Stones of Ten* | Regrouping addition & coins; nouns/topic sentence; Day 3 plants; Indigenous North America; Genesis 1:3–5 & Gratitude |
| **3** | *Bridges Across the River* | Subtraction regrouping, estimation, time; verbs/paragraph; Day 4 sun/moon/stars (created lights); Indigenous Texas; Psalm 19 & Reverence |
| **4** | *The Multiplication Gate Opens* | Meaning of ×, facts 0–2/5/10, arrays; adjectives; Day 5 sea/birds; explorers overview; Genesis 1:20–23 & Courage |
| **5** | *Hall of Times-Tables* | Facts 3–4 & equal-groups problems; capitalization/friendly letter; Day 6 land animals & people (God’s image); Spanish explorers/missions; Genesis 1:26–28 & Dignity |
| **6** | *Steward’s Storehouse* | Facts 6–7, multi-step, inches; informational/how-to; Day 7 rest; 13 colonies; Genesis 2:2–3 & Rest & trust |
| **7** | *Raid of the Fact Keepers* | Facts 8–9 & perimeter; story structure; habitats (forest/pond/desert); colonial life; Proverbs 6:6–8 (ant) & Diligence |
| **8** | *Lanterns of Language* | Facts 11–12 & ÷ as sharing; synonyms/poetry; weather; Road to Revolution; John 1:1–3 & Truthfulness |
| **9** | *Campaign I Raid Review & Feast* | Cumulative math/LA/science/history/Bible review; Campaign I badge + Kindling Cloak |

### Campaign II — *Scrolls of the Free* (Weeks 10–18)

**Season theme:** Fluency & freedom — multiplication/division strength, stronger writing, rocks & water cycle, Revolution → Constitution → early republic, Texas Spanish/Mexican eras; virtues courage, justice, faithfulness.

| Week | Theme | Guild focus |
|------|--------|-------------|
| **10** | *The Equal-Share Well* | Division & fact families; informational main idea (ai/ay); rocks/minerals; Declaration; Galatians 5:13 & liberty with responsibility |
| **11** | *Alamo of Algorithms* | Multi-digit × & estimation; narrative/dialogue; soil & bean sprout; Revolutionary War; Joshua 1:9 & Courage |
| **12** | *Constitution Citadel* | Multi-digit × & area; pronouns/revise (soft c/g); water cycle; Constitution/Bill of Rights; Romans 13:1 & Order |
| **13** | *Westward Lanterns* | Division with remainders; informational report notes; habitats & food chains; westward expansion; Psalm 121 & Trust |
| **14** | *Texas Under Spain* | Fractions as parts of a whole; fluency/commas (oi/oy); animal classifications; Spanish Texas & missions; Matthew 28 & Faithfulness |
| **15** | *Mexican Texas Roads* | Fractions on number line; fact vs opinion; human body (designed); Mexican Texas & empresarios (Austin); Proverbs 16:3 & Purpose |
| **16** | *Remember the Alamo* | Equivalent fractions & ×/÷ review; timeline/sequence; regional birds; Texas Revolution — Alamo; John 15:13 & Sacrifice/love |
| **17** | *San Jacinto Sunrise* | Elapsed time & money; poetry/simile; insects & life cycles; San Jacinto & Republic of Texas; Psalm 33:12 & Humility |
| **18** | *Campaign II Raid Review & Feast* | Cumulative ×/÷/fractions/time/money; mid-year LA portfolio; science journal review; US + Texas timelines; justice & mercy; Campaign II badge + Scrolls Cloak |

### Campaign III — *Builders of the Republic* (Weeks 19–27)

**Season theme:** Measurement, geometry, multi-step problems; research writing; solar system as created order; Texas Republic → statehood; US growth; virtues perseverance, stewardship, patriotism.

| Week | Theme | Guild focus |
|------|--------|-------------|
| **19** | *Yardstick of the Realm* | Customary length; research notes (tion/sion); solar system created order; Republic of Texas / Houston; Genesis 1:14–18 & Orderliness |
| **20** | *Scales & Measures* | Weight/capacity; 3-paragraph essay; moon phases; Texas statehood 1845; Colossians 3:23 & Excellence |
| **21** | *Geometry Gardens* | Shapes/angles/perimeter; adverbs/dialogue; planets; US symbols; Psalm 8 & Humility |
| **22** | *Star Maps & State Maps* | Area vs perimeter; maps/glossary/index; stars/constellations (biblical framing, no fortune-telling); Texas geography/symbols; Philippians 2 & Cheerfulness |
| **23** | *Multi-Step Mountain* | Multi-step word problems; narrative conflict/resolution; weather instruments; 1860s overview (union, hardship, end of slavery as justice — age-right); Micah 6:8 |
| **24** | *Fraction Forge* | Fractions of a set/compare/add like denominators; spelling/dictation; plant parts; reuniting/inventors; 1 Cor 14:40 & Order |
| **25** | *Citizen Scribes* | Graphs; opinion + oral; conservation as stewardship; citizenship/voting idea; 1 Peter 2:17 & Honor |
| **26** | *Trail of Stories* | Mixed geometry/measurement/graphs; book project; Texas habitats; famous Texans/Americans; Hebrews 12:1 & Perseverance |
| **27** | *Campaign III Raid Review & Feast* | Cumulative measurement/geometry/fractions/multi-step/graphs; LA portfolio; space & stewardship poster; Republic→statehood review; stewardship feast; Campaign III badge + Builders Cloak |

### Campaign IV — *Light for the Realm* (Weeks 28–36)

**Season theme:** Consolidation & celebration — fact mastery, polished writing, science fair-style project, history review & Texas pride, Scripture memory showcase; virtues love, joy, peace, self-control.

| Week | Theme | Guild focus |
|------|--------|-------------|
| **28** | *Mastery Mills* | ×0–12 fluency clinic; grammar bootcamp; choose nature project; US 5-scene retell; Fruit of the Spirit start; self-control |
| **29** | *Problem-Solvers’ Path* | Multi-step story problems; writing process; project plan; Texas 5-scene retell; patience |
| **30** | *Publishers of the Hall* | Fractions + measurement review; publish writing; run experiment; US/TX timeline compare; joy |
| **31** | *Geometry Jubilee* | Shapes/perimeter/area games; poetry cafe; project display; map mastery; thankfulness |
| **32** | *Steward’s Science Fair* | Graph project data; presentation/thank-yous; present project creation-honoring; museum night 3 facts; goodness |
| **33** | *Citizenship Crown* | Money/elapsed time mastery; long passage; nature journal scavenger; rights/responsibilities/flag/pledge; kindness |
| **34** | *Remediation Roads* | Weak-skill clinics all subjects; memory verse review; perseverance |
| **35** | *Raid Review Supreme* | Year assessments math/LA/science/history conferences; Fruit full recite; faithfulness |
| **36** | *Festival of Lumens* | Celebration games/parties/hike/history game night/thanksgiving; love; Campaign IV badge + year champion cloak/certificate |

**218 quests** total (56 Campaign I + 54 Campaign II + 54 Campaign III + 54 Campaign IV), each with MC / typed challenges and answer keys. Talk to guild NPCs on the village green.

## What’s implemented (vertical slice)

- Dense village green: fountain, path spokes/trim, trees, rocks/bushes, **barrels / fences / lanterns / benches / crates / flowers**, richer **5 guild halls** (porch, pillars, banners, chimneys)
- NPCs for all five guilds with **Weeks 1–36** quests (curriculum-aligned, Campaigns I–IV / full year complete) + idle variety (sway / wave / look / shift)
- Character customize (skin / hair / cape / outfit) with **humanoid** player mesh (clearer arms/legs + visible equipped gear)
- Inventory + equip slots (head, cape, accessory, weapon, belt) — **3D accessory + held weapon + cloak/armor overlays** when equipped
- **Quest journal (J)** — available/completed by week + progress toward next unlock
- Quest unlock gear (plain names only)
- RuneScape-style **tick combat** with clearer hitsplats, player weapon swing pose, enemy flinch + death dissolve, soft wild aggro, wholesome defeat verbs, soft respawn
- Wild edges: Lost Lantern Wisp, Shadow Moth, Briar Boar, Dust Golem, Moss Badger, Cedar Stag, Pine Fox, Oak Hare, Birch Squirrel, Aspen Otter
- **Camera zoom** (scroll / `=` `-`) + **entity-first click targeting** (props no longer steal enemy/NPC/ground clicks)
- **Weapon mesh variants** on equip: practice sword, oak axe, shepherd staff, yew bow (cosmetic), flint dagger
- **Minimap + compass** + day/dusk/night label for village/wilds orientation
- **Subtle day–night tint** (readable nights; steady indoor lighting in halls)
- **Enterable guild halls** — door volumes teleport to simple interior rooms with exit glow
- Soft-aggro **chunky yellow telegraph** (~1.15s, bright torus rim + soft fill) + gentle “notices you…” toast before pull
- **Denser guild-hall interiors** — quest desks (F), bookshelves, study tables/chairs, rugs, notice boards, indoor attendants
- **Weather cycle** (clear → fog → rain particles) — HUD/R toggle; quiet rain loop when unmuted; readable fog
- **Later-tier weapons** (cedar/bronze/iron/Lightbearer, crook, longbow, Steward’s Mallet) gated by mid/late quests + combat level
- **Lantern Glade** northern brook path spur + landmark + a few extra wild spawns (small map expansion)
- **Pine Ridge** western spur beyond the glade — pine stand, creek ford, signpost, a few wild spawns (**B** soft travel)
- **Stronger hall lighting** (warm omni lanterns) + light **per-guild prop themes** (blocks/abacus, scrolls, plants, map table, lectern/candles)
- **Richer NPC greetings** (short wholesome lines per guild; no combat jargon)
- Soft **combat tutorial toasts** on first yellow telegraph and first fight
- **Quest-desk highlight** pulse when standing nearby (F still talks to mentor)
- **Quiet rain audio loop** during rain weather when unmuted (respects **M**)
- **Procedural audio** (footstep, hit/miss, swing, UI, quest complete, ambient drone + short original village music loop) + **mute toggle (M)** — no copyrighted music
- Parent dashboard (PIN default **1234**, changeable) with progress, week unlock, skills-by-week, **Needs Help** list
- **3 save slots** on title screen (legacy `lumenstone_save_v1.json` migrates into Slot 1)
- Soft **Travel (T)** menu + landmark keys (Fountain / Glade / Ridge / Prayer Garden / Lookout / Mill / Hollow / Willow / Reed / Quiet Cross / Stone Arch / Amber Knoll / Birch Rest / Fern Dell / Heather Heath / Thistle Rise / Maple Copse / halls)
- Clearer wilds corridors (wider dirt paths, thinner tree collision, corridor keep-outs)
- **Prayer Garden** eastern landmark with soft travel (**G**)
- **Indoor rain drip** SFX when raining + indoors + unmuted
- Saves to `user://lumenstone_save_slot_N.json` (+ legacy mirror for Slot 1)
- **Overwrite / clear confirm** dialogs on title (non-empty slots)
- **In-game Saves panel** (switch / optional rename / clear) — parent PIN file untouched
- **PIN recovery**: type `RESET` twice in Parent panel to restore default `1234`
- **Click-to-move path assist** when stuck against props (slide + side bias)
- **Lookout Rock** southeast landmark + soft travel (**L**)
- Optional **slot labels** on title / Saves panel
- Combat food: **Wholesome Bread** (+12 HP) and **Cool Water** (+8 HP) starters — Use in inventory
- **Mill Bridge** southwest landmark + soft travel (**K**) + minimap mark
- **Cedar Hollow** northeast landmark + soft travel (**O**) + Cedar Stag
- Outdoor **NavigationRegion3D** bake for click-to-move (raycast path assist fallback)
- Consumable **pantry stacks** (Bread ×5 / Water ×8) + short cooldown; refill at fountain
- Stronger **per-slot rename** on title + in-game Saves panel
- Quest-desk / hall density polish (extra shelf, desk props, study nook, plaque)
- Lookout path corridor fix (diagonal keep-clear)
- **Indoor NavigationRegion3D** — reliable click-to-move in guild halls (desk/shelf awareness)
- Inventory **live cooldown ticks** for Bread / Water / Trail Rations while the panel is open
- Mid-game combat food: **Trail Rations** (+20 HP, ×3) — unlock Week 5 Friday Raid **or** Combat Lv 3; fountain refill
- Outdoor **nav re-path** when blocked mid-walk (refresh nav + assist waypoints)
- **Mill Bridge** polish (foam, door/window, grindstone, sacks, fence) + **Lookout Rock** polish (steps, spyglass, flag, fire ring)
- Fountain pantry refill covers all unlocked consumables (not only starters)
- **V / F1** hotkey eats best available food (highest heal, pantry + cooldown aware)
- Light **NavigationAgent avoidance** + NPC/foe obstacles; soft sidestep around mentors
- Tighter **hall prop collision** + a bit more desk/shelf density (perf-minded)
- Fountain **rest** clears soft combat / yellow pull and shows brief green HP regen ticks
- Inventory Use button respects empty pantry stacks (v1.8 bugfix)
- Indoor attendant shifted clear of quest-desk approach

### Wave 11 overnight (v1.11.0-overnight)
- Later-tier combat food: **Hearty Stew** (+36 HP, ×2) — unlock Week 21 Friday Raid **or** Combat Lv 7; fountain refill
- **Parent dashboard** campaign tabs (I–IV) for week-by-week skills across all 36 weeks
- HUD **pantry stacks / next-food** readout beside HP (V hotkey target + cooldown)
- Indoor nav bake `agent_radius` aligned to `cell_size` (quiets precision warning)
- Bugfix: weapons/gear with `combat_level_req` no longer unlock from quest mastery alone (AND gate); food stays OR

### Wave 12 overnight (v1.12.0-overnight)
- Headless quieting: skip **Label3D** in headless; clear mesh RIDs on exit (`HeadlessGuard`) to cut `mesh_get_surface_count` spam
- Parent dashboard: **collapsible week rows** inside campaign tabs (expand current week by default)
- Feel polish: soft **yellow click-to-move marker** (RuneScape-style destination ring)
- Bug fix: eating food emits **green heal hitsplat** (`heal_tick`); combat **level-up toast** on foe clear



### Wave 18 overnight (v1.18.0-overnight)
- Slightly tougher **late wilds** foes (Briar Boar / Dust Golem HP, damage, accuracy) so Def 5 mid-combat still has a soft poke — early wisps/moths unchanged
- **Denser village-green / plaza ambient** — more bird/bug sites + denser particle counts around the fountain
- **Armor icons on the equipped loadout row** (not only the bag list) with Head/Cape slot glyphs
- Bug fix: Unequip only works when the selected bag row is the worn [E] item (v1.17 could clear another item in that slot)
- Bag ItemList uses fixed 16×16 icons for clearer armor glyphs
- Re-export Linux + Windows

### Wave 19 overnight (v1.19.0-overnight)
- Added the **Moss Badger** foe with a chunky low-poly mesh, gentle defeat language, and five wilds spawns.
- Raised the soft-defense ceiling to **7** so late cloaks and crowns can contribute together while every hit still ticks for at least 1.
- Added denser ambient life around guild-hall doorsteps, indoor halls, and the wilds spurs.
- Inventory polish: equipped loadout rows keep clear armor icons, and Unequip only acts on the selected worn item.
- Re-export Linux + Windows.



### Wave 41 overnight (v1.41.0-overnight)
- Soft **rain puddle ripples** — gentle expanding rings on the ground while raining outdoors (with splash; RuneScape-chunky, wholesome)
- Clearer **first-fight tip** — soft ticks (~0.7s) + walk away / click ground to leave
- New wilds foe **Alder Duck** — plump body, flat bill, short wings, paddle feet, gentle “cradled” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare / Birch Squirrel / Aspen Otter / Elm Raccoon / Hazel Hedgehog / Willow Wren / Maple Mouse / Spruce Mole / Beech Chipmunk)
- HUD QoL: **combat level near HP** (`HP N / M · Lv N`) + soft **Ready flash** when food cooldown ends (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 40 overnight (v1.40.0-overnight)
- Soft **milestone toast every 5 weeks unlocked** — gentle fifth-mark celebration (weeks 5/10/15/20/25/30 + full-year at 36)
- Clearer **landmark approach toast** — ✦ New landmark / ✦ Near wording so wilds places read at a glance
- Quiet **combat XP float** on foe defeat — soft cream **+N XP** rise (RuneScape-chunky, wholesome; no cheesy combat labels)
- New wilds foe **Beech Chipmunk** — cheek pouches, back stripes, short bushy tail, gentle “nestled” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare / Birch Squirrel / Aspen Otter / Elm Raccoon / Hazel Hedgehog / Willow Wren / Maple Mouse / Spruce Mole)
- Parent QoL: clearer **PIN-change success toast** + campaign tabs show **mastered/total** for that campaign (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 39 overnight (v1.39.0-overnight)
- Soft **firefly sparkles at dusk** outdoors — warm gold-green motes gather around the player from dusk into night (off indoors; RuneScape-chunky, wholesome)
- Clearer **compass N marker** — chunkier gold **N** with soft outline + warm plate so north reads at a glance
- Clearer **pantry empty toast** — names the fountain (**H**) refill
- New wilds foe **Spruce Mole** — low round body, pointed digging snout, stubby paws, gentle “tucked” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare / Birch Squirrel / Aspen Otter / Elm Raccoon / Hazel Hedgehog / Willow Wren / Maple Mouse)
- Travel QoL: Travel (T) menu **Find:** name search/filter + section **group counts** (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 38 overnight (v1.38.0-overnight)
- Soft **brook murmur near water landmarks** (fountain, glade brook, creek ford, mill creek, willow bend, reed pool) — respects mute; RuneScape-chunky, wholesome
- Clearer **mute indicator** — warm amber plate + **Muted · M** when silent; clearer **quest-complete chime** (soft rising sparkle)
- New wilds foe **Maple Mouse** — round body, big ears, long thin tail, gentle “settled” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare / Birch Squirrel / Aspen Otter / Elm Raccoon / Hazel Hedgehog / Willow Wren)
- Save QoL: quieter **Autosaved** toast (shows slot nickname) + **Save · nickname** HUD chip (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 37 overnight (v1.37.0-overnight)
- Soft **indoor hall reverb** cue when inside guild halls + soft **leaf rustle near trees** outdoors (respect mute; RuneScape-chunky, wholesome)
- Clearer **soft-aggro countdown toast** — names the foe with ~seconds remaining, plus a mid-telegraph nudge (no cheesy combat labels)
- New wilds foe **Willow Wren** — tiny body + quick wings, gentle “coaxed” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare / Birch Squirrel / Aspen Otter / Elm Raccoon / Hazel Hedgehog)
- Inventory QoL: clearer **[Head]/[Cape]/[Wpn]** equipped slot tags; gray out unequippable items with reason (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 36 overnight (v1.36.0-overnight)
- Clearer **combat swing whoosh** — chunkier soft band-sweep with gentle pitch variety (respects mute; no cheesy combat labels)
- Clearer **minimap zoom feel** — camera zoom in/out scales the map world radius + soft inner tick when close
- New wilds foe **Hazel Hedgehog** — round body + spine tufts, gentle “stilled” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare / Birch Squirrel / Aspen Otter / Elm Raccoon)
- Journal QoL: filter label **Mastered ★**; **All weeks** section headers (Available / Mastered / Locked); attempted-not-mastered rows show **mastery %** (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 35 overnight (v1.35.0-overnight)
- Soft **footstep pitch variety** — gentle left/right thud pitch so walks feel alive (respects mute)
- Clearer **combat HP number on HUD** — bold cream **HP N / M** with soft outline (RuneScape-chunky, no cheesy combat labels)
- Soft **dusk lamp flicker** — village lanterns glow with a gentle irregular flicker at dusk
- New wilds foe **Elm Raccoon** — face mask + ringed bushy tail, gentle “hushed” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare / Birch Squirrel / Aspen Otter)
- Parent QoL: needs-help list shows **WEEK / GUILD** more boldly + warmer empty-state encouragement (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 34 overnight (v1.34.0-overnight)
- Soft **outdoor wind whoosh** — gentle filtered hush while outdoors (off indoors; respects **M**)
- Clearer **food cooldown on HUD** — **Wait N.Ns** / **Ready** with soft color (no cryptic CD)
- Soft **wardrobe open flourish** — gentle scale + fade when opening Look/Wardrobe (RuneScape-chunky, wholesome)
- New wilds foe **Aspen Otter** — sleek body, flat paddle tail, gentle “lulled” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare / Birch Squirrel)
- Travel QoL: Travel (T) menu marks **★ last** visited landmark; soft-travel toast names arrival (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 33 overnight (v1.33.0-overnight)
- Softer **rain audio mix** — quieter hush + gentler drip pops (respects **M**)
- Clearer **soft-defeat toast** — rest-safe fountain wording with HP & pantry restore note
- Soft **plaza campfire crackle** when near the hearth (RuneScape-chunky, wholesome; respects mute)
- New wilds foe **Birch Squirrel** — tuft ears, bushy upright tail, gentle “gentled” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox / Oak Hare)
- Quest QoL: near-miss toast shows **mastery %**; NPC quest list marks mastered rows with **★** (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 32 overnight (v1.32.0-overnight)
- Soft **campfire ember sparks** polish — denser loft + bright spark tips on the plaza hearth (RuneScape-chunky, wholesome)
- Clearer **Year HUD chip** — soft green plate with **Year · N%** so year progress reads at a glance
- Soft **music ducking on talk** — village tune dips while mentor Talk (F) is open (respects mute)
- New wilds foe **Oak Hare** — long-ear hop hare with cotton-tail, gentle “eased” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag / Pine Fox)
- Inventory QoL: armor rows show clearer **[Def +N]**; pantry food rows show **+N HP** heal preview (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 31 overnight (v1.31.0-overnight)
- Soft **plaza campfire glow** — warm hearth ring + ember motes east of the fountain (RuneScape-chunky, wholesome)
- Clearer **NPC talk prompt** — nearby mentors show **Talk (F)** with a soft gold pulse
- Combat **target reticle** — soft cream ring under the engaged foe (no cheesy combat labels; tick combat unchanged)
- New wilds foe **Pine Fox** — slender pointed-ear fox with bushy tail, gentle “soothed” defeat language, five wilds spawns (distinct from Moss Badger / Cedar Stag)
- Journal QoL: **★ on mastered quest rows** + clearer **Mastered this week: N / M ★** (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 30 overnight (v1.30.0-overnight)
- Soft **wind leaf particles** — warm maple flakes drift on a gentle breeze around the player outdoors (RuneScape-chunky, wholesome)
- Clearer **minimap player arrow** — larger tip with soft gold outline so facing direction reads at a glance
- New northwest wilds landmark **Maple Copse** (soft travel **0**) with toasts, minimap maple-leaf mark, path corridor, autumn maple stand, and denser ambient life
- Parent QoL: **Copy line** shows week unlock + year mastery % on one plain line; current campaign tab marked ★ and current week row highlighted gold (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 29 overnight (v1.29.0-overnight)
- **Travel (T) menu landmark grouping** — Village · Wilds landmarks · Guild halls sections (clearer list, disabled headers)
- Soft **quest-mastery victory sparkle** — cream/gold sparkles near the player when a quest is mastered (RuneScape-chunky, wholesome)
- **Fog density cue** — denser low ground-mist particles + toast “soft mist gathers thick nearby”
- Soft-aggro toast **always names the foe** (first tip + later notices); foe **HP bar** shifts green → amber → warm rose at low HP
- New east-southeast wilds landmark **Thistle Rise** (soft travel **9**) with toasts, minimap thistle mark, path corridor, spiky purple thistle rise, and denser ambient life
- PIN stays **1234**; mastery still ≥80%
- Re-export Linux + Windows

### Wave 28 overnight (v1.28.0-overnight)
- **Village lamp posts at dusk** — plaza lanterns warm up with soft OmniLights as day fades (RuneScape-chunky, wholesome)
- **Rain splash FX** — gentle ground-splash puffs while raining (no loud combat juice)
- Soft combat **pull telegraph polish** — clearer yellow ring breath before a pull (still no cheesy combat labels)
- New west-southwest wilds landmark **Heather Heath** (soft travel **8**) with toasts, minimap heather mark, path corridor, purple heather rise, and denser ambient life
- Save-slot QoL: clearer rename hint (nickname siblings’ saves) + toast names the slot label when switching (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 27 overnight (v1.27.0-overnight)
- **Hall door Enter glow** — warmer pulsing gold wash at guild-hall doors (RuneScape-chunky, wholesome)
- **Footstep dust tweak** — slightly chunkier soft puffs on walk
- Combat **HP float polish** — soft scale pop on hitsplats (no cheesy combat labels)
- New south-southeast wilds landmark **Fern Dell** (soft travel **7**) with toasts, minimap fern mark, path corridor, mossy fern hollow, and denser ambient life
- Journal header shows **campaign name** (e.g. Campaign I — Kindling the Lamps · Week N…)
- Parent Dashboard shows **Last session** time from save (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 26 overnight (v1.26.0-overnight)
- **Day/night ambient audio cue** — soft daytime bird chirps vs gentle night hush (respects **M** mute)
- **Weather cloud density** — sparse clear skies, denser fog cover, medium rain cover (chunky soft puffs)
- **NPC idle variety** near halls — stretch and soft toe-tap added to mentor idles (six styles)
- New southwest wilds landmark **Birch Rest** (soft travel **6**) with toasts, minimap mark, path corridor, pale birch stand, heather tufts, benches, and denser ambient life
- Learning QoL: quest panel shows **running % toward mastery** mid-quiz (`Toward mastery: N% (need ≥80%)`) (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 25 overnight (v1.25.0-overnight)
- **Minimap landmark icons** — chunky distinct shapes (fountain, tree, cross, arch, water, rock, mill, knoll, hall) so wilds marks read at a glance
- Compass **nearest-landmark tick** — soft gold tick on the compass ring points toward the closest landmark
- **Wardrobe preview polish** — live skin/hair/cape/outfit color swatches before you confirm
- New east-northeast wilds landmark **Amber Knoll** (soft travel **Z**) with toasts, minimap mark, path corridor, layered honey-stone rise, wildflowers, and denser ambient life
- Inventory/combat QoL: **Unequip toast** names the item (cape restores Travel Cape); combat line flashes **Def N softens the hit** when soft armor blocks a poke (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 24 overnight (v1.24.0-overnight)
- Soft defeat **fountain restore FX** — cream/gold sparkles + soft mist at the village fountain when you respawn (RuneScape-chunky, wholesome)
- Clearer **food heal toasts** — show healed amount and current HP (`Ate Bread — healed +12 HP (now 28/40) · 4 left`)
- Denser **village-green / plaza ambient** — a few more bird/bug sites around the fountain
- New west wilds landmark **Stone Arch** (soft travel **X**) with toasts, minimap mark, path corridor, weathered stone gateway, and denser ambient life
- Parent QoL: summary header shows **Needs help: N**; Help title updates with count; year/week progress bars gain quarter ticks + `cur/max` fractions (PIN stays **1234**; mastery still ≥80%)
- Re-export Linux + Windows

### Wave 23 overnight (v1.23.0-overnight)
- Clearer **soft-aggro ring**: chunky RuneScape-style yellow **torus rim + soft fill disc** (easier to spot before a pull)
- New east wilds landmark **Quiet Cross** (soft travel **U**) with toasts, minimap mark, path corridor, wooden cross knoll, and denser ambient life
- Chunky framed **landmark sign board** helper (thick post, framed board, gold corner studs) on Quiet Cross
- Learning-loop QoL: journal marks **Friday Raid Review** with ★ + gold highlight + detail note; week-unlock toast includes **~N% of the year** (mastery still ≥80%)
- Re-export Linux + Windows

### Wave 22 overnight (v1.22.0-overnight)
- Clearer **equipped gear / held-weapon** motion: cape sway + weapon tip bob on walk; attack wind-up → strike → recover with wrist flick, counter-arm, and soft torso lean (chunky RuneScape humanoid arms/legs)
- New south wilds landmark **Reed Pool** (soft travel **Y**) with toasts, minimap mark, path corridor, reed clumps, and denser pool ambient life
- Parent/HUD QoL: compact **Year N%** chip on the HUD; soft once-per-day checkpoint reminder toast (PIN stays **1234**)
- Re-export Linux + Windows

### Wave 21 overnight (v1.22.0-overnight)
- Clearer **year progress %** on Parent Dashboard: keep Week unlock bar, add labeled **Year progress / quest mastery** bar (`completed_quests / QuestDB.quests`) plus combined note “Year: week unlock X% · quests mastered Y%”
- Journal header shows the same overall year progress line
- New northwest wilds landmark **Willow Bend** (soft travel **P**) with toasts, minimap mark, path corridor, weeping willow trees, and denser brook ambient life
- Combat polish: soft **hit flash** on foes when a swing lands (cream wash; kill flash unchanged)
- Re-export Linux + Windows

### Wave 20 overnight (v1.20.0-overnight)
- **Visible equipped gear** on the humanoid player: held weapon (sword/axe/staff/bow/dagger/mallet), cloak vs tunic, chest plate + shoulder pads on defensive cloaks, explorer hat vs jeweled crown
- Longer, clearer **arms and legs** on the chunky RuneScape-style humanoid (still not AAA)
- New late-wilds landmark **Cedar Hollow** (northeast spur, soft travel **O**) with toasts, minimap mark, and path corridor
- New foe **Cedar Stag** (branching antlers, graze idle) with four hollow-area spawns
- Village yard **hens and lambs** plus hollow birds/bugs so the green and wilds feel busier
- Re-export Linux + Windows

### Wave 17 overnight (v1.17.0-overnight)
- Mid/late **cloaks & hats** gain plain Soft defense (+1 early/mid, +2 late, +3 Year Champion); crowns +2
- Clearer inventory **armor-slot icons** (head helm / cape drape / food / gear) + "Head armor" / "Cape armor" labels
- **Ambient life on the village green** — birds, bugs, butterfly & sparrow near the fountain (same system as landmarks)
- Feel polish: HUD combat line shows **Def N** when soft armor is active
- Bug fix: low-HP **rose vignette** edge strips now have real thickness (v1.16 zero-height preset bug); soft defense soft-max note when capped (cap 5)
- Re-export Linux + Windows

### Wave 16 overnight (v1.16.0-overnight)
- Inventory **armor / defense UX**: Def +N on gear rows, Head/Cape labeled as armor slots, soft-armor breakdown (level + gear = total)
- **Ambient life** at landmarks — bird flocks, soft bug sparkles, idle butterfly/sparrow/dragonfly critters (wholesome, headless-safe)
- Combat feel: tiny **hit pause** on player hurt + soft **screen-edge rose vignette** when HP is low (kid-friendly)
- Bug fixes: unequipping a cape restores **Travel Cape**; Equip no longer treats food as wearable gear
- Re-export Linux + Windows

### Wave 15 overnight (v1.15.0-overnight)
- Light **player defense** (combat level + cape/head gear) and **enemy hit variance** (±1, occasional firmer poke) — wholesome RuneScape-feel numbers
- Denser **Lantern Glade**, **Pine Ridge**, and **Prayer Garden** spur props (path trim, lanterns, foam/candles, yard props) toward Mill/Lookout quality
- Optional **first-discovery vs return** landmark toast flavor (`discovered_landmarks` forever; per-visit greet memory kept)
- Soft Travel first-discovery toast when you land somewhere new
- Bug fix: foe **kill-flash colors restore** on respawn (v1.14 gold wash could linger)

### Wave 14 overnight (v1.14.0-overnight)
- **Landmark toast memory**: once-per-visit greetings saved in the slot (`greeted_landmarks`); reload in-zone does not re-toast; leave and return greets again
- Soft Travel no longer double-toasts approach + travel (syncs zone via `note_soft_travel_arrival`)
- Soft Travel **Glade / Ridge** land inside approach radii (v1.13 destination bugfix)
- Light **hit variance** on player swings (±1) with ~15% bright hit → stronger gold hitsplat (wholesome)
- Denser **Mill Bridge** and **Lookout Rock** spur paths (trim, lanterns, side props, yard crates)

### Wave 13 overnight (v1.13.0-overnight)
- Subtle **footstep dust puffs** on walk (CPUParticles, headless-safe)
- **Landmark approach toasts** for Lantern Glade / Pine Ridge / Prayer Garden / Lookout Rock / Mill Bridge
- Richer combat feedback: **strong-hit** hitsplat color on high damage + soft **gold kill flash** before dissolve (wholesome)
- Parent dashboard: **persist week expand state** in `user://lumenstone_parent.json`
- Bug fix: Soft Travel hint lists **K Mill** (was missing)

### Architecture

| Autoload | Role |
|----------|------|
| `GameState` | XP, lumens, inventory, combat, week unlock, save/load |
| `ItemDB` | `data/items.json` |
| `QuestDB` | `data/quests.json` (Weeks 1–36 / Campaigns I–IV) |
| `EnemyDB` | `data/enemies.json` + spawns |
| `AudioBus` | Procedural SFX + ambient; respects mute |

World layout: `data/world.json`. Scenes under `scenes/`; scripts under `scripts/`.

## Content philosophy

- Christian / creationist worldview; High King allegory (Narnia-friendly)
- Traditional arithmetic (place value, +/−, × facts) — **not** Common Core framing
- Age-right American & Texas history/geography
- No occult / pagan worship gameplay; combat is soft and non-graphic
- **Plain item names only** (no cheesy virtue-branded attack names)

## Limitations

- Chunky low-poly **humanoid** characters (head, torso, shoulders, arms, legs, feet) — RuneScape-adjacent, not photoreal
- Equipped hat / crown / cape or tunic / weapon held in the right hand / belt / **accessory** / cloak armor plate show on the player model; NPCs share the same humanoid base
- Enemies have limb-aware creature meshes (boar legs, moth wings, golem arms/legs, badger, stag antlers, fox, hare, squirrel; wisp stays simple)
- Procedural walk / attack poses (no skeletal AnimationPlayer clips yet)
- Village green + **Lantern Glade** + **Pine Ridge** + **Prayer Garden** + **Lookout Rock** + **Mill Bridge** + **Cedar Hollow** + **Willow Bend** + **Reed Pool** + **Quiet Cross** + **Stone Arch** + **Amber Knoll** + **Birch Rest** + **Fern Dell** + **Heather Heath** + **Thistle Rise** + **Maple Copse** spurs; not a full multi-biome world map yet
- Campaigns I–IV (Weeks 1–36) complete — full-year content arc finished
- Audio is short procedural SFX + soft drone + original village loop + quiet rain / indoor drip loops (intentionally no copyrighted songs)
- Combat is click-to-engage / soft-aggro auto-attack only
- Learning challenges are in guild quest UI overlays, not mid-fight quizzes

## Project paths

| Path | Purpose |
|------|---------|
| `/workspace/lumenstone-godot/` | This Godot 4 project |
| `/workspace/lumenstone-godot/builds/linux/` | Ubuntu/Linux binary |
| `/workspace/lumenstone-godot/builds/windows/` | Windows `.exe` |
| `/workspace/tools/godot/` | Godot 4.3 editor/headless |
| `/workspace/lumenstone-game/` | Browser reference (do not delete) |
| `/workspace/lumenstone-curriculum/` | Curriculum markdown reference |

## License note

Prototype for family/homeschool use. Scripture quotations use familiar public phrasing for family instruction.
