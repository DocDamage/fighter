# Street Fighter — DocRoshi Remix
## Private Fan Prototype · Game Design Document

| Field | Value |
|---|---|
| **Document Version** | 2.0 |
| **Last Updated** | 2026-05-15 |
| **Project Type** | Private fan prototype |
| **Engine** | Godot 4.x (GDScript) |
| **Render Pipeline** | 2D — Compatibility renderer, pixel-perfect viewport |
| **Target Resolution** | 384 × 224 logical (scaled to display via integer scaling) |
| **Target Frame Rate** | 60 FPS fixed (game-logic tick = 1/60 s) |
| **Target Platform** | PC (Windows) — controller-first, keyboard fallback |
| **Primary Design Target** | Serious competitive 2D fighting game |
| **Visual Direction** | Mixed crossover roster built from supplied pixel-art sprite sheets, ripped stage backgrounds, custom VFX sprite animations, SFII Turbo SFX, DavidKBD synthwave OST, and fighting-game icon packs |
| **Initial Vertical Slice** | Ryu vs Ken — Tournament Day stage |
| **Initial Roster Size** | 4 fighters (Phase 1) · 6+ fighters (Phase 2) |
| **Long-Term Goal** | Expanded crossover roster after the core engine is proven |

> [!CAUTION]
> This design assumes the project remains a **private fan prototype** using supplied assets. Public release or commercial distribution would require replacing all copyrighted/ripped assets with original or licensed material.

## Table of Contents

| § | Section | Key Content |
|---|---|---|
| 0 | Asset Inventory | Complete catalogue of all supplied files |
| 1 | Game Identity | Design pillars and project vision |
| 2 | Combat Direction | Technical parameters and gameplay systems |
| 3 | Vertical Slice | Phase 1/2 roster, stages, and modes |
| 4 | Controls | Six-button layout, Classic/Modern modes |
| 5 | Controller Support | Input system architecture and device support |
| 6 | Defensive Mechanics | Blocking, perfect block, parry — with frame data |
| 7 | Mobility | Movement parameters and air-action economy |
| 8 | Attacks and Combos | Normal matrix, combo rules, damage scaling |
| 9 | Throws | Throw system properties and interactions |
| 10 | Stun / Dizzy | Stun accumulation, recovery, and dizzy state |
| 11 | Super System | Meter economy, gain sources, super tiers |
| 12 | Universal Mechanics | Full mechanic list with VFX/SFX and milestone targets |
| 13 | Character Design | Per-fighter stat tables, move lists, asset bindings |
| 14 | Stage Design | Stage data schema and Phase 1 stage specs |
| 15 | Modes | Versus, Training, CPU, Arcade, Story, Trials, Tutorial |
| 16 | HUD / UI | Element specs, layout diagram, training overlay |
| 17 | Audio Design | Complete SFX → game event mapping tables |
| 18 | VFX Design | Effect → game event mapping and data schema |
| 19 | Data-Driven Structure | Folder layout, sprite pipeline, JSON examples |
| 20 | Godot 4 Implementation | Core scripts and scenes |
| 21 | Development Roadmap | 12 milestones with acceptance criteria |
| 22 | Key Design Warnings | Critical anti-patterns with section cross-refs |
| 23 | Final Direction | Phase 1, Phase 1.5, and Phase 2 build targets |

---

# 0. Supplied Asset Inventory

The following assets ship with the project workspace and are referenced throughout this document.

## 0.1 Fighter Sprite Sheets

| Filename | Source | Format | Notes |
|---|---|---|---|
| `SNES - Super Street Fighter II…Ryu.gif` | SSF2 SNES | GIF sheet | Phase 1 baseline shoto |
| `SNES - Super Street Fighter II…Ken.gif` | SSF2 SNES | GIF sheet | Phase 1 rushdown shoto |
| `SNES - Super Street Fighter II…Guile.gif` | SSF2 SNES | GIF sheet | Phase 1 charge zoner |
| `SNES - Super Street Fighter II…Chun-Li.gif` | SSF2 SNES | GIF sheet | Phase 1 speed/footsie |
| `SNES - Super Street Fighter II…Blanka.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…Balrog.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…Cammy.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…Dee Jay.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…Dhalsim.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…E. Honda.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…Fei Long.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…M. Bison.gif` | SSF2 SNES | GIF sheet | Phase 2 — boss candidate |
| `SNES - Super Street Fighter II…Sagat.gif` | SSF2 SNES | GIF sheet | Phase 2 — sub-boss candidate |
| `SNES - Super Street Fighter II…T. Hawk.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…Vega.gif` | SSF2 SNES | GIF sheet | Phase 2 candidate |
| `SNES - Super Street Fighter II…Zangief.gif` | SSF2 SNES | GIF sheet | Phase 2 grappler |
| `Shin Akuma/` (789 individual PNGs) | Custom rip | Pre-cut frames | Phase 2 — secret/boss character |
| `MagicianRed/` (878 individual PNGs) | Custom rip | Pre-cut frames | Crossover guest fighter |
| `Arcade…Alex.png` | SF III NG | PNG sheet | Future crossover candidate |
| `Arcade…Dudley.png` | SF III NG | PNG sheet | Future crossover candidate |
| `Arcade…Elena.png` | SF III NG | PNG sheet | Future crossover candidate |
| `Arcade…Gill.png` | SF III 2I | PNG sheet | Future crossover boss |
| `Arcade…Guy.png` | SFA3 | PNG sheet | Future crossover candidate |
| `Arcade…Gambit.png` | MvC | PNG sheet | Future crossover guest |
| `Arcade…The Hulk.png` | MvC | PNG sheet | Future crossover guest |
| `Neo Geo…Hanzo Hattori.png` | SamSho 5 | PNG sheet | Future crossover guest |
| `Neo Geo…Athena.png` | KOF 2002 | PNG sheet | Future crossover guest |

## 0.2 Stage Backgrounds (15 total)

| Filename | Suggested ID | Mood |
|---|---|---|
| `…Tournament (Day).png` | `tournament_day` | Bright, clean — training/debug |
| `…Temple (Night).png` | `temple_night` | Dark dramatic — story/boss |
| `…Noh Stage.png` | `noh_stage` | Traditional — arcade/story |
| `…Sound Beach.png` | `sound_beach` | Upbeat coastal |
| `…Back Alley.png` | `back_alley` | Gritty urban |
| `…The Pit II.png` | `pit_ii` | Iconic bridge — dramatic |
| `…Deadpool.png` | `deadpool` | Acid pit hazard visual |
| `…Goro's Lair.png` | `goros_lair` | Underground throne |
| `…Kahn's Arena.png` | `kahns_arena` | Grand arena |
| `…Kombat Tomb.png` | `kombat_tomb` | Underground crypt |
| `…Living Forest.png` | `living_forest` | Eerie nature |
| `…The Armory.png` | `armory` | Weapons display |
| `…The Portal.png` | `portal` | Mystical gateway |
| `…The Tower.png` | `tower` | High elevation |
| `…Wasteland.png` | `wasteland` | Desolate post-apoc |

## 0.3 Music (10 OGG tracks — DavidKBD "Electric Pulse")

| # | Track | Suggested Assignment |
|---|---|---|
| 01 | Electric Pulse | Title screen / main menu |
| 02 | Digital Horizon | Character select |
| 03 | Cyber Lights | `tournament_day` stage |
| 04 | Retrochrome Nights | `noh_stage` stage |
| 05 | Neon Arcadia Awakening | `temple_night` / boss fight |
| 06 | Time Warp | `pit_ii` / `back_alley` stage |
| 07 | Electric Dreams of Infinity | Victory / results screen |
| 08 | Quantum Ripples of Sound | Arcade ending / credits |
| 09 | Vapor Trails Pursuit | `sound_beach` / alternate stage |
| 10 | Synthetic Power Surge | Final boss / climax |

## 0.4 Sound Effects

### SFII Turbo SFX Library (`sound fx/Street Fighter II Turbo - Sounds (SNES)/`)

| Category | Files | Key Samples |
|---|---|---|
| **Fight Announcer** | 9 WAVs | Round 1/2/3, Final, Fight!, You Win, You Lose, Perfect |
| **Moves & Hits** | 16 WAVs | Light/Medium/Hard Attack whiffs, Jab/Strong/Fierce/Short/Forward/Roundhouse hits, Blocked, Landing, Knockdown, Electricity, Fire |
| **Character Voices** | 22 WAVs | Ryu/Ken Hadouken/Shoryuken/Tatsumaki, Guile Sonic Boom, Chun-Li voices, KO screams |
| **Select/Stage/Other** | remaining | Cursor, stage ambience, misc UI |

### Fighting Announcer Voices (`Fighting Announcer Voices/`)
64 WAV files including: Fight!, Round…, KO, Perfect, Game Over, Continue, Select Your Fighter, Stage Select, countdown 0–9, round numbers n1–n10, reaction callouts (Amazing, Excellent, Great, Super, etc.)

