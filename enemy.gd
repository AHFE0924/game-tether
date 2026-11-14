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
