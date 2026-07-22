# Development Roadmap - Phase 3 Complete ✅

## 🎯 Project Status

| Phase | Status | Tasks | Files |
|-------|--------|-------|-------|
| Phase 1 | ✅ Complete | 8/8 | 8 scripts |
| Phase 2 | ✅ Complete | 8/8 | 7 scripts |
| Phase 3 | ✅ Complete | 7/7 | 7 scripts |
| Phase 4+ | ⏳ Next | - | - |

---

## ✨ Phase 3: Graphics & Camera Controls ✅ COMPLETE

### New Systems Deployed

#### 3.1 Camera Controller ✅
- **CameraController.gd**
  - Orthographic top-down view (perfect for tabletop)
  - Mouse wheel zoom (30-150 range)
  - Middle mouse drag to pan
  - Optional unit following
  - Camera position/zoom reset

#### 3.2 Unit Selection & Interaction ✅
- **UnitSelector.gd**
  - Left-click to select units
  - Raycast-based selection
  - Shows unit stats in combat log
  - Hover detection
  - Integration with movement preview

#### 3.3 Terrain & Environment ✅
- **Terrain.gd**
  - Central ruins (heavy cover, 4+ save)
  - Scattered rock formations (light cover, 6+ save)
  - Optional grid overlay
  - Collision shapes for blocking
  - Cover metadata system

#### 3.4 Visual Feedback ✅
- **MovementPreview.gd**
  - Green overlay showing movement range
  - Red overlay for shooting range
  - Dynamic cell visualization
  - Clear/refresh on selection

- **HealthBar.gd**
  - 3D labels with unit names above each unit
  - Health bars color-coded green→red
  - Auto-updates on damage
  - Auto-removes on death

#### 3.5 Animations ✅
- **UnitAnimator.gd**
  - Smooth movement animations (linear tween)
  - Attack jab animation (backward easing)
  - Recoil effect on damage (sine wave shake)
  - Charge animation (quadratic easing)
  - Non-blocking animation queue

#### 3.6 Integration ✅
- **Updated Unit.gd**
  - Adds animator component automatically
  - Adds health bar component automatically
  - Recoil animation on taking damage
  - Cleaner initialization

- **Updated GameLoop.gd**
  - Instantiates all Phase 3 systems
  - Wires camera, selector, terrain, preview
  - Shows movement range on selection
  - Passes game_loop reference to selector
  - Adds helpful controls hint to combat log

---

## 🎮 Phase 3 Features Now Available

### Camera Controls
```
Scroll Up/Down     → Zoom in/out
Middle Mouse Drag  → Pan camera
Click Unit         → Select and show range
```

### Visual Indicators
```
Green Overlay   → Movement range
Red Overlay     → Shooting range
Health Bars     → Unit status (green→red)
Unit Labels     → Names above units
Central Ruins   → Heavy cover (4+ save)
Rock Patches    → Light cover (6+ save)
```

### Animations
```
Movement  → Smooth linear tween
Attack    → Quick jab motion
Damage    → Recoil shake effect
Charge    → Fast forward acceleration
Death     → Fade out + rise (from Phase 2)
```

---

## 📊 Complete Game Architecture

```
Main.tscn
│
├─ GameManager (State machine)
│
├─ Board (3D grid positioning)
│
└─ GameLoop (Master Orchestrator) ✨ NOW WITH PHASE 3
   ├─ CombatSystem (Combat resolution)
   ├─ RulesEngine (Rule database)
   ├─ AIBrain (Enemy AI)
   ├─ CameraController (Camera system) ✨ NEW
   ├─ UnitSelector (Unit interaction) ✨ NEW
   ├─ Terrain (Board environment) ✨ NEW
   ├─ MovementPreview (Range display) ✨ NEW
   │
   ├─ UI Layer (CanvasLayer)
   │  ├─ GameHUD (Top panel)
   │  ├─ CombatLog (Left panel)
   │  └─ RulesReference (Right sidebar)
   │
   ├─ Player Army
   │  └─ Squad Alpha
   │     └─ Units (with Visuals + HealthBar + Animator)
   │
   └─ Enemy Army
      └─ Squad (Boyz)
         └─ Units (with Visuals + HealthBar + Animator)
```

---

## 🚀 What You Can Do Now

