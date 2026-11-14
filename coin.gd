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
