extends Control

signal inventory_pressed
signal wardrobe_pressed
signal parent_pressed
signal journal_pressed
signal mute_pressed

@onready var name_lbl: Label = $TopBar/NameLbl
@onready var xp_lbl: Label = $TopBar/XpLbl
@onready var combat_lbl: Label = $TopBar/CombatLbl
@onready var hp_bar: ProgressBar = $TopBar/HpBar
@onready var lumen_lbl: Label = $TopBar/LumenLbl
@onready var inv_btn: Button = $BottomBar/InvBtn
@onready var look_btn: Button = $BottomBar/LookBtn
@onready var journal_btn: Button = $BottomBar/JournalBtn
@onready var mute_btn: Button = $BottomBar/MuteBtn
@onready var parent_btn: Button = $BottomBar/ParentBtn
@onready var hint_lbl: Label = $Hint

func _ready() -> void:
	inv_btn.pressed.connect(func(): AudioBus.play_ui(); inventory_pressed.emit())
	look_btn.pressed.connect(func(): AudioBus.play_ui(); wardrobe_pressed.emit())
	journal_btn.pressed.connect(func(): AudioBus.play_ui(); journal_pressed.emit())
	mute_btn.pressed.connect(func(): mute_pressed.emit())
	parent_btn.pressed.connect(func(): AudioBus.play_ui(); parent_pressed.emit())
	hint_lbl.text = "Click ground · WASD · Click NPC/enemy · Q/E camera · I inventory · J journal · C wardrobe · M mute · F talk"
	_refresh_mute_label()
	if not AudioBus.mute_changed.is_connected(_on_mute):
		AudioBus.mute_changed.connect(_on_mute)

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
