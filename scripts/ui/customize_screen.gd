extends Control

signal confirmed(p_name: String, appearance: Dictionary)
signal cancelled

@onready var name_edit: LineEdit = $Panel/MainRow/ControlsCol/NameEdit
@onready var gender_opt: OptionButton = $Panel/MainRow/ControlsCol/GenderOpt
@onready var skin_opt: OptionButton = $Panel/MainRow/ControlsCol/SkinOpt
@onready var hair_opt: OptionButton = $Panel/MainRow/ControlsCol/HairOpt
@onready var hair_style_opt: OptionButton = $Panel/MainRow/ControlsCol/HairStyleOpt
@onready var facial_hair_opt: OptionButton = $Panel/MainRow/ControlsCol/FacialHairOpt
@onready var facial_hair_lbl: Label = $Panel/MainRow/ControlsCol/FacialHairLbl
@onready var cape_opt: OptionButton = $Panel/MainRow/ControlsCol/CapeOpt
@onready var outfit_opt: OptionButton = $Panel/MainRow/ControlsCol/OutfitOpt
@onready var title_lbl: Label = $Panel/MainRow/ControlsCol/Title
@onready var ok_btn: Button = $Panel/MainRow/ControlsCol/OkBtn
@onready var cancel_btn: Button = $Panel/MainRow/ControlsCol/CancelBtn
@onready var preview_host: SubViewportContainer = $Panel/MainRow/PreviewCol/PreviewHost
@onready var preview_viewport: SubViewport = $Panel/MainRow/PreviewCol/PreviewHost/SubViewport

var wardrobe_mode: bool = false
var _preview_row: HBoxContainer = null
var _preview_pulse_tw: Tween = null  # Wave 52: wardrobe color preview pulse
var _preview_parts: Dictionary = {}
var _preview_root: Node3D = null
var _preview_spin_t: float = 0.0  # oscillate so face stays readable while cape peeks

var _swatches: Dictionary = {}  # key -> ColorRect

const SKIN_COLORS := {
	"fair": Color("#ffe0bd"),
	"light": Color("#f1c27d"),
	"medium": Color("#c68642"),
	"tan": Color("#8d5524"),
	"deep": Color("#5c3317"),
}
const HAIR_COLORS := {
	"brown": Color("#5c4033"),
	"black": Color("#1a1a1a"),
	"blonde": Color("#d4a84b"),
	"auburn": Color("#8b3a2a"),
	"gray": Color("#8a8a8a"),
}
const CAPE_COLORS := {
	"crimson": Color("#c1121f"),
	"azure": Color("#1d7a9c"),
	"emerald": Color("#2d6a4f"),
	"gold": Color("#c9a227"),
	"violet": Color("#6a4c93"),
}
const OUTFIT_COLORS := {
	"cream": Color("#f4e4bc"),
	"sky": Color("#87b8d4"),
	"forest": Color("#4a7c59"),
	"sand": Color("#c2b280"),
	"rose": Color("#d4a0a0"),
}

const HAIR_STYLES := ["short", "neat", "spiky", "fringe", "wavy", "long", "ponytail", "bun"]
const FACIAL_HAIR_STYLES := ["none", "stubble", "mustache", "goatee", "beard"]

func _ready() -> void:
	_fill(gender_opt, ["boy", "girl"])
	_fill(skin_opt, ["fair","light","medium","tan","deep"])
	_fill(hair_opt, ["brown","black","blonde","auburn","gray"])
	_fill_pretty(hair_style_opt, HAIR_STYLES)
	_fill_pretty(facial_hair_opt, FACIAL_HAIR_STYLES)
	_fill(cape_opt, ["crimson","azure","emerald","gold","violet"])
	_fill(outfit_opt, ["cream","sky","forest","sand","rose"])
	ok_btn.pressed.connect(_on_ok)
	cancel_btn.pressed.connect(_on_cancel)
	gender_opt.item_selected.connect(func(_i): _on_gender_changed())
	skin_opt.item_selected.connect(func(_i): _refresh_preview())
	hair_opt.item_selected.connect(func(_i): _refresh_preview())
	hair_style_opt.item_selected.connect(func(_i): _refresh_preview())
	facial_hair_opt.item_selected.connect(func(_i): _refresh_preview())
	cape_opt.item_selected.connect(func(_i): _refresh_preview())
	outfit_opt.item_selected.connect(func(_i): _refresh_preview())
	_ensure_character_preview()
	_ensure_preview_row()
	_sync_facial_hair_enabled()

