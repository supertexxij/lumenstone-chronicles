extends Control

signal confirmed(p_name: String, appearance: Dictionary)
signal cancelled

@onready var name_edit: LineEdit = $Panel/RootHBox/OptionsScroll/VBox/NameEdit
@onready var gender_prev: Button = $Panel/RootHBox/OptionsScroll/VBox/GenderRow/GenderPrev
@onready var gender_next: Button = $Panel/RootHBox/OptionsScroll/VBox/GenderRow/GenderNext
@onready var gender_value: Label = $Panel/RootHBox/OptionsScroll/VBox/GenderRow/GenderValue
@onready var hair_style_prev: Button = $Panel/RootHBox/OptionsScroll/VBox/HairStyleRow/HairStylePrev
@onready var hair_style_next: Button = $Panel/RootHBox/OptionsScroll/VBox/HairStyleRow/HairStyleNext
@onready var hair_style_value: Label = $Panel/RootHBox/OptionsScroll/VBox/HairStyleRow/HairStyleValue
@onready var skin_opt: OptionButton = $Panel/RootHBox/OptionsScroll/VBox/SkinOpt
@onready var hair_opt: OptionButton = $Panel/RootHBox/OptionsScroll/VBox/HairOpt
@onready var cape_opt: OptionButton = $Panel/RootHBox/OptionsScroll/VBox/CapeOpt
@onready var outfit_opt: OptionButton = $Panel/RootHBox/OptionsScroll/VBox/OutfitOpt
@onready var title_lbl: Label = $Panel/RootHBox/OptionsScroll/VBox/Title
@onready var ok_btn: Button = $Panel/RootHBox/OptionsScroll/VBox/OkBtn
@onready var cancel_btn: Button = $Panel/RootHBox/OptionsScroll/VBox/CancelBtn

var wardrobe_mode: bool = false
var _preview_row: HBoxContainer = null
var _preview_pulse_tw: Tween = null  # Wave 52: wardrobe color preview pulse

var _swatches: Dictionary = {}  # key -> ColorRect
var _gender_idx: int = 0
var _hair_style_idx: int = 0

## Live 3D apprentice preview (SubViewport).
var _preview_host: PanelContainer = null
var _preview_viewport: SubViewport = null
var _preview_root: Node3D = null
var _preview_bob: Node3D = null
var _preview_parts: Dictionary = {}
var _preview_yaw: float = 0.0

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

const GENDER_KEYS := ["boy", "girl"]
const GENDER_LABELS := {"boy": "Boy", "girl": "Girl"}
const HAIR_STYLE_KEYS := ["short", "tidy", "long", "bun", "pony", "spiky"]
const HAIR_STYLE_LABELS := {
	"short": "Short",
	"tidy": "Tidy",
	"long": "Long",
	"bun": "Bun",
	"pony": "Ponytail",
	"spiky": "Spiky",
}


func _ready() -> void:
	z_index = 40  # Draw above HUD so wardrobe is not covered
	mouse_filter = Control.MOUSE_FILTER_STOP
	PanelChrome.apply_overlay(self)
	_ensure_preview_host()
	_fill(skin_opt, ["fair", "light", "medium", "tan", "deep"])
	_fill(hair_opt, ["brown", "black", "blonde", "auburn", "gray"])
	_fill(cape_opt, ["crimson", "azure", "emerald", "gold", "violet"])
	_fill(outfit_opt, ["cream", "sky", "forest", "sand", "rose"])
	ok_btn.pressed.connect(_on_ok)
	cancel_btn.pressed.connect(_on_cancel)
	gender_prev.pressed.connect(func(): _cycle_gender(-1))
	gender_next.pressed.connect(func(): _cycle_gender(1))
	hair_style_prev.pressed.connect(func(): _cycle_hair_style(-1))
	hair_style_next.pressed.connect(func(): _cycle_hair_style(1))
	PanelChrome.style_button(gender_prev, false)
	PanelChrome.style_button(gender_next, false)
	PanelChrome.style_button(hair_style_prev, false)
	PanelChrome.style_button(hair_style_next, false)
	skin_opt.item_selected.connect(func(_i): _refresh_preview())
	hair_opt.item_selected.connect(func(_i): _refresh_preview())
	cape_opt.item_selected.connect(func(_i): _refresh_preview())
	outfit_opt.item_selected.connect(func(_i): _refresh_preview())
	_ensure_preview_row()
	_ensure_first_hint()
	_build_character_preview()
	_sync_cycle_labels()
	_refresh_preview()
	set_process(false)


