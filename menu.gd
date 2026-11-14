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