## 0.5 VFX Sprite Animations (22 effect sets in `VFX/`)

| Effect Folder | Use Case | Frame Rates |
|---|---|---|
| `Effect_SmallHit` | Light-attack hit spark | 30 fps / 60 fps |
| `Effect_BigHit` | Heavy-attack hit spark | 30 fps / 60 fps |
| `Effect_Impact` | Medium-attack hit spark | 30 fps / 60 fps |
| `Effect_DitheredFire` | Hadouken / fire specials | 30 fps / 60 fps |
| `Effect_FastPixelFire` | Ken fire effects | 30 fps / 60 fps |
| `Effect_ElectricShield` | Blanka / electric specials | 30 fps / 60 fps |
| `Effect_Charged` | Super startup charge aura | 30 fps / 60 fps |
| `Effect_Explosion` | Projectile clash / KO | 30 fps / 60 fps |
| `Effect_Explosion2` | Alternate explosion | 30 fps / 60 fps |
| `Effect_BloodImpact` | Optional blood toggle | 30 fps / 60 fps |
| `Effect_PuffAndStars` | Dizzy state indicator | 30 fps / 60 fps |
| `Effect_Kabooms` | Super impact / cinematic | 30 fps / 60 fps |
| `Effect_Anima` | Parry success flash | 30 fps / 60 fps |
| `Effect_Constellation` | Perfect block spark | 30 fps / 60 fps |
| `Effect_Hyperspeed` | Dash / speed trail | 30 fps / 60 fps |
| `Effect_Magma` | Stage hazard / super | 30 fps / 60 fps |
| `Effect_PowerChords` | Taunt / buff activation | 30 fps / 60 fps |
| `Effect_EldenRing` | Guard cancel / alpha counter | 30 fps / 60 fps |
| `Effect_TheVortex` | Command grab / super | 30 fps / 60 fps |
| `Effect_Tentacles` | Grapple / grab VFX | 30 fps / 60 fps |
| `Effect_Wheel` | Spinning special VFX | 30 fps / 60 fps |
| `Effect_Worm` | Projectile trail variant | 30 fps / 60 fps |

## 0.6 UI & HUD Assets

| Asset | Contents |
|---|---|
| `TurboGrafx-16…HUD and UI.png` | Health bars, timer, round markers |
| `Neo Geo…Timer Sprites.png` | KOF-style timer digits |
| `Wii U…Enemy Health Bars.png` | Premium health bar reference |
| `Saturn…Hit Sparks & Blood.png` | Additional spark/blood sprites |
| `Game Gear…Backgrounds.png` | SamSho BG reference tiles |

## 0.7 Input & Controller Icon Packs

| Pack | Contents |
|---|---|
| `fighting-game-icons/basic_directions/` | 8-way directional arrows (normal + highlighted) |
| `fighting-game-icons/motions_with_d_pad/` | 30 motion-input diagrams (236, 623, 360, etc.) |
| `fighting-game-icons/motions_without_d_pad/` | Same motions, arrow-only style |
| `fighting-game-icons/hit_flags/` | High/Mid/Low/Throw/Unblockable icons |
| `fighting-game-icons/miscellanea/` | Plus sign, arrow, null button |
| `keyboard and controller icons/` | Xbox 360, Xbox One, PS3–PS5, Switch, Steam Deck, generic controller, full keyboard, mouse, touchpad icon sets |

---

# 1. High-Level Game Identity

**Street Fighter — DocRoshi Remix** is a mixed-world crossover 2D fighter inspired by the feel and structure of *Street Fighter III: 3rd Strike*, expanded with modern controller support, optional modern controls, air blocking, anime-style mobility options, and a broader crossover presentation.

The game should feel **competitive, deliberate, readable, and skill-based**. It should never become a random party fighter. The crossover element comes from the roster and stages — not from chaotic mechanics.

### Core Design Pillars

| # | Pillar | Key Implication |
|---|---|---|
| 1 | **Precise competitive combat** | Frame-data-driven, 60 fps tick, deterministic |
| 2 | **Strong defensive expression** | Parry, perfect block, throw tech — all viable |
| 3 | **Classic six-button arcade controls** | No shortcut-only fighters; execution matters |
| 4 | **Modern accessibility options** | Modern Mode lowers execution floor, not skill ceiling |
| 5 | **Training-mode-first development** | Training mode ships before Arcade mode |
| 6 | **Data-driven everything** | Fighters, moves, hitboxes, VFX, SFX — all JSON |
| 7 | **Private prototype first** | Prove 4 fighters before expanding the roster |

---

# 2. Core Combat Direction

The base feel should be:

- **Grounded and deliberate** like Street Fighter III: 3rd Strike
- **Readable neutral game** — footsies and spacing matter more than rushdown
- **Parry / perfect-block mind games** create high-level defensive expression
- **Combos matter** but should not erase neutral entirely (target: 4–8 hit optimal combos)
- **Air mobility exists** but should not turn the game into pure anime chaos

## Technical Combat Parameters

| Parameter | Value | Notes |
|---|---|---|
| Game tick rate | 60 fps | All frame data expressed in 60ths of a second |
| Hitstop (light) | 8 frames | Freeze on hit connect |
| Hitstop (medium) | 10 frames | |
| Hitstop (heavy) | 12 frames | |
| Hitstop (super) | 16 frames | |
| Gravity | -1200 px/s² | Affects all airborne characters |
| Max fall speed | 800 px/s | Terminal velocity cap |
| Corner pushback | 50% of normal | Reduced when against wall |
| Wakeup invincibility | 3 frames | After knockdown recovery |

## Supported Gameplay Systems

| Category | Systems |
|---|---|
| **Movement** | Walk, crouch, jump (neutral/forward/back), dash, backdash, double jump, air dash |
| **Defense** | Block (stand/crouch/air), parry, perfect block, throw tech |
| **Offense** | Normals (6 buttons × 3 stances), specials, supers, EX moves, throws, command throws |
| **Systems** | Dizzy/stun, chip damage, damage scaling, juggle limits, combo counter |
| **Modes** | Versus, Training, CPU Battle, Arcade, Story, Combo Trials, Tutorial |

---

# 3. Initial Vertical Slice

The first build should not attempt the full roster. It should prove the complete combat loop with a small but strong set.

## Phase 1 Roster

Recommended first 4 fighters:

1. **Ryu** — `SNES - Super Street Fighter II…Ryu.gif`  
   Baseline shoto. Fireball, uppercut, hurricane kick. Used to validate the core system.  
   SFX: `SFII_69 - RyuKen Hadouken.wav`, `SFII_70 - RyuKen Shoryuken.wav`, `SFII_71 - RyuKen Tatsumaki Senpuukyaku.wav`

2. **Ken** — `SNES - Super Street Fighter II…Ken.gif`  
   Shoto variant. Similar enough to reuse logic, different enough to test balance changes.  
   SFX: shares Ryu voice bank; differentiate via fire VFX (`Effect_FastPixelFire`)

3. **Guile** — `SNES - Super Street Fighter II…Guile.gif`  
   Charge character. Used to validate charge inputs, sonic boom, flash-kick-style anti-air logic.  
   SFX: `SFII_65 - Guile Sonic Boom.wav`

4. **Chun-Li** — `SNES - Super Street Fighter II…Chun-Li.gif`  
   Fast mobility/kick character. Used to validate speed, multi-hit attacks, air movement, and combo variety.  
   SFX: `SFII_55 - Chun-Li Laugh.wav`, `SFII_56 - Chun-Li Spinning Bird Kick.wav`, `SFII_57 - Chun-Li Ya.wav`, `SFII_58 - Chun-Li Yatta.wav`, `SFII_68 - KO Chun-Li.wav`

## Phase 2 Roster Candidates

After Phase 1 engine is stable, expand the roster in priority order:

| Priority | Fighter | Source | Archetype | Why |
|---|---|---|---|---|
| 1 | **Shin Akuma** | `Shin Akuma/` (789 pre-cut frames) | Rushdown boss | Tests boss-tier stats, pre-cut frame pipeline |
| 2 | **MagicianRed** | `MagicianRed/` (878 pre-cut frames) | Zoner / crossover | Tests crossover art integration, unique projectile |
| 3 | **Zangief** | SSF2 sheet | Grappler | Tests 360/720 motion, command throws |
| 4 | **M. Bison** | SSF2 sheet | Charge rushdown | Tests boss AI, charge-based offense |
| 5 | **Sagat** | SSF2 sheet | Tall zoner | Tests large hurtbox, Tiger Shot/Uppercut |
| 6 | **Blanka** | SSF2 sheet | Unorthodox | Tests electricity VFX, `SFII_49`, `SFII_54` |

## Phase 1 Stages

Use 3 real stages from the supplied `stages/` directory:

1. **Tournament Day** — `SNES - Dragon Ball Z…Tournament (Day).png`  
   Clean, bright. Best for debug, training, and initial tuning.  
   Music: `03 - Cyber Lights-full.ogg`

