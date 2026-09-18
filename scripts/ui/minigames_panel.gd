extends Control
## Village Games — colorful Grade 3 recess. Lantern Catch, Wisp Pop, Fact Dash.

signal closed

const GAME_LANTERN := "lantern"
const GAME_WISP := "wisp"
const GAME_FACTS := "facts"

const WISP_PALETTE := [
	Color(1.0, 0.45, 0.70),
	Color(0.40, 0.85, 1.0),
	Color(1.0, 0.85, 0.25),
	Color(0.45, 0.95, 0.55),
	Color(0.85, 0.50, 1.0),
	Color(1.0, 0.60, 0.30),
]

const FACT_BTN_COLORS := [
	Color(1.0, 0.42, 0.45),
	Color(0.30, 0.78, 0.95),
	Color(1.0, 0.78, 0.22),
	Color(0.70, 0.48, 1.0),
]

var _root_panel: PanelContainer
var _title: Label
var _hint: Label
var _hub: VBoxContainer
var _play_host: Control
var _status: Label
var _back_btn: Button
var _close_btn: Button
var _fx_layer: Control

var _mode: String = "hub"
var _score: int = 0
var _active: bool = false
var _built: bool = false

# Lantern Catch
var _lantern_arena: Control
var _basket: Control
var _lanterns: Array = []
var _lantern_time: float = 0.0
var _lantern_spawn: float = 0.0
var _basket_x: float = 0.5
var _lantern_stars: Array = []
var _catch_streak: int = 0

# Wisp Pop
var _wisp_arena: Control
var _wisps: Array = []
var _wisp_time: float = 0.0
var _wisp_spawn: float = 0.0
var _wisp_combo: int = 0
var _wisp_combo_t: float = 0.0
var _wisp_bg_blobs: Array = []

# Fact Dash
var _fact_prompt: Label
var _fact_prompt_card: PanelContainer
var _fact_options: GridContainer
var _fact_timer_bar: ProgressBar
var _fact_stage: PanelContainer
var _fact_time: float = 0.0
var _fact_correct: int = 0
var _fact_streak: int = 0
var _fact_answer: String = ""
var _fact_flash: ColorRect


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ensure_built()
	set_process(false)


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_chrome()


func _build_chrome() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.03, 0.14, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_root_panel = PanelContainer.new()
	_root_panel.name = "Panel"
	_root_panel.anchor_left = 0.5
	_root_panel.anchor_top = 0.5
	_root_panel.anchor_right = 0.5
	_root_panel.anchor_bottom = 0.5
	_root_panel.offset_left = -400
	_root_panel.offset_top = -340
	_root_panel.offset_right = 400
	_root_panel.offset_bottom = 340
	add_child(_root_panel)
	_style_fun_panel(_root_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_panel.add_child(vbox)

	_title = Label.new()
	_title.name = "Title"
	_title.text = "✦ Village Games ✦"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40, 1))
	vbox.add_child(_title)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72, 1))
	vbox.add_child(_hint)

	_hub = VBoxContainer.new()
	_hub.name = "Hub"
	_hub.add_theme_constant_override("separation", 10)
	_hub.custom_minimum_size = Vector2(0, 240)
	vbox.add_child(_hub)

	_play_host = Control.new()
	_play_host.name = "PlayHost"
	_play_host.visible = false
	_play_host.custom_minimum_size = Vector2(0, 0)
	_play_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play_host.clip_contents = true
	vbox.add_child(_play_host)

	_fx_layer = Control.new()
	_fx_layer.name = "FxLayer"
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_play_host.add_child(_fx_layer)

	_status = Label.new()
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", Color(1.0, 0.94, 0.65, 1))
	vbox.add_child(_status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	_back_btn = Button.new()
	_back_btn.text = "All Games"
	_back_btn.visible = false
	_back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back_btn.pressed.connect(_on_back)
	_style_chunky_btn(_back_btn, Color(0.38, 0.32, 0.55), false)
	row.add_child(_back_btn)

	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_btn.pressed.connect(_on_close)
	_style_chunky_btn(_close_btn, Color(0.95, 0.68, 0.22), true)
	row.add_child(_close_btn)

	_rebuild_hub()


func _style_fun_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.10, 0.28, 0.98)
	style.border_color = Color(1.0, 0.78, 0.28, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(1.0, 0.45, 0.20, 0.40)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", style)


func _style_chunky_btn(btn: Button, base: Color, primary: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = base
	style.border_color = base.lightened(0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = base.lightened(0.14)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate()
	pressed.bg_color = base.darkened(0.12)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(1, 0.98, 0.92, 1))
	btn.add_theme_font_size_override("font_size", 17)


func open() -> void:
	_ensure_built()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stop_play()
	_show_hub()
	visible = true
	move_to_front()
	AudioBus.play_ui()


func _on_close() -> void:
	_stop_play()
	visible = false
	AudioBus.play_ui()
	closed.emit()


func _on_back() -> void:
	AudioBus.play_ui()
	_stop_play()
	_show_hub()


func _show_hub() -> void:
	_mode = "hub"
	_title.text = "✦ Village Games ✦"
	_title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40, 1))
	_hint.text = "Bright recess between lessons! Beat your best for a tiny XP cheer. Press 1 / 2 / 3."
	_hub.visible = true
	_play_host.visible = false
	_play_host.custom_minimum_size = Vector2(0, 0)
	_back_btn.visible = false
	_close_btn.text = "Close"
	_rebuild_hub()
	_status.text = _best_summary()


