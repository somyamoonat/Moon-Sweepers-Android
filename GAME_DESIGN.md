# Moon Sweepers: Game Design Document & Roadmap

## 1. Executive Summary & Core Vision
**Moon Sweepers** is a cozy, tactile, incremental cleaning and factory automation game tailored for Android mobile devices in Godot 4.

* **Premise:** You play as a contracted lunar cleaner for the Lunar Surface Department. Your assignment: clean the dust-choked surface of the Moon, compress the collected asteroid regolith into transportable Dust Capsules, sell them for credits, and build an automated cleaning and refining empire to clean 100% of the lunar surface.
* **Core Loop:** 
  1. **Scrub & Clean:** Walk or sweep across dirty lunar hex sectors.
  2. **Collect & Compress:** Accumulate raw dust in your suit hopper, then compress it into physical **Dust Capsules**.
  3. **Deliver & Sell:** Bring capsules to the Depot to earn Lunar Credits.
  4. **Upgrade & Automate:** Buy wider brooms, faster thrusters, rovers, autonomous robot vacuums, and refinery conveyor lines.
  5. **Expand:** Clean sectors to 100%, unlock new sectors on the global holographic map, and scale your operations.
* **Tone & Atmosphere:** Relaxing, low-stress, zero-combat, floaty low-gravity physics, and high visual satisfaction comparing dusty grey ground with dark, sparkling clean lunar bedrock.

---

## 2. Technical Pillars & Mobile Optimization
Because this game targets mobile phones (Android), performance and battery life are prioritized from day one:
* **No Node Bloat for Dirt:** We will **never** spawn thousands of individual nodes or physics colliders for dust particles. Instead, terrain dirt is represented via lightweight grid cells or a dynamic dirt mask texture / shader canvas.
* **Mobile Viewport & Controls:** Designed for comfortable one-thumb or two-thumb mobile interaction (portrait orientation, virtual floating joystick, auto-sweep toggle, single-tap capsule compression).
* **Chunk-Based Hex Sectors:** Only active, nearby sectors compute high-detail sweeping; inactive distant sectors render simplified states.
* **Lightweight Jolt Physics:** Using Godot 4's Jolt Physics engine for smooth low-gravity simulation of capsules and vehicles.
* **Object Pooling:** Dust particles, dropped capsules, and floating text reuse pre-allocated pools to prevent Android garbage collection hitching.

---

## 3. Game Systems Breakdown

### A. Mobile Controls & Player Mechanics
* **Locomotion:** Low-gravity lunar physics, floaty jumps, and an upgradeable jetpack for hovering.
* **One-Finger / Two-Finger Touch:**
  * **Movement:** Floating virtual thumbstick on the left.
  * **Camera & Actions:** Drag to pan view, tap **Auto-Sweep** to vacuum/sweep continuously without holding, **Angle Lock** to sweep in straight lines, and **Compress Capsule** when hopper is full.
* **Dual View:** First-person view for precision cleaning; third-person view for vehicle driving and base building.

### B. Terrain & Dirt System (Hex Grid)
* The Moon is divided into hexagonal sectors.
* Each sector tracks its cleanliness percentage:
  * **Orange:** Untouched (0% cleaned).
  * **Blue:** In-progress (1% – 97% cleaned).
  * **Green:** Completed (≥98% clean auto-snaps to 100%, triggering a celebration banner and credit bonus).

### C. Economy & Progression Trees
* **Manual Tools:**
  1. *Toothbrush* (Free starter: narrow strip, slow speed).
  2. *Nail Brush* ($15: modest upgrade).
  3. *Push Broom* ($50: wide cleaning arc).
  4. *Wide Industrial Broom* ($150: wide arc + sweep movement speed boost).
* **Suit & Tank Upgrades:**
  * Walking speed & jetpack hover fuel.
  * Hopper tank capacity (e.g., 10 kg -> 25 kg -> 100 kg before needing capsule compression).
  * Market contracts (+% payout per capsule).
