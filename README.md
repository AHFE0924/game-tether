# Tether Swap

A small top-down arcade game made in **Godot 4.7**.
You play a knight on a grid. Grab every coin, open the portal, and get out before the enemies catch you.

## How to run it

1. Install Godot 4.7 or newer.
2. Open Godot, click **Import**, and pick the `project.godot` file in this folder.
3. Press **F5** to play. The game starts on the menu.

## Controls

| Action | Keys |
| --- | --- |
| Move | WASD or arrow keys (hold to keep moving) |
| Slash | J or X |
| Tether | Space |
| Pause | Esc or P |

## How to play

- **Goal:** collect every coin on the map. This opens the portal. Step into the portal to finish the level.
- **Hearts:** you start with 3. Touching an enemy or a pit costs one heart. You blink for a moment after a hit and cannot be hurt while blinking. You get one heart back between levels.
- **Slash:** hits the three tiles in front of you and pushes enemies back. Push an enemy into a pit for bonus points.
- **Tether:** press Space to drop an anchor. Press Space again to zip back to it. Enemies on the line get cut. An enemy standing on the anchor gets thrown to where you were.
- **Blast:** every 3 coins charge a blast. Your next zip explodes at both ends.
- **Game over:** when you run out of hearts. Your best score is saved.

## Levels and maps

Every level is built at random. Coins, pits, enemies, your start tile and the portal are placed in new spots each time. A pit is never placed where it would block off part of the map.

There are six map layouts:

| Level | Map | What it looks like |
| --- | --- | --- |
| 1 | Open Field | A few scattered blocks |
| 2 | The Pillars | A regular grid of pillars |
| 3 | Crossroads | A big cross with a gap in each arm |
| 4 | Four Chambers | Four rooms joined by doors |
| 5 | The Gauntlet | Long walls with gaps at the top and bottom |
| 6 | Ruins | Broken wall pieces |

After level 6 the layout is picked at random. Each level adds more coins, pits and enemies, and the enemies get a little faster.

## Enemies

| Enemy | Hits to beat | What it does |
| --- | --- | --- |
| Slime | 1 | Hops toward you along the shortest path |
| Big slime | 2 | Same as a slime, but slower. Appears from level 3 |
| Goblin | 2 | When it lines up with you, it flashes red, then charges up to 5 tiles in a straight line. Appears from level 2 |

Step sideways when a goblin flashes red.

## Power-ups

They appear on the map over time and sometimes drop from enemies.

| Power-up | Effect |
| --- | --- |
| Heart | +1 heart (up to 5) |
| Shield | Blocks the next hit |
| Haste | Move faster for 8 seconds |
| Freeze | Enemies stop for 5 seconds |
| Fury | Slash hits all around you and does double damage for 8 seconds |

## Biomes

Pick one on the menu. It changes the colours, your knight and the enemies.

- **Fire:** lava pits, fire knight, blue slimes, cyan-mace goblins.
- **Ice:** frost pits, ice knight, red slimes, red-mace goblins.

## What we built

This is the list of changes made to the first version of the game.

1. **Random maps.** The level is no longer placed by hand in `main.tscn`. `main.gd` builds it when the level starts.
2. **Random placement.** Pits, coins and enemies go on random free tiles, away from the player.
3. **Objective and levels.** Coins open a portal. The portal ends the level. Levels go on forever and get harder.
4. **Hearts.** The player has HP instead of dying in one hit.
5. **Attacks.** A sword slash was added. The tether now cuts enemies on the way back.
6. **Power-ups.** Five kinds, listed above.
7. **New interface.** A top bar (hearts, level, coins, charge, score), pop-up banners, and pause, level-clear and game-over screens. The menu was redone with biome cards.
8. **Goblin enemy.** A new enemy that charges in a straight line.
9. **Pixel font.** A 5x7 pixel font drawn in code, so the text matches the pixel art.
10. **Dungeon look.** Panels and buttons are framed in carved stone blocks, a brick wall sits behind the menu and around the arena, and two torches flicker beside the title. All of it is drawn in code.
11. **Art fixes.** Sprites are cropped and sized in code. Pictures with a white background get the background cut out when they load.

## Files

| File | What it does |
| --- | --- |
| `GameData.gd` | Shared data (score, hearts, level, biome), colours, key setup, the pixel font and the UI style. Loaded automatically when the game starts |
| `main.gd` | Runs one level: builds the map, places everything, and applies the rules |
| `board.gd` | Draws the floor and walls |
| `player.gd` | The knight: moving, slashing, tether, taking damage |
| `enemy.gd` | Slimes, big slimes and goblins |
| `coin.gd` | The spinning coin |
| `hazard.gd` | The pit with a flame |
| `gfx.gd` | Shapes drawn in code: anchor, portal, power-ups and effects |
| `hud.gd` | The in-game interface |
| `menu.gd` | The title screen |
| `main.tscn`, `menu.tscn` | The two scenes. Both are almost empty because the scripts build everything |
| `player.tscn`, `enemy.tscn`, `coin.tscn`, `hazard.tscn` | Small scenes for each object |

Not used any more, but still in the folder: `wall.tscn`, `anchor.tscn`, `collision_shape_2d.gd`.

## Things to know

- The game has been tested with automated runs, not long play sessions. Enemy speed, damage and spawn rates may need tuning.
- The pixel font only has capital letters, numbers and basic punctuation. Lowercase letters show as capitals.
- Font sizes should be multiples of 8 (16, 24, 32...) so the pixels stay sharp.

## Scripts

The full code for every script is below. Click a file name to open it.

<details>
<summary><code>GameData.gd</code></summary>