func _gs():
	return Engine.get_main_loop().root.get_node_or_null("GameState") if Engine.get_main_loop() else null


func _best_summary() -> String:
	var gs = _gs()
	if gs == null or not gs.has_method("get_minigame_best"):
		return "Pick a bright game!"
	return "★ Best · Lantern %d · Wisp %d · Facts %d ★" % [
		int(gs.get_minigame_best(GAME_LANTERN)),
		int(gs.get_minigame_best(GAME_WISP)),
		int(gs.get_minigame_best(GAME_FACTS)),
	]


func _rebuild_hub() -> void:
	for c in _hub.get_children():
		_hub.remove_child(c)
		c.free()
	_add_game_row(
		"1  Lantern Catch",
		"Scoop glowing lanterns from a starry sky — streaks light up!",
		GAME_LANTERN,
		Color(1.0, 0.78, 0.22),
		Color(0.55, 0.25, 0.90)
	)
	_add_game_row(
		"2  Wisp Pop",
		"Tap swirling color-wisps before they fade — build a wild combo!",
		GAME_WISP,
		Color(0.45, 0.90, 1.0),
		Color(1.0, 0.40, 0.75)
	)
	_add_game_row(
		"3  Fact Dash",
		"Smash bright answer tiles against a racing rainbow timer!",
		GAME_FACTS,
		Color(0.40, 0.95, 0.55),
		Color(0.25, 0.60, 1.0)
	)


func _add_game_row(title: String, blurb: String, game_id: String, accent: Color, accent2: Color) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.34, 0.97)
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	style.shadow_size = 8
	card.add_theme_stylebox_override("panel", style)
	_hub.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var badge := Control.new()
	badge.custom_minimum_size = Vector2(56, 56)
	var b1 := ColorRect.new()
	b1.size = Vector2(56, 56)
	b1.color = accent2.darkened(0.2)
	badge.add_child(b1)
	var b2 := ColorRect.new()
	b2.position = Vector2(8, 8)
	b2.size = Vector2(40, 40)
	b2.color = accent
	badge.add_child(b2)
	var b3 := ColorRect.new()
	b3.position = Vector2(18, 18)
	b3.size = Vector2(20, 20)
	b3.color = Color(1, 1, 1, 0.9)
	badge.add_child(b3)
	row.add_child(badge)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 19)
	t.add_theme_color_override("font_color", accent.lightened(0.2))
	col.add_child(t)
	var d := Label.new()
	d.text = blurb
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 12)
	d.add_theme_color_override("font_color", Color(0.90, 0.86, 0.78, 1))
	col.add_child(d)

	var play := Button.new()
	play.text = "Play!"
	play.custom_minimum_size = Vector2(100, 48)
	_style_chunky_btn(play, accent.darkened(0.05), true)
	play.pressed.connect(func(): _start_game(game_id))
	row.add_child(play)


func _clear_play_host() -> void:
	if _play_host == null:
		return
	for c in _play_host.get_children():
		if c == _fx_layer:
			continue
		c.queue_free()
	if _fx_layer == null or not is_instance_valid(_fx_layer):
		_fx_layer = Control.new()
		_fx_layer.name = "FxLayer"
		_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_play_host.add_child(_fx_layer)
	else:
		for c in _fx_layer.get_children():
			c.queue_free()
		_play_host.move_child(_fx_layer, _play_host.get_child_count() - 1)
	_lantern_arena = null
	_basket = null
	_lanterns.clear()
	_lantern_stars.clear()
	_wisp_arena = null
	_wisps.clear()
	_wisp_bg_blobs.clear()
	_fact_prompt = null
	_fact_prompt_card = null
	_fact_options = null
	_fact_timer_bar = null
	_fact_stage = null
	_fact_flash = null


func _raise_fx() -> void:
	if _fx_layer and is_instance_valid(_fx_layer) and _play_host:
		_play_host.move_child(_fx_layer, _play_host.get_child_count() - 1)


func _stop_play() -> void:
	_active = false
	set_process(false)
	_clear_play_host()


func _start_game(game_id: String) -> void:
	_ensure_built()
	AudioBus.play_ui()
	_stop_play()
	_hub.visible = false
	_play_host.visible = true
	_play_host.custom_minimum_size = Vector2(0, 390)
	_back_btn.visible = true
	_close_btn.text = "Close"
	_score = 0
	match game_id:
		GAME_LANTERN:
			_begin_lantern()
		GAME_WISP:
			_begin_wisp()
		GAME_FACTS:
			_begin_facts()
		_:
			_show_hub()


