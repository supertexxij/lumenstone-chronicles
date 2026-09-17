extends Control

signal inventory_pressed
signal wardrobe_pressed
signal parent_pressed
signal journal_pressed
signal mute_pressed
signal weather_pressed
signal travel_pressed
signal saves_pressed

@onready var name_lbl: Label = $TopBar/NameLbl
@onready var xp_lbl: Label = $TopBar/XpLbl
@onready var combat_lbl: Label = $TopBar/CombatLbl
@onready var hp_bar: ProgressBar = $TopBar/HpBar
var food_lbl: Label
@onready var lumen_lbl: Label = $TopBar/LumenLbl
@onready var inv_btn: Button = $BottomBar/InvBtn
@onready var look_btn: Button = $BottomBar/LookBtn
@onready var journal_btn: Button = $BottomBar/JournalBtn
@onready var mute_btn: Button = $BottomBar/MuteBtn
@onready var weather_btn: Button = $BottomBar/WeatherBtn
@onready var travel_btn: Button = $BottomBar/TravelBtn
@onready var parent_btn: Button = $BottomBar/ParentBtn
@onready var saves_btn: Button = $BottomBar/SavesBtn
@onready var hint_lbl: Label = $Hint
@onready var compass: Control = $Compass
@onready var compass_needle: Label = $Compass/Needle
@onready var compass_n: Label = $Compass/N
@onready var minimap: Control = $Minimap
@onready var day_lbl: Label = $DayLbl

var _world: Node = null
var _map_data: Dictionary = {}
var _hurt_vignette: Control = null
var _year_chip: Label = null
var _year_chip_panel: PanelContainer = null  # Wave 32: clearer chip plate
var _save_chip: Label = null
var _save_chip_panel: PanelContainer = null  # Wave 38: slot nickname chip
var _mute_style_on: StyleBoxFlat = null
var _mute_style_off: StyleBoxFlat = null
var _vignette_edges: Array = []
var _landmark_tick: ColorRect = null
var _def_flash_t: float = 0.0
var _def_flash_active: bool = false

func _ready() -> void:
	inv_btn.pressed.connect(func(): AudioBus.play_ui(); inventory_pressed.emit())
	look_btn.pressed.connect(func(): AudioBus.play_ui(); wardrobe_pressed.emit())
	journal_btn.pressed.connect(func(): AudioBus.play_ui(); journal_pressed.emit())
	mute_btn.pressed.connect(func(): mute_pressed.emit())
	if weather_btn:
		weather_btn.pressed.connect(func(): AudioBus.play_ui(); weather_pressed.emit())
	if travel_btn:
		travel_btn.pressed.connect(func(): AudioBus.play_ui(); travel_pressed.emit())
	parent_btn.pressed.connect(func(): AudioBus.play_ui(); parent_pressed.emit())
	if saves_btn == null:
		saves_btn = Button.new()
		saves_btn.name = "SavesBtn"
		saves_btn.text = "Saves"
		$BottomBar.add_child(saves_btn)
		$BottomBar.move_child(saves_btn, parent_btn.get_index())
	saves_btn.pressed.connect(func(): AudioBus.play_ui(); saves_pressed.emit())
	_ensure_food_lbl()
	_ensure_year_chip()
	_ensure_save_chip()
	hint_lbl.text = "Click · WASD · Zoom · Q/E · I/J/C · V food · M mute · R weather · T travel · F talk · H fountain · N glade · B ridge · G garden · L lookout · K mill · O hollow · P willow · Y reed · U cross · X arch · Z knoll · 6 birch · 7 fern · 8 heather · 9 thistle · 0 maple · 1–5 halls"
	_refresh_mute_label()
	if not AudioBus.mute_changed.is_connected(_on_mute):
		AudioBus.mute_changed.connect(_on_mute)
	if GameState.has_signal("hurt") and not GameState.hurt.is_connected(_on_hurt_def_flash):
		GameState.hurt.connect(_on_hurt_def_flash)
	_ensure_landmark_tick()
	set_process(true)

func set_world(world: Node) -> void:
	_world = world

func _on_mute(_m: bool) -> void:
	_refresh_mute_label()