func _process(delta: float) -> void:
	## Gentle turntable so gender / hair styles read from more than one angle.
	if not visible or _preview_bob == null or not is_instance_valid(_preview_bob):
		return
	_preview_yaw += delta * 0.55
	_preview_bob.rotation.y = _preview_yaw


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(visible)
		if visible and _preview_viewport:
			_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		elif _preview_viewport:
			_preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _fill(opt: OptionButton, keys: Array) -> void:
	opt.clear()
	for k in keys:
		opt.add_item(str(k).capitalize())
		opt.set_item_metadata(opt.item_count - 1, k)


func _cycle_gender(dir: int) -> void:
	AudioBus.play_ui()
	_gender_idx = (_gender_idx + dir) % GENDER_KEYS.size()
	if _gender_idx < 0:
		_gender_idx = GENDER_KEYS.size() - 1
	_sync_cycle_labels()
	_refresh_preview()


func _cycle_hair_style(dir: int) -> void:
	AudioBus.play_ui()
	_hair_style_idx = (_hair_style_idx + dir) % HAIR_STYLE_KEYS.size()
	if _hair_style_idx < 0:
		_hair_style_idx = HAIR_STYLE_KEYS.size() - 1
	_sync_cycle_labels()
	_refresh_preview()


func _sync_cycle_labels() -> void:
	var gkey: String = str(GENDER_KEYS[_gender_idx])
	gender_value.text = str(GENDER_LABELS.get(gkey, gkey.capitalize()))
	var hkey: String = str(HAIR_STYLE_KEYS[_hair_style_idx])
	hair_style_value.text = str(HAIR_STYLE_LABELS.get(hkey, hkey.capitalize()))


func _set_gender_key(key: String) -> void:
	var k := str(key).to_lower()
	var idx := GENDER_KEYS.find(k)
	_gender_idx = idx if idx >= 0 else 0
	_sync_cycle_labels()


func _set_hair_style_key(key: String) -> void:
	var k := str(key).to_lower()
	var idx := HAIR_STYLE_KEYS.find(k)
	_hair_style_idx = idx if idx >= 0 else 0
	_sync_cycle_labels()


func open_new() -> void:
	wardrobe_mode = false
	title_lbl.text = "Create Your Apprentice"
	name_edit.text = ""
	name_edit.editable = true
	_set_gender_key("boy")
	_set_hair_style_key("short")
	_select(skin_opt, "medium")
	_select(hair_opt, "brown")
	_select(cape_opt, "crimson")
	_select(outfit_opt, "cream")
	_preview_yaw = 0.0
	_refresh_preview()
	_ensure_first_hint()
	var hint: Label = get_node_or_null("Panel/RootHBox/OptionsScroll/VBox/FirstHint")
	if hint:
		hint.visible = true


func open_wardrobe() -> void:
	wardrobe_mode = true
	title_lbl.text = "Wardrobe"
	name_edit.text = GameState.child_name
	name_edit.editable = true
	GameState.normalize_appearance()
	_set_gender_key(str(GameState.appearance.get("gender", "boy")))
	_set_hair_style_key(str(GameState.appearance.get("hair_style", "short")))
	_select(skin_opt, GameState.appearance.get("skin", "medium"))
	_select(hair_opt, GameState.appearance.get("hair", "brown"))
	_select(cape_opt, GameState.appearance.get("cape_color", "crimson"))
	_select(outfit_opt, GameState.appearance.get("outfit", "cream"))
	_preview_yaw = 0.0
	_refresh_preview()
	_play_wardrobe_flourish()  # Wave 34: soft open flourish
	var hint: Label = get_node_or_null("Panel/RootHBox/OptionsScroll/VBox/FirstHint")
	if hint:
		hint.visible = false