func _finish_game(game_id: String, score: int, detail: String) -> void:
	_active = false
	set_process(false)
	_mode = "result"
	var result: Dictionary = {}
	var gs = _gs()
	if gs != null and gs.has_method("record_minigame_score"):
		result = gs.record_minigame_score(game_id, score)
	else:
		result = {"best": score, "new_best": false, "xp_awarded": 0}
	var best: int = int(result.get("best", score))
	var xp_n: int = int(result.get("xp_awarded", 0))
	var cheer := ""
	if bool(result.get("new_best", false)):
		cheer = " ★ New best!"
		if AudioBus.has_method("play_quest_complete"):
			AudioBus.play_quest_complete()
		else:
			AudioBus.play_ui()
		_burst(Color(1.0, 0.82, 0.30), _play_host.size * 0.5, 22)
	else:
		AudioBus.play_ui()
	_title.text = "Nice play!"
	_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1))
	_hint.text = detail
	_status.text = "Score %d · Best %d%s%s" % [
		score, best, cheer, (" · +%d XP" % xp_n) if xp_n > 0 else "",
	]
	_clear_play_host()
	var again := Button.new()
	again.text = "Play again!"
	_style_chunky_btn(again, Color(1.0, 0.55, 0.25), true)
	again.pressed.connect(func(): _start_game(game_id))
	_play_host.add_child(again)
	again.set_anchors_preset(Control.PRESET_CENTER_TOP)
	again.offset_left = -140
	again.offset_right = 140
	again.offset_top = 140
	again.offset_bottom = 195


func _burst(base: Color, at: Vector2, count: int = 16) -> void:
	if _fx_layer == null:
		return
	for i in range(count):
		var speck := ColorRect.new()
		var sz := 6 + randi() % 12
		speck.size = Vector2(sz, sz)
		speck.position = at
		speck.color = WISP_PALETTE[i % WISP_PALETTE.size()] if i % 2 == 0 else base
		_fx_layer.add_child(speck)
		var tw := create_tween()
		var dest := at + Vector2(randf_range(-160, 160), randf_range(-140, 90))
		tw.tween_property(speck, "position", dest, 0.5 + randf() * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(speck, "modulate:a", 0.0, 0.55)
		tw.parallel().tween_property(speck, "scale", Vector2(0.2, 0.2), 0.55)
		tw.tween_callback(speck.queue_free)


func _float_score(txt: String, at: Vector2, col: Color) -> void:
	if _fx_layer == null:
		return
	var lbl := Label.new()
	lbl.text = txt
	lbl.position = at
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", col)
	_fx_layer.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", at.y - 48.0, 0.55).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.55)
	tw.tween_callback(lbl.queue_free)


# --- Lantern Catch ---------------------------------------------------------

func _begin_lantern() -> void:
	_mode = "lantern"
	_title.text = "Lantern Catch"
	_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28, 1))
	_hint.text = "Scoop glowing lanterns · dodge dusty shells · streaks make bigger pops!"
	_lantern_time = 40.0
	_lantern_spawn = 0.2
	_basket_x = 0.5
	_score = 0
	_catch_streak = 0
	_active = true

	_lantern_arena = Control.new()
	_lantern_arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lantern_arena.clip_contents = true
	_play_host.add_child(_lantern_arena)
	_play_host.move_child(_lantern_arena, 0)

	var sky := ColorRect.new()
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.06, 0.08, 0.26, 1)
	_lantern_arena.add_child(sky)
	var aurora := ColorRect.new()
	aurora.set_anchors_preset(Control.PRESET_TOP_WIDE)
	aurora.offset_bottom = 110
	aurora.color = Color(0.35, 0.15, 0.55, 0.75)
	_lantern_arena.add_child(aurora)
	var aurora2 := ColorRect.new()
	aurora2.set_anchors_preset(Control.PRESET_TOP_WIDE)
	aurora2.offset_top = 40
	aurora2.offset_bottom = 130
	aurora2.color = Color(0.15, 0.35, 0.55, 0.45)
	_lantern_arena.add_child(aurora2)
	# Moon
	var moon_glow := ColorRect.new()
	moon_glow.position = Vector2(520, 18)
	moon_glow.size = Vector2(64, 64)
	moon_glow.color = Color(1.0, 0.95, 0.70, 0.22)
	_lantern_arena.add_child(moon_glow)
	var moon := ColorRect.new()
	moon.position = Vector2(532, 30)
	moon.size = Vector2(40, 40)
	moon.color = Color(1.0, 0.96, 0.82, 1)
	_lantern_arena.add_child(moon)
	var ground := ColorRect.new()
	ground.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -56
	ground.color = Color(0.14, 0.30, 0.20, 1)
	_lantern_arena.add_child(ground)
	var path := ColorRect.new()
	path.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	path.offset_top = -28
	path.offset_left = 80
	path.offset_right = -80
	path.color = Color(0.35, 0.28, 0.18, 1)
	_lantern_arena.add_child(path)

	_lantern_stars.clear()
	for i in range(28):
		var star := ColorRect.new()
		var s := 2 + (i % 4)
		star.size = Vector2(s, s)
		star.color = Color(1, 0.95, 0.75, 0.7)
		star.position = Vector2(12 + randf() * 700, 6 + randf() * 180)
		_lantern_arena.add_child(star)
		_lantern_stars.append(star)

	_basket = _make_basket()
	_lantern_arena.add_child(_basket)
	_status.text = "⏱ 40 · ✨ 0 · streak ×0"
	_raise_fx()
	set_process(true)
	_place_basket()


