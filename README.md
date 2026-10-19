<p align="center">
  <img src="docs/media/logo.png" width="112" alt="NoSpace: Arena logo">
</p>

<h1 align="center">NoSpace: Arena</h1>
<p align="center"><strong>Draw a line. Take the void.</strong></p>
<p align="center">A mobile arcade game where the territory you capture becomes part of your defense.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Godot-4.6.3-478CBF?style=for-the-badge&amp;logo=godotengine&amp;logoColor=white" alt="Godot 4.6.3">
  <img src="https://img.shields.io/badge/GDScript-Typed-00BFA5?style=for-the-badge" alt="Typed GDScript">
  <img src="https://img.shields.io/badge/Status-In_Development-A78BFA?style=for-the-badge" alt="In Development">
</p>

---

## 🎮 Gameplay

<p align="center">
  <a href="docs/media/gameplay.gif"><img src="docs/media/gameplay.gif" width="360" alt="Real gameplay: move along the boundary, enter the field, draw a line, and reconnect to capture territory while an enemy moves"></a>
</p>

<p align="center"><strong>Move along the boundary → enter the void → close your line → claim territory.</strong></p>

Inspired by **Qix** and **Volfied**, every cut is a risk: enemies can reach your exposed line before you reconnect. Captured ground changes the fight through your character's territory effect.

<p align="center">
  <a href="docs/media/main-menu.png"><img src="docs/media/main-menu.png" width="220" alt="English Main Menu with Play, Store, Missions, Leaderboard, and How to Play"></a>
  <a href="docs/media/gameplay.png"><img src="docs/media/gameplay.png" width="220" alt="English gameplay HUD and a freshly captured region"></a>
  <a href="docs/media/modes.png"><img src="docs/media/modes.png" width="220" alt="English Mode Select with four modes and three pre-run boosts"></a>
</p>
<p align="center"><sub>Main Menu · Territory capture · Mode Select<br>Actual Godot gameplay and English UI captures. Select any image to view it at full size.</sub></p>

---

## ✨ Features

| Feature | In the game |
|:--|:--|
| **Living Territory** | Pulse, Drag, and Halt give captured ground distinct defensive effects. |
| **Daily challenge & personal bests** | Date-based arena selection, local best scores, and a replay of your own best-run ghost. |
| **Progression & rewards** | Campaign stars, rotating missions, coins, daily login rewards, and Supply gifts. |
| **Your loadout** | Three arenas, unlockable characters, and Extra Life, Coin Bonus, and Slow Start boosts. |
| **Made for portrait play** | Swipe, tap-to-turn, and D-pad controls; responsive layouts, safe areas, and 18 UI languages. |

## 🕹️ Game Modes

| Mode | The challenge |
|:--|:--|
| **Daily** | A date-based challenge with personal best/ghost tracking. Boosts are disabled. |
| **Free** | Play a single arena with your selected character and arena. |
| **Endless** | Clear successive arenas as enemy pressure and capture targets increase. |
| **Campaign** | Take on 12 authored stages and earn up to three stars per stage. |

---

## 🛠️ Tech Stack

Built with **Godot 4.6.3** and **statically typed GDScript**. Procedural 2D visuals, Godot Resources for authored content, and a shared UI theme keep the presentation consistent. Core game logic is separated from rendering and covered by **GUT** tests.

## 🚧 Development Status

**Playable prototype · Android development builds · Not yet released**

- **Implemented:** the core capture loop, territory effects, four modes, progression, rewards, and multilingual UI.
- **Currently validating:** the UI on physical Android devices. iOS export and device testing are still pending.
- **Planned for v1.1:** roguelite drafting.

English, Turkish, German, French, Spanish, Brazilian Portuguese, Italian, Japanese, Korean,
Simplified Chinese, Traditional Chinese, Russian, Indonesian, Vietnamese, Polish, Hindi, Thai, and Arabic are supported.
New translations await native-speaker review; physical Android acceptance is pending.

Daily scores and ghosts are stored **on the device**. Online rankings and a server-synced Daily clock are not implemented.

---

<p align="center">
  Created by <strong>Tuğra Hekimoğlu</strong><br>
  Public for portfolio and reference purposes · <strong>All rights reserved</strong><br>
  Written permission is required for use, copying, modification, or distribution.<br>
  <a href="LICENSE">License</a> · <a href="docs/credits.md">Third-party credits</a>
</p>
