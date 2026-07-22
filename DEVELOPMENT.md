# Development Roadmap

## 🎯 Project Vision

A playable Warhammer 40K 4th Edition tabletop simulator with:
- ✅ Accurate WH40K 4th ed rules implementation
- ✅ 3D minimalist graphics (not AAA-level, but clean)
- ✅ Single-player campaigns and scenarios
- ✅ Embedded rule reference system
- ✅ Army roster and unit management

---

## 📋 Development Phases

### Phase 1: Core Systems ✅ COMPLETE
- [x] Project scaffold with Godot 4.0
- [x] Game manager and turn system
- [x] Unit and Squad classes with full stats
- [x] Army management system
- [x] Combat system (to-hit, to-wound, armor saves)
- [x] Rules engine with comprehensive WH40K 4th ed rules
- [x] Grid-based board system (2" squares, 48"x48")
- [x] Main scene structure

**Deliverables:**
- GameManager.gd - Core game loop control
- Unit.gd - Individual model with stats
- Squad.gd - Squad-level operations
- Army.gd - Army-level management
- CombatSystem.gd - Full combat resolution
- RulesEngine.gd - 30+ embedded rules
- Board.gd - Grid positioning system
- main.tscn - Game entry point

---

### Phase 2: Basic Game Loop & Combat 🔄 IN PROGRESS

#### 2.1 Combat Resolution UI
- [ ] Combat log/console for attack resolution
- [ ] Dice roll visualization (3D dice rolling)
- [ ] Attack result display (hits/wounds/saves)
- [ ] Casualty removal animation

#### 2.2 Unit Selection & Interaction
- [ ] Unit selection interface
- [ ] Squad highlighting
- [ ] Movement preview (show movement range)
- [ ] Target selection for shooting/melee

#### 2.3 Game Loop Integration
- [ ] Wire GameManager to player input
- [ ] Turn phase buttons (End Shooting, End Assault, End Turn)
- [ ] Implement AI for enemy turns
- [ ] Victory/defeat detection

#### 2.4 HUD/UI Layer
- [ ] Current turn display
- [ ] Active army/squad display
- [ ] Unit stats panel
- [ ] Dice roll history
- [ ] Rules reference sidebar

**Estimated Tasks:** 8 features
**Time Estimate:** 2-3 weeks

---

### Phase 3: 3D Visualization & Graphics

#### 3.1 Unit Models
- [ ] Simple cube/pyramid unit placeholders
- [ ] Color coding by faction
- [ ] Squad indicator (grouping visualization)
- [ ] Damage indicators (color shift on wounds)
- [ ] Animation on death/removal

#### 3.2 Board Visualization
- [ ] Terrain placement (ruins, rocks)
- [ ] Grid overlay toggle
- [ ] Board edge markers
- [ ] Deployment zone visualization
- [ ] Light/shadow effects

#### 3.3 Camera & Controls
- [ ] Orthographic board view
- [ ] Zoom in/out
- [ ] Pan camera
- [ ] Unit tracking camera
- [ ] 3D perspective option

#### 3.4 Visual Effects
- [ ] Muzzle flash on shooting
- [ ] Damage hit effect
- [ ] Melee combat animation
- [ ] Smoke/dust effects
- [ ] Blood splash (optional)

**Estimated Tasks:** 10 features
**Time Estimate:** 3-4 weeks

---

### Phase 4: Scenarios & Campaign

#### 4.1 Scenario System
- [ ] Scenario loader from JSON/markdown
- [ ] Deployment rules parser
- [ ] Victory condition checker
- [ ] Terrain initialization
- [ ] Pre-game setup UI

#### 4.2 Tutorial Scenario
- [ ] Load "First Blood" scenario
- [ ] AI opponent (basic)
- [ ] Tutorial hints/tooltips
- [ ] Victory/defeat screens
- [ ] Replay option

#### 4.3 Additional Scenarios
- [ ] Annihilation (kill all enemies)
- [ ] Capture the Relic
- [ ] Secure Objectives
- [ ] Dawn of War (reserve deployment)

#### 4.4 Campaign Framework
- [ ] Campaign progression system
- [ ] Unit carry-over between battles
- [ ] Damage/experience tracking
- [ ] Campaign victory conditions
- [ ] Narrative text/briefings

**Estimated Tasks:** 8 features
**Time Estimate:** 2-3 weeks

---

### Phase 5: Army Building & Customization

#### 5.1 Army Builder
- [ ] Unit creation interface
- [ ] Squad builder
- [ ] Points calculator
- [ ] Army list export/save
- [ ] Load pre-built armies

#### 5.2 Roster Management
- [ ] Unit database (Space Marines, Orks, etc.)
- [ ] Equipment selection
- [ ] Weapon loadouts
- [ ] Special rules assignment
- [ ] Character upgrades

#### 5.3 Save/Load System
- [ ] Serialize army to JSON
- [ ] Serialize game state
- [ ] Load campaigns
- [ ] Auto-save on turn end
- [ ] Multiple save slots

**Estimated Tasks:** 6 features
**Time Estimate:** 2 weeks

---

### Phase 6: Polish & Performance

#### 6.1 Performance Optimization
- [ ] Render optimization
- [ ] Memory profiling
- [ ] Load time reduction
- [ ] Frame rate stabilization (target 60 FPS)

#### 6.2 Audio
- [ ] Background music
- [ ] Dice roll sound
- [ ] Weapon fire sounds
- [ ] Melee impact sounds
- [ ] UI click sounds

#### 6.3 UI/UX Polish
- [ ] Improved visual design
- [ ] Better fonts and layout
- [ ] Accessibility features
- [ ] Keyboard shortcuts
- [ ] Settings menu

#### 6.4 Bug Fixes & Testing
- [ ] Combat system testing
- [ ] Morale check validation
- [ ] UI responsiveness
- [ ] Cross-platform testing

**Estimated Tasks:** 8 features
**Time Estimate:** 2-3 weeks

---

## 🏗️ Architecture Overview

```
Main Scene (main.tscn)
│
├─ GameManager (Node)
│  ├─ current_turn, current_round
│  ├─ player_army, enemy_army
│  ├─ Signals: turn_started, turn_ended, game_ended
│  └─ Methods: start_turn(), end_turn(), check_victory()
│
├─ Board (Node3D)
│  ├─ Grid positioning (120x120 inches, 2" squares)
│  ├─ Unit placement tracking
│  └─ Distance calculations
│
├─ CombatSystem (Node)
│  ├─ resolve_attack(attacker, defender)
│  ├─ roll_to_hit(), roll_to_wound()
│  ├─ roll_armor_saves()
│  └─ Signals: attack_resolved, saving_throw_resolved
│
├─ RulesEngine (Node)
│  ├─ rules_database (30+ rules)
│  ├─ search_rules(query)
│  └─ get_rule_by_stat(stat)
│
├─ UI Layer (TBD)
│  ├─ HUD elements
│  ├─ Combat log
│  └─ Rule reference sidebar
│
└─ Armies
   ├─ Player Army (Army)
   │  └─ Squads (Squad)
   │     └─ Units (Unit)
   └─ Enemy Army (Army)
      └─ Squads (Squad)
         └─ Units (Unit)
```

## 📊 Class Hierarchy

```
Node (GameManager) - Core game control
Node (CombatSystem) - Combat resolution
Node (RulesEngine) - Rule database

Node3D (Board) - 3D battlefield
Node3D (Army) - Army container
  └─ Node3D (Squad) - Squad container
     └─ Node3D (Unit) - Individual model

Control (UI elements) - TBD
```

## 🎮 Game Flow

```
START
  ↓
Load Scenario
  ↓
Deploy Armies
  ↓
Start Round Loop
  ├─ Player Movement Phase
  ├─ Player Shooting Phase
  ├─ Player Assault Phase
  ├─ AI Movement Phase
  ├─ AI Shooting Phase
  ├─ AI Assault Phase
  ├─ Check Victory
  └─ Next Round?
      ├─ YES → Start Round Loop
      └─ NO → Game End
  ↓
Show Results
  ↓
END
```

## 🔧 Current Sprint: Phase 2.1 - Combat Resolution UI

### Next Immediate Tasks
1. Create combat log display UI
2. Implement attack resolution display
3. Add dice roll visualization
4. Create casualty removal animation
5. Build unit selection interface
6. Add movement preview system

### Code Quality
- Document all public methods
- Add signal documentation
- Include usage examples
- Maintain consistent naming

## 📝 Notes

### Design Decisions
- **GDScript**: Native to Godot, Python-like syntax, perfect for beginners
- **Grid-Based**: 2" squares matches WH40K base sizes exactly
- **Embedded Rules**: Searchable dictionary system for quick reference
- **Modular Architecture**: Each system (combat, units, rules) is independent

### Future Considerations
- Multiplayer networking (Phase 7+)
- Advanced AI opponent
- More factions (currently just Space Marines/Orks)
- Expanded points list
- Competitive balance tweaking
- Community feedback integration

### Known Limitations
- AI is basic (placeholder)
- Graphics are minimal (intentional)
- Limited to 4th edition (can expand)
- No multiplayer yet
- Campaign is framework only