func _make_basket() -> Control:
	var root := Control.new()
	root.size = Vector2(128, 48)
	var glow := ColorRect.new()
	glow.position = Vector2(10, -6)
	glow.size = Vector2(108, 14)
	glow.color = Color(1.0, 0.85, 0.35, 0.4)
	root.add_child(glow)
	var rim := ColorRect.new()
	rim.position = Vector2(0, 2)
	rim.size = Vector2(128, 14)
	rim.color = Color(1.0, 0.78, 0.35, 1)
	root.add_child(rim)
	var body := ColorRect.new()
	body.position = Vector2(6, 12)
	body.size = Vector2(116, 32)
	body.color = Color(0.82, 0.48, 0.18, 1)
	root.add_child(body)
	var stripe := ColorRect.new()
	stripe.position = Vector2(12, 22)
	stripe.size = Vector2(104, 8)
	stripe.color = Color(0.55, 0.28, 0.10, 1)
	root.add_child(stripe)
	var stripe2 := ColorRect.new()
	stripe2.position = Vector2(12, 34)
	stripe2.size = Vector2(104, 5)
	stripe2.color = Color(0.65, 0.35, 0.12, 1)
	root.add_child(stripe2)
	return root


func _place_basket() -> void:
	if _basket == null or _lantern_arena == null:
		return
	var w: float = maxf(1.0, _lantern_arena.size.x)
	var h: float = maxf(1.0, _lantern_arena.size.y)
	_basket.position = Vector2(_basket_x * (w - _basket.size.x), h - 58.0)


func _make_lantern_node(good: bool) -> Control:
	var root := Control.new()
	root.size = Vector2(36, 50)
	if good:
		var glow := ColorRect.new()
		glow.position = Vector2(-10, 0)
		glow.size = Vector2(56, 50)
		glow.color = Color(1.0, 0.82, 0.25, 0.32)
		root.add_child(glow)
		var glow2 := ColorRect.new()
		glow2.position = Vector2(-2, 8)
		glow2.size = Vector2(40, 36)
		glow2.color = Color(1.0, 0.70, 0.15, 0.45)
		root.add_child(glow2)
		var body := ColorRect.new()
		body.position = Vector2(6, 12)
		body.size = Vector2(24, 28)
		body.color = Color(1.0, 0.75, 0.18, 1)
		root.add_child(body)
		var flame := ColorRect.new()
		flame.position = Vector2(11, 16)
		flame.size = Vector2(14, 16)
		flame.color = Color(1.0, 0.96, 0.55, 1)
		root.add_child(flame)
		var core := ColorRect.new()
		core.position = Vector2(14, 20)
		core.size = Vector2(8, 8)
		core.color = Color(1.0, 1.0, 0.92, 1)
		root.add_child(core)
		var cap := ColorRect.new()
		cap.position = Vector2(8, 6)
		cap.size = Vector2(20, 8)
		cap.color = Color(0.90, 0.50, 0.12, 1)
		root.add_child(cap)
		var hang := ColorRect.new()
		hang.position = Vector2(16, 0)
		hang.size = Vector2(4, 8)
		hang.color = Color(0.75, 0.55, 0.25, 1)
		root.add_child(hang)
	else:
		var body := ColorRect.new()
		body.position = Vector2(6, 12)
		body.size = Vector2(24, 28)
		body.color = Color(0.40, 0.38, 0.36, 1)
		root.add_child(body)
		var crack := ColorRect.new()
		crack.position = Vector2(15, 14)
		crack.size = Vector2(5, 22)
		crack.color = Color(0.18, 0.16, 0.15, 1)
		root.add_child(crack)
		var dust := ColorRect.new()
		dust.position = Vector2(2, 38)
		dust.size = Vector2(32, 6)
		dust.color = Color(0.50, 0.46, 0.40, 0.6)
		root.add_child(dust)
	return root


func _spawn_lantern() -> void:
	if _lantern_arena == null:
		return
	var good: bool = randf() > 0.20
	var lamp := _make_lantern_node(good)
	var w: float = maxf(40.0, _lantern_arena.size.x - 44.0)
	lamp.position = Vector2(randf() * w, -50.0)
	_lantern_arena.add_child(lamp)
	_lanterns.append({
		"node": lamp,
		"good": good,
		"speed": 120.0 + randf() * 100.0,
		"wobble": randf() * TAU,
	})