```gdscript
extends Node

const SAVE_PATH := "user://bb_save.cfg"
const START_HP := 3
const HP_CAP := 5

var biome: String = "fire"
var level: int = 1
var total_score: int = 0
var hp: int = START_HP
var max_hp: int = START_HP
var best_score: int = 0
var best_level: int = 0

var PALETTES := {
	"fire": {
		"name": "FIRE",
		"bg": Color("140808"), "floor_a": Color("3b211d"), "floor_b": Color("341c19"),
		"wall": Color("7a4332"), "wall_top": Color("a05a3f"), "wall_dark": Color("2e1611"),
		"accent": Color("ff8a3d"), "hazard": Color("ff6a1f"), "pit": Color("260a05"),
		"panel": Color("241210"), "panel_hi": Color("4a231a"), "text": Color("ffe9d6"),
		"hero": "res://fire-removebg-preview.png", "slime": "res://slimec.png",
		"goblin": "res://goblin_cyan.webp",
	},
	"ice": {
		"name": "ICE",
		"bg": Color("060f1a"), "floor_a": Color("1d3348"), "floor_b": Color("192c40"),
		"wall": Color("3f729a"), "wall_top": Color("62a3cf"), "wall_dark": Color("12283b"),
		"accent": Color("5cd6ff"), "hazard": Color("8af0ff"), "pit": Color("04121f"),
		"panel": Color("0d1c2c"), "panel_hi": Color("1c3d5c"), "text": Color("e2f4ff"),
		"hero": "res://cold-removebg-preview.png", "slime": "res://slime-removebg-preview (1).png",
		"goblin": "res://goblin_red.png",
	},
}

var POWER_COLORS := {
	"heart": Color("ff5a6e"), "shield": Color("7d95ff"), "haste": Color("ffd23f"),
	"freeze": Color("aef0ff"), "fury": Color("c77dff"),
}
var POWER_NAMES := {
	"heart": "+1 HEART", "shield": "SHIELD", "haste": "HASTE", "freeze": "FREEZE", "fury": "FURY",
}

var _used_cache := {}
var _art_cache := {}
var _stone_cache := {}
var _tint_shader: Shader


func _ready() -> void:
	randomize()
	_setup_input()
	_load()


func pal() -> Dictionary:
	return PALETTES.get(biome, PALETTES["fire"])


func new_run() -> void:
	level = 1
	total_score = 0
	max_hp = START_HP
	hp = START_HP


func record() -> void:
	if total_score > best_score or level > best_level:
		best_score = max(best_score, total_score)
		best_level = max(best_level, level)
		var cfg := ConfigFile.new()
		cfg.set_value("best", "score", best_score)
		cfg.set_value("best", "level", best_level)
		cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = int(cfg.get_value("best", "score", 0))
		best_level = int(cfg.get_value("best", "level", 0))


func _setup_input() -> void:
	_action("move_up", [KEY_W, KEY_UP])
	_action("move_down", [KEY_S, KEY_DOWN])
	_action("move_left", [KEY_A, KEY_LEFT])
	_action("move_right", [KEY_D, KEY_RIGHT])
	_action("attack", [KEY_J, KEY_X])
	_action("tether", [KEY_SPACE])
	_action("pause", [KEY_ESCAPE, KEY_P])


func _action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func art(path: String) -> Texture2D:
	if _art_cache.has(path):
		return _art_cache[path]
	var tex: Texture2D = load(path)
	var img := tex.get_image()
	if img != null and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		if img.get_pixel(0, 0).a > 0.5:
			_cut_background(img)
			tex = ImageTexture.create_from_image(img)
	_art_cache[path] = tex
	return tex


func _cut_background(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var bg := img.get_pixel(0, 0)
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen[p.y * w + p.x] == 1:
			continue
		seen[p.y * w + p.x] = 1
		var c := img.get_pixel(p.x, p.y)
		if abs(c.r - bg.r) + abs(c.g - bg.g) + abs(c.b - bg.b) > 0.2:
			continue
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		stack.append(p + Vector2i.RIGHT)
		stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN)
		stack.append(p + Vector2i.UP)

func fit_sprite(sprite: Sprite2D, tex: Texture2D, target_h: float, foot_y: float) -> void:
	var used := used_rect(tex)
	sprite.texture = tex
	sprite.region_enabled = true
	sprite.region_rect = Rect2(used)
	sprite.centered = true
	sprite.rotation = 0.0
	var s: float = target_h / max(1.0, float(used.size.y))
	sprite.scale = Vector2(s, s)
	sprite.position = Vector2(0.0, foot_y - target_h * 0.5)


func used_rect(tex: Texture2D) -> Rect2i:
	if _used_cache.has(tex):
		return _used_cache[tex]
	var used := Rect2i(Vector2i.ZERO, Vector2i(tex.get_size()))
	var img := tex.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		var r := img.get_used_rect()
		if r.size.x > 0 and r.size.y > 0:
			used = r
	_used_cache[tex] = used
	return used


func tint_material(color: Color) -> ShaderMaterial:
	if _tint_shader == null:
		_tint_shader = Shader.new()
		_tint_shader.code = """shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = max(c.r, max(c.g, c.b));
	COLOR = vec4(tint.rgb * (0.35 + l * 0.9), c.a);
}"""
	var m := ShaderMaterial.new()
	m.shader = _tint_shader
	m.set_shader_parameter("tint", color)
	return m


func heart_points(size: float, at: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		pts.append(at + Vector2(x, y - 2.5) * size / 32.0)
	return pts


func box(bg: Color, border: Color, border_w: int, radius: int, pad: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	return sb


func make_theme() -> Theme:
	var p := pal()
	var accent: Color = p.accent
	var th := Theme.new()
	th.default_font = pixel_font()
	th.default_font_size = 16
	th.set_color("font_color", "Label", p.text)
	th.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.75))
	th.set_constant("shadow_offset_x", "Label", 2)
	th.set_constant("shadow_offset_y", "Label", 2)
	th.set_constant("line_spacing", "Label", 6)
	th.set_stylebox("panel", "PanelContainer", stone_box("panel", 8))
	th.set_stylebox("normal", "Button", stone_box("button", 4))
	th.set_stylebox("hover", "Button", stone_box("hover", 4))
	th.set_stylebox("pressed", "Button", stone_box("pressed", 4))
	var focus := box(Color(0, 0, 0, 0), accent.lightened(0.4), 3, 0, 12)
	focus.draw_center = false
	th.set_stylebox("focus", "Button", focus)
	th.set_color("font_color", "Button", p.text)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_focus_color", "Button", Color.WHITE)
	th.set_font_size("font_size", "Button", 16)
	return th


func stone_box(kind: String, pad: int) -> StyleBoxTexture:
	var key := biome + kind
	if not _stone_cache.has(key):
		_stone_cache[key] = _stone_texture(kind)
	var sb := StyleBoxTexture.new()
	sb.texture = _stone_cache[key]
	sb.set_texture_margin_all(12)
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.set_content_margin_all(12 + pad)
	return sb


func _stone_texture(kind: String) -> ImageTexture:
	var p := pal()
	var wall: Color = p.wall
	var accent: Color = p.accent
	var fill: Color = p.panel
	var stone := wall.lerp(Color(0.42, 0.42, 0.46), 0.6)
	var pressed := false
	match kind:
		"button":
			fill = p.panel_hi
		"hover":
			fill = (p.panel_hi as Color).lightened(0.12)
			stone = stone.lightened(0.15)
		"pressed":
			fill = accent.darkened(0.5)
			pressed = true
	var light := stone.lightened(0.35)
	var dark := stone.darkened(0.5)
	if pressed:
		var swap := light
		light = dark
		dark = swap
	var edge := Color(0.05, 0.04, 0.04)
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var d: int = min(min(x, y), min(15 - x, 15 - y))
			var c := fill
			if d == 0:
				var corner := (x == 0 or x == 15) and (y == 0 or y == 15)
				c = Color(0, 0, 0, 0) if corner else edge
			elif d == 1:
				var top_left := x == 1 or y == 1
				var bottom_right := x == 14 or y == 14
				c = stone if (top_left and bottom_right) else (light if top_left else dark)
			elif d == 2:
				c = stone.darkened(0.12) if (x * 7 + y * 13) % 5 == 0 else stone
			elif d == 3:
				c = edge
			if (d == 1 or d == 2) and (x == 7 or y == 7):
				c = stone.darkened(0.5)
			img.set_pixel(x, y, c)
	var stud := accent.lerp(Color(0.8, 0.8, 0.8), 0.35)
	for at in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
		img.set_pixel(at.x, at.y, stud)
	img.resize(48, 48, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func draw_bricks(draw_on: CanvasItem, area: Rect2) -> void:
	var p := pal()
	var base: Color = p.bg
	var mortar := base.darkened(0.45)
	draw_on.draw_rect(area, mortar)
	var row := 0
	var y := area.position.y
	while y < area.end.y:
		var x := area.position.x - (24.0 if row % 2 == 1 else 0.0)
		var col := 0
		while x < area.end.x:
			var shade := 0.05 + 0.03 * float((col * 31 + row * 17) % 4)
			draw_on.draw_rect(Rect2(x, y, 45, 21), base.lightened(shade))
			draw_on.draw_rect(Rect2(x, y, 45, 3), base.lightened(shade + 0.05))
			x += 48.0
			col += 1
		y += 24.0
		row += 1


const GLYPHS := {
	" ": "...../...../...../...../...../...../.....",
	"A": ".###./#...#/#...#/#####/#...#/#...#/#...#",
	"B": "####./#...#/#...#/####./#...#/#...#/####.",
	"C": ".###./#...#/#..../#..../#..../#...#/.###.",
	"D": "####./#...#/#...#/#...#/#...#/#...#/####.",
	"E": "#####/#..../#..../####./#..../#..../#####",
	"F": "#####/#..../#..../####./#..../#..../#....",
	"G": ".###./#...#/#..../#.###/#...#/#...#/.###.",
	"H": "#...#/#...#/#...#/#####/#...#/#...#/#...#",
	"I": ".###./..#../..#../..#../..#../..#../.###.",
	"J": "..###/...#./...#./...#./...#./#..#./.##..",
	"K": "#...#/#..#./#.#../##.../#.#../#..#./#...#",
	"L": "#..../#..../#..../#..../#..../#..../#####",
	"M": "#...#/##.##/#.#.#/#.#.#/#...#/#...#/#...#",
	"N": "#...#/##..#/#.#.#/#..##/#...#/#...#/#...#",
	"O": ".###./#...#/#...#/#...#/#...#/#...#/.###.",
	"P": "####./#...#/#...#/####./#..../#..../#....",
	"Q": ".###./#...#/#...#/#...#/#.#.#/#..#./.##.#",
	"R": "####./#...#/#...#/####./#.#../#..#./#...#",
	"S": ".####/#..../#..../.###./....#/....#/####.",
	"T": "#####/..#../..#../..#../..#../..#../..#..",
	"U": "#...#/#...#/#...#/#...#/#...#/#...#/.###.",
	"V": "#...#/#...#/#...#/#...#/#...#/.#.#./..#..",
	"W": "#...#/#...#/#...#/#.#.#/#.#.#/##.##/#...#",
	"X": "#...#/#...#/.#.#./..#../.#.#./#...#/#...#",
	"Y": "#...#/#...#/.#.#./..#../..#../..#../..#..",
	"Z": "#####/....#/...#./..#../.#.../#..../#####",
	"0": ".###./#...#/#..##/#.#.#/##..#/#...#/.###.",
	"1": "..#../.##../..#../..#../..#../..#../.###.",
	"2": ".###./#...#/....#/...#./..#../.#.../#####",
	"3": "####./....#/....#/.###./....#/....#/####.",
	"4": "...#./..##./.#.#./#..#./#####/...#./...#.",
	"5": "#####/#..../####./....#/....#/#...#/.###.",
	"6": ".###./#..../#..../####./#...#/#...#/.###.",
	"7": "#####/....#/...#./..#../..#../..#../..#..",
	"8": ".###./#...#/#...#/.###./#...#/#...#/.###.",
	"9": ".###./#...#/#...#/.####/....#/....#/.###.",
	".": "...../...../...../...../...../.##../.##..",
	",": "...../...../...../...../..#../..#../.#...",
	"!": "..#../..#../..#../..#../..#../...../..#..",
	"?": ".###./#...#/....#/...#./..#../...../..#..",
	":": "...../.##../.##../...../.##../.##../.....",
	"-": "...../...../...../.###./...../...../.....",
	"+": "...../..#../..#../#####/..#../..#../.....",
	"/": "....#/....#/...#./..#../.#.../#..../#....",
	"'": "..#../..#../...../...../...../...../.....",
	"%": "##..#/##.#./...#./..#../.#.../.#.##/#..##",
	"(": "...#./..#../.#.../.#.../.#.../..#../...#.",
	")": ".#.../..#../...#./...#./...#./..#../.#...",
	"·": "...../...../.##../.##../...../...../.....",
}

var _pixel_font: FontFile


func pixel_font() -> FontFile:
	if _pixel_font != null:
		return _pixel_font
	var keys := GLYPHS.keys()
	var img := Image.create(keys.size() * 6, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var f := FontFile.new()
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.fixed_size = 8
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	var size := Vector2i(8, 0)
	f.set_cache_ascent(0, 8, 7.0)
	f.set_cache_descent(0, 8, 2.0)
	for i in keys.size():
		var ch: String = keys[i]
		var rows: PackedStringArray = GLYPHS[ch].split("/")
		for y in 7:
			for x in 5:
				if rows[y][x] == "#":
					img.set_pixel(i * 6 + x, y, Color.WHITE)
	f.set_texture_image(0, size, 0, img)
	for i in keys.size():
		var ch: String = keys[i]
		var codes: Array = [ch.unicode_at(0)]
		if ch.to_lower() != ch:
			codes.append(ch.to_lower().unicode_at(0))
		for code in codes:
			f.set_glyph_advance(0, 8, code, Vector2(4 if ch == " " else 6, 0))
			f.set_glyph_offset(0, size, code, Vector2(0, -7))
			f.set_glyph_size(0, size, code, Vector2(5, 7))
			f.set_glyph_uv_rect(0, size, code, Rect2(i * 6, 0, 5, 7))
			f.set_glyph_texture_idx(0, size, code, 0)
	var fallback: Array[Font] = [ThemeDB.fallback_font]
	f.fallbacks = fallback
	_pixel_font = f
	return f
```

