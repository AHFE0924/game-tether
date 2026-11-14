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