func _process_lantern(delta: float) -> void:
	_lantern_time -= delta
	_lantern_spawn -= delta
	if _lantern_spawn <= 0.0:
		_lantern_spawn = 0.42 + randf() * 0.35
		_spawn_lantern()
		if randf() > 0.55:
			_spawn_lantern()

	for s in _lantern_stars:
		if s is ColorRect and is_instance_valid(s):
			s.modulate.a = 0.4 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.005 + s.position.x * 0.05))

	var move := 0.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_LEFT):
		move -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_RIGHT):
		move += 1.0
	_basket_x = clampf(_basket_x + move * delta * 1.55, 0.0, 1.0)
	_place_basket()

	var keep: Array = []
	for entry in _lanterns:
		var n: Control = entry.get("node")
		if n == null or not is_instance_valid(n):
			continue
		entry["wobble"] = float(entry.get("wobble", 0.0)) + delta * 4.5
		n.position.y += float(entry.get("speed", 120.0)) * delta
		n.position.x += sin(float(entry["wobble"])) * 36.0 * delta
		# Pulse glow on good lanterns
		if bool(entry.get("good", true)):
			n.modulate = Color(1, 1, 1, 0.85 + 0.15 * absf(sin(float(entry["wobble"]))))
		var caught := false
		if _basket and n.get_global_rect().intersects(_basket.get_global_rect()):
			caught = true
			var local := n.position + Vector2(18, 18)
			if bool(entry.get("good", true)):
				_catch_streak += 1
				var bonus := mini(3, _catch_streak / 3)
				_score += 1 + bonus
				AudioBus.play_ui()
				_burst(Color(1.0, 0.85, 0.25), local, 10 + bonus * 3)
				_float_score("+%d" % (1 + bonus), local, Color(1.0, 0.92, 0.35))
			else:
				_catch_streak = 0
				_score = maxi(0, _score - 1)
				_burst(Color(0.5, 0.45, 0.4), local, 6)
				_float_score("-1", local, Color(1.0, 0.45, 0.4))
		if caught or n.position.y > _lantern_arena.size.y + 60.0:
			if not caught and bool(entry.get("good", true)):
				_catch_streak = 0
			n.queue_free()
		else:
			keep.append(entry)
	_lanterns = keep
	_status.text = "⏱ %d · ✨ %d · streak ×%d" % [maxi(0, int(ceil(_lantern_time))), _score, _catch_streak]
	if _lantern_time <= 0.0:
		_finish_game(GAME_LANTERN, _score, "Lanterns gathered — the green glows warm!")


# --- Wisp Pop --------------------------------------------------------------

func _begin_wisp() -> void:
	_mode = "wisp"
	_title.text = "Wisp Pop"
	_title.add_theme_color_override("font_color", Color(0.55, 0.90, 1.0, 1))
	_hint.text = "Tap the glowing wisps · bigger combos = bigger bursts!"
	_wisp_time = 35.0
	_wisp_spawn = 0.15
	_score = 0
	_wisp_combo = 0
	_wisp_combo_t = 0.0
	_wisps.clear()
	_active = true

	_wisp_arena = Control.new()
	_wisp_arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wisp_arena.clip_contents = true
	_wisp_arena.gui_input.connect(_on_wisp_arena_input)
	_play_host.add_child(_wisp_arena)
	_play_host.move_child(_wisp_arena, 0)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.10, 0.14, 0.32, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wisp_arena.add_child(bg)
	var top := ColorRect.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 100
	top.color = Color(0.55, 0.20, 0.55, 0.55)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wisp_arena.add_child(top)
	var bot := ColorRect.new()
	bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top = -90
	bot.color = Color(0.15, 0.35, 0.45, 0.6)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wisp_arena.add_child(bot)

	_wisp_bg_blobs.clear()
	for i in range(10):
		var blob := ColorRect.new()
		blob.size = Vector2(40 + randi() % 50, 40 + randi() % 50)
		blob.position = Vector2(randf() * 600, randf() * 280)
		blob.color = Color(WISP_PALETTE[i % WISP_PALETTE.size()].r, WISP_PALETTE[i % WISP_PALETTE.size()].g, WISP_PALETTE[i % WISP_PALETTE.size()].b, 0.12)
		blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_wisp_arena.add_child(blob)
		_wisp_bg_blobs.append({"node": blob, "phase": randf() * TAU, "speed": 0.6 + randf()})

	_status.text = "⏱ 35 · 💥 0 · combo ×0"
	_raise_fx()
	set_process(true)


func _spawn_wisp() -> void:
	if _wisp_arena == null:
		return
	var col: Color = WISP_PALETTE[randi() % WISP_PALETTE.size()]
	var root := Control.new()
	var sz := 44.0 + randf() * 28.0
	root.size = Vector2(sz, sz)
	root.custom_minimum_size = Vector2(sz, sz)
	var aw: float = maxf(80.0, _wisp_arena.size.x - sz - 20.0)
	var ah: float = maxf(80.0, _wisp_arena.size.y - sz - 40.0)
	root.position = Vector2(20 + randf() * aw, 20 + randf() * ah)

	var glow := ColorRect.new()
	glow.position = Vector2(-8, -8)
	glow.size = Vector2(sz + 16, sz + 16)
	glow.color = Color(col.r, col.g, col.b, 0.28)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glow)
	var mid := ColorRect.new()
	mid.position = Vector2(4, 4)
	mid.size = Vector2(sz - 8, sz - 8)
	mid.color = col
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mid)
	var core := ColorRect.new()
	core.position = Vector2(sz * 0.28, sz * 0.28)
	core.size = Vector2(sz * 0.44, sz * 0.44)
	core.color = Color(1, 1, 1, 0.92)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(core)
	var spark := ColorRect.new()
	spark.position = Vector2(sz * 0.38, sz * 0.18)
	spark.size = Vector2(sz * 0.18, sz * 0.18)
	spark.color = Color(1, 1, 1, 0.7)
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(spark)

	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_pop_wisp(root)
	)
	_wisp_arena.add_child(root)
	_wisps.append({
		"node": root,
		"color": col,
		"life": 2.2 + randf() * 1.6,
		"age": 0.0,
		"vx": randf_range(-55, 55),
		"vy": randf_range(-40, 40),
		"pulse": randf() * TAU,
	})


