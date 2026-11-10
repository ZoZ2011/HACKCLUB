# Magicopalypse

2D pixel-art game made with Godot 4.7.

Currently: animated main menu — START / SHOP / LEVELS / QUIT hang on chains with
pendulum physics, drop in with a spring on launch, clouds drift by, corner icon
buttons (mute / settings), CC0 UI sounds, F11 fullscreen, mouse + sound settings
saved to `user://settings.cfg`.

Plus the game itself — **Canyon Defense**: START jumps into the highest unlocked
level, LEVELS opens a level select with 6 wooden plaques (locked ones show
LOCKED). Guard the canyon gate as the mage: aim with the mouse, hold to cast
magic bolts, stop the monsters before 3 hearts run out. 6 levels with escalating
waves (imps, wogols, chorts, pumpkin dudes + a necromancer boss), kills drop
spinning soul coins that fly into the SOULS counter, progress saved to
`user://save.cfg`, ESC returns to the menu.

## Credits (downloaded assets, nothing hand-drawn)

| Asset | Source | License |
|---|---|---|
| Desert mountain background (+ clouds) | "Background Desert Mountains" by Szadi art — https://szadiart.itch.io/background-desert-mountains | Free for personal & commercial use |
| Wooden sign buttons, chains, title sign, corner icons | "Pixel Art Wooden GUI v1" by Narik (soulofkiran) — https://soulofkiran.itch.io/pixel-art-wooden-gui-v1 | CC0 |
| UI sounds (hover, press, drop, toggle, confirm) | "Kenney Interface Sounds" — https://kenney.nl/assets/interface-sounds | CC0 |
| Mage, monsters, coins, hearts, column sprites | "16x16 DungeonTileset II" by 0x72 — https://0x72.itch.io/dungeontileset-ii | CC0 |
| Gameplay foley (cast, hit, hurt, coins, wood creaks) | "Kenney RPG Audio" — https://kenney.nl/assets/rpg-audio | CC0 |
| Font (TS Serif) | "TS Serif" by Thundersnow Pixel — https://thundersnowpixel.itch.io/ts-serif | Commercial & non-commercial use OK; no redistribution |

`assets/` textures were sliced and integer-scaled (nearest neighbor) from the packs above;
no art was drawn from scratch.

## Run

Open the project in Godot 4.7 and press Play, or:

```
Godot_v4.7.2-stable_win64.exe --path D:\Roblox\opencode\tdy
```