2. **Noh Stage** — `SNES - Teenage Mutant Ninja Turtles…Noh Stage.png`  
   Strong visual identity and traditional fighting-game aesthetic.  
   Music: `04 - Retrochrome Nights-full.ogg`

3. **Temple Night** — `SNES - Dragon Ball Z…Temple (Night).png`  
   Dark dramatic mood. Ideal for boss fights and story presentation.  
   Music: `05 - Neon Arcadia Awakening-full.ogg`

All stages are visual only. No hazards. No interactable stage mechanics.

## Phase 2 Stages (12 additional backgrounds available)

Back Alley, Sound Beach, The Pit II, Deadpool, Goro's Lair, Kahn's Arena, Kombat Tomb, Living Forest, The Armory, The Portal, The Tower, Wasteland.

## Phase 1 Modes

1. Versus (local 1v1)
2. Training (hitbox overlay, input display, frame data)
3. CPU Battle (single match with AI)
4. Arcade (4-fight ladder)
5. Story shell (intro → rival → boss → ending text)

---

# 4. Controls

## Control Philosophy

The game supports both:

1. **Classic Mode**
   - full six-button control
   - motion inputs
   - charge inputs
   - manual execution

2. **Modern Mode**
   - simplified special access
   - optional assist commands
   - still competitively constrained
   - lower execution barrier without fully replacing classic skill

Classic Mode should be the default for competitive play.

## Six-Button Layout

Movement:
- D-pad / left stick: movement
- up: jump
- down: crouch
- back: block
- forward: walk forward

Attacks:
- Light Punch
- Medium Punch
- Heavy Punch
- Light Kick
- Medium Kick
- Heavy Kick

Utility:
- Throw button
- Parry button
- Menu/Pause
- Training reset
- Optional macro buttons

## Suggested Controller Layouts

All buttons must be remappable via `InputRemapMenu`. Use `InputGlyphResolver` to display correct icons per controller type using the supplied `keyboard and controller icons/` pack.

| Action | Xbox | PlayStation | Switch Pro | Keyboard |
|---|---|---|---|---|
| Light Punch | X | □ | Y | U |
| Medium Punch | Y | △ | X | I |
| Heavy Punch | RB | R1 | R | O |
| Light Kick | A | × | B | J |
| Medium Kick | B | ○ | A | K |
| Heavy Kick | RT | R2 | ZR | L |
| Throw | LB | L1 | L | T |
| Parry | LT | L2 | ZL | Space |
| Pause | Menu | Options | + | Esc |
| Training Reset | View | Share | - | F1 |

---

# 5. Modern Controller Support

The game should support:

- Xbox Series / Xbox One / Xbox 360
- PlayStation-style controllers
- Nintendo Switch Pro Controller
- Steam Controller
- Steam Deck / Steam Input
- Generic XInput controllers
- Generic DirectInput controllers
- Keyboard fallback

## Input System Architecture

The input system must not be hardcoded to Xbox buttons. It should be **action-based** using Godot's `InputMap`.

| Script | Responsibility |
|---|---|
| `InputDeviceManager.gd` | Detect connected controllers, track device type per player |
| `PlayerInputRouter.gd` | Route raw input to correct player's buffer |
| `InputBuffer.gd` | Store 20 frames of input history per player |
| `MotionParser.gd` | Recognize motion inputs (236, 623, etc.) from buffer |
| `ChargeInputTracker.gd` | Track charge duration for ←[→] and ↓[↑] moves |
| `InputProfile.gd` | Per-player button mapping (loaded from JSON) |
| `InputRemapMenu.gd` | UI for rebinding buttons at runtime |
| `InputGlyphResolver.gd` | Return correct icon sprite for current device type |
| `InputHistoryDisplay.gd` | Render input history in Training Mode overlay |

## Input Buffer Specification

Store at least **20 frames** of input history per player.

| Tracked Data | Type | Notes |
|---|---|---|
| Direction (numpad notation) | int (1–9) | 5 = neutral |
| Button presses | bitmask | Per-frame press events |
| Button holds | bitmask | Currently held |
| Button releases | bitmask | Per-frame release events |
| Simultaneous inputs | bitmask | Multiple buttons same frame |
| Charge duration | int (frames) | Per-direction charge timer |
| Air/ground state | enum | `GROUND`, `AIR`, `PREJUMP` |
| Facing direction | int (±1) | Auto-normalized for motion parsing |

## Motion Parser

All motions use **numpad notation** (5 = neutral, 6 = forward, 2 = down, etc.). Icon assets available in `fighting-game-icons/motions_with_d_pad/`.

| Motion | Numpad | Common Name | Icon File |
|---|---|---|---|
| 236 | ↓↙→ | Quarter-circle forward | `direction_236.png` |
| 214 | ↓↙← | Quarter-circle back | `direction_214.png` |
| 623 | →↓↘ | Dragon punch | `direction_623.png` |
| 421 | ←↓↙ | Reverse dragon punch | `direction_421.png` |
| 41236 | ←↓↙→ | Half-circle forward | `direction_41236.png` |
| 63214 | →↓↙← | Half-circle back | `direction_63214.png` |
| 360 | Full circle | Full circle (grappler) | `direction_23698741.png` |
| 720 | Double circle | Double full circle | — (combine two 360 icons) |
| [4]6 | Charge ← then → | Charge forward | `direction_44.png` + `direction_66.png` |
| [2]8 | Charge ↓ then ↑ | Charge up | `direction_22.png` + `direction_88.png` |

## Input Priority

When multiple motions are detected in the same buffer window, resolve by priority:

| Priority | Category | Example |
|---|---|---|
| 1 (highest) | Supers | 236236+P |
| 2 | Command throws | 360+P, 720+P |
| 3 | Special moves | 236+P, 623+P |
| 4 | Throws | Throw button |
| 5 | Target combos | Preset chains |
| 6 | Normals | Single button |
| 7 (lowest) | Movement | Directional only |

When motions overlap: **dragon punch (623) beats fireball (236)** because 623 is a superset.

---

# 6. Defensive Mechanics

## Blocking

Blocking is performed by holding away from the opponent.

| Block Type | Input | Blocks | VFX | SFX |
|---|---|---|---|---|
| Standing | Hold ← | Mids, highs | `Effect_SmallHit` (tinted, 0.5× scale) | `SFII_51 - Blocked.wav` |
| Crouching | Hold ↙ | Mids, lows | `Effect_SmallHit` (tinted, 0.5× scale) | `SFII_51 - Blocked.wav` |
| Air | Hold ← (airborne) | All except grabs | `Effect_SmallHit` (tinted, 0.5× scale) | `SFII_51 - Blocked.wav` |

| Block Property | Ground | Air |
|---|---|---|
| Blockstun (light) | 9 frames | 12 frames |
| Blockstun (medium) | 13 frames | 16 frames |
| Blockstun (heavy) | 17 frames | 20 frames |
| Pushback | Normal | 1.3× normal |
| Chip damage | 20% of move damage | 20% of move damage |

## Chip Damage Setting

Settings menu option:

- Chip KO: **ON** — specials/supers can kill via chip
- Chip KO: **OFF** — chip damage cannot reduce health below 1 HP (default)

## Perfect Block

Perfect block activates when the player blocks within a tight timing window before impact.

| Property | Value |
|---|---|
| Input window | 3–5 frames before impact |
| Blockstun reduction | 50% |
| Pushback reduction | 50% |
| Chip damage | 0 (negated) |
| Meter gain | +5 |
| Stun damage reduction | 50% |
| VFX | `Effect_Constellation` |
| SFX | Unique perfect-block sound (custom or pitched `SFII_51`) |
| Frame advantage | +2 to +4 depending on move |

Perfect block should be **safer and more accessible** than parry, but less rewarding.

## Parry

Parry uses a dedicated parry button (LT / L2 / ZL).

| Property | Value |
|---|---|
| Active window | 5 frames |
| Whiff recovery | 18 frames (punishable) |
| Success freeze | 8 frames (both fighters) |
| Frame advantage | Move-dependent (+5 to +15) |
| Meter gain | +10 |
| Stun damage | 0 (negated) |
| Variants | Ground, crouch, air |
| VFX | `Effect_Anima` |
| SFX | Custom parry impact sound |

Parry should be **powerful but dangerous**. Whiffing a parry is worse than just blocking.

---

# 7. Mobility

Movement should blend Street Fighter III-style grounded combat with selected anime-fighter mobility.

## Universal Movement Parameters

| Movement | Startup | Active | Recovery | Notes |
|---|---|---|---|---|
| Walk forward | 0 | continuous | 0 | Speed varies per character (165–210 px/s) |
| Walk back | 0 | continuous | 0 | Slower than forward walk |
| Crouch | 2 frames | continuous | 2 frames | Transitions from stand |
| Neutral jump | 4 frames | ~32 frames | 2 frames | Pre-jump can be thrown |
| Forward jump | 4 frames | ~36 frames | 2 frames | More horizontal arc |
| Back jump | 4 frames | ~30 frames | 2 frames | Shorter arc, escape tool |
| Dash | 3 frames | 14 frames | 6 frames | Cancellable into normals |
| Backdash | 3 frames | 18 frames | 8 frames | Invincible frames 1–8 |
| Double jump | 3 frames | ~24 frames | 2 frames | Consumes air action |
| Air dash | 5 frames | 12 frames | 8 frames (landing) | Consumes air action |
| Air block | 0 | continuous | 0 | Higher blockstun than ground |