func _pop_wisp(node: Control) -> void:
	if not _active or _mode != "wisp":
		return
	var found: Dictionary = {}
	for entry in _wisps:
		if entry.get("node") == node:
			found = entry
			break
	if found.is_empty():
		return
	_wisp_combo += 1
	_wisp_combo_t = 1.4
	var pts := 1 + mini(5, _wisp_combo / 2)
	_score += pts
	AudioBus.play_ui()
	var col: Color = found.get("color", Color.WHITE)
	var at := node.position + node.size * 0.5
	_burst(col, at, 12 + pts * 2)
	_float_score("+%d" % pts, at, col.lightened(0.2))
	_wisps.erase(found)
	node.queue_free()
	_status.text = "⏱ %d · 💥 %d · combo ×%d" % [maxi(0, int(ceil(_wisp_time))), _score, _wisp_combo]


func _on_wisp_arena_input(ev: InputEvent) -> void:
	# Misses just break combo softly — only when clicking empty space
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		# If a wisp handled it, it will have been removed; empty clicks cool the combo
		pass


func _process_wisp(delta: float) -> void:
	_wisp_time -= delta
	_wisp_spawn -= delta
	_wisp_combo_t -= delta
	if _wisp_combo_t <= 0.0:
		_wisp_combo = 0
	if _wisp_spawn <= 0.0:
		_wisp_spawn = 0.55 - mini(0.25, float(_score) * 0.004)
		_spawn_wisp()
		if randf() > 0.45:
			_spawn_wisp()

	for blob in _wisp_bg_blobs:
		var n: ColorRect = blob.get("node")
		if n == null or not is_instance_valid(n):
			continue
		blob["phase"] = float(blob.get("phase", 0.0)) + delta * float(blob.get("speed", 1.0))
		n.position.x += sin(float(blob["phase"])) * 18.0 * delta
		n.position.y += cos(float(blob["phase"]) * 0.7) * 14.0 * delta

	var keep: Array = []
	var arena_w: float = maxf(1.0, _wisp_arena.size.x)
	var arena_h: float = maxf(1.0, _wisp_arena.size.y)
	for entry in _wisps:
		var n: Control = entry.get("node")
		if n == null or not is_instance_valid(n):
			continue
		entry["age"] = float(entry.get("age", 0.0)) + delta
		entry["pulse"] = float(entry.get("pulse", 0.0)) + delta * 5.0
		n.position.x += float(entry.get("vx", 0.0)) * delta
		n.position.y += float(entry.get("vy", 0.0)) * delta
		# Bounce softly in arena
		if n.position.x < 8.0 or n.position.x > arena_w - n.size.x - 8.0:
			entry["vx"] = -float(entry.get("vx", 0.0))
		if n.position.y < 8.0 or n.position.y > arena_h - n.size.y - 8.0:
			entry["vy"] = -float(entry.get("vy", 0.0))
		var life: float = float(entry.get("life", 2.5))
		var age: float = float(entry.get("age", 0.0))
		var fade := 1.0 - clampf(age / life, 0.0, 1.0)
		var pulse := 1.0 + 0.08 * sin(float(entry["pulse"]))
		n.scale = Vector2(pulse, pulse)
		n.modulate.a = 0.35 + 0.65 * fade
		n.pivot_offset = n.size * 0.5
		if age >= life:
			# Missed — soft poof, lose combo
			_wisp_combo = 0
			n.queue_free()
		else:
			keep.append(entry)
	_wisps = keep
	_status.text = "⏱ %d · 💥 %d · combo ×%d" % [maxi(0, int(ceil(_wisp_time))), _score, _wisp_combo]
	if _wisp_time <= 0.0:
		_finish_game(GAME_WISP, _score, "Wisps danced and popped — what a colorful show!")


# --- Fact Dash -------------------------------------------------------------