func _refresh_mute_label() -> void:
	## Wave 38: clearer mute indicator — warm plate + bold Muted label when silent.
	_ensure_mute_styles()
	if GameState.muted:
		mute_btn.text = "Muted · M"
		mute_btn.add_theme_stylebox_override("normal", _mute_style_on)
		mute_btn.add_theme_stylebox_override("hover", _mute_style_on)
		mute_btn.add_theme_stylebox_override("pressed", _mute_style_on)
		mute_btn.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78, 1.0))
		mute_btn.tooltip_text = "Sound is muted — press M to hear the village again"
	else:
		mute_btn.text = "Mute (M)"
		if _mute_style_off:
			mute_btn.add_theme_stylebox_override("normal", _mute_style_off)
			mute_btn.add_theme_stylebox_override("hover", _mute_style_off)
			mute_btn.add_theme_stylebox_override("pressed", _mute_style_off)
		mute_btn.remove_theme_color_override("font_color")
		mute_btn.tooltip_text = "Mute sound (M)"

func refresh() -> void:
	name_lbl.text = GameState.child_name
	xp_lbl.text = "XP %d · Lv %d · Wk %d" % [GameState.xp, GameState.level, GameState.unlocked_week]
	var def_n: int = 0
	if GameState.has_method("get_defense"):
		def_n = int(GameState.get_defense())
	if _def_flash_active and def_n > 0:
		combat_lbl.text = "Combat Lv %d (%d XP) · Def %d softens the hit" % [GameState.combat_level, GameState.combat_xp, def_n]
	elif def_n > 0:
		combat_lbl.text = "Combat Lv %d (%d XP) · Def %d" % [GameState.combat_level, GameState.combat_xp, def_n]
	else:
		combat_lbl.text = "Combat Lv %d (%d XP)" % [GameState.combat_level, GameState.combat_xp]
	var parts: PackedStringArray = []
	for g in ["math","la","science","history","bible"]:
		parts.append("%s:%d" % [GameState.GUILDS[g]["lumen"], GameState.lumens.get(g, 0)])
	lumen_lbl.text = " · ".join(parts)
	set_hp(GameState.hp, GameState.max_hp)
	_refresh_food_lbl()
	_refresh_mute_label()
	_refresh_year_chip()
	_refresh_save_chip()

func set_hp(cur: int, mx: int) -> void:
	hp_bar.max_value = mx
	hp_bar.value = cur
	var hp_txt: Label = hp_bar.get_node("HpText")
	_ensure_clear_hp_text(hp_txt)
	# Wave 35: clearer combat HP number — bold "HP N / M" on the bar
	hp_txt.text = "HP %d / %d" % [cur, mx]
	_update_hurt_vignette(cur, mx)

func _ensure_clear_hp_text(hp_txt: Label) -> void:
	## Wave 35: larger cream HP digits with soft outline so combat HP reads at a glance.
	if hp_txt == null or hp_txt.has_meta("wave35_hp_styled"):
		return
	hp_txt.add_theme_font_size_override("font_size", 15)
	hp_txt.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	hp_txt.add_theme_color_override("font_outline_color", Color(0.12, 0.1, 0.08, 0.85))
	hp_txt.add_theme_constant_override("outline_size", 3)
	hp_txt.set_meta("wave35_hp_styled", true)

func _process(delta: float) -> void:
	if _def_flash_t > 0.0:
		_def_flash_t -= delta
		if _def_flash_t <= 0.0 and _def_flash_active:
			_def_flash_active = false
			if combat_lbl:
				combat_lbl.modulate = Color(1, 1, 1, 1)
			refresh()
	if not visible or _world == null:
		return
	if _world.has_method("get_minimap_markers"):
		_map_data = _world.get_minimap_markers()
	_update_compass()
	_update_day_label()
	if minimap and minimap.has_method("set_data"):
		minimap.set_data(_map_data)
	_refresh_food_lbl()

func _update_compass() -> void:
	if compass_needle == null:
		return
	var yaw: float = float(_map_data.get("player", {}).get("yaw", 0.0))
	# Needle rotates opposite camera so N stays world-north
	compass_needle.rotation = -yaw
	if compass_n:
		compass_n.rotation = -yaw
	_update_landmark_tick(yaw)

func _update_day_label() -> void:
	if day_lbl == null:
		return
	var phase: float = float(_map_data.get("day", 0.25))
	var inside: String = str(_map_data.get("inside", ""))
	var tod: String
	if inside != "":
		tod = "Indoors"
	elif phase < 0.2 or phase > 0.85:
		tod = "Night"
	elif phase < 0.35:
		tod = "Dawn"
	elif phase < 0.65:
		tod = "Day"
	else:
		tod = "Dusk"
	var weather: String = str(_map_data.get("weather", "Clear"))
	day_lbl.text = "%s · %s" % [tod, weather]
	if weather_btn:
		weather_btn.text = "Weather (R): %s" % weather