## Movement Balance Rules

Because air dash, double jump, and air blocking can overpower grounded neutral, they must be tuned carefully:

- Air dash has **5-frame startup** (vulnerable) and **8-frame landing recovery**
- Double jump and air dash share one "air action" — you get one or the other, not both
- Air block has **1.3× blockstun** compared to ground block
- Grounded anti-airs (Shoryuken, Flash Kick) should beat careless air approaches
- Throws beat predictable defense (blocking, crouching)
- Parry beats predictable attacks but loses to throws and timing bait

---

# 8. Attacks and Combos

## Normal Attack Matrix (18 normals per character)

| Stance | Light Punch | Medium Punch | Heavy Punch | Light Kick | Medium Kick | Heavy Kick |
|---|---|---|---|---|---|---|
| **Standing** | st.LP | st.MP | st.HP | st.LK | st.MK | st.HK |
| **Crouching** | cr.LP | cr.MP | cr.HP | cr.LK | cr.MK | cr.HK |
| **Jumping** | j.LP | j.MP | j.HP | j.LK | j.MK | j.HK |

Plus: throws, specials, EX specials, supers.

## Hit Properties by Strength

| Property | Light | Medium | Heavy |
|---|---|---|---|
| Startup | 3–5 frames | 6–9 frames | 10–15 frames |
| Active | 2–3 frames | 3–4 frames | 4–6 frames |
| Recovery | 6–8 frames | 10–14 frames | 16–22 frames |
| On-hit advantage | +2 to +5 | +3 to +6 | -2 to +4 |
| On-block advantage | 0 to +2 | -2 to +1 | -6 to -3 |
| Base damage | 20–30 | 50–70 | 80–120 |
| Hitstop | 8 frames | 10 frames | 12 frames |
| Hit SFX | `SFII_42`/`SFII_45` | `SFII_43`/`SFII_46` | `SFII_44`/`SFII_47` |
| Hit VFX | `Effect_SmallHit` | `Effect_Impact` | `Effect_BigHit` |

## Combo Rules

| Rule | Detail |
|---|---|
| Light → Light | Chain cancel allowed (no gap) |
| Light → Special | Cancel allowed on hit or block |
| Medium → Special | Cancel allowed (character-specific list) |
| Heavy → Special | Usually not cancelable unless character-specific |
| Normal → Super | Cancel from designated normals only |
| Special → Super | Cancel allowed (super cancel) |
| Target combos | Character-specific preset chains |
| Air combos | Limited by juggle counter (max 3 post-launch hits) |
| Juggle limit | Each move has a juggle value; sum capped at 8 per combo |

## Damage Scaling

Required to prevent infinite or death combos.

| Hit # | Scaling | Cumulative Example (100 base) |
|---|---|---|
| 1st | 100% | 100 |
| 2nd | 90% | 90 |
| 3rd | 80% | 80 |
| 4th | 70% | 70 |
| 5th+ | 60% (floor) | 60 |
| Super after 4+ hits | Additional 80% multiplier | 48 |
| Throws | Fixed damage, no scaling | — |

---

# 9. Throws

| Property | Value | Notes |
|---|---|---|
| Input | Throw button (LB / L1) near opponent | Cannot be blocked |
| Range | Close only (~40 px) | Standing or crouching opponents |
| Startup | 5 frames | Loses to jump on frame 1–4 |
| Active | 3 frames | |
| Whiff recovery | 25 frames | Punishable on whiff |
| Tech window | 7 frames after throw connects | Defender presses Throw to escape |
| Tech result | Both push apart, no damage | |
| Damage | 120–150 (fixed, no scaling) | |
| Stun damage | 100–150 (fixed) | |
| Air throw | Not universal — character-specific | Chun-Li may have air throw |
| Command throws | Grappler-only (Zangief 360/720) | Cannot be teched |
| Throw vs. jump | Throw loses if opponent is pre-jump (frames 1–4) | |
| Throw vs. backdash | Throw loses if opponent backdashes in time | |
| SFX | `SFII_43 - Strong Hit.wav` (impact) | |
| VFX | None (or subtle `Effect_Impact` at reduced scale) | |

---

# 10. Stun / Dizzy

Dizzy system is enabled.

| Property | Value |
|---|---|
| Default stun health | 1000 (varies per character: 900–1100) |
| Stun recovery rate | 60 per second (paused during hitstun/blockstun) |
| Recovery pause after hit | 120 frames (2 seconds) before recovery begins |
| Dizzy duration (base) | 180 frames (3 seconds) |
| Mash reduction | Each input reduces remaining duration by 5 frames |
| VFX | `Effect_PuffAndStars` looping above head |
| Stun reset | Full reset after dizzy ends |

## Stun Damage by Attack Type

| Attack Type | Stun Damage | Notes |
|---|---|---|
| Light normal | 30–50 | Low stun, but fast |
| Medium normal | 60–80 | |
| Heavy normal | 100–130 | High stun reward |
| Special move | 80–150 | Varies by move |
| Super | 0 | Supers do not add stun |
| Throw | 100–150 | Fixed, no scaling |

Competitive tuning:
- High-stun combos should be dangerous but not automatic death
- Stun should reward sustained pressure across multiple exchanges
- Perfect block reduces incoming stun by **50%**; parry negates stun entirely

---

# 11. Super System

Every character always has access to their supers. No selectable Super Art restriction.

## Meter Properties

| Property | Value |
|---|---|
| Max bars | 3 (300 units, 100 per bar) |
| EX move cost | 1 bar (100 units) |
| Level 1 super cost | 1 bar |
| Level 2 super cost | 2 bars |
| Level 3 super cost | 3 bars (cinematic finish) |
| Meter carry between rounds | No (resets to 0) |

## Meter Gain Sources

| Action | Meter Gained | Notes |
|---|---|---|
| Normal hit | +3–8 | Scales by strength |
| Special hit | +8–12 | |
| Super hit | +0 | No meter on super |
| Being hit | +5–10 | Comeback mechanic |
| Being blocked | +2–4 | Small attacker reward |
| Blocking | +1–2 | Small defender reward |
| Perfect block | +5 | Defensive reward |
| Parry | +10 | High-skill reward |
| Whiffed attack | +1 | Minimal |

## Super Tier Targets (per character, eventually)

| Tier | Cost | Properties | VFX |
|---|---|---|---|
| Level 1 | 1 bar | Fast, combo-ender | `Effect_Kabooms` |
| Level 2 | 2 bars | Higher damage, longer animation | `Effect_Kabooms` + `Effect_Explosion` |
| Level 3 | 3 bars | Cinematic, maximum damage, invincible startup | `Effect_Kabooms` + `Effect_Explosion2` + screen flash |

For Phase 1: **one super per character** is acceptable. Add Level 2/3 after core engine is stable.

---

# 12. Universal Mechanics

Do not implement all universal mechanics at once. Build in priority order:

| Priority | Mechanic | Input | VFX | SFX | Milestone |
|---|---|---|---|---|---|
| 1 | **Dash** | →→ | `Effect_Hyperspeed` (trail) | `SFII_53` (landing) | M1 |
| 2 | **Backdash** | ←← | `Effect_Hyperspeed` (trail) | `SFII_53` (landing) | M1 |
| 3 | **Throws** | Throw button | `Effect_Impact` (light) | `SFII_43` | M3 |
| 4 | **Parry** | LT / L2 | `Effect_Anima` | Custom parry SFX | M5 |
| 5 | **Perfect Block** | Block with timing | `Effect_Constellation` | Pitched `SFII_51` | M5 |
| 6 | **Supers** | 236236+P/K (etc.) | `Effect_Kabooms` | `super_activate` | M4 |
| 7 | **EX Moves** | Special + 2 buttons | Flash tint on character | Pitched special SFX | M4 |
| 8 | **Guard Cancel** | →+HP+HK while blocking | `Effect_EldenRing` | `SFII_40` | M6 |
| 9 | **Universal Overhead** | MP+MK | `Effect_Impact` | `SFII_39` | M6 |
| 10 | **Stun/Dizzy** | Passive (accumulates) | `Effect_PuffAndStars` | Dizzy SFX | M6 |
| 11 | **Taunt Buffs** | Select/View button | `Effect_PowerChords` | Character voice | M10 |
| 12 | **Roll** | LP+LK (optional) | `Effect_Hyperspeed` | `SFII_53` | Phase 2 |
| 13 | **Short Hop** | Tap ↑ briefly (optional) | None | `SFII_53` | Phase 2 |

