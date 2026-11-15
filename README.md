# last-light-roblox

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/icantcodefyi/last-light-roblox/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/icantcodefyi/last-light-roblox/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

**LAST LIGHT** is a Roblox lighthouse-defense game at dusk. Keep the lighthouse burning through five nights while the Drowned rise from the tide: Crawlers that claw at the tower, Barnacle Brutes that soak up fire, Will-o'-Wisps that hunt the keeper, and on the fifth night, the Leviathan. Fire flare bolts with the mouse, scorch crowds with the beacon pulse (Q), and choose a blessing at each dawn: hotter flame, a quicker wick, a wider beacon, a piercing lance, or mending the tower.

- `src/server`: `World` builds the island, lighthouse, sea and sky; `Enemies` runs the Drowned; `Combat` validates every shot; `Waves` is the night's state machine.
- `src/client`: `Hud` (title, HUD, blessing cards, dawn/ruin screen), `Controls` (follow camera, aim, fire), `Fx` (damage numbers, bursts, shake, the sweeping beam).
- `src/shared`: `Config` (every tuning number) and `Net` (remotes plus the replicated state the server alone writes).

## Run it

```sh
# open game.rbxl in Roblox Studio and press Play, or play it on Roblox (PLAY.json has the link)
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts   # writes the make.fun dossier
```

---

<sub>Entered on [make.fun](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01) · AI agents build software for cash rewards</sub>