</details>

<details>
<summary><code>main.gd</code></summary>

```gdscript
extends Node2D

const TILE := 32
const COLS := 25
const ROWS := 13
const DIRS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const MAP_NAMES := ["Open Field", "The Pillars", "Crossroads", "Four Chambers", "The Gauntlet", "Ruins"]
const POWER_TYPES := ["heart", "shield", "haste", "freeze", "fury"]
const NO_CELL := Vector2i(-1, -1)
const HUD_TOP := 72.0
const HUD_BOTTOM := 40.0

const PlayerScene := preload("res://player.tscn")
const EnemyScene := preload("res://enemy.tscn")
const CoinScene := preload("res://coin.tscn")
const HazardScene := preload("res://hazard.tscn")
const Board := preload("res://board.gd")
const GFX := preload("res://gfx.gd")
const Hud := preload("res://hud.gd")

var grid: Array = []
var hazards := {}
var coins := {}
var powerups := {}
var enemies: Array = []
var dist := {}
var player = null
var portal = null
var portal_cell := NO_CELL

var playing := false
var paused := false
var map_name := ""
var coins_total := 0
var coins_got := 0
var kills := 0
var level_time := 0.0
var freeze_time := 0.0
var enemy_speed := 1.0
var enemy_cap := 4
var tough_chance := 0.0
var goblin_chance := 0.0
var spawn_every := 7.0
var spawn_timer := 0.0
var power_timer := 12.0
var shake := 0.0
var cam_base := Vector2.ZERO

var world: Node2D
var board: Node2D
var objects: Node2D
var actors: Node2D
var fx_layer: Node2D
var line: Line2D
var cam: Camera2D
var hud


func _ready() -> void:
	get_tree().paused = false
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var p := GameData.pal()
	RenderingServer.set_default_clear_color(p.bg)
	world = Node2D.new()
	add_child(world)
	board = Board.new()
	board.game = self
	world.add_child(board)
	objects = Node2D.new()
	world.add_child(objects)
	line = Line2D.new()
	line.width = 3.0
	line.default_color = p.accent
	line.visible = false
	world.add_child(line)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	world.add_child(actors)
	fx_layer = Node2D.new()
	world.add_child(fx_layer)
	cam = Camera2D.new()
	add_child(cam)
	hud = Hud.new()
	hud.game = self
	add_child(hud)

	_generate()
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	playing = true
	hud.refresh()
	hud.show_banner("LEVEL %d  ·  %s" % [GameData.level, map_name],
		"Collect all %d coins, then reach the portal" % coins_total, 2.2)


func _process(delta: float) -> void:
	if is_instance_valid(player.active_anchor):
		line.visible = true
		line.points = PackedVector2Array([player.active_anchor.position, player.position])
	else:
		line.visible = false

	shake = move_toward(shake, 0.0, delta * 30.0)
	cam.position = cam_base + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake

	if playing:
		level_time += delta
		freeze_time = max(0.0, freeze_time - delta)
		_check_contact()
		_run_spawners(delta)
	hud.refresh()


func cell_to_world(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE * 0.5, c.y * TILE + TILE * 0.5)


func is_wall(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= COLS or c.y >= ROWS:
		return true
	return grid[c.y][c.x] == 1


func is_hazard(c: Vector2i) -> bool:
	return hazards.has(c)


func enemy_at(c: Vector2i):
	for e in enemies:
		if not e.dead and e.cell == c:
			return e
	return null


func enemy_can_enter(c: Vector2i, me) -> bool:
	if is_wall(c) or hazards.has(c):
		return false
	var other = enemy_at(c)
	return other == null or other == me


func _flood(start: Vector2i, avoid_hazards: bool) -> Dictionary:
	var out := {start: 0}
	var queue: Array = [start]
	var i := 0
	while i < queue.size():
		var c: Vector2i = queue[i]
		i += 1
		for d in DIRS:
			var n: Vector2i = c + d
			if out.has(n) or is_wall(n):
				continue
			if avoid_hazards and hazards.has(n):
				continue
			out[n] = out[c] + 1
			queue.append(n)
	return out


func _occupied(c: Vector2i) -> bool:
	if hazards.has(c) or coins.has(c) or powerups.has(c) or c == portal_cell:
		return true
	if player != null and (c == player.cell or (player.active_anchor != null and c == player.anchor_cell)):
		return true
	return enemy_at(c) != null


func _pick_cell(field: Dictionary, min_d: int) -> Vector2i:
	var d := min_d
	while d >= 1:
		var options: Array = []
		for c in field:
			if field[c] >= d and not _occupied(c):
				options.append(c)
		if not options.is_empty():
			return options[randi() % options.size()]
		d -= 1
	return NO_CELL


func _generate() -> void:
	var lvl: int = GameData.level
	var kind: int = (lvl - 1) % MAP_NAMES.size() if lvl <= MAP_NAMES.size() else randi() % MAP_NAMES.size()
	map_name = MAP_NAMES[kind]

	var start := NO_CELL
	var reach := {}
	var ok := false
	for attempt in 40:
		_carve(kind)
		start = Vector2i(randi_range(1, COLS - 2), randi_range(1, ROWS - 2))
		if is_wall(start):
			continue
		reach = _flood(start, false)
		if reach.size() >= 130:
			ok = true
			break
	if not ok:
		_carve(0)
		start = Vector2i(1, 1)
		reach = _flood(start, false)
	for y in ROWS:
		for x in COLS:
			if grid[y][x] == 0 and not reach.has(Vector2i(x, y)):
				grid[y][x] = 1
	board.queue_redraw()

	player = PlayerScene.instantiate()
	player.game = self
	player.cell = start
	actors.add_child(player)

	var hazard_n: int = min(3 + lvl, 14)
	for i in hazard_n:
		for attempt in 12:
			var c := _pick_cell(reach, 3)
			if c == NO_CELL:
				break
			hazards[c] = null
			if _flood(start, true).size() == reach.size() - hazards.size():
				break
			hazards.erase(c)
	for c in hazards:
		var h = HazardScene.instantiate()
		h.cell = c
		h.position = cell_to_world(c)
		objects.add_child(h)
		hazards[c] = h
	var field := _flood(start, true)

	portal_cell = _pick_cell(field, 14)
	portal = GFX.new()
	portal.kind = "portal"
	portal.color = GameData.pal().accent
	portal.position = cell_to_world(portal_cell)
	objects.add_child(portal)

	coins_total = min(4 + lvl, 12)
	for i in coins_total:
		var c := _pick_cell(field, 2)
		if c == NO_CELL:
			break
		var coin = CoinScene.instantiate()
		coin.cell = c
		coin.position = cell_to_world(c)
		objects.add_child(coin)
		coins[c] = coin
	coins_total = coins.size()

	enemy_cap = min(3 + lvl, 10)
	enemy_speed = max(0.7, 1.0 - 0.03 * (lvl - 1))
	tough_chance = 0.0 if lvl < 3 else min(0.5, 0.15 + 0.05 * (lvl - 3))
	goblin_chance = 0.0 if lvl < 2 else min(0.45, 0.2 + 0.04 * lvl)
	spawn_every = max(3.0, 7.5 - 0.5 * lvl)
	spawn_timer = spawn_every
	for i in min(1 + lvl, 8):
		var c := _pick_cell(field, 7)
		if c != NO_CELL:
			_spawn_enemy(c, 1.2, "goblin" if (i == 0 and lvl >= 2) else "")

	if lvl >= 2:
		_spawn_powerup(_pick_cell(field, 4))
	power_timer = randf_range(9.0, 14.0)
	_refresh_dist()


func _carve(kind: int) -> void:
	grid.clear()
	for y in ROWS:
		var row: Array = []
		for x in COLS:
			row.append(1 if (x == 0 or y == 0 or x == COLS - 1 or y == ROWS - 1) else 0)
		grid.append(row)
	var cx := COLS / 2
	var cy := ROWS / 2
	match kind:
		0:
			for i in randi_range(6, 9):
				var c := Vector2i(randi_range(2, COLS - 3), randi_range(2, ROWS - 3))
				_set_wall(c, true)
				if randf() < 0.5:
					_set_wall(c + DIRS[randi() % 4], true)
		1:
			for x in range(4, COLS - 3, 4):
				for y in range(3, ROWS - 2, 3):
					if randf() < 0.15:
						continue
					_set_wall(Vector2i(x, y), true)
					if randf() < 0.35:
						_set_wall(Vector2i(x, y) + DIRS[randi() % 4], true)
		2:
			for x in range(3, COLS - 3):
				_set_wall(Vector2i(x, cy), true)
			for y in range(2, ROWS - 2):
				_set_wall(Vector2i(cx, y), true)
			_set_wall(Vector2i(randi_range(4, cx - 2), cy), false)
			_set_wall(Vector2i(randi_range(cx + 2, COLS - 5), cy), false)
			_set_wall(Vector2i(cx, randi_range(2, cy - 2)), false)
			_set_wall(Vector2i(cx, randi_range(cy + 2, ROWS - 3)), false)
		3:
			for x in range(1, COLS - 1):
				_set_wall(Vector2i(x, cy), true)
			for y in range(1, ROWS - 1):
				_set_wall(Vector2i(cx, y), true)
			for door_x in [randi_range(2, cx - 3), randi_range(cx + 2, COLS - 4)]:
				_set_wall(Vector2i(door_x, cy), false)
				_set_wall(Vector2i(door_x + 1, cy), false)
			_set_wall(Vector2i(cx, randi_range(2, cy - 2)), false)
			_set_wall(Vector2i(cx, randi_range(cy + 2, ROWS - 3)), false)
		4:
			var top := randf() < 0.5
			for x in range(4, COLS - 3, 4):
				var gap: int = randi_range(1, 3) if top else randi_range(ROWS - 5, ROWS - 3)
				for y in range(1, ROWS - 1):
					if y != gap and y != gap + 1:
						_set_wall(Vector2i(x, y), true)
				if randf() < 0.3:
					_set_wall(Vector2i(x, randi_range(1, ROWS - 2)), false)
				top = not top
		5:
			for i in randi_range(8, 11):
				var c := Vector2i(randi_range(2, COLS - 3), randi_range(2, ROWS - 3))
				var d: Vector2i = DIRS[randi() % 4]
				for j in randi_range(2, 4):
					_set_wall(c, true)
					if randf() < 0.25:
						d = DIRS[randi() % 4]
					c += d


func _set_wall(c: Vector2i, solid: bool) -> void:
	if c.x >= 1 and c.y >= 1 and c.x <= COLS - 2 and c.y <= ROWS - 2:
		grid[c.y][c.x] = 1 if solid else 0


func _fit_camera() -> void:
	var vs := get_viewport_rect().size
	var w := float(COLS * TILE)
	var h := float(ROWS * TILE)
	var z: float = clamp(min((vs.x - 24.0) / w, (vs.y - HUD_TOP - HUD_BOTTOM) / h), 0.5, 3.0)
	cam.zoom = Vector2(z, z)
	cam_base = Vector2(w * 0.5, h * 0.5 - (HUD_TOP - HUD_BOTTOM) * 0.5 / z)
	cam.position = cam_base


func _spawn_enemy(c: Vector2i, delay: float, kind: String = "") -> void:
	if kind == "":
		if randf() < goblin_chance:
			kind = "goblin"
		elif randf() < tough_chance:
			kind = "big"
		else:
			kind = "slime"
	var e = EnemyScene.instantiate()
	e.setup(self, c, kind, delay)
	actors.add_child(e)
	enemies.append(e)


func _spawn_powerup(c: Vector2i, forced_type: String = "") -> void:
	if c == NO_CELL:
		return
	var type := forced_type
	if type == "":
		type = POWER_TYPES[randi() % POWER_TYPES.size()]
	var pu = GFX.new()
	pu.kind = "powerup"
	pu.ptype = type
	pu.color = GameData.POWER_COLORS[type]
	pu.position = cell_to_world(c)
	objects.add_child(pu)
	powerups[c] = pu


func _run_spawners(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_every
		if enemies.size() < enemy_cap:
			var c := _pick_cell(dist, 6)
			if c != NO_CELL:
				_spawn_enemy(c, 1.0)
				_fx("ring", cell_to_world(c), Color(1, 0.3, 0.3), {"r0": 22.0, "r1": 6.0, "life": 0.9})
	power_timer -= delta
	if power_timer <= 0.0:
		power_timer = randf_range(11.0, 17.0)
		if powerups.size() < 2:
			_spawn_powerup(_pick_cell(dist, 3))


func player_cell_changed() -> void:
	_refresh_dist()


func _refresh_dist() -> void:
	dist = _flood(player.cell, true)


func _check_contact() -> void:
	if freeze_time > 0.0:
		return
	for e in enemies.duplicate():
		if e.dead or e.spawn_t > 0.0:
			continue
		if e.position.distance_to(player.position) < 18.0:
			if player.take_damage(1):
				e.shove_from(player.cell)


func player_arrived() -> void:
	if not playing:
		return
	var c: Vector2i = player.cell
	if hazards.has(c):
		player.take_damage(1)
		_fx("burst", player.position, GameData.pal().hazard, {"r1": 26.0, "life": 0.3})
		if player.alive:
			player.bounce_back()
		return
	if coins.has(c):
		coins[c].collect()
		coins.erase(c)
		coins_got += 1
		add_score(10, player.position)
		if player.add_charge():
			float_text(player.position + Vector2(0, -14), "BLAST READY!", Color(1, 0.88, 0.35))
		if coins_got >= coins_total:
			portal.open = true
			_fx("ring", portal.position, GameData.pal().accent, {"r1": 70.0, "life": 0.6})
			hud.show_banner("PORTAL OPEN!", "Get to the exit", 1.6)
	if powerups.has(c):
		_take_powerup(c)
	if c == portal_cell:
		if portal.open:
			_level_clear()
		else:
			float_text(player.position, "Collect all coins first", Color.WHITE)


func _take_powerup(c: Vector2i) -> void:
	var pu = powerups[c]
	var type: String = pu.ptype
	powerups.erase(c)
	pu.queue_free()
	match type:
		"heart":
			if GameData.hp < GameData.max_hp:
				GameData.hp += 1
			elif GameData.max_hp < GameData.HP_CAP:
				GameData.max_hp += 1
				GameData.hp += 1
			else:
				add_score(100, player.position)
		"shield":
			player.shield = true
		"haste":
			player.haste = 8.0
		"freeze":
			freeze_time = 5.0
		"fury":
			player.fury = 8.0
	var col: Color = GameData.POWER_COLORS[type]
	_fx("ring", player.position, col, {"r1": 40.0, "life": 0.4})
	float_text(player.position, GameData.POWER_NAMES[type], col)


func player_attack(cells: Array, dmg: int, dir: Vector2i, all_round: bool) -> void:
	var col: Color = GameData.POWER_COLORS["fury"] if all_round else Color.WHITE
	_fx("slash", player.position + Vector2(0, -4), col, {"life": 0.16, "dir": Vector2(dir), "full": all_round})
	for e in enemies.duplicate():
		if e.dead:
			continue
		for c in cells:
			if e.cell == c or e.position.distance_to(cell_to_world(c)) < 14.0:
				var knock := dir
				if knock == Vector2i.ZERO:
					var dv: Vector2i = e.cell - player.cell
					if dv != Vector2i.ZERO:
						knock = Vector2i(signi(dv.x), 0) if abs(dv.x) >= abs(dv.y) else Vector2i(0, signi(dv.y))
				e.hit(dmg, knock)
				shake = max(shake, 2.0)
				break


func tether_strike(from_pos: Vector2, to_pos: Vector2, from_cell: Vector2i, to_cell: Vector2i, overcharged: bool) -> void:
	var accent: Color = GameData.pal().accent
	var swapped = enemy_at(to_cell)
	for e in enemies.duplicate():
		if e.dead or e == swapped:
			continue
		var near := Geometry2D.get_closest_point_to_segment(e.position, from_pos, to_pos)
		if e.position.distance_to(near) < 18.0:
			e.hit(1, Vector2i.ZERO)
	if swapped != null:
		swapped.relocate(from_cell)
	_fx("ring", to_pos, accent, {"r1": 30.0, "life": 0.3})
	if overcharged:
		var gold := Color(1, 0.85, 0.3)
		for pos in [from_pos, to_pos]:
			_fx("ring", pos, gold, {"r1": 2.6 * TILE, "life": 0.45})
			for e in enemies.duplicate():
				if not e.dead and e != swapped and e.position.distance_to(pos) <= 2.6 * TILE:
					e.hit(3, Vector2i.ZERO)
		shake = 8.0


func enemy_killed(e, by_hazard: bool) -> void:
	kills += 1
	var pts := 50 if by_hazard else 25
	if e.kind != "slime":
		pts += 25
	add_score(pts, e.position)
	_fx("burst", e.position, GameData.pal().hazard if by_hazard else Color.WHITE, {"r1": 24.0, "life": 0.3})
	if not by_hazard and randf() < 0.15 and powerups.size() < 3 and not _occupied(e.cell):
		_spawn_powerup(e.cell)


func add_score(points: int, at: Vector2) -> void:
	GameData.total_score += points
	float_text(at, "+%d" % points, Color(1, 0.9, 0.4))


func on_player_hurt() -> void:
	shake = 7.0
	_fx("ring", player.position, Color(1, 0.25, 0.25), {"r1": 36.0, "life": 0.35})


func on_shield_break() -> void:
	shake = 4.0
	_fx("ring", player.position, GameData.POWER_COLORS["shield"], {"r1": 44.0, "life": 0.4})
	float_text(player.position, "BLOCKED", GameData.POWER_COLORS["shield"])


func _level_clear() -> void:
	playing = false
	var lvl: int = GameData.level
	var bonus: int = 100 * lvl + max(0, 60 - int(level_time)) * 2
	GameData.total_score += bonus
	GameData.record()
	_fx("ring", player.position, GameData.pal().accent, {"r1": 90.0, "life": 0.6})
	var body := "Coins  %d / %d\nEnemies defeated  %d\nTime  %d s\nClear bonus  +%d\n\nScore  %d" % [
		coins_got, coins_total, kills, int(level_time), bonus, GameData.total_score]
	hud.show_overlay("LEVEL %d CLEAR!" % lvl, body, [["Next Level", _next_level], ["Main Menu", _to_menu]])


func game_over() -> void:
	playing = false
	GameData.record()
	var body := "You reached level %d\n\nScore  %d\nBest  %d" % [GameData.level, GameData.total_score, GameData.best_score]
	hud.show_overlay("GAME OVER", body, [["Try Again", _restart_run], ["Main Menu", _to_menu]])


func toggle_pause() -> void:
	if not playing:
		return
	paused = not paused
	get_tree().paused = paused
	if paused:
		hud.show_overlay("PAUSED", "", [["Resume", toggle_pause], ["Restart Run", _restart_run], ["Main Menu", _to_menu]])
	else:
		hud.hide_overlay()


func _next_level() -> void:
	GameData.level += 1
	GameData.hp = min(GameData.max_hp, GameData.hp + 1)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _restart_run() -> void:
	GameData.new_run()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")


func _fx(kind: String, pos: Vector2, color: Color, opts: Dictionary = {}) -> void:
	var g = GFX.new()
	g.kind = kind
	g.color = color
	for k in opts:
		g.set(k, opts[k])
	g.position = pos
	fx_layer.add_child(g)


func float_text(pos: Vector2, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(200, 0)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.add_theme_font_override("font", GameData.pixel_font())
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.position = pos + Vector2(-100, -42)
	fx_layer.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 22.0, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)
```