func _process(delta: float) -> void:
	## Gentle yaw sway — face stays kid-readable; cape still peeks on the turn.
	if not visible or _preview_root == null or not is_instance_valid(_preview_root):
		return
	_preview_spin_t += delta * 0.85
	_preview_root.rotation.y = 0.15 + sin(_preview_spin_t) * 0.55

func _fill(opt: OptionButton, keys: Array) -> void:
	opt.clear()
	for k in keys:
		opt.add_item(str(k).capitalize())
		opt.set_item_metadata(opt.item_count - 1, k)

func _fill_pretty(opt: OptionButton, keys: Array) -> void:
	## Keys like "ponytail" / "short_beard" → "Ponytail" / "Short Beard".
	opt.clear()
	for k in keys:
		var label := str(k).replace("_", " ").capitalize()
		opt.add_item(label)
		opt.set_item_metadata(opt.item_count - 1, k)

func _on_gender_changed() -> void:
	_sync_facial_hair_enabled()
	# Girls default toward longer hair if still on short; boys keep current style.
	var gender_k: String = str(gender_opt.get_selected_metadata())
	if gender_k == "girl":
		_select(facial_hair_opt, "none")
		if str(hair_style_opt.get_selected_metadata()) == "short":
			_select(hair_style_opt, "long")
	_refresh_preview()

func _sync_facial_hair_enabled() -> void:
	var is_boy := str(gender_opt.get_selected_metadata()) == "boy"
	if facial_hair_opt:
		facial_hair_opt.disabled = not is_boy
		facial_hair_opt.modulate = Color(1, 1, 1, 1) if is_boy else Color(1, 1, 1, 0.45)
	if facial_hair_lbl:
		facial_hair_lbl.modulate = Color(1, 1, 1, 1) if is_boy else Color(1, 1, 1, 0.55)

func open_new() -> void:
	wardrobe_mode = false
	title_lbl.text = "Create Your Apprentice"
	name_edit.text = ""
	name_edit.editable = true
	ok_btn.text = "Begin"
	var demo_gender := str(OS.get_environment("LUMEN_DEMO_GENDER")).to_lower()
	if demo_gender != "boy" and demo_gender != "girl":
		demo_gender = "boy"
	_select(gender_opt, demo_gender)
	_select(skin_opt, "medium")
	_select(hair_opt, "brown")
	_select(hair_style_opt, "long" if demo_gender == "girl" else "short")
	_select(facial_hair_opt, "none")
	_select(cape_opt, "crimson")
	_select(outfit_opt, "cream")
	_sync_facial_hair_enabled()
	_refresh_preview()

func open_wardrobe() -> void:
	wardrobe_mode = true
	title_lbl.text = "Wardrobe"
	name_edit.text = GameState.child_name
	name_edit.editable = true
	ok_btn.text = "Wear This Look"
	_select(gender_opt, GameState.appearance.get("gender", "boy"))
	_select(skin_opt, GameState.appearance.get("skin", "medium"))
	_select(hair_opt, GameState.appearance.get("hair", "brown"))
	_select(hair_style_opt, GameState.appearance.get("hair_style", "short"))
	_select(facial_hair_opt, GameState.appearance.get("facial_hair", "none"))
	_select(cape_opt, GameState.appearance.get("cape_color", "crimson"))
	_select(outfit_opt, GameState.appearance.get("outfit", "cream"))
	_sync_facial_hair_enabled()
	_refresh_preview()
	_play_wardrobe_flourish()  # Wave 34: soft open flourish

func _select(opt: OptionButton, key: String) -> void:
	for i in opt.item_count:
		if opt.get_item_metadata(i) == key:
			opt.select(i)
			return