1. **Click units** on the board to select them
2. **See green range** showing where unit can move
3. **Zoom in/out** with mouse wheel to focus
4. **Pan camera** by middle-clicking and dragging
5. **See health bars** above each unit (green→red)
6. **Watch animations** as units take damage
7. **View terrain** with ruins and rocks for cover
8. **Hover units** to see which unit you're about to select
9. **Read unit stats** when selected in the combat log
10. **Play full game** with all visual feedback

---

## 📝 Phase 3 Implementation Details

### Camera System
- Orthographic projection (ideal for tabletop view)
- Position at (0, 100, 0) looking straight down
- Size starts at 80 (zoom level)
- Min zoom: 30 (zoomed in)
- Max zoom: 150 (zoomed out)
- Pan speed: 50 units/second

### Unit Selection
- Raycast from camera through mouse position
- Finds first colliding Unit node
- Displays stats: Name, WS, BS, S, T, W
- Shows movement range preview
- Deselect on click elsewhere

### Movement Preview
- Gets unit position from board grid
- Shows all cells within movement range
- Creates semi-transparent green boxes
- Clears when deselected
- Can also show shooting range (red)

### Health Bars
- 3D Label above unit at +1.5 height
- Simple box mesh as health indicator
- Color transitions: Green (full) → Red (dead)
- Updates automatically on damage
- Destroyed when unit dies

