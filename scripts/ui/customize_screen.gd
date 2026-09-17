extends Control

signal confirmed(p_name: String, appearance: Dictionary)
signal cancelled

@onready var name_edit: LineEdit = $Panel/VBox/NameEdit
@onready var skin_opt: OptionButton = $Panel/VBox/SkinOpt
@onready var hair_opt: OptionButton = $Panel/VBox/HairOpt
@onready var cape_opt: OptionButton = $Panel/VBox/CapeOpt
@onready var outfit_opt: OptionButton = $Panel/VBox/OutfitOpt
@onready var title_lbl: Label = $Panel/VBox/Title
@onready var ok_btn: Button = $Panel/VBox/OkBtn
@onready var cancel_btn: Button = $Panel/VBox/CancelBtn

var wardrobe_mode: bool = false

func _ready() -> void:
	_fill(skin_opt, ["fair","light","medium","tan","deep"])
	_fill(hair_opt, ["brown","black","blonde","auburn","gray"])
	_fill(cape_opt, ["crimson","azure","emerald","gold","violet"])
	_fill(outfit_opt, ["cream","sky","forest","sand","rose"])
	ok_btn.pressed.connect(_on_ok)
	cancel_btn.pressed.connect(func(): cancelled.emit())

func _fill(opt: OptionButton, keys: Array) -> void:
	opt.clear()
	for k in keys:
		opt.add_item(str(k).capitalize())
		opt.set_item_metadata(opt.item_count - 1, k)

func open_new() -> void:
	wardrobe_mode = false
	title_lbl.text = "Create Your Apprentice"
	name_edit.text = ""
	name_edit.editable = true
	_select(skin_opt, "medium")
	_select(hair_opt, "brown")
	_select(cape_opt, "crimson")
	_select(outfit_opt, "cream")

func open_wardrobe() -> void:
	wardrobe_mode = true
	title_lbl.text = "Wardrobe"
	name_edit.text = GameState.child_name
	name_edit.editable = true
	_select(skin_opt, GameState.appearance.get("skin", "medium"))
	_select(hair_opt, GameState.appearance.get("hair", "brown"))
	_select(cape_opt, GameState.appearance.get("cape_color", "crimson"))
	_select(outfit_opt, GameState.appearance.get("outfit", "cream"))

func _select(opt: OptionButton, key: String) -> void:
	for i in opt.item_count:
		if opt.get_item_metadata(i) == key:
			opt.select(i)
			return

func _on_ok() -> void:
	var app := {
		"skin": skin_opt.get_selected_metadata(),
		"hair": hair_opt.get_selected_metadata(),
		"cape_color": cape_opt.get_selected_metadata(),
		"outfit": outfit_opt.get_selected_metadata(),
	}
	confirmed.emit(name_edit.text.strip_edges(), app)
