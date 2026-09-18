extends Control
## Village Games hub — wholesome Grade 3 recess breaks between lessons.
## Three mini games: Lantern Catch, Virtue Match, Fact Dash.

signal closed

const GAME_LANTERN := "lantern"
const GAME_MATCH := "match"
const GAME_FACTS := "facts"

const VIRTUES := [
	{"id": "wonder", "label": "Wonder", "color": Color(0.95, 0.78, 0.35)},
	{"id": "gratitude", "label": "Thanks", "color": Color(0.55, 0.78, 0.45)},
	{"id": "courage", "label": "Courage", "color": Color(0.90, 0.45, 0.35)},
	{"id": "diligence", "label": "Diligence", "color": Color(0.45, 0.65, 0.90)},
	{"id": "kindness", "label": "Kindness", "color": Color(0.90, 0.55, 0.75)},
	{"id": "joy", "label": "Joy", "color": Color(0.95, 0.85, 0.40)},
]

var _root_panel: PanelContainer
var _title: Label
var _hint: Label
var _hub: VBoxContainer
var _play_host: Control
var _status: Label
var _back_btn: Button
var _close_btn: Button

var _mode: String = "hub"  # hub | lantern | match | facts | result
var _score: int = 0
var _active: bool = false
var _built: bool = false

# Lantern Catch
var _lantern_arena: Control
var _basket: ColorRect
var _lanterns: Array = []
var _lantern_time: float = 0.0
var _lantern_spawn: float = 0.0
var _basket_x: float = 0.5
var _lantern_move: float = 0.0

# Virtue Match
var _match_grid: GridContainer
var _match_cards: Array = []
var _match_flipped: Array = []
var _match_lock: bool = false
var _match_pairs: int = 0
var _match_moves: int = 0

# Fact Dash
var _fact_prompt: Label
var _fact_options: VBoxContainer
var _fact_time: float = 0.0
var _fact_correct: int = 0
var _fact_total: int = 0
var _fact_answer: String = ""


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_built()
	set_process(false)


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_build_chrome()


func _build_chrome() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_root_panel = PanelContainer.new()
	_root_panel.name = "Panel"
	_root_panel.set_anchors_preset(Control.PRESET_CENTER)
	_root_panel.offset_left = -340
	_root_panel.offset_top = -300
	_root_panel.offset_right = 340
	_root_panel.offset_bottom = 300
	add_child(_root_panel)
	PanelChrome.apply_panel(_root_panel, 16)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	_root_panel.add_child(vbox)

	_title = Label.new()
	_title.name = "Title"
	_title.text = "Village Games"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PanelChrome.style_title(_title, 24)
	vbox.add_child(_title)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PanelChrome.style_muted(_hint, 13)
	vbox.add_child(_hint)

	_hub = VBoxContainer.new()
	_hub.name = "Hub"
	_hub.add_theme_constant_override("separation", 8)
	vbox.add_child(_hub)

	_play_host = Control.new()
	_play_host.name = "PlayHost"
	_play_host.visible = false
	_play_host.custom_minimum_size = Vector2(0, 360)
	_play_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_play_host)

	_status = Label.new()
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PanelChrome.style_body(_status, 14)
	vbox.add_child(_status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	_back_btn = Button.new()
	_back_btn.text = "All Games"
	_back_btn.visible = false
	_back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back_btn.pressed.connect(_on_back)
	PanelChrome.style_button(_back_btn, false)
	row.add_child(_back_btn)

	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_btn.pressed.connect(_on_close)
	PanelChrome.style_button(_close_btn, true)
	row.add_child(_close_btn)

	_rebuild_hub()


func open() -> void:
	_ensure_built()
	_stop_play()
	_show_hub()
	visible = true
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
	_title.text = "Village Games"
	_hint.text = "Fun recess between lessons. Beat your best for a tiny XP cheer (a few per day)."
	_hub.visible = true
	_play_host.visible = false
	_back_btn.visible = false
	_close_btn.text = "Close"
	_rebuild_hub()
	_status.text = _best_summary()


func _best_summary() -> String:
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState") if Engine.get_main_loop() else null
	if gs == null or not gs.has_method("get_minigame_best"):
		return "Pick a game to play."
	var a: int = int(gs.get_minigame_best(GAME_LANTERN))
	var b: int = int(gs.get_minigame_best(GAME_MATCH))
	var c: int = int(gs.get_minigame_best(GAME_FACTS))
	return "Best · Lantern %d · Match %d · Facts %d" % [a, b, c]


func _rebuild_hub() -> void:
	for c in _hub.get_children():
		c.queue_free()
	_add_game_row(
		"Lantern Catch",
		"Catch falling lanterns with your basket · A/D or ←/→",
		GAME_LANTERN,
		Color(0.95, 0.78, 0.35)
	)
	_add_game_row(
		"Virtue Match",
		"Flip cards and match six wholesome virtues",
		GAME_MATCH,
		Color(0.55, 0.72, 0.95)
	)
	_add_game_row(
		"Fact Dash",
		"Quick math facts timed to your unlocked week",
		GAME_FACTS,
		Color(0.55, 0.82, 0.55)
	)


func _add_game_row(title: String, blurb: String, game_id: String, accent: Color) -> void:
	var card := PanelContainer.new()
	var style := PanelChrome.apply_card(card)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.85)
	_hub.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var accent_bar := ColorRect.new()
	accent_bar.custom_minimum_size = Vector2(8, 48)
	accent_bar.color = accent
	row.add_child(accent_bar)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var t := Label.new()
	t.text = title
	PanelChrome.style_body(t, 16)
	col.add_child(t)
	var d := Label.new()
	d.text = blurb
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PanelChrome.style_muted(d, 12)
	col.add_child(d)
	var play := Button.new()
	play.text = "Play"
	play.custom_minimum_size = Vector2(88, 0)
	PanelChrome.style_button(play, true)
	play.pressed.connect(func(): _start_game(game_id))
	row.add_child(play)


