# Frontier Trail Builder

A mobile idle road-logistics builder set in the 1840s–60s westward-expansion
frontier. You found towns and blaze trails between them; an autonomous workforce
gathers, hauls, builds, and trades on its own. The **trail itself is the hero
mechanic**. Cozy but strategic.

This repo is being built as a learning project — Godot and game design at the
same time — so it advances in small, self-contained "rungs," each of which runs
on its own and teaches one thing.

## Project structure

The most important rule here is the **sim / presentation split**:

- **`sim/`** — pure logic. No nodes, no rendering, no screen. Just data and the
  math/rules of the game (e.g. hex coordinates, later: pathfinding, the economy
  tick). Code here knows nothing about how anything looks.
- **`presentation/`** — everything visual. Draws the world and handles input,
  but only ever *reads* from `sim/`; it never holds game truth.
- **`data/`** — tunable constants in JSON (hex size, colors, later: road costs,
  extraction rates). Loaded at startup. Nothing tunable is hardcoded in scripts.

Why bother this early: keeping logic pure and serializable is what makes
save/load and the idle game's "offline accrual" sane later. It's painful to
retrofit, trivial to maintain from the start.

## The learning ladder

1. **Clickable hex grid** ← *you are here (rung 1)*. Render a hex board, hover a
   hex, see its axial coordinate.
2. Place two towns, draw a road between hexes, show its total cost.
3. A* pathfinding with terrain cost — watch the cheapest path bend around a
   costly mountain hex.
4. One throughput number: producer → market over a road. Re-route by hand,
   watch the number change. **This is the riskiest-assumption / is-it-fun test.**

After rung 4: minions → economy → idle/offline → progression → art (and a port
of the look to 3D; the systems stay identical thanks to the split above).

## Rung 1 — what's here

- `sim/hex_grid.gd` — pure hex math: which hexes exist, axial↔pixel conversion,
  and pixel→hex rounding. Uses **axial coordinates, pointy-top**.
- `presentation/hex_grid_view.gd` — draws the grid and highlights the hovered
  hex; reads everything from `HexGrid` and `data/constants.json`.
- `main.tscn` — the scene (set as the project's main scene).
- `data/constants.json` — hex size, grid radius, colors.

Run the project (F5). Move the mouse over the board; the hovered hex lightens
and the label top-left shows its `q, r`.

Hex reference (canonical): https://www.redblobgames.com/grids/hexagons/