---

# 13. Character Design Direction

The roster uses supplied assets. Do not redesign characters yet.

## Character Data Profile Schema

Each character requires a JSON data profile with the following fields:

| Field | Type | Example (Ryu) |
|---|---|---|
| `id` | string | `"ryu"` |
| `display_name` | string | `"Ryu"` |
| `archetype` | string | `"balanced_shoto"` |
| `sprite_source` | string | `"SNES - Super Street Fighter II…Ryu.gif"` |
| `sprite_format` | enum | `"gif_sheet"` or `"pre_cut_frames"` |
| `health` | int | `1000` |
| `stun` | int | `1000` |
| `walk_speed` | float | `180` |
| `back_walk_speed` | float | `130` |
| `jump_velocity` | float | `-620` |
| `gravity_override` | float / null | `null` (use global) |
| `weight` | enum | `"medium"` |
| `dash_distance` | float | `120` |
| `backdash_distance` | float | `100` |
| `backdash_invuln` | int (frames) | `8` |
| `air_dash` | bool | `true` |
| `double_jump` | bool | `true` |
| `air_throw` | bool | `false` |
| `moves` | string[] | `["ryu_st_lp", "ryu_hadouken", …]` |
| `ko_sfx` | string | `"SFII_67 - KO Male.wav"` |
| `rival` | string | `"ken"` |
| `arcade_ending` | string | `"endings/ryu.txt"` |

## Phase 1 Character Roles

### Ryu — `SNES - Super Street Fighter II…Ryu.gif`

| Property | Value |
|---|---|
| Role | Balanced shoto |
| Purpose | Baseline system test — all mechanics validated against Ryu first |
| Walk Speed | 180 px/s |
| Back Walk | 130 px/s |
| Health | 1000 |
| Stun | 1000 |
| Weight | Medium |

Core moves:
- Hadouken (236+P) — VFX: `Effect_DitheredFire`, SFX: `SFII_69`
- Shoryuken (623+P) — VFX: `Effect_BigHit` on contact, SFX: `SFII_70`
- Tatsumaki (214+K) — VFX: `Effect_Wheel`, SFX: `SFII_71`
- Super: Shinku Hadouken (236236+P, 1 bar) — VFX: `Effect_Kabooms`, SFX: `SFII_69` pitched

### Ken — `SNES - Super Street Fighter II…Ken.gif`

| Property | Value |
|---|---|
| Role | Rushdown shoto |
| Purpose | Animation reuse test, balance contrast vs Ryu |
| Walk Speed | 195 px/s |
| Back Walk | 125 px/s |
| Health | 1000 |
| Stun | 950 |
| Weight | Medium |

Core moves:
- Hadouken (236+P) — slower recovery than Ryu's, same SFX
- Shoryuken (623+P) — multi-hit, fire VFX: `Effect_FastPixelFire`, SFX: `SFII_70`
- Tatsumaki (214+K) — more horizontal travel than Ryu's
- Super: Shoryu Reppa (236236+P, 1 bar) — VFX: `Effect_FastPixelFire` + `Effect_Kabooms`

### Guile — `SNES - Super Street Fighter II…Guile.gif`

| Property | Value |
|---|---|
| Role | Charge zoner |
| Purpose | Charge input system validation |
| Walk Speed | 165 px/s |
| Back Walk | 140 px/s |
| Health | 1050 |
| Stun | 1000 |
| Weight | Medium-Heavy |

Core moves:
- Sonic Boom (charge ← then →+P) — VFX: `Effect_DitheredFire` (tinted blue), SFX: `SFII_65`
- Flash Kick (charge ↓ then ↑+K) — VFX: `Effect_BigHit`, SFX: `SFII_63`
- Strong defensive normals (cr.MK, st.HP)
- Super: Sonic Hurricane (charge ←→←→+P, 1 bar)

### Chun-Li — `SNES - Super Street Fighter II…Chun-Li.gif`

| Property | Value |
|---|---|
| Role | Fast footsie / mobility |
| Purpose | Speed, multi-hit, air movement validation |
| Walk Speed | 210 px/s |
| Back Walk | 145 px/s |
| Health | 950 |
| Stun | 900 |
| Weight | Light |

Core moves:
- Kikoken (236+P) — VFX: `Effect_DitheredFire` (tinted blue), SFX: `SFII_57`
- Spinning Bird Kick (charge ↓ then ↑+K) — VFX: `Effect_Wheel`, SFX: `SFII_56`
- Lightning Legs (rapid K) — multi-hit, SFX: `SFII_57` rapid
- Hyakuretsukyaku / air mobility — fastest air dash in roster
- Super: Senretsukyaku (charge ←→←→+K, 1 bar) — VFX: `Effect_Kabooms`

---

# 14. Stage Design

Initial stage count: 3 real stages.

Stages are visual only. No hazards.

Each stage needs:

- display name
- background image/layers
- music assignment
- floor Y position
- left wall boundary
- right wall boundary
- camera bounds
- fighter spawn positions
- optional foreground layer
- optional crowd animation later

## Stage Candidates (Phase 1 — with concrete asset paths)

### Tournament Day — `stages/SNES - Dragon Ball Z…Tournament (Day).png`

| Property | Value |
|---|---|
| Use | Debug, training, competitive testing |
| Music | `Music/DavidKBD - Electric Pulse - 03 - Cyber Lights-full.ogg` |
| Floor Y | Calibrate from sprite bottom edge |
| Mood | Bright, clean, neutral |

### Noh Stage — `stages/SNES - Teenage Mutant Ninja Turtles…Noh Stage.png`

| Property | Value |
|---|---|
| Use | Arcade/story mode, dramatic presentation |
| Music | `Music/DavidKBD - Electric Pulse - 04 - Retrochrome Nights-full.ogg` |
| Floor Y | Calibrate from sprite bottom edge |
| Mood | Traditional, atmospheric |

### Temple Night — `stages/SNES - Dragon Ball Z…Temple (Night).png`

| Property | Value |
|---|---|
| Use | Boss fights, story climax, darker matches |
| Music | `Music/DavidKBD - Electric Pulse - 05 - Neon Arcadia Awakening-full.ogg` |
| Floor Y | Calibrate from sprite bottom edge |
| Mood | Dark, dramatic, foreboding |

---

# 15. Modes

## Versus Mode
Local 1v1. Announcer: `Fighting Announcer Voices/Versus....wav`

| Setting | Options | Default |
|---|---|---|
| Rounds to win | 1 / 2 / 3 | 2 |
| Round timer | 30 / 60 / 90 / 99 / ∞ | 99 |
| Chip KO | ON / OFF | OFF |
| Control mode | Classic / Modern (per player) | Classic |
| Stage select | Any unlocked stage | Random |
| Controller assignment | P1 / P2 auto-detect | First input |

Flow: Main Menu → Character Select (`Select your Fighter!`) → Stage Select (`Stage Select`) → VS Screen (`Versus....wav`) → Fight → Results → Rematch / Return

## Training Mode
Must be built early — **Milestone 7 is critical path**.

| Feature | Input Icons | Notes |
|---|---|---|
| Input display | `fighting-game-icons/basic_directions/` + button glyphs | Left side P1, right side P2 |
| Hitbox overlay | Toggle key (F2) | Pushbox=green, Hurtbox=blue, Hitbox=red |
| Frame data display | Real-time | Startup / Active / Recovery / Advantage |
| Damage readout | On-hit | Raw damage, scaled damage, stun damage |
| Combo counter | On-hit | Hit count + total damage + stun |
| Command list | Overlay (F3) | Uses `fighting-game-icons/motions_with_d_pad/` + `hit_flags/` |
| Dummy block | Stand / Crouch / All / After First Hit / Random | |
| Dummy parry | Off / All / Random | |
| Dummy state | Stand / Crouch / Jump / Walk / CPU | |
| Meter settings | Normal / Infinite / Empty / Refill | |
| Health settings | Normal / Infinite / Refill | |
| Position reset | Hotkey (Select / F1) | |
| Record/Playback | Phase 2 feature | |

## CPU Battle
Single match against AI.

| AI Phase | Implementation | Milestone |
|---|---|---|
| Phase 1 | Random movement + random attacks | M10 |
| Phase 2 | Scripted decision trees (anti-air, punish, block) | M10 |
| Phase 3 | 5 difficulty levels (reaction time, combo depth) | M10+ |
| Phase 4 | Character-specific AI (zoning for Guile, rushdown for Ken) | Phase 2 |

## Arcade Mode
Classic arcade ladder. Announcer: `Fighting Announcer Voices/Challenge....wav`

| Round | Opponent | Stage | Notes |
|---|---|---|---|
| 1 | Random from roster | Random | Warm-up |
| 2 | Random from roster | Random | |
| 3 | Random from roster | Random | |
| 4 | **Rival** | Rival's stage | Pre-fight dialogue |
| 5 | **Boss** (placeholder) | Temple Night | `10 - Synthetic Power Surge.ogg` |
| End | Ending card | — | Character-specific text |