func _clear_play_host() -> void:
	if _play_host == null:
		return
	for c in _play_host.get_children():
		c.queue_free()
	_lantern_arena = null
	_basket = null
	_lanterns.clear()
	_match_grid = null
	_match_cards.clear()
	_fact_prompt = null
	_fact_options = null


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
	_back_btn.visible = true
	_close_btn.text = "Close"
	_score = 0
	match game_id:
		GAME_LANTERN:
			_begin_lantern()
		GAME_MATCH:
			_begin_match()
		GAME_FACTS:
			_begin_facts()
		_:
			_show_hub()


func _gs():
	return Engine.get_main_loop().root.get_node_or_null("GameState") if Engine.get_main_loop() else null


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
		cheer = " New best!"
		if AudioBus.has_method("play_quest_complete"):
			AudioBus.play_quest_complete()
		else:
			AudioBus.play_ui()
	else:
		AudioBus.play_ui()
	_title.text = "Nice play!"
	_hint.text = detail
	_status.text = "Score %d · Best %d%s%s" % [
		score,
		best,
		cheer,
		(" · +%d XP" % xp_n) if xp_n > 0 else "",
	]
	_clear_play_host()
	var again := Button.new()
	again.text = "Play again"
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PanelChrome.style_button(again, true)
	again.pressed.connect(func(): _start_game(game_id))
	_play_host.add_child(again)
	again.set_anchors_preset(Control.PRESET_CENTER_TOP)
	again.offset_left = -120
	again.offset_right = 120
	again.offset_top = 120
	again.offset_bottom = 160


# --- Lantern Catch ---------------------------------------------------------

func _begin_lantern() -> void:
	_mode = "lantern"
	_title.text = "Lantern Catch"
	_hint.text = "Move the basket · catch warm lanterns · avoid empty shells"
	_lantern_time = 40.0
	_lantern_spawn = 0.35
	_basket_x = 0.5
	_lantern_move = 0.0
	_score = 0
	_active = true

	_lantern_arena = Control.new()
	_lantern_arena.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lantern_arena.clip_contents = true
	_play_host.add_child(_lantern_arena)

	var sky := ColorRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.12, 0.14, 0.22, 1)
	_lantern_arena.add_child(sky)

	_basket = ColorRect.new()
	_basket.color = Color(0.72, 0.52, 0.28, 1)
	_basket.size = Vector2(90, 28)
	_lantern_arena.add_child(_basket)

	_status.text = "Time 40 · Caught 0"
	set_process(true)
	_place_basket()


