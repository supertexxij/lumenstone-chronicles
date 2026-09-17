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
var _vignette_edges: Array = []

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
	hint_lbl.text = "Click · WASD · Zoom · Q/E · I/J/C · V food · M mute · R weather · T travel · F talk · H fountain · N glade · B ridge · G garden · L lookout · K mill · O hollow · P willow · 1–5 halls"
	_refresh_mute_label()
	if not AudioBus.mute_changed.is_connected(_on_mute):
		AudioBus.mute_changed.connect(_on_mute)
	set_process(true)

func set_world(world: Node) -> void:
	_world = world

func _on_mute(_m: bool) -> void:
	_refresh_mute_label()

func _refresh_mute_label() -> void:
	mute_btn.text = "Unmute (M)" if GameState.muted else "Mute (M)"

func refresh() -> void:
	name_lbl.text = GameState.child_name
	xp_lbl.text = "XP %d · Lv %d · Wk %d" % [GameState.xp, GameState.level, GameState.unlocked_week]
	var def_n: int = 0
	if GameState.has_method("get_defense"):
		def_n = int(GameState.get_defense())
	if def_n > 0:
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

func set_hp(cur: int, mx: int) -> void:
	hp_bar.max_value = mx
	hp_bar.value = cur
	hp_bar.get_node("HpText").text = "%d / %d" % [cur, mx]
	_update_hurt_vignette(cur, mx)

func _process(_delta: float) -> void:
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
	if cd > 0.05:
		food_lbl.text = "Pantry %s · CD %.1fs · V:%s" % [stack_txt, cd, next_txt]
	else:
		food_lbl.text = "Pantry %s · V:%s" % [stack_txt, next_txt]


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