## Story Mode
Lightweight until combat is stable.

Phase 1 structure per character:
1. Intro text + character art
2. 3 standard fights
3. Rival intro dialogue → Rival fight
4. Boss intro dialogue → Boss fight
5. Ending text + win quote
6. Credits roll with `08 - Quantum Ripples of Sound.ogg`

## Combo Trials
Character-specific missions. 5 trials per fighter (Phase 1):

| Trial | Example (Ryu) | Difficulty |
|---|---|---|
| 1 | st.LP → st.LP → st.LP | Basic chain |
| 2 | cr.MK → Hadouken (236+P) | Special cancel |
| 3 | j.HK → st.MP → cr.MK → Hadouken | Jump-in combo |
| 4 | Parry → st.HP → Shoryuken (623+HP) | Parry punish |
| 5 | cr.MK → Hadouken → Super (236236+P) | Super cancel |

## Tutorial Mode
Teach systems progressively. Use Training Mode stage with guided prompts.

| Lesson | Topic | Unlock |
|---|---|---|
| 1 | Movement (walk, crouch, jump, dash) | Default |
| 2 | Blocking (stand, crouch, air) | After L1 |
| 3 | Throwing and throw tech | After L2 |
| 4 | Parry timing and risk/reward | After L3 |
| 5 | Perfect block timing | After L4 |
| 6 | Special move inputs (236, 623, charge) | After L5 |
| 7 | Supers and meter management | After L6 |
| 8 | Combo structure and damage scaling | After L7 |
| 9 | Stun system and dizzy | After L8 |
| 10 | Classic vs Modern control comparison | After L9 |

---

# 16. HUD / UI

HUD should include all combat-critical information. Reference assets: `TurboGrafx-16…HUD and UI.png` for bar layout, `Neo Geo…Timer Sprites.png` for timer digits, `Wii U…Enemy Health Bars.png` for premium bar styling.

## HUD Element Specifications

| Element | Position | Asset Reference | Notes |
|---|---|---|---|
| P1 Health Bar | Top-left | `TurboGrafx-16…HUD and UI.png` | Drains right-to-left |
| P2 Health Bar | Top-right | `TurboGrafx-16…HUD and UI.png` | Drains left-to-right |
| Timer | Top-center | `Neo Geo…Timer Sprites.png` | 99-count, flashes at 10 |
| P1 Name | Above P1 health | System font / custom | Character display name |
| P2 Name | Above P2 health | System font / custom | Character display name |
| Round markers | Below health bars | `TurboGrafx-16…HUD and UI.png` | Circles: empty → filled on win |
| P1 Super Meter | Bottom-left | Custom 3-segment bar | Glows per segment filled |
| P2 Super Meter | Bottom-right | Custom 3-segment bar | |
| P1 Stun Meter | Under P1 health | Thin bar | Flashes when near threshold |
| P2 Stun Meter | Under P2 health | Thin bar | |
| Combo Counter | Center-screen | Large text popup | "N Hits!" with damage total |
| KO Text | Center-screen | Animated banner | `Effect_Explosion2` background |
| Round Banner | Center-screen | Animated text | "Round 1… FIGHT!" sequence |

## HUD Layout Diagram

```text
┌─────────────────────────────────────────────┐
│ [P1 NAME]          [TIMER]       [P2 NAME]  │
│ ████████████████▒▒  :99:  ▒▒████████████████│
│ [stun]  ○ ○ ●              ● ○ ○  [stun]   │
│                                             │
│                  5 HITS!                    │
│                  1247 DMG                   │
│                                             │
│                                             │
│ [P1 SUPER ███▒▒▒]          [▒▒▒███ P2 SUPER]│
└─────────────────────────────────────────────┘
```

## Training Overlay (additive layer on top of fight HUD)

| Element | Position | Notes |
|---|---|---|
| P1 Input History | Left edge, vertical stack | Last 20 inputs using `fighting-game-icons/` |
| P2 Input History | Right edge, vertical stack | Mirror of P1 |
| Damage Readout | Below combo counter | Raw / Scaled / Stun |
| Frame Data | Top-right corner | Startup / Active / Recovery / Advantage |
| Hitbox Toggle Status | Top-left corner | Shows current overlay mode |
| Dummy Settings | Bottom-center | Current dummy block/state/parry config |

---

# 17. Audio Design

Two complete SFX libraries are supplied. Map every game event to a concrete WAV file.

## Audio Mapping Table (SFII Turbo SFX → Game Events)

| Game Event ID | Source File | Notes |
|---|---|---|
| `normal_whiff_light` | `04/SFII_38 - Light Attack.wav` | |
| `normal_whiff_medium` | `04/SFII_39 - Medium Attack.wav` | |
| `normal_whiff_heavy` | `04/SFII_40 - Hard Attack1.wav` | Alt: `SFII_41` |
| `hit_jab` | `04/SFII_42 - Jab Hit.wav` | Light punch connect |
| `hit_strong` | `04/SFII_43 - Strong Hit.wav` | Medium punch connect |
| `hit_fierce` | `04/SFII_44 - Fierce Hit.wav` | Heavy punch connect |
| `hit_short` | `04/SFII_45 - Short Hit.wav` | Light kick connect |
| `hit_forward` | `04/SFII_46 - Forward Hit.wav` | Medium kick connect |
| `hit_roundhouse` | `04/SFII_47 - Roundhouse Hit.wav` | Heavy kick connect |
| `block` | `04/SFII_51 - Blocked.wav` | |
| `landing` | `04/SFII_53 - Landing.wav` | |
| `knockdown` | `04/SFII_52 - Hit the ground.wav` | |
| `projectile_fire` | `04/SFII_50 - On fire.wav` | Fireball launch |
| `electricity` | `04/SFII_49 - Blanka Electricity.wav` | Electric specials |
| `claw_bite` | `04/SFII_48 - Claw & Bite.wav` | Vega/beast attacks |
| `ko_male` | `05/SFII_67 - KO Male.wav` | Default male KO |
| `ko_female` | `05/SFII_68 - KO Chun-Li.wav` | Female KO |
| `announcer_fight` | `02/SFII_17 - Fight!.wav` | Round start |
| `announcer_round` | `02/SFII_18 - Round.wav` | + `SFII_19`/`20`/`22` |
| `announcer_final` | `02/SFII_21 - Final.wav` | Final round |
| `announcer_you_win` | `02/SFII_14 - You win!.wav` | |
| `announcer_you_lose` | `02/SFII_15 - You lose.wav` | |
| `announcer_perfect` | `02/SFII_16 - Perfect.wav` | |

## Extended Announcer Mapping (Fighting Announcer Voices pack)

| Game Event ID | Source File |
|---|---|
| `announcer_fight_alt` | `Fighting Announcer Voices/Fight!.wav` |
| `announcer_ko` | `Fighting Announcer Voices/Knock Out!.wav` |
| `announcer_double_ko` | `Fighting Announcer Voices/Double KO.wav` |
| `announcer_time_over` | `Fighting Announcer Voices/Time Over!.wav` |
| `announcer_perfect` | `Fighting Announcer Voices/Perfect!.wav` |
| `announcer_select_fighter` | `Fighting Announcer Voices/Select your Fighter!.wav` |
| `announcer_stage_select` | `Fighting Announcer Voices/Stage Select.wav` |
| `announcer_game_over` | `Fighting Announcer Voices/Game Over!.wav` |
| `announcer_continue` | `Fighting Announcer Voices/Continue.wav` |
| `announcer_get_ready` | `Fighting Announcer Voices/Get Ready!.wav` |
| `announcer_excellent` | `Fighting Announcer Voices/Excellent!.wav` |
| `announcer_victory` | `Fighting Announcer Voices/Victory!.wav` |
| `announcer_countdown_N` | `Fighting Announcer Voices/N_countdown.wav` (0–9) |
| `announcer_round_N` | `Fighting Announcer Voices/nN.wav` (n1–n10) |

## Character Voice Mapping

| Character | Event | Source File |
|---|---|---|
| Ryu / Ken | Hadouken | `05/SFII_69 - RyuKen Hadouken.wav` |
| Ryu / Ken | Shoryuken | `05/SFII_70 - RyuKen Shoryuken.wav` |
| Ryu / Ken | Tatsumaki | `05/SFII_71 - RyuKen Tatsumaki Senpuukyaku.wav` |
| Guile | Sonic Boom | `05/SFII_65 - Guile Sonic Boom.wav` |
| Chun-Li | Laugh (win) | `05/SFII_55 - Chun-Li Laugh.wav` |
| Chun-Li | Spinning Bird | `05/SFII_56 - Chun-Li Spinning Bird Kick.wav` |
| Chun-Li | Attack voice | `05/SFII_57 - Chun-Li Ya.wav` |
| Chun-Li | Victory | `05/SFII_58 - Chun-Li Yatta.wav` |
| Dhalsim | Yoga | `05/SFII_59 - Dhalsim Yoga.wav` |
| Dhalsim | Yoga Fire | `05/SFII_60 - Dhalsim Yoga Fire.wav` |
| E. Honda | Dosukoi | `05/SFII_62 - EHonda Dosukoi.wav` |
| Generic | Grunt 1 | `05/SFII_63 - Grunt1.wav` |
| Generic | Grunt 2 | `05/SFII_64 - Grunt2.wav` |