func _select(opt: OptionButton, key: String) -> void:
	for i in opt.item_count:
		if opt.get_item_metadata(i) == key:
			opt.select(i)
			return


func _ensure_preview_host() -> void:
	var panel: PanelContainer = $Panel
	var root: HBoxContainer = panel.get_node_or_null("RootHBox")
	if root == null:
		return
	_preview_host = root.get_node_or_null("PreviewHost") as PanelContainer
	if _preview_host != null:
		return
	_preview_host = PanelContainer.new()
	_preview_host.name = "PreviewHost"
	# Fixed portrait card — do not stretch to the tall options column.
	_preview_host.custom_minimum_size = Vector2(230, 380)
	_preview_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_preview_host.clip_contents = false
	PanelChrome.apply_card(_preview_host)
	root.add_child(_preview_host)
	root.move_child(_preview_host, 0)


func _build_character_preview() -> void:
	_ensure_preview_host()
	if _preview_host == null:
		return
	# Clear prior preview children (rebuild-safe).
	for c in _preview_host.get_children():
		_preview_host.remove_child(c)
		c.free()
	_preview_parts = {}
	_preview_bob = null
	_preview_root = null
	_preview_viewport = null

	var caption := Label.new()
	caption.text = "Your apprentice"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PanelChrome.style_muted(caption, 12)

	# Keep the SubViewport off the Control layout tree so a TextureRect can
	# show the full portrait without SubViewportContainer clipping the boots.
	_preview_viewport = SubViewport.new()
	_preview_viewport.name = "CharacterPreview"
	_preview_viewport.size = Vector2i(200, 320)
	_preview_viewport.transparent_bg = true
	_preview_viewport.handle_input_locally = false
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_preview_viewport)

	var world := Node3D.new()
	world.name = "PreviewWorld"
	_preview_viewport.add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, 28, 0)
	light.light_energy = 1.15
	light.shadow_enabled = false
	world.add_child(light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.2, 2.0, 1.6)
	fill.light_color = Color(1.0, 0.95, 0.85)
	fill.light_energy = 0.55
	fill.omni_range = 6.0
	world.add_child(fill)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = 2.95
	cam.near = 0.05
	cam.far = 40.0
	cam.current = true
	world.add_child(cam)
	cam.position = Vector3(0.0, 1.05, 6.0)
	cam.rotation_degrees = Vector3(0.0, 0.0, 0.0)

	_preview_root = Node3D.new()
	_preview_root.name = "PreviewMesh"
	# Raise into the portrait center so boots clear the card border.
	_preview_root.position = Vector3(0, 0.85, 0)
	_preview_root.scale = Vector3(0.42, 0.42, 0.42)
	world.add_child(_preview_root)
	_preview_parts = HumanoidBuilder.build(_preview_root)
	_preview_bob = _preview_parts.get("bob") as Node3D

	var ground := MeshInstance3D.new()
	ground.name = "PreviewGround"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.65
	disc.bottom_radius = 0.65
	disc.height = 0.04
	ground.mesh = disc
	ground.position = Vector3(0, -0.20, 0)  # below boot soles (~-0.10) so feet sit on top
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.48, 0.42, 0.30, 1.0)
	gmat.roughness = 0.95
	ground.material_override = gmat
	HeadlessGuard.guard_mesh(ground)
	_preview_root.add_child(ground)

	var tr := TextureRect.new()
	tr.name = "PreviewTexture"
	tr.custom_minimum_size = Vector2(200, 320)
	tr.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.texture = _preview_viewport.get_texture()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.add_child(caption)
	col.add_child(tr)
	_preview_host.clip_contents = false
	_preview_host.add_child(col)
	call_deferred("_finalize_preview_camera", cam)


