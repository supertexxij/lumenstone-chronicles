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
| Move | **Click** ground, or **WASD** / arrows |
| Rotate camera | **Q** / **E**, or right-drag |
| Talk to NPC | **Click** NPC, or walk near and press **F** |
| Inventory / equip | **I** or HUD button |
| Quest journal | **J** or HUD button |
| Wardrobe | **C** or HUD button |
| Mute audio | **M** or HUD button |
| Combat | **Click** enemy · auto-attack ~0.7s tick · walk away to leave · soft aggro in wilds |
| Parent dashboard | **Parent** · PIN `1234` |

Camera is elevated oblique (RuneScape-like). Soft defeat respawns at the village fountain; unlocks and gear are kept.

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
- Character customize (skin / hair / cape / outfit) with **humanoid** player mesh
- Inventory + equip slots (head, cape, accessory, weapon, belt) — **3D accessory attach** on character when equipped
- **Quest journal (J)** — available/completed by week + progress toward next unlock
- Quest unlock gear (plain names only)
- RuneScape-style **tick combat** with clearer hitsplats, player weapon swing pose, enemy flinch + death dissolve, soft wild aggro, wholesome defeat verbs, soft respawn
- Wild edges: Lost Lantern Wisp, Shadow Moth, Briar Boar, Dust Golem
- **Procedural audio** (footstep, hit/miss, swing, UI click, quest complete, soft ambient drone) + **mute toggle (M)** — no copyrighted music
- Parent dashboard (PIN **1234**) with progress, week unlock, skills-by-week, **Needs Help** list
- Saves to `user://lumenstone_save_v1.json`


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

- Chunky low-poly **humanoid** characters (head, torso, arms, legs, feet) — RuneScape-adjacent, not photoreal
- Equipped hat / cape / weapon / belt / **accessory** show on the player model; NPCs share the same humanoid base
- Enemies have limb-aware creature meshes (boar legs, moth wings, golem arms/legs; wisp stays simple)
- Procedural walk / attack poses (no skeletal AnimationPlayer clips yet)
- One region (village + wild edges); not a full world map yet
- Campaigns I–IV (Weeks 1–36) complete — full-year content arc finished
- Audio is short procedural SFX + soft drone (intentionally no copyrighted songs)
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