func _ensure_character_preview() -> void:
	## Live 3D apprentice beside the color pickers (RuneScape-chunky, kid-readable).
	if preview_viewport == null:
		return
	if _preview_root != null and is_instance_valid(_preview_root):
		return
	# Clear any leftover scene children except we own the viewport empty
	for c in preview_viewport.get_children():
		preview_viewport.remove_child(c)
		c.free()

	preview_viewport.own_world_3d = true
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_viewport.transparent_bg = false
	# Size is owned by SubViewportContainer.stretch — do not set size manually.

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#2a3a2e")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.68)
	env.ambient_light_energy = 0.55
	world_env.environment = env
	preview_viewport.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-42, 35, 0)
	preview_viewport.add_child(sun)

	var fill := OmniLight3D.new()
	fill.light_color = Color(1.0, 0.95, 0.85)
	fill.light_energy = 0.55
	fill.omni_range = 8.0
	fill.position = Vector3(-1.2, 2.2, 2.4)
	preview_viewport.add_child(fill)

	# Soft podium so the figure grounds in the frame
	var podium := MeshInstance3D.new()
	podium.name = "Podium"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.62
	cyl.height = 0.08
	podium.mesh = cyl
	podium.position = Vector3(0, 0.04, 0)
	podium.material_override = HumanoidBuilder.make_mat(Color("#4a5c48"), 0.9)
	HeadlessGuard.guard_mesh(podium)
	preview_viewport.add_child(podium)

	_preview_root = Node3D.new()
	_preview_root.name = "PreviewCharacter"
	_preview_root.position = Vector3(0, 0.08, 0)
	preview_viewport.add_child(_preview_root)
	_preview_parts = HumanoidBuilder.build(_preview_root)

	var cam := Camera3D.new()
	cam.name = "PreviewCam"
	# Elevated oblique — same family as the in-world RuneScape camera
	cam.fov = 38.0
	preview_viewport.add_child(cam)
	cam.look_at_from_position(Vector3(0.55, 1.95, 2.85), Vector3(0, 1.15, 0))
	cam.current = true

	if preview_host:
		preview_host.stretch = true
		preview_host.custom_minimum_size = Vector2(240, 320)

func _ensure_preview_row() -> void:
	## Wave 25: chunky color swatches so wardrobe picks read before you confirm.
	if _preview_row != null and is_instance_valid(_preview_row):
		return
	var preview_col: VBoxContainer = $Panel/MainRow/PreviewCol
	_preview_row = HBoxContainer.new()
	_preview_row.name = "PreviewRow"
	_preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview_row.add_theme_constant_override("separation", 8)
	var note := Label.new()
	note.text = "Colors"
	note.modulate = Color(0.85, 0.88, 0.75, 1)
	_preview_row.add_child(note)
	for key in ["skin", "hair", "cape", "outfit"]:
		var wrap := VBoxContainer.new()
		wrap.alignment = BoxContainer.ALIGNMENT_CENTER
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(24, 24)
		sw.name = "Swatch_%s" % key
		var border := PanelContainer.new()
		border.custom_minimum_size = Vector2(28, 28)
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
		lbl.add_theme_font_size_override("font_size", 10)
		wrap.add_child(border)
		wrap.add_child(lbl)
		_preview_row.add_child(wrap)
		_swatches[key] = sw
	preview_col.add_child(_preview_row)

func _refresh_preview() -> void:
	_ensure_character_preview()
	_ensure_preview_row()
	if _swatches.is_empty():
		return
	var skin_k: String = str(skin_opt.get_selected_metadata())
	var hair_k: String = str(hair_opt.get_selected_metadata())
	var cape_k: String = str(cape_opt.get_selected_metadata())
	var outfit_k: String = str(outfit_opt.get_selected_metadata())
	var skin_c: Color = SKIN_COLORS.get(skin_k, Color.WHITE)
	var hair_c: Color = HAIR_COLORS.get(hair_k, Color.WHITE)
	var cape_c: Color = CAPE_COLORS.get(cape_k, Color.WHITE)
	var outfit_c: Color = OUTFIT_COLORS.get(outfit_k, Color.WHITE)
	_swatches["skin"].color = skin_c
	_swatches["hair"].color = hair_c
	_swatches["cape"].color = cape_c
	_swatches["outfit"].color = outfit_c
	var gender_k: String = str(gender_opt.get_selected_metadata())
	var style_k: String = str(hair_style_opt.get_selected_metadata())
	var face_k: String = str(facial_hair_opt.get_selected_metadata())
	_apply_preview_appearance(skin_c, hair_c, outfit_c, cape_c, gender_k, style_k, face_k)
	_play_wardrobe_preview_pulse()  # Wave 52: color preview pulse

func _apply_preview_appearance(
	skin: Color, hair: Color, outfit: Color, cape_col: Color,
	gender: String = "boy", hair_style: String = "short", facial_hair: String = "none"
) -> void:
	if _preview_parts.is_empty():
		return
	HumanoidBuilder.apply_human_colors(_preview_parts, skin, hair, outfit, cape_col)
	HumanoidBuilder.apply_gender(_preview_parts, gender)
	HumanoidBuilder.apply_hair_style(_preview_parts, hair_style)
	HumanoidBuilder.apply_facial_hair(_preview_parts, facial_hair, gender)
	var cape_mesh: MeshInstance3D = _preview_parts.get("cape")
	if cape_mesh:
		cape_mesh.visible = true
	# Wardrobe: mirror worn hat / weapon / accessory so the look matches the village avatar
	if wardrobe_mode:
		_apply_preview_equipment()
	else:
		_clear_preview_equipment()