## Music Assignment

All tracks are OGG format from `Music/`. Assign by stage/screen:

| Screen / Stage | Track |
|---|---|
| Title / Main Menu | `01 - Electric Pulse-full.ogg` |
| Character Select | `02 - Digital Horizon-full.ogg` |
| Tournament Day | `03 - Cyber Lights-full.ogg` |
| Noh Stage | `04 - Retrochrome Nights-full.ogg` |
| Temple Night / Boss | `05 - Neon Arcadia Awakening-full.ogg` |
| Pit II / Back Alley | `06 - Time Warp-full.ogg` |
| Victory / Results | `07 - Electric Dreams of Infinity-full.ogg` |
| Credits / Ending | `08 - Quantum Ripples of Sound-full.ogg` |
| Sound Beach / Alt | `09 - Vapor Trails Pursuit-full.ogg` |
| Final Boss / Climax | `10 - Synthetic Power Surge-full.ogg` |

---

# 18. VFX Design

All VFX in `VFX/` are supplied as individual PNG frames in `30fps/` and `60fps/` subdirectories, plus a `.smp` metadata file. Use the 60fps variants for gameplay; 30fps for menus or low-performance fallback.

VFX **must** be spawned by move data, not hardcoded.

## VFX → Game Event Mapping

| Game Event | VFX Folder | Spawn Rule |
|---|---|---|
| Light-attack hit | `Effect_SmallHit` | On hitbox contact, at contact point |
| Medium-attack hit | `Effect_Impact` | On hitbox contact, at contact point |
| Heavy-attack hit | `Effect_BigHit` | On hitbox contact, at contact point |
| Parry success | `Effect_Anima` | Centered on defender, brief freeze |
| Perfect block | `Effect_Constellation` | Centered on defender |
| Guard cancel / alpha counter | `Effect_EldenRing` | Centered on defender |
| Block spark | `Effect_SmallHit` (tinted) | At contact point, reduced scale |
| Hadouken / fire projectile | `Effect_DitheredFire` | Attached to projectile node |
| Ken fire effects | `Effect_FastPixelFire` | Attached to active hitbox |
| Electric special | `Effect_ElectricShield` | Looping on character during active |
| Super charge startup | `Effect_Charged` | Centered on character, pre-super |
| Super impact | `Effect_Kabooms` | At contact point on super connect |
| Projectile clash | `Effect_Explosion` | At collision midpoint |
| KO finish | `Effect_Explosion2` | Centered on loser |
| Dash / speed trail | `Effect_Hyperspeed` | Trailing behind character |
| Command grab / vortex | `Effect_TheVortex` | Centered on opponent |
| Grapple connect | `Effect_Tentacles` | At grab point |
| Dizzy state | `Effect_PuffAndStars` | Looping above character head |
| Taunt / buff activate | `Effect_PowerChords` | Centered on character |
| Spinning special | `Effect_Wheel` | Attached to character during spin |
| Projectile trail variant | `Effect_Worm` | Trailing behind projectile |
| Magma / super variant | `Effect_Magma` | Stage-level or character-level |
| Blood impact (toggle) | `Effect_BloodImpact` | At contact point if setting ON |

## VFX Data Schema (per effect)

```json
{
  "id": "small_hit",
  "folder": "VFX/Effect_SmallHit/60fps/",
  "frame_count": 8,
  "fps": 60,
  "loop": false,
  "scale": 1.0,
  "tint": null,
  "z_order": 10
}
```

---

# 19. Data-Driven Structure

The project should be data-driven. Do not hardcode individual character moves into the controller script.

## Recommended Folder Structure

```text
res://
  scenes/
    boot/
    menu/
    fight/
    ui/
    training/

  scripts/
    core/
    input/
    fight/
    data/
    ui/
    audio/
    vfx/

  data/
    fighters/
      ryu.json
      ken.json
      guile.json
      chun_li.json
      shin_akuma.json          # Phase 2
      magician_red.json        # Phase 2 crossover

    moves/
      ryu_moves.json
      ken_moves.json
      guile_moves.json
      chun_li_moves.json

    stages/
      tournament_day.json
      noh_stage.json
      temple_night.json

    input/
      xbox_default.json
      playstation_default.json
      switch_default.json
      keyboard_default.json
      generic_controller_default.json

    vfx/
      hit_sparks.json
      fire_effects.json
      electric_effects.json

    audio/
      sfx_map.json             # Maps event IDs → WAV paths
      music_map.json           # Maps stage IDs → OGG paths
      announcer_map.json       # Maps announcer events → WAV paths

  assets/
    raw/                       # Original supplied files, untouched
    processed/
      fighters/
        ryu/                   # Sliced frames from GIF sheet
        ken/
        guile/
        chun_li/
        shin_akuma/            # Already pre-cut (789 PNGs)
        magician_red/          # Already pre-cut (878 PNGs)
      stages/
      ui/
      vfx/                     # Copied from VFX/Effect_*/60fps/
      audio/
        sfx/
        music/
        announcer/
```

## Sprite Pipeline Notes

Two asset formats exist and require different import pipelines:

### GIF Sheet Characters (Ryu, Ken, Guile, Chun-Li, SSF2 roster)
1. Import the GIF as a `SpriteFrames` resource or use an external tool to slice into individual PNGs
2. Define animation regions per action (idle, walk, crouch, jump, attacks, etc.)
3. Store frame rects in the fighter JSON
4. Use `AnimatedSprite2D` with frame regions

### Pre-Cut Frame Characters (Shin Akuma — 789 PNGs, MagicianRed — 878 PNGs)
1. Frames are already individual PNGs with sequential numbering
2. Create a frame-map JSON that assigns index ranges to animation states
3. Load via `SpriteFrames.add_frame()` from the numbered sequence
4. Example mapping:
```json
{
  "idle": { "start": 0, "end": 15, "fps": 12, "loop": true },
  "walk_forward": { "start": 16, "end": 33, "fps": 12, "loop": true },
  "st_lp": { "start": 34, "end": 40, "fps": 15, "loop": false }
}
```

## Fighter Data Example

```json
{
  "id": "ryu",
  "display_name": "Ryu",
  "archetype": "balanced_shoto",
  "health": 1000,
  "stun": 1000,
  "walk_speed": 180,
  "back_walk_speed": 130,
  "jump_velocity": -620,
  "dash_distance": 120,
  "backdash_distance": 100,
  "air_dash": true,
  "double_jump": true,
  "moves": [
    "ryu_st_lp",
    "ryu_st_mp",
    "ryu_st_hp",
    "ryu_cr_mk",
    "ryu_hadouken",
    "ryu_shoryuken",
    "ryu_tatsumaki",
    "ryu_super_1"
  ]
}
```

## Move Data Example

```json
{
  "id": "ryu_hadouken",
  "display_name": "Hadouken",
  "input_classic": "236+punch",
  "input_modern": "special+punch",
  "type": "special",
  "startup": 14,
  "active": 0,
  "recovery": 32,
  "damage": 60,
  "stun_damage": 80,
  "chip_damage": 12,
  "meter_gain": 8,
  "projectile": "hadouken_projectile",
  "sound": "ryuken_hadouken",
  "vfx": "fire_projectile_spawn",
  "cancel_from": ["normal_cancelable"]
}
```

---

# 20. Godot 4 Implementation Plan

## Core Scripts

```text
InputDeviceManager.gd
PlayerInputRouter.gd
InputBuffer.gd
MotionParser.gd
ChargeInputTracker.gd
FighterController.gd
FighterStateMachine.gd
FighterData.gd
MoveData.gd
Hitbox.gd
Hurtbox.gd
Pushbox.gd
Projectile.gd
RoundManager.gd
FightCamera.gd
TrainingManager.gd
HUDController.gd
AudioManager.gd
VFXSpawner.gd
```

## Core Scenes

```text
Boot.tscn
MainMenu.tscn
CharacterSelect.tscn
StageSelect.tscn
FightScene.tscn
TrainingScene.tscn
FightHUD.tscn
CommandList.tscn
InputDisplay.tscn
ButtonRemapMenu.tscn
```

---

# 21. Development Roadmap

## Milestone 0: Asset Intake & Pipeline

- [ ] Organize supplied assets into `raw/` and `processed/` folders
- [ ] Rename files to consistent snake_case scheme
- [ ] Slice GIF sheets into individual PNG frames per animation
- [ ] Copy pre-cut Shin Akuma / MagicianRed PNGs into processed pipeline
- [ ] Define `fighter_manifest.json`, `stage_manifest.json`, `audio_manifest.json`, `vfx_manifest.json`
- [ ] Create `sfx_map.json` and `announcer_map.json` mapping event IDs → WAV paths
- [ ] Create `music_map.json` mapping stage/screen IDs → OGG paths
- [ ] **Acceptance:** All assets loadable from Godot, manifests validate with no missing refs

