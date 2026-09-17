extends Control

signal inventory_pressed
signal wardrobe_pressed
signal parent_pressed

@onready var name_lbl: Label = $TopBar/NameLbl
@onready var xp_lbl: Label = $TopBar/XpLbl
@onready var combat_lbl: Label = $TopBar/CombatLbl
@onready var hp_bar: ProgressBar = $TopBar/HpBar
@onready var lumen_lbl: Label = $TopBar/LumenLbl
@onready var inv_btn: Button = $BottomBar/InvBtn
@onready var look_btn: Button = $BottomBar/LookBtn
@onready var parent_btn: Button = $BottomBar/ParentBtn
@onready var hint_lbl: Label = $Hint

func _ready() -> void:
	inv_btn.pressed.connect(func(): inventory_pressed.emit())
	look_btn.pressed.connect(func(): wardrobe_pressed.emit())
	parent_btn.pressed.connect(func(): parent_pressed.emit())
	hint_lbl.text = "Click ground · WASD · Click NPC/enemy · Q/E camera · I inventory · C wardrobe · F talk"

func refresh() -> void:
	name_lbl.text = GameState.child_name
	xp_lbl.text = "XP %d · Lv %d" % [GameState.xp, GameState.level]
	combat_lbl.text = "Combat Lv %d (%d XP)" % [GameState.combat_level, GameState.combat_xp]
	var parts: PackedStringArray = []
	for g in ["math","la","science","history","bible"]:
		parts.append("%s:%d" % [GameState.GUILDS[g]["lumen"], GameState.lumens.get(g, 0)])
	lumen_lbl.text = " · ".join(parts)
	set_hp(GameState.hp, GameState.max_hp)

func set_hp(cur: int, mx: int) -> void:
	hp_bar.max_value = mx
	hp_bar.value = cur
	hp_bar.get_node("HpText").text = "%d / %d" % [cur, mx]
