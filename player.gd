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