func _place_basket() -> void:
	if _basket == null or _lantern_arena == null:
		return
	var w: float = maxf(1.0, _lantern_arena.size.x)
	var h: float = maxf(1.0, _lantern_arena.size.y)
	_basket.position = Vector2(_basket_x * (w - _basket.size.x), h - 40.0)


func _spawn_lantern() -> void:
	if _lantern_arena == null:
		return
	var good: bool = randf() > 0.22
	var lamp := ColorRect.new()
	lamp.size = Vector2(22, 28)
	lamp.color = Color(0.98, 0.82, 0.35, 1) if good else Color(0.45, 0.42, 0.40, 1)
	var w: float = maxf(40.0, _lantern_arena.size.x - 30.0)
	lamp.position = Vector2(randf() * w, -30.0)
	_lantern_arena.add_child(lamp)
	_lanterns.append({
		"node": lamp,
		"good": good,
		"speed": 110.0 + randf() * 90.0,
	})


func _process_lantern(delta: float) -> void:
	_lantern_time -= delta
	_lantern_spawn -= delta
	if _lantern_spawn <= 0.0:
		_lantern_spawn = 0.55 + randf() * 0.45
		_spawn_lantern()

	var move := _lantern_move
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_LEFT):
		move -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_RIGHT):
		move += 1.0
	_basket_x = clampf(_basket_x + move * delta * 1.35, 0.0, 1.0)
	_place_basket()

	var keep: Array = []
	for entry in _lanterns:
		var n: ColorRect = entry.get("node")
		if n == null or not is_instance_valid(n):
			continue
		n.position.y += float(entry.get("speed", 120.0)) * delta
		var caught := false
		if _basket and n.get_global_rect().intersects(_basket.get_global_rect()):
			caught = true
			if bool(entry.get("good", true)):
				_score += 1
				AudioBus.play_ui()
			else:
				_score = maxi(0, _score - 1)
		if caught or n.position.y > _lantern_arena.size.y + 40.0:
			n.queue_free()
		else:
			keep.append(entry)
	_lanterns = keep
	_status.text = "Time %d · Caught %d" % [maxi(0, int(ceil(_lantern_time))), _score]
	if _lantern_time <= 0.0:
		_finish_game(GAME_LANTERN, _score, "Warm lanterns gathered for the village green.")


# --- Virtue Match ----------------------------------------------------------

func _begin_match() -> void:
	_mode = "match"
	_title.text = "Virtue Match"
	_hint.text = "Find matching virtues · fewer flips is better"
	_match_pairs = 0
	_match_moves = 0
	_match_flipped.clear()
	_match_lock = false
	_match_cards.clear()
	_active = true
	_score = 0

	var wrap := VBoxContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_theme_constant_override("separation", 8)
	_play_host.add_child(wrap)

	_match_grid = GridContainer.new()
	_match_grid.columns = 4
	_match_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_match_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_match_grid.add_theme_constant_override("h_separation", 8)
	_match_grid.add_theme_constant_override("v_separation", 8)
	wrap.add_child(_match_grid)

	var deck: Array = []
	for v in VIRTUES:
		deck.append(v)
		deck.append(v.duplicate())
	deck.shuffle()

	for i in range(deck.size()):
		var v: Dictionary = deck[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 64)
		btn.text = "?"
		btn.set_meta("virtue_id", str(v.get("id", "")))
		btn.set_meta("virtue_label", str(v.get("label", "")))
		btn.set_meta("virtue_color", v.get("color", Color.WHITE))
		btn.set_meta("matched", false)
		btn.set_meta("face_up", false)
		PanelChrome.style_button(btn, false)
		var idx: int = i
		btn.pressed.connect(func(): _on_match_card(idx))
		_match_grid.add_child(btn)
		_match_cards.append(btn)

	_status.text = "Pairs 0 / 6 · Flips 0"
	set_process(false)


