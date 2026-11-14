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
