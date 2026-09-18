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
var _preview_pulse_tw: Tween = null  # Wave 52: wardrobe color preview pulse

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
	PanelChrome.apply_overlay(self)
	_fill(skin_opt, ["fair","light","medium","tan","deep"])
	_fill(hair_opt, ["brown","black","blonde","auburn","gray"])
	_fill(cape_opt, ["crimson","azure","emerald","gold","violet"])
	_fill(outfit_opt, ["cream","sky","forest","sand","rose"])
	ok_btn.pressed.connect(_on_ok)
	cancel_btn.pressed.connect(_on_cancel)
	skin_opt.item_selected.connect(func(_i): _refresh_preview())
	hair_opt.item_selected.connect(func(_i): _refresh_preview())
	cape_opt.item_selected.connect(func(_i): _refresh_preview())
	outfit_opt.item_selected.connect(func(_i): _refresh_preview())
	_ensure_preview_row()
	_ensure_first_hint()

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
	_ensure_first_hint()
	var hint: Label = get_node_or_null("Panel/VBox/FirstHint")
	if hint:
		hint.visible = true

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
	_play_wardrobe_flourish()  # Wave 34: soft open flourish
	var hint: Label = get_node_or_null("Panel/VBox/FirstHint")
	if hint:
		hint.visible = false

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
	_play_wardrobe_preview_pulse()  # Wave 52: color preview pulse

func _play_wardrobe_preview_pulse() -> void:
	## Wave 52: soft wardrobe color preview pulse — gentle cream scale bloom on swatches (RuneScape-chunky, wholesome).
	if _preview_row == null or not is_instance_valid(_preview_row):
		return
	if _preview_pulse_tw != null and is_instance_valid(_preview_pulse_tw):
		_preview_pulse_tw.kill()
	_preview_row.pivot_offset = _preview_row.size * 0.5
	_preview_row.scale = Vector2(1.06, 1.06)
	_preview_row.modulate = Color(1.08, 1.05, 0.92, 1.0)
	_preview_pulse_tw = create_tween()
	_preview_pulse_tw.set_parallel(true)
	_preview_pulse_tw.tween_property(_preview_row, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_preview_pulse_tw.tween_property(_preview_row, "modulate", Color(1, 1, 1, 1), 0.28)

func _on_ok() -> void:
	var app := {
		"skin": skin_opt.get_selected_metadata(),
		"hair": hair_opt.get_selected_metadata(),
		"cape_color": cape_opt.get_selected_metadata(),
		"outfit": outfit_opt.get_selected_metadata(),
	}
	if wardrobe_mode:
		_play_wardrobe_equip_sparkle()  # Wave 42: soft equip sparkle
		_play_wardrobe_close_flourish(func():
			confirmed.emit(name_edit.text.strip_edges(), app)
		)
	else:
		confirmed.emit(name_edit.text.strip_edges(), app)


func _on_cancel() -> void:
	if wardrobe_mode:
		_play_wardrobe_close_flourish(func(): cancelled.emit())
	else:
		cancelled.emit()


func _play_wardrobe_flourish() -> void:
	## Wave 34: soft wardrobe open flourish — gentle scale + fade (RuneScape-chunky, wholesome).
	var panel: Control = get_node_or_null("Panel")
	if panel == null:
		return
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate = Color(1, 1, 1, 0.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.18)

func _play_wardrobe_equip_sparkle() -> void:
	## Wave 42: soft cream/gold wardrobe equip sparkle over the panel (RuneScape-chunky, wholesome).
	## Wave 58: stronger wardrobe equip sparkle — more motes, brighter bloom, taller rise.
	var panel: Control = get_node_or_null("Panel")
	if panel == null:
		return
	var host := Control.new()
	host.name = "WardrobeEquipSparkle"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(host)
	# Soft cream flash plate behind motes
	var flash := ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.94, 0.78, 0.22)
	host.add_child(flash)
	var flash_tw := create_tween()
	flash_tw.tween_property(flash, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Soft rising sparkle motes as ColorRects
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var tw := create_tween()
	tw.set_parallel(true)
	for i in 24:
		var mote := ColorRect.new()
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sz := 8.0 if i % 3 != 0 else 11.0
		mote.custom_minimum_size = Vector2(sz, sz)
		mote.size = Vector2(sz, sz)
		var warm := Color(1.0, 0.94, 0.7, 1.0) if i % 2 == 0 else Color(0.98, 0.88, 0.55, 0.95)
		mote.color = warm
		var cx := panel.size.x * 0.5 + rng.randf_range(-110.0, 110.0)
		var cy := panel.size.y * 0.55 + rng.randf_range(-30.0, 50.0)
		mote.position = Vector2(cx, cy)
		host.add_child(mote)
		var rise := Vector2(cx + rng.randf_range(-40.0, 40.0), cy - rng.randf_range(90.0, 170.0))
		var dur := rng.randf_range(0.4, 0.65)
		tw.tween_property(mote, "position", rise, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(mote, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(mote, "scale", Vector2(0.35, 0.35), dur)
	get_tree().create_timer(0.85).timeout.connect(func():
		if is_instance_valid(host):
			host.queue_free()
	)

func _ensure_first_hint() -> void:
	var vbox: VBoxContainer = get_node_or_null("Panel/VBox")
	if vbox == null:
		return
	if vbox.get_node_or_null("FirstHint") != null:
		return
	var hint := Label.new()
	hint.name = "FirstHint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "After this you’ll stand by the fountain. Press J for Journal — it shows your next lesson. Talk to Steward Guide (gold hall) and press F."
	PanelChrome.style_muted(hint, 13)
	vbox.add_child(hint)
	var ok_n: Node = vbox.get_node_or_null("OkBtn")
	if ok_n:
		vbox.move_child(hint, ok_n.get_index())


func _play_wardrobe_close_flourish(done: Callable) -> void:
	## Wave 48: soft wardrobe close flourish — gentle scale down + fade (RuneScape-chunky, wholesome).
	var panel: Control = get_node_or_null("Panel")
	if panel == null:
		done.call()
		return
	panel.pivot_offset = panel.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.94, 0.94), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "modulate", Color(1, 1, 1, 0.0), 0.16)
	tw.chain().tween_callback(func():
		panel.scale = Vector2.ONE
		panel.modulate = Color(1, 1, 1, 1)
		done.call()
	)