### Animations
- Non-blocking (don't prevent other actions)
- Use Tweens for smooth motion
- Different easing for different actions
- Recoil plays automatically on damage
- Charge plays on melee engagement

### Terrain
- Central 24x24x24 structure (ruins)
- 4 patches of 4-5 rocks each
- Rocks randomized in position/size
- Both have collision shapes
- Both have cover metadata

---

## ✅ Phase 3 Completion Checklist

- [x] CameraController fully functional
- [x] UnitSelector with raycast detection
- [x] Terrain with ruins and rocks
- [x] MovementPreview with range display
- [x] HealthBar with color gradient
- [x] UnitAnimator with multiple animations
- [x] Unit.gd updated with components
- [x] GameLoop integrates all systems
- [x] All systems communicating properly
- [x] Camera controls documented
- [x] Selection system working
- [x] Animations playing correctly

**Phase 3 Status: ✅ 100% COMPLETE**

---

## 🎯 Phase 4: Scenarios & Campaign (Design & Implementation)

Phase 4 expands the playable content beyond a single "First Blood" scenario and introduces a lightweight campaign system so players can run linked scenarios, track unit experience and damage between scenarios, and save/load campaign progress.

### Goals (high level)
- Provide multiple scenario types (skirmish, objective, assault)
- Track squad-level and unit-level progression (experience, wounds, injuries)
- Define flexible victory/lose conditions per scenario
- Add briefing/mission text and simple narrative flow
- Implement persistent save/load for campaigns (JSON-based)
- Expose in-game UI for campaign management and scenario selection

### UX / Flow
1. Player opens Campaign Screen → New Campaign / Load Campaign
2. If New: choose faction, roster (predefined or custom), and starting scenario
3. Play scenario (existing GameLoop) with ScenarioManager active
4. At scenario end: ScenarioManager evaluates victory conditions and rewards
   - Apply XP to surviving units
   - Track accumulated damage and apply injuries/wounds
   - Add campaign-level resources or story flags
5. Progress to next scenario (branching or linear) or return to campaign map
6. Save campaign state automatically and via manual save

### Core Systems to Implement
- ScenarioManager.gd
  - Loads scenario definitions (metadata + setup rules)
  - Spawns units/forces according to scenario file
  - Manages scenario-specific victory conditions and triggers
  - Emits signals: scenario_started, scenario_ended(result, summary)

- CampaignManager.gd
  - Campaign data model (roster, current_scenario_id, flags, resources)
  - Handles progression rules (which scenario unlocks next)
  - Applies post-scenario effects (XP, injuries, roster updates)
  - Interfaces with SaveLoad system

- SaveLoad.gd
  - Serialize/deserialize campaign state to disk (user://campaigns/*.json)
  - Keep versioning field for backward compatibility
  - Provide autosave and manual save APIs

- Scenario definitions (YAML/JSON)
  - id, name, description, map_scene, enemy_roster, objectives, time_limit, victory_criteria
  - Example file: res://scenarios/first_blood.json

- UI
  - CampaignScreen.tscn / CampaignScreen.gd (create/load/delete campaigns)
  - ScenarioBriefing.tscn (shows objectives, briefing text, rewards)
  - PostScenarioSummary.tscn (shows casualties, XP gained, injuries)

### Data Model (proposal)
Campaign JSON structure (example):
{
  "version": 1,
  "id": "ember_campaign_001",
  "player_faction": "Space Marines",
  "roster": [
    {
      "unit_id": "termies_1",
      "name": "Brother A",
      "type": "Terminator",
      "xp": 0,
      "wounds": 2,
      "injuries": []
    }
  ],
  "current_scenario": "first_blood",
  "completed_scenarios": ["first_blood"],
  "flags": {}
}

Save considerations:
- Save to user://campaigns/<campaign_id>.json
- Include timestamp and engine version
- Keep files reasonably small (no scene deep-dumps) — store roster and minimal unit state

### Unit Progression & Damage
- XP system: survivors gain XP based on actions (kills, objectives, assists)
- XP thresholds unlock bonuses (e.g., +1 WS at 10 XP)
- Damage persistence: track wounds, accumulated damage; when wounds exceed threshold, apply "injury" status
- Injuries can be temporary (require rest) or permanent (affect stats)
- Provide simple UI to spend XP between scenarios (level up screen)

### Victory Conditions (flexible rules)
- Destroy enemy forces (all enemy units down)
- Hold objective points for N turns
- Survive for T turns
- Retrieve item/objective on map

Scenario definition includes a small scriptable rule set (JSON fields plus optional GDScript hooks for complex cases).

### File/Code Changes (suggested)
- Add: res://managers/ScenarioManager.gd
- Add: res://managers/CampaignManager.gd
- Add: res://managers/SaveLoad.gd
- Add: res://ui/CampaignScreen.tscn + CampaignScreen.gd
- Add: res://scenarios/*.json (scenario definitions)
- Update: GameLoop.gd to optionally consult ScenarioManager when running a campaign
- Update: Unit.gd to include persistent identity (unit_id) and xp/wounds fields

### API & Signals
- ScenarioManager signals:
  - signal scenario_started(scenario_id)
  - signal scenario_ended(scenario_id, result:Dictionary)
- CampaignManager API:
  - new_campaign(definition:Dictionary)
  - load_campaign(campaign_id:String)
  - save_campaign(campaign_id:String)
  - apply_scenario_result(result:Dictionary)

### Persistence & Versioning
- Include a "version" field at top-level of saved JSON
- Migrate on load if version < current
- Back up old saves before overwriting

### Priority Checklist (Phase 4 MVP)
- [ ] ScenarioManager core (load scenario, spawn forces)
- [ ] CampaignManager (create/load/save campaign state)
- [ ] SaveLoad implementation (JSON file IO + versioning)
- [ ] Add 3 sample scenarios: first_blood.json (existing), hold_the_line.json, raid_supply.json
- [ ] UI: Campaign screen + scenario briefing + post-scenario summary
- [ ] Unit persistence: unit_id, xp, wounds, injuries
- [ ] Victory condition engine (basic types)
- [ ] Post-scenario rewards / XP assignment
- [ ] Autosave on scenario end

### Nice-to-have (Phase 4+)
- Branching scenario map (map view showing progress and choices)
- Recruit / buy new units between scenarios
- Campaign modifiers (difficulty, narrative choices)
- Cloud sync (GitHub Gist or user account) — out of scope for MVP

### Implementation Notes & Tips
- Keep scenario definitions data-driven: prefer JSON files for easy editing and modding
- Avoid serializing whole SceneTree — only store identifiers and small unit state
- Use Godot's File and JSON APIs (FileAccess.open, JSON.parse_string / to_json)
- Write unit tests for SaveLoad migration cases
- Keep signals small and descriptive to decouple GameLoop from campaign logic

---

## 🎮 To Run Your Game

```bash
1. Open Godot 4.0+
2. Open project (40k-4th-edition-simulator)
3. Press F5 to run main.tscn
4. See fully playable 3D tabletop!
```

**Now with:**
- ✨ Movable camera
- ✨ Clickable units
- ✨ Visual feedback
- ✨ Smooth animations
- ✨ Terrain
- ✨ Health indicators

Enjoy your WH40K simulator! 🎮⚔️
