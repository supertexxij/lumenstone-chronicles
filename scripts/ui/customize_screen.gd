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
var _preview_row: HBoxContainer = null
var _swatches: Dictionary = {}  # key -> ColorRect

const SKIN_COLORS := {
	"fair": Color("#f3d5b5"),
	"light": Color("#e0b48a"),
	"medium": Color("#c68642"),
	"tan": Color("#8d5524"),
	"deep": Color("#5c3317"),
}
const HAIR_COLORS := {
	"brown": Color("#5c4033"),
	"black": Color("#1a1a1e"),
	"blonde": Color("#d4b483"),
	"auburn": Color("#8a3a22"),
	"gray": Color("#9a9aa2"),
}
const CAPE_COLORS := {
	"crimson": Color("#c1121f"),
	"azure": Color("#2a6fbb"),
	"emerald": Color("#2d6a4f"),
	"gold": Color("#c9a227"),
	"violet": Color("#6a4c93"),
}
const OUTFIT_COLORS := {
	"cream": Color("#f5f0e1"),
	"sky": Color("#a8d4ea"),
	"forest": Color("#3d6b3d"),
	"sand": Color("#d4c4a0"),
	"rose": Color("#e8b4b8"),
}

func _ready() -> void:
	_fill(skin_opt, ["fair","light","medium","tan","deep"])
	_fill(hair_opt, ["brown","black","blonde","auburn","gray"])
	_fill(cape_opt, ["crimson","azure","emerald","gold","violet"])
	_fill(outfit_opt, ["cream","sky","forest","sand","rose"])
	ok_btn.pressed.connect(_on_ok)
	cancel_btn.pressed.connect(func(): cancelled.emit())
	skin_opt.item_selected.connect(func(_i): _refresh_preview())
	hair_opt.item_selected.connect(func(_i): _refresh_preview())
	cape_opt.item_selected.connect(func(_i): _refresh_preview())
	outfit_opt.item_selected.connect(func(_i): _refresh_preview())
	_ensure_preview_row()

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
	_refresh_preview()

func open_wardrobe() -> void:
	wardrobe_mode = true
	title_lbl.text = "Wardrobe"
	name_edit.text = GameState.child_name
	name_edit.editable = true
	_select(skin_opt, GameState.appearance.get("skin", "medium"))
	_select(hair_opt, GameState.appearance.get("hair", "brown"))
	_select(cape_opt, GameState.appearance.get("cape_color", "crimson"))
	_select(outfit_opt, GameState.appearance.get("outfit", "cream"))
	_refresh_preview()

func _select(opt: OptionButton, key: String) -> void:
	for i in opt.item_count:
		if opt.get_item_metadata(i) == key:
			opt.select(i)
			return

func _ensure_preview_row() -> void:
	## Wave 25: chunky color swatches so wardrobe picks read before you confirm.
	if _preview_row != null and is_instance_valid(_preview_row):
		return
	var vbox: VBoxContainer = $Panel/VBox
	_preview_row = HBoxContainer.new()
	_preview_row.name = "PreviewRow"
	_preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview_row.add_theme_constant_override("separation", 10)
	var note := Label.new()
	note.text = "Preview"
	note.modulate = Color(0.85, 0.88, 0.75, 1)
	_preview_row.add_child(note)
	for key in ["skin", "hair", "cape", "outfit"]:
		var wrap := VBoxContainer.new()
		wrap.alignment = BoxContainer.ALIGNMENT_CENTER
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(28, 28)
		sw.name = "Swatch_%s" % key
		var border := PanelContainer.new()
		border.custom_minimum_size = Vector2(32, 32)
		var inner := MarginContainer.new()
		inner.add_theme_constant_override("margin_left", 2)
		inner.add_theme_constant_override("margin_top", 2)
		inner.add_theme_constant_override("margin_right", 2)
		inner.add_theme_constant_override("margin_bottom", 2)
		border.add_child(inner)
		inner.add_child(sw)
		var lbl := Label.new()
		lbl.text = key.capitalize()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		wrap.add_child(border)
		wrap.add_child(lbl)
		_preview_row.add_child(wrap)
		_swatches[key] = sw
	# Place above Ok button
	var ok_i: int = ok_btn.get_index()
	vbox.add_child(_preview_row)
	vbox.move_child(_preview_row, ok_i)

func _refresh_preview() -> void:
	_ensure_preview_row()
	if _swatches.is_empty():
		return
	var skin_k: String = str(skin_opt.get_selected_metadata())
	var hair_k: String = str(hair_opt.get_selected_metadata())
	var cape_k: String = str(cape_opt.get_selected_metadata())
	var outfit_k: String = str(outfit_opt.get_selected_metadata())
	_swatches["skin"].color = SKIN_COLORS.get(skin_k, Color.WHITE)
	_swatches["hair"].color = HAIR_COLORS.get(hair_k, Color.WHITE)
	_swatches["cape"].color = CAPE_COLORS.get(cape_k, Color.WHITE)
	_swatches["outfit"].color = OUTFIT_COLORS.get(outfit_k, Color.WHITE)

func _on_ok() -> void:
	var app := {
		"skin": skin_opt.get_selected_metadata(),
		"hair": hair_opt.get_selected_metadata(),
		"cape_color": cape_opt.get_selected_metadata(),
		"outfit": outfit_opt.get_selected_metadata(),
	}
	confirmed.emit(name_edit.text.strip_edges(), app)
