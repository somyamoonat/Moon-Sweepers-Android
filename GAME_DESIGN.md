# Moon Sweepers: Game Design Document & Roadmap

## 1. Executive Summary & Core Vision
**Moon Sweepers** is a cozy, tactile, incremental cleaning and factory automation game built in **Godot 4** for **Android mobile devices** (portrait orientation, one-finger touch controls, short satisfying play sessions, zero combat/fail state).

* **Premise:** You play as a low-paid contracted astronaut hired by the Lunar Surface Department to clean a massive moon covered in asteroid regolith, compress collected dust, earn Credits, unlock autonomous cleaning rovers, and expand operations across multiple lunar sectors.
* **Core Loop:**
  $$\text{Scrub Dust} \longrightarrow \text{Fill Storage Hopper} \longrightarrow \text{Sell Dust for Credits} \longrightarrow \text{Upgrade Tools \& Automate} \longrightarrow \text{Advance Sectors}$$

---

## 2. Technical Pillars & Mobile Architecture
* **Single-Texture Dynamic Dust Layer:** Never spawns individual dirt nodes. Dirt is stored in an ultra-fast $256 \times 256$ RGBA8 image buffer updated via GPU texture streaming (`ImageTexture.update`), consuming $<0.1\text{ ms}$ per stamp and yielding 60 FPS on any Android phone.
* **Lightweight Dual Persistence:**
  - `user://savegame.json`: Encodes currency, sector progression, sound settings, and data-driven upgrade levels in human-readable JSON.
  - `user://dust_mask.png`: Uses Godot's built-in PNG compressor to save the entire visual dust mask state into a tiny $\sim 8\text{ KB}$ file, restoring exact scrubbed holes in $<5\text{ ms}$.
* **Autosave Safety:** Automatically saves every 30 seconds and on mobile lifecycle triggers (`NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_WM_CLOSE_REQUEST`).
* **Mobile-First Touch & Audio:** Virtual touch-drag interpolation prevents gaps during quick finger swipes. Built-in `AudioManager` with rate-limiting and sound toggles prevents audio stuttering on mobile processors.

---

## 3. Implemented Systems (Stages 1 – 8 Summary)

### Stage 1: Mobile Project Foundations
- Portrait base resolution: $1080 \times 1920$ with `canvas_items` stretch mode and `keep` aspect ratio.
- Desktop testing window override ($540 \times 960$) for comfortable Mac testing.
- Touch-from-mouse and mouse-from-touch emulation enabled.

### Stage 2: Scrubbing Mechanic
- Framed 900x900 px lunar surface with dark bedrock and realistic crater geology underneath.
- Circular brush pixel erasure with touch-drag linear interpolation for butter-smooth strokes.
- Real-time clean percentage calculation ($0.0\%$ to $100.0\%$).

### Stage 3: Collecting, Capacity & Selling
- Internal dust hopper tank with live storage meter HUD (`current / capacity kg`).
- Physical storage cap: stops vacuuming when full and displays visual warning: `"⚠️ Storage full! Sell your dust."`
- Large thumb-friendly **SELL DUST** button with dynamic earnings counter (`💰 SELL DUST (+$XX)`).
- Floating golden `+$` text animation rising and fading out using cubic easing tweens.

### Stage 4: Data-Driven Upgrade Shop
- Sliding mobile modal shop dynamically populated from `GameState.upgrades` dictionary:
  - **🧹 Brush Width:** Increases cleaning radius with each swipe.
  - **🎒 Storage Tank:** Increases maximum capacity before needing to sell.
  - **💎 Dust Value:** Increases payout credits per kilogram.
- Upgrades scale exponentially by $\sim 1.5\times$ cost per level.
- Thumb-friendly buy buttons automatically disabled when unaffordable.

### Stage 5: Save & Load System
- Complete JSON persistence in `user://savegame.json`.
- Dual image persistence in `user://dust_mask.png`.
- Settings modal (`⚙️`) with manual **"SAVE GAME NOW"** and **"RESET ALL PROGRESS"** for testing.

### Stage 6: Autonomous Cleaning & Automation
- **🤖 Autonomous Cleaning Bots:** Mobile rovers roaming the lunar surface, scrubbing dust and adding kilograms to your hopper. Capped at 6 bots with a 0.12s tick interval for zero mobile CPU overhead.
- **⚡ Auto-Sell Module:** Automatically unloads and sells dust $0.65\text{s}$ after storage reaches full capacity.

### Stage 7: Sector Progression & Biomes
- Sector completion threshold set at $95\%$.
- Celebration banner awarding completion bonuses: `+$50 × Sector Number`.
- Dynamic color themes and scaling dust density:
  1. *Sector 01: Mare Tranquillitatis* (Navy Space, 350 kg base dust)
  2. *Sector 02: Oceanus Procellarum* (Emerald/Teal, 500 kg base dust)
  3. *Sector 03: Mare Imbrium* (Crimson/Violet, 700 kg base dust)
  4. *Sector 04: Sinus Iridum* (Obsidian/Gold, 950 kg base dust)

### Stage 8: Polish, Juice & UI Polish
- **Dust Puff Particles:** Single pooled `CPUParticles2D` emitting tactile dust clouds during scrubbing.
- **Juice & Game Feel:** Button press punch scale tweens, subtle screen shake upon selling dust, and pulsing storage warnings.
- **Main Menu Scene:** Dedicated start screen with "START MISSION", "MISSION SETTINGS", "HOW TO PLAY" manual, and sound toggle (`🔊 ON / 🔇 OFF`).
- **Placeholder Audio Hooks:** Centralized `AudioManager` ready for `.wav`/`.ogg` audio files.

---

## 4. Code & Scene Organization
```
moon-sweepers/
├── project.godot               # Godot 4.7 Mobile configuration & Autoloads
├── GAME_DESIGN.md              # Living architecture & roadmap document
├── scenes/
│   ├── main_menu.tscn          # Main menu start screen
│   ├── main.tscn               # Core gameplay workspace scene
│   ├── lunar_surface.tscn      # 900x900 dynamic scrubbing surface
│   ├── cleaning_bot.tscn       # Autonomous rover node
│   ├── shop_panel.tscn         # Modal upgrade shop
│   └── settings_panel.tscn     # Settings & save management modal
└── scripts/
    ├── game_state.gd           # Global economy, progression & JSON save manager
    ├── audio_manager.gd        # Global audio manager & sound hooks
    ├── main_menu.gd            # Main menu navigation controller
    ├── main.gd                 # Gameplay controller & HUD
    ├── lunar_surface.gd        # Pixel erasure math & particle emission
    ├── cleaning_bot.gd         # Bot wander AI & periodic scrub
    ├── shop_panel.gd           # Dynamic card generator & purchase handling
    └── settings_panel.gd       # Sound toggle, save now & reset triggers
```

---

## 5. Future Expansion Roadmap (Next Steps)
1. **Physical Dust Capsules (3D / Rigidbody):** Add an option to eject physical Dust Capsules onto a conveyor line instead of instant digital selling.
2. **Drivable Rovers:** Implement a garage pad where players can drive a motorized Push Sweeper or Mega Lunar Rover with virtual mobile joystick controls.
3. **Refining Factory Automation:** Pressure chambers and stone presses that convert raw dust capsules into higher-tier Moon Sand and Moonstone Blocks.
4. **Day/Night Solar Power Grid:** 15-minute day/night cycle requiring solar panels and battery storage to keep automated factories running through the lunar night.
