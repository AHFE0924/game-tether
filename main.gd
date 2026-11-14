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
