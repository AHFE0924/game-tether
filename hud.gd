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