## Milestone 1: Combat Sandbox

- [ ] Load Tournament Day stage background
- [ ] Spawn Ryu and Ken with idle animation
- [ ] Move left/right, jump, crouch
- [ ] Auto-face opponent
- [ ] Camera follows fighters with proper bounds
- [ ] Basic health bars rendering (prototype HUD)
- [ ] **Acceptance:** Two characters walk, jump, crouch on stage with camera tracking

## Milestone 2: Animation & State Machine

- [ ] Implement `FighterStateMachine.gd` with states: Idle, Walk, Crouch, Jump, Block, Hitstun, Knockdown, GetUp, KO, Victory
- [ ] Load all animation states from fighter JSON
- [ ] State transitions driven by input + game events
- [ ] **Acceptance:** Full state cycle observable in training — every state visually distinct

## Milestone 3: Hit Detection & Combat Feel

- [ ] Implement Pushbox, Hurtbox, Hitbox collision layers
- [ ] Active-frame-based hit detection
- [ ] Hitstop (freeze frames on connect)
- [ ] Hitstun / blockstun with proper duration
- [ ] Pushback on hit and block
- [ ] Combo counter tracking
- [ ] Damage scaling (100% → 90% → 80% → 70% → 60% floor)
- [ ] **Acceptance:** Ryu cr.MK → Hadouken combo registers as 2-hit, scaled damage

## Milestone 4: Specials & Projectiles

- [ ] Hadouken projectile with collision, VFX (`Effect_DitheredFire`), SFX (`SFII_69`)
- [ ] Shoryuken invincible startup, anti-air, VFX (`Effect_BigHit`), SFX (`SFII_70`)
- [ ] Tatsumaki with movement arc, VFX (`Effect_Wheel`), SFX (`SFII_71`)
- [ ] Projectile-vs-projectile clash with `Effect_Explosion`
- [ ] EX-move variant framework (spend 1 bar)
- [ ] **Acceptance:** All Ryu/Ken specials functional with correct VFX/SFX

## Milestone 5: Defensive Systems

- [ ] Standing / crouching block (hold back)
- [ ] Air block with increased blockstun
- [ ] Perfect block (3–5 frame window) → `Effect_Constellation` + unique SFX
- [ ] Parry button (5 frame active, 18 frame whiff) → `Effect_Anima` + freeze
- [ ] Throw button (3–5 frame startup, 7–10 frame tech window)
- [ ] Chip damage with KO toggle setting
- [ ] **Acceptance:** All defensive options distinguishable in training with visual/audio feedback

## Milestone 6: HUD & Round Flow

- [ ] Full HUD: health bars, timer, round counter, super meter, stun meter, combo counter
- [ ] Round start sequence: announcer “Round N… Fight!” with banners
- [ ] Timer countdown with announcer voice at low time
- [ ] KO detection → slowdown → win announcement
- [ ] Win markers (best of 3)
- [ ] Round reset and match end flow
- [ ] **Acceptance:** Complete 3-round match playable from start to victory screen

## Milestone 7: Training Mode

- [ ] Input display (using `fighting-game-icons/` direction + button art)
- [ ] Hitbox/hurtbox/pushbox overlay toggle
- [ ] Real-time damage, stun, and frame-data readout
- [ ] Dummy settings: stand, crouch, jump, block all, block after first hit, random
- [ ] Command list overlay (using `fighting-game-icons/motions_with_d_pad/`)
- [ ] Position/meter/health reset hotkey
- [ ] **Acceptance:** Developer can verify any move's startup/active/recovery with visual overlay

## Milestone 8: Add Guile & Chun-Li

- [ ] Charge input logic (`ChargeInputTracker.gd`)
- [ ] Guile: Sonic Boom (`SFII_65`), Flash Kick, defensive normals
- [ ] Chun-Li: Kikoken, Spinning Bird Kick (`SFII_56`), Lightning Legs, air mobility
- [ ] Balance pass across 4-character roster
- [ ] **Acceptance:** All 4 fighters playable with distinct feel

## Milestone 9: Menus & Presentation

- [ ] Title screen with music (`01 - Electric Pulse`)
- [ ] Character select with portraits and announcer (`Select your Fighter!`)
- [ ] Stage select with thumbnails and announcer (`Stage Select`)
- [ ] Controls/settings menu with button remap
- [ ] Controller glyph resolution (Xbox/PS/Switch/Keyboard icons)
- [ ] **Acceptance:** Full menu → match → results → menu loop functional

## Milestone 10: Arcade / Story / CPU

- [ ] CPU AI (basic → scripted → difficulty levels)
- [ ] Arcade ladder: 4 fights → rival → boss placeholder
- [ ] Story mode shell: intro → rival intro → boss intro → ending card
- [ ] Win quotes and ending text
- [ ] Combo trials per character (5 trials each)
- [ ] Tutorial mode (movement → blocking → parry → specials → combos)
- [ ] **Acceptance:** Arcade mode completable with ending screen

## Milestone 11 (Phase 2): Roster Expansion

- [ ] Integrate Shin Akuma (789 pre-cut frames) as secret/boss character
- [ ] Integrate MagicianRed (878 pre-cut frames) as crossover guest
- [ ] Add remaining SSF2 roster as data allows
- [ ] Expand stage pool to 6–10 stages
- [ ] Boss AI for Shin Akuma
- [ ] **Acceptance:** 6+ character roster with balanced matchups

---

# 22. Key Design Warnings

> [!WARNING]
> These are the most common failure modes for fan-game fighting projects. Each warning links to the relevant section.

### ⛔ Do Not Add the Full Roster First
The full roster should wait until Ryu/Ken/Guile/Chun-Li are working (see **§3 Phase 1 Roster**). Adding 20 characters before the engine is stable will bury the project in animation and hitbox work. The supplied 16 SSF2 sheets + 2 pre-cut sets will still be there after the engine proves out.

### ⛔ Do Not Hardcode Character Logic
Everything — moves, frame data, hitboxes, VFX, SFX — must reference JSON data files (see **§19 Data-Driven Structure**). Zero character-specific `if` branches in `FighterController.gd`.

### ⛔ Do Not Overpower Air Mobility
Air dash + double jump + air block can destroy grounded neutral if tuned badly (see **§7 Movement Balance Rules**). Enforce the air-action economy: one air action per jump, 5-frame air-dash startup, 8-frame landing recovery, 1.3× air blockstun.

### ⛔ Do Not Skip Training Mode
Training mode is not optional — it is the fastest way to debug a serious fighter (see **§15 Training Mode** and **Milestone 7**). Ship training before arcade.

### ⛔ Do Not Treat Parry and Perfect Block as the Same
They serve different risk/reward tiers (see **§6 Defensive Mechanics**). Perfect block: safe, small reward. Parry: risky, large reward. If both feel identical, one is redundant.

### ⛔ Do Not Ignore Asset Pipeline Differences
GIF sheets (SSF2 roster) and pre-cut PNGs (Shin Akuma, MagicianRed) require different import pipelines (see **§19 Sprite Pipeline Notes**). Build both pipelines in Milestone 0 before touching character logic.

---

# 23. Final Direction

The correct first build target is:

```text
Street Fighter — DocRoshi Remix v0.1
Private Fan Prototype
Godot 4.x (GDScript)
Ryu vs Ken
Tournament Day stage (SNES DBZ Tournament Day.png)
Six-button controls (Xbox / PS / Switch / Keyboard)
Classic + Modern control modes
Parry button (Effect_Anima VFX)
Perfect block (Effect_Constellation VFX)
Throws with tech window
Basic combos with damage scaling
Full HUD (TurboGrafx-16 HUD sheet + KOF Timer Sprites)
Music (DavidKBD Electric Pulse OST)
Combat SFX (SFII Turbo Sounds library)
Announcer (Fighting Announcer Voices pack)
Hit sparks (Effect_SmallHit / Impact / BigHit)
Training debug overlay with input display
```

After that works, add:

```text
Guile (charge input system)
Chun-Li (speed/multi-hit system)
3-stage select (Tournament Day, Noh Stage, Temple Night)
CPU battle with basic AI
Arcade ladder (4 fights + rival + boss)
Story shell (text-based intro/outro)
Combo trials (5 per character)
Tutorial mode (movement → blocking → specials → combos)
```

Phase 2 expansion:

```text
Shin Akuma (789 pre-cut frames — secret boss)
MagicianRed (878 pre-cut frames — crossover guest)
Zangief / M. Bison / Sagat / Blanka
6–10 stage rotation
Expanded arcade/story content
Online netcode (rollback, future milestone)
```

Only after Phase 2 is stable should the project expand into the full crossover roster using SF III, SFA3, MvC, SamSho, and KOF assets.
