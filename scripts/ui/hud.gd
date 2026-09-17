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
	hint_lbl.text = "Click · WASD · Zoom · Q/E · I/J/C · V food · M mute · R weather · T travel · F talk · H fountain · N glade · B ridge · G garden · L lookout · K mill · 1–5 halls"
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
	combat_lbl.text = "Combat Lv %d (%d XP)" % [GameState.combat_level, GameState.combat_xp]
	var parts: PackedStringArray = []
	for g in ["math","la","science","history","bible"]:
		parts.append("%s:%d" % [GameState.GUILDS[g]["lumen"], GameState.lumens.get(g, 0)])
	lumen_lbl.text = " · ".join(parts)
	set_hp(GameState.hp, GameState.max_hp)
	_refresh_mute_label()

func set_hp(cur: int, mx: int) -> void:
	hp_bar.max_value = mx
	hp_bar.value = cur
	hp_bar.get_node("HpText").text = "%d / %d" % [cur, mx]

func _process(_delta: float) -> void:
	if not visible or _world == null:
		return
	if _world.has_method("get_minimap_markers"):
		_map_data = _world.get_minimap_markers()
	_update_compass()
	_update_day_label()
	if minimap and minimap.has_method("set_data"):
		minimap.set_data(_map_data)

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