func _ensure_food_lbl() -> void:
	var top: HBoxContainer = $TopBar
	if top.get_node_or_null("FoodLbl") != null:
		food_lbl = top.get_node("FoodLbl")
		return
	food_lbl = Label.new()
	food_lbl.name = "FoodLbl"
	food_lbl.text = "Pantry —"
	food_lbl.custom_minimum_size = Vector2(220, 0)
	top.add_child(food_lbl)
	# Place right after HpBar
	var hp_i: int = hp_bar.get_index()
	top.move_child(food_lbl, hp_i + 1)

func _refresh_food_lbl() -> void:
	if food_lbl == null:
		_ensure_food_lbl()
	if food_lbl == null or not GameState.has_method("peek_best_consumable"):
		return
	var info: Dictionary = GameState.peek_best_consumable()
	var stacks: Array = info.get("stacks", [])
	var bits: PackedStringArray = []
	# Compact stack marks for unlocked foods (short names)
	for s in stacks:
		var nm: String = str(s.get("name", ""))
		var short := nm
		if "Bread" in nm:
			short = "Bread"
		elif "Water" in nm:
			short = "Water"
		elif "Trail" in nm:
			short = "Trail"
		elif "Honey" in nm:
			short = "Cake"
		elif "Stew" in nm:
			short = "Stew"
		bits.append("%s×%d" % [short, int(s.get("count", 0))])
	var stack_txt := " · ".join(bits) if bits.size() > 0 else "empty"
	var cd: float = float(info.get("cooldown", 0.0))
	var best: Dictionary = info.get("best", {})
	var next_txt := "—"
	if not best.is_empty():
		var bname: String = str(best.get("name", ""))
		if "Bread" in bname:
			bname = "Bread"
		elif "Water" in bname:
			bname = "Water"
		elif "Trail" in bname:
			bname = "Trail"
		elif "Honey" in bname:
			bname = "Cake"
		elif "Stew" in bname:
			bname = "Stew"
		next_txt = "%s +%d" % [bname, int(best.get("heal", 0))]
	# Wave 34: clearer food cooldown — Wait vs Ready (no cryptic CD)
	if cd > 0.05:
		food_lbl.text = "Pantry %s · Wait %.1fs · next V:%s" % [stack_txt, cd, next_txt]
		food_lbl.modulate = Color(1.0, 0.88, 0.55, 1.0)
	else:
		food_lbl.text = "Pantry %s · Ready · V:%s" % [stack_txt, next_txt]
		food_lbl.modulate = Color(0.85, 1.0, 0.85, 1.0)


func _ensure_hurt_vignette() -> void:
	## Soft screen-edge rose wash when HP is low — kid-friendly, no gore.
	if _hurt_vignette != null and is_instance_valid(_hurt_vignette):
		return
	_hurt_vignette = Control.new()
	_hurt_vignette.name = "HurtVignette"
	_hurt_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hurt_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hurt_vignette.z_index = -1
	add_child(_hurt_vignette)
	move_child(_hurt_vignette, 0)
	_vignette_edges.clear()
	# Explicit offsets — PRESET_*_WIDE alone can leave zero-thickness strips (v1.16 bugfix).
	var specs := [
		{"name": "Top", "preset": Control.PRESET_TOP_WIDE, "bottom": 56.0, "left": 0.0, "right": 0.0, "top": 0.0},
		{"name": "Bottom", "preset": Control.PRESET_BOTTOM_WIDE, "top": -56.0, "left": 0.0, "right": 0.0, "bottom": 0.0},
		{"name": "Left", "preset": Control.PRESET_LEFT_WIDE, "right": 48.0, "top": 0.0, "bottom": 0.0, "left": 0.0},
		{"name": "Right", "preset": Control.PRESET_RIGHT_WIDE, "left": -48.0, "top": 0.0, "bottom": 0.0, "right": 0.0},
	]
	for s in specs:
		var r := ColorRect.new()
		r.name = str(s["name"])
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.color = Color(0.72, 0.28, 0.32, 0.0)
		r.set_anchors_and_offsets_preset(int(s["preset"]))
		r.offset_left = float(s["left"])
		r.offset_top = float(s["top"])
		r.offset_right = float(s["right"])
		r.offset_bottom = float(s["bottom"])
		_hurt_vignette.add_child(r)
		_vignette_edges.append(r)


