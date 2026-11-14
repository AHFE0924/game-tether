extends Area2D

const TILE_SIZE = 32
@onready var ray: RayCast2D = $RayCast2D
var player: Area2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	if not player: 
		return
		
	var diff = player.global_position - global_position
	var dir = Vector2.ZERO
	
	if abs(diff.x) > abs(diff.y):
		dir = Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
	else:
		dir = Vector2.DOWN if diff.y > 0 else Vector2.UP
		
	try_move(dir)

func try_move(dir: Vector2) -> void:
	ray.target_position = dir * TILE_SIZE
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		var tween = create_tween()
		tween.tween_property(self, "global_position", global_position + (dir * TILE_SIZE), 0.15)