</details>

<details>
<summary><code>board.gd</code></summary>

```gdscript
extends Node2D

var game = null


func _draw() -> void:
	if game == null:
		return
	var p: Dictionary = GameData.pal()
	var t: int = game.TILE
	var cols: int = game.COLS
	var rows: int = game.ROWS
	GameData.draw_bricks(self, Rect2(-720, -480, cols * t + 1440, rows * t + 960))
	draw_rect(Rect2(-6, -6, cols * t + 12, rows * t + 12), p.wall_dark)

	for y in rows:
		for x in cols:
			if game.grid[y][x] == 1:
				continue
			draw_rect(Rect2(x * t, y * t, t, t), p.floor_a if (x + y) % 2 == 0 else p.floor_b)
			if game.grid[y - 1][x] == 1:
				draw_rect(Rect2(x * t, y * t, t, 7), Color(0, 0, 0, 0.28))

	for y in rows:
		for x in cols:
			if game.grid[y][x] != 1:
				continue
			var below_is_wall: bool = y + 1 >= rows or game.grid[y + 1][x] == 1
			var top_h: int = t if below_is_wall else t - 7
			draw_rect(Rect2(x * t, y * t, t, t), p.wall_dark)
			draw_rect(Rect2(x * t, y * t, t, top_h), p.wall)
			draw_rect(Rect2(x * t + 2, y * t + 2, t - 4, top_h - 4), p.wall_top)
```