func _update_hurt_vignette(cur: int, mx: int) -> void:
	_ensure_hurt_vignette()
	if _hurt_vignette == null:
		return
	var ratio: float = 1.0
	if mx > 0:
		ratio = float(cur) / float(mx)
	# Fade in below ~45% HP; stronger under ~25%. Soft rose, never opaque.
	var alpha: float = 0.0
	if ratio < 0.45:
		alpha = clampf((0.45 - ratio) / 0.45, 0.0, 1.0) * 0.38
		if ratio < 0.25:
			alpha = clampf(alpha + (0.25 - ratio) * 0.55, 0.0, 0.52)
	for r in _vignette_edges:
		if r == null or not is_instance_valid(r):
			continue
		r.color = Color(0.78, 0.32, 0.36, alpha)
	_hurt_vignette.visible = alpha > 0.01



func _ensure_year_chip() -> void:
	## Compact year-progress chip near the day label (Wave 22; Wave 32 clearer plate).
	if _year_chip != null and is_instance_valid(_year_chip):
		return
	if has_node("YearChipPanel"):
		_year_chip_panel = $YearChipPanel
		_year_chip = _year_chip_panel.get_node_or_null("YearChip")
		if _year_chip != null:
			return
	if has_node("YearChip"):
		_year_chip = $YearChip
		return
	_year_chip_panel = PanelContainer.new()
	_year_chip_panel.name = "YearChipPanel"
	_year_chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_year_chip_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_year_chip_panel.offset_left = -196.0
	_year_chip_panel.offset_top = 74.0
	_year_chip_panel.offset_right = -12.0
	_year_chip_panel.offset_bottom = 108.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.18, 0.14, 0.72)
	style.border_color = Color(0.78, 0.86, 0.55, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_year_chip_panel.add_theme_stylebox_override("panel", style)
	_year_chip = Label.new()
	_year_chip.name = "YearChip"
	_year_chip.add_theme_font_size_override("font_size", 15)
	_year_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_year_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_year_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_year_chip.modulate = Color(0.94, 0.98, 0.82, 1.0)
	_year_chip_panel.add_child(_year_chip)
	add_child(_year_chip_panel)


func _refresh_year_chip() -> void:
	_ensure_year_chip()
	if _year_chip == null:
		return
	var pct := 0
	if GameState.has_method("get_year_progress_percent"):
		pct = int(GameState.get_year_progress_percent())
	elif GameState.has_method("get_quest_mastery_progress"):
		pct = int(GameState.get_quest_mastery_progress().get("percent", 0))
	# Wave 32: clearer wording so the chip reads at a glance
	_year_chip.text = "Year · %d%%" % pct
	_year_chip.tooltip_text = GameState.get_year_progress_note() if GameState.has_method("get_year_progress_note") else "Year progress"



func _ensure_mute_styles() -> void:
	## Warm amber plate when muted so the mute state reads at a glance (Wave 38).
	if _mute_style_on != null:
		return
	_mute_style_on = StyleBoxFlat.new()
	_mute_style_on.bg_color = Color(0.42, 0.28, 0.12, 0.92)
	_mute_style_on.border_color = Color(0.95, 0.78, 0.42, 0.95)
	_mute_style_on.set_border_width_all(2)
	_mute_style_on.set_corner_radius_all(6)
	_mute_style_on.content_margin_left = 8
	_mute_style_on.content_margin_right = 8
	_mute_style_on.content_margin_top = 3
	_mute_style_on.content_margin_bottom = 3
	_mute_style_off = StyleBoxFlat.new()
	_mute_style_off.bg_color = Color(0.16, 0.18, 0.16, 0.75)
	_mute_style_off.border_color = Color(0.55, 0.62, 0.50, 0.7)
	_mute_style_off.set_border_width_all(1)
	_mute_style_off.set_corner_radius_all(6)
	_mute_style_off.content_margin_left = 8
	_mute_style_off.content_margin_right = 8
	_mute_style_off.content_margin_top = 3
	_mute_style_off.content_margin_bottom = 3


func _ensure_save_chip() -> void:
	## Wave 38: show save-slot nickname on a soft HUD chip (PIN stays 1234; mastery ≥80%).
	if _save_chip != null and is_instance_valid(_save_chip):
		return
	if has_node("SaveChipPanel"):
		_save_chip_panel = $SaveChipPanel
		_save_chip = _save_chip_panel.get_node_or_null("SaveChip")
		if _save_chip != null:
			return
	_save_chip_panel = PanelContainer.new()
	_save_chip_panel.name = "SaveChipPanel"
	_save_chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_save_chip_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_save_chip_panel.offset_left = -196.0
	_save_chip_panel.offset_top = 112.0
	_save_chip_panel.offset_right = -12.0
	_save_chip_panel.offset_bottom = 144.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.16, 0.18, 0.72)
	style.border_color = Color(0.70, 0.82, 0.90, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_save_chip_panel.add_theme_stylebox_override("panel", style)
	_save_chip = Label.new()
	_save_chip.name = "SaveChip"
	_save_chip.add_theme_font_size_override("font_size", 14)
	_save_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_save_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_save_chip.modulate = Color(0.88, 0.94, 0.98, 1.0)
	_save_chip_panel.add_child(_save_chip)
	add_child(_save_chip_panel)


func _refresh_save_chip() -> void:
	_ensure_save_chip()
	if _save_chip == null:
		return
	var lab := str(GameState.slot_label).strip_edges()
	var slot_n: int = int(GameState.active_slot) + 1
	if lab != "":
		_save_chip.text = "Save · %s" % lab
		_save_chip.tooltip_text = "Slot %d nickname — rename from Saves" % slot_n
	else:
		_save_chip.text = "Save · Slot %d" % slot_n
		_save_chip.tooltip_text = "Slot %d — add a nickname in Saves" % slot_n


func _on_hurt_def_flash(_amount: int) -> void:
	## Wave 25 QoL: when soft armor is active, flash Def on the combat line after a hit.
	var def_n: int = 0
	if GameState.has_method("get_defense"):
		def_n = int(GameState.get_defense())
	if def_n <= 0:
		return
	_def_flash_active = true
	_def_flash_t = 1.35
	if combat_lbl:
		combat_lbl.text = "Combat Lv %d (%d XP) · Def %d softens the hit" % [GameState.combat_level, GameState.combat_xp, def_n]
		combat_lbl.modulate = Color(1.0, 0.92, 0.55, 1.0)


func _ensure_landmark_tick() -> void:
	## Soft gold tick on the compass ring pointing toward the nearest wilds landmark.
	if compass == null:
		return
	if _landmark_tick != null and is_instance_valid(_landmark_tick):
		return
	_landmark_tick = ColorRect.new()
	_landmark_tick.name = "LandmarkTick"
	_landmark_tick.color = Color(1.0, 0.85, 0.35, 0.95)
	_landmark_tick.size = Vector2(6, 10)
	_landmark_tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_landmark_tick.pivot_offset = Vector2(3, 28)
	compass.add_child(_landmark_tick)


func _update_landmark_tick(yaw: float) -> void:
	_ensure_landmark_tick()
	if _landmark_tick == null:
		return
	var px: float = float(_map_data.get("player", {}).get("x", 0))
	var pz: float = float(_map_data.get("player", {}).get("z", 0))
	var best_d := 1.0e9
	var best_ang := 0.0
	var found := false
	for h in _map_data.get("halls", []):
		# Prefer wilds/village landmarks (skip guild hall squares)
		var icon := str(h.get("icon", ""))
		if icon == "hall":
			continue
		var dx: float = float(h["x"]) - px
		var dz: float = float(h["z"]) - pz
		var d: float = sqrt(dx * dx + dz * dz)
		if d < 2.5:
			continue  # already here — look for next
		if d < best_d:
			best_d = d
			# 0 = world -Z (north), matching minimap forward
			best_ang = atan2(dx, -dz)
			found = true
	if not found or str(_map_data.get("inside", "")) != "":
		_landmark_tick.visible = false
		return
	_landmark_tick.visible = true
	var sz: Vector2 = compass.size
	var center := sz * 0.5
	# Screen angle: world bearing minus camera yaw
	var screen_ang: float = best_ang - yaw
	var ring_r: float = minf(sz.x, sz.y) * 0.42
	var tip: Vector2 = Vector2(0, -ring_r).rotated(screen_ang)
	_landmark_tick.position = center + tip - Vector2(3, 5)
	_landmark_tick.rotation = screen_ang