func _on_match_card(idx: int) -> void:
	if not _active or _match_lock:
		return
	if idx < 0 or idx >= _match_cards.size():
		return
	var btn: Button = _match_cards[idx]
	if bool(btn.get_meta("matched")) or bool(btn.get_meta("face_up")):
		return
	if _match_flipped.size() >= 2:
		return
	AudioBus.play_ui()
	_flip_up(btn)
	_match_flipped.append(btn)
	if _match_flipped.size() < 2:
		return
	_match_moves += 1
	_match_lock = true
	var a: Button = _match_flipped[0]
	var b: Button = _match_flipped[1]
	var same: bool = str(a.get_meta("virtue_id")) == str(b.get_meta("virtue_id"))
	await get_tree().create_timer(0.55).timeout
	if not visible or _mode != "match":
		return
	if same:
		a.set_meta("matched", true)
		b.set_meta("matched", true)
		a.disabled = true
		b.disabled = true
		a.modulate = Color(0.85, 1.0, 0.85, 1)
		b.modulate = Color(0.85, 1.0, 0.85, 1)
		_match_pairs += 1
	else:
		_flip_down(a)
		_flip_down(b)
	_match_flipped.clear()
	_match_lock = false
	_status.text = "Pairs %d / 6 · Flips %d" % [_match_pairs, _match_moves]
	if _match_pairs >= 6:
		_score = maxi(1, 120 - _match_moves * 4)
		_finish_game(GAME_MATCH, _score, "All six virtues paired — Wonder through Joy.")


func _flip_up(btn: Button) -> void:
	btn.set_meta("face_up", true)
	btn.text = str(btn.get_meta("virtue_label"))
	var col: Color = btn.get_meta("virtue_color")
	btn.add_theme_color_override("font_color", col.lightened(0.15))


func _flip_down(btn: Button) -> void:
	btn.set_meta("face_up", false)
	btn.text = "?"
	btn.remove_theme_color_override("font_color")


# --- Fact Dash -------------------------------------------------------------

func _begin_facts() -> void:
	_mode = "facts"
	_title.text = "Fact Dash"
	_hint.text = "Answer as many as you can · facts grow with your week unlock"
	_fact_time = 30.0
	_fact_correct = 0
	_fact_total = 0
	_score = 0
	_active = true

	var wrap := VBoxContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_theme_constant_override("separation", 12)
	_play_host.add_child(wrap)

	_fact_prompt = Label.new()
	_fact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fact_prompt.add_theme_font_size_override("font_size", 28)
	PanelChrome.style_title(_fact_prompt, 28)
	wrap.add_child(_fact_prompt)

	_fact_options = VBoxContainer.new()
	_fact_options.add_theme_constant_override("separation", 8)
	wrap.add_child(_fact_options)

	_status.text = "Time 30 · Correct 0"
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
	for opt in fact.get("options", []):
		var btn := Button.new()
		btn.text = str(opt)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		PanelChrome.style_button(btn, false)
		var chosen := str(opt)
		btn.pressed.connect(func(): _on_fact_pick(chosen))
		_fact_options.add_child(btn)


func _on_fact_pick(chosen: String) -> void:
	if not _active or _mode != "facts":
		return
	_fact_total += 1
	if chosen == _fact_answer:
		_fact_correct += 1
		_score = _fact_correct
		AudioBus.play_ui()
	else:
		if AudioBus.has_method("play_miss"):
			AudioBus.play_miss()
		else:
			AudioBus.play_ui()
	_status.text = "Time %d · Correct %d" % [maxi(0, int(ceil(_fact_time))), _fact_correct]
	_next_fact()


func _process_facts(delta: float) -> void:
	_fact_time -= delta
	_status.text = "Time %d · Correct %d" % [maxi(0, int(ceil(_fact_time))), _fact_correct]
	if _fact_time <= 0.0:
		_finish_game(GAME_FACTS, _score, "Fact Dash done — %d correct in thirty seconds." % _fact_correct)


func _process(delta: float) -> void:
	if not _active:
		return
	match _mode:
		"lantern":
			_process_lantern(delta)
		"facts":
			_process_facts(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _active or _mode != "lantern":
		return
	if event is InputEventMouseMotion:
		if _lantern_arena and _lantern_arena.size.x > 1.0:
			var local_x: float = _lantern_arena.get_local_mouse_position().x
			_basket_x = clampf(local_x / _lantern_arena.size.x, 0.0, 1.0)