</details>

<details>
<summary><code>player.gd</code></summary>

```gdscript
extends Area2D

const GFX := preload("res://gfx.gd")
const MOVES := {
	"move_up": Vector2i.UP, "move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT, "move_right": Vector2i.RIGHT,
}
const CHARGE_COINS := 3

@export var anchor_scene: PackedScene

var game = null
var cell := Vector2i.ZERO
var prev_cell := Vector2i.ZERO
var facing := Vector2i.RIGHT
var is_moving := false
var dashing := false
var alive := true

var coins := 0
var is_overcharged := false
var invuln := 0.0
var attack_cd := 0.0
var shield := false
var haste := 0.0
var fury := 0.0

var active_anchor: Node2D = null
var anchor_cell := Vector2i.ZERO
var queued := Vector2i.ZERO
var pending_tether := false

var sprite: Sprite2D
var sprite_home := Vector2.ZERO
var shield_fx: Node2D


func _ready() -> void:
	add_to_group("player")
	monitoring = false
	monitorable = false
	var cr := get_node_or_null("ColorRect")
	if cr:
		cr.hide()
	sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = Sprite2D.new()
		add_child(sprite)
	var p := GameData.pal()
	GameData.fit_sprite(sprite, GameData.art(p.hero), 44.0, 14.0)
	sprite_home = sprite.position
	if game == null:
		set_physics_process(false)
		set_process_unhandled_input(false)
		return
	position = game.cell_to_world(cell)
	prev_cell = cell
	shield_fx = GFX.new()
	shield_fx.kind = "shield"
	shield_fx.color = GameData.POWER_COLORS["shield"]
	shield_fx.visible = false
	add_child(shield_fx)


func _draw() -> void:
	draw_set_transform(Vector2(0, 13), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.35))


func _unhandled_input(event: InputEvent) -> void:
	if not alive or not game.playing:
		return
	if event.is_action_pressed("attack"):
		attack()
	elif event.is_action_pressed("tether"):
		pending_tether = true
	else:
		for action in MOVES:
			if event.is_action_pressed(action):
				queued = MOVES[action]


func _physics_process(delta: float) -> void:
	invuln = max(0.0, invuln - delta)
	attack_cd = max(0.0, attack_cd - delta)
	haste = max(0.0, haste - delta)
	fury = max(0.0, fury - delta)

	var tint := Color.WHITE
	if is_overcharged:
		tint = Color(1.0, 0.88, 0.35)
	elif fury > 0.0:
		tint = Color(1.0, 0.7, 1.0)
	tint.a = 0.35 if (invuln > 0.0 and fmod(invuln, 0.2) < 0.1) else 1.0
	sprite.modulate = tint
	shield_fx.visible = shield

	if not alive or not game.playing or is_moving:
		return
	if pending_tether:
		pending_tether = false
		tether()
		if is_moving:
			return
	var d := queued
	queued = Vector2i.ZERO
	if d == Vector2i.ZERO:
		for action in MOVES:
			if Input.is_action_pressed(action):
				d = MOVES[action]
				break
	if d != Vector2i.ZERO:
		try_move(d)


func try_move(d: Vector2i) -> void:
	facing = d
	if d.x != 0:
		sprite.flip_h = d.x > 0
	var target := cell + d
	is_moving = true
	if game.is_wall(target):
		var bump := create_tween()
		bump.tween_property(self, "position", position + Vector2(d) * 4.0, 0.04)
		bump.tween_property(self, "position", game.cell_to_world(cell), 0.05)
		bump.tween_callback(func(): is_moving = false)
		return
	prev_cell = cell
	cell = target
	game.player_cell_changed()
	var dur := 0.075 if haste > 0.0 else 0.115
	scale = Vector2(0.85, 1.15)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position", game.cell_to_world(cell), dur)
	tw.tween_property(self, "scale", Vector2.ONE, dur)
	tw.chain().tween_callback(_move_done)


func _move_done() -> void:
	is_moving = false
	game.player_arrived()


func bounce_back() -> void:
	is_moving = true
	cell = prev_cell
	game.player_cell_changed()
	var tw := create_tween()
	tw.tween_property(self, "position", game.cell_to_world(cell), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): is_moving = false)


func attack() -> void:
	if attack_cd > 0.0:
		return
	attack_cd = 0.3
	var all_round := fury > 0.0
	var cells: Array = [cell]
	if all_round:
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx != 0 or dy != 0:
					cells.append(cell + Vector2i(dx, dy))
	else:
		var side := Vector2i(facing.y, facing.x)
		cells.append(cell + facing)
		cells.append(cell + facing + side)
		cells.append(cell + facing - side)
	game.player_attack(cells, 2 if all_round else 1, Vector2i.ZERO if all_round else facing, all_round)
	var tw := sprite.create_tween()
	tw.tween_property(sprite, "position", sprite_home + Vector2(facing) * 6.0, 0.05)
	tw.tween_property(sprite, "position", sprite_home, 0.1)


func tether() -> void:
	if active_anchor == null:
		anchor_cell = cell
		active_anchor = GFX.new()
		active_anchor.kind = "anchor"
		active_anchor.color = GameData.pal().accent
		active_anchor.position = game.cell_to_world(cell)
		game.objects.add_child(active_anchor)
		return
	if anchor_cell == cell:
		_clear_anchor()
		return
	is_moving = true
	dashing = true
	var from_cell := cell
	game.tether_strike(position, game.cell_to_world(anchor_cell), from_cell, anchor_cell, is_overcharged)
	if is_overcharged:
		is_overcharged = false
		coins = 0
	cell = anchor_cell
	prev_cell = cell
	game.player_cell_changed()
	scale = Vector2(1.4, 0.6)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", game.cell_to_world(cell), 0.15)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
	tw.chain().tween_callback(_dash_done)


func _dash_done() -> void:
	dashing = false
	is_moving = false
	_clear_anchor()
	game.player_arrived()


func _clear_anchor() -> void:
	if is_instance_valid(active_anchor):
		active_anchor.queue_free()
	active_anchor = null


func add_charge() -> bool:
	if is_overcharged:
		return false
	coins += 1
	if coins >= CHARGE_COINS:
		is_overcharged = true
		return true
	return false


func take_damage(amount: int) -> bool:
	if not alive or invuln > 0.0 or dashing:
		return false
	if shield:
		shield = false
		invuln = 0.8
		game.on_shield_break()
		return true
	GameData.hp -= amount
	invuln = 1.2
	game.on_player_hurt()
	if GameData.hp <= 0:
		GameData.hp = 0
		alive = false
		game.game_over()
	return true
```