func _clear_preview_equipment() -> void:
	for key in ["hat", "weapon", "accessory", "chest_plate", "l_pad", "r_pad"]:
		var n: Node = _preview_parts.get(key)
		if n:
			n.visible = false
	var jewel: MeshInstance3D = _preview_parts.get("hat_jewel")
	if jewel:
		jewel.visible = false

func _apply_preview_equipment() -> void:
	# Keep selected cape color as the wardrobe signal; still show soft armor if a defensive cape is worn
	var cape_id = GameState.equipped.get("cape")
	if cape_id != null:
		var citem: Dictionary = ItemDB.get_item(str(cape_id))
		if not citem.is_empty():
			HumanoidBuilder.style_armor(_preview_parts, citem)
			# Re-assert wardrobe cape color after armor styling
			var cape_k: String = str(cape_opt.get_selected_metadata())
			HumanoidBuilder.set_color(_preview_parts.get("cape"), CAPE_COLORS.get(cape_k, Color("#c1121f")))
	else:
		HumanoidBuilder.style_armor(_preview_parts, {})

	var weapon_root: Node3D = _preview_parts.get("weapon")
	var wid = GameState.equipped.get("weapon")
	if weapon_root:
		weapon_root.visible = wid != null
		if wid != null:
			HumanoidBuilder.style_weapon(_preview_parts, ItemDB.get_item(str(wid)))

	var hat_root: Node3D = _preview_parts.get("hat")
	var hid = GameState.equipped.get("head")
	if hat_root:
		if hid != null:
			HumanoidBuilder.style_hat(_preview_parts, ItemDB.get_item(str(hid)))
		else:
			hat_root.visible = false
			var jewel: MeshInstance3D = _preview_parts.get("hat_jewel")
			if jewel:
				jewel.visible = false

	var belt_mesh: MeshInstance3D = _preview_parts.get("belt")
	var bid = GameState.equipped.get("belt")
	if belt_mesh:
		belt_mesh.visible = true
		if bid != null:
			var bitem: Dictionary = ItemDB.get_item(str(bid))
			HumanoidBuilder.set_color(belt_mesh, Color(bitem.get("color", "#d4a017")))
		else:
			HumanoidBuilder.set_color(belt_mesh, Color("#5c3d24"))

	var acc_root: Node3D = _preview_parts.get("accessory")
	var aid = GameState.equipped.get("accessory")
	if acc_root:
		acc_root.visible = aid != null
		if aid != null:
			HumanoidBuilder.style_accessory(_preview_parts, ItemDB.get_item(str(aid)))

func _play_wardrobe_preview_pulse() -> void:
	## Wave 52: soft wardrobe color preview pulse — gentle cream scale bloom on swatches (RuneScape-chunky, wholesome).
	if _preview_row == null or not is_instance_valid(_preview_row):
		return
	if _preview_pulse_tw != null and is_instance_valid(_preview_pulse_tw):
		_preview_pulse_tw.kill()
	_preview_row.pivot_offset = _preview_row.size * 0.5
	_preview_row.scale = Vector2(1.06, 1.06)
	_preview_row.modulate = Color(1.08, 1.05, 0.92, 1.0)
	# Soft nudge on the 3D host too
	if preview_host != null and is_instance_valid(preview_host):
		preview_host.modulate = Color(1.06, 1.04, 0.94, 1.0)
	_preview_pulse_tw = create_tween()
	_preview_pulse_tw.set_parallel(true)
	_preview_pulse_tw.tween_property(_preview_row, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_preview_pulse_tw.tween_property(_preview_row, "modulate", Color(1, 1, 1, 1), 0.28)
	if preview_host != null and is_instance_valid(preview_host):
		_preview_pulse_tw.tween_property(preview_host, "modulate", Color(1, 1, 1, 1), 0.28)

func _on_ok() -> void:
	var app := {
		"gender": gender_opt.get_selected_metadata(),
		"skin": skin_opt.get_selected_metadata(),
		"hair": hair_opt.get_selected_metadata(),
		"hair_style": hair_style_opt.get_selected_metadata(),
		"facial_hair": facial_hair_opt.get_selected_metadata() if str(gender_opt.get_selected_metadata()) == "boy" else "none",
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