func _begin_facts() -> void:
	_mode = "facts"
	_title.text = "Fact Dash"
	_title.add_theme_color_override("font_color", Color(0.45, 0.98, 0.60, 1))
	_hint.text = "Smash a bright tile · 1–4 keys work · streaks paint the stage!"
	_fact_time = 30.0
	_fact_correct = 0
	_fact_streak = 0
	_score = 0
	_active = true

	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_play_host.add_child(wrap)
	_play_host.move_child(wrap, 0)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.16, 0.30, 1)
	wrap.add_child(bg)

	_fact_flash = ColorRect.new()
	_fact_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fact_flash.color = Color(0.40, 1.0, 0.55, 0.0)
	_fact_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(_fact_flash)

	_fact_stage = PanelContainer.new()
	_fact_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fact_stage.offset_left = 8
	_fact_stage.offset_top = 8
	_fact_stage.offset_right = -8
	_fact_stage.offset_bottom = -8
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.12, 0.20, 0.38, 0.95)
	ss.border_color = Color(0.40, 0.90, 1.0, 1)
	ss.set_border_width_all(3)
	ss.set_corner_radius_all(16)
	ss.content_margin_left = 14
	ss.content_margin_right = 14
	ss.content_margin_top = 14
	ss.content_margin_bottom = 14
	_fact_stage.add_theme_stylebox_override("panel", ss)
	wrap.add_child(_fact_stage)

	var stage_v := VBoxContainer.new()
	stage_v.add_theme_constant_override("separation", 14)
	_fact_stage.add_child(stage_v)

	_fact_timer_bar = ProgressBar.new()
	_fact_timer_bar.min_value = 0
	_fact_timer_bar.max_value = 30
	_fact_timer_bar.value = 30
	_fact_timer_bar.show_percentage = false
	_fact_timer_bar.custom_minimum_size = Vector2(0, 22)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.95, 0.55, 1)
	fill.set_corner_radius_all(10)
	_fact_timer_bar.add_theme_stylebox_override("fill", fill)
	var tbg := StyleBoxFlat.new()
	tbg.bg_color = Color(0.16, 0.18, 0.28, 1)
	tbg.set_corner_radius_all(10)
	_fact_timer_bar.add_theme_stylebox_override("background", tbg)
	stage_v.add_child(_fact_timer_bar)

	_fact_prompt_card = PanelContainer.new()
	var pc := StyleBoxFlat.new()
	pc.bg_color = Color(1.0, 0.90, 0.40, 1)
	pc.border_color = Color(1.0, 0.55, 0.20, 1)
	pc.set_border_width_all(4)
	pc.set_corner_radius_all(18)
	pc.content_margin_left = 18
	pc.content_margin_right = 18
	pc.content_margin_top = 22
	pc.content_margin_bottom = 22
	pc.shadow_color = Color(1.0, 0.70, 0.20, 0.45)
	pc.shadow_size = 12
	_fact_prompt_card.add_theme_stylebox_override("panel", pc)
	stage_v.add_child(_fact_prompt_card)

	_fact_prompt = Label.new()
	_fact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fact_prompt.add_theme_font_size_override("font_size", 42)
	_fact_prompt.add_theme_color_override("font_color", Color(0.16, 0.12, 0.28, 1))
	_fact_prompt_card.add_child(_fact_prompt)

	_fact_options = GridContainer.new()
	_fact_options.columns = 2
	_fact_options.add_theme_constant_override("h_separation", 12)
	_fact_options.add_theme_constant_override("v_separation", 12)
	_fact_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_v.add_child(_fact_options)

	_status.text = "⏱ 30 · ✅ 0 · streak ×0"
	_raise_fx()
	_next_fact()
	set_process(true)


func _fact_band() -> String:
	var gs = _gs()
	var week: int = int(gs.unlocked_week) if gs else 1
	if week <= 3:
		return "add"
	if week <= 9:
		return "mul_easy"
	return "mul"


func _make_fact() -> Dictionary:
	var band := _fact_band()
	var a := 0
	var b := 0
	var prompt := ""
	var answer := 0
	match band:
		"add":
			a = randi_range(2, 20)
			b = randi_range(1, 15)
			if randf() > 0.45:
				prompt = "%d + %d = ?" % [a, b]
				answer = a + b
			else:
				var bigger: int = maxi(a, b + 3)
				var smaller: int = randi_range(1, mini(12, bigger - 1))
				prompt = "%d − %d = ?" % [bigger, smaller]
				answer = bigger - smaller
		"mul_easy":
			a = randi_range(0, 5)
			if randf() > 0.5:
				a = [2, 5, 10][randi() % 3]
			b = randi_range(0, 10)
			prompt = "%d × %d = ?" % [a, b]
			answer = a * b
		_:
			a = randi_range(2, 12)
			b = randi_range(2, 12)
			prompt = "%d × %d = ?" % [a, b]
			answer = a * b
	var opts: Array = [str(answer)]
	while opts.size() < 4:
		var wrong: int = answer + randi_range(-6, 6)
		if wrong == answer:
			wrong += 3 if randf() > 0.5 else -2
		wrong = maxi(0, wrong)
		var s := str(wrong)
		if s not in opts:
			opts.append(s)
	opts.shuffle()
	return {"prompt": prompt, "answer": str(answer), "options": opts}