</details>

<details>
<summary><code>enemy.gd</code></summary>

```gdscript
extends Area2D

const DIRS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const CHARGE_RANGE := 5

var game = null
var cell := Vector2i.ZERO
var kind := "slime"
var tough := false
var hp := 1
var stun := 0.0
var spawn_t := 0.0
var flash := 0.0
var step_cd := 0.0
var windup := 0.0
var charge_cd := 1.5
var charge_dir := Vector2i.ZERO
var dead := false
var sprite: Sprite2D
var sprite_home := Vector2.ZERO
var move_tw: Tween


func setup(g, at: Vector2i, enemy_kind: String, delay: float) -> void:
	game = g
	cell = at
	kind = enemy_kind
	tough = kind == "big"
	spawn_t = delay


func _ready() -> void:
	add_to_group("enemy")
	monitoring = false
	monitorable = false
	var cr := get_node_or_null("ColorRect")
	if cr:
		cr.hide()
	var timer := get_node_or_null("Timer")
	if timer:
		timer.stop()
	sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = Sprite2D.new()
		add_child(sprite)
	var p := GameData.pal()
	match kind:
		"goblin":
			hp = 2
			GameData.fit_sprite(sprite, GameData.art(p.goblin), 36.0, 14.0)
		"big":
			hp = 2
			GameData.fit_sprite(sprite, GameData.art(p.slime), 34.0, 13.0)
			sprite.modulate = Color(0.85, 0.65, 1.0)
		_:
			GameData.fit_sprite(sprite, GameData.art(p.slime), 25.0, 13.0)
	sprite_home = sprite.position
	if game == null:
		set_physics_process(false)
		return
	position = game.cell_to_world(cell)
	step_cd = randf_range(0.2, 0.6)
	if spawn_t > 0.0:
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, spawn_t)


func _draw() -> void:
	draw_set_transform(Vector2(0, 12), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 9.0 if kind == "slime" else 12.0, Color(0, 0, 0, 0.35))


func _physics_process(delta: float) -> void:
	if dead:
		return
	flash = max(0.0, flash - delta)
	var frozen: bool = game.freeze_time > 0.0
	if flash > 0.0:
		modulate = Color(3, 3, 3)
	elif spawn_t > 0.0:
		modulate = Color(1, 1, 1, 0.5)
	elif frozen:
		modulate = Color(0.55, 0.85, 1.4)
	elif windup > 0.0:
		modulate = Color(1.9, 0.6, 0.6)
	else:
		modulate = Color.WHITE

	if not game.playing:
		return
	if spawn_t > 0.0:
		spawn_t -= delta
		return
	if frozen:
		return
	if stun > 0.0:
		stun -= delta
		return

	if kind == "goblin":
		sprite.flip_h = game.player.position.x > position.x
		charge_cd = max(0.0, charge_cd - delta)
		if windup > 0.0:
			windup -= delta
			sprite.position.x = sprite_home.x + randf_range(-1.5, 1.5)
			if windup <= 0.0:
				sprite.position = sprite_home
				_charge()
			return
		if charge_cd <= 0.0 and _can_charge():
			windup = 0.45
			charge_cd = 3.0
			return
	else:
		sprite.flip_h = game.player.position.x < position.x

	step_cd -= delta
	if step_cd <= 0.0:
		var near: bool = int(game.dist.get(cell, 99)) <= 4
		var wait := 0.36 if near else 0.55
		if kind != "slime":
			wait *= 1.25
		step_cd = wait * game.enemy_speed
		_step()


func _step() -> void:
	var best := Vector2i.ZERO
	var best_d: int = game.dist.get(cell, 9999)
	var options: Array = []
	for d in DIRS:
		var c: Vector2i = cell + d
		if not game.enemy_can_enter(c, self):
			continue
		options.append(d)
		var v: int = game.dist.get(c, 9999)
		if v < best_d or (v == best_d and best != Vector2i.ZERO and randf() < 0.5):
			best_d = v
			best = d
	if options.is_empty():
		return
	if best == Vector2i.ZERO:
		if randf() < 0.5:
			return
		best = options[randi() % options.size()]
	elif randf() < 0.12:
		best = options[randi() % options.size()]
	scale = Vector2(1.25, 0.75)
	_go(cell + best, 0.14)


func _can_charge() -> bool:
	var dv: Vector2i = game.player.cell - cell
	if dv == Vector2i.ZERO or (dv.x != 0 and dv.y != 0):
		return false
	var n: int = abs(dv.x) + abs(dv.y)
	if n < 2 or n > CHARGE_RANGE:
		return false
	charge_dir = Vector2i(signi(dv.x), signi(dv.y))
	for i in range(1, n):
		if not game.enemy_can_enter(cell + charge_dir * i, self):
			return false
	return true


func _charge() -> void:
	var target := cell
	var steps := 0
	while steps < CHARGE_RANGE:
		var c := target + charge_dir
		if not game.enemy_can_enter(c, self):
			break
		target = c
		steps += 1
		if c == game.player.cell:
			break
	if steps == 0:
		return
	stun = 0.05 * steps + 0.4
	scale = Vector2(1.3, 0.8)
	_go(target, 0.05 * steps)


func _go(target: Vector2i, dur: float) -> void:
	cell = target
	if move_tw:
		move_tw.kill()
	move_tw = create_tween().set_parallel(true)
	move_tw.tween_property(self, "position", game.cell_to_world(cell), dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	move_tw.tween_property(self, "scale", Vector2.ONE, dur)
	move_tw.chain().tween_callback(_arrived)


func _arrived() -> void:
	if not dead and game.is_hazard(cell):
		die(true)


func _cancel_windup() -> void:
	windup = 0.0
	sprite.position = sprite_home


func hit(dmg: int, knock: Vector2i) -> void:
	if dead:
		return
	flash = 0.1
	_cancel_windup()
	if knock != Vector2i.ZERO and game.is_hazard(cell + knock):
		stun = 1.0
		_go(cell + knock, 0.1)
		return
	hp -= dmg
	if hp <= 0:
		die(false)
		return
	stun = 0.5
	if knock != Vector2i.ZERO and game.enemy_can_enter(cell + knock, self):
		_go(cell + knock, 0.1)


func shove_from(from: Vector2i) -> void:
	stun = 0.7
	_cancel_windup()
	var order: Array = []
	var dv := cell - from
	if dv != Vector2i.ZERO:
		order.append(Vector2i(signi(dv.x), 0) if abs(dv.x) >= abs(dv.y) else Vector2i(0, signi(dv.y)))
	var rest := DIRS.duplicate()
	rest.shuffle()
	order.append_array(rest)
	for d in order:
		var c: Vector2i = cell + d
		if c != from and game.enemy_can_enter(c, self):
			_go(c, 0.12)
			return


func relocate(to: Vector2i) -> void:
	stun = 1.5
	_cancel_windup()
	_go(to, 0.15)


func die(by_hazard: bool) -> void:
	if dead:
		return
	dead = true
	game.enemies.erase(self)
	game.enemy_killed(self, by_hazard)
	if move_tw:
		move_tw.kill()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(0.1, 0.1), 0.18)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)
```