* **Vehicles:**
  * *Push Sweeper* ($300): Motorized walk-behind unit with 100 kg hopper.
  * *Ride-On Sweeper* ($1,200): Fast mobile buggy with 500 kg hopper.
  * *Mega Lunar Rover* ($6,000): Heavy 6-wheeler with front roller and auto capsule dispenser.
* **Automation & Refineries:**
  * *Robot Vacuums (Mk I & Mk II):* Roam nearby dirty hexes, sweep regolith, and return to dock.
  * *Pressure Chamber:* Compresses raw capsules into higher-value Moon Sand.
  * *Stone Press & Crusher:* Converts refined sand into Moonstone Blocks and Refined Lunar Cores.
  * *Solar Power Grid:* Solar panels and battery banks powering factory equipment through the lunar day/night cycle.

---

## 4. Development Roadmap

### Stage 1: Project Setup & Architecture Foundations
* Establish clean directory layout: `/scenes`, `/scripts`, `/assets` (placeholder primitives).
* Configure Godot project settings for Android portrait orientation, stretch mode, and input emulation (emulate touch from mouse).
* Create a foundational test scene with low-gravity physics, simple ground plane, and mobile-friendly camera.
* Verify project runs smoothly with zero errors.

### Stage 2: Mobile Touch & Scrubbing Mechanic
* Build the player character with low-gravity movement and smooth camera controls.
* Implement mobile touch interface: virtual floating joystick, auto-sweep toggle, and touch drag.
* Build the performance-friendly dirt grid / masking system (no node bloat; cell-based sweeping).
* Add visual contrast showing dirty terrain turning into clean lunar surface under the sweeper.

### Stage 3: Collecting, Hopper Tank & Selling
* Implement the internal dust hopper with capacity meter HUD.
* Add capsule compression: spending accumulated dust to produce a physical **Dust Capsule** item.
* Create the **Depot** drop-off zone.
* Deliver capsules to the Depot to earn Lunar Credits with satisfying audio-visual floating text feedback.

### Stage 4: In-Game Upgrade Shop
* Create a mobile-friendly slide-over / modal Shop UI.
* Add upgrade paths:
  * Brush upgrades (Toothbrush -> Nail Brush -> Push Broom -> Industrial Broom).
  * Suit speed and hopper capacity upgrades.
* Hook up currency transactions with instant stat feedback.

### Stage 5: Save & Load System (Local Persistence)
* Implement a robust JSON-based save/load manager in `user://savegame.json`.
* Persist player credits, owned tools, upgrade tiers, and cleaned hex sectors.
* Add auto-saving every 60 seconds and on application pause/exit (essential for mobile lifecycle).

### Stage 6: Autonomous Cleaning Bots
* Build the **Robot Vacuum Mk I** node with simple pathfinding / state machine:
  * Roams within designated sector boundaries.
  * Sweeps dirt into internal tank.
  * Returns to the docking station / Depot to unload when full.
* Allow player to purchase and place bots from the base terminal.

### Stage 7: Multiple Moon Sectors & Sector Completion
* Implement the Hex Sector grid logic.
* Track individual sector cleanliness percentage.
* Trigger "SECTOR COMPLETE!" banner, sound effect, and bonus payout when reaching ≥98%.
* Global minimap overlay showing sector states: Orange (Untouched), Blue (In-Progress), Green (Cleaned).

### Stage 8: Polish, Balance & Android Build Preparation
* Visual juice: particle effects for dust sweeping, bouncy capsule physics, day/night lighting.
* Object pooling for dust particles and floating text.
* Performance profiling on mobile renderer (FPS lock, power consumption).
* Android export configuration and final check.

---

## 5. Code & Project Standards
* **Scripts:** All GDScript files strictly inside `res://scripts/`.
* **Scenes:** All scenes strictly inside `res://scenes/`.
* **Naming:** `snake_case` for files and variables, `PascalCase` for node classes.
* **Runnable State:** Every incremental step must compile and run without runtime exceptions.
* **Version Control:** Clear, descriptive Git commits after every verified step pushed to `Moon-Sweepers-Android`.