func _finalize_preview_camera(cam: Camera3D) -> void:
	## Re-assert ortho framing after SubViewport enters the scene tree.
	if cam == null or not is_instance_valid(cam):
		return
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = 2.95
	cam.position = Vector3(0.0, 1.05, 6.0)
	cam.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	cam.current = true
	if _preview_viewport:
		_preview_viewport.size = Vector2i(200, 320)
		_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _current_appearance() -> Dictionary:
	return {
		"gender": GENDER_KEYS[_gender_idx],
		"hair_style": HAIR_STYLE_KEYS[_hair_style_idx],
		"skin": skin_opt.get_selected_metadata(),
		"hair": hair_opt.get_selected_metadata(),
		"cape_color": cape_opt.get_selected_metadata(),
		"outfit": outfit_opt.get_selected_metadata(),
	}


func _ensure_preview_row() -> void:
	## Wave 25: chunky color swatches so wardrobe picks read before you confirm.
	if _preview_row != null and is_instance_valid(_preview_row):
		return
	var vbox: VBoxContainer = $Panel/RootHBox/OptionsScroll/VBox
	_preview_row = HBoxContainer.new()
	_preview_row.name = "PreviewRow"
	_preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview_row.add_theme_constant_override("separation", 10)
	var note := Label.new()
	note.text = "Colors"
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
	var app := _current_appearance()
	var skin_k: String = str(app.get("skin", "medium"))
	var hair_k: String = str(app.get("hair", "brown"))
	var cape_k: String = str(app.get("cape_color", "crimson"))
	var outfit_k: String = str(app.get("outfit", "cream"))
	_swatches["skin"].color = SKIN_COLORS.get(skin_k, Color.WHITE)
	_swatches["hair"].color = HAIR_COLORS.get(hair_k, Color.WHITE)
	_swatches["cape"].color = CAPE_COLORS.get(cape_k, Color.WHITE)
	_swatches["outfit"].color = OUTFIT_COLORS.get(outfit_k, Color.WHITE)
	_apply_preview_mesh(app)
	_play_wardrobe_preview_pulse()  # Wave 52: color preview pulse


func _apply_preview_mesh(app: Dictionary) -> void:
	if _preview_parts.is_empty():
		return
	var skin: Color = SKIN_COLORS.get(str(app.get("skin", "medium")), Color("#c68642"))
	var hair: Color = HAIR_COLORS.get(str(app.get("hair", "brown")), Color("#5c4033"))
	var outfit: Color = OUTFIT_COLORS.get(str(app.get("outfit", "cream")), Color("#f5f0e1"))
	var cape_col: Color = CAPE_COLORS.get(str(app.get("cape_color", "crimson")), Color("#c1121f"))
	HumanoidBuilder.apply_human_colors(_preview_parts, skin, hair, outfit, cape_col)
	HumanoidBuilder.apply_gender(_preview_parts, str(app.get("gender", "boy")))
	HumanoidBuilder.apply_hair_style(_preview_parts, str(app.get("hair_style", "short")))
	var cape_mesh: MeshInstance3D = _preview_parts.get("cape")
	if cape_mesh:
		cape_mesh.visible = true


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
	var app := _current_appearance()
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
	var vbox: VBoxContainer = get_node_or_null("Panel/RootHBox/OptionsScroll/VBox")
	if vbox == null:
		return
	if vbox.get_node_or_null("FirstHint") != null:
		return
	var hint := Label.new()
	hint.name = "FirstHint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "Next: stand by the fountain, press J for Journal, then talk to Steward Guide (gold hall) with F."
	PanelChrome.style_muted(hint, 12)
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