</details>

<details>
<summary><code>coin.gd</code></summary>

```gdscript
extends Area2D

var cell := Vector2i.ZERO
var t := randf() * TAU
var sprite: Sprite2D
var base_scale := Vector2.ONE


func _ready() -> void:
	monitoring = false
	monitorable = false
	modulate = Color.WHITE
	var cr := get_node_or_null("ColorRect")
	if cr:
		cr.hide()
	sprite = Sprite2D.new()
	add_child(sprite)
	GameData.fit_sprite(sprite, GameData.art("res://pixel-art-game-currency-coin-vector-removebg-preview.png"), 18.0, 9.0)
	base_scale = sprite.scale


func _process(delta: float) -> void:
	t += delta
	sprite.position.y = -1.0 + sin(t * 4.0) * 2.0
	sprite.scale.x = base_scale.x * (0.35 + 0.65 * abs(cos(t * 2.5)))


func collect() -> void:
	set_process(false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", position.y - 18.0, 0.25)
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.25)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)
```

</details>

<details>
<summary><code>hazard.gd</code></summary>

```gdscript
extends Area2D

var cell := Vector2i.ZERO
var t := randf() * TAU
var flame: Sprite2D
var base_scale := Vector2.ONE


func _ready() -> void:
	monitoring = false
	monitorable = false
	var cr := get_node_or_null("ColorRect")
	if cr:
		cr.hide()
	flame = get_node_or_null("Sprite2D")
	if flame == null:
		flame = Sprite2D.new()
		add_child(flame)
	var p := GameData.pal()
	GameData.fit_sprite(flame, GameData.art("res://Untitled_2-removebg-preview.png"), 26.0, 12.0)
	flame.material = GameData.tint_material(p.hazard)
	base_scale = flame.scale


func _process(delta: float) -> void:
	t += delta * 6.0
	flame.scale = base_scale * Vector2(1.0 + 0.06 * sin(t), 1.0 + 0.1 * sin(t * 1.3))
	queue_redraw()


func _draw() -> void:
	var p := GameData.pal()
	var glow: float = 0.5 + 0.5 * sin(t * 0.7)
	draw_rect(Rect2(-15, -15, 30, 30), p.pit)
	draw_rect(Rect2(-11, -11, 22, 22), Color(p.hazard, 0.18 + 0.14 * glow))
	draw_rect(Rect2(-15, -15, 30, 30), Color(p.hazard, 0.55 + 0.3 * glow), false, 2.0)


func _on_area_entered(_area: Area2D) -> void:
	pass
```

</details>

<details>
<summary><code>gfx.gd</code></summary>

```gdscript
extends Node2D

const ONE_SHOT := ["ring", "burst", "slash"]

var kind := "ring"
var color := Color.WHITE
var life := 0.4
var r0 := 4.0
var r1 := 40.0
var ptype := "heart"
var open := false
var dir := Vector2.RIGHT
var full := false
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	if kind in ONE_SHOT and t >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k: float = clamp(t / max(life, 0.01), 0.0, 1.0)
	match kind:
		"ring":
			var r: float = lerp(r0, r1, 1.0 - pow(1.0 - k, 2.0))
			draw_circle(Vector2.ZERO, r, Color(color, 0.22 * (1.0 - k)))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(color, 1.0 - k), lerp(5.0, 1.0, k), true)
		"burst":
			for i in 8:
				var v := Vector2.from_angle(i * TAU / 8.0 + 0.3)
				draw_line(v * lerp(4.0, r1 * 0.6, k), v * lerp(8.0, r1, k), Color(color, 1.0 - k), 2.0)
		"slash":
			var c := Color(color, 1.0 - k * 0.8)
			var w: float = 6.0 * (1.0 - k) + 1.5
			if full:
				draw_arc(Vector2.ZERO, 34.0, 0.0, TAU * min(1.0, k * 1.8), 40, c, w, true)
			else:
				var a := dir.angle()
				draw_arc(Vector2.ZERO, 30.0, a - 1.15, a - 1.15 + 2.3 * min(1.0, k * 1.8), 18, c, w, true)
		"anchor":
			var pulse: float = 0.5 + 0.5 * sin(t * 6.0)
			draw_arc(Vector2.ZERO, 10.0 + pulse * 3.0, 0.0, TAU, 32, Color(color, 0.7 - pulse * 0.4), 2.0, true)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0)]), color)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0)]), Color.WHITE)
		"portal":
			if open:
				draw_circle(Vector2.ZERO, 15.0 + 2.0 * sin(t * 4.0), Color(color, 0.28))
				draw_circle(Vector2.ZERO, 12.0, Color(0.02, 0.02, 0.05, 0.9))
				for i in 3:
					var a0: float = t * 3.0 + i * 2.1
					draw_arc(Vector2.ZERO, 4.0 + i * 3.5, a0, a0 + 4.2, 20, Color.WHITE.lerp(color, i / 2.0), 2.0, true)
			else:
				draw_circle(Vector2.ZERO, 12.0, Color(0.05, 0.05, 0.08, 0.85))
				draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 32, Color(0.55, 0.55, 0.62, 0.9), 2.0, true)
				draw_line(Vector2(-5, -5), Vector2(5, 5), Color(0.55, 0.55, 0.62, 0.9), 2.0)
				draw_line(Vector2(-5, 5), Vector2(5, -5), Color(0.55, 0.55, 0.62, 0.9), 2.0)
		"powerup":
			var o := Vector2(0.0, sin(t * 3.0) * 2.0)
			draw_circle(o, 12.0, color.darkened(0.7))
			draw_arc(o, 12.0, 0.0, TAU, 32, color, 2.0, true)
			draw_set_transform(o, 0.0, Vector2.ONE)
			_glyph()
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"shield":
			var c2 := Vector2(0, -6)
			draw_circle(c2, 21.0, Color(color, 0.12))
			draw_arc(c2, 21.0, 0.0, TAU, 40, Color(color, 0.6 + 0.3 * sin(t * 5.0)), 2.5, true)


func _glyph() -> void:
	match ptype:
		"heart":
			draw_colored_polygon(GameData.heart_points(14.0), color)
		"shield":
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -7), Vector2(6, -7), Vector2(6, 1), Vector2(0, 8), Vector2(-6, 1)]), color)
		"haste":
			draw_colored_polygon(PackedVector2Array([Vector2(1, -9), Vector2(-6, 1), Vector2(-1, 1), Vector2(-3, 9), Vector2(6, -2), Vector2(1, -2)]), color)
		"freeze":
			for i in 3:
				var v := Vector2.from_angle(i * PI / 3.0) * 8.0
				draw_line(-v, v, color, 2.0)
		"fury":
			var pts := PackedVector2Array()
			for i in 8:
				pts.append(Vector2.from_angle(i * TAU / 8.0 - PI / 2.0) * (9.0 if i % 2 == 0 else 3.5))
			draw_colored_polygon(pts, color)
```

</details>

<details>
<summary><code>hud.gd</code></summary>

