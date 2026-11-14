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
