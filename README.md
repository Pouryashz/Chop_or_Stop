# Chop_or_Stop
Asymmetric 1v1 steam-train chase for 1899, built in Godot 4. The Conductor keeps the train rolling by felling trees and loading wood, while the Bandit chases it down and tries to make it stop. 2D gameplay with 3D toon-shaded characters and 2D scenery.


# Cordwood Express

> Keep the train rolling, or make it stop.

*Cordwood Express* is a 1v1 asymmetric chase game set in 1899. A steam train has to cross the map, but its fuel won't last the trip. One player is the **Conductor**, who rides a hand-pumped trolley ahead of the train, fells trees, hauls wood back and feeds the boiler. The other is the **Bandit**, who rides alongside the track, closes the gap whenever the train slows, and tries to stop it long enough to loot it.

If the train stops, the Bandit catches up. Every run is 15 to 25 minutes on a newly generated route.

## Features

- **Asymmetric 1v1 multiplayer.** Conductor versus Bandit, with code written for N players so 2v2 is possible.
- **Boiler-driven train.** Fuel burn, pressure, engine force and drag drive the train's speed, so wood is the clock of every match.
- **Tree-cutting loop.** Choose which side to cut, watch the tree fall with pendulum-then-rigid-body physics, and collect the pre-cut trunk segments.
- **Sabotage and traps.** The Bandit can place logs on the rails, board the train, and steal fuel. Ropes and winches are simulated with PBD/Verlet.
- **Procedural routes.** Each run is assembled from segments across biomes (forest, desert, snow) with different wood types and rules.
- **Bandit bot.** Play solo or test without a second player.
- **Cartoon, non-lethal tone.** Steam blasts, ropes and tripping, never gore.

## Tech

- **Engine:** Godot 4 (MIT licence, no fees or royalties)
- **Gameplay:** all gameplay and physics run in 2D, side view
- **Rendering:** 3D toon-shaded train and characters with outlines, 2D sprite scenery on multiple depth layers with parallax, and one shared palette and outline shader for both
- **Train simulation:** a 1D object on a spline (`v += (engineForce(pressure) - drag - slope) * dt`) rather than engine physics
- **Smoke and steam:** a low-resolution stable-fluid grid rendered as a texture over the scene
- **Networking:** Godot high-level multiplayer. The server owns the train, player and tree state, while ropes and smoke run locally as cosmetic effects

## Getting started

1. Install [Godot 4](https://godotengine.org/).
2. Clone this repo and open `project.godot` in the editor.
3. Press **F5** to run.

## Controls

*(fill in once finalised)*

## Credits

Built by **Pourya Shahbazzadeh** (gameplay, characters, art, levels, multiplayer lobby) and **Jeanne** (simulation, rendering, procedural generation, Bandit bot, audio).

## Licence

*(choose one, e.g. MIT for code, CC-BY for art)*