func _next_fact() -> void:
	if _fact_options == null or _fact_prompt == null:
		return
	for c in _fact_options.get_children():
		c.queue_free()
	var fact: Dictionary = _make_fact()
	_fact_prompt.text = str(fact.get("prompt", "?"))
	_fact_answer = str(fact.get("answer", ""))
	if _fact_prompt_card:
		_fact_prompt_card.pivot_offset = Vector2(200, 40)
		_fact_prompt_card.scale = Vector2(0.82, 0.82)
		var tw := create_tween()
		tw.tween_property(_fact_prompt_card, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var i := 0
	for opt in fact.get("options", []):
		var btn := Button.new()
		btn.text = "%d  %s" % [i + 1, str(opt)]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_size_override("font_size", 24)
		_style_chunky_btn(btn, FACT_BTN_COLORS[i % FACT_BTN_COLORS.size()], true)
		var chosen := str(opt)
		var bi := i
		btn.pressed.connect(func(): _on_fact_pick(chosen, btn))
		_fact_options.add_child(btn)
		# Pop-in
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.7, 0.7)
		btn.pivot_offset = Vector2(80, 32)
		var twb := create_tween()
		twb.tween_interval(0.04 * bi)
		twb.tween_property(btn, "modulate:a", 1.0, 0.12)
		twb.parallel().tween_property(btn, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)
		i += 1


func _on_fact_pick(chosen: String, btn: Button = null) -> void:
	if not _active or _mode != "facts":
		return
	if chosen == _fact_answer:
		_fact_correct += 1
		_fact_streak += 1
		_score = _fact_correct
		AudioBus.play_ui()
		if _fact_flash:
			_fact_flash.color = Color(0.35, 1.0, 0.55, 0.45)
			var twf := create_tween()
			twf.tween_property(_fact_flash, "color:a", 0.0, 0.35)
		if btn:
			btn.pivot_offset = btn.size * 0.5
			var tw := create_tween()
			tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.08)
			tw.tween_property(btn, "scale", Vector2.ONE, 0.12)
		_burst(Color(0.45, 0.98, 0.55), _play_host.size * 0.5, 10 + _fact_streak)
		_float_score("✓ +1", Vector2(_play_host.size.x * 0.5 - 20, 80), Color(0.55, 1.0, 0.65))
		# Paint stage border by streak
		if _fact_stage:
			var ss := _fact_stage.get_theme_stylebox("panel") as StyleBoxFlat
			if ss:
				ss.border_color = WISP_PALETTE[mini(5, _fact_streak) % WISP_PALETTE.size()]
	else:
		_fact_streak = 0
		if AudioBus.has_method("play_miss"):
			AudioBus.play_miss()
		else:
			AudioBus.play_ui()
		if _fact_flash:
			_fact_flash.color = Color(1.0, 0.35, 0.35, 0.35)
			var twf := create_tween()
			twf.tween_property(_fact_flash, "color:a", 0.0, 0.3)
		if btn:
			var ox := btn.position.x
			var tw := create_tween()
			tw.tween_property(btn, "position:x", ox + 10, 0.05)
			tw.tween_property(btn, "position:x", ox - 10, 0.05)
			tw.tween_property(btn, "position:x", ox, 0.05)
	_status.text = "⏱ %d · ✅ %d · streak ×%d" % [maxi(0, int(ceil(_fact_time))), _fact_correct, _fact_streak]
	_next_fact()


func _process_facts(delta: float) -> void:
	_fact_time -= delta
	if _fact_timer_bar:
		_fact_timer_bar.value = _fact_time
		var fill := _fact_timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill:
			if _fact_time > 18.0:
				fill.bg_color = Color(0.35, 0.95, 0.55, 1)
			elif _fact_time > 8.0:
				fill.bg_color = Color(1.0, 0.82, 0.28, 1)
			else:
				fill.bg_color = Color(1.0, 0.40, 0.38, 1)
	_status.text = "⏱ %d · ✅ %d · streak ×%d" % [maxi(0, int(ceil(_fact_time))), _fact_correct, _fact_streak]
	if _fact_time <= 0.0:
		_finish_game(GAME_FACTS, _score, "Fact Dash done — %d correct!" % _fact_correct)


func _process(delta: float) -> void:
	if not _active:
		return
	match _mode:
		"lantern":
			_process_lantern(delta)
		"wisp":
			_process_wisp(delta)
		"facts":
			_process_facts(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.keycode if event.keycode != 0 else event.physical_keycode
		if _mode == "hub":
			match code:
				KEY_1:
					_start_game(GAME_LANTERN)
					get_viewport().set_input_as_handled()
					return
				KEY_2:
					_start_game(GAME_WISP)
					get_viewport().set_input_as_handled()
					return
				KEY_3:
					_start_game(GAME_FACTS)
					get_viewport().set_input_as_handled()
					return
		if _mode == "facts" and _fact_options:
			var digits := {KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3}
			if digits.has(code):
				var i: int = int(digits[code])
				if i < _fact_options.get_child_count():
					var btn: Button = _fact_options.get_child(i)
					if btn:
						# text is "1  42" — extract answer after spaces
						var parts := btn.text.split(" ", false)
						var ans := parts[parts.size() - 1] if parts.size() > 0 else btn.text
						_on_fact_pick(ans, btn)
						get_viewport().set_input_as_handled()
						return
	if not _active or _mode != "lantern":
		return
	if event is InputEventMouseMotion:
		if _lantern_arena and _lantern_arena.size.x > 1.0:
			var local_x: float = _lantern_arena.get_local_mouse_position().x
			_basket_x = clampf(local_x / _lantern_arena.size.x, 0.0, 1.0)