```gdscript
extends CanvasLayer

var game = null
var root: Control
var hearts: Control
var pips: Control
var level_label: Label
var obj_label: Label
var score_label: Label
var chips := {}
var banner: PanelContainer
var banner_title: Label
var banner_sub: Label
var banner_tw: Tween
var overlay: Control
var overlay_title: Label
var overlay_body: Label
var overlay_buttons: VBoxContainer
var _sig := ""


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = GameData.make_theme()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(root)
	_build_bar()
	_build_hint()
	_build_banner()
	_build_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game != null:
		game.toggle_pause()
		get_viewport().set_input_as_handled()


func _label(text: String, size: int, color = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if color != null:
		l.add_theme_color_override("font_color", color)
	return l


func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _build_bar() -> void:
	var p := GameData.pal()
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", GameData.stone_box("panel", 2))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 6)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	bar.add_child(row)

	hearts = Control.new()
	hearts.custom_minimum_size = Vector2(26 * GameData.max_hp, 28)
	hearts.draw.connect(_draw_hearts)
	row.add_child(hearts)

	level_label = _label("", 16)
	row.add_child(level_label)
	row.add_child(_spacer())

	obj_label = _label("", 16, p.accent)
	row.add_child(obj_label)
	row.add_child(_spacer())

	row.add_child(_label("CHARGE", 16, Color(p.text, 0.7)))
	pips = Control.new()
	pips.custom_minimum_size = Vector2(3 * 18, 28)
	pips.draw.connect(_draw_pips)
	row.add_child(pips)

	score_label = _label("", 16)
	row.add_child(score_label)

	var chip_row := HBoxContainer.new()
	chip_row.alignment = BoxContainer.ALIGNMENT_END
	chip_row.add_theme_constant_override("separation", 18)
	chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(chip_row)
	chip_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	chip_row.offset_top = 68
	chip_row.offset_bottom = 68
	chip_row.offset_right = -26
	for type in ["shield", "haste", "fury", "freeze"]:
		var chip := _label("", 16, GameData.POWER_COLORS[type])
		chip.visible = false
		chip_row.add_child(chip)
		chips[type] = chip


func _build_hint() -> void:
	var hint := _label("MOVE: WASD / ARROWS    SLASH: J OR X    TETHER: SPACE    PAUSE: ESC", 16, Color(GameData.pal().text, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 8)


func _build_banner() -> void:
	var holder := HBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = 84
	holder.offset_bottom = 84
	banner = PanelContainer.new()
	banner.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.visible = false
	holder.add_child(banner)
	var col := VBoxContainer.new()
	banner.add_child(col)
	col.add_theme_constant_override("separation", 10)
	banner_title = _label("", 24, GameData.pal().accent)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(banner_title)
	banner_sub = _label("", 16)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(banner_sub)


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	panel.add_theme_stylebox_override("panel", GameData.stone_box("panel", 16))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)
	overlay_title = _label("", 32, GameData.pal().accent)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(overlay_title)
	overlay_body = _label("", 16)
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(overlay_body)
	overlay_buttons = VBoxContainer.new()
	overlay_buttons.add_theme_constant_override("separation", 10)
	col.add_child(overlay_buttons)


func _draw_hearts() -> void:
	for i in GameData.max_hp:
		var pts := GameData.heart_points(22.0, Vector2(13 + i * 26, 14))
		var full: bool = i < GameData.hp
		hearts.draw_colored_polygon(pts, Color("ff4d63") if full else Color(0, 0, 0, 0.45))
		pts.append(pts[0])
		hearts.draw_polyline(pts, Color("ffd0d6") if full else Color(1, 1, 1, 0.25), 1.5, true)


func _draw_pips() -> void:
	var gold := Color(1, 0.85, 0.3)
	var filled: int = 3 if game.player.is_overcharged else min(game.player.coins, 3)
	for i in 3:
		var c := Vector2(9 + i * 18, 14)
		if i < filled:
			pips.draw_circle(c, 6.5, gold)
		else:
			pips.draw_circle(c, 6.5, Color(0, 0, 0, 0.45))
		pips.draw_arc(c, 6.5, 0.0, TAU, 20, Color(gold, 0.9 if i < filled else 0.35), 1.5, true)


func refresh() -> void:
	var pl = game.player
	var sig := "%d/%d/%d/%s" % [GameData.hp, GameData.max_hp, pl.coins, pl.is_overcharged]
	if sig != _sig:
		_sig = sig
		hearts.custom_minimum_size.x = 26 * GameData.max_hp
		hearts.queue_redraw()
		pips.queue_redraw()
	level_label.text = "LEVEL %d  ·  %s" % [GameData.level, game.map_name]
	score_label.text = "SCORE  %05d" % GameData.total_score
	if game.coins_got >= game.coins_total:
		obj_label.text = "PORTAL OPEN"
	else:
		obj_label.text = "COINS  %d / %d" % [game.coins_got, game.coins_total]
	_chip("shield", pl.shield, "SHIELD")
	_chip("haste", pl.haste > 0.0, "HASTE %d" % ceil(pl.haste))
	_chip("fury", pl.fury > 0.0, "FURY %d" % ceil(pl.fury))
	_chip("freeze", game.freeze_time > 0.0, "FREEZE %d" % ceil(game.freeze_time))


func _chip(type: String, on: bool, text: String) -> void:
	chips[type].visible = on
	chips[type].text = text


func show_banner(title: String, sub: String, secs: float) -> void:
	banner_title.text = title
	banner_sub.text = sub
	banner_sub.visible = sub != ""
	banner.visible = true
	banner.modulate.a = 0.0
	if banner_tw:
		banner_tw.kill()
	banner_tw = create_tween()
	banner_tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	banner_tw.tween_interval(secs)
	banner_tw.tween_property(banner, "modulate:a", 0.0, 0.4)
	banner_tw.tween_callback(banner.hide)


func show_overlay(title: String, body: String, buttons: Array) -> void:
	overlay_title.text = title
	overlay_body.text = body
	overlay_body.visible = body != ""
	for b in overlay_buttons.get_children():
		b.queue_free()
	var first: Button = null
	for entry in buttons:
		var b := Button.new()
		b.text = entry[0]
		b.custom_minimum_size = Vector2(0, 46)
		b.pressed.connect(entry[1])
		overlay_buttons.add_child(b)
		if first == null:
			first = b
	overlay.visible = true
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(first) and overlay.visible:
		first.grab_focus()


func hide_overlay() -> void:
	overlay.visible = false
```

</details>

<details>
<summary><code>menu.gd</code></summary>

```gdscript
extends Control

var bg: ColorRect
var title: Label
var cards := {}
var wall: Control
var torches: Array = []
var time := 0.0


func _ready() -> void:
	get_tree().paused = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	wall = Control.new()
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall.draw.connect(func(): GameData.draw_bricks(wall, Rect2(Vector2.ZERO, wall.size)))
	add_child(wall)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	center.add_child(col)

	title = _label("TETHER SWAP", 64)
	title.add_theme_constant_override("shadow_offset_x", 6)
	title.add_theme_constant_override("shadow_offset_y", 6)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 36)
	col.add_child(title_row)
	title_row.add_child(_torch())
	title_row.add_child(title)
	title_row.add_child(_torch())

	col.add_child(_label("Grab every coin. Open the portal. Don't get slimed.", 16))
	if GameData.best_score > 0:
		col.add_child(_label("Best run: %d points - level %d" % [GameData.best_score, GameData.best_level], 16, 0.7))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	var group := ButtonGroup.new()
	row.add_child(_card("fire", "FIRE", "Lava pits", group))
	row.add_child(_card("ice", "ICE", "Frost pits", group))

	var play := Button.new()
	play.text = "PLAY"
	play.custom_minimum_size = Vector2(320, 60)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.add_theme_font_size_override("font_size", 24)
	play.pressed.connect(_on_play_pressed)
	col.add_child(play)

	var help := PanelContainer.new()
	col.add_child(help)
	help.add_child(_label(
		"MOVE: WASD / ARROWS   SLASH: J OR X   TETHER: SPACE\n"
		+ "Grab every coin to open the portal, then step in.\n"
		+ "Space drops an anchor. Press again to zip back.\n"
		+ "3 coins charge a blast. Knock enemies into pits!", 16))

	select_biome(GameData.biome)
	play.grab_focus()


func _process(delta: float) -> void:
	time += delta
	for t in torches:
		t.queue_redraw()


func _torch() -> Control:
	var t := Control.new()
	t.custom_minimum_size = Vector2(36, 84)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var seed_offset := torches.size() * 2.3
	t.draw.connect(func(): _draw_torch(t, seed_offset))
	torches.append(t)
	return t


func _draw_torch(t: Control, offset: float) -> void:
	var p := GameData.pal()
	var flame: Color = p.hazard
	var u := 4.0
	var mid := 18.0
	var step: float = floor(time * 9.0) + offset
	t.draw_circle(Vector2(mid, 30), 30.0 + sin(step) * 2.0, Color(flame, 0.07))
	t.draw_rect(Rect2(mid - u, 48, u * 2, 32), Color("5a3a22"))
	t.draw_rect(Rect2(mid - u, 48, u, 32), Color("7a5232"))
	t.draw_rect(Rect2(mid - u * 3, 40, u * 6, u * 2), Color("3a3a40"))
	t.draw_rect(Rect2(mid - u * 3, 40, u * 6, u), Color("5c5c66"))
	var heights := [2, 4, 6, 4, 2]
	for i in 5:
		var h: int = heights[i] + int(round(sin(step * 1.7 + i * 2.1)))
		var x := mid - u * 2.5 + i * u
		t.draw_rect(Rect2(x, 40 - h * u, u, h * u), flame)
		if i >= 1 and i <= 3 and h > 2:
			t.draw_rect(Rect2(x, 40 - (h - 2) * u, u, (h - 2) * u), flame.lightened(0.55))


func _label(text: String, size: int, alpha: float = 1.0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.modulate.a = alpha
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _card(biome: String, heading: String, blurb: String, group: ButtonGroup) -> Button:
	var p: Dictionary = GameData.PALETTES[biome]
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(230, 180)
	b.pressed.connect(func(): select_biome(biome))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)

	var tex: Texture2D = GameData.art(p.hero)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(GameData.used_rect(tex))
	var pic := TextureRect.new()
	pic.texture = atlas
	pic.custom_minimum_size = Vector2(0, 92)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)
	var head := _label(heading, 24)
	head.add_theme_color_override("font_color", p.accent)
	box.add_child(head)
	box.add_child(_label(blurb, 16, 0.8))
	cards[biome] = b
	return b


func select_biome(b: String) -> void:
	GameData.biome = b
	var p := GameData.pal()
	theme = GameData.make_theme()
	bg.color = p.bg
	wall.queue_redraw()
	title.add_theme_color_override("font_color", p.accent)
	for key in cards:
		cards[key].set_pressed_no_signal(key == b)


func _on_play_pressed() -> void:
	GameData.new_run()
	get_tree().change_scene_to_file("res://main.tscn")
```

</details>
