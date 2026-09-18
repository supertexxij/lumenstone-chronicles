extends Node3D
## Builds village + guild halls + props + NPCs + enemy spawns from world.json
## Dense RuneScape-like green with performance-minded prop budgets (llvmpipe OK).

const PlayerScene := preload("res://scenes/player/player.tscn")
const EnemyScene := preload("res://scenes/world/enemy.tscn")
const NpcScene := preload("res://scenes/world/npc.tscn")

@onready var entities: Node3D = $Entities
@onready var static_world: Node3D = $StaticWorld

var player: CharacterBody3D
var world_data: Dictionary = {}

## Shared materials to cut draw-state churn on low-end / llvmpipe
var _mats: Dictionary = {}

## Day–night cycle (subtle; readable at night)
var _day_phase: float = 0.22  # start late morning
var _day_seconds: float = 360.0  # full day ~6 minutes
var _sun: DirectionalLight3D
var _env: Environment
var _interior_root: Node3D
var _outdoor_return: Vector3 = Vector3(0, 0, 10)
var _inside_hall: String = ""
var _door_cooldown: float = 0.0
var _door_glow_mats: Array = []  # Wave 27: pulsing hall Enter glows
var _village_lamp_lights: Array = []  # Wave 28: dusk OmniLights on village lamp posts
var _plaza_campfire_light: OmniLight3D = null  # Wave 31: soft campfire glow near plaza
var _plaza_campfire_pos: Vector3 = Vector3(6.8, 0, 9.2)  # Wave 33: crackle proximity
var _rain_splash: CPUParticles3D  # Wave 28: soft ground splash while raining
var _fog_mist: CPUParticles3D  # Wave 29: denser low mist cue while foggy
var _edge_fog_banks: Array = []  # Wave 46: soft fog banks at outdoor edges
var _wind_leaves: CPUParticles3D  # Wave 30: soft wind-blown leaf flakes outdoors
var _maple_leaves: CPUParticles3D  # Wave 56: denser soft leaf fall at Maple Copse
var _reed_sway_nodes: Array = []  # Wave 57: soft reed sway near Reed Pool
var _thistle_sway_nodes: Array = []  # Wave 58: soft thistle sway at Thistle Rise
var _willow_sway_nodes: Array = []  # Wave 61: soft willow weep sway at Willow Bend
var _fern_sway_nodes: Array = []  # Wave 62: soft fern sway at Fern Dell
var _heather_sway_nodes: Array = []  # Wave 63: soft heather sway at Heather Heath
var _hall_light_dip_t: float = 0.0  # Wave 63: soft hall enter/exit light dip
var _knoll_dusk_lights: Array = []  # Wave 59: soft amber knoll glow at dusk
var _arch_dusk_lights: Array = []  # Wave 64: soft stone arch glow at dusk
var _cross_dusk_lights: Array = []  # Wave 65: soft quiet cross lantern at dusk
var _dusk_fireflies: CPUParticles3D  # Wave 39: soft firefly sparkles at dusk outdoors
var _garden_fireflies: CPUParticles3D  # Wave 53: denser fireflies near Prayer Garden at dusk
var _birch_fireflies: CPUParticles3D  # Wave 66: soft birch-rest firefly wink at dusk
var _reed_pool_gleam: CPUParticles3D  # Wave 67: soft Reed Pool ripple gleam at dusk
var _willow_leaves: CPUParticles3D  # Wave 68: soft Willow Bend willow-leaf drift at dusk
var _fern_fronds: CPUParticles3D  # Wave 69: soft Fern Dell fern-frond drift at dusk
var _heather_blooms: CPUParticles3D  # Wave 70: soft Heather Heath heather-bloom drift at dusk
var _thistle_blooms: CPUParticles3D  # Wave 71: soft Thistle Rise thistle-bloom drift at dusk
var _maple_dusk_leaves: CPUParticles3D  # Wave 72: soft Maple Copse maple-leaf drift at dusk
var _amber_knoll_motes: CPUParticles3D  # Wave 73: soft Amber Knoll amber-glow motes at dusk
var _cedar_needles: CPUParticles3D  # Wave 74: soft Cedar Hollow cedar-needle drift at dusk
var _stone_arch_dust: CPUParticles3D  # Wave 75: soft Stone Arch limestone dust motes at dusk
var _cross_lantern_moths: CPUParticles3D  # Wave 76: soft Quiet Cross lantern moths at dusk
var _landmark_dist: float = 9999.0  # Wave 69: distance to current landmark for ✦ chip paces
var _brook_sparkle: CPUParticles3D  # Wave 54: soft brook sparkle near water
var _brook_sparkle_check_t: float = 0.0
var _snowdust: CPUParticles3D  # Wave 47: soft snowdust particles in cold fog outdoors
var _canopy_drip: CPUParticles3D  # Wave 48: soft rain canopy drip under trees outdoors
var _eaves_splash: CPUParticles3D  # Wave 51: soft rain splash on hall outdoor eaves
var _hall_eaves: Array = []  # Wave 51: roof-eave world positions for rain splash
var _puddle_ripples: CPUParticles3D  # Wave 41: soft rain puddle ripples on ground
var _tree_positions: Array = []  # Wave 37: leaf rustle proximity
var _leaf_check_t: float = 0.0
var _water_positions: Array = []  # Wave 38: brook murmur proximity
var _brook_check_t: float = 0.0
var _wind_chime_check_t: float = 0.0  # Wave 52: soft wind chime near halls
var _weather_mode: int = 0  # 0 clear, 1 fog, 2 rain
var _weather_timer: float = 90.0
var _weather_auto: bool = true
var _rain: CPUParticles3D
var _clouds: CPUParticles3D
var _fog_boost: float = 0.0
var _weather_label_cache: String = "Clear"
var _landmark_here: String = ""  # current approach zone id (hysteresis)
var _landmark_toast_cd: float = 0.0
var _ambient_critters: Array = []  # {node, base: Vector3, phase, kind}
var _fountain_root: Node3D = null  # Wave 24 soft-defeat fountain FX anchor
var _fountain_mist: CPUParticles3D = null  # Wave 50: soft plaza fountain mist polish

signal npc_talk(npc: Node)
signal weather_changed(mode: int, label: String)

func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://data/world.json", FileAccess.READ)
	if f:
		world_data = JSON.parse_string(f.get_as_text())
		f.close()
	_init_mats()
	_build_ground()
	_build_paths()
	_build_buildings()
	_build_trees()
	_build_wilds()
	_build_fountain()
	_build_village_props()
	_build_plaza_campfire()
	_spawn_npcs()
	_spawn_enemies()
	_spawn_player()
	_build_interiors()
	_build_lantern_glade()
	_build_pine_ridge()
	_build_prayer_garden()
	_build_lookout_rock()
	_build_mill_bridge()
	_build_cedar_hollow()
	_build_willow_bend()
	_build_reed_pool()
	_build_quiet_cross()
	_build_stone_arch()
	_build_amber_knoll()
	_build_birch_rest()
	_build_fern_dell()
	_build_heather_heath()
	_build_thistle_rise()
	_build_maple_copse()
	_dress_world_finish()
	_build_ambient_life()
	_setup_day_night()
	_setup_weather()
	_setup_outdoor_navigation()
	_setup_indoor_navigation()
	GameState.in_world = true
	AudioBus.start_ambient()
	if not GameState.soft_defeated.is_connected(_play_fountain_restore_fx):
		GameState.soft_defeated.connect(_play_fountain_restore_fx)
	if GameState.has_signal("quest_mastered") and not GameState.quest_mastered.is_connected(_play_quest_victory_sparkle):
		GameState.quest_mastered.connect(_play_quest_victory_sparkle)
	if GameState.has_signal("week_advanced") and not GameState.week_advanced.is_connected(_play_week_unicorn_party):
		GameState.week_advanced.connect(_play_week_unicorn_party)
	# Optional visual demo: LUMEN_CELEBRATE_DEMO=1 auto-plays fireworks then unicorn party.
	if OS.get_environment("LUMEN_CELEBRATE_DEMO") == "1" and not HeadlessGuard.is_headless():
		get_tree().create_timer(2.2).timeout.connect(func():
			_play_quest_victory_sparkle("demo-quest")
			get_tree().create_timer(2.4).timeout.connect(func():
				_play_week_unicorn_party(2, 1)
			)
		)

func _init_mats() -> void:
	## v1.80 world: warmer earth tones so the map reads as a finished village, not muddy gray.
	_mats["grass"] = _mat(Color("#4d8a3e"))
	_mats["grass_dark"] = _mat(Color("#356b32"))
	_mats["grass_light"] = _mat(Color("#6aaa4c"))
	_mats["dirt"] = _mat(Color("#c4a06a"))
	_mats["dirt_trim"] = _mat(Color("#d8b888"))
	_mats["stone"] = _mat(Color("#c8b49a"))
	_mats["stone_dark"] = _mat(Color("#9a8468"))
	_mats["wood"] = _mat(Color("#6e4428"))
	_mats["wood_light"] = _mat(Color("#8e5c34"))
	_mats["roof"] = _mat(Color("#8c4030"))
	_mats["water"] = _mat(Color("#4a90c8"), 0.2)
	_mats["leaf"] = _mat(Color("#3d8a44"))
	_mats["leaf_alt"] = _mat(Color("#5aaa3a"))
	_mats["leaf_autumn"] = _mat(Color("#c47a28"))
	_mats["barrel"] = _mat(Color("#7a5528"))
	_mats["iron"] = _mat(Color("#6a5a4a"), 0.45)
	_mats["lantern"] = _mat(Color("#f4a261"), 0.35)
	_mats["lantern_glow"] = _mat(Color("#ffe08a"), 0.25)
	_mats["fence"] = _mat(Color("#7a5838"))
	_mats["bench"] = _mat(Color("#8a6238"))
	_mats["flower"] = _mat(Color("#d46a8a"))
	_mats["flower_y"] = _mat(Color("#e0b020"))
	_mats["rock"] = _mat(Color("#9a8a70"))
	_mats["leaf_cedar"] = _mat(Color("#246848"))
	_mats["leaf_willow"] = _mat(Color("#5a9a48"))
	_mats["bush"] = _mat(Color("#3d7a42"))
	_mats["hedge"] = _mat(Color("#2f6a36"))
	_mats["amber"] = _mat(Color("#d4ae32"))
	_mats["amber_dark"] = _mat(Color("#9a7220"))
	_mats["birch"] = _mat(Color("#eee6d2"))
	_mats["birch_dark"] = _mat(Color("#c8bca0"))
	_mats["leaf_birch"] = _mat(Color("#72aa48"))
	_mats["heather"] = _mat(Color("#aa6aaa"))
	_mats["fern"] = _mat(Color("#4a8a3a"))
	_mats["fern_light"] = _mat(Color("#64aa48"))
	_mats["fern_dark"] = _mat(Color("#2f6230"))
	_mats["thistle"] = _mat(Color("#7a5a92"))
	_mats["thistle_leaf"] = _mat(Color("#4a8a46"))
	_mats["thistle_bloom"] = _mat(Color("#8a4aaa"))
	_mats["maple"] = _mat(Color("#9a3e26"))
	_mats["maple_leaf"] = _mat(Color("#d45a28"))
	_mats["maple_leaf_gold"] = _mat(Color("#e0b020"))
	_mats["maple_leaf_green"] = _mat(Color("#5a8a38"))
	_mats["cobble"] = _mat(Color("#b8a888"))
	_mats["cobble_light"] = _mat(Color("#d6c8a8"))
	_mats["cobble_dark"] = _mat(Color("#8e7a62"))
	_mats["plaster"] = _mat(Color("#eadcc4"))
	_mats["window"] = _mat(Color("#3a5470"), 0.25)
	_mats["leather"] = _mat(Color("#5c3d24"))

func _mat(c: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	return m

func _hex_color(h: String) -> Color:
	return Color(h)

func _mi(mesh: Mesh, pos: Vector3, parent: Node, mat: Material, name: String = "") -> MeshInstance3D:
	var n := MeshInstance3D.new()
	if name != "":
		n.name = name
	n.mesh = mesh
	n.position = pos
	n.material_override = mat
	parent.add_child(n)
	HeadlessGuard.guard_mesh(n)
	return n

func _make_label3d() -> Label3D:
	return HeadlessGuard.make_label3d()

func _place_label3d(parent: Node, text: String, font_size: int, pos: Vector3, outline: int = 6, modulate: Color = Color(1, 1, 1, 1)) -> Label3D:
	## Creates a billboard Label3D, or returns null in headless (no dummy-renderer spam).
	var lbl := _make_label3d()
	if lbl == null or parent == null:
		return null
	lbl.text = text
	lbl.font_size = font_size
	lbl.position = pos
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.outline_size = outline
	lbl.modulate = modulate
	parent.add_child(lbl)
	return lbl

func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m

func _cyl(tr: float, br: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = tr
	m.bottom_radius = br
	m.height = h
	return m

func _sphere(r: float, h: float = -1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h if h > 0.0 else r * 2.0
	return m

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	ground.mesh = plane
	ground.material_override = _mats["grass"]
	ground.position.y = -0.01
	static_world.add_child(ground)
	HeadlessGuard.guard_mesh(ground)
	# Thin floor collider — outdoor click-to-move NavigationMesh bake + footing
	var floor_body := StaticBody3D.new()
	floor_body.name = "GroundBody"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(120, 0.2, 120)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0, -0.1, 0)
	floor_body.add_child(floor_col)
	static_world.add_child(floor_body)
	# Soft wild tint edges + mid-ring meadow patches (v1.80 world: break the flat green slab)
	for i in 14:
		var patch := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 5.2 + (i % 4) * 0.85
		pm.bottom_radius = pm.top_radius
		pm.height = 0.02
		patch.mesh = pm
		patch.material_override = _mats["grass_dark"] if i % 2 == 0 else _mats["grass_light"]
		var ang := i * TAU / 14.0
		var rad := 34.0 if i % 2 == 0 else 22.0
		patch.position = Vector3(cos(ang) * rad, 0.015, sin(ang) * rad)
		static_world.add_child(patch)
		HeadlessGuard.guard_mesh(patch)
	# v1.78 refine: worn grass patches inside the plaza so the yard is not one flat green
	for i in 6:
		var wear := MeshInstance3D.new()
		var wm := CylinderMesh.new()
		wm.top_radius = 3.2 + (i % 3) * 0.5
		wm.bottom_radius = wm.top_radius
		wm.height = 0.018
		wear.mesh = wm
		wear.material_override = _mats["grass_light"]
		var wang := i * TAU / 6.0 + 0.3
		wear.position = Vector3(cos(wang) * 8.5, 0.012, 6.0 + sin(wang) * 7.5)
		static_world.add_child(wear)
		HeadlessGuard.guard_mesh(wear)
	# v1.80 world: village lawn ring just outside the cobble so the green meets the plaza
	var lawn := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 17.6
	lm.bottom_radius = 17.6
	lm.height = 0.016
	lawn.mesh = lm
	lawn.material_override = _mats["grass_light"]
	lawn.position = Vector3(0, 0.01, 6)
	static_world.add_child(lawn)
	HeadlessGuard.guard_mesh(lawn)

func _build_paths() -> void:
	# Central plaza ring
	var path := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 14.5
	cyl.bottom_radius = 14.5
	cyl.height = 0.05
	path.mesh = cyl
	path.material_override = _mats["dirt"]
	path.position = Vector3(0, 0.02, 6)
	static_world.add_child(path)
	HeadlessGuard.guard_mesh(path)
	# Inner trim ring
	var trim := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = 15.3
	tc.bottom_radius = 15.3
	tc.height = 0.03
	trim.mesh = tc
	trim.material_override = _mats["dirt_trim"]
	trim.position = Vector3(0, 0.018, 6)
	static_world.add_child(trim)
	HeadlessGuard.guard_mesh(trim)
	# v1.78 refine: cobble plaza disc + stone curb so the village green reads finished
	var cobble := MeshInstance3D.new()
	cobble.name = "PlazaCobble"
	var cc := CylinderMesh.new()
	cc.top_radius = 7.6
	cc.bottom_radius = 7.6
	cc.height = 0.055
	cobble.mesh = cc
	cobble.material_override = _mats["cobble"]
	cobble.position = Vector3(0, 0.032, 6)
	static_world.add_child(cobble)
	HeadlessGuard.guard_mesh(cobble)
	var cobble_in := MeshInstance3D.new()
	cobble_in.name = "PlazaCobbleInner"
	var ci := CylinderMesh.new()
	ci.top_radius = 5.4
	ci.bottom_radius = 5.4
	ci.height = 0.05
	cobble_in.mesh = ci
	cobble_in.material_override = _mats["cobble_light"]
	cobble_in.position = Vector3(0, 0.036, 6)
	static_world.add_child(cobble_in)
	HeadlessGuard.guard_mesh(cobble_in)
	for i in 20:
		var ang := i * TAU / 20.0
		var curb := _mi(_box(Vector3(0.70, 0.20, 0.32)), Vector3(cos(ang) * 15.05, 0.11, 6.0 + sin(ang) * 15.05), static_world, _mats["stone"], "PlazaCurb%d" % i)
		curb.rotation.y = -ang
	# v1.80 world: flagstone tiles so the plaza reads as cobble, not two flat discs
	for i in 24:
		var fang := i * TAU / 24.0 + 0.07
		var fr := 6.15 if i % 2 == 0 else 6.95
		var flag := _mi(_box(Vector3(0.88, 0.045, 0.56)), Vector3(cos(fang) * fr, 0.052, 6.0 + sin(fang) * fr), static_world, _mats["cobble_light"] if i % 3 else _mats["stone"], "PlazaFlag%d" % i)
		flag.rotation.y = -fang
	for i in 12:
		var iang := i * TAU / 12.0 + 0.2
		var inner := _mi(_box(Vector3(0.62, 0.04, 0.42)), Vector3(cos(iang) * 4.55, 0.05, 6.0 + sin(iang) * 4.55), static_world, _mats["stone"] if i % 2 else _mats["cobble"], "PlazaFlagIn%d" % i)
		inner.rotation.y = -iang
	# v1.80 world: checker flagstones across the whole disc so the plaza is not a flat sand plate
	var tile_i := 0
	for ix in range(-7, 8):
		for iz in range(-7, 8):
			var px := float(ix) * 1.02
			var pz := 6.0 + float(iz) * 1.02
			if Vector2(px, pz - 6.0).length() > 7.15:
				continue
			var tmat: Material = _mats["cobble_light"] if (ix + iz) % 2 == 0 else _mats["cobble_dark"]
			_mi(_box(Vector3(0.94, 0.028, 0.94)), Vector3(px, 0.054, pz), static_world, tmat, "PlazaTile%d" % tile_i)
			tile_i += 1
	# Spokes toward guild halls
	var spokes := [
		Vector3(18, 0, 2), Vector3(-18, 0, 2), Vector3(0, 0, -14),
		Vector3(0, 0, 18), Vector3(0, 0, 0)
	]
	for s in spokes:
		var plank := MeshInstance3D.new()
		var box := BoxMesh.new()
		var dx: float = s.x
		var dz: float = s.z
		var length: float = maxf(8.0, Vector2(dx, dz).length() + 4.0)
		var ang: float = atan2(dx, dz)
		box.size = Vector3(2.4, 0.04, length)
		plank.mesh = box
		plank.material_override = _mats["dirt"]
		plank.position = Vector3(dx * 0.45, 0.025, 6.0 + dz * 0.45)
		plank.rotation.y = ang
		static_world.add_child(plank)
		HeadlessGuard.guard_mesh(plank)
		# Stone edge trim along each spoke
		var edge := MeshInstance3D.new()
		var ebox := BoxMesh.new()
		ebox.size = Vector3(2.85, 0.03, length)
		edge.mesh = ebox
		edge.material_override = _mats["stone"]
		edge.position = Vector3(dx * 0.45, 0.016, 6.0 + dz * 0.45)
		edge.rotation.y = ang
		static_world.add_child(edge)
		HeadlessGuard.guard_mesh(edge)

func _build_buildings() -> void:
	for b in world_data.get("buildings", []):
		var body := StaticBody3D.new()
		body.position = Vector3(b["x"], 0, b["z"])
		var w: float = float(b["w"])
		var d: float = float(b["d"])
		var h: float = float(b["h"])
		var guild_col := _hex_color(b["color"])
		var wall_mat := _mat(guild_col.lightened(0.08))
		var trim_mat := _mat(guild_col.darkened(0.25))
		# Foundation plinth so halls sit on the green (v1.78 refine)
		_mi(_box(Vector3(w + 0.55, 0.38, d + 0.55)), Vector3(0, 0.14, 0), body, _mats["stone"], "Plinth")
		# Main hall body
		_mi(_box(Vector3(w, h, d)), Vector3(0, h * 0.5, 0), body, wall_mat, "Hall")
		# Mid timber beam
		_mi(_box(Vector3(w + 0.08, 0.18, d + 0.08)), Vector3(0, h * 0.62, 0), body, _mats["wood"], "Beam")
		# Front porch / steps
		_mi(_box(Vector3(w * 0.62, 0.22, 1.55)), Vector3(0, 0.10, d * 0.5 + 0.55), body, _mats["stone"], "StepLow")
		_mi(_box(Vector3(w * 0.55, 0.25, 1.2)), Vector3(0, 0.22, d * 0.5 + 0.4), body, _mats["stone"], "Steps")
		_mi(_box(Vector3(w * 0.5, 0.18, 0.9)), Vector3(0, 0.38, d * 0.5 + 0.25), body, _mats["stone_dark"], "Landing")
		# Door awning
		_mi(_box(Vector3(1.7, 0.10, 0.85)), Vector3(0, 2.35, d * 0.5 + 0.42), body, _mats["wood"], "Awning")
		# Door frame recess (darker panel)
		_mi(_box(Vector3(1.1, 2.0, 0.12)), Vector3(0, 1.1, d * 0.5 + 0.02), body, trim_mat, "Door")
		# Front windows
		_mi(_box(Vector3(0.85, 0.80, 0.10)), Vector3(-w * 0.28, h * 0.55, d * 0.5 + 0.04), body, _mats["window"], "WinL")
		_mi(_box(Vector3(0.85, 0.80, 0.10)), Vector3(w * 0.28, h * 0.55, d * 0.5 + 0.04), body, _mats["window"], "WinR")
		_mi(_box(Vector3(0.95, 0.08, 0.12)), Vector3(-w * 0.28, h * 0.55 + 0.46, d * 0.5 + 0.05), body, _mats["wood"], "SillL")
		_mi(_box(Vector3(0.95, 0.08, 0.12)), Vector3(w * 0.28, h * 0.55 + 0.46, d * 0.5 + 0.05), body, _mats["wood"], "SillR")
		# Side windows
		_mi(_box(Vector3(0.10, 0.70, 0.70)), Vector3(-w * 0.5 - 0.04, h * 0.52, 0), body, _mats["window"], "WinSideL")
		_mi(_box(Vector3(0.10, 0.70, 0.70)), Vector3(w * 0.5 + 0.04, h * 0.52, 0), body, _mats["window"], "WinSideR")
		# Side buttress pillars
		_mi(_cyl(0.28, 0.32, h * 0.85), Vector3(-w * 0.5 - 0.15, h * 0.42, d * 0.35), body, _mats["stone"], "PillarL")
		_mi(_cyl(0.28, 0.32, h * 0.85), Vector3(w * 0.5 + 0.15, h * 0.42, d * 0.35), body, _mats["stone"], "PillarR")
		# Banner strip under eaves
		_mi(_box(Vector3(w * 0.7, 0.35, 0.08)), Vector3(0, h - 0.4, d * 0.5 + 0.06), body, trim_mat, "Banner")
		# v1.80 world: front half-timber so halls read as buildings, not painted boxes
		_mi(_box(Vector3(0.12, h * 0.78, 0.10)), Vector3(-w * 0.18, h * 0.50, d * 0.5 + 0.06), body, _mats["wood"], "HallTimberL")
		_mi(_box(Vector3(0.12, h * 0.78, 0.10)), Vector3(w * 0.18, h * 0.50, d * 0.5 + 0.06), body, _mats["wood"], "HallTimberR")
		_mi(_box(Vector3(w * 0.78, 0.12, 0.10)), Vector3(0, h * 0.36, d * 0.5 + 0.06), body, _mats["wood"], "HallTimberLo")
		_mi(_box(Vector3(w * 0.78, 0.12, 0.10)), Vector3(0, h * 0.72, d * 0.5 + 0.06), body, _mats["wood"], "HallTimberHi")
		_mi(_box(Vector3(1.28, 2.18, 0.10)), Vector3(0, 1.12, d * 0.5 + 0.03), body, _mats["wood"], "DoorFrame")
		# Roof prism
		var roof := MeshInstance3D.new()
		var rmesh := PrismMesh.new()
		rmesh.size = Vector3(w + 0.6, 1.8, d + 0.6)
		roof.mesh = rmesh
		roof.position.y = h + 0.75
		roof.material_override = _mats["roof"]
		body.add_child(roof)
		HeadlessGuard.guard_mesh(roof)
		# Chimney
		_mi(_box(Vector3(0.55, 1.4, 0.55)), Vector3(w * 0.28, h + 1.4, -d * 0.15), body, _mats["stone_dark"], "Chimney")
		# v1.80 world: timber corners, ridge, chimney pot, garden beds — halls read as buildings
		_mi(_box(Vector3(0.22, h + 0.18, 0.22)), Vector3(-w * 0.5, (h + 0.18) * 0.5, -d * 0.5), body, _mats["wood"], "CornerSW")
		_mi(_box(Vector3(0.22, h + 0.18, 0.22)), Vector3(w * 0.5, (h + 0.18) * 0.5, -d * 0.5), body, _mats["wood"], "CornerSE")
		_mi(_box(Vector3(0.22, h + 0.18, 0.22)), Vector3(-w * 0.5, (h + 0.18) * 0.5, d * 0.5), body, _mats["wood"], "CornerNW")
		_mi(_box(Vector3(0.22, h + 0.18, 0.22)), Vector3(w * 0.5, (h + 0.18) * 0.5, d * 0.5), body, _mats["wood"], "CornerNE")
		_mi(_box(Vector3(0.12, 0.16, d * 0.78)), Vector3(-w * 0.5 - 0.06, h * 0.36, 0), body, _mats["wood"], "StudL")
		_mi(_box(Vector3(0.12, 0.16, d * 0.78)), Vector3(w * 0.5 + 0.06, h * 0.36, 0), body, _mats["wood"], "StudR")
		_mi(_box(Vector3(w + 0.72, 0.16, 0.22)), Vector3(0, h + 1.58, 0), body, _mats["wood"], "Ridge")
		_mi(_cyl(0.16, 0.18, 0.30), Vector3(w * 0.28, h + 2.22, -d * 0.15), body, _mats["stone_dark"], "ChimneyPot")
		_mi(_box(Vector3(1.02, 0.10, 0.10)), Vector3(-w * 0.28, h * 0.55 - 0.46, d * 0.5 + 0.05), body, _mats["wood"], "SillLoL")
		_mi(_box(Vector3(1.02, 0.10, 0.10)), Vector3(w * 0.28, h * 0.55 - 0.46, d * 0.5 + 0.05), body, _mats["wood"], "SillLoR")
		_mi(_box(Vector3(0.95, 0.28, 0.95)), Vector3(-w * 0.42, 0.16, d * 0.5 + 1.35), body, _mats["hedge"], "GardenL")
		_mi(_box(Vector3(0.95, 0.28, 0.95)), Vector3(w * 0.42, 0.16, d * 0.5 + 1.35), body, _mats["hedge"], "GardenR")
		_mi(_sphere(0.16, 0.22), Vector3(-w * 0.42, 0.42, d * 0.5 + 1.35), body, _mats["flower"], "GardenBloomL")
		_mi(_sphere(0.16, 0.22), Vector3(w * 0.42, 0.42, d * 0.5 + 1.35), body, _mats["flower_y"], "GardenBloomR")
		# Collision for main box only
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(w, h, d)
		col.shape = shape
		col.position.y = h * 0.5
		body.add_child(col)
		_place_label3d(body, str(b["label"]), 64, Vector3(0, h + 2.6, 0), 6)
		# Small lantern by door
		_add_lantern(body, Vector3(-1.0, 2.2, d * 0.5 + 0.35))
		# Wave 51: hall outdoor eaves anchors for soft rain splash
		var bx := float(b["x"])
		var bz := float(b["z"])
		var ey := h + 0.85
		_hall_eaves.append(Vector3(bx, ey, bz + d * 0.52))
		_hall_eaves.append(Vector3(bx, ey, bz - d * 0.52))
		_hall_eaves.append(Vector3(bx - w * 0.52, ey, bz))
		_hall_eaves.append(Vector3(bx + w * 0.52, ey, bz))
		static_world.add_child(body)

func _build_trees() -> void:
	for t in world_data.get("trees", []):
		_add_tree(Vector3(t[0], 0, t[1]), 0)

func _build_wilds() -> void:
	## Extra edge variety: rocks, bushes, alternate trees — capped for performance
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var placed := 0
	var attempts := 0
	while placed < 36 and attempts < 120:
		attempts += 1
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(30.0, 44.0)
		var p := Vector3(cos(ang) * rad, 0, sin(ang) * rad)
		if _in_travel_corridor(p):
			continue
		match placed % 4:
			0:
				_add_tree(p, 1 if placed % 8 == 0 else 0)
			1:
				_add_rock_cluster(p, rng)
			2:
				_add_bush(p, rng)
			_:
				_add_bush(p + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)), rng)
		placed += 1

func _near_segment_xz(pos: Vector3, a: Vector3, b: Vector3, half_w: float) -> bool:
	## Distance from point to segment on XZ plane (y ignored).
	var p := Vector2(pos.x, pos.z)
	var aa := Vector2(a.x, a.z)
	var bb := Vector2(b.x, b.z)
	var ab := bb - aa
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return p.distance_to(aa) < half_w
	var t := clampf((p - aa).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(aa + ab * t) < half_w

func _in_travel_corridor(pos: Vector3) -> bool:
	## Keep soft-travel routes walkable: north glade spur, west ridge spur, east garden spur.
	# North path to Lantern Glade (around x=0.5)
	if abs(pos.x - 0.5) < 3.2 and pos.z < -16.0 and pos.z > -52.0:
		return true
	# West path Glade → Pine Ridge (around z=-48)
	if abs(pos.z + 48.0) < 3.0 and pos.x < -2.0 and pos.x > -30.0:
		return true
	# East path to Prayer Garden
	if abs(pos.z - 18.0) < 3.0 and pos.x > 12.0 and pos.x < 36.0:
		return true
	# Village plaza keep-clear near fountain soft-travel
	if abs(pos.x) < 4.0 and abs(pos.z - 12.0) < 3.0:
		return true
	# Southeast diagonal path to Lookout Rock (v1.6 bugfix: was only z≈34 band)
	if _near_segment_xz(pos, Vector3(10, 0, 14), Vector3(40, 0, 34), 3.4):
		return true
	# Lookout plaza keep-clear
	if abs(pos.x - 40.0) < 4.0 and abs(pos.z - 34.0) < 4.0:
		return true
	# Southwest path to Mill Bridge
	if _near_segment_xz(pos, Vector3(-8, 0, 14), Vector3(-36, 0, 30), 3.4):
		return true
	# Mill Bridge plaza keep-clear
	if abs(pos.x + 36.0) < 5.0 and abs(pos.z - 30.0) < 5.0:
		return true
	# Northeast path to Cedar Hollow
	if _near_segment_xz(pos, Vector3(10, 0, -16), Vector3(38, 0, -36), 3.4):
		return true
	# Cedar Hollow plaza keep-clear
	if abs(pos.x - 38.0) < 5.0 and abs(pos.z + 36.0) < 5.0:
		return true
	# Northwest path to Willow Bend
	if _near_segment_xz(pos, Vector3(-10, 0, -12), Vector3(-38, 0, -34), 3.4):
		return true
	# Willow Bend plaza keep-clear
	if abs(pos.x + 38.0) < 5.0 and abs(pos.z + 34.0) < 5.0:
		return true
	# South path to Reed Pool (Wave 22)
	if _near_segment_xz(pos, Vector3(-6, 0, 20), Vector3(-20, 0, 48), 3.4):
		return true
	# Reed Pool plaza keep-clear
	if abs(pos.x + 20.0) < 5.0 and abs(pos.z - 48.0) < 5.0:
		return true
	# East path to Quiet Cross (Wave 23)
	if _near_segment_xz(pos, Vector3(14, 0, 8), Vector3(48, 0, 8), 3.4):
		return true
	# Quiet Cross plaza keep-clear
	if abs(pos.x - 48.0) < 5.0 and abs(pos.z - 8.0) < 5.0:
		return true
	# West path to Stone Arch (Wave 24)
	if _near_segment_xz(pos, Vector3(-14, 0, 8), Vector3(-48, 0, 8), 3.4):
		return true
	# Stone Arch plaza keep-clear
	if abs(pos.x + 48.0) < 5.0 and abs(pos.z - 8.0) < 5.0:
		return true
	# Northeast-east path to Amber Knoll (Wave 25)
	if _near_segment_xz(pos, Vector3(16, 0, -4), Vector3(48, 0, -22), 3.4):
		return true
	# Amber Knoll plaza keep-clear
	if abs(pos.x - 48.0) < 5.0 and abs(pos.z + 22.0) < 5.0:
		return true
	# Southwest path to Birch Rest (Wave 26)
	if _near_segment_xz(pos, Vector3(-14, 0, -6), Vector3(-42, 0, -20), 3.4):
		return true
	# Birch Rest plaza keep-clear
	if abs(pos.x + 42.0) < 5.0 and abs(pos.z + 20.0) < 5.0:
		return true
	# South-southeast path to Fern Dell (Wave 27)
	if _near_segment_xz(pos, Vector3(8, 0, 20), Vector3(22, 0, 48), 3.4):
		return true
	# Fern Dell plaza keep-clear
	if abs(pos.x - 22.0) < 5.0 and abs(pos.z - 48.0) < 5.0:
		return true
	# West-southwest path to Heather Heath (Wave 28)
	if _near_segment_xz(pos, Vector3(-14, 0, 20), Vector3(-48, 0, 42), 3.4):
		return true
	# Heather Heath plaza keep-clear
	if abs(pos.x + 48.0) < 5.0 and abs(pos.z - 42.0) < 5.0:
		return true
	# East-southeast path to Thistle Rise (Wave 29)
	if _near_segment_xz(pos, Vector3(14, 0, 20), Vector3(48, 0, 42), 3.4):
		return true
	# Thistle Rise plaza keep-clear
	if abs(pos.x - 48.0) < 5.0 and abs(pos.z - 42.0) < 5.0:
		return true
	# Northwest path to Maple Copse (Wave 30)
	if _near_segment_xz(pos, Vector3(-16, 0, -20), Vector3(-48, 0, -48), 3.4):
		return true
	# Maple Copse plaza keep-clear
	if abs(pos.x + 48.0) < 5.0 and abs(pos.z + 48.0) < 5.0:
		return true
	return false

func _add_tree(pos: Vector3, style: int = 0) -> void:
	if _in_travel_corridor(pos):
		return
	var body := StaticBody3D.new()
	body.position = pos
	var trunk_h := 1.4 if style == 0 else (2.15 if style == 2 else (1.95 if style == 3 else 1.8))
	_mi(_cyl(0.22, 0.34, trunk_h), Vector3(0, trunk_h * 0.5, 0), body, _mats["wood"], "Trunk")
	if style == 2:
		# Cedar — taller stacked dark cones
		_mi(_sphere(0.95, 1.7), Vector3(0, trunk_h + 0.35, 0), body, _mats["leaf_cedar"], "Leaves")
		_mi(_sphere(0.72, 1.3), Vector3(0, trunk_h + 1.05, 0), body, _mats["leaf_cedar"], "Leaves2")
		_mi(_sphere(0.45, 0.9), Vector3(0, trunk_h + 1.65, 0), body, _mats["leaf"], "Leaves3")
	elif style == 3:
		# Willow — soft weeping canopy (Wave 21); Wave 61: weep sway parent for soft wind lean
		var canopy := Node3D.new()
		canopy.name = "WillowCanopy"
		body.add_child(canopy)
		_mi(_sphere(1.15, 1.5), Vector3(0, trunk_h + 0.55, 0), canopy, _mats["leaf_willow"], "Leaves")
		_mi(_sphere(0.55, 1.1), Vector3(-0.55, trunk_h + 0.05, 0.15), canopy, _mats["leaf_willow"], "WeepL")
		_mi(_sphere(0.55, 1.1), Vector3(0.55, trunk_h + 0.05, -0.1), canopy, _mats["leaf_willow"], "WeepR")
		_mi(_sphere(0.45, 0.95), Vector3(0.1, trunk_h - 0.15, 0.55), canopy, _mats["leaf_willow"], "WeepF")
		_mi(_sphere(0.4, 0.85), Vector3(-0.05, trunk_h - 0.1, -0.5), canopy, _mats["leaf_alt"], "WeepB")
		canopy.set_meta("sway_phase", float(hash(str(pos)) % 1000) * 0.006283)
		canopy.set_meta("sway_amp", 0.028)
		_willow_sway_nodes.append(canopy)
	else:
		var leaf_mat: Material = _mats["leaf"] if style == 0 else _mats["leaf_autumn"]
		_mi(_sphere(1.05 if style == 0 else 0.95, 2.0), Vector3(0, trunk_h + 0.55, 0), body, leaf_mat, "Leaves")
		# v1.80 world: extra canopy lobes so trees read as foliage, not one green blob
		_mi(_sphere(0.62, 1.15), Vector3(-0.42, trunk_h + 0.28, 0.18), body, _mats["leaf_alt"], "LeavesL")
		_mi(_sphere(0.58, 1.05), Vector3(0.38, trunk_h + 0.22, -0.16), body, leaf_mat, "LeavesR")
		_mi(_sphere(0.48, 0.82), Vector3(0.08, trunk_h + 1.05, 0.22), body, _mats["leaf_alt"], "LeavesTop")
		_mi(_sphere(0.72, 0.70), Vector3(0.0, trunk_h + 0.08, 0.0), body, _mats["grass_dark"], "LeavesUnder")
		_mi(_cyl(1.15, 1.15, 0.02), Vector3(0, 0.012, 0), body, _mats["grass_dark"], "Shade")
		if style == 1:
			_mi(_sphere(0.7, 1.3), Vector3(0.35, trunk_h + 0.2, 0.1), body, _mats["leaf_alt"], "Leaves2")
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.32
	shape.height = 2.0
	col.shape = shape
	col.position.y = 1.0
	body.add_child(col)
	static_world.add_child(body)
	_tree_positions.append(pos)  # Wave 37: leaf rustle near trees

func _add_rock_cluster(pos: Vector3, rng: RandomNumberGenerator) -> void:
	if _in_travel_corridor(pos):
		return
	var root := Node3D.new()
	root.position = pos
	for i in rng.randi_range(2, 4):
		var rock := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.25, 0.55)
		sm.height = sm.radius * rng.randf_range(1.2, 1.8)
		rock.mesh = sm
		rock.material_override = _mats["rock"]
		rock.position = Vector3(rng.randf_range(-0.6, 0.6), sm.height * 0.35, rng.randf_range(-0.6, 0.6))
		rock.scale = Vector3(rng.randf_range(0.8, 1.3), rng.randf_range(0.6, 1.0), rng.randf_range(0.8, 1.2))
		root.add_child(rock)
		HeadlessGuard.guard_mesh(rock)
	static_world.add_child(root)

func _add_bush(pos: Vector3, rng: RandomNumberGenerator) -> void:
	if _in_travel_corridor(pos):
		return
	var root := Node3D.new()
	root.position = pos
	_mi(_sphere(rng.randf_range(0.45, 0.7), rng.randf_range(0.7, 1.1)), Vector3(0, 0.35, 0), root, _mats["bush"], "Bush")
	_mi(_sphere(rng.randf_range(0.28, 0.42), rng.randf_range(0.45, 0.7)), Vector3(rng.randf_range(-0.28, 0.28), 0.28, rng.randf_range(-0.22, 0.22)), root, _mats["leaf_alt"], "BushLobe")
	static_world.add_child(root)

func _build_fountain() -> void:
	var f: Dictionary = world_data.get("fountain", {"x": 0, "z": 8})
	var root := Node3D.new()
	root.name = "Fountain"
	root.position = Vector3(f["x"], 0, f["z"])
	_fountain_root = root
	# v1.78 refine: cobble apron under the fountain
	_mi(_cyl(3.6, 3.6, 0.06), Vector3(0, 0.03, 0), root, _mats["cobble"], "FountainApron")
	_mi(_cyl(3.15, 3.15, 0.05), Vector3(0, 0.04, 0), root, _mats["cobble_light"], "FountainApronIn")
	_mi(_cyl(2.35, 2.55, 0.4), Vector3(0, 0.2, 0), root, _mats["stone"], "Base")
	_mi(_cyl(2.48, 2.55, 0.12), Vector3(0, 0.42, 0), root, _mats["stone_dark"], "Rim")
	_mi(_cyl(1.65, 1.65, 0.15), Vector3(0, 0.35, 0), root, _mats["water"], "Water")
	_water_positions.append(root.position)  # Wave 38: brook murmur near fountain
	_mi(_cyl(0.28, 0.38, 1.6), Vector3(0, 1.0, 0), root, _mats["stone"], "Pillar")
	_mi(_cyl(0.9, 0.95, 0.2), Vector3(0, 1.75, 0), root, _mats["stone_dark"], "Bowl")
	_mi(_cyl(0.55, 0.55, 0.08), Vector3(0, 1.82, 0), root, _mats["water"], "UpperWater")
	_mi(_sphere(0.16), Vector3(0, 2.02, 0), root, _mats["amber"], "Gem")
	# Ring of low posts
	for i in 6:
		var ang := i * TAU / 6.0
		_mi(_cyl(0.12, 0.14, 0.55), Vector3(cos(ang) * 2.7, 0.28, sin(ang) * 2.7), root, _mats["stone"], "Post%d" % i)
	_place_label3d(root, "Fountain", 48, Vector3(0, 2.5, 0))
	# Wave 50: soft plaza fountain mist polish — gentle cream mist over the water (RuneScape-chunky, wholesome)
	_fountain_mist = CPUParticles3D.new()
	_fountain_mist.name = "FountainPlazaMist"
	_fountain_mist.position = Vector3(0, 0.55, 0)
	_fountain_mist.emitting = true
	_fountain_mist.amount = 18
	_fountain_mist.lifetime = 2.4
	_fountain_mist.preprocess = 1.0
	_fountain_mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_fountain_mist.emission_sphere_radius = 1.55
	_fountain_mist.direction = Vector3(0, 1, 0)
	_fountain_mist.spread = 40.0
	_fountain_mist.initial_velocity_min = 0.15
	_fountain_mist.initial_velocity_max = 0.45
	_fountain_mist.gravity = Vector3(0, 0.08, 0)
	_fountain_mist.scale_amount_min = 0.18
	_fountain_mist.scale_amount_max = 0.42
	_fountain_mist.color = Color(0.88, 0.96, 1.0, 0.42)
	HeadlessGuard.guard_particles(_fountain_mist)
	root.add_child(_fountain_mist)
	# Soft pantry refill when walking near the fountain
	var refill := Area3D.new()
	refill.name = "PantryRefill"
	refill.monitoring = true
	refill.collision_layer = 0
	refill.collision_mask = 2
	refill.position = Vector3(0, 1.0, 0)
	var rcol := CollisionShape3D.new()
	var rbox := CylinderShape3D.new()
	rbox.radius = 3.2
	rbox.height = 2.4
	rcol.shape = rbox
	refill.add_child(rcol)
	refill.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and GameState.has_method("rest_at_fountain"):
			GameState.rest_at_fountain(true)
		elif body.is_in_group("player") and GameState.has_method("refill_pantry"):
			GameState.refill_pantry(true)
	)
	root.add_child(refill)
	static_world.add_child(root)

func _build_village_props() -> void:
	## Barrels, fences, lantern posts, benches around plaza — budget ~50 pieces
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	# Fence arcs near plaza edges
	_fence_arc(Vector3(10, 0, 14), 4, 0.0)
	_fence_arc(Vector3(-10, 0, 14), 4, PI)
	_fence_arc(Vector3(12, 0, -2), 3, -0.4)
	_fence_arc(Vector3(-12, 0, -2), 3, 0.4 + PI)
	# Benches facing fountain
	_add_bench(Vector3(5.5, 0, 11.5), -0.6)
	_add_bench(Vector3(-5.5, 0, 11.5), 0.6)
	_add_bench(Vector3(4.0, 0, 3.5), 0.2)
	_add_bench(Vector3(-4.0, 0, 3.5), -0.2)
	# Barrel clusters near halls
	var barrel_spots := [
		Vector3(16, 0, 2), Vector3(17.2, 0, 2.8), Vector3(-16, 0, 2),
		Vector3(-17, 0, 1.4), Vector3(2.5, 0, -16), Vector3(-2.2, 0, -15.5),
		Vector3(2.0, 0, 20), Vector3(-1.5, 0, 19.5), Vector3(3.5, 0, -3.5)
	]
	for p in barrel_spots:
		_add_barrel(p, rng.randf() * TAU)
	# Lantern posts along path
	var lantern_spots := [
		Vector3(8, 0, 8), Vector3(-8, 0, 8), Vector3(0, 0, 14),
		Vector3(14, 0, 4), Vector3(-14, 0, 4), Vector3(0, 0, -10),
		Vector3(6, 0, 0), Vector3(-6, 0, 0)
	]
	for p in lantern_spots:
		_add_lantern_post(p, true)
	# Wave 28: a few extra village lamp posts for dusk glow (chunky, wholesome)
	for p in [Vector3(10.5, 0, 12.0), Vector3(-10.5, 0, 12.0), Vector3(3.5, 0, 16.5), Vector3(-3.5, 0, 16.5), Vector3(0.0, 0, 2.5)]:
		_add_lantern_post(p, true)
	# Flower patches
	for i in 10:
		var ang := i * TAU / 10.0
		_add_flowers(Vector3(cos(ang) * 11.0, 0, 6.0 + sin(ang) * 9.0), rng)
	# Market crates near Builder hall
	_add_crate(Vector3(15.5, 0, 5.5))
	_add_crate(Vector3(16.3, 0, 5.0))
	_add_crate(Vector3(-15.2, 0, 5.2))
	# v1.78 refine: plaza planters + a simple market stall so the green feels lived-in
	_add_planter(Vector3(7.2, 0, 6.5))
	_add_planter(Vector3(-7.2, 0, 6.5))
	_add_planter(Vector3(3.4, 0, 13.2))
	_add_planter(Vector3(-3.4, 0, 13.2))
	_add_market_stall(Vector3(9.5, 0, 3.2), -0.4)
	_add_market_stall(Vector3(-9.5, 0, 3.2), 0.4)
	_add_market_stall(Vector3(11.2, 0, 8.4), -1.1)
	_add_bench(Vector3(0.0, 0, 15.6), PI)
	# v1.80 world: plaza hedges + yard cart so the green feels lived-in (visual only, no extra collision)
	_add_hedge(Vector3(13.2, 0, 10.6), 0.35, 2.1)
	_add_hedge(Vector3(-13.2, 0, 10.6), -0.35, 2.1)
	_add_hedge(Vector3(13.4, 0, 1.4), -0.2, 1.9)
	_add_hedge(Vector3(-13.4, 0, 1.4), 0.2, 1.9)
	_add_hedge(Vector3(7.6, 0, -4.2), 0.15, 1.8)
	_add_hedge(Vector3(-7.6, 0, -4.2), -0.15, 1.8)
	_add_yard_cart(Vector3(11.0, 0, 6.2), -0.55)
	_add_planter(Vector3(0.0, 0, -1.8))
	_add_planter(Vector3(5.8, 0, 16.4))
	_add_planter(Vector3(-5.8, 0, 16.4))

func _fence_arc(origin: Vector3, posts: int, yaw: float) -> void:
	var root := Node3D.new()
	root.position = origin
	root.rotation.y = yaw
	for i in posts:
		var x := float(i) * 1.35
		_mi(_box(Vector3(0.12, 1.0, 0.12)), Vector3(x, 0.5, 0), root, _mats["fence"], "Post")
		if i < posts - 1:
			_mi(_box(Vector3(1.25, 0.1, 0.08)), Vector3(x + 0.65, 0.7, 0), root, _mats["fence"], "Rail")
			_mi(_box(Vector3(1.25, 0.1, 0.08)), Vector3(x + 0.65, 0.35, 0), root, _mats["fence"], "RailLo")
	static_world.add_child(root)

func _add_bench(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	_mi(_box(Vector3(1.6, 0.12, 0.45)), Vector3(0, 0.45, 0), root, _mats["bench"], "Seat")
	_mi(_box(Vector3(1.6, 0.45, 0.1)), Vector3(0, 0.7, -0.2), root, _mats["bench"], "Back")
	_mi(_box(Vector3(0.12, 0.45, 0.4)), Vector3(-0.7, 0.22, 0), root, _mats["wood"], "LegL")
	_mi(_box(Vector3(0.12, 0.45, 0.4)), Vector3(0.7, 0.22, 0), root, _mats["wood"], "LegR")
	static_world.add_child(root)

func _add_barrel(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	_mi(_cyl(0.35, 0.38, 0.85), Vector3(0, 0.42, 0), root, _mats["barrel"], "Barrel")
	_mi(_cyl(0.36, 0.36, 0.06), Vector3(0, 0.55, 0), root, _mats["iron"], "Band")
	_mi(_cyl(0.36, 0.36, 0.06), Vector3(0, 0.28, 0), root, _mats["iron"], "Band2")
	static_world.add_child(root)

func _add_lantern_post(pos: Vector3, village_dusk: bool = false) -> void:
	var root := Node3D.new()
	root.position = pos
	_mi(_cyl(0.16, 0.20, 0.16), Vector3(0, 0.08, 0), root, _mats["stone"], "Base")
	_mi(_cyl(0.08, 0.1, 2.2), Vector3(0, 1.1, 0), root, _mats["wood"], "Post")
	_add_lantern(root, Vector3(0.25, 2.0, 0))
	# Wave 28: village lamp posts glow softly at dusk (RuneScape-chunky, wholesome)
	if village_dusk:
		var light := OmniLight3D.new()
		light.name = "DuskLamp"
		light.light_color = Color(1.0, 0.82, 0.48)
		light.light_energy = 0.0
		light.omni_range = 6.5
		light.omni_attenuation = 1.35
		light.shadow_enabled = false
		light.position = Vector3(0.25, 2.0, 0)
		root.add_child(light)
		_village_lamp_lights.append(light)
	static_world.add_child(root)

func _add_lantern(parent: Node, pos: Vector3, with_light: bool = false) -> void:
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	_mi(_box(Vector3(0.22, 0.28, 0.22)), Vector3(0, 0, 0), holder, _mats["iron"], "Cage")
	_mi(_sphere(0.1), Vector3(0, 0, 0), holder, _mats["lantern_glow"], "Glow")
	_mi(_cyl(0.04, 0.06, 0.12), Vector3(0, 0.2, 0), holder, _mats["lantern"], "Cap")
	if with_light:
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.88, 0.62)
		light.light_energy = 1.35
		light.omni_range = 7.5
		light.omni_attenuation = 1.2
		light.shadow_enabled = false
		holder.add_child(light)

func _add_flowers(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var root := Node3D.new()
	root.position = pos
	for i in rng.randi_range(3, 5):
		var mat: Material = _mats["flower"] if i % 2 == 0 else _mats["flower_y"]
		_mi(_sphere(0.08, 0.12), Vector3(rng.randf_range(-0.4, 0.4), 0.15, rng.randf_range(-0.4, 0.4)), root, mat, "Fl")
	static_world.add_child(root)

func _add_crate(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	_mi(_box(Vector3(0.7, 0.55, 0.7)), Vector3(0, 0.28, 0), root, _mats["wood_light"], "Crate")
	static_world.add_child(root)

func _add_planter(pos: Vector3) -> void:
	## v1.78 refine: chunky stone planter with flowers for the plaza yard.
	var root := Node3D.new()
	root.name = "Planter"
	root.position = pos
	_mi(_box(Vector3(1.15, 0.42, 1.15)), Vector3(0, 0.21, 0), root, _mats["stone"], "Box")
	_mi(_box(Vector3(0.95, 0.12, 0.95)), Vector3(0, 0.44, 0), root, _mats["bush"], "Soil")
	_mi(_sphere(0.16, 0.22), Vector3(-0.22, 0.62, 0.1), root, _mats["flower"], "BloomA")
	_mi(_sphere(0.14, 0.20), Vector3(0.2, 0.60, -0.12), root, _mats["flower_y"], "BloomB")
	_mi(_sphere(0.12, 0.18), Vector3(0.05, 0.58, 0.22), root, _mats["flower"], "BloomC")
	static_world.add_child(root)

func _add_market_stall(pos: Vector3, yaw: float) -> void:
	## v1.78 refine: simple awning stall so the plaza feels like a village, not empty grass.
	var root := Node3D.new()
	root.name = "MarketStall"
	root.position = pos
	root.rotation.y = yaw
	_mi(_box(Vector3(2.1, 0.18, 1.15)), Vector3(0, 0.55, 0), root, _mats["wood"], "Counter")
	_mi(_box(Vector3(0.14, 1.15, 0.14)), Vector3(-0.95, 0.95, -0.45), root, _mats["wood_light"], "PostL")
	_mi(_box(Vector3(0.14, 1.15, 0.14)), Vector3(0.95, 0.95, -0.45), root, _mats["wood_light"], "PostR")
	_mi(_box(Vector3(2.3, 0.08, 1.4)), Vector3(0, 1.55, -0.1), root, _mats["roof"], "Awning")
	_mi(_box(Vector3(0.45, 0.35, 0.45)), Vector3(-0.45, 0.82, 0.05), root, _mats["barrel"], "GoodsA")
	_mi(_box(Vector3(0.38, 0.28, 0.38)), Vector3(0.4, 0.78, 0.1), root, _mats["wood_light"], "GoodsB")
	_mi(_sphere(0.16, 0.18), Vector3(0.05, 0.78, 0.22), root, _mats["flower_y"], "GoodsC")
	static_world.add_child(root)


func _add_hedge(pos: Vector3, yaw: float = 0.0, length: float = 1.8) -> void:
	## v1.80 world: low village hedge (visual only — navmesh / corridors stay open).
	var root := Node3D.new()
	root.name = "Hedge"
	root.position = pos
	root.rotation.y = yaw
	_mi(_box(Vector3(length, 0.78, 0.40)), Vector3(0, 0.39, 0), root, _mats["hedge"], "Body")
	_mi(_sphere(0.26, 0.34), Vector3(-length * 0.28, 0.78, 0.02), root, _mats["leaf"], "TopA")
	_mi(_sphere(0.22, 0.30), Vector3(length * 0.24, 0.74, -0.04), root, _mats["leaf_alt"], "TopB")
	static_world.add_child(root)


func _add_yard_cart(pos: Vector3, yaw: float) -> void:
	## v1.80 world: chunky market cart so the plaza has a readable village silhouette.
	var root := Node3D.new()
	root.name = "YardCart"
	root.position = pos
	root.rotation.y = yaw
	_mi(_box(Vector3(1.75, 0.16, 0.98)), Vector3(0, 0.58, 0), root, _mats["wood"], "Bed")
	_mi(_box(Vector3(1.60, 0.30, 0.08)), Vector3(0, 0.76, 0.46), root, _mats["wood_light"], "SideN")
	_mi(_box(Vector3(1.60, 0.30, 0.08)), Vector3(0, 0.76, -0.46), root, _mats["wood_light"], "SideS")
	_mi(_cyl(0.22, 0.22, 0.12), Vector3(-0.55, 0.28, 0.52), root, _mats["wood"], "WheelFL")
	_mi(_cyl(0.22, 0.22, 0.12), Vector3(-0.55, 0.28, -0.52), root, _mats["wood"], "WheelFR")
	_mi(_cyl(0.22, 0.22, 0.12), Vector3(0.55, 0.28, 0.52), root, _mats["wood"], "WheelBL")
	_mi(_cyl(0.22, 0.22, 0.12), Vector3(0.55, 0.28, -0.52), root, _mats["wood"], "WheelBR")
	_mi(_box(Vector3(0.12, 0.12, 0.95)), Vector3(1.00, 0.58, 0), root, _mats["wood"], "Tongue")
	_mi(_box(Vector3(0.42, 0.32, 0.38)), Vector3(-0.25, 0.82, 0.05), root, _mats["barrel"], "LoadA")
	_mi(_box(Vector3(0.34, 0.26, 0.32)), Vector3(0.35, 0.78, -0.08), root, _mats["wood_light"], "LoadB")
	static_world.add_child(root)


func _add_landmark_plaza(pos: Vector3, radius: float, plaza_name: String) -> void:
	## v1.80 world: visual yard disc + curb so wilds landmarks have presence (no collision).
	var root := Node3D.new()
	root.name = plaza_name
	root.position = pos
	_mi(_cyl(radius, radius, 0.05), Vector3(0, 0.02, 0), root, _mats["cobble"], "Yard")
	_mi(_cyl(radius * 0.62, radius * 0.62, 0.042), Vector3(0, 0.028, 0), root, _mats["cobble_light"], "Inner")
	for i in 10:
		var ang := i * TAU / 10.0
		var curb := _mi(_box(Vector3(0.58, 0.16, 0.26)), Vector3(cos(ang) * radius * 0.96, 0.09, sin(ang) * radius * 0.96), root, _mats["stone"], "Curb%d" % i)
		curb.rotation.y = -ang
	static_world.add_child(root)


func _dress_landmark_ring(center: Vector3, radius: float) -> void:
	## Visual foliage ring just outside the yard (skips travel corridors).
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(center.x * 17.0 + center.z * 13.0)) + 11
	for i in 8:
		var ang := i * TAU / 8.0 + 0.18
		var p := center + Vector3(cos(ang) * radius, 0, sin(ang) * radius)
		if _in_travel_corridor(p):
			continue
		if i % 2 == 0:
			_add_bush(p, rng)
		else:
			_add_flowers(p, rng)


func _dress_world_finish() -> void:
	## v1.80 world: landmark yards on dry clearings (skip mill/reed/lookout water-or-rock).
	_add_landmark_plaza(Vector3(0.5, 0, -48), 4.6, "LandmarkPlazaGlade")
	_add_landmark_plaza(Vector3(-24, 0, -54), 4.2, "LandmarkPlazaRidge")
	_add_landmark_plaza(Vector3(38, 0, -36), 4.4, "LandmarkPlazaHollow")
	_add_landmark_plaza(Vector3(-38, 0, -34), 3.8, "LandmarkPlazaWillow")
	_add_landmark_plaza(Vector3(48, 0, 8), 4.0, "LandmarkPlazaCross")
	_add_landmark_plaza(Vector3(-48, 0, 8), 4.0, "LandmarkPlazaArch")
	_add_landmark_plaza(Vector3(48, 0, -22), 4.2, "LandmarkPlazaKnoll")
	_add_landmark_plaza(Vector3(-42, 0, -20), 4.0, "LandmarkPlazaBirch")
	_add_landmark_plaza(Vector3(22, 0, 48), 4.0, "LandmarkPlazaFern")
	_add_landmark_plaza(Vector3(-48, 0, 42), 4.0, "LandmarkPlazaHeather")
	_add_landmark_plaza(Vector3(48, 0, 42), 4.0, "LandmarkPlazaThistle")
	_dress_landmark_ring(Vector3(0.5, 0, -48), 7.4)
	_dress_landmark_ring(Vector3(-24, 0, -54), 6.8)
	_dress_landmark_ring(Vector3(38, 0, -36), 7.0)
	_dress_landmark_ring(Vector3(-38, 0, -34), 6.6)
	_dress_landmark_ring(Vector3(48, 0, 8), 6.6)
	_dress_landmark_ring(Vector3(-48, 0, 8), 6.6)
	_dress_landmark_ring(Vector3(48, 0, -22), 6.8)
	_dress_landmark_ring(Vector3(-42, 0, -20), 6.6)
	_dress_landmark_ring(Vector3(22, 0, 48), 6.6)
	_dress_landmark_ring(Vector3(-48, 0, 42), 6.6)
	_dress_landmark_ring(Vector3(48, 0, 42), 6.6)

func _spawn_npcs() -> void:
	for n in world_data.get("npcs", []):
		var npc: Node = NpcScene.instantiate()
		npc.npc_id = n["id"]
		npc.npc_name = n["name"]
		npc.title = n["title"]
		npc.guild = n["guild"]
		npc.quest_ids = PackedStringArray(n["quest_ids"])
		npc.accent = _hex_color(n["color"])
		npc.position = Vector3(n["x"], 0, n["z"])
		npc.talk_requested.connect(func(p): npc_talk.emit(p))
		entities.add_child(npc)

func _spawn_enemies() -> void:
	for s in EnemyDB.spawns:
		var e: Node = EnemyScene.instantiate()
		e.kind = s["kind"]
		e.spawn_id = s["id"]
		e.position = Vector3(s["x"], 0, s["z"])
		entities.add_child(e)

func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	entities.add_child(player)
	player.global_position = Vector3(GameState.position_xz.x, 0, GameState.position_xz.y)


func _process(delta: float) -> void:
	if _door_cooldown > 0.0:
		_door_cooldown -= delta
	if _landmark_toast_cd > 0.0:
		_landmark_toast_cd -= delta
	_update_day_night(delta)
	_update_weather(delta)
	_update_quest_desk_highlights()
	_update_door_glows()
	_update_landmark_approach()
	_update_ambient_critters(delta)
	_update_reed_sway(delta)  # Wave 57: soft reed sway near Reed Pool
	_update_thistle_sway(delta)  # Wave 58: soft thistle sway at Thistle Rise
	_update_willow_sway(delta)  # Wave 61: soft willow weep sway at Willow Bend
	_update_fern_sway(delta)  # Wave 62: soft fern sway at Fern Dell
	_update_heather_sway(delta)  # Wave 63: soft heather sway at Heather Heath
	_update_hall_light_dip(delta)  # Wave 63: soft hall enter/exit light dip


func _landmark_zones() -> Array:
	## Soft approach radii for wilds landmarks (RuneScape-feel area toasts).
	## first_toast = first discovery ever; return_toast = later visits (once per visit).
	return [
		{"id": "glade", "pos": Vector3(0.5, 0, -48), "enter": 11.0, "exit": 14.0,
			"first_toast": "First discovery: Lantern Glade — lanterns glow soft among the trees.",
			"return_toast": "Back at Lantern Glade — the soft light still waits."},
		{"id": "ridge", "pos": Vector3(-24, 0, -54), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Pine Ridge — cool air under the pines.",
			"return_toast": "Back at Pine Ridge — the pines still whisper softly."},
		{"id": "garden", "pos": Vector3(30, 0, 18), "enter": 9.0, "exit": 12.0,
			"first_toast": "First discovery: Prayer Garden — a quiet place to give thanks.",
			"return_toast": "Back at the Prayer Garden — a peaceful place to rest."},
		{"id": "lookout", "pos": Vector3(40, 0, 34), "enter": 9.0, "exit": 12.0,
			"first_toast": "First discovery: Lookout Rock — a clear view over the green.",
			"return_toast": "Back at Lookout Rock — the green still stretches wide."},
		{"id": "mill", "pos": Vector3(-36, 0, 30), "enter": 9.0, "exit": 12.0,
			"first_toast": "First discovery: Mill Bridge — water and stone work together.",
			"return_toast": "Back at Mill Bridge — the creek still sings under the planks."},
		{"id": "hollow", "pos": Vector3(38, 0, -36), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Cedar Hollow — quiet trees and a gentle clearing.",
			"return_toast": "Back at Cedar Hollow — the cedars still stand still and kind."},
		{"id": "willow", "pos": Vector3(-38, 0, -34), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Willow Bend — soft leaves trail over quiet water.",
			"return_toast": "Back at Willow Bend — the willows still lean gently by the brook."},
		{"id": "reed", "pos": Vector3(-20, 0, 48), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Reed Pool — tall reeds ring a quiet south pool.",
			"return_toast": "Back at Reed Pool — the reeds still whisper by the water."},
		{"id": "cross", "pos": Vector3(48, 0, 8), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Quiet Cross — a simple wooden cross on a grassy knoll for thanksgiving.",
			"return_toast": "Back at Quiet Cross — a peaceful place to give thanks."},
		{"id": "arch", "pos": Vector3(-48, 0, 8), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Stone Arch — a weathered stone gateway opens toward the western wilds.",
			"return_toast": "Back at Stone Arch — the old gateway still welcomes weary feet."},
		{"id": "knoll", "pos": Vector3(48, 0, -22), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Amber Knoll — a warm honey-stone rise with soft wildflowers.",
			"return_toast": "Back at Amber Knoll — the amber stones still catch the light kindly."},
		{"id": "birch", "pos": Vector3(-42, 0, -20), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Birch Rest — pale birch trunks and a quiet place to sit awhile.",
			"return_toast": "Back at Birch Rest — the pale trunks still stand gentle and calm."},
		{"id": "fern", "pos": Vector3(22, 0, 48), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Fern Dell — soft green fronds fill a quiet south hollow.",
			"return_toast": "Back at Fern Dell — the fronds still rustle kindly underfoot."},
		{"id": "heather", "pos": Vector3(-48, 0, 42), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Heather Heath — purple heather rolls across a quiet west rise.",
			"return_toast": "Back at Heather Heath — the heather still nods gently in the breeze."},
		{"id": "thistle", "pos": Vector3(48, 0, 42), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Thistle Rise — spiky purple thistles crown a quiet east rise.",
			"return_toast": "Back at Thistle Rise — the thistles still stand proud in the soft breeze."},
		{"id": "maple", "pos": Vector3(-48, 0, -48), "enter": 10.0, "exit": 13.0,
			"first_toast": "First discovery: Maple Copse — warm maple leaves drift in a quiet northwest stand.",
			"return_toast": "Back at Maple Copse — the maples still rustle kindly in the soft wind."},
	]

func _landmark_display_name(lid: String) -> String:
	## Wave 46: plain landmark names for HUD near-chip.
	match lid:
		"glade":
			return "Lantern Glade"
		"ridge":
			return "Pine Ridge"
		"garden":
			return "Prayer Garden"
		"lookout":
			return "Lookout Rock"
		"mill":
			return "Mill Bridge"
		"hollow":
			return "Cedar Hollow"
		"willow":
			return "Willow Bend"
		"reed":
			return "Reed Pool"
		"cross":
			return "Quiet Cross"
		"arch":
			return "Stone Arch"
		"knoll":
			return "Amber Knoll"
		"birch":
			return "Birch Rest"
		"fern":
			return "Fern Dell"
		"heather":
			return "Heather Heath"
		"thistle":
			return "Thistle Rise"
		"maple":
			return "Maple Copse"
		_:
			return lid.capitalize()

func _update_landmark_approach() -> void:
	if player == null or not is_instance_valid(player):
		return
	if _inside_hall != "":
		if _landmark_here != "":
			GameState.clear_landmark_greeted(_landmark_here)
			_landmark_here = ""
		_landmark_dist = 9999.0
		return
	var ppos: Vector3 = player.global_position
	var best_id := ""
	var best_zone: Dictionary = {}
	var best_d := 9999.0
	for z in _landmark_zones():
		var c: Vector3 = z["pos"]
		var d: float = Vector2(ppos.x - c.x, ppos.z - c.z).length()
		var enter_r: float = float(z["enter"])
		var exit_r: float = float(z["exit"])
		var active: bool = d <= enter_r or (_landmark_here == str(z["id"]) and d <= exit_r)
		if active and d < best_d:
			best_d = d
			best_id = str(z["id"])
			best_zone = z
	if best_id == "":
		if _landmark_here != "":
			GameState.clear_landmark_greeted(_landmark_here)
			_landmark_here = ""
		_landmark_dist = 9999.0
		return
	_landmark_dist = best_d  # Wave 69: paces for ✦ landmark chip
	if best_id != _landmark_here:
		if _landmark_here != "" and _landmark_here != best_id:
			GameState.clear_landmark_greeted(_landmark_here)
		_landmark_here = best_id
		# Once-per-visit: greet if not already remembered (survives save/reload in-zone).
		if not GameState.has_landmark_greeted(best_id):
			var first := false
			if GameState.has_method("mark_landmark_discovered"):
				first = GameState.mark_landmark_discovered(best_id)
			var msg := ""
			if first:
				var raw_f := str(best_zone.get("first_toast", best_zone.get("return_toast", "")))
				# Wave 40/75: clearer first-discovery landmark toast (RuneScape-chunky, wholesome)
				if raw_f.begins_with("First discovery:"):
					msg = "✦ First discovery ·" + raw_f.substr("First discovery:".length())
				else:
					msg = "✦ First discovery · " + raw_f
			else:
				var raw_r := str(best_zone.get("return_toast", best_zone.get("first_toast", "")))
				var stripped := raw_r
				if stripped.begins_with("Back at the "):
					stripped = stripped.substr("Back at the ".length())
				elif stripped.begins_with("Back at "):
					stripped = stripped.substr("Back at ".length())
				msg = "✦ Near · " + stripped
			# Wave 60: clearer landmark approach with paces (RuneScape-chunky, wholesome)
			if msg != "":
				var paces: int = maxi(1, int(round(best_d / 1.15)))
				msg = "%s · ~%d paces" % [msg, paces]
			if _landmark_toast_cd <= 0.0 and msg != "":
				GameState.toast.emit(msg)
				_landmark_toast_cd = 2.5
			GameState.mark_landmark_greeted(best_id)

func note_soft_travel_arrival(pos: Vector3) -> bool:
	## Soft Travel already toasts the destination — sync zone memory without a second approach toast.
	## Returns true if this soft-travel was a first-ever discovery of a landmark.
	var best_id := ""
	var best_d := 9999.0
	for z in _landmark_zones():
		var c: Vector3 = z["pos"]
		var d: float = Vector2(pos.x - c.x, pos.z - c.z).length()
		if d <= float(z["enter"]) and d < best_d:
			best_d = d
			best_id = str(z["id"])
	if _landmark_here != "" and _landmark_here != best_id:
		GameState.clear_landmark_greeted(_landmark_here)
	_landmark_here = best_id
	var first := false
	if best_id != "":
		if GameState.has_method("mark_landmark_discovered"):
			first = GameState.mark_landmark_discovered(best_id)
		GameState.mark_landmark_greeted(best_id)
	return first

func _setup_day_night() -> void:
	_sun = get_node_or_null("Sun") as DirectionalLight3D
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we:
		_env = we.environment
	# v1.80 world: warm fill so midday shadows stay readable, not muddy gray
	if get_node_or_null("DayFill") == null:
		var fill := DirectionalLight3D.new()
		fill.name = "DayFill"
		fill.light_color = Color(1.0, 0.90, 0.74)
		fill.light_energy = 0.32
		fill.shadow_enabled = false
		fill.rotation_degrees = Vector3(-28, 210, 0)
		add_child(fill)
	_update_day_night(0.0)

func _update_day_night(delta: float) -> void:
	_day_phase = fmod(_day_phase + delta / _day_seconds, 1.0)
	# Smooth day curve: bright midday, soft dusk, readable night (never pitch black)
	var ang := _day_phase * TAU
	var dayness := clampf(0.55 + 0.45 * sin(ang - 0.2), 0.28, 1.0)
	if _inside_hall != "":
		dayness = 0.75  # indoor lamps feel steady
	if _sun:
		_sun.light_energy = lerpf(0.38, 1.28, dayness)
		var warm := Color(1.0, 0.93, 0.70)
		var cool := Color(0.80, 0.86, 1.0)
		_sun.light_color = warm.lerp(cool, 1.0 - dayness)
		# Orbit sun a bit
		var elev := lerpf(20.0, 58.0, dayness)
		var az := _day_phase * 360.0
		_sun.rotation_degrees = Vector3(-elev, az, 0)
	var fill_n := get_node_or_null("DayFill") as DirectionalLight3D
	if fill_n:
		fill_n.light_energy = 0.0 if _inside_hall != "" else lerpf(0.12, 0.34, dayness)
	if _env:
		var day_sky := Color(0.55, 0.76, 0.94)
		var dusk_sky := Color(0.72, 0.48, 0.42)
		var night_sky := Color(0.14, 0.18, 0.30)
		var sky: Color
		if dayness > 0.65:
			sky = day_sky
		elif dayness > 0.4:
			sky = day_sky.lerp(dusk_sky, (0.65 - dayness) / 0.25)
		else:
			sky = dusk_sky.lerp(night_sky, (0.4 - dayness) / 0.4)
		_env.background_color = sky
		_env.ambient_light_color = Color(1.0, 0.94, 0.82).lerp(Color(0.50, 0.58, 0.78), 1.0 - dayness)
		_env.ambient_light_energy = lerpf(0.42, 0.74, dayness)
		_env.fog_light_color = sky.lightened(0.16)
		var base_fog := lerpf(0.0022, 0.0012, dayness)
		if _inside_hall != "":
			_env.fog_density = 0.0004
		else:
			_env.fog_density = base_fog + _fog_boost

	if AudioBus.has_method("set_day_night_audio") and _inside_hall == "":
		# Wave 44: pass day_phase for soft morning bird swell at dawn
		AudioBus.set_day_night_audio(dayness, _day_phase)
	elif AudioBus.has_method("set_day_night_audio") and _inside_hall != "":
		# Soft indoor: bias toward quiet day pad
		AudioBus.set_day_night_audio(0.55, _day_phase)
	# Wave 34: soft outdoor wind whoosh (off indoors)
	if AudioBus.has_method("set_wind_audio"):
		AudioBus.set_wind_audio(_inside_hall == "")
	# Wave 37: soft indoor hall reverb cue (on indoors)
	if AudioBus.has_method("set_hall_reverb"):
		AudioBus.set_hall_reverb(_inside_hall != "")
	if AudioBus.has_method("set_hall_chatter"):
		AudioBus.set_hall_chatter(_inside_hall != "")
	_update_leaf_rustle()
	_update_brook_murmur()
	_update_brook_sparkle()
	_update_hall_wind_chime()
	_update_village_dusk_lamps(dayness)
	_update_knoll_dusk_glow(dayness)  # Wave 59: soft amber knoll glow at dusk
	_update_arch_dusk_glow(dayness)  # Wave 64: soft stone arch glow at dusk
	_update_cross_dusk_glow(dayness)  # Wave 65: soft quiet cross lantern at dusk
	_update_plaza_campfire(dayness)


func _build_plaza_campfire() -> void:
	## Wave 31/32/33/45/77: soft campfire glow + ember sparks + soft smoke wisps + crackle near the village plaza (RuneScape-chunky, wholesome).
	var root := Node3D.new()
	root.name = "PlazaCampfire"
	# East of fountain keep-clear, near benches — warm hearth feel
	root.position = _plaza_campfire_pos
	_mi(_cyl(0.65, 0.7, 0.12), Vector3(0, 0.08, 0), root, _mats["rock"], "Ring")
	_mi(_box(Vector3(0.45, 0.12, 0.12)), Vector3(0.05, 0.18, 0.02), root, _mats["wood"], "LogA")
	_mi(_box(Vector3(0.12, 0.12, 0.42)), Vector3(-0.05, 0.18, -0.02), root, _mats["wood"], "LogB")
	# Soft flame orb (always-on warm glow)
	_mi(_sphere(0.18, 0.32), Vector3(0, 0.42, 0), root, _mats["lantern_glow"], "Flame")
	var light := OmniLight3D.new()
	light.name = "CampfireGlow"
	light.light_color = Color(1.0, 0.74, 0.40)  # Wave 77: soft campfire glow polish
	light.light_energy = 1.22
	light.omni_range = 8.2
	light.omni_attenuation = 1.1
	light.shadow_enabled = false
	light.position = Vector3(0, 0.55, 0)
	root.add_child(light)
	_plaza_campfire_light = light
	# Soft ember motes (Wave 32: denser loft + bright spark tips)
	var embers := CPUParticles3D.new()
	embers.name = "CampfireEmbers"
	embers.emitting = true
	embers.amount = 22
	embers.lifetime = 2.1
	embers.preprocess = 0.8
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 0.26
	embers.direction = Vector3(0, 1, 0)
	embers.spread = 32.0
	embers.initial_velocity_min = 0.3
	embers.initial_velocity_max = 1.05
	embers.gravity = Vector3(0, 0.12, 0)
	embers.scale_amount_min = 0.07
	embers.scale_amount_max = 0.2
	embers.color = Color(1.0, 0.68, 0.28, 0.88)
	var ember_ramp := Gradient.new()
	ember_ramp.colors = PackedColorArray([
		Color(1.0, 0.85, 0.45, 0.95),
		Color(1.0, 0.55, 0.2, 0.7),
		Color(0.55, 0.22, 0.08, 0.0),
	])
	embers.color_ramp = ember_ramp
	embers.position = Vector3(0, 0.35, 0)
	root.add_child(embers)
	HeadlessGuard.guard_particles(embers)
	# Bright spark tips that pop above the hearth (Wave 32 polish)
	var sparks := CPUParticles3D.new()
	sparks.name = "CampfireSparks"
	sparks.emitting = true
	sparks.amount = 10
	sparks.lifetime = 1.15
	sparks.preprocess = 0.4
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 0.12
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 18.0
	sparks.initial_velocity_min = 0.7
	sparks.initial_velocity_max = 1.6
	sparks.gravity = Vector3(0, -0.05, 0)
	sparks.scale_amount_min = 0.04
	sparks.scale_amount_max = 0.1
	sparks.color = Color(1.0, 0.92, 0.55, 0.95)
	var spark_ramp := Gradient.new()
	spark_ramp.colors = PackedColorArray([
		Color(1.0, 0.98, 0.75, 1.0),
		Color(1.0, 0.7, 0.3, 0.55),
		Color(0.8, 0.3, 0.1, 0.0),
	])
	sparks.color_ramp = spark_ramp
	sparks.position = Vector3(0, 0.48, 0)
	root.add_child(sparks)
	HeadlessGuard.guard_particles(sparks)
	# Soft rising smoke wisps (Wave 45) — gentle gray loft above the hearth
	var smoke := CPUParticles3D.new()
	smoke.name = "CampfireSmoke"
	smoke.emitting = true
	smoke.amount = 24  # Wave 77: soft campfire smoke wisps polish
	smoke.lifetime = 4.1
	smoke.preprocess = 1.5
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 0.24
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 28.0
	smoke.initial_velocity_min = 0.20
	smoke.initial_velocity_max = 0.68
	smoke.gravity = Vector3(0.035, 0.11, 0.02)
	smoke.scale_amount_min = 0.22
	smoke.scale_amount_max = 0.74
	smoke.color = Color(0.56, 0.53, 0.49, 0.34)  # Wave 77: soft campfire smoke/glow polish
	var smoke_ramp := Gradient.new()
	smoke_ramp.colors = PackedColorArray([
		Color(0.65, 0.62, 0.58, 0.28),
		Color(0.5, 0.48, 0.45, 0.18),
		Color(0.4, 0.4, 0.4, 0.0),
	])
	smoke.color_ramp = smoke_ramp
	smoke.position = Vector3(0, 0.55, 0)
	root.add_child(smoke)
	HeadlessGuard.guard_particles(smoke)
	_place_label3d(root, "Campfire", 28, Vector3(0, 1.6, 0), 5, Color(1, 0.92, 0.7, 0.7))
	static_world.add_child(root)



func _near_points_xz(points: Array, origin: Vector3, dist_sq: float, stride: int = 1) -> bool:
	for i in points.size():
		if stride > 1 and i % stride != 0:
			continue
		var p: Vector3 = points[i]
		var dx: float = origin.x - p.x
		var dz: float = origin.z - p.z
		if dx * dx + dz * dz < dist_sq:
			return true
	return false


func _update_leaf_rustle() -> void:
	## Wave 37: soft leaf rustle when outdoors and near a tree (throttled; respects mute via AudioBus).
	if not AudioBus.has_method("set_leaf_rustle"):
		return
	if _inside_hall != "" or player == null:
		AudioBus.set_leaf_rustle(false)
		return
	# Throttle proximity scans (~3×/sec)
	var now: float = float(Time.get_ticks_msec()) * 0.001
	if now - _leaf_check_t < 0.33:
		return
	_leaf_check_t = now
	var near := _near_points_xz(_tree_positions, player.global_position, 30.25, 3 if _tree_positions.size() > 40 else 1)
	AudioBus.set_leaf_rustle(near)

func _update_brook_murmur() -> void:
	## Wave 38: soft brook murmur when outdoors and near water landmarks (throttled; respects mute via AudioBus).
	## Wave 73: soft brook murmur polish — a touch wider hear-distance (RuneScape-chunky, wholesome).
	if not AudioBus.has_method("set_brook_murmur"):
		return
	if _inside_hall != "" or player == null:
		AudioBus.set_brook_murmur(false)
		return
	var now: float = float(Time.get_ticks_msec()) * 0.001
	if now - _brook_check_t < 0.33:
		return
	_brook_check_t = now
	var near := _near_points_xz(_water_positions, player.global_position, 144.0)  # Wave 73: 12^2 — soft brook murmur polish hear-distance
	AudioBus.set_brook_murmur(near)



func _update_hall_wind_chime() -> void:
	## Wave 52: soft wind chime when outdoors near guild halls (throttled; respects mute via AudioBus).
	if not AudioBus.has_method("set_wind_chime"):
		return
	if _inside_hall != "" or player == null:
		AudioBus.set_wind_chime(false)
		return
	var now: float = float(Time.get_ticks_msec()) * 0.001
	if now - _wind_chime_check_t < 0.33:
		return
	_wind_chime_check_t = now
	var pts: Array = []
	if not _hall_eaves.is_empty():
		pts = _hall_eaves
	else:
		for b in world_data.get("buildings", []):
			pts.append(Vector3(float(b.get("x", 0)), 0.0, float(b.get("z", 0))))
	var near := _near_points_xz(pts, player.global_position, 132.25)  # ~11.5^2 soft hear-distance by halls
	AudioBus.set_wind_chime(near)


func _update_plaza_campfire(dayness: float) -> void:
	## Soft hearth stays lit by day; warms up a bit at dusk. Wave 33: near-hearth crackle.
	## Wave 60: plaza dusk lantern flicker sync — hearth breathes with village lamp flicker.
	## Wave 74: plaza dusk lantern sync polish — shared phase + warmer dusk breath with village lamps (RuneScape-chunky, wholesome).
	if _plaza_campfire_light == null or not is_instance_valid(_plaza_campfire_light):
		return
	var dusk: float = clampf((0.62 - dayness) / 0.35, 0.0, 1.0)
	var t_ms: float = float(Time.get_ticks_msec())
	var pulse: float = 0.88 + 0.14 * abs(sin(t_ms * 0.0042))
	# Sync soft irregular flicker with village dusk lamps (same phase recipe — Wave 74 polish)
	var flicker: float = 1.0 + 0.07 * sin(t_ms * 0.011) + 0.045 * sin(t_ms * 0.027 + 1.7)
	_plaza_campfire_light.light_energy = (0.88 + dusk * 1.28) * pulse * clampf(flicker, 0.86, 1.14)
	# Soft crackle when outdoors and near the plaza hearth (respects mute via AudioBus)
	if AudioBus.has_method("set_campfire_audio") and player:
		var near: bool = _inside_hall == "" and player.global_position.distance_to(_plaza_campfire_pos) < 14.0
		AudioBus.set_campfire_audio(near)

func _update_village_dusk_lamps(dayness: float) -> void:
	## Wave 28: village lamp posts warm up as dusk falls (RuneScape-chunky, wholesome).
	## Wave 35: soft dusk lamp flicker — gentle irregular glow, not a strobe.
	## Wave 74: plaza dusk lantern sync polish — shared flicker phase with plaza hearth (RuneScape-chunky, wholesome).
	if _village_lamp_lights.is_empty():
		return
	var dusk: float = clampf((0.58 - dayness) / 0.30, 0.0, 1.0)
	var t_ms: float = float(Time.get_ticks_msec())
	var pulse: float = 0.90 + 0.10 * abs(sin(t_ms * 0.0022))
	# Soft irregular flicker layered on the slow pulse (shared recipe with plaza hearth)
	var flicker: float = 1.0 + 0.07 * sin(t_ms * 0.011) + 0.045 * sin(t_ms * 0.027 + 1.7)
	var energy: float = dusk * 1.68 * pulse * clampf(flicker, 0.86, 1.14)
	var i: int = 0
	for light in _village_lamp_lights:
		if light == null or not is_instance_valid(light):
			continue
		# Tiny per-lamp phase so posts don't blink in lockstep
		var phase: float = 1.0 + 0.035 * sin(t_ms * 0.019 + float(i) * 1.3)
		var e: float = energy * clampf(phase, 0.9, 1.1)
		light.light_energy = e
		light.visible = e > 0.04
		i += 1

func _apply_dusk_glow_lights(lights: Array, dayness: float, pulse_a: float, pulse_b: float, pulse_speed: float, energy_scale: float, phase_speed: float, phase_spread: float) -> void:
	if lights.is_empty():
		return
	var dusk: float = clampf((0.58 - dayness) / 0.30, 0.0, 1.0)
	var t_ms: float = float(Time.get_ticks_msec())
	var pulse: float = pulse_a + pulse_b * abs(sin(t_ms * pulse_speed))
	var energy: float = dusk * energy_scale * pulse
	var i: int = 0
	for light in lights:
		if light == null or not is_instance_valid(light):
			continue
		var phase: float = 1.0 + 0.04 * sin(t_ms * phase_speed + float(i) * phase_spread)
		var e: float = energy * clampf(phase, 0.88, 1.12)
		# Rim light a touch softer than crest
		if "Rim" in str(light.name):
			e *= 0.55
		light.light_energy = e
		light.visible = e > 0.04
		i += 1


func _update_knoll_dusk_glow(dayness: float) -> void:
	## Wave 59: soft amber knoll glow at dusk — warm honey light on Amber Knoll crest (RuneScape-chunky, wholesome).
	## Wave 73: soft Amber Knoll amber-glow polish at dusk — warmer honey energy + gentler pulse (RuneScape-chunky, wholesome).
	_apply_dusk_glow_lights(_knoll_dusk_lights, dayness, 0.88, 0.12, 0.0017, 2.35, 0.017, 1.1)


func _update_arch_dusk_glow(dayness: float) -> void:
	## Wave 64: soft stone arch glow at dusk — cool limestone OmniLight on Stone Arch gateway (RuneScape-chunky, wholesome).
	_apply_dusk_glow_lights(_arch_dusk_lights, dayness, 0.90, 0.10, 0.0018, 1.70, 0.015, 1.2)


func _update_cross_dusk_glow(dayness: float) -> void:
	## Wave 65: soft quiet cross lantern at dusk — warm honey OmniLight on Quiet Cross knoll (RuneScape-chunky, wholesome).
	_apply_dusk_glow_lights(_cross_dusk_lights, dayness, 0.90, 0.10, 0.0021, 1.80, 0.016, 1.15)


func _build_interiors() -> void:
	## Simple enterable guild-hall volumes: walk into the door, teleport to a cozy interior.
	_interior_root = Node3D.new()
	_interior_root.name = "Interiors"
	_interior_root.position = Vector3(120, 0, 0)
	add_child(_interior_root)
	var halls: Array = world_data.get("buildings", [])
	for i in halls.size():
		var b: Dictionary = halls[i]
		_add_door_volume(b)
		_add_interior_room(b, i)

func _add_door_volume(b: Dictionary) -> void:
	var area := Area3D.new()
	area.name = "Door_%s" % b.get("id", "hall")
	area.monitoring = true
	area.monitorable = false
	area.collision_layer = 0
	area.collision_mask = 2  # player layer
	var d: float = float(b.get("d", 5))
	area.position = Vector3(float(b["x"]), 1.0, float(b["z"]) + d * 0.5 + 0.7)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.2, 1.4)
	col.shape = box
	area.add_child(col)
	# Visible soft door marker — Wave 27: warmer pulse glow (RuneScape-chunky Enter)
	var mat := _mat(Color(1.0, 0.92, 0.45, 0.42), 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var glow_mi := _mi(_box(Vector3(1.35, 2.15, 0.18)), Vector3(0, 0.1, 0), area, mat, "DoorGlow")
	# Soft ground wash under the door
	var wash := _mat(Color(1.0, 0.88, 0.4, 0.22), 0.5)
	wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var wash_mi := _mi(_box(Vector3(1.8, 0.05, 1.1)), Vector3(0, -0.95, 0.15), area, wash, "DoorWash")
	area.set_meta("door_glow_mi", glow_mi)
	area.set_meta("door_wash_mi", wash_mi)
	_door_glow_mats.append({"glow": mat, "wash": wash, "label_area": area})
	_place_label3d(area, "Enter", 38, Vector3(0, 1.55, 0))
	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"):
			_enter_hall(str(b.get("id", "")), str(b.get("label", "Hall")), body)
	)
	static_world.add_child(area)

func _add_interior_room(b: Dictionary, index: int) -> void:
	var room := Node3D.new()
	room.name = "Interior_%s" % b.get("id", index)
	room.position = Vector3(float(index) * 28.0, 0, 0)
	room.set_meta("hall_id", str(b.get("id", "")))
	room.set_meta("hall_label", str(b.get("label", "Hall")))
	room.set_meta("guild", str(b.get("guild", "")))
	_interior_root.add_child(room)
	var col := Color(b.get("color", "#888888"))
	var wall := _mat(col.lightened(0.15))
	var floor_m: Material = _mats["stone"]
	var rug := _mat(col.darkened(0.15))
	# Floor / walls / ceiling with collision shells
	_mi(_box(Vector3(12, 0.2, 12)), Vector3(0, 0.1, 0), room, floor_m, "Floor")
	_add_wall_col(room, Vector3(12, 0.2, 12), Vector3(0, 0.1, 0))  # floor for indoor nav bake
	_add_wall_col(room, Vector3(12, 3.6, 0.35), Vector3(0, 1.85, -6))
	_add_wall_col(room, Vector3(12, 3.6, 0.35), Vector3(0, 1.85, 6))
	_add_wall_col(room, Vector3(0.35, 3.6, 12), Vector3(-6, 1.85, 0))
	_add_wall_col(room, Vector3(0.35, 3.6, 12), Vector3(6, 1.85, 0))
	_mi(_box(Vector3(12, 3.5, 0.3)), Vector3(0, 1.8, -6), room, wall, "WallN")
	_mi(_box(Vector3(12, 3.5, 0.3)), Vector3(0, 1.8, 6), room, wall, "WallS")
	_mi(_box(Vector3(0.3, 3.5, 12)), Vector3(-6, 1.8, 0), room, wall, "WallW")
	_mi(_box(Vector3(0.3, 3.5, 12)), Vector3(6, 1.8, 0), room, wall, "WallE")
	_mi(_box(Vector3(12.2, 0.25, 12.2)), Vector3(0, 3.7, 0), room, _mats["roof"], "Ceiling")
	# Rug
	_mi(_box(Vector3(4.5, 0.04, 3.2)), Vector3(0, 0.22, 0.5), room, rug, "Rug")
	# Quest desk (center-north) — interactable; collision snug to desk mesh
	_add_quest_desk(room, Vector3(0, 0, -3.2), col, str(b.get("guild", "")), str(b.get("label", "Hall")))
	_add_wall_col(room, Vector3(2.75, 0.95, 1.15), Vector3(0, 0.5, -3.2))
	# Side study tables + chairs (with collisions)
	_add_study_table(room, Vector3(-3.4, 0, -1.0), 0.2)
	_add_study_table(room, Vector3(3.4, 0, -1.0), -0.2)
	_add_chair(room, Vector3(-3.4, 0, 0.3), PI)
	_add_chair(room, Vector3(3.4, 0, 0.3), PI)
	# Bookshelves / scroll racks — slightly tighter shelf shells
	_add_bookshelf(room, Vector3(-5.2, 0, -3.5), col)
	_add_bookshelf(room, Vector3(5.2, 0, -3.5), col)
	_add_bookshelf(room, Vector3(-5.2, 0, 2.0), col)
	_add_bookshelf(room, Vector3(5.2, 0, 2.0), col)
	_add_bookshelf(room, Vector3(-5.2, 0, -0.7), col)  # denser west wall
	_add_wall_col(room, Vector3(1.15, 2.0, 0.4), Vector3(-5.2, 1.0, -3.5))
	_add_wall_col(room, Vector3(1.15, 2.0, 0.4), Vector3(5.2, 1.0, -3.5))
	_add_wall_col(room, Vector3(1.15, 2.0, 0.4), Vector3(-5.2, 1.0, 2.0))
	_add_wall_col(room, Vector3(1.15, 2.0, 0.4), Vector3(5.2, 1.0, 2.0))
	_add_wall_col(room, Vector3(1.15, 2.0, 0.4), Vector3(-5.2, 1.0, -0.7))
	# Extra study nook + second desk pair (Wave 9 density, still light)
	_add_study_table(room, Vector3(0.0, 0, 2.4), 0.0)
	_add_chair(room, Vector3(0.0, 0, 3.4), 0.0)
	_add_study_table(room, Vector3(-3.5, 0, 1.6), -0.15)
	_add_chair(room, Vector3(-3.5, 0, 2.5), PI)
	_add_chair(room, Vector3(-0.9, 0, -2.2), 0.4)  # seat at quest desk
	# Wall plaque near desk
	_mi(_box(Vector3(1.1, 0.7, 0.06)), Vector3(-2.2, 1.8, -5.7), room, _mat(col.darkened(0.25)), "Plaque")
	_place_label3d(room, "Mastery Desk", 26, Vector3(-2.2, 2.35, -5.5))
	# Benches along walls (with snug collision)
	_mi(_box(Vector3(2.2, 0.45, 0.5)), Vector3(-2.5, 0.55, 4.2), room, _mats["bench"], "BenchL")
	_mi(_box(Vector3(2.2, 0.45, 0.5)), Vector3(2.5, 0.55, 4.2), room, _mats["bench"], "BenchR")
	_add_wall_col(room, Vector3(2.1, 0.5, 0.45), Vector3(-2.5, 0.5, 4.2))
	_add_wall_col(room, Vector3(2.1, 0.5, 0.45), Vector3(2.5, 0.5, 4.2))
	# Barrel + crate + notice board
	var bar := Node3D.new()
	bar.position = Vector3(-4.5, 0, 3.5)
	room.add_child(bar)
	_mi(_cyl(0.32, 0.35, 0.8), Vector3(0, 0.4, 0), bar, _mats["barrel"], "Barrel")
	_add_wall_col(room, Vector3(0.65, 0.85, 0.65), Vector3(-4.5, 0.45, 3.5))
	_mi(_box(Vector3(0.65, 0.5, 0.65)), Vector3(4.4, 0.28, 3.4), room, _mats["wood_light"], "Crate")
	_add_wall_col(room, Vector3(0.6, 0.55, 0.6), Vector3(4.4, 0.3, 3.4))
	_mi(_box(Vector3(1.6, 1.1, 0.08)), Vector3(0, 1.6, 5.5), room, _mat(col.darkened(0.35)), "NoticeBoard")
	_place_label3d(room, "Notices", 28, Vector3(0, 2.3, 5.5))
	# Warm indoor lanterns + real omni lights (stronger, cozy halls)
	_add_lantern(room, Vector3(-3.5, 2.6, -4.0), true)
	_add_lantern(room, Vector3(3.5, 2.6, -4.0), true)
	_add_lantern(room, Vector3(-3.5, 2.6, 3.5), true)
	_add_lantern(room, Vector3(3.5, 2.6, 3.5), true)
	_add_lantern(room, Vector3(0, 2.8, 0.2), true)  # center fill
	_mi(_box(Vector3(2.8, 1.1, 0.08)), Vector3(0, 2.5, -5.7), room, _mat(col.darkened(0.2)), "Banner")
	_add_guild_theme_props(room, str(b.get("guild", "")), col)
	_place_label3d(room, "%s Hall" % b.get("label", "Guild"), 56, Vector3(0, 3.15, 0))
	# Indoor attendant NPC (same quests as outdoor mentor)
	_spawn_indoor_attendant(room, b)
	# Exit volume near south wall
	var exit_area := Area3D.new()
	exit_area.name = "Exit"
	exit_area.monitoring = true
	exit_area.collision_layer = 0
	exit_area.collision_mask = 2
	exit_area.position = Vector3(0, 1.0, 5.0)
	var ecol := CollisionShape3D.new()
	var ebox := BoxShape3D.new()
	ebox.size = Vector3(2.2, 2.2, 1.3)
	ecol.shape = ebox
	exit_area.add_child(ecol)
	var emat := _mat(Color(0.6, 0.85, 0.95, 0.4), 0.5)
	emat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mi(_box(Vector3(1.5, 2.0, 0.12)), Vector3(0, 0.1, 0), exit_area, emat, "ExitGlow")
	_place_label3d(exit_area, "Exit to green", 32, Vector3(0, 1.4, 0))
	exit_area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"):
			_exit_hall(body)
	)
	room.add_child(exit_area)

func _add_wall_col(room: Node3D, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	room.add_child(body)

func _add_quest_desk(room: Node3D, pos: Vector3, guild_col: Color, guild: String, label: String) -> void:
	var root := Node3D.new()
	root.position = pos
	room.add_child(root)
	_mi(_box(Vector3(2.8, 0.85, 1.2)), Vector3(0, 0.55, 0), root, _mats["wood"], "Desk")
	_mi(_box(Vector3(2.9, 0.08, 1.3)), Vector3(0, 1.0, 0), root, _mats["wood_light"], "DeskTop")
	_mi(_box(Vector3(0.45, 0.12, 0.55)), Vector3(-0.7, 1.1, 0.1), root, _mat(guild_col), "Book")
	_mi(_box(Vector3(0.35, 0.08, 0.45)), Vector3(0.6, 1.08, -0.15), root, _mats["iron"], "Inkwell")
	_mi(_box(Vector3(0.4, 0.05, 0.5)), Vector3(0.05, 1.08, 0.25), root, _mat(Color("#f4e4bc")), "Scroll")
	_mi(_cyl(0.05, 0.06, 0.28), Vector3(0.95, 1.22, 0.25), root, _mat(Color("#f4e4bc")), "DeskCandle")
	_mi(_sphere(0.045), Vector3(0.95, 1.4, 0.25), root, _mats["lantern_glow"], "DeskFlame")
	_mi(_cyl(0.16, 0.14, 0.22), Vector3(-1.05, 1.18, -0.25), root, _mats["barrel"], "DeskPot")
	_mi(_sphere(0.18, 0.28), Vector3(-1.05, 1.42, -0.25), root, _mats["leaf"], "DeskPlant")
	# Interactable volume — opens outdoor mentor for this guild
	var area := Area3D.new()
	area.name = "QuestDesk"
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector3(0, 1.0, 1.1)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.0, 1.6)
	col.shape = box
	area.add_child(col)
	var tip := _place_label3d(area, "Quest Desk (F)", 30, Vector3(0, 1.5, 0), 6, Color(1, 1, 1, 0.55))
	if tip:
		tip.name = "DeskTip"
	var glow_mat := _mat(Color(guild_col.r, guild_col.g, guild_col.b, 0.18), 0.5)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var glow_mi := _mi(_box(Vector3(2.0, 0.05, 1.2)), Vector3(0, -0.7, 0), area, glow_mat, "DeskGlow")
	var ring_mat := _mat(Color(guild_col.r, guild_col.g, guild_col.b, 0.0), 0.5)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring := _mi(_cyl(1.15, 1.15, 0.04), Vector3(0, -0.85, 0), area, ring_mat, "DeskHighlight")
	area.set_meta("guild", guild)
	area.set_meta("glow_mi", glow_mi)
	area.set_meta("ring_mi", ring)
	area.set_meta("tip", tip)
	area.set_meta("guild_col", guild_col)
	area.set_meta("player_near", false)
	area.add_to_group("quest_desks")
	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and guild != "":
			body.set_meta("nearby_guild_desk", guild)
			area.set_meta("player_near", true)
			GameState.toast.emit("Quest desk — press F to speak with the hall mentor.")
	)
	area.body_exited.connect(func(body: Node):
		if body.is_in_group("player") and body.has_meta("nearby_guild_desk"):
			if str(body.get_meta("nearby_guild_desk")) == guild:
				body.remove_meta("nearby_guild_desk")
			area.set_meta("player_near", false)
	)
	root.add_child(area)

func _add_study_table(room: Node3D, pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	room.add_child(root)
	_mi(_box(Vector3(1.6, 0.7, 0.9)), Vector3(0, 0.45, 0), root, _mats["wood"], "Table")
	_mi(_cyl(0.06, 0.06, 0.7), Vector3(-0.6, 0.35, -0.3), root, _mats["wood_light"], "Leg1")
	_mi(_cyl(0.06, 0.06, 0.7), Vector3(0.6, 0.35, -0.3), root, _mats["wood_light"], "Leg2")
	_mi(_cyl(0.06, 0.06, 0.7), Vector3(-0.6, 0.35, 0.3), root, _mats["wood_light"], "Leg3")
	_mi(_cyl(0.06, 0.06, 0.7), Vector3(0.6, 0.35, 0.3), root, _mats["wood_light"], "Leg4")
	# Snug collision for indoor nav + walk (Wave 9)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.55, 0.75, 0.85)
	col.shape = shape
	col.position = Vector3(0, 0.4, 0)
	body.add_child(col)
	root.add_child(body)

func _add_chair(room: Node3D, pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	room.add_child(root)
	_mi(_box(Vector3(0.55, 0.12, 0.5)), Vector3(0, 0.45, 0), root, _mats["bench"], "Seat")
	_mi(_box(Vector3(0.55, 0.55, 0.08)), Vector3(0, 0.75, -0.22), root, _mats["bench"], "Back")
	_mi(_box(Vector3(0.08, 0.45, 0.08)), Vector3(-0.2, 0.22, 0.15), root, _mats["wood"], "Leg")
	_mi(_box(Vector3(0.08, 0.45, 0.08)), Vector3(0.2, 0.22, 0.15), root, _mats["wood"], "Leg2")
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 0.85, 0.45)
	col.shape = shape
	col.position = Vector3(0, 0.45, -0.05)
	body.add_child(col)
	root.add_child(body)

func _add_bookshelf(room: Node3D, pos: Vector3, guild_col: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	room.add_child(root)
	_mi(_box(Vector3(1.4, 2.2, 0.4)), Vector3(0, 1.15, 0), root, _mats["wood"], "Shelf")
	for i in 4:
		var y := 0.45 + float(i) * 0.45
		_mi(_box(Vector3(1.2, 0.08, 0.35)), Vector3(0, y, 0), root, _mats["wood_light"], "Plank")
		_mi(_box(Vector3(0.18, 0.32, 0.12)), Vector3(-0.35 + (i % 3) * 0.3, y + 0.2, 0.05), root, _mat(guild_col.lightened(0.1 * (i % 3))), "Book")

func _spawn_indoor_attendant(room: Node3D, b: Dictionary) -> void:
	## Quiet indoor attendant sharing the outdoor mentor's quest list.
	var guild: String = str(b.get("guild", ""))
	var outdoor: Dictionary = {}
	for n in world_data.get("npcs", []):
		if str(n.get("guild", "")) == guild:
			outdoor = n
			break
	if outdoor.is_empty():
		return
	var npc: Node = NpcScene.instantiate()
	npc.npc_id = str(outdoor.get("id", "")) + "-indoor"
	npc.npc_name = str(outdoor.get("name", "Mentor"))
	npc.title = "%s (Hall)" % outdoor.get("title", "Guild")
	npc.guild = guild
	npc.quest_ids = PackedStringArray(outdoor.get("quest_ids", []))
	npc.accent = _hex_color(str(outdoor.get("color", b.get("color", "#888"))))
	npc.position = Vector3(3.1, 0, -4.2)  # clear of quest-desk approach (v1.8/v1.9)
	npc.talk_requested.connect(func(p): npc_talk.emit(p))
	room.add_child(npc)

func _open_guild_npc(guild: String) -> void:
	for n in get_tree().get_nodes_in_group("npcs"):
		if str(n.get("guild")) == guild and not str(n.get("npc_id")).ends_with("-indoor"):
			npc_talk.emit(n)
			return
	# Fallback: indoor attendant
	for n in get_tree().get_nodes_in_group("npcs"):
		if str(n.get("guild")) == guild:
			npc_talk.emit(n)
			return

func _enter_hall(hall_id: String, label: String, body: Node) -> void:
	if _inside_hall != "" or _door_cooldown > 0.0:
		return
	# Push return point clearly outside the door volume (south of front face)
	var door_z: float = body.global_position.z
	_outdoor_return = Vector3(body.global_position.x, 0, door_z + 2.8)
	_inside_hall = hall_id
	if AudioBus.has_method("set_wind_audio"):
		AudioBus.set_wind_audio(false)
	if AudioBus.has_method("set_hall_reverb"):
		AudioBus.set_hall_reverb(true)
	if AudioBus.has_method("set_hall_chatter"):
		AudioBus.set_hall_chatter(true)
	if AudioBus.has_method("set_leaf_rustle"):
		AudioBus.set_leaf_rustle(false)
	if AudioBus.has_method("set_wind_chime"):
		AudioBus.set_wind_chime(false)
	if AudioBus.has_method("set_brook_murmur"):
		AudioBus.set_brook_murmur(false)
	_door_cooldown = 0.8
	# Wave 47: soft hall door open whoosh (respects mute)
	if AudioBus.has_method("play_door_whoosh"):
		AudioBus.play_door_whoosh()
	for room in _interior_root.get_children():
		if str(room.get_meta("hall_id", "")) == hall_id:
			body.global_position = room.global_position + Vector3(0, 0, 2.8)
			if "has_click_target" in body:
				body.has_click_target = false
			GameState.toast.emit("Entered %s Hall — desk for quests, blue glow to leave." % label)
			GameState.position_xz = Vector2(body.global_position.x, body.global_position.z)
			_begin_hall_light_dip()  # Wave 63: soft hall enter light dip
			_apply_weather_visuals(false)
			return

func _exit_hall(body: Node) -> void:
	if _inside_hall == "":
		return
	_inside_hall = ""
	if AudioBus.has_method("set_hall_reverb"):
		AudioBus.set_hall_reverb(false)
	if AudioBus.has_method("set_hall_chatter"):
		AudioBus.set_hall_chatter(false)
	_door_cooldown = 1.2
	body.global_position = _outdoor_return
	if "has_click_target" in body:
		body.has_click_target = false
	GameState.toast.emit("Back on the village green.")
	GameState.position_xz = Vector2(body.global_position.x, body.global_position.z)
	_begin_hall_light_dip()  # Wave 63: soft hall exit light dip
	_apply_weather_visuals(false)

func _build_lantern_glade() -> void:
	## Northern wilds spur — denser path trim, brook foam, lanterns, side props (Mill/Lookout parity).
	var root := Node3D.new()
	root.name = "LanternGlade"
	static_world.add_child(root)
	# Continuous dirt ribbon north from village (overlap for no gaps)
	for i in 14:
		var z := -12.0 - float(i) * 2.8
		_mi(_box(Vector3(3.0, 0.04, 3.2)), Vector3(0.5, 0.025, z), root, _mats["dirt"], "GladePath")
	# Soft edge trim (Lookout/Mill style)
	for i in 8:
		var z := -14.0 - float(i) * 4.5
		_mi(_box(Vector3(3.6, 0.02, 0.32)), Vector3(0.5, 0.03, z), root, _mats["dirt_trim"], "GladeTrim")
	# v1.78 refine: stone curb along the glade path so the wilds corridor looks finished
	for i in 10:
		var z2 := -13.0 - float(i) * 3.6
		_mi(_box(Vector3(0.28, 0.16, 0.85)), Vector3(-1.3, 0.09, z2), root, _mats["stone"], "GladeCurbL")
		_mi(_box(Vector3(0.28, 0.16, 0.85)), Vector3(2.3, 0.09, z2), root, _mats["stone"], "GladeCurbR")
	# Stepping stones across a tiny brook + foam highlights
	_mi(_cyl(2.8, 2.8, 0.08), Vector3(0.5, 0.02, -42), root, _mats["water"], "Brook")
	_water_positions.append(Vector3(0.5, 0, -42))  # Wave 38: brook murmur
	_mi(_cyl(1.6, 1.6, 0.06), Vector3(3.6, 0.02, -44.5), root, _mats["water"], "BrookPool")
	_mi(_cyl(0.5, 0.55, 0.04), Vector3(-0.8, 0.05, -41.5), root, _mat(Color("#a8d4ea"), 0.15), "GladeFoam1")
	_mi(_cyl(0.35, 0.4, 0.03), Vector3(1.6, 0.05, -42.4), root, _mat(Color("#b8dff0"), 0.15), "GladeFoam2")
	_mi(_cyl(0.3, 0.35, 0.03), Vector3(0.2, 0.05, -43.1), root, _mat(Color("#a8d4ea"), 0.12), "GladeFoam3")
	for i in 6:
		_mi(_sphere(0.32, 0.2), Vector3(-0.4 + float(i) * 0.55, 0.12, -42.0), root, _mats["rock"], "Step")
	# Signpost off the walk line
	var sign := Node3D.new()
	sign.position = Vector3(3.4, 0, -30)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 2.0), Vector3(0, 1.0, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.4, 0.7, 0.1)), Vector3(0, 1.8, 0), sign, _mats["wood_light"], "Board")
	_place_label3d(sign, "Lantern Glade", 42, Vector3(0, 2.5, 0))
	# Framing props kept outside corridor (side >= 4.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 14:
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(0.5 + side * rng.randf_range(5.0, 10.0), 0, -18.0 - float(i) * 2.4)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 1 if i > 6 else 0)
	# Lanterns along the spur + ring at glade end
	_add_lantern_post(Vector3(-3.2, 0, -22))
	_add_lantern_post(Vector3(4.2, 0, -28))
	_add_lantern_post(Vector3(-3.5, 0, -36))
	_add_lantern_post(Vector3(4.0, 0, -40))
	for i in 6:
		var ang := i * TAU / 6.0
		_add_lantern_post(Vector3(0.5 + cos(ang) * 5.2, 0, -48.0 + sin(ang) * 5.2))
	# Glade yard props (benches, crate, barrel, flower ring)
	_add_bench(Vector3(-3.8, 0, -46.5), 0.4)
	_add_bench(Vector3(4.5, 0, -49.0), -0.5)
	_add_crate(Vector3(5.2, 0, -45.5))
	_add_barrel(Vector3(-4.6, 0, -50.0), 0.3)
	for i in 8:
		var ang := i * TAU / 8.0
		_add_flowers(Vector3(0.5 + cos(ang) * 6.0, 0, -48.0 + sin(ang) * 6.0), rng)
	_place_label3d(root, "Soft light among the trees", 28, Vector3(0.5, 3.85, -48), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Lantern Glade", 56, Vector3(0.5, 3.2, -48))

func _setup_weather() -> void:
	_rain = CPUParticles3D.new()
	_rain.name = "Rain"
	_rain.emitting = false
	_rain.amount = 280
	_rain.lifetime = 1.1
	_rain.preprocess = 0.4
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(28, 0.2, 28)
	_rain.direction = Vector3(0.08, -1, 0.02)
	_rain.spread = 4.0
	_rain.initial_velocity_min = 8.0
	_rain.initial_velocity_max = 12.0
	_rain.gravity = Vector3(0, -2, 0)
	var rm := BoxMesh.new()
	rm.size = Vector3(0.03, 0.22, 0.03)
	_rain.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.65, 0.75, 0.9, 0.45)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rain.material_override = rmat
	_rain.position = Vector3(0, 14, 6)
	add_child(_rain)
	HeadlessGuard.guard_particles(_rain)

	# Wave 26: soft cloud puffs — density scales with weather (clear sparse, fog dense, rain medium)
	_clouds = CPUParticles3D.new()
	_clouds.name = "WeatherClouds"
	_clouds.emitting = true
	_clouds.amount = 12
	_clouds.lifetime = 14.0
	_clouds.preprocess = 6.0
	_clouds.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_clouds.emission_box_extents = Vector3(40, 2, 40)
	_clouds.direction = Vector3(1, 0.02, 0.15)
	_clouds.spread = 12.0
	_clouds.initial_velocity_min = 0.35
	_clouds.initial_velocity_max = 0.85
	_clouds.gravity = Vector3(0, 0, 0)
	var cm := SphereMesh.new()
	cm.radius = 1.6
	cm.height = 2.2
	_clouds.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.92, 0.94, 0.98, 0.35)
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_clouds.material_override = cmat
	_clouds.position = Vector3(0, 22, 0)
	add_child(_clouds)
	HeadlessGuard.guard_particles(_clouds)
	_apply_weather_visuals()
	_setup_rain_splash()
	_setup_rain_puddle_ripples()
	_setup_fog_mist()
	_setup_edge_fog_banks()
	_setup_wind_leaves()
	_setup_maple_leaves()
	_setup_dusk_fireflies()
	_setup_garden_fireflies()
	_setup_birch_fireflies()
	_setup_reed_pool_gleam()
	_setup_willow_leaves()
	_setup_fern_fronds()
	_setup_heather_blooms()
	_setup_thistle_blooms()
	_setup_maple_dusk_leaves()
	_setup_amber_knoll_motes()
	_setup_cedar_needles()
	_setup_stone_arch_dust()
	_setup_cross_lantern_moths()
	_setup_brook_sparkle()
	_setup_snowdust()
	_setup_canopy_drip()
	_setup_eaves_splash()

func _setup_rain_splash() -> void:
	## Wave 28: soft ground-splash puffs while raining (RuneScape-chunky, wholesome).
	_rain_splash = CPUParticles3D.new()
	_rain_splash.name = "RainSplash"
	_rain_splash.emitting = false
	_rain_splash.amount = 36
	_rain_splash.lifetime = 0.45
	_rain_splash.preprocess = 0.2
	_rain_splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain_splash.emission_box_extents = Vector3(10, 0.05, 10)
	_rain_splash.direction = Vector3(0, 1, 0)
	_rain_splash.spread = 40.0
	_rain_splash.initial_velocity_min = 0.4
	_rain_splash.initial_velocity_max = 1.2
	_rain_splash.gravity = Vector3(0, -3.0, 0)
	_rain_splash.scale_amount_min = 0.08
	_rain_splash.scale_amount_max = 0.18
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.08
	_rain_splash.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.75, 0.82, 0.92, 0.55)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rain_splash.material_override = smat
	_rain_splash.position = Vector3(0, 0.05, 0)
	add_child(_rain_splash)
	HeadlessGuard.guard_particles(_rain_splash)

func _setup_rain_puddle_ripples() -> void:
	## Wave 41: soft expanding puddle ripples while raining (RuneScape-chunky, wholesome).
	## Wave 73: soft puddle ripple polish — denser rings, gentler fade (RuneScape-chunky, wholesome).
	_puddle_ripples = CPUParticles3D.new()
	_puddle_ripples.name = "RainPuddleRipples"
	_puddle_ripples.emitting = false
	_puddle_ripples.amount = 22
	_puddle_ripples.lifetime = 1.55
	_puddle_ripples.preprocess = 0.4
	_puddle_ripples.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_puddle_ripples.emission_box_extents = Vector3(7.5, 0.02, 7.5)
	_puddle_ripples.direction = Vector3(0, 1, 0)
	_puddle_ripples.spread = 5.0
	_puddle_ripples.initial_velocity_min = 0.0
	_puddle_ripples.initial_velocity_max = 0.02
	_puddle_ripples.gravity = Vector3(0, 0, 0)
	_puddle_ripples.scale_amount_min = 0.35
	_puddle_ripples.scale_amount_max = 1.65
	var ring := TorusMesh.new()
	ring.inner_radius = 0.12
	ring.outer_radius = 0.18
	ring.rings = 8
	ring.ring_segments = 16
	_puddle_ripples.mesh = ring
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.72, 0.82, 0.92, 0.42)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_puddle_ripples.material_override = rmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.75, 0.85, 0.95, 0.0),
		Color(0.78, 0.88, 0.96, 0.5),
		Color(0.7, 0.8, 0.9, 0.0),
	])
	_puddle_ripples.color_ramp = ramp
	_puddle_ripples.position = Vector3(0, 0.04, 0)
	add_child(_puddle_ripples)
	HeadlessGuard.guard_particles(_puddle_ripples)


func _setup_fog_mist() -> void:
	## Wave 29: denser low ground-mist cue while foggy (player-visible fog density).
	_fog_mist = CPUParticles3D.new()
	_fog_mist.name = "FogMist"
	_fog_mist.emitting = false
	_fog_mist.amount = 40
	_fog_mist.lifetime = 4.5
	_fog_mist.preprocess = 2.0
	_fog_mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_fog_mist.emission_box_extents = Vector3(14, 0.4, 14)
	_fog_mist.direction = Vector3(0.15, 0.05, 0.1)
	_fog_mist.spread = 35.0
	_fog_mist.initial_velocity_min = 0.15
	_fog_mist.initial_velocity_max = 0.45
	_fog_mist.gravity = Vector3(0, 0.02, 0)
	_fog_mist.scale_amount_min = 0.8
	_fog_mist.scale_amount_max = 1.8
	var fm := SphereMesh.new()
	fm.radius = 0.55
	fm.height = 0.7
	_fog_mist.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.88, 0.9, 0.94, 0.28)
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fog_mist.material_override = fmat
	_fog_mist.position = Vector3(0, 0.6, 0)
	add_child(_fog_mist)
	HeadlessGuard.guard_particles(_fog_mist)

func _setup_edge_fog_banks() -> void:
	## Wave 46: soft fog banks along outdoor map edges (RuneScape-chunky, wholesome; off indoors).
	## Wave 72: soft edge-fog banks polish — taller cream mist, gentler drift (RuneScape-chunky, wholesome).
	_edge_fog_banks.clear()
	var root := Node3D.new()
	root.name = "EdgeFogBanks"
	add_child(root)
	var spots: Array = [
		Vector3(0, 0.9, -78), Vector3(0, 0.9, 78),
		Vector3(-78, 0.9, 0), Vector3(78, 0.9, 0),
		Vector3(-62, 0.9, -62), Vector3(62, 0.9, -62),
		Vector3(-62, 0.9, 62), Vector3(62, 0.9, 62),
	]
	for i in spots.size():
		var fx := CPUParticles3D.new()
		fx.name = "EdgeFog%d" % i
		fx.emitting = true
		fx.amount = 22
		fx.lifetime = 6.2
		fx.preprocess = 2.8
		fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		fx.emission_box_extents = Vector3(11, 0.95, 11)
		fx.direction = Vector3(0.08, 0.05, 0.04)
		fx.spread = 32.0
		fx.initial_velocity_min = 0.06
		fx.initial_velocity_max = 0.26
		fx.gravity = Vector3(0, 0.012, 0)
		fx.scale_amount_min = 1.35
		fx.scale_amount_max = 2.7
		var sm := SphereMesh.new()
		sm.radius = 0.62
		sm.height = 1.05
		fx.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.88, 0.92, 0.96, 0.26)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fx.material_override = mat
		fx.position = spots[i]
		root.add_child(fx)
		HeadlessGuard.guard_particles(fx)
		_edge_fog_banks.append(fx)

func _update_weather(delta: float) -> void:
	# Follow player outdoors so rain reads nearby; mute-friendly (no weather audio)
	if player and _rain:
		if _inside_hall == "":
			_rain.global_position = Vector3(player.global_position.x, 14, player.global_position.z)
			_rain.visible = true
			if _rain_splash:
				_rain_splash.global_position = Vector3(player.global_position.x, 0.05, player.global_position.z)
				_rain_splash.visible = true
			if _puddle_ripples:
				_puddle_ripples.global_position = Vector3(player.global_position.x, 0.04, player.global_position.z)
				_puddle_ripples.visible = true
		else:
			_rain.emitting = false
			_rain.visible = false
			if _rain_splash:
				_rain_splash.emitting = false
				_rain_splash.visible = false
			if _puddle_ripples:
				_puddle_ripples.emitting = false
				_puddle_ripples.visible = false
	if player and _clouds:
		if _inside_hall == "":
			_clouds.global_position = Vector3(player.global_position.x, 22, player.global_position.z)
			_clouds.visible = true
		else:
			_clouds.visible = false
	if player and _fog_mist:
		if _inside_hall == "" and _weather_mode == 1:
			_fog_mist.global_position = Vector3(player.global_position.x, 0.6, player.global_position.z)
			_fog_mist.visible = true
		else:
			_fog_mist.visible = false
	# Wave 46: soft edge fog banks outdoors (always gentle; denser in Fog via _apply_weather_visuals)
	for fx in _edge_fog_banks:
		if fx == null or not is_instance_valid(fx):
			continue
		var out := (_inside_hall == "")
		fx.visible = out
		fx.emitting = out
	if player and _wind_leaves:
		if _inside_hall == "":
			_wind_leaves.global_position = Vector3(player.global_position.x, 2.4, player.global_position.z)
			_wind_leaves.emitting = true
			_wind_leaves.visible = true
		else:
			_wind_leaves.emitting = false
			_wind_leaves.visible = false
	# Wave 56: denser soft leaf fall at Maple Copse (RuneScape-chunky, wholesome)
	if _maple_leaves:
		var maple_out := (_inside_hall == "")
		_maple_leaves.emitting = maple_out
		_maple_leaves.visible = maple_out
		# Wave 72: denser Maple Copse leaf fall reads stronger at dusk (RuneScape-chunky, wholesome)
		if maple_out and _is_dusk_firefly_time():
			_maple_leaves.amount = 72
		else:
			_maple_leaves.amount = 56
	if player and _dusk_fireflies:
		# Wave 39: soft firefly sparkles at dusk/night outdoors only
		var dusk_on := _inside_hall == "" and _is_dusk_firefly_time()
		if dusk_on:
			_dusk_fireflies.global_position = Vector3(player.global_position.x, 1.6, player.global_position.z)
			_dusk_fireflies.emitting = true
			_dusk_fireflies.visible = true
		else:
			_dusk_fireflies.emitting = false
			_dusk_fireflies.visible = false
	# Wave 53: denser soft fireflies gather near Prayer Garden at dusk (RuneScape-chunky, wholesome)
	if _garden_fireflies:
		var garden_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_garden_fireflies.emitting = garden_dusk
		_garden_fireflies.visible = garden_dusk
	# Wave 66: soft birch-rest firefly wink at dusk (RuneScape-chunky, wholesome)
	if _birch_fireflies:
		var birch_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_birch_fireflies.emitting = birch_dusk
		_birch_fireflies.visible = birch_dusk
	# Wave 67: soft Reed Pool ripple gleam at dusk (RuneScape-chunky, wholesome)
	if _reed_pool_gleam:
		var reed_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_reed_pool_gleam.emitting = reed_dusk
		_reed_pool_gleam.visible = reed_dusk
	# Wave 68: soft Willow Bend willow-leaf drift at dusk (RuneScape-chunky, wholesome)
	if _willow_leaves:
		var willow_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_willow_leaves.emitting = willow_dusk
		_willow_leaves.visible = willow_dusk
	if _fern_fronds:
		var fern_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_fern_fronds.emitting = fern_dusk
		_fern_fronds.visible = fern_dusk
	if _heather_blooms:
		var heather_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_heather_blooms.emitting = heather_dusk
		_heather_blooms.visible = heather_dusk
	if _thistle_blooms:
		var thistle_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_thistle_blooms.emitting = thistle_dusk
		_thistle_blooms.visible = thistle_dusk
	if _maple_dusk_leaves:
		var maple_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_maple_dusk_leaves.emitting = maple_dusk
		_maple_dusk_leaves.visible = maple_dusk
	if _amber_knoll_motes:
		var amber_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_amber_knoll_motes.emitting = amber_dusk
		_amber_knoll_motes.visible = amber_dusk
	if _cedar_needles:
		var cedar_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_cedar_needles.emitting = cedar_dusk
		_cedar_needles.visible = cedar_dusk
	if _stone_arch_dust:
		var arch_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_stone_arch_dust.emitting = arch_dusk
		_stone_arch_dust.visible = arch_dusk
	if _cross_lantern_moths:
		var cross_dusk := _inside_hall == "" and _is_dusk_firefly_time()
		_cross_lantern_moths.emitting = cross_dusk
		_cross_lantern_moths.visible = cross_dusk
	# Wave 47: soft snowdust in cold Fog outdoors (off indoors / clear / rain)
	if player and _snowdust:
		if _inside_hall == "" and _weather_mode == 1:
			_snowdust.global_position = Vector3(player.global_position.x, 2.8, player.global_position.z)
			_snowdust.emitting = true
			_snowdust.visible = true
		else:
			_snowdust.emitting = false
			_snowdust.visible = false
	# Wave 48: soft rain canopy drip under nearest tree outdoors (off indoors / clear / fog)
	_update_canopy_drip()
	_update_eaves_splash()
	if _weather_auto:
		_weather_timer -= delta
		if _weather_timer <= 0.0:
			cycle_weather(true)
			_weather_timer = [100.0, 70.0, 55.0][_weather_mode]

func cycle_weather(announce: bool = true) -> void:
	_weather_mode = (_weather_mode + 1) % 3
	_apply_weather_visuals(announce)

func set_weather(mode: int, announce: bool = false) -> void:
	_weather_mode = clampi(mode, 0, 2)
	_weather_auto = true
	_weather_timer = [100.0, 70.0, 55.0][_weather_mode]
	_apply_weather_visuals(announce)

func toggle_weather_auto() -> void:
	## Manual bump through clear → fog → rain; keeps auto-cycle on.
	cycle_weather(true)
	_weather_timer = [100.0, 70.0, 55.0][_weather_mode]

func get_weather_label() -> String:
	return _weather_label_cache

func _apply_weather_visuals(announce: bool = false) -> void:
	var rain_on := false
	var drip_on := false
	match _weather_mode:
		1:
			_weather_label_cache = "Fog"
			_fog_boost = 0.0045
			if _rain:
				_rain.emitting = false
				if _rain_splash:
					_rain_splash.emitting = false
				if _puddle_ripples:
					_puddle_ripples.emitting = false
			if _fog_mist:
				_fog_mist.emitting = (_inside_hall == "")
				_fog_mist.amount = 48
		2:
			_weather_label_cache = "Rain"
			_fog_boost = 0.0025
			if _fog_mist:
				_fog_mist.emitting = false
			if _rain and _inside_hall == "":
				_rain.emitting = true
				if _rain_splash:
					_rain_splash.emitting = true
				if _puddle_ripples:
					_puddle_ripples.emitting = true
				rain_on = true
			elif _rain:
				_rain.emitting = false
				if _rain_splash:
					_rain_splash.emitting = false
				if _puddle_ripples:
					_puddle_ripples.emitting = false
				drip_on = true  # raining outdoors while player is indoors
		_:
			_weather_label_cache = "Clear"
			_fog_boost = 0.0
			if _fog_mist:
				_fog_mist.emitting = false
			if _rain:
				_rain.emitting = false
				if _rain_splash:
					_rain_splash.emitting = false
				if _puddle_ripples:
					_puddle_ripples.emitting = false
	# Wave 26: weather cloud density (clear sparse · fog dense · rain medium)
	if _clouds:
		match _weather_mode:
			1:
				_clouds.amount = 28
				_clouds.emitting = true
			2:
				_clouds.amount = 18
				_clouds.emitting = true
			_:
				_clouds.amount = 10
				_clouds.emitting = true
		if _inside_hall != "":
			_clouds.emitting = false
	if AudioBus.has_method("set_indoor_drip"):
		AudioBus.set_indoor_drip(drip_on)
	if AudioBus.has_method("set_rain_audio"):
		AudioBus.set_rain_audio(rain_on)
	# Wave 46: edge fog denser in Fog weather
	for fx in _edge_fog_banks:
		if fx == null or not is_instance_valid(fx):
			continue
		fx.amount = 34 if _weather_mode == 1 else 20
	weather_changed.emit(_weather_mode, _weather_label_cache)
	if announce:
		# Wave 44: clearer weather cycle toast (Clear / Fog / Rain each named with a soft cue)
		match _weather_mode:
			1:
				GameState.toast.emit("Weather cycle · Fog — soft mist gathers thick nearby.")
			2:
				GameState.toast.emit("Weather cycle · Rain — gentle drops patter on the green.")
			_:
				GameState.toast.emit("Weather cycle · Clear — bright open skies settle soft over the village.")


func _update_quest_desk_highlights() -> void:
	## Soft pulse when the player stands at a quest desk.
	for area in get_tree().get_nodes_in_group("quest_desks"):
		var near: bool = bool(area.get_meta("player_near", false))
		var tip = area.get_meta("tip") if area.has_meta("tip") else null
		var glow_mi: MeshInstance3D = area.get_meta("glow_mi") if area.has_meta("glow_mi") else null
		var ring_mi: MeshInstance3D = area.get_meta("ring_mi") if area.has_meta("ring_mi") else null
		var gc: Color = area.get_meta("guild_col") if area.has_meta("guild_col") else Color(1, 0.9, 0.5)
		var pulse: float = 0.35 + 0.35 * abs(sin(Time.get_ticks_msec() * 0.004))
		if tip != null and is_instance_valid(tip) and tip is Label3D:
			tip.modulate = Color(1, 1, 0.85, 0.95 if near else 0.5)
			tip.font_size = 36 if near else 30
		if glow_mi and glow_mi.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = glow_mi.material_override
			m.albedo_color = Color(gc.r, gc.g, gc.b, (0.45 * pulse) if near else 0.14)
		if ring_mi:
			ring_mi.visible = near
			if near and ring_mi.material_override is StandardMaterial3D:
				var rm: StandardMaterial3D = ring_mi.material_override
				rm.albedo_color = Color(gc.r, gc.g, gc.b, 0.25 + 0.35 * pulse)
				var s: float = 0.95 + 0.12 * pulse
				ring_mi.scale = Vector3(s, 1.0, s)

func _add_guild_theme_props(room: Node3D, guild: String, col: Color) -> void:
	## Light per-guild prop flavor — keeps halls distinct without heavy budgets.
	match guild:
		"math":
			# Counting blocks + abacus bar
			for i in 5:
				var c := Color("#d4a017").lightened(0.05 * i)
				_mi(_box(Vector3(0.28, 0.28, 0.28)), Vector3(-4.2 + float(i) * 0.35, 0.35, 1.8), room, _mat(c), "Block")
			_mi(_box(Vector3(1.4, 0.08, 0.12)), Vector3(4.0, 1.2, -2.0), room, _mats["wood"], "AbacusBar")
			for i in 6:
				_mi(_sphere(0.08), Vector3(3.5 + float(i) * 0.18, 1.35, -2.0), room, _mat(Color("#c9a227")), "Bead")
		"la":
			# Scroll racks + ink pots
			for i in 4:
				_mi(_cyl(0.08, 0.08, 0.7), Vector3(-4.0 + float(i) * 0.35, 0.9, 1.5), room, _mats["wood_light"], "Scroll")
				_mi(_cyl(0.1, 0.1, 0.06), Vector3(-4.0 + float(i) * 0.35, 1.25, 1.5), room, _mat(col), "ScrollCap")
			_mi(_cyl(0.12, 0.14, 0.2), Vector3(4.2, 1.15, -2.2), room, _mats["iron"], "Ink")
			_mi(_box(Vector3(0.5, 0.04, 0.7)), Vector3(3.6, 1.08, -2.0), room, _mat(Color("#f4e4bc")), "Parchment")
		"science":
			# Potted plants + observation tray
			_mi(_cyl(0.22, 0.18, 0.35), Vector3(-4.3, 0.35, 1.6), room, _mats["barrel"], "Pot")
			_mi(_sphere(0.35, 0.55), Vector3(-4.3, 0.85, 1.6), room, _mats["leaf"], "Plant")
			_mi(_cyl(0.2, 0.16, 0.3), Vector3(4.2, 0.3, 1.4), room, _mats["stone"], "Pot2")
			_mi(_sphere(0.28, 0.45), Vector3(4.2, 0.75, 1.4), room, _mats["leaf_alt"], "Plant2")
			_mi(_box(Vector3(1.1, 0.08, 0.7)), Vector3(3.5, 1.08, -2.1), room, _mats["stone_dark"], "Tray")
			_mi(_sphere(0.12), Vector3(3.3, 1.2, -2.1), room, _mats["rock"], "Sample")
			_mi(_sphere(0.1, 0.14), Vector3(3.7, 1.18, -2.0), room, _mat(Color("#6aaa6a")), "LeafSample")
		"history":
			# Map table + timeline posts
			_mi(_box(Vector3(1.8, 0.7, 1.1)), Vector3(-3.8, 0.45, 1.5), room, _mats["wood"], "MapTable")
			_mi(_box(Vector3(1.5, 0.04, 0.9)), Vector3(-3.8, 0.85, 1.5), room, _mat(Color("#c2b280")), "Map")
			_add_wall_col(room, Vector3(1.7, 0.75, 1.0), Vector3(-3.8, 0.4, 1.5))
			for i in 4:
				_mi(_cyl(0.06, 0.06, 1.1), Vector3(3.6 + float(i) * 0.35, 0.7, 1.8), room, _mats["wood"], "Post")
				_mi(_box(Vector3(0.2, 0.15, 0.05)), Vector3(3.6 + float(i) * 0.35, 1.2, 1.8), room, _mat(col.lightened(0.1 * i)), "Flag")
		"bible":
			# Simple lectern + quiet candles
			_mi(_box(Vector3(0.7, 1.1, 0.5)), Vector3(-3.8, 0.7, 1.4), room, _mats["wood"], "Lectern")
			_mi(_box(Vector3(0.55, 0.08, 0.45)), Vector3(-3.8, 1.3, 1.55), room, _mats["wood_light"], "LecternTop")
			_add_wall_col(room, Vector3(0.65, 1.15, 0.5), Vector3(-3.8, 0.65, 1.4))
			_mi(_box(Vector3(0.35, 0.1, 0.28)), Vector3(-3.8, 1.4, 1.55), room, _mat(Color("#f4e4bc")), "OpenWord")
			for i in 3:
				var cx := 3.5 + float(i) * 0.4
				_mi(_cyl(0.06, 0.07, 0.35), Vector3(cx, 1.2, -2.0), room, _mat(Color("#f4e4bc")), "Candle")
				_mi(_sphere(0.05), Vector3(cx, 1.42, -2.0), room, _mats["lantern_glow"], "Flame")
		_:
			pass

func _build_pine_ridge() -> void:
	## Western spur beyond Lantern Glade — denser ford path, foam, lanterns, camp props.
	var root := Node3D.new()
	root.name = "PineRidge"
	static_world.add_child(root)
	# Continuous path west from glade brook toward ridge
	for i in 12:
		var x := -1.0 - float(i) * 2.4
		_mi(_box(Vector3(3.0, 0.04, 2.8)), Vector3(x, 0.025, -48.0), root, _mats["dirt"], "RidgePath")
	for i in 6:
		var x := -3.0 - float(i) * 4.0
		_mi(_box(Vector3(0.32, 0.02, 3.4)), Vector3(x, 0.03, -48.0), root, _mats["dirt_trim"], "RidgeTrim")
	# Creek ford (shallow crossing) with foam + stepping stones
	_mi(_cyl(3.2, 3.2, 0.07), Vector3(-18, 0.015, -48), root, _mats["water"], "Creek")
	_water_positions.append(Vector3(-18, 0, -48))  # Wave 38: brook murmur
	_mi(_cyl(1.4, 1.4, 0.05), Vector3(-20.5, 0.015, -50.5), root, _mats["water"], "CreekBend")
	_mi(_cyl(0.45, 0.5, 0.04), Vector3(-17.2, 0.04, -47.4), root, _mat(Color("#a8d4ea"), 0.15), "RidgeFoam1")
	_mi(_cyl(0.35, 0.4, 0.03), Vector3(-19.0, 0.04, -48.8), root, _mat(Color("#b8dff0"), 0.15), "RidgeFoam2")
	_mi(_cyl(0.28, 0.32, 0.03), Vector3(-18.4, 0.04, -49.6), root, _mat(Color("#a8d4ea"), 0.12), "RidgeFoam3")
	for i in 5:
		_mi(_sphere(0.3, 0.18), Vector3(-16.2 - float(i) * 0.75, 0.12, -48.0), root, _mats["rock"], "FordStone")
	var sign := Node3D.new()
	sign.position = Vector3(-12, 0, -45.2)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.9), Vector3(0, 0.95, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.5, 0.65, 0.1)), Vector3(0, 1.7, 0), sign, _mats["wood_light"], "Board")
	_place_label3d(sign, "Pine Ridge", 40, Vector3(0, 2.4, 0))
	# Pines kept off the ford corridor
	var rng := RandomNumberGenerator.new()
	rng.seed = 113
	for i in 16:
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(4.0, 10.5)
		var p := Vector3(-24.0 + cos(ang) * rad, 0, -54.0 + sin(ang) * rad * 0.75)
		if _in_travel_corridor(p):
			continue
		_add_pine(p, rng)
	for i in 5:
		_add_rock_cluster(Vector3(-26.0 + float(i) * 2.0, 0, -58.0 - (i % 2)), rng)
	# Spur lanterns + ridge camp props
	_add_lantern_post(Vector3(-6.0, 0, -45.5))
	_add_lantern_post(Vector3(-14.0, 0, -45.2))
	_add_lantern_post(Vector3(-22.0, 0, -50.5))
	_add_lantern_post(Vector3(-27.5, 0, -52.0))
	_add_lantern_post(Vector3(-20.5, 0, -57.0))
	# Simple stump seat + fire ring (decorative ash) + crate
	_mi(_cyl(0.45, 0.5, 0.55), Vector3(-25.5, 0.28, -51.5), root, _mats["wood"], "StumpSeat")
	_mi(_cyl(0.7, 0.75, 0.12), Vector3(-27.2, 0.08, -55.2), root, _mats["rock"], "RidgeFireRing")
	_mi(_box(Vector3(0.35, 0.12, 0.12)), Vector3(-27.2, 0.18, -55.2), root, _mats["wood"], "RidgeAshLog")
	_add_crate(Vector3(-28.5, 0, -52.5))
	_add_barrel(Vector3(-29.0, 0, -54.0), -0.4)
	_add_bench(Vector3(-22.5, 0, -56.5), 0.6)
	for i in 7:
		var ang := i * TAU / 7.0
		_add_flowers(Vector3(-24.0 + cos(ang) * 5.5, 0, -54.0 + sin(ang) * 5.5), rng)
	_place_label3d(root, "Cool air under the pines", 28, Vector3(-24, 4.0, -54), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Pine Ridge", 52, Vector3(-24, 3.4, -54))

func _add_pine(pos: Vector3, rng: RandomNumberGenerator) -> void:
	if _in_travel_corridor(pos):
		return
	var body := StaticBody3D.new()
	body.position = pos
	var trunk_h := rng.randf_range(1.6, 2.2)
	_mi(_cyl(0.14, 0.22, trunk_h), Vector3(0, trunk_h * 0.5, 0), body, _mats["wood"], "Trunk")
	var pine := _mat(Color("#2a6a40"))
	for j in 3:
		var y := trunk_h * 0.45 + float(j) * 0.55
		var r := 0.95 - float(j) * 0.22
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = r
		cone.height = 0.85
		_mi(cone, Vector3(0, y, 0), body, pine, "Pine%d" % j)
	_mi(_cyl(0.85, 0.85, 0.02), Vector3(0, 0.012, 0), body, _mats["grass_dark"], "Shade")
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.28
	shape.height = 2.2
	col.shape = shape
	col.position.y = 1.1
	body.add_child(col)
	static_world.add_child(body)


func _build_prayer_garden() -> void:
	## Quiet eastern landmark — denser path trim, lanterns, rail, candles (Mill/Lookout parity).
	var root := Node3D.new()
	root.name = "PrayerGarden"
	static_world.add_child(root)
	# Path east from plaza
	for i in 10:
		var x := 12.0 + float(i) * 2.0
		_mi(_box(Vector3(2.6, 0.04, 2.6)), Vector3(x, 0.025, 18.0), root, _mats["dirt"], "GardenPath")
	for i in 5:
		var x := 14.0 + float(i) * 3.5
		_mi(_box(Vector3(0.32, 0.02, 3.2)), Vector3(x, 0.03, 18.0), root, _mats["dirt_trim"], "GardenTrim")
	# Garden circle + stone cross marker
	_mi(_cyl(5.5, 5.5, 0.04), Vector3(30, 0.02, 18), root, _mats["grass_light"], "Lawn")
	_mi(_cyl(1.2, 1.3, 0.35), Vector3(30, 0.2, 18), root, _mats["stone"], "MarkerBase")
	_mi(_box(Vector3(0.28, 1.8, 0.18)), Vector3(30, 1.2, 18), root, _mats["stone_dark"], "Marker")
	_mi(_box(Vector3(0.9, 0.22, 0.16)), Vector3(30, 1.55, 18), root, _mats["stone"], "MarkerArm")
	# Low rail around marker (quiet fence stub)
	for i in 6:
		var ang := float(i) * TAU / 6.0
		var px := 30.0 + cos(ang) * 2.2
		var pz := 18.0 + sin(ang) * 2.2
		_mi(_box(Vector3(0.08, 0.7, 0.08)), Vector3(px, 0.35, pz), root, _mats["fence"], "GardenRailPost")
	_mi(_cyl(2.15, 2.15, 0.06), Vector3(30, 0.72, 18), root, _mats["fence"], "GardenRailRing")
	# Quiet benches
	_add_bench(Vector3(27.5, 0, 20.5), 0.8)
	_add_bench(Vector3(32.5, 0, 20.5), -0.8)
	_add_bench(Vector3(30, 0, 14.8), 0.0)
	_add_bench(Vector3(26.8, 0, 16.2), 0.3)
	# Flower ring (denser)
	var rng := RandomNumberGenerator.new()
	rng.seed = 131
	for i in 12:
		var ang := i * TAU / 12.0
		_add_flowers(Vector3(30.0 + cos(ang) * 3.8, 0, 18.0 + sin(ang) * 3.8), rng)
	for i in 8:
		var ang := i * TAU / 8.0 + 0.2
		_add_flowers(Vector3(30.0 + cos(ang) * 5.0, 0, 18.0 + sin(ang) * 5.0), rng)
	# Lanterns along spur + garden corners
	_add_lantern_post(Vector3(16.0, 0, 15.5))
	_add_lantern_post(Vector3(22.0, 0, 20.5))
	_add_lantern_post(Vector3(26.5, 0, 15.5))
	_add_lantern_post(Vector3(33.5, 0, 15.5))
	_add_lantern_post(Vector3(26.5, 0, 20.5))
	_add_lantern_post(Vector3(33.5, 0, 20.5))
	# Quiet candles near marker
	for i in 4:
		var ang := float(i) * TAU / 4.0 + 0.4
		var cx := 30.0 + cos(ang) * 1.55
		var cz := 18.0 + sin(ang) * 1.55
		_mi(_cyl(0.06, 0.07, 0.35), Vector3(cx, 0.55, cz), root, _mat(Color("#f4e4bc")), "GardenCandle")
		_mi(_sphere(0.05), Vector3(cx, 0.78, cz), root, _mats["lantern_glow"], "GardenFlame")
	var sign := Node3D.new()
	sign.position = Vector3(26.2, 0, 18.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.5, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	_place_label3d(sign, "Prayer Garden", 40, Vector3(0, 2.3, 0))
	_place_label3d(root, "A quiet place to give thanks", 28, Vector3(30, 3.85, 18), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Prayer Garden", 52, Vector3(30, 3.2, 18))


func _build_lookout_rock() -> void:
	## Southeast landmark — soft travel (L). Rocky overlook with denser path + spur props.
	var root := Node3D.new()
	root.name = "LookoutRock"
	static_world.add_child(root)
	# Path southeast from plaza toward lookout (tighter ribbon + edge trim)
	for i in 14:
		var tt := float(i) / 13.0
		var x := 10.0 + tt * 28.0
		var z := 14.0 + tt * 20.0
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "LookoutPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := 12.0 + tt * 24.0
		var z := 15.5 + tt * 17.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "LookoutTrim")
	# Rocky outcrop + stepped stones
	_mi(_cyl(4.2, 4.5, 0.35), Vector3(40, 0.18, 34), root, _mats["stone"], "LookoutBase")
	_mi(_box(Vector3(3.2, 1.6, 2.4)), Vector3(40, 1.0, 34), root, _mats["stone_dark"], "LookoutMass")
	_mi(_box(Vector3(1.4, 0.9, 1.2)), Vector3(41.2, 1.85, 33.2), root, _mats["stone"], "LookoutCap")
	_mi(_box(Vector3(1.6, 0.28, 0.9)), Vector3(38.2, 0.35, 35.4), root, _mats["stone"], "Step1")
	_mi(_box(Vector3(1.4, 0.28, 0.85)), Vector3(38.8, 0.65, 34.8), root, _mats["stone_dark"], "Step2")
	_mi(_box(Vector3(1.2, 0.28, 0.8)), Vector3(39.3, 0.95, 34.3), root, _mats["stone"], "Step3")
	# Viewing post + rail + simple spyglass
	_mi(_cyl(0.35, 0.4, 1.4), Vector3(39.0, 1.9, 35.0), root, _mats["wood"], "LookoutPost")
	_mi(_box(Vector3(1.1, 0.08, 0.7)), Vector3(39.0, 2.65, 35.0), root, _mats["wood_light"], "LookoutRail")
	_mi(_cyl(0.07, 0.09, 0.85), Vector3(39.55, 2.55, 34.55), root, _mats["iron"], "Scope")
	_mi(_cyl(0.11, 0.12, 0.12), Vector3(39.55, 2.55, 34.1), root, _mats["iron"], "ScopeLens")
	# Small steward flag
	_mi(_cyl(0.05, 0.06, 2.2), Vector3(41.6, 2.4, 35.2), root, _mats["wood"], "FlagPole")
	_mi(_box(Vector3(0.7, 0.4, 0.04)), Vector3(41.95, 3.2, 35.2), root, _mat(Color("#c1121f")), "Flag")
	# Campfire ring (decorative, unlit ash) + crate stash
	_mi(_cyl(0.7, 0.75, 0.12), Vector3(37.2, 0.08, 32.8), root, _mats["rock"], "FireRing")
	_mi(_box(Vector3(0.35, 0.12, 0.12)), Vector3(37.2, 0.18, 32.8), root, _mats["wood"], "AshLog")
	_add_crate(Vector3(42.6, 0, 33.2))
	_add_barrel(Vector3(42.8, 0, 34.4), 0.4)
	_add_bench(Vector3(37.5, 0, 36.2), -0.6)
	_add_bench(Vector3(42.0, 0, 32.5), 0.9)
	_add_bench(Vector3(38.4, 0, 31.6), 0.2)
	_add_lantern_post(Vector3(37.0, 0, 32.0))
	_add_lantern_post(Vector3(42.5, 0, 36.5))
	_add_lantern_post(Vector3(22.0, 0, 22.5))
	_add_lantern_post(Vector3(31.0, 0, 28.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 211
	# Framing props along the spur (outside corridor)
	for i in 10:
		var tt := float(i) / 9.0
		var cx := 12.0 + tt * 24.0
		var cz := 15.5 + tt * 17.0
		var side := 1.0 if i % 2 == 0 else -1.0
		# Perpendicular offset along SE diagonal (dir ~ (28,20))
		var ox := side * rng.randf_range(4.8, 8.5) * 0.71
		var oz := side * rng.randf_range(4.8, 8.5) * -0.55
		var p := Vector3(cx + ox, 0, cz + oz)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 1 if i > 5 else 0)
	for i in 8:
		var ang := i * TAU / 8.0
		_add_flowers(Vector3(40.0 + cos(ang) * 5.2, 0, 34.0 + sin(ang) * 5.2), rng)
	for i in 5:
		var ang := float(i) * TAU / 5.0 + 0.35
		_mi(_sphere(0.35 + float(i % 2) * 0.1), Vector3(40.0 + cos(ang) * 6.0, 0.25, 34.0 + sin(ang) * 6.0), root, _mats["rock"], "Boulder")
	var sign := Node3D.new()
	sign.position = Vector3(36.5, 0, 34.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.6, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	_place_label3d(sign, "Lookout Rock", 40, Vector3(0, 2.3, 0))
	_place_label3d(root, "See the village green", 28, Vector3(40, 4.15, 34), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Lookout Rock", 52, Vector3(40, 3.6, 34))

func get_minimap_markers() -> Dictionary:
	## Data for HUD minimap / compass
	var halls: Array = []
	for b in world_data.get("buildings", []):
		halls.append({"x": float(b["x"]), "z": float(b["z"]), "label": str(b.get("label", "")), "color": str(b.get("color", "#888")), "icon": "hall"})
	# Landmarks for wilds spurs (Wave 25: icon kinds for chunky minimap marks)
	halls.append({"x": 0.5, "z": -48.0, "label": "Glade", "color": "#4a90c8", "icon": "tree"})
	halls.append({"x": -24.0, "z": -54.0, "label": "Pine", "color": "#1f4d32", "icon": "tree"})
	halls.append({"x": 30.0, "z": 18.0, "label": "Garden", "color": "#c9b037", "icon": "tree"})
	halls.append({"x": 40.0, "z": 34.0, "label": "Lookout", "color": "#8a8a9a", "icon": "rock"})
	halls.append({"x": -36.0, "z": 30.0, "label": "Mill", "color": "#7a5a40", "icon": "mill"})
	halls.append({"x": 38.0, "z": -36.0, "label": "Hollow", "color": "#1e4a32", "icon": "tree"})
	halls.append({"x": -38.0, "z": -34.0, "label": "Willow", "color": "#4a7a48", "icon": "tree"})
	halls.append({"x": -20.0, "z": 48.0, "label": "Reed", "color": "#3a6a5a", "icon": "water"})
	halls.append({"x": 48.0, "z": 8.0, "label": "Cross", "color": "#c9b037", "icon": "cross"})
	halls.append({"x": -48.0, "z": 8.0, "label": "Arch", "color": "#8a8a9a", "icon": "arch"})
	halls.append({"x": 48.0, "z": -22.0, "label": "Knoll", "color": "#c9a227", "icon": "knoll"})
	halls.append({"x": -42.0, "z": -20.0, "label": "Birch", "color": "#e8e0d0", "icon": "birch"})
	halls.append({"x": 22.0, "z": 48.0, "label": "Fern", "color": "#3d7a3a", "icon": "fern"})
	halls.append({"x": -48.0, "z": 42.0, "label": "Heather", "color": "#9a6a9a", "icon": "heather"})
	halls.append({"x": 48.0, "z": 42.0, "label": "Thistle", "color": "#6a5a8a", "icon": "thistle"})
	halls.append({"x": -48.0, "z": -48.0, "label": "Maple", "color": "#c45a28", "icon": "maple"})
	halls.append({"x": 0.0, "z": 8.0, "label": "Fountain", "color": "#4a90c8", "icon": "fountain"})
	var npcs: Array = []
	for n in get_tree().get_nodes_in_group("npcs"):
		# Hide indoor duplicates on minimap (keep outdoor mentors)
		if str(n.get("npc_id")).ends_with("-indoor"):
			continue
		npcs.append({"x": n.global_position.x, "z": n.global_position.z})
	var foes: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("is_alive") and e.is_alive() and e.visible:
			foes.append({"x": e.global_position.x, "z": e.global_position.z})
	var px := 0.0
	var pz := 0.0
	var yaw := 0.0
	var zoom := 1.0
	if player:
		px = player.global_position.x
		pz = player.global_position.z
		yaw = float(player.get("cam_yaw"))
		zoom = float(player.get("cam_zoom"))
	var landmark_name := ""
	if _inside_hall == "" and _landmark_here != "":
		landmark_name = _landmark_display_name(_landmark_here)
	return {
		"player": {"x": px, "z": pz, "yaw": yaw, "zoom": zoom},
		"halls": halls,
		"npcs": npcs,
		"foes": foes,
		"inside": _inside_hall,
		"day": _day_phase,
		"weather": _weather_label_cache,
		"landmark_name": landmark_name,
		"landmark_dist": _landmark_dist,  # Wave 69: paces for ✦ chip
	}

func _build_mill_bridge() -> void:
	## Southwest landmark — soft travel (K). Denser spur path, mill yard props, creek foam.
	var root := Node3D.new()
	root.name = "MillBridge"
	static_world.add_child(root)
	# Dirt spur southwest from plaza (overlap ribbon + trim)
	for i in 14:
		var tt := float(i) / 13.0
		var x := -8.0 + tt * (-28.0)
		var z := 14.0 + tt * 16.0
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "MillPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := -10.0 + tt * (-22.0)
		var z := 15.0 + tt * 13.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "MillTrim")
	# Creek under the bridge + foam highlights
	_mi(_cyl(3.4, 3.4, 0.08), Vector3(-36.0, 0.015, 30.0), root, _mats["water"], "MillCreek")
	_water_positions.append(Vector3(-36.0, 0, 30.0))  # Wave 38: brook murmur
	_mi(_cyl(1.5, 1.5, 0.05), Vector3(-39.0, 0.015, 32.5), root, _mats["water"], "MillCreekBend")
	_mi(_cyl(0.55, 0.6, 0.04), Vector3(-37.2, 0.04, 29.4), root, _mat(Color("#a8d4ea"), 0.15), "Foam1")
	_mi(_cyl(0.4, 0.45, 0.03), Vector3(-35.0, 0.04, 30.6), root, _mat(Color("#b8dff0"), 0.15), "Foam2")
	_mi(_cyl(0.35, 0.4, 0.03), Vector3(-38.4, 0.04, 31.2), root, _mat(Color("#a8d4ea"), 0.15), "Foam3")
	_mi(_cyl(0.3, 0.35, 0.03), Vector3(-36.6, 0.04, 31.4), root, _mat(Color("#b8dff0"), 0.12), "Foam4")
	# Bridge planks + center runner
	_mi(_box(Vector3(5.2, 0.12, 1.8)), Vector3(-36.0, 0.35, 30.0), root, _mats["wood"], "BridgeDeck")
	_mi(_box(Vector3(5.0, 0.04, 0.35)), Vector3(-36.0, 0.43, 30.0), root, _mats["wood_light"], "BridgeRunner")
	_mi(_box(Vector3(5.2, 0.35, 0.12)), Vector3(-36.0, 0.65, 29.0), root, _mats["wood_light"], "RailS")
	_mi(_box(Vector3(5.2, 0.35, 0.12)), Vector3(-36.0, 0.65, 31.0), root, _mats["wood_light"], "RailN")
	for i in 5:
		var px := -38.0 + float(i) * 1.0
		_mi(_cyl(0.08, 0.1, 0.7), Vector3(px, 0.2, 29.0), root, _mats["wood"], "PillarS")
		_mi(_cyl(0.08, 0.1, 0.7), Vector3(px, 0.2, 31.0), root, _mats["wood"], "PillarN")
	# Small mill house + door + water wheel
	_mi(_box(Vector3(3.2, 2.4, 2.8)), Vector3(-40.5, 1.2, 27.0), root, _mats["wood"], "MillHouse")
	_mi(_box(Vector3(3.6, 0.2, 3.2)), Vector3(-40.5, 2.5, 27.0), root, _mats["roof"], "MillRoof")
	_mi(_box(Vector3(0.7, 1.3, 0.08)), Vector3(-40.5, 0.85, 28.45), root, _mats["wood_light"], "MillDoor")
	_mi(_box(Vector3(0.55, 0.55, 0.06)), Vector3(-39.3, 1.7, 28.45), root, _mat(Color("#7ec8e3"), 0.2), "MillWindow")
	_mi(_cyl(1.1, 1.1, 0.22), Vector3(-38.2, 1.3, 28.6), root, _mats["wood_light"], "Wheel")
	for i in 6:
		var ang := float(i) * TAU / 6.0
		var bx := -38.2 + cos(ang) * 1.05
		var by := 1.3 + sin(ang) * 1.05
		_mi(_box(Vector3(0.12, 0.7, 0.08)), Vector3(bx, by, 28.6), root, _mats["wood"], "Blade")
	_mi(_cyl(0.12, 0.14, 1.6), Vector3(-38.2, 1.3, 27.8), root, _mats["iron"], "Axle")
	# Grindstone + grain sacks + fence stub + yard props
	_mi(_cyl(0.55, 0.55, 0.18), Vector3(-42.2, 0.55, 29.2), root, _mats["stone"], "Grindstone")
	_mi(_cyl(0.08, 0.1, 0.7), Vector3(-42.2, 0.25, 29.2), root, _mats["wood"], "GrindStand")
	_mi(_sphere(0.38, 0.55), Vector3(-41.5, 0.35, 25.6), root, _mats["barrel"], "Sack1")
	_mi(_sphere(0.32, 0.48), Vector3(-42.2, 0.3, 26.1), root, _mats["barrel"], "Sack2")
	_mi(_sphere(0.28, 0.42), Vector3(-40.8, 0.28, 25.2), root, _mats["barrel"], "Sack3")
	_add_crate(Vector3(-42.8, 0, 27.4))
	_add_barrel(Vector3(-39.2, 0, 25.0), -0.5)
	_mi(_box(Vector3(0.08, 0.9, 0.08)), Vector3(-34.8, 0.45, 27.2), root, _mats["fence"], "FenceA")
	_mi(_box(Vector3(0.08, 0.9, 0.08)), Vector3(-33.6, 0.45, 27.2), root, _mats["fence"], "FenceB")
	_mi(_box(Vector3(1.4, 0.08, 0.08)), Vector3(-34.2, 0.75, 27.2), root, _mats["fence"], "FenceRail")
	_mi(_box(Vector3(0.08, 0.9, 0.08)), Vector3(-32.4, 0.45, 27.2), root, _mats["fence"], "FenceC")
	_mi(_box(Vector3(1.3, 0.08, 0.08)), Vector3(-33.0, 0.55, 27.2), root, _mats["fence"], "FenceRail2")
	_add_lantern_post(Vector3(-33.5, 0, 28.0))
	_add_lantern_post(Vector3(-33.5, 0, 32.0))
	_add_lantern_post(Vector3(-42.0, 0, 25.0))
	_add_lantern_post(Vector3(-18.0, 0, 20.0))
	_add_lantern_post(Vector3(-26.0, 0, 24.5))
	_add_bench(Vector3(-34.0, 0, 33.5), 0.3)
	_add_bench(Vector3(-38.5, 0, 33.8), -0.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 307
	# Framing props along the spur (outside corridor)
	for i in 10:
		var tt := float(i) / 9.0
		var cx := -10.0 + tt * (-22.0)
		var cz := 15.0 + tt * 13.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var ox := side * rng.randf_range(4.8, 8.5) * 0.55
		var oz := side * rng.randf_range(4.8, 8.5) * 0.75
		var p := Vector3(cx + ox, 0, cz + oz)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0 if i < 5 else 1)
	for i in 7:
		var ang := i * TAU / 7.0
		_add_flowers(Vector3(-36.0 + cos(ang) * 5.8, 0, 30.0 + sin(ang) * 5.8), rng)
	var sign := Node3D.new()
	sign.position = Vector3(-32.5, 0, 30.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.7, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	_place_label3d(sign, "Mill Bridge", 40, Vector3(0, 2.3, 0))
	_place_label3d(root, "Creek mill & bridge", 28, Vector3(-36.0, 3.95, 30.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Mill Bridge", 52, Vector3(-36.0, 3.4, 30.0))


func _build_cedar_hollow() -> void:
	## Northeast late-wilds landmark — cedar stand, fallen log, lanterns (soft travel O).
	var root := Node3D.new()
	root.name = "CedarHollow"
	static_world.add_child(root)
	# Dirt spur northeast from the glade path / village edge
	for i in 14:
		var tt := float(i) / 13.0
		var x := 10.0 + tt * 28.0
		var z := -16.0 + tt * (-20.0)
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "HollowPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := 12.0 + tt * 22.0
		var z := -18.0 + tt * (-16.0)
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "HollowTrim")
	# Soft needle bed in the clearing
	_mi(_cyl(4.2, 4.2, 0.05), Vector3(38.0, 0.02, -36.0), root, _mats["grass_dark"], "NeedleBed")
	# Fallen log + stump
	var logm := _mi(_cyl(0.22, 0.26, 2.6), Vector3(35.2, 0.28, -34.2), root, _mats["wood"], "FallenLog")
	logm.rotation_degrees = Vector3(0, 0, 90)
	_mi(_cyl(0.28, 0.32, 0.45), Vector3(40.6, 0.22, -38.4), root, _mats["wood"], "Stump")
	_add_lantern_post(Vector3(34.6, 0, -33.5))
	_add_lantern_post(Vector3(41.2, 0, -38.8))
	_add_lantern_post(Vector3(24.0, 0, -26.0))
	_add_lantern_post(Vector3(16.5, 0, -20.5))
	_add_bench(Vector3(36.2, 0, -32.6), 0.4)
	_add_crate(Vector3(40.8, 0, -33.4))
	var rng := RandomNumberGenerator.new()
	rng.seed = 421
	# Framing cedars kept outside the walk corridor
	for i in 10:
		var tt := float(i) / 9.0
		var cx := 12.0 + tt * 22.0
		var cz := -18.0 + tt * (-16.0)
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx + side * rng.randf_range(5.0, 8.5), 0, cz + side * rng.randf_range(1.5, 4.0) * 0.4)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 2)
	for i in 6:
		var ang := float(i) * TAU / 6.0
		_add_tree(Vector3(38.0 + cos(ang) * 6.4, 0, -36.0 + sin(ang) * 6.4), 2)
		_add_flowers(Vector3(38.0 + cos(ang) * 4.6, 0, -36.0 + sin(ang) * 4.6), rng)
	var sign := Node3D.new()
	sign.position = Vector3(34.0, 0, -36.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.7, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	_place_label3d(sign, "Cedar Hollow", 40, Vector3(0, 2.3, 0))
	_place_label3d(root, "Quiet cedar grove", 28, Vector3(38.0, 3.95, -36.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Cedar Hollow", 52, Vector3(38.0, 3.4, -36.0))



func _build_willow_bend() -> void:
	## Northwest wilds landmark — weeping willows by a quiet brook bend (soft travel P).
	var root := Node3D.new()
	root.name = "WillowBend"
	static_world.add_child(root)
	# Dirt spur northwest from the village / glade edge
	for i in 14:
		var tt := float(i) / 13.0
		var x := -10.0 + tt * (-28.0)
		var z := -12.0 + tt * (-22.0)
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "WillowPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := -12.0 + tt * (-22.0)
		var z := -14.0 + tt * (-16.0)
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "WillowTrim")
	# Soft grass ring + quiet brook crescent
	_mi(_cyl(4.0, 4.0, 0.05), Vector3(-38.0, 0.02, -34.0), root, _mats["grass_dark"], "WillowBed")
	_mi(_cyl(2.6, 2.6, 0.06), Vector3(-41.5, 0.015, -36.5), root, _mats["water"], "BrookBend")
	_water_positions.append(Vector3(-41.5, 0, -36.5))  # Wave 38: brook murmur
	_mi(_cyl(1.2, 1.2, 0.04), Vector3(-43.0, 0.015, -34.2), root, _mats["water"], "BrookFoam")
	_add_lantern_post(Vector3(-34.8, 0, -31.5))
	_add_lantern_post(Vector3(-41.0, 0, -37.2))
	_add_lantern_post(Vector3(-24.0, 0, -22.0))
	_add_lantern_post(Vector3(-16.5, 0, -16.5))
	_add_bench(Vector3(-36.2, 0, -31.2), -0.5)
	_add_crate(Vector3(-40.2, 0, -31.8))
	var rng := RandomNumberGenerator.new()
	rng.seed = 521
	# Framing willows outside the walk corridor
	for i in 10:
		var tt := float(i) / 9.0
		var cx := -12.0 + tt * (-22.0)
		var cz := -14.0 + tt * (-16.0)
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx + side * rng.randf_range(5.0, 8.5), 0, cz + side * rng.randf_range(1.5, 4.0) * 0.4)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 3)
	for i in 6:
		var ang := float(i) * TAU / 6.0
		_add_tree(Vector3(-38.0 + cos(ang) * 6.2, 0, -34.0 + sin(ang) * 6.2), 3)
		_add_flowers(Vector3(-38.0 + cos(ang) * 4.4, 0, -34.0 + sin(ang) * 4.4), rng)
	var sign := Node3D.new()
	sign.position = Vector3(-34.0, 0, -34.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.7, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	_place_label3d(sign, "Willow Bend", 40, Vector3(0, 2.3, 0))
	_place_label3d(root, "Quiet willow brook", 28, Vector3(-38.0, 3.95, -34.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Willow Bend", 52, Vector3(-38.0, 3.4, -34.0))



func _build_reed_pool() -> void:
	## South wilds landmark — quiet reed-ringed pool (soft travel Y).
	var root := Node3D.new()
	root.name = "ReedPool"
	static_world.add_child(root)
	# Dirt spur south from the village / chronicle edge
	for i in 14:
		var tt := float(i) / 13.0
		var x := -6.0 + tt * (-14.0)
		var z := 20.0 + tt * 28.0
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "ReedPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := -8.0 + tt * (-10.0)
		var z := 24.0 + tt * 20.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "ReedTrim")
	# Soft bank + quiet pool
	_mi(_cyl(4.0, 4.0, 0.05), Vector3(-20.0, 0.02, 48.0), root, _mats["grass_dark"], "ReedBed")
	_mi(_cyl(2.8, 2.8, 0.06), Vector3(-20.0, 0.015, 48.0), root, _mats["water"], "QuietPool")
	_water_positions.append(Vector3(-20.0, 0, 48.0))  # Wave 38: brook murmur
	_mi(_cyl(1.1, 1.1, 0.04), Vector3(-22.2, 0.015, 49.6), root, _mats["water"], "PoolFoam")
	_add_lantern_post(Vector3(-16.8, 0, 45.2))
	_add_lantern_post(Vector3(-23.5, 0, 50.8))
	_add_lantern_post(Vector3(-12.0, 0, 34.0))
	_add_lantern_post(Vector3(-8.5, 0, 26.5))
	_add_bench(Vector3(-17.2, 0, 45.0), 0.3)
	_add_crate(Vector3(-23.0, 0, 45.6))
	var rng := RandomNumberGenerator.new()
	rng.seed = 622
	# Framing reeds + soft trees outside the walk corridor
	for i in 10:
		var tt := float(i) / 9.0
		var cx := -8.0 + tt * (-10.0)
		var cz := 24.0 + tt * 20.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx + side * rng.randf_range(4.5, 7.5), 0, cz + side * rng.randf_range(1.2, 3.5) * 0.4)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	# Tall reed clumps around the pool rim
	for i in 12:
		var ang := float(i) * TAU / 12.0
		var rp := Vector3(-20.0 + cos(ang) * 3.6, 0, 48.0 + sin(ang) * 3.6)
		var reed := Node3D.new()
		reed.position = rp
		root.add_child(reed)
		for k in 3:
			var h := rng.randf_range(1.1, 1.7)
			var offset := Vector3(rng.randf_range(-0.18, 0.18), h * 0.5, rng.randf_range(-0.18, 0.18))
			_mi(_cyl(0.035, 0.045, h), offset, reed, _mats["leaf_willow"], "ReedStem")
			_mi(_sphere(0.07, 0.12), offset + Vector3(0, h * 0.52, 0), reed, _mats["leaf_alt"], "ReedTuft")
		reed.set_meta("sway_phase", ang + rng.randf() * 0.4)
		reed.set_meta("sway_amp", rng.randf_range(0.05, 0.09))
		_reed_sway_nodes.append(reed)
		if i % 2 == 0:
			_add_flowers(Vector3(-20.0 + cos(ang) * 4.8, 0, 48.0 + sin(ang) * 4.8), rng)
	var sign := Node3D.new()
	sign.position = Vector3(-16.5, 0, 48.0)
	root.add_child(sign)
	_mi(_cyl(0.08, 0.1, 1.8), Vector3(0, 0.9, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(1.7, 0.6, 0.1)), Vector3(0, 1.6, 0), sign, _mats["wood_light"], "Board")
	_place_label3d(sign, "Reed Pool", 40, Vector3(0, 2.3, 0))
	_place_label3d(root, "Quiet reed pool", 28, Vector3(-20.0, 3.95, 48.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Reed Pool", 52, Vector3(-20.0, 3.4, 48.0))


func _dusk_sway_boost() -> float:
	return 1.55 if (_inside_hall == "" and _is_dusk_firefly_time()) else 1.0


func _apply_plant_sway(nodes: Array, freq_z: float, freq_x: float, phase_mul: float, x_scale: float, default_amp: float, dusk_boost: float = 1.0) -> void:
	if nodes.is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	for n in nodes:
		if n == null or not is_instance_valid(n):
			continue
		var phase := float(n.get_meta("sway_phase", 0.0))
		var amp := float(n.get_meta("sway_amp", default_amp)) * dusk_boost
		n.rotation.z = sin(t * freq_z + phase) * amp
		n.rotation.x = cos(t * freq_x + phase * phase_mul) * amp * x_scale


func _update_reed_sway(_delta: float) -> void:
	## Wave 57: soft reed sway near Reed Pool — gentle wind lean (RuneScape-chunky, wholesome).
	_apply_plant_sway(_reed_sway_nodes, 1.15, 0.95, 0.7, 0.55, 0.06)


func _update_thistle_sway(_delta: float) -> void:
	## Wave 58: soft thistle sway at Thistle Rise — gentle wind lean (RuneScape-chunky, wholesome).
	## Wave 71: soft thistle sway reads stronger at dusk (RuneScape-chunky, wholesome).
	_apply_plant_sway(_thistle_sway_nodes, 1.05, 0.88, 0.65, 0.5, 0.05, _dusk_sway_boost())


func _update_willow_sway(_delta: float) -> void:
	## Wave 61: soft willow weep sway at Willow Bend — gentle canopy lean (RuneScape-chunky, wholesome).
	_apply_plant_sway(_willow_sway_nodes, 0.72, 0.58, 0.7, 0.55, 0.028)


func _update_fern_sway(_delta: float) -> void:
	## Wave 62: soft fern sway at Fern Dell — gentle frond lean (RuneScape-chunky, wholesome).
	## Wave 69: soft fern-frond sway reads stronger at dusk (RuneScape-chunky, wholesome).
	_apply_plant_sway(_fern_sway_nodes, 1.08, 0.92, 0.65, 0.55, 0.045, _dusk_sway_boost())


func _update_heather_sway(_delta: float) -> void:
	## Wave 63: soft heather sway at Heather Heath — gentle tuft lean (RuneScape-chunky, wholesome).
	## Wave 70: soft heather sway reads stronger at dusk (RuneScape-chunky, wholesome).
	_apply_plant_sway(_heather_sway_nodes, 0.95, 0.78, 0.6, 0.5, 0.04, _dusk_sway_boost())


func _begin_hall_light_dip() -> void:
	## Wave 63: soft hall enter/exit light dip (RuneScape-chunky, wholesome).
	_hall_light_dip_t = 0.55


func _update_hall_light_dip(delta: float) -> void:
	## Wave 63: brief cozy dim after crossing a guild-hall door (applied after day/night).
	if _hall_light_dip_t <= 0.0:
		return
	_hall_light_dip_t = maxf(0.0, _hall_light_dip_t - delta)
	var u := clampf(_hall_light_dip_t / 0.55, 0.0, 1.0)
	var pulse := sin(u * PI)  # soft in-out dip
	if _sun:
		_sun.light_energy = maxf(0.12, _sun.light_energy * (1.0 - 0.28 * pulse))
	if _env:
		_env.ambient_light_energy = maxf(0.12, _env.ambient_light_energy * (1.0 - 0.32 * pulse))



func _add_chunky_sign(parent: Node, pos: Vector3, title: String, yaw: float = 0.0) -> Node3D:
	## Wave 23 feel: chunkier RuneScape-style landmark sign — thick post, framed board, clear label.
	var sign := Node3D.new()
	sign.name = "LandmarkSign"
	sign.position = pos
	sign.rotation.y = yaw
	parent.add_child(sign)
	# Thick post + cross-brace
	_mi(_cyl(0.11, 0.13, 2.05), Vector3(0, 1.02, 0), sign, _mats["wood"], "Post")
	_mi(_box(Vector3(0.22, 0.14, 0.22)), Vector3(0, 0.08, 0), sign, _mats["wood"], "PostBase")
	# Framed board (dark border + lighter face)
	_mi(_box(Vector3(2.05, 0.85, 0.12)), Vector3(0, 1.72, 0), sign, _mats["wood"], "Frame")
	_mi(_box(Vector3(1.78, 0.62, 0.08)), Vector3(0, 1.72, 0.02), sign, _mats["wood_light"], "Board")
	# Soft gold corner studs
	if _mats.has("lantern"):
		_mi(_sphere(0.06), Vector3(-0.88, 1.95, 0.08), sign, _mats["lantern"], "StudTL")
		_mi(_sphere(0.06), Vector3(0.88, 1.95, 0.08), sign, _mats["lantern"], "StudTR")
		_mi(_sphere(0.06), Vector3(-0.88, 1.48, 0.08), sign, _mats["lantern"], "StudBL")
		_mi(_sphere(0.06), Vector3(0.88, 1.48, 0.08), sign, _mats["lantern"], "StudBR")
	_place_label3d(sign, title, 42, Vector3(0, 2.45, 0))
	return sign


func _build_quiet_cross() -> void:
	## East wilds landmark — simple wooden cross on a grassy knoll (soft travel U). Christian/creationist tone.
	var root := Node3D.new()
	root.name = "QuietCross"
	static_world.add_child(root)
	# Dirt spur east from the village green (along z≈8 fountain latitude)
	for i in 14:
		var tt := float(i) / 13.0
		var x := 14.0 + tt * 34.0
		var z := 8.0 + sin(tt * PI) * 0.4
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "CrossPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := 16.0 + tt * 28.0
		var z := 8.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "CrossTrim")
	# Grassy knoll + soft flowers
	_mi(_cyl(4.2, 4.2, 0.08), Vector3(48.0, 0.04, 8.0), root, _mats["grass_dark"], "Knoll")
	_mi(_cyl(2.4, 2.4, 0.12), Vector3(48.0, 0.1, 8.0), root, _mats["grass_light"], "KnollTop")
	# Simple wooden cross (wholesome — not occult)
	var cross := Node3D.new()
	cross.name = "WoodCross"
	cross.position = Vector3(48.0, 0.15, 8.0)
	root.add_child(cross)
	_mi(_box(Vector3(0.22, 2.6, 0.18)), Vector3(0, 1.4, 0), cross, _mats["wood"], "Upright")
	_mi(_box(Vector3(1.35, 0.2, 0.16)), Vector3(0, 2.25, 0), cross, _mats["wood_light"], "Beam")
	_mi(_box(Vector3(0.32, 0.18, 0.28)), Vector3(0, 0.12, 0), cross, _mats["stone"], "CrossBase")
	_add_lantern_post(Vector3(44.5, 0, 10.5))
	_add_lantern_post(Vector3(51.2, 0, 5.8))
	_add_lantern_post(Vector3(28.0, 0, 8.0))
	_add_lantern_post(Vector3(20.0, 0, 9.5))
	_add_bench(Vector3(45.6, 0, 5.4), 0.2)
	_add_crate(Vector3(50.8, 0, 10.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 723
	# Framing trees/bushes outside the walk corridor
	for i in 10:
		var tt := float(i) / 9.0
		var cx := 16.0 + tt * 28.0
		var cz := 8.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx, 0, cz + side * rng.randf_range(4.8, 7.8))
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	for i in 8:
		var ang := float(i) * TAU / 8.0
		_add_flowers(Vector3(48.0 + cos(ang) * 3.2, 0, 8.0 + sin(ang) * 3.2), rng)
		if i % 2 == 0:
			_add_tree(Vector3(48.0 + cos(ang) * 6.5, 0, 8.0 + sin(ang) * 6.5), 1)
	_add_chunky_sign(root, Vector3(44.2, 0, 8.0), "Quiet Cross", 0.15)
	_place_label3d(root, "A place to give thanks", 28, Vector3(48.0, 4.15, 8.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Quiet Cross", 52, Vector3(48.0, 3.55, 8.0))
	# Wave 65: soft quiet cross lantern at dusk — warm honey OmniLight on beam + knoll rim (RuneScape-chunky, wholesome)
	var cross_light := OmniLight3D.new()
	cross_light.name = "CrossDuskGlow"
	cross_light.light_color = Color(1.0, 0.82, 0.48)  # soft warm lantern honey
	cross_light.light_energy = 0.0
	cross_light.omni_range = 8.5
	cross_light.omni_attenuation = 1.25
	cross_light.shadow_enabled = false
	cross_light.position = Vector3(48.0, 2.55, 8.0)  # near wooden cross beam
	root.add_child(cross_light)
	_cross_dusk_lights.append(cross_light)
	var cross_rim := OmniLight3D.new()
	cross_rim.name = "CrossDuskRim"
	cross_rim.light_color = Color(0.98, 0.78, 0.42)
	cross_rim.light_energy = 0.0
	cross_rim.omni_range = 5.2
	cross_rim.omni_attenuation = 1.4
	cross_rim.shadow_enabled = false
	cross_rim.position = Vector3(48.0, 1.15, 8.0)
	root.add_child(cross_rim)
	_cross_dusk_lights.append(cross_rim)


func _build_stone_arch() -> void:
	## West wilds landmark — weathered stone gateway (soft travel X). Distinct from Quiet Cross.
	var root := Node3D.new()
	root.name = "StoneArch"
	static_world.add_child(root)
	# Dirt spur west from the village green (along z≈8 fountain latitude)
	for i in 14:
		var tt := float(i) / 13.0
		var x := -14.0 - tt * 34.0
		var z := 8.0 + sin(tt * PI) * 0.4
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "ArchPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := -16.0 - tt * 28.0
		var z := 8.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "ArchTrim")
	# Stone plaza under the arch
	_mi(_cyl(4.0, 4.0, 0.08), Vector3(-48.0, 0.04, 8.0), root, _mats["stone"], "ArchPlaza")
	_mi(_cyl(2.2, 2.2, 0.06), Vector3(-48.0, 0.09, 8.0), root, _mats["stone_dark"], "ArchPlazaInner")
	# Weathered stone gateway (two pillars + lintel + soft keystone)
	var arch := Node3D.new()
	arch.name = "Gateway"
	arch.position = Vector3(-48.0, 0.1, 8.0)
	root.add_child(arch)
	_mi(_box(Vector3(0.85, 3.2, 0.85)), Vector3(-1.55, 1.6, 0), arch, _mats["stone"], "PillarL")
	_mi(_box(Vector3(0.85, 3.2, 0.85)), Vector3(1.55, 1.6, 0), arch, _mats["stone"], "PillarR")
	_mi(_box(Vector3(4.2, 0.7, 1.0)), Vector3(0, 3.45, 0), arch, _mats["stone_dark"], "Lintel")
	_mi(_box(Vector3(0.55, 0.55, 1.05)), Vector3(0, 3.85, 0), arch, _mats["stone"], "Keystone")
	# Soft moss tufts on the lintel (wholesome wilds wear)
	_mi(_sphere(0.18, 0.22), Vector3(-0.9, 3.75, 0.35), arch, _mats["leaf"], "MossL")
	_mi(_sphere(0.14, 0.18), Vector3(0.75, 3.7, -0.3), arch, _mats["leaf_alt"], "MossR")
	_add_lantern_post(Vector3(-44.5, 0, 10.5))
	_add_lantern_post(Vector3(-51.2, 0, 5.8))
	_add_lantern_post(Vector3(-28.0, 0, 8.0))
	_add_lantern_post(Vector3(-20.0, 0, 9.5))
	_add_bench(Vector3(-45.6, 0, 5.4), -0.2)
	_add_crate(Vector3(-50.8, 0, 10.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 824
	# Framing rocks/bushes/trees outside the walk corridor
	for i in 10:
		var tt := float(i) / 9.0
		var cx := -16.0 - tt * 28.0
		var cz := 8.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx, 0, cz + side * rng.randf_range(4.8, 7.8))
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	for i in 8:
		var ang := float(i) * TAU / 8.0
		_add_flowers(Vector3(-48.0 + cos(ang) * 3.2, 0, 8.0 + sin(ang) * 3.2), rng)
		if i % 2 == 0:
			_add_tree(Vector3(-48.0 + cos(ang) * 6.5, 0, 8.0 + sin(ang) * 6.5), 1)
	_add_chunky_sign(root, Vector3(-44.2, 0, 8.0), "Stone Arch", -0.15)
	_place_label3d(root, "Gateway to the west wilds", 28, Vector3(-48.0, 4.55, 8.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Stone Arch", 52, Vector3(-48.0, 4.0, 8.0))
	# Wave 64: soft stone arch glow at dusk — cool limestone OmniLight on keystone + plaza rim (RuneScape-chunky, wholesome)
	var arch_light := OmniLight3D.new()
	arch_light.name = "ArchDuskGlow"
	arch_light.light_color = Color(0.82, 0.88, 1.0)  # soft cool stone
	arch_light.light_energy = 0.0
	arch_light.omni_range = 9.0
	arch_light.omni_attenuation = 1.25
	arch_light.shadow_enabled = false
	arch_light.position = Vector3(-48.0, 3.95, 8.0)  # near keystone
	root.add_child(arch_light)
	_arch_dusk_lights.append(arch_light)
	var arch_rim := OmniLight3D.new()
	arch_rim.name = "ArchDuskRim"
	arch_rim.light_color = Color(0.78, 0.84, 0.96)
	arch_rim.light_energy = 0.0
	arch_rim.omni_range = 5.5
	arch_rim.omni_attenuation = 1.4
	arch_rim.shadow_enabled = false
	arch_rim.position = Vector3(-48.0, 1.2, 8.0)
	root.add_child(arch_rim)
	_arch_dusk_lights.append(arch_rim)



func _build_amber_knoll() -> void:
	## East-northeast wilds landmark — warm honey-stone rise with wildflowers (soft travel Z).
	## Distinct from Quiet Cross (wooden cross) and Cedar Hollow (cedar stand).
	var root := Node3D.new()
	root.name = "AmberKnoll"
	static_world.add_child(root)
	# Dirt spur toward the knoll (from near Quiet Cross latitude, angling north)
	for i in 14:
		var tt := float(i) / 13.0
		var x := 16.0 + tt * 32.0
		var z := -4.0 + tt * (-18.0)
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "KnollPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := 18.0 + tt * 26.0
		var z := -5.0 + tt * (-14.0)
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "KnollTrim")
	# Amber stone rise (chunky layered knoll)
	_mi(_cyl(4.4, 4.4, 0.1), Vector3(48.0, 0.05, -22.0), root, _mats["grass_dark"], "KnollGrass")
	_mi(_cyl(3.2, 3.2, 0.35), Vector3(48.0, 0.22, -22.0), root, _mats["amber_dark"], "KnollBase")
	_mi(_cyl(2.2, 2.2, 0.45), Vector3(48.0, 0.55, -22.0), root, _mats["amber"], "KnollMid")
	_mi(_cyl(1.1, 1.1, 0.4), Vector3(48.0, 0.95, -22.0), root, _mats["amber_dark"], "KnollCap")
	# Soft honey-glow lantern stone on the crest
	_mi(_sphere(0.28, 0.32), Vector3(48.0, 1.35, -22.0), root, _mats["lantern_glow"], "AmberGlow")
	# Wave 59: soft amber knoll glow at dusk — warm OmniLight on the crest (RuneScape-chunky, wholesome)
	var knoll_light := OmniLight3D.new()
	knoll_light.name = "KnollDuskGlow"
	knoll_light.light_color = Color(1.0, 0.80, 0.40)  # Wave 73: warmer amber-glow polish
	knoll_light.light_energy = 0.0
	knoll_light.omni_range = 11.0  # Wave 73: soft Amber Knoll amber-glow polish at dusk
	knoll_light.omni_attenuation = 1.15
	knoll_light.shadow_enabled = false
	knoll_light.position = Vector3(48.0, 1.55, -22.0)
	root.add_child(knoll_light)
	_knoll_dusk_lights.append(knoll_light)
	var knoll_rim := OmniLight3D.new()
	knoll_rim.name = "KnollDuskRim"
	knoll_rim.light_color = Color(1.0, 0.74, 0.32)  # Wave 73: warmer amber rim
	knoll_rim.light_energy = 0.0
	knoll_rim.omni_range = 7.2
	knoll_rim.omni_attenuation = 1.4
	knoll_rim.shadow_enabled = false
	knoll_rim.position = Vector3(48.0, 0.85, -22.0)
	root.add_child(knoll_rim)
	_knoll_dusk_lights.append(knoll_rim)
	_add_lantern_post(Vector3(44.2, 0, -19.5))
	_add_lantern_post(Vector3(51.5, 0, -24.8))
	_add_lantern_post(Vector3(28.0, 0, -10.0))
	_add_lantern_post(Vector3(22.0, 0, -6.0))
	_add_bench(Vector3(45.4, 0, -24.6), 0.35)
	_add_crate(Vector3(50.6, 0, -19.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 925
	# Framing props outside the walk corridor
	for i in 10:
		var tt := float(i) / 9.0
		var cx := 18.0 + tt * 26.0
		var cz := -5.0 + tt * (-14.0)
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx, 0, cz + side * rng.randf_range(4.8, 7.8))
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	for i in 10:
		var ang := float(i) * TAU / 10.0
		_add_flowers(Vector3(48.0 + cos(ang) * 3.4, 0, -22.0 + sin(ang) * 3.4), rng)
		if i % 2 == 0:
			_add_tree(Vector3(48.0 + cos(ang) * 6.6, 0, -22.0 + sin(ang) * 6.6), 1)
	_add_chunky_sign(root, Vector3(44.0, 0, -22.0), "Amber Knoll", 0.2)
	_place_label3d(root, "Warm stones catch the light", 28, Vector3(48.0, 4.2, -22.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Amber Knoll", 52, Vector3(48.0, 3.6, -22.0))



func _build_birch_rest() -> void:
	## Southwest wilds landmark — pale birch stand with resting benches (soft travel 6).
	## Distinct from Willow Bend (weeping water) and Stone Arch (gateway).
	var root := Node3D.new()
	root.name = "BirchRest"
	static_world.add_child(root)
	# Dirt spur southwest from the green
	for i in 14:
		var tt := float(i) / 13.0
		var x := -14.0 + tt * (-28.0)
		var z := -6.0 + tt * (-14.0)
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "BirchPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := -16.0 + tt * (-24.0)
		var z := -7.0 + tt * (-12.0)
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "BirchTrim")
	# Soft clearing under birches
	_mi(_cyl(4.2, 4.2, 0.08), Vector3(-42.0, 0.04, -20.0), root, _mats["grass_dark"], "BirchClearing")
	_mi(_cyl(2.4, 2.4, 0.06), Vector3(-42.0, 0.08, -20.0), root, _mats["grass_light"], "BirchClearingInner")
	# Pale birch trunks (white bark + dark marks)
	for i in 7:
		var ang := float(i) * TAU / 7.0 + 0.2
		var bx := -42.0 + cos(ang) * 3.6
		var bz := -20.0 + sin(ang) * 3.6
		var th := 2.4 + float(i % 3) * 0.25
		_mi(_cyl(0.16, 0.20, th), Vector3(bx, th * 0.5, bz), root, _mats["birch"], "BirchTrunk%d" % i)
		_mi(_cyl(0.05, 0.06, 0.35), Vector3(bx + 0.08, th * 0.55, bz), root, _mats["birch_dark"], "BirchMark%d" % i)
		_mi(_sphere(0.85, 1.2), Vector3(bx, th + 0.45, bz), root, _mats["leaf_birch"], "BirchCanopy%d" % i)
	# Resting benches + crate + lanterns
	_add_bench(Vector3(-40.2, 0, -18.4), -0.4)
	_add_bench(Vector3(-44.0, 0, -21.6), 0.55)
	_add_crate(Vector3(-39.5, 0, -22.0))
	_add_lantern_post(Vector3(-38.5, 0, -17.5))
	_add_lantern_post(Vector3(-45.5, 0, -22.5))
	_add_lantern_post(Vector3(-28.0, 0, -12.0))
	_add_lantern_post(Vector3(-20.0, 0, -8.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1026
	for i in 10:
		var tt := float(i) / 9.0
		var cx := -16.0 + tt * (-24.0)
		var cz := -7.0 + tt * (-12.0)
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx, 0, cz + side * rng.randf_range(4.8, 7.8))
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	for i in 10:
		var ang := float(i) * TAU / 10.0
		# Soft heather / flower tufts
		_mi(_sphere(0.18, 0.22), Vector3(-42.0 + cos(ang) * 2.8, 0.12, -20.0 + sin(ang) * 2.8), root, _mats["heather"], "Heather%d" % i)
		_add_flowers(Vector3(-42.0 + cos(ang) * 3.5, 0, -20.0 + sin(ang) * 3.5), rng)
	_add_chunky_sign(root, Vector3(-38.5, 0, -20.0), "Birch Rest", -0.25)
	_place_label3d(root, "Pale trunks, quiet rest", 28, Vector3(-42.0, 4.1, -20.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Birch Rest", 52, Vector3(-42.0, 3.5, -20.0))



func _update_door_glows() -> void:
	## Wave 27: soft warm pulse on guild-hall Enter markers (wholesome, no combat labels).
	if _door_glow_mats.is_empty():
		return
	var pulse: float = 0.38 + 0.32 * abs(sin(Time.get_ticks_msec() * 0.0035))
	for entry in _door_glow_mats:
		var gmat: StandardMaterial3D = entry.get("glow")
		var wmat: StandardMaterial3D = entry.get("wash")
		if gmat:
			gmat.albedo_color = Color(1.0, 0.92, 0.45, 0.28 + 0.38 * pulse)
		if wmat:
			wmat.albedo_color = Color(1.0, 0.88, 0.4, 0.12 + 0.18 * pulse)


func _build_fern_dell() -> void:
	## South-southeast wilds landmark — soft fern hollow (soft travel 7).
	## Distinct from Reed Pool (reeds/water west) and Birch Rest (pale trunks SW).
	var root := Node3D.new()
	root.name = "FernDell"
	static_world.add_child(root)
	# Dirt spur SSE from the green
	for i in 14:
		var tt := float(i) / 13.0
		var x := 8.0 + tt * 14.0
		var z := 20.0 + tt * 28.0
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "FernPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := 9.0 + tt * 12.0
		var z := 22.0 + tt * 24.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "FernTrim")
	# Soft mossy dell floor
	_mi(_cyl(4.4, 4.4, 0.08), Vector3(22.0, 0.04, 48.0), root, _mats["grass_dark"], "FernClearing")
	_mi(_cyl(2.6, 2.6, 0.06), Vector3(22.0, 0.08, 48.0), root, _mats["fern_light"], "FernClearingInner")
	# Ring of fern fronds (chunky leaf fans)
	# Wave 62: each frond is a sway parent so soft fern sway reads at Fern Dell
	for i in 9:
		var ang := float(i) * TAU / 9.0 + 0.15
		var fx := 22.0 + cos(ang) * 3.4
		var fz := 48.0 + sin(ang) * 3.4
		var fh := 0.55 + float(i % 3) * 0.12
		var frond := Node3D.new()
		frond.name = "FernFrond%d" % i
		frond.position = Vector3(fx, 0, fz)
		frond.set_meta("sway_phase", ang)
		frond.set_meta("sway_amp", 0.045 + float(i % 3) * 0.01)
		root.add_child(frond)
		_fern_sway_nodes.append(frond)
		# Stem
		_mi(_cyl(0.04, 0.05, fh), Vector3(0, fh * 0.5, 0), frond, _mats["fern_dark"], "FernStem")
		# Frond lobes
		var lobe := _mi(_box(Vector3(0.55, 0.06, 0.28)), Vector3(0, fh + 0.08, 0), frond, _mats["fern"], "FernLobe")
		lobe.rotation_degrees = Vector3(12.0, rad_to_deg(ang), 18.0 if i % 2 == 0 else -18.0)
		_mi(_sphere(0.22, 0.18), Vector3(cos(ang) * 0.15, fh + 0.2, sin(ang) * 0.15), frond, _mats["fern_light"], "FernTip")
	# Inner tufts (Wave 62: soft sway parents too)
	for i in 6:
		var ang := float(i) * TAU / 6.0
		var tuft := Node3D.new()
		tuft.name = "FernTuft%d" % i
		tuft.position = Vector3(22.0 + cos(ang) * 1.6, 0, 48.0 + sin(ang) * 1.6)
		tuft.set_meta("sway_phase", ang + 0.8)
		tuft.set_meta("sway_amp", 0.035)
		root.add_child(tuft)
		_fern_sway_nodes.append(tuft)
		_mi(_sphere(0.2, 0.24), Vector3(0, 0.14, 0), tuft, _mats["fern"], "FernTuftBall")
	# Resting log + lanterns + crate
	_mi(_cyl(0.22, 0.22, 1.6), Vector3(20.2, 0.22, 46.4), root, _mats["wood"], "FernLog")
	_add_crate(Vector3(24.0, 0, 49.5))
	_add_lantern_post(Vector3(18.5, 0, 45.0))
	_add_lantern_post(Vector3(25.5, 0, 50.5))
	_add_lantern_post(Vector3(12.0, 0, 28.0))
	_add_lantern_post(Vector3(16.0, 0, 36.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1027
	for i in 10:
		var tt := float(i) / 9.0
		var cx := 9.0 + tt * 12.0
		var cz := 22.0 + tt * 24.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx + side * rng.randf_range(4.5, 7.2), 0, cz)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	_add_chunky_sign(root, Vector3(19.5, 0, 48.0), "Fern Dell", 0.35)
	_place_label3d(root, "Soft fronds, quiet dell", 28, Vector3(22.0, 4.1, 48.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Fern Dell", 52, Vector3(22.0, 3.5, 48.0))



func _build_heather_heath() -> void:
	## West-southwest wilds landmark — purple heather rise (soft travel 8).
	## Distinct from Reed Pool (reeds/water), Mill Bridge (creek), and Birch Rest (pale trunks).
	var root := Node3D.new()
	root.name = "HeatherHeath"
	static_world.add_child(root)
	# Dirt spur WSW from the green
	for i in 14:
		var tt := float(i) / 13.0
		var x := -8.0 + tt * (-40.0)
		var z := 16.0 + tt * 26.0
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "HeatherPath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := -10.0 + tt * (-34.0)
		var z := 18.0 + tt * 22.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "HeatherTrim")
	# Soft heath clearing
	_mi(_cyl(4.2, 4.2, 0.08), Vector3(-48.0, 0.04, 42.0), root, _mats["grass_dark"], "HeatherClearing")
	_mi(_cyl(2.4, 2.4, 0.06), Vector3(-48.0, 0.08, 42.0), root, _mats["heather"], "HeatherClearingInner")
	# Ring of heather tufts (chunky purple mounds)
	# Wave 63: each tuft is a sway parent so soft heather sway reads at Heather Heath
	for i in 10:
		var ang := float(i) * TAU / 10.0 + 0.12
		var hx := -48.0 + cos(ang) * 3.5
		var hz := 42.0 + sin(ang) * 3.5
		var tuft := Node3D.new()
		tuft.name = "HeatherTuft%d" % i
		tuft.position = Vector3(hx, 0, hz)
		tuft.set_meta("sway_phase", ang)
		tuft.set_meta("sway_amp", 0.038 + float(i % 3) * 0.008)
		root.add_child(tuft)
		_heather_sway_nodes.append(tuft)
		_mi(_sphere(0.32, 0.38), Vector3(0, 0.16, 0), tuft, _mats["heather"], "HeatherBall")
		_mi(_sphere(0.18, 0.22), Vector3(cos(ang) * 0.2, 0.28, sin(ang) * 0.2), tuft, _mats["heather"], "HeatherTip")
	# Inner tufts + resting stone + benches + lanterns (Wave 63: soft sway parents too)
	for i in 5:
		var ang := float(i) * TAU / 5.0
		var inner := Node3D.new()
		inner.name = "HeatherInner%d" % i
		inner.position = Vector3(-48.0 + cos(ang) * 1.5, 0, 42.0 + sin(ang) * 1.5)
		inner.set_meta("sway_phase", ang + 0.7)
		inner.set_meta("sway_amp", 0.032)
		root.add_child(inner)
		_heather_sway_nodes.append(inner)
		_mi(_sphere(0.22, 0.26), Vector3(0, 0.14, 0), inner, _mats["heather"], "HeatherInnerBall")
	_mi(_cyl(0.55, 0.65, 0.45), Vector3(-48.0, 0.28, 42.0), root, _mats["stone"], "HeatherStone")
	_mi(_sphere(0.2, 0.22), Vector3(-48.0, 0.58, 42.0), root, _mats["heather"], "StoneHeather")
	_add_bench(Vector3(-45.5, 0, 40.2), -0.4)
	_add_bench(Vector3(-50.5, 0, 44.0), 0.5)
	_add_crate(Vector3(-45.0, 0, 44.5))
	_add_lantern_post(Vector3(-44.0, 0, 38.5))
	_add_lantern_post(Vector3(-52.0, 0, 45.5))
	_add_lantern_post(Vector3(-28.0, 0, 28.0))
	_add_lantern_post(Vector3(-18.0, 0, 22.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1028
	for i in 10:
		var tt := float(i) / 9.0
		var cx := -10.0 + tt * (-34.0)
		var cz := 18.0 + tt * 22.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx + side * rng.randf_range(4.5, 7.2), 0, cz)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	_add_chunky_sign(root, Vector3(-45.5, 0, 42.0), "Heather Heath", 0.35)
	_place_label3d(root, "Purple heather, quiet rise", 28, Vector3(-48.0, 4.1, 42.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Heather Heath", 52, Vector3(-48.0, 3.5, 42.0))


func _build_thistle_rise() -> void:
	## East-southeast wilds landmark — spiky purple thistle rise (soft travel 9).
	## Distinct from Heather Heath (soft purple mounds WSW), Fern Dell (fern hollow SSE), Quiet Cross (wooden cross E).
	var root := Node3D.new()
	root.name = "ThistleRise"
	static_world.add_child(root)
	# Dirt spur ESE from the green
	for i in 14:
		var tt := float(i) / 13.0
		var x := 8.0 + tt * 40.0
		var z := 16.0 + tt * 26.0
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "ThistlePath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := 10.0 + tt * 34.0
		var z := 18.0 + tt * 22.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "ThistleTrim")
	# Soft thistle clearing
	_mi(_cyl(4.2, 4.2, 0.08), Vector3(48.0, 0.04, 42.0), root, _mats["grass_dark"], "ThistleClearing")
	_mi(_cyl(2.4, 2.4, 0.06), Vector3(48.0, 0.08, 42.0), root, _mats["thistle"], "ThistleClearingInner")
	# Ring of spiky thistle clumps (chunky stems + purple blooms — not soft heather mounds)
	# Wave 58: each clump is a sway parent so soft thistle sway reads at Thistle Rise
	for i in 10:
		var ang := float(i) * TAU / 10.0 + 0.18
		var hx := 48.0 + cos(ang) * 3.5
		var hz := 42.0 + sin(ang) * 3.5
		var clump := Node3D.new()
		clump.name = "ThistleClump%d" % i
		clump.position = Vector3(hx, 0, hz)
		clump.set_meta("sway_phase", ang)
		clump.set_meta("sway_amp", 0.05 + float(i % 3) * 0.012)
		root.add_child(clump)
		_thistle_sway_nodes.append(clump)
		_mi(_cyl(0.08, 0.1, 0.55), Vector3(0, 0.28, 0), clump, _mats["thistle_leaf"], "ThistleStem")
		_mi(_sphere(0.22, 0.28), Vector3(0, 0.62, 0), clump, _mats["thistle_bloom"], "ThistleBloom")
		_mi(_sphere(0.12, 0.18), Vector3(cos(ang) * 0.15, 0.72, sin(ang) * 0.15), clump, _mats["thistle"], "ThistleSpike")
	# Inner thistles + resting stone + benches + lanterns
	for i in 5:
		var ang := float(i) * TAU / 5.0
		var ix := 48.0 + cos(ang) * 1.5
		var iz := 42.0 + sin(ang) * 1.5
		var iclump := Node3D.new()
		iclump.name = "ThistleInner%d" % i
		iclump.position = Vector3(ix, 0, iz)
		iclump.set_meta("sway_phase", ang + 1.2)
		iclump.set_meta("sway_amp", 0.04)
		root.add_child(iclump)
		_thistle_sway_nodes.append(iclump)
		_mi(_cyl(0.07, 0.09, 0.45), Vector3(0, 0.24, 0), iclump, _mats["thistle_leaf"], "ThistleInnerStem")
		_mi(_sphere(0.16, 0.2), Vector3(0, 0.52, 0), iclump, _mats["thistle_bloom"], "ThistleInnerBloom")
	_mi(_cyl(0.55, 0.65, 0.45), Vector3(48.0, 0.28, 42.0), root, _mats["stone"], "ThistleStone")
	_mi(_sphere(0.18, 0.2), Vector3(48.0, 0.58, 42.0), root, _mats["thistle_bloom"], "StoneThistle")
	_add_bench(Vector3(50.5, 0, 40.2), 0.4)
	_add_bench(Vector3(45.5, 0, 44.0), -0.5)
	_add_crate(Vector3(51.0, 0, 44.5))
	_add_lantern_post(Vector3(52.0, 0, 38.5))
	_add_lantern_post(Vector3(44.0, 0, 45.5))
	_add_lantern_post(Vector3(28.0, 0, 28.0))
	_add_lantern_post(Vector3(18.0, 0, 22.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1029
	for i in 10:
		var tt := float(i) / 9.0
		var cx := 10.0 + tt * 34.0
		var cz := 18.0 + tt * 22.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx + side * rng.randf_range(4.5, 7.2), 0, cz)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	_add_chunky_sign(root, Vector3(50.5, 0, 42.0), "Thistle Rise", -0.35)
	_place_label3d(root, "Spiky thistles, quiet rise", 28, Vector3(48.0, 4.1, 42.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Thistle Rise", 52, Vector3(48.0, 3.5, 42.0))





func _build_maple_copse() -> void:
	## Northwest wilds landmark — warm maple stand with drifting autumn color (soft travel 0).
	## Distinct from Birch Rest (pale trunks SW), Willow Bend (weeping NW brook), Pine Ridge (dark pines N), Heather Heath (purple WSW).
	var root := Node3D.new()
	root.name = "MapleCopse"
	static_world.add_child(root)
	# Dirt spur NW from the green toward the maple stand
	for i in 14:
		var tt := float(i) / 13.0
		var x := -10.0 + tt * -38.0
		var z := -14.0 + tt * -34.0
		_mi(_box(Vector3(2.9, 0.04, 2.6)), Vector3(x, 0.025, z), root, _mats["dirt"], "MaplePath")
	for i in 7:
		var tt := float(i) / 6.0
		var x := -12.0 + tt * -32.0
		var z := -16.0 + tt * -28.0
		_mi(_box(Vector3(3.4, 0.02, 0.32)), Vector3(x, 0.03, z), root, _mats["dirt_trim"], "MapleTrim")
	# Soft maple clearing
	_mi(_cyl(4.2, 4.2, 0.08), Vector3(-48.0, 0.04, -48.0), root, _mats["grass_dark"], "MapleClearing")
	_mi(_cyl(2.4, 2.4, 0.06), Vector3(-48.0, 0.08, -48.0), root, _mats["maple_leaf"], "MapleClearingInner")
	# Ring of chunky maple trunks + broad autumn canopies
	for i in 8:
		var ang := float(i) * TAU / 8.0 + 0.12
		var mx := -48.0 + cos(ang) * 3.6
		var mz := -48.0 + sin(ang) * 3.6
		_mi(_cyl(0.22, 0.28, 1.7), Vector3(mx, 0.9, mz), root, _mats["maple"], "MapleTrunk%d" % i)
		var leaf_mat: Material
		if i % 3 == 0:
			leaf_mat = _mats["maple_leaf"]
		elif i % 3 == 1:
			leaf_mat = _mats["maple_leaf_gold"]
		else:
			leaf_mat = _mats["maple_leaf_green"]
		_mi(_sphere(1.05, 1.35), Vector3(mx, 2.35, mz), root, leaf_mat, "MapleCanopy%d" % i)
		_mi(_sphere(0.55, 0.75), Vector3(mx + cos(ang) * 0.35, 2.7, mz + sin(ang) * 0.35), root, leaf_mat, "MapleCanopyTip%d" % i)
	# Inner resting stone + fallen maple leaf tufts + benches + lanterns
	_mi(_cyl(0.55, 0.65, 0.4), Vector3(-48.0, 0.25, -48.0), root, _mats["stone"], "MapleStone")
	_mi(_sphere(0.22, 0.18), Vector3(-48.0, 0.55, -48.0), root, _mats["maple_leaf_gold"], "StoneLeaf")
	for i in 6:
		var ang := float(i) * TAU / 6.0
		var lx := -48.0 + cos(ang) * 1.6
		var lz := -48.0 + sin(ang) * 1.6
		_mi(_sphere(0.18, 0.08), Vector3(lx, 0.12, lz), root, _mats["maple_leaf"] if i % 2 == 0 else _mats["maple_leaf_gold"], "FallenLeaf%d" % i)
	_add_bench(Vector3(-45.5, 0, -50.0), -0.45)
	_add_bench(Vector3(-50.5, 0, -46.0), 0.55)
	_add_crate(Vector3(-45.0, 0, -45.5))
	_add_lantern_post(Vector3(-44.0, 0, -52.0))
	_add_lantern_post(Vector3(-52.0, 0, -44.0))
	_add_lantern_post(Vector3(-30.0, 0, -30.0))
	_add_lantern_post(Vector3(-20.0, 0, -22.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1030
	for i in 10:
		var tt := float(i) / 9.0
		var cx := -12.0 + tt * -32.0
		var cz := -16.0 + tt * -28.0
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(cx + side * rng.randf_range(4.5, 7.2), 0, cz)
		if i % 3 == 0:
			_add_rock_cluster(p, rng)
		elif i % 3 == 1:
			_add_bush(p, rng)
		else:
			_add_tree(p, 0)
	_add_chunky_sign(root, Vector3(-45.5, 0, -48.0), "Maple Copse", 0.4)
	_place_label3d(root, "Warm maples, soft wind", 28, Vector3(-48.0, 4.1, -48.0), 6, Color(1, 1, 1, 0.75))
	_place_label3d(root, "Maple Copse", 52, Vector3(-48.0, 3.5, -48.0))


func _setup_wind_leaves() -> void:
	## Wave 30/75: soft wind-blown leaf flakes that follow the player outdoors — Wave 75 soft wind leaf particles polish (RuneScape-chunky, wholesome).
	_wind_leaves = CPUParticles3D.new()
	_wind_leaves.name = "WindLeaves"
	_wind_leaves.emitting = true
	_wind_leaves.amount = 28
	_wind_leaves.lifetime = 5.8
	_wind_leaves.preprocess = 2.6
	_wind_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_wind_leaves.emission_box_extents = Vector3(11.5, 2.8, 11.5)
	_wind_leaves.direction = Vector3(0.58, -0.14, 0.28)
	_wind_leaves.spread = 46.0
	_wind_leaves.initial_velocity_min = 0.32
	_wind_leaves.initial_velocity_max = 1.15
	_wind_leaves.gravity = Vector3(0, -0.38, 0)
	_wind_leaves.angular_velocity_min = -48.0
	_wind_leaves.angular_velocity_max = 48.0
	_wind_leaves.scale_amount_min = 0.32
	_wind_leaves.scale_amount_max = 0.92
	var lm := BoxMesh.new()
	lm.size = Vector3(0.24, 0.035, 0.15)
	_wind_leaves.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.80, 0.44, 0.18, 0.74)
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wind_leaves.material_override = lmat
	var wramp := Gradient.new()
	wramp.colors = PackedColorArray([
		Color(0.85, 0.55, 0.22, 0.0),
		Color(0.80, 0.44, 0.18, 0.82),
		Color(0.62, 0.32, 0.12, 0.0),
	])
	_wind_leaves.color_ramp = wramp
	_wind_leaves.position = Vector3(0, 2.4, 0)
	add_child(_wind_leaves)
	HeadlessGuard.guard_particles(_wind_leaves)





func _setup_maple_leaves() -> void:
	## Wave 56: denser soft autumn leaf fall fixed at Maple Copse (player-visible feel).
	_maple_leaves = CPUParticles3D.new()
	_maple_leaves.name = "MapleCopseLeaves"
	_maple_leaves.emitting = true
	_maple_leaves.amount = 56
	_maple_leaves.lifetime = 5.8
	_maple_leaves.preprocess = 2.8
	_maple_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_maple_leaves.emission_box_extents = Vector3(9.5, 3.2, 9.5)
	_maple_leaves.direction = Vector3(0.35, -0.55, 0.18)
	_maple_leaves.spread = 48.0
	_maple_leaves.initial_velocity_min = 0.25
	_maple_leaves.initial_velocity_max = 0.95
	_maple_leaves.gravity = Vector3(0, -0.55, 0)
	_maple_leaves.angular_velocity_min = -55.0
	_maple_leaves.angular_velocity_max = 55.0
	_maple_leaves.scale_amount_min = 0.4
	_maple_leaves.scale_amount_max = 1.0
	var lm := BoxMesh.new()
	lm.size = Vector3(0.26, 0.035, 0.16)
	_maple_leaves.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.82, 0.38, 0.16, 0.78)
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_maple_leaves.material_override = lmat
	_maple_leaves.position = Vector3(-48.0, 3.2, -48.0)
	add_child(_maple_leaves)
	HeadlessGuard.guard_particles(_maple_leaves)


func _setup_garden_fireflies() -> void:
	## Wave 53: denser gold-green fireflies fixed near Prayer Garden at dusk (player-visible feel).
	_garden_fireflies = CPUParticles3D.new()
	_garden_fireflies.name = "PrayerGardenFireflies"
	_garden_fireflies.emitting = false
	_garden_fireflies.amount = 52
	_garden_fireflies.lifetime = 4.2
	_garden_fireflies.preprocess = 1.4
	_garden_fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_garden_fireflies.emission_box_extents = Vector3(6.5, 1.6, 6.5)
	_garden_fireflies.direction = Vector3(0, 0.4, 0)
	_garden_fireflies.spread = 155.0
	_garden_fireflies.initial_velocity_min = 0.06
	_garden_fireflies.initial_velocity_max = 0.38
	_garden_fireflies.gravity = Vector3(0, 0.012, 0)
	_garden_fireflies.angular_velocity_min = -18.0
	_garden_fireflies.angular_velocity_max = 18.0
	_garden_fireflies.scale_amount_min = 0.5
	_garden_fireflies.scale_amount_max = 1.15
	var fm := SphereMesh.new()
	fm.radius = 0.04
	fm.height = 0.08
	_garden_fireflies.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.albedo_color = Color(0.94, 0.96, 0.48, 0.82)
	fmat.emission_enabled = true
	fmat.emission = Color(0.88, 0.95, 0.38)
	fmat.emission_energy_multiplier = 1.65
	_garden_fireflies.material_override = fmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.9, 0.95, 0.4, 0.0),
		Color(1.0, 0.98, 0.55, 0.9),
		Color(0.85, 0.9, 0.35, 0.0),
	])
	_garden_fireflies.color_ramp = ramp
	# Prayer Garden landmark at (30, 0, 18)
	_garden_fireflies.position = Vector3(30, 1.55, 18)
	add_child(_garden_fireflies)
	HeadlessGuard.guard_particles(_garden_fireflies)




func _setup_birch_fireflies() -> void:
	## Wave 66/77: soft birch-rest firefly denser wink at dusk — warm gold-green motes among pale trunks (RuneScape-chunky, wholesome).
	_birch_fireflies = CPUParticles3D.new()
	_birch_fireflies.name = "BirchRestFireflies"
	_birch_fireflies.emitting = false
	_birch_fireflies.amount = 58  # Wave 77: denser birch-rest firefly wink
	_birch_fireflies.lifetime = 3.9
	_birch_fireflies.preprocess = 1.3
	_birch_fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_birch_fireflies.emission_box_extents = Vector3(5.6, 1.7, 5.6)
	_birch_fireflies.direction = Vector3(0, 0.34, 0)
	_birch_fireflies.spread = 155.0
	_birch_fireflies.initial_velocity_min = 0.04
	_birch_fireflies.initial_velocity_max = 0.38
	_birch_fireflies.gravity = Vector3(0, 0.012, 0)
	_birch_fireflies.angular_velocity_min = -22.0
	_birch_fireflies.angular_velocity_max = 22.0
	_birch_fireflies.scale_amount_min = 0.38
	_birch_fireflies.scale_amount_max = 1.08
	var fm := SphereMesh.new()
	fm.radius = 0.036
	fm.height = 0.072
	_birch_fireflies.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.albedo_color = Color(0.96, 0.94, 0.55, 0.82)
	fmat.emission_enabled = true
	fmat.emission = Color(0.92, 0.96, 0.42)
	fmat.emission_energy_multiplier = 1.85  # Wave 77: denser wink glow
	_birch_fireflies.material_override = fmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.9, 0.95, 0.4, 0.0),
		Color(1.0, 0.98, 0.62, 0.92),
		Color(0.95, 0.98, 0.55, 0.55),
		Color(0.88, 0.92, 0.38, 0.0),
	])
	_birch_fireflies.color_ramp = ramp
	# Birch Rest landmark at (-42, 0, -20)
	_birch_fireflies.position = Vector3(-42.0, 1.5, -20.0)
	add_child(_birch_fireflies)
	HeadlessGuard.guard_particles(_birch_fireflies)

func _setup_reed_pool_gleam() -> void:
	## Wave 67: soft Reed Pool ripple gleam at dusk — cool mint-silver rings on the quiet south pool (RuneScape-chunky, wholesome).
	_reed_pool_gleam = CPUParticles3D.new()
	_reed_pool_gleam.name = "ReedPoolRippleGleam"
	_reed_pool_gleam.emitting = false
	_reed_pool_gleam.amount = 10
	_reed_pool_gleam.lifetime = 2.4
	_reed_pool_gleam.preprocess = 0.6
	_reed_pool_gleam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_reed_pool_gleam.emission_sphere_radius = 1.6
	_reed_pool_gleam.direction = Vector3(0, 1, 0)
	_reed_pool_gleam.spread = 8.0
	_reed_pool_gleam.initial_velocity_min = 0.0
	_reed_pool_gleam.initial_velocity_max = 0.03
	_reed_pool_gleam.gravity = Vector3(0, 0, 0)
	_reed_pool_gleam.scale_amount_min = 0.45
	_reed_pool_gleam.scale_amount_max = 1.8
	var ring := TorusMesh.new()
	ring.inner_radius = 0.08
	ring.outer_radius = 0.22
	ring.rings = 8
	ring.ring_segments = 12
	_reed_pool_gleam.mesh = ring
	var rmat := StandardMaterial3D.new()
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.albedo_color = Color(0.72, 0.92, 0.95, 0.42)
	rmat.emission_enabled = true
	rmat.emission = Color(0.55, 0.85, 0.9)
	rmat.emission_energy_multiplier = 0.55
	_reed_pool_gleam.material_override = rmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.75, 0.95, 0.98, 0.0),
		Color(0.7, 0.9, 0.95, 0.45),
		Color(0.65, 0.85, 0.92, 0.0),
	])
	_reed_pool_gleam.color_ramp = ramp
	_reed_pool_gleam.position = Vector3(-20.0, 0.06, 48.0)
	add_child(_reed_pool_gleam)
	HeadlessGuard.guard_particles(_reed_pool_gleam)


func _setup_willow_leaves() -> void:
	## Wave 68: soft Willow Bend willow-leaf drift at dusk — pale green leaves drift over the quiet NW brook (RuneScape-chunky, wholesome).
	_willow_leaves = CPUParticles3D.new()
	_willow_leaves.name = "WillowBendLeafDrift"
	_willow_leaves.emitting = false
	_willow_leaves.amount = 42
	_willow_leaves.lifetime = 5.2
	_willow_leaves.preprocess = 1.6
	_willow_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_willow_leaves.emission_box_extents = Vector3(7.5, 2.8, 7.5)
	_willow_leaves.direction = Vector3(0.22, -0.45, 0.12)
	_willow_leaves.spread = 42.0
	_willow_leaves.initial_velocity_min = 0.18
	_willow_leaves.initial_velocity_max = 0.72
	_willow_leaves.gravity = Vector3(0, -0.42, 0)
	_willow_leaves.angular_velocity_min = -40.0
	_willow_leaves.angular_velocity_max = 40.0
	_willow_leaves.scale_amount_min = 0.35
	_willow_leaves.scale_amount_max = 0.9
	var lm := BoxMesh.new()
	lm.size = Vector3(0.22, 0.028, 0.10)
	_willow_leaves.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.55, 0.72, 0.42, 0.78)
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_willow_leaves.material_override = lmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.6, 0.78, 0.45, 0.0),
		Color(0.55, 0.72, 0.42, 0.82),
		Color(0.5, 0.65, 0.38, 0.0),
	])
	_willow_leaves.color_ramp = ramp
	# Willow Bend landmark at (-38, 0, -34)
	_willow_leaves.position = Vector3(-38.0, 3.0, -34.0)
	add_child(_willow_leaves)
	HeadlessGuard.guard_particles(_willow_leaves)





func _setup_fern_fronds() -> void:
	## Wave 69: soft Fern Dell fern-frond drift at dusk — pale mint fronds drift over the SSE hollow (RuneScape-chunky, wholesome).
	_fern_fronds = CPUParticles3D.new()
	_fern_fronds.name = "FernDellFrondDrift"
	_fern_fronds.emitting = false
	_fern_fronds.amount = 36
	_fern_fronds.lifetime = 4.8
	_fern_fronds.preprocess = 1.4
	_fern_fronds.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_fern_fronds.emission_box_extents = Vector3(6.5, 2.4, 6.5)
	_fern_fronds.direction = Vector3(0.18, -0.38, 0.10)
	_fern_fronds.spread = 48.0
	_fern_fronds.initial_velocity_min = 0.14
	_fern_fronds.initial_velocity_max = 0.62
	_fern_fronds.gravity = Vector3(0, -0.36, 0)
	_fern_fronds.angular_velocity_min = -35.0
	_fern_fronds.angular_velocity_max = 35.0
	_fern_fronds.scale_amount_min = 0.32
	_fern_fronds.scale_amount_max = 0.85
	var fm := BoxMesh.new()
	fm.size = Vector3(0.20, 0.022, 0.08)
	_fern_fronds.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.48, 0.72, 0.46, 0.76)
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fern_fronds.material_override = fmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.52, 0.76, 0.48, 0.0),
		Color(0.48, 0.72, 0.46, 0.80),
		Color(0.42, 0.64, 0.40, 0.0),
	])
	_fern_fronds.color_ramp = ramp
	# Fern Dell landmark at (22, 0, 48)
	_fern_fronds.position = Vector3(22.0, 2.8, 48.0)
	add_child(_fern_fronds)
	HeadlessGuard.guard_particles(_fern_fronds)


func _setup_heather_blooms() -> void:
	## Wave 70: soft Heather Heath heather-bloom drift at dusk — pale purple blooms drift over the WSW rise (RuneScape-chunky, wholesome).
	_heather_blooms = CPUParticles3D.new()
	_heather_blooms.name = "HeatherHeathBloomDrift"
	_heather_blooms.emitting = false
	_heather_blooms.amount = 34
	_heather_blooms.lifetime = 4.6
	_heather_blooms.preprocess = 1.3
	_heather_blooms.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_heather_blooms.emission_box_extents = Vector3(6.2, 2.2, 6.2)
	_heather_blooms.direction = Vector3(0.14, -0.36, 0.12)
	_heather_blooms.spread = 46.0
	_heather_blooms.initial_velocity_min = 0.12
	_heather_blooms.initial_velocity_max = 0.58
	_heather_blooms.gravity = Vector3(0, -0.34, 0)
	_heather_blooms.angular_velocity_min = -32.0
	_heather_blooms.angular_velocity_max = 32.0
	_heather_blooms.scale_amount_min = 0.30
	_heather_blooms.scale_amount_max = 0.82
	var hm := SphereMesh.new()
	hm.radius = 0.045
	hm.height = 0.09
	_heather_blooms.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.62, 0.42, 0.62, 0.78)
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_heather_blooms.material_override = hmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.68, 0.48, 0.68, 0.0),
		Color(0.62, 0.42, 0.62, 0.82),
		Color(0.52, 0.34, 0.52, 0.0),
	])
	_heather_blooms.color_ramp = ramp
	# Heather Heath landmark at (-48, 0, 42)
	_heather_blooms.position = Vector3(-48.0, 2.6, 42.0)
	add_child(_heather_blooms)
	HeadlessGuard.guard_particles(_heather_blooms)

func _setup_thistle_blooms() -> void:
	## Wave 71: soft Thistle Rise thistle-bloom drift at dusk — pale purple thistle tufts drift over the ESE rise (RuneScape-chunky, wholesome).
	_thistle_blooms = CPUParticles3D.new()
	_thistle_blooms.name = "ThistleRiseBloomDrift"
	_thistle_blooms.emitting = false
	_thistle_blooms.amount = 34
	_thistle_blooms.lifetime = 4.6
	_thistle_blooms.preprocess = 1.3
	_thistle_blooms.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_thistle_blooms.emission_box_extents = Vector3(6.2, 2.2, 6.2)
	_thistle_blooms.direction = Vector3(-0.14, -0.36, 0.12)
	_thistle_blooms.spread = 46.0
	_thistle_blooms.initial_velocity_min = 0.12
	_thistle_blooms.initial_velocity_max = 0.58
	_thistle_blooms.gravity = Vector3(0, -0.34, 0)
	_thistle_blooms.angular_velocity_min = -32.0
	_thistle_blooms.angular_velocity_max = 32.0
	_thistle_blooms.scale_amount_min = 0.30
	_thistle_blooms.scale_amount_max = 0.82
	var tm := SphereMesh.new()
	tm.radius = 0.045
	tm.height = 0.09
	_thistle_blooms.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.52, 0.38, 0.68, 0.78)
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_thistle_blooms.material_override = tmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.58, 0.42, 0.72, 0.0),
		Color(0.52, 0.38, 0.68, 0.82),
		Color(0.42, 0.30, 0.58, 0.0),
	])
	_thistle_blooms.color_ramp = ramp
	# Thistle Rise landmark at (48, 0, 42)
	_thistle_blooms.position = Vector3(48.0, 2.6, 42.0)
	add_child(_thistle_blooms)
	HeadlessGuard.guard_particles(_thistle_blooms)

func _setup_maple_dusk_leaves() -> void:
	## Wave 72: soft Maple Copse maple-leaf drift at dusk — warm autumn maple leaves drift over the NW copse (RuneScape-chunky, wholesome).
	_maple_dusk_leaves = CPUParticles3D.new()
	_maple_dusk_leaves.name = "MapleCopseDuskLeafDrift"
	_maple_dusk_leaves.emitting = false
	_maple_dusk_leaves.amount = 38
	_maple_dusk_leaves.lifetime = 5.2
	_maple_dusk_leaves.preprocess = 1.4
	_maple_dusk_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_maple_dusk_leaves.emission_box_extents = Vector3(7.2, 2.6, 7.2)
	_maple_dusk_leaves.direction = Vector3(0.28, -0.42, 0.16)
	_maple_dusk_leaves.spread = 52.0
	_maple_dusk_leaves.initial_velocity_min = 0.14
	_maple_dusk_leaves.initial_velocity_max = 0.72
	_maple_dusk_leaves.gravity = Vector3(0, -0.42, 0)
	_maple_dusk_leaves.angular_velocity_min = -48.0
	_maple_dusk_leaves.angular_velocity_max = 48.0
	_maple_dusk_leaves.scale_amount_min = 0.35
	_maple_dusk_leaves.scale_amount_max = 0.95
	var lm := BoxMesh.new()
	lm.size = Vector3(0.22, 0.03, 0.14)
	_maple_dusk_leaves.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.88, 0.42, 0.18, 0.82)
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_maple_dusk_leaves.material_override = lmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.92, 0.55, 0.22, 0.0),
		Color(0.88, 0.42, 0.18, 0.85),
		Color(0.72, 0.28, 0.12, 0.0),
	])
	_maple_dusk_leaves.color_ramp = ramp
	# Maple Copse landmark at (-48, 0, -48)
	_maple_dusk_leaves.position = Vector3(-48.0, 3.4, -48.0)
	add_child(_maple_dusk_leaves)
	HeadlessGuard.guard_particles(_maple_dusk_leaves)


func _setup_amber_knoll_motes() -> void:
	## Wave 73: soft Amber Knoll amber-glow motes at dusk — warm honey motes drift over the ENE knoll (RuneScape-chunky, wholesome).
	_amber_knoll_motes = CPUParticles3D.new()
	_amber_knoll_motes.name = "AmberKnollGlowMotes"
	_amber_knoll_motes.emitting = false
	_amber_knoll_motes.amount = 28
	_amber_knoll_motes.lifetime = 4.6
	_amber_knoll_motes.preprocess = 1.2
	_amber_knoll_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_amber_knoll_motes.emission_sphere_radius = 4.8
	_amber_knoll_motes.direction = Vector3(0.05, 0.35, 0.02)
	_amber_knoll_motes.spread = 48.0
	_amber_knoll_motes.initial_velocity_min = 0.05
	_amber_knoll_motes.initial_velocity_max = 0.28
	_amber_knoll_motes.gravity = Vector3(0, 0.02, 0)
	_amber_knoll_motes.scale_amount_min = 0.12
	_amber_knoll_motes.scale_amount_max = 0.38
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	_amber_knoll_motes.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.78, 0.38, 0.72)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.28)
	mat.emission_energy_multiplier = 1.4
	_amber_knoll_motes.material_override = mat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(1.0, 0.85, 0.45, 0.0),
		Color(1.0, 0.78, 0.38, 0.85),
		Color(0.95, 0.55, 0.22, 0.0),
	])
	_amber_knoll_motes.color_ramp = ramp
	# Amber Knoll landmark at (48, 0, -22)
	_amber_knoll_motes.position = Vector3(48.0, 2.2, -22.0)
	add_child(_amber_knoll_motes)
	HeadlessGuard.guard_particles(_amber_knoll_motes)



func _setup_cedar_needles() -> void:
	## Wave 74: soft Cedar Hollow cedar-needle drift at dusk — soft green-brown needles drift over the NE hollow (RuneScape-chunky, wholesome).
	_cedar_needles = CPUParticles3D.new()
	_cedar_needles.name = "CedarHollowNeedleDrift"
	_cedar_needles.emitting = false
	_cedar_needles.amount = 40
	_cedar_needles.lifetime = 5.0
	_cedar_needles.preprocess = 1.3
	_cedar_needles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_cedar_needles.emission_box_extents = Vector3(6.8, 2.5, 6.8)
	_cedar_needles.direction = Vector3(0.22, -0.40, 0.12)
	_cedar_needles.spread = 50.0
	_cedar_needles.initial_velocity_min = 0.12
	_cedar_needles.initial_velocity_max = 0.68
	_cedar_needles.gravity = Vector3(0, -0.38, 0)
	_cedar_needles.angular_velocity_min = -55.0
	_cedar_needles.angular_velocity_max = 55.0
	_cedar_needles.scale_amount_min = 0.28
	_cedar_needles.scale_amount_max = 0.85
	var nm := BoxMesh.new()
	nm.size = Vector3(0.06, 0.02, 0.18)
	_cedar_needles.mesh = nm
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.32, 0.48, 0.28, 0.80)
	nmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	nmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cedar_needles.material_override = nmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.42, 0.55, 0.32, 0.0),
		Color(0.32, 0.48, 0.28, 0.85),
		Color(0.28, 0.38, 0.22, 0.0),
	])
	_cedar_needles.color_ramp = ramp
	# Cedar Hollow landmark at (38, 0, -36)
	_cedar_needles.position = Vector3(38.0, 3.2, -36.0)
	add_child(_cedar_needles)
	HeadlessGuard.guard_particles(_cedar_needles)



func _setup_stone_arch_dust() -> void:
	## Wave 75: soft Stone Arch limestone dust motes at dusk — cool pale limestone motes drift through the western gateway (RuneScape-chunky, wholesome).
	_stone_arch_dust = CPUParticles3D.new()
	_stone_arch_dust.name = "StoneArchLimestoneDust"
	_stone_arch_dust.emitting = false
	_stone_arch_dust.amount = 32
	_stone_arch_dust.lifetime = 4.8
	_stone_arch_dust.preprocess = 1.2
	_stone_arch_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_stone_arch_dust.emission_box_extents = Vector3(5.5, 3.2, 4.2)
	_stone_arch_dust.direction = Vector3(0.12, 0.18, 0.08)
	_stone_arch_dust.spread = 55.0
	_stone_arch_dust.initial_velocity_min = 0.04
	_stone_arch_dust.initial_velocity_max = 0.32
	_stone_arch_dust.gravity = Vector3(0, -0.08, 0)
	_stone_arch_dust.angular_velocity_min = -25.0
	_stone_arch_dust.angular_velocity_max = 25.0
	_stone_arch_dust.scale_amount_min = 0.10
	_stone_arch_dust.scale_amount_max = 0.36
	var dm := SphereMesh.new()
	dm.radius = 0.045
	dm.height = 0.09
	_stone_arch_dust.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.82, 0.80, 0.72, 0.70)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.emission_enabled = true
	dmat.emission = Color(0.78, 0.76, 0.68)
	dmat.emission_energy_multiplier = 0.55
	_stone_arch_dust.material_override = dmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.88, 0.86, 0.78, 0.0),
		Color(0.82, 0.80, 0.72, 0.78),
		Color(0.70, 0.68, 0.60, 0.0),
	])
	_stone_arch_dust.color_ramp = ramp
	# Stone Arch landmark at (-48, 0, 8)
	_stone_arch_dust.position = Vector3(-48.0, 2.8, 8.0)
	add_child(_stone_arch_dust)
	HeadlessGuard.guard_particles(_stone_arch_dust)




func _setup_cross_lantern_moths() -> void:
	## Wave 76: soft Quiet Cross lantern moths at dusk — warm cream moths flutter around the knoll lanterns (RuneScape-chunky, wholesome).
	_cross_lantern_moths = CPUParticles3D.new()
	_cross_lantern_moths.name = "QuietCrossLanternMoths"
	_cross_lantern_moths.emitting = false
	_cross_lantern_moths.amount = 18
	_cross_lantern_moths.lifetime = 3.6
	_cross_lantern_moths.preprocess = 1.0
	_cross_lantern_moths.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_cross_lantern_moths.emission_box_extents = Vector3(6.5, 2.8, 5.5)
	_cross_lantern_moths.direction = Vector3(0.05, 0.35, 0.05)
	_cross_lantern_moths.spread = 70.0
	_cross_lantern_moths.initial_velocity_min = 0.08
	_cross_lantern_moths.initial_velocity_max = 0.42
	_cross_lantern_moths.gravity = Vector3(0, 0.02, 0)
	_cross_lantern_moths.angular_velocity_min = -40.0
	_cross_lantern_moths.angular_velocity_max = 40.0
	_cross_lantern_moths.scale_amount_min = 0.22
	_cross_lantern_moths.scale_amount_max = 0.55
	var mm := SphereMesh.new()
	mm.radius = 0.04
	mm.height = 0.08
	_cross_lantern_moths.mesh = mm
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(1.0, 0.92, 0.72, 0.82)
	mmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmat.emission_enabled = true
	mmat.emission = Color(1.0, 0.88, 0.55)
	mmat.emission_energy_multiplier = 0.95
	_cross_lantern_moths.material_override = mmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(1.0, 0.95, 0.78, 0.0),
		Color(1.0, 0.90, 0.62, 0.88),
		Color(0.95, 0.78, 0.45, 0.0),
	])
	_cross_lantern_moths.color_ramp = ramp
	# Quiet Cross landmark at (48, 0, 8) — moths drift near lantern posts + knoll
	_cross_lantern_moths.position = Vector3(48.0, 2.4, 8.0)
	add_child(_cross_lantern_moths)
	HeadlessGuard.guard_particles(_cross_lantern_moths)


func _setup_brook_sparkle() -> void:
	## Wave 54: soft cream-cyan brook sparkle near water (RuneScape-chunky, wholesome).
	_brook_sparkle = CPUParticles3D.new()
	_brook_sparkle.name = "BrookSparkle"
	_brook_sparkle.emitting = false
	_brook_sparkle.amount = 28
	_brook_sparkle.lifetime = 2.4
	_brook_sparkle.preprocess = 0.6
	_brook_sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_brook_sparkle.emission_sphere_radius = 2.8
	_brook_sparkle.direction = Vector3(0, 0.55, 0)
	_brook_sparkle.spread = 140.0
	_brook_sparkle.initial_velocity_min = 0.05
	_brook_sparkle.initial_velocity_max = 0.32
	_brook_sparkle.gravity = Vector3(0, 0.04, 0)
	_brook_sparkle.angular_velocity_min = -25.0
	_brook_sparkle.angular_velocity_max = 25.0
	_brook_sparkle.scale_amount_min = 0.35
	_brook_sparkle.scale_amount_max = 0.85
	var sm := SphereMesh.new()
	sm.radius = 0.028
	sm.height = 0.056
	_brook_sparkle.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.78, 0.94, 0.96, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(0.72, 0.92, 0.95)
	mat.emission_energy_multiplier = 1.35
	_brook_sparkle.material_override = mat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.7, 0.9, 0.95, 0.0),
		Color(0.92, 0.98, 1.0, 0.85),
		Color(0.75, 0.92, 0.94, 0.0),
	])
	_brook_sparkle.color_ramp = ramp
	_brook_sparkle.position = Vector3(0.5, 0.55, -42)
	add_child(_brook_sparkle)
	HeadlessGuard.guard_particles(_brook_sparkle)


func _update_brook_sparkle() -> void:
	## Wave 54: soft sparkle emits near water when outdoors (player-visible feel).
	if _brook_sparkle == null:
		return
	if _inside_hall != "" or player == null or _water_positions.is_empty():
		_brook_sparkle.emitting = false
		_brook_sparkle.visible = false
		return
	var now: float = float(Time.get_ticks_msec()) * 0.001
	if now - _brook_sparkle_check_t < 0.28:
		return
	_brook_sparkle_check_t = now
	var pp: Vector3 = player.global_position
	var best: Vector3 = _water_positions[0]
	var best_d2: float = 1.0e12
	for wp in _water_positions:
		var dx: float = pp.x - wp.x
		var dz: float = pp.z - wp.z
		var d2: float = dx * dx + dz * dz
		if d2 < best_d2:
			best_d2 = d2
			best = wp
	var near: bool = best_d2 < 100.0  # 10^2 — same soft distance as brook murmur
	_brook_sparkle.emitting = near
	_brook_sparkle.visible = near
	if near:
		_brook_sparkle.global_position = Vector3(best.x, 0.55, best.z)



func _setup_dusk_fireflies() -> void:
	## Wave 39: soft gold-green firefly sparkles that gather at dusk outdoors (RuneScape-chunky, wholesome).
	_dusk_fireflies = CPUParticles3D.new()
	_dusk_fireflies.name = "DuskFireflies"
	_dusk_fireflies.emitting = false
	_dusk_fireflies.amount = 26
	_dusk_fireflies.lifetime = 3.8
	_dusk_fireflies.preprocess = 1.2
	_dusk_fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dusk_fireflies.emission_box_extents = Vector3(8.5, 1.8, 8.5)
	_dusk_fireflies.direction = Vector3(0, 0.35, 0)
	_dusk_fireflies.spread = 160.0
	_dusk_fireflies.initial_velocity_min = 0.08
	_dusk_fireflies.initial_velocity_max = 0.42
	_dusk_fireflies.gravity = Vector3(0, 0.015, 0)
	_dusk_fireflies.angular_velocity_min = -20.0
	_dusk_fireflies.angular_velocity_max = 20.0
	_dusk_fireflies.scale_amount_min = 0.45
	_dusk_fireflies.scale_amount_max = 1.05
	var fm := SphereMesh.new()
	fm.radius = 0.035
	fm.height = 0.07
	_dusk_fireflies.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.albedo_color = Color(0.92, 0.95, 0.45, 0.78)
	fmat.emission_enabled = true
	fmat.emission = Color(0.85, 0.92, 0.35)
	fmat.emission_energy_multiplier = 1.4
	_dusk_fireflies.material_override = fmat
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.9, 0.95, 0.4, 0.0),
		Color(1.0, 0.98, 0.55, 0.85),
		Color(0.85, 0.9, 0.35, 0.0),
	])
	_dusk_fireflies.color_ramp = ramp
	_dusk_fireflies.position = Vector3(0, 1.6, 0)
	add_child(_dusk_fireflies)
	HeadlessGuard.guard_particles(_dusk_fireflies)


func _is_dusk_firefly_time() -> bool:
	## Soft dusk through early night — matches HUD Dusk/Night feel without harsh cutovers.
	var phase := _day_phase
	if phase >= 0.62 and phase <= 0.95:
		return true
	if phase <= 0.12:
		return true  # deep night spill
	return false

func _setup_snowdust() -> void:
	## Wave 47: soft snowdust motes in cold Fog outdoors (RuneScape-chunky, wholesome; off indoors).
	_snowdust = CPUParticles3D.new()
	_snowdust.name = "ColdFogSnowdust"
	_snowdust.emitting = false
	_snowdust.amount = 36
	_snowdust.lifetime = 4.2
	_snowdust.preprocess = 1.5
	_snowdust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snowdust.emission_box_extents = Vector3(9.5, 2.2, 9.5)
	_snowdust.direction = Vector3(0.18, -0.35, 0.08)
	_snowdust.spread = 48.0
	_snowdust.initial_velocity_min = 0.15
	_snowdust.initial_velocity_max = 0.55
	_snowdust.gravity = Vector3(0, -0.22, 0)
	_snowdust.angular_velocity_min = -25.0
	_snowdust.angular_velocity_max = 25.0
	_snowdust.scale_amount_min = 0.25
	_snowdust.scale_amount_max = 0.55
	var sm := SphereMesh.new()
	sm.radius = 0.045
	sm.height = 0.09
	_snowdust.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.94, 0.96, 1.0, 0.72)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_snowdust.material_override = smat
	_snowdust.position = Vector3(0, 2.8, 0)
	add_child(_snowdust)
	HeadlessGuard.guard_particles(_snowdust)

func _setup_canopy_drip() -> void:
	## Wave 48: soft canopy drip motes under trees while raining outdoors (RuneScape-chunky, wholesome).
	_canopy_drip = CPUParticles3D.new()
	_canopy_drip.name = "RainCanopyDrip"
	_canopy_drip.emitting = false
	# Wave 69: soft rain-canopy drip polish — denser motes, softer fade (RuneScape-chunky, wholesome)
	_canopy_drip.amount = 44
	_canopy_drip.lifetime = 1.85
	_canopy_drip.preprocess = 0.55
	_canopy_drip.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_canopy_drip.emission_box_extents = Vector3(2.5, 0.18, 2.5)
	_canopy_drip.direction = Vector3(0.02, -1, 0.01)
	_canopy_drip.spread = 10.0
	_canopy_drip.initial_velocity_min = 1.05
	_canopy_drip.initial_velocity_max = 2.2
	_canopy_drip.gravity = Vector3(0, -4.2, 0)
	_canopy_drip.scale_amount_min = 0.16
	_canopy_drip.scale_amount_max = 0.42
	var dm := SphereMesh.new()
	dm.radius = 0.032
	dm.height = 0.064
	_canopy_drip.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.74, 0.86, 0.96, 0.70)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_canopy_drip.material_override = dmat
	var drip_ramp := Gradient.new()
	drip_ramp.colors = PackedColorArray([
		Color(0.7, 0.84, 0.95, 0.0),
		Color(0.78, 0.90, 0.98, 0.78),
		Color(0.68, 0.80, 0.92, 0.0),
	])
	_canopy_drip.color_ramp = drip_ramp
	_canopy_drip.position = Vector3(0, 3.2, 0)
	_canopy_drip.visible = false
	add_child(_canopy_drip)
	HeadlessGuard.guard_particles(_canopy_drip)


func _update_canopy_drip() -> void:
	## Soft drip under the nearest tree canopy while raining outdoors.
	if _canopy_drip == null:
		return
	var raining_out := player != null and _inside_hall == "" and _weather_mode == 2
	if not raining_out or _tree_positions.is_empty():
		_canopy_drip.emitting = false
		_canopy_drip.visible = false
		return
	var pp: Vector3 = player.global_position
	var best: Vector3 = _tree_positions[0]
	var best_d2: float = 1.0e12
	for i in _tree_positions.size():
		# Sample every other tree for cheap proximity (same spirit as leaf rustle)
		if i % 2 != 0 and _tree_positions.size() > 24:
			continue
		var tp: Vector3 = _tree_positions[i]
		var dx: float = pp.x - tp.x
		var dz: float = pp.z - tp.z
		var d2: float = dx * dx + dz * dz
		if d2 < best_d2:
			best_d2 = d2
			best = tp
	if best_d2 > 36.0:  # farther than ~6 paces — no canopy overhead
		_canopy_drip.emitting = false
		_canopy_drip.visible = false
		return
	_canopy_drip.global_position = Vector3(best.x, 3.4, best.z)
	_canopy_drip.emitting = true
	_canopy_drip.visible = true


func _setup_eaves_splash() -> void:
	## Wave 51: soft rain splash on hall outdoor eaves (RuneScape-chunky, wholesome).
	_eaves_splash = CPUParticles3D.new()
	_eaves_splash.name = "RainEavesSplash"
	_eaves_splash.emitting = false
	_eaves_splash.amount = 22
	_eaves_splash.lifetime = 0.55
	_eaves_splash.preprocess = 0.15
	_eaves_splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_eaves_splash.emission_box_extents = Vector3(1.8, 0.08, 0.35)
	_eaves_splash.direction = Vector3(0, -1, 0.15)
	_eaves_splash.spread = 28.0
	_eaves_splash.initial_velocity_min = 0.6
	_eaves_splash.initial_velocity_max = 1.6
	_eaves_splash.gravity = Vector3(0, -6.0, 0)
	_eaves_splash.scale_amount_min = 0.06
	_eaves_splash.scale_amount_max = 0.14
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.07
	_eaves_splash.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.78, 0.86, 0.95, 0.62)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_eaves_splash.material_override = smat
	_eaves_splash.position = Vector3(0, 4.0, 0)
	_eaves_splash.visible = false
	add_child(_eaves_splash)
	HeadlessGuard.guard_particles(_eaves_splash)


func _update_eaves_splash() -> void:
	## Soft splash off the nearest hall eave while raining outdoors.
	if _eaves_splash == null:
		return
	var raining_out := player != null and _inside_hall == "" and _weather_mode == 2
	if not raining_out or _hall_eaves.is_empty():
		_eaves_splash.emitting = false
		_eaves_splash.visible = false
		return
	var pp: Vector3 = player.global_position
	var best: Vector3 = _hall_eaves[0]
	var best_d2: float = 1.0e12
	for ep in _hall_eaves:
		var dx: float = pp.x - ep.x
		var dz: float = pp.z - ep.z
		var d2: float = dx * dx + dz * dz
		if d2 < best_d2:
			best_d2 = d2
			best = ep
	if best_d2 > 100.0:  # farther than ~10 paces from any hall eave
		_eaves_splash.emitting = false
		_eaves_splash.visible = false
		return
	_eaves_splash.global_position = best
	_eaves_splash.emitting = true
	_eaves_splash.visible = true


func _play_fountain_restore_fx() -> void:
	## Soft defeat feel: brief cream/gold sparkles at the village fountain (RuneScape-chunky, wholesome).
	if HeadlessGuard.is_headless():
		return
	var anchor: Node3D = _fountain_root
	if anchor == null or not is_instance_valid(anchor):
		anchor = static_world.get_node_or_null("Fountain")
	if anchor == null:
		return
	var fx := CPUParticles3D.new()
	fx.name = "FountainRestoreFx"
	fx.position = Vector3(0, 1.6, 0)
	fx.emitting = true
	fx.one_shot = true
	fx.explosiveness = 0.85
	fx.amount = 28
	fx.lifetime = 1.15
	fx.direction = Vector3(0, 1, 0)
	fx.spread = 55.0
	fx.initial_velocity_min = 1.2
	fx.initial_velocity_max = 2.8
	fx.gravity = Vector3(0, -1.5, 0)
	fx.scale_amount_min = 0.12
	fx.scale_amount_max = 0.28
	fx.color = Color(1.0, 0.92, 0.65, 0.9)
	HeadlessGuard.guard_particles(fx)
	anchor.add_child(fx)
	# Soft rising mist disc (second layer) — Wave 55: soft-defeat mist linger (longer cream mist)
	var mist := CPUParticles3D.new()
	mist.name = "FountainRestoreMist"
	mist.position = Vector3(0, 0.5, 0)
	mist.emitting = true
	mist.one_shot = true
	mist.explosiveness = 0.35  # Wave 55: less bursty so mist lingers
	mist.amount = 22
	mist.lifetime = 3.2  # Wave 55: linger longer after soft defeat
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 1.6
	mist.direction = Vector3(0, 1, 0)
	mist.spread = 36.0
	mist.initial_velocity_min = 0.22
	mist.initial_velocity_max = 0.75
	mist.gravity = Vector3(0, 0.08, 0)
	mist.scale_amount_min = 0.22
	mist.scale_amount_max = 0.55
	mist.color = Color(0.85, 0.95, 1.0, 0.58)
	HeadlessGuard.guard_particles(mist)
	anchor.add_child(mist)
	# Wave 42: clearer soft-defeat fountain glow — warm cream OmniLight pulse (RuneScape-chunky, wholesome)
	var glow := OmniLight3D.new()
	glow.name = "FountainRestoreGlow"
	glow.position = Vector3(0, 1.4, 0)
	glow.light_color = Color(1.0, 0.92, 0.7)
	glow.light_energy = 2.4
	glow.omni_range = 6.5
	glow.shadow_enabled = false
	anchor.add_child(glow)
	var tw := create_tween()
	tw.tween_property(glow, "light_energy", 0.15, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Wave 55: hold mist/glow a bit longer so soft-defeat mist lingers (RuneScape-chunky, wholesome)
	get_tree().create_timer(4.0).timeout.connect(func():
		if is_instance_valid(fx):
			fx.queue_free()
		if is_instance_valid(mist):
			mist.queue_free()
		if is_instance_valid(glow):
			glow.queue_free()
	)



func play_wave60_festival_confetti() -> void:
	## Wave 60: soft festival confetti on load once per save (RuneScape-chunky, wholesome — no cheesy combat labels).
	if HeadlessGuard.is_headless():
		return
	var anchor: Node3D = player
	if anchor == null or not is_instance_valid(anchor):
		return
	var fx := CPUParticles3D.new()
	fx.name = "Wave60FestivalConfetti"
	fx.position = Vector3(0, 2.2, 0)
	fx.emitting = true
	fx.one_shot = true
	fx.explosiveness = 0.78
	fx.amount = 42
	fx.lifetime = 1.65
	fx.direction = Vector3(0, -1, 0)
	fx.spread = 85.0
	fx.initial_velocity_min = 0.55
	fx.initial_velocity_max = 1.85
	fx.gravity = Vector3(0, -2.2, 0)
	fx.scale_amount_min = 0.10
	fx.scale_amount_max = 0.26
	fx.color = Color(1.0, 0.78, 0.45, 0.92)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(1.0, 0.86, 0.55, 0.95),
		Color(0.95, 0.55, 0.62, 0.9),
		Color(0.55, 0.78, 0.95, 0.85),
		Color(0.75, 0.92, 0.55, 0.7),
	])
	fx.color_ramp = ramp
	HeadlessGuard.guard_particles(fx)
	anchor.add_child(fx)
	var glow := OmniLight3D.new()
	glow.name = "Wave60FestivalGlow"
	glow.position = Vector3(0, 1.8, 0)
	glow.light_color = Color(1.0, 0.88, 0.6)
	glow.light_energy = 1.6
	glow.omni_range = 5.0
	glow.shadow_enabled = false
	anchor.add_child(glow)
	var tw := create_tween()
	tw.tween_property(glow, "light_energy", 0.05, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(2.2).timeout.connect(func():
		if is_instance_valid(fx):
			fx.queue_free()
		if is_instance_valid(glow):
			glow.queue_free()
	)

func play_festival_decade_sparkle() -> void:
	## Wave 50: soft festival sparkle when year % hits a multiple of 10 (RuneScape-chunky, wholesome).
	if HeadlessGuard.is_headless():
		return
	var anchor: Node3D = player
	if anchor == null or not is_instance_valid(anchor):
		return
	var fx := CPUParticles3D.new()
	fx.name = "FestivalDecadeSparkle"
	fx.position = Vector3(0, 1.5, 0)
	fx.emitting = true
	fx.one_shot = true
	fx.explosiveness = 0.88
	fx.amount = 32
	fx.lifetime = 1.25
	fx.direction = Vector3(0, 1, 0)
	fx.spread = 70.0
	fx.initial_velocity_min = 1.2
	fx.initial_velocity_max = 2.8
	fx.gravity = Vector3(0, -1.0, 0)
	fx.scale_amount_min = 0.12
	fx.scale_amount_max = 0.32
	fx.color = Color(1.0, 0.92, 0.55, 0.95)
	HeadlessGuard.guard_particles(fx)
	anchor.add_child(fx)
	var glow := OmniLight3D.new()
	glow.name = "FestivalDecadeGlow"
	glow.position = Vector3(0, 1.6, 0)
	glow.light_color = Color(1.0, 0.9, 0.55)
	glow.light_energy = 2.0
	glow.omni_range = 5.5
	glow.shadow_enabled = false
	anchor.add_child(glow)
	var tw := create_tween()
	tw.tween_property(glow, "light_energy", 0.1, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(fx):
			fx.queue_free()
		if is_instance_valid(glow):
			glow.queue_free()
	)

func _play_quest_victory_sparkle(_quest_id: String = "") -> void:
	## Wave 29/46/66 + v1.84: soft cream/gold victory sparkle + mini fireworks over the apprentice.
	if HeadlessGuard.is_headless():
		return
	var anchor: Node3D = player
	if anchor == null or not is_instance_valid(anchor):
		return
	var fx := CPUParticles3D.new()
	fx.name = "QuestVictorySparkle"
	fx.position = Vector3(0, 1.4, 0)
	fx.emitting = true
	fx.one_shot = true
	fx.explosiveness = 0.84
	fx.amount = 36  # Wave 66: softer richer victory sparkle polish
	fx.lifetime = 1.25
	fx.direction = Vector3(0, 1, 0)
	fx.spread = 66.0
	fx.initial_velocity_min = 1.1
	fx.initial_velocity_max = 2.7
	fx.gravity = Vector3(0, -1.1, 0)
	fx.scale_amount_min = 0.12
	fx.scale_amount_max = 0.32
	fx.color = Color(1.0, 0.96, 0.62, 0.95)
	HeadlessGuard.guard_particles(fx)
	anchor.add_child(fx)
	var ring := CPUParticles3D.new()
	ring.name = "QuestVictoryRing"
	ring.position = Vector3(0, 0.35, 0)
	ring.emitting = true
	ring.one_shot = true
	ring.explosiveness = 0.92
	ring.amount = 16
	ring.lifetime = 1.0
	ring.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	ring.emission_ring_radius = 0.78
	ring.emission_ring_inner_radius = 0.48
	ring.emission_ring_height = 0.05
	ring.direction = Vector3(0, 1, 0)
	ring.spread = 22.0
	ring.initial_velocity_min = 0.35
	ring.initial_velocity_max = 0.9
	ring.gravity = Vector3(0, 0.45, 0)
	ring.scale_amount_min = 0.13
	ring.scale_amount_max = 0.3
	ring.color = Color(0.97, 0.90, 0.52, 0.75)
	HeadlessGuard.guard_particles(ring)
	anchor.add_child(ring)
	# Wave 46: soft warm mastery light pulse (no cheesy combat labels)
	var glow := OmniLight3D.new()
	glow.name = "QuestVictoryGlow"
	glow.position = Vector3(0, 1.5, 0)
	glow.light_color = Color(1.0, 0.94, 0.68)
	glow.light_energy = 2.35  # Wave 66: softer warmer victory glow
	glow.omni_range = 5.9
	glow.shadow_enabled = false
	anchor.add_child(glow)
	var tw := create_tween()
	tw.tween_property(glow, "light_energy", 0.1, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(1.9).timeout.connect(func():
		if is_instance_valid(fx):
			fx.queue_free()
		if is_instance_valid(ring):
			ring.queue_free()
		if is_instance_valid(glow):
			glow.queue_free()
	)
	# v1.84: mini fireworks bursts above the character (wholesome, colorful, short)
	_play_quest_mini_fireworks(anchor)


func _play_quest_mini_fireworks(anchor: Node3D) -> void:
	## Small staggered firework pops over the apprentice on quest mastery.
	if anchor == null or not is_instance_valid(anchor):
		return
	var colors: Array = [
		Color(1.0, 0.45, 0.42, 0.95),  # soft coral
		Color(0.45, 0.75, 1.0, 0.95),  # sky
		Color(0.55, 0.95, 0.55, 0.95), # mint
		Color(1.0, 0.72, 0.35, 0.95),  # honey
		Color(0.85, 0.55, 1.0, 0.95),  # lilac
		Color(1.0, 0.55, 0.78, 0.95),  # rose
	]
	for i in colors.size():
		var delay: float = 0.12 + float(i) * 0.18
		var col: Color = colors[i]
		var ox: float = randf_range(-0.55, 0.55)
		var oz: float = randf_range(-0.55, 0.55)
		var oy: float = 2.05 + float(i % 3) * 0.35
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(anchor):
				return
			_spawn_firework_burst(anchor, Vector3(ox, oy, oz), col, i % 2 == 0)
		)


func _spawn_firework_burst(anchor: Node3D, local_pos: Vector3, col: Color, play_pop: bool = true) -> void:
	var burst := CPUParticles3D.new()
	burst.name = "QuestFireworkBurst"
	burst.position = local_pos
	burst.emitting = true
	burst.one_shot = true
	burst.explosiveness = 0.96
	burst.amount = 28
	burst.lifetime = 1.0
	burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 0.1
	burst.direction = Vector3(0, 1, 0)
	burst.spread = 180.0
	burst.initial_velocity_min = 1.8
	burst.initial_velocity_max = 3.8
	burst.gravity = Vector3(0, -3.4, 0)
	burst.scale_amount_min = 0.1
	burst.scale_amount_max = 0.28
	burst.color = col
	HeadlessGuard.guard_particles(burst)
	anchor.add_child(burst)
	var flash := OmniLight3D.new()
	flash.name = "QuestFireworkFlash"
	flash.position = local_pos
	flash.light_color = Color(col.r, col.g, col.b)
	flash.light_energy = 2.8
	flash.omni_range = 3.2
	flash.shadow_enabled = false
	anchor.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "light_energy", 0.05, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(1.1).timeout.connect(func():
		if is_instance_valid(burst):
			burst.queue_free()
		if is_instance_valid(flash):
			flash.queue_free()
	)
	if play_pop and AudioBus.has_method("play_firework_pop"):
		AudioBus.play_firework_pop()


func _play_week_unicorn_party(_new_week: int = 1, _completed_week: int = 1) -> void:
	## v1.84: after a week assignment unlocks the next week, animated unicorn art dances around the apprentice.
	if HeadlessGuard.is_headless():
		return
	var anchor: Node3D = player
	if anchor == null or not is_instance_valid(anchor):
		return
	# Clear any prior party so repeats stay tidy
	var old := get_node_or_null("WeekUnicornParty")
	if old != null:
		old.queue_free()
	var party := Node3D.new()
	party.name = "WeekUnicornParty"
	# Keep party in world space near the player (not parented to moving mesh root forever)
	add_child(party)
	party.global_position = anchor.global_position
	if not _party_unicorn_frames_loaded():
		return
	# Soft coat tints — art already has a rainbow mane; keep modulate gentle
	var tints: Array = [
		Color(1.0, 1.0, 1.0),
		Color(1.0, 0.88, 0.95),
		Color(0.88, 0.94, 1.0),
		Color(0.95, 0.9, 1.0),
		Color(1.0, 0.95, 0.85),
		Color(0.88, 1.0, 0.92),
	]
	var count: int = tints.size()
	var radius: float = 3.2
	for i in count:
		var uni := Node3D.new()
		uni.name = "PartyUnicorn%d" % i
		var ang: float = TAU * float(i) / float(count)
		uni.position = Vector3(cos(ang) * radius, 0.0, sin(ang) * radius)
		uni.scale = Vector3(1.0, 1.0, 1.0)
		party.add_child(uni)
		var spr := _make_party_unicorn_sprite(uni, null, tints[i], float(i))
		if spr == null:
			continue
		var trail := CPUParticles3D.new()
		trail.name = "UnicornTrail"
		trail.position = Vector3(0, 0.35, 0)
		trail.emitting = true
		trail.amount = 10
		trail.lifetime = 0.7
		trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		trail.emission_sphere_radius = 0.2
		trail.direction = Vector3(0, 1, 0)
		trail.spread = 50.0
		trail.initial_velocity_min = 0.2
		trail.initial_velocity_max = 0.7
		trail.gravity = Vector3(0, 0.6, 0)
		trail.scale_amount_min = 0.06
		trail.scale_amount_max = 0.14
		var tint: Color = tints[i]
		trail.color = Color(tint.r, tint.g, tint.b, 0.7)
		HeadlessGuard.guard_particles(trail)
		uni.add_child(trail)
		_dance_unicorn(uni, spr, ang, radius, float(i))
	# Soft center rainbow fountain
	var fountain := CPUParticles3D.new()
	fountain.name = "PartyFountain"
	fountain.position = Vector3(0, 0.2, 0)
	fountain.emitting = true
	fountain.amount = 40
	fountain.lifetime = 1.4
	fountain.direction = Vector3(0, 1, 0)
	fountain.spread = 40.0
	fountain.initial_velocity_min = 1.2
	fountain.initial_velocity_max = 2.6
	fountain.gravity = Vector3(0, -1.5, 0)
	fountain.scale_amount_min = 0.1
	fountain.scale_amount_max = 0.28
	fountain.color = Color(1.0, 0.85, 0.95, 0.85)
	HeadlessGuard.guard_particles(fountain)
	party.add_child(fountain)
	var party_glow := OmniLight3D.new()
	party_glow.name = "PartyGlow"
	party_glow.position = Vector3(0, 1.8, 0)
	party_glow.light_color = Color(1.0, 0.85, 0.95)
	party_glow.light_energy = 2.4
	party_glow.omni_range = 8.0
	party_glow.shadow_enabled = false
	party.add_child(party_glow)
	if AudioBus.has_method("play_unicorn_party"):
		AudioBus.play_unicorn_party()
	# Dance ~7s then soft scale-out + poof
	var fade_tw := create_tween()
	fade_tw.tween_interval(6.5)
	fade_tw.tween_property(party_glow, "light_energy", 0.05, 0.8)
	get_tree().create_timer(7.0).timeout.connect(func():
		if not is_instance_valid(party):
			return
		var poof := CPUParticles3D.new()
		poof.name = "PartyPoof"
		poof.emitting = true
		poof.one_shot = true
		poof.explosiveness = 0.9
		poof.amount = 56
		poof.lifetime = 1.0
		poof.direction = Vector3(0, 1, 0)
		poof.spread = 80.0
		poof.initial_velocity_min = 1.0
		poof.initial_velocity_max = 3.0
		poof.gravity = Vector3(0, -1.0, 0)
		poof.scale_amount_min = 0.1
		poof.scale_amount_max = 0.34
		poof.color = Color(1.0, 0.9, 1.0, 0.9)
		HeadlessGuard.guard_particles(poof)
		party.add_child(poof)
		var exit_tw := create_tween()
		exit_tw.set_parallel(true)
		for c in party.get_children():
			if c is Node3D and str(c.name).begins_with("PartyUnicorn"):
				exit_tw.tween_property(c, "scale", Vector3(0.05, 0.05, 0.05), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		get_tree().create_timer(1.1).timeout.connect(func():
			if is_instance_valid(party):
				party.queue_free()
		)
	)


var _party_unicorn_frame_tex: Array = []  # Texture2D[6]


func _party_unicorn_frames_loaded() -> bool:
	## Load six discrete opaque frame textures (more reliable than atlas + AnimatedSprite3D).
	if not _party_unicorn_frame_tex.is_empty():
		return true
	var loaded: Array = []
	for i in 6:
		var path := "res://assets/vfx/party_unicorn_frame_%d.png" % i
		if not ResourceLoader.exists(path):
			push_warning("Party unicorn frame missing: %s" % path)
			return false
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			return false
		loaded.append(tex)
	_party_unicorn_frame_tex = loaded
	return true


func _party_unicorn_sheet() -> Texture2D:
	## Kept for smoke/path checks; frames prefer discrete PNGs.
	if _party_unicorn_frames_loaded():
		return _party_unicorn_frame_tex[0] as Texture2D
	var path := "res://assets/vfx/party_unicorn_dance_sheet.png"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _make_party_unicorn_sprite(parent: Node3D, _frames: SpriteFrames, tint: Color, idx: float) -> MeshInstance3D:
	## Upright Y-billboard cutout — stays vertical under the overhead camera.
	if not _party_unicorn_frames_loaded():
		return null
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.4
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# FIXED_Y keeps the art upright (full BILLBOARD flattens toward the top-down camera).
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 1.0)
	mat.albedo_texture = _party_unicorn_frame_tex[int(idx) % 6] as Texture2D
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	var quad := QuadMesh.new()
	quad.size = Vector2(1.55, 2.15)
	var mi := MeshInstance3D.new()
	mi.name = "Art"
	mi.mesh = quad
	mi.material_override = mat
	mi.position = Vector3(0, 1.25, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("mat", mat)
	mi.set_meta("frame_i", int(idx) % 6)
	parent.add_child(mi)
	return mi


func _set_party_unicorn_frame(spr: MeshInstance3D, frame_i: int) -> void:
	if spr == null or not is_instance_valid(spr):
		return
	if not _party_unicorn_frames_loaded():
		return
	var mat: StandardMaterial3D = spr.get_meta("mat") as StandardMaterial3D
	if mat == null:
		return
	var fi: int = posmod(frame_i, 6)
	mat.albedo_texture = _party_unicorn_frame_tex[fi] as Texture2D
	spr.set_meta("frame_i", fi)


func _dance_unicorn(uni: Node3D, spr: Node3D, start_ang: float, radius: float, idx: float) -> void:
	## Orbit + hop + prance-frame dance for one party unicorn (~8s).
	if uni == null or not is_instance_valid(uni):
		return
	var hop_h: float = 0.7 + (idx * 0.05)
	var orbit := uni.create_tween()
	orbit.set_loops(16)
	orbit.tween_method(func(t: float):
		if not is_instance_valid(uni):
			return
		var a: float = start_ang + t * TAU
		var hop: float = absf(sin(t * TAU * 2.5)) * hop_h
		uni.position = Vector3(cos(a) * radius, hop, sin(a) * radius)
		if spr != null and is_instance_valid(spr) and spr is MeshInstance3D:
			var mi: MeshInstance3D = spr as MeshInstance3D
			_set_party_unicorn_frame(mi, int(floor(t * 18.0 + idx * 2.0)))
			var flip: float = -1.0 if (-sin(a) > 0.0) else 1.0
			var squash: float = 1.0 + absf(sin(t * TAU * 2.5)) * 0.14
			mi.scale = Vector3(flip * (2.0 - squash), squash, 1.0)
			mi.position.y = 1.25 + absf(sin(t * TAU * 5.0)) * 0.12
	, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_LINEAR)


func _build_ambient_life() -> void:
	## Wholesome birds / bugs / idle critters at wilds landmarks (headless-safe).
	var root := Node3D.new()
	root.name = "AmbientLife"
	static_world.add_child(root)
	_ambient_critters.clear()
	if HeadlessGuard.is_headless():
		return
	var sites := [
		# Village green / fountain plaza — denser ambient variety (Wave 18)
		{"pos": Vector3(0.0, 0, 8.0), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(4.5, 0, 11.5), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-4.8, 0, 11.2), "birds": false, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(0.0, 0, 3.5), "birds": true, "bugs": false, "critter": "sparrow", "dense": true},
		{"pos": Vector3(9.0, 0, 7.5), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(-9.0, 0, 7.5), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(2.5, 0, 15.5), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		# Wave 24 denser plaza ambient
		{"pos": Vector3(-2.2, 0, 14.8), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(6.8, 0, 9.0), "birds": false, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(-6.5, 0, 9.2), "birds": true, "bugs": false, "critter": "sparrow", "dense": true},
		# Guild hall doorsteps — closer to plaza density (Wave 19)
		{"pos": Vector3(22.0, 0, 1.2), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-22.0, 0, 1.2), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(0.0, 0, -18.8), "birds": false, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(0.0, 0, 27.2), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(0.0, 0, -2.6), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		# Indoor hall dust-motes / soft moths (Interiors at x≈120+)
		{"pos": Vector3(120.0, 0, 0.0), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(148.0, 0, 0.0), "birds": false, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(176.0, 0, 0.0), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(204.0, 0, 0.0), "birds": false, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(232.0, 0, 0.0), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		# Wilds spurs — denser ambient (Wave 19, plaza parity)
		{"pos": Vector3(0.5, 0, -48.0), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(3.5, 0, -45.0), "birds": true, "bugs": false, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-24.0, 0, -54.0), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-27.0, 0, -51.0), "birds": false, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(30.0, 0, 18.0), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(33.0, 0, 15.5), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(40.0, 0, 34.0), "birds": true, "bugs": false, "critter": "sparrow", "dense": true},
		{"pos": Vector3(37.0, 0, 31.0), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(-36.0, 0, 30.0), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(-33.0, 0, 33.0), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		# Cedar Hollow (Wave 20)
		{"pos": Vector3(38.0, 0, -36.0), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(41.0, 0, -33.0), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		# Willow Bend (Wave 21)
		{"pos": Vector3(-38.0, 0, -34.0), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(-35.0, 0, -31.0), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		# Reed Pool (Wave 22)
		{"pos": Vector3(-20.0, 0, 48.0), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(-17.0, 0, 45.5), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(-23.0, 0, 50.0), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-41.0, 0, -36.5), "birds": false, "bugs": true, "critter": "sparrow", "dense": true},
		# Quiet Cross (Wave 23)
		{"pos": Vector3(48.0, 0, 8.0), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(45.0, 0, 10.5), "birds": false, "bugs": true, "critter": "sparrow", "dense": true},
		# Stone Arch (Wave 24)
		{"pos": Vector3(-48.0, 0, 8.0), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-45.0, 0, 10.5), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(-51.0, 0, 5.5), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		# Amber Knoll (Wave 25)
		{"pos": Vector3(48.0, 0, -22.0), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(45.0, 0, -19.5), "birds": false, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(51.0, 0, -24.5), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		# Birch Rest (Wave 26)
		{"pos": Vector3(-42.0, 0, -20.0), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-39.0, 0, -17.5), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(-45.0, 0, -22.5), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		# Fern Dell (Wave 27)
		{"pos": Vector3(22.0, 0, 48.0), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(19.0, 0, 45.5), "birds": false, "bugs": true, "critter": "dragonfly", "dense": true},
		{"pos": Vector3(25.0, 0, 50.5), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		# Heather Heath (Wave 28)
		{"pos": Vector3(-48.0, 0, 42.0), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(-45.0, 0, 39.5), "birds": false, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-51.0, 0, 44.5), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		# Thistle Rise (Wave 29)
		{"pos": Vector3(48.0, 0, 42.0), "birds": true, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(45.0, 0, 39.5), "birds": false, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(51.0, 0, 44.5), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		# Maple Copse (Wave 30)
		{"pos": Vector3(-48.0, 0, -48.0), "birds": true, "bugs": true, "critter": "sparrow", "dense": true},
		{"pos": Vector3(-45.0, 0, -45.5), "birds": false, "bugs": true, "critter": "butterfly", "dense": true},
		{"pos": Vector3(-51.0, 0, -50.5), "birds": true, "bugs": true, "critter": "dragonfly", "dense": true},
		# Village yard animals — hens and lambs near the fountain (Wave 20)
		{"pos": Vector3(6.5, 0, 5.0), "birds": false, "bugs": false, "critter": "hen"},
		{"pos": Vector3(-6.2, 0, 4.8), "birds": false, "bugs": false, "critter": "hen"},
		{"pos": Vector3(8.0, 0, 12.5), "birds": false, "bugs": false, "critter": "lamb"},
		{"pos": Vector3(-7.5, 0, 13.0), "birds": false, "bugs": false, "critter": "lamb"},
	]
	for i in sites.size():
		var s: Dictionary = sites[i]
		var p: Vector3 = s["pos"]
		var dense: bool = bool(s.get("dense", false))
		if s.get("birds", false):
			_add_bird_particles(root, p + Vector3(0, 4.5, 0), 200 + i, dense)
		if s.get("bugs", false):
			_add_bug_particles(root, p + Vector3(0.8, 1.2, -0.5), 300 + i, dense)
		_add_idle_critter(root, p + Vector3(-1.2, 1.1, 0.9), str(s.get("critter", "butterfly")), 0.4 * float(i))


func _add_bird_particles(parent: Node, pos: Vector3, seed_n: int, dense: bool = false) -> void:
	var p := CPUParticles3D.new()
	p.name = "Birds_%d" % seed_n
	p.position = pos
	p.amount = 10 if dense else 6
	p.lifetime = 5.5
	p.preprocess = 2.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(5.5, 1.2, 5.5)
	p.direction = Vector3(1, 0.05, 0.35)
	p.spread = 28.0
	p.initial_velocity_min = 1.1
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0, 0.05, 0)
	p.angular_velocity_min = -20.0
	p.angular_velocity_max = 20.0
	p.scale_amount_min = 0.85
	p.scale_amount_max = 1.2
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.22, 0.05, 0.1)
	p.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.55, 0.48, 0.42, 0.85)
	p.material_override = mat
	parent.add_child(p)
	HeadlessGuard.guard_particles(p)


func _add_bug_particles(parent: Node, pos: Vector3, seed_n: int, dense: bool = false) -> void:
	var p := CPUParticles3D.new()
	p.name = "Bugs_%d" % seed_n
	p.position = pos
	p.amount = 16 if dense else 10
	p.lifetime = 3.2
	p.preprocess = 1.5
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 2.4
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.15
	p.initial_velocity_max = 0.55
	p.gravity = Vector3(0, 0.02, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.1
	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	p.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Soft firefly / bug sparkle — warm gold-green
	mat.albedo_color = Color(0.85, 0.92, 0.45, 0.7)
	p.material_override = mat
	parent.add_child(p)
	HeadlessGuard.guard_particles(p)


func _add_idle_critter(parent: Node, pos: Vector3, kind: String, phase0: float) -> void:
	var bob := Node3D.new()
	bob.name = "Critter_%s" % kind
	# Ground animals stay near the dirt; flyers keep a little height.
	var place := pos
	if kind == "hen" or kind == "lamb":
		place = Vector3(pos.x, 0.12, pos.z)
	bob.position = place
	parent.add_child(bob)
	var body := MeshInstance3D.new()
	body.name = "Body"
	match kind:
		"sparrow":
			var sm := SphereMesh.new()
			sm.radius = 0.09
			sm.height = 0.14
			body.mesh = sm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.45, 0.38, 0.32)
			body.material_override = mat
			body.position = Vector3(0, 0, 0)
			# Tiny wing stubs
			var wing := MeshInstance3D.new()
			wing.mesh = _box(Vector3(0.16, 0.03, 0.06))
			var wmat := StandardMaterial3D.new()
			wmat.albedo_color = Color(0.5, 0.42, 0.35)
			wing.material_override = wmat
			wing.position = Vector3(0, 0.02, 0)
			bob.add_child(wing)
			HeadlessGuard.guard_mesh(wing)
		"dragonfly":
			var sm := SphereMesh.new()
			sm.radius = 0.05
			sm.height = 0.14
			body.mesh = sm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.65, 0.55)
			body.material_override = mat
			var wing := MeshInstance3D.new()
			wing.mesh = _box(Vector3(0.28, 0.015, 0.08))
			var wmat := StandardMaterial3D.new()
			wmat.albedo_color = Color(0.7, 0.9, 0.85, 0.7)
			wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			wing.material_override = wmat
			wing.position = Vector3(0, 0.02, 0)
			bob.add_child(wing)
			HeadlessGuard.guard_mesh(wing)
		"hen":
			var sm := SphereMesh.new()
			sm.radius = 0.11
			sm.height = 0.16
			body.mesh = sm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.78, 0.42, 0.22)
			body.material_override = mat
			var head := MeshInstance3D.new()
			var hm := SphereMesh.new()
			hm.radius = 0.055
			head.mesh = hm
			var hmat := StandardMaterial3D.new()
			hmat.albedo_color = Color(0.85, 0.55, 0.28)
			head.material_override = hmat
			head.position = Vector3(0, 0.1, 0.08)
			bob.add_child(head)
			HeadlessGuard.guard_mesh(head)
			var comb := MeshInstance3D.new()
			comb.mesh = _box(Vector3(0.03, 0.05, 0.04))
			var cmat := StandardMaterial3D.new()
			cmat.albedo_color = Color(0.75, 0.18, 0.16)
			comb.material_override = cmat
			comb.position = Vector3(0, 0.16, 0.08)
			bob.add_child(comb)
			HeadlessGuard.guard_mesh(comb)
		"lamb":
			var sm := SphereMesh.new()
			sm.radius = 0.14
			sm.height = 0.18
			body.mesh = sm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.92, 0.90, 0.84)
			body.material_override = mat
			var head := MeshInstance3D.new()
			var hm := SphereMesh.new()
			hm.radius = 0.07
			head.mesh = hm
			var hmat := StandardMaterial3D.new()
			hmat.albedo_color = Color(0.85, 0.78, 0.62)
			head.material_override = hmat
			head.position = Vector3(0, 0.08, 0.14)
			bob.add_child(head)
			HeadlessGuard.guard_mesh(head)
			for side in [-1.0, 1.0]:
				var ear := MeshInstance3D.new()
				ear.mesh = _box(Vector3(0.04, 0.06, 0.02))
				var emat := StandardMaterial3D.new()
				emat.albedo_color = Color(0.78, 0.68, 0.5)
				ear.material_override = emat
				ear.position = Vector3(side * 0.08, 0.14, 0.12)
				bob.add_child(ear)
				HeadlessGuard.guard_mesh(ear)
		_:
			# Butterfly — two soft wing plates
			var sm := SphereMesh.new()
			sm.radius = 0.045
			sm.height = 0.08
			body.mesh = sm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.85, 0.55, 0.35)
			body.material_override = mat
			for side in [-1.0, 1.0]:
				var wing := MeshInstance3D.new()
				wing.mesh = _box(Vector3(0.14, 0.02, 0.1))
				var wmat := StandardMaterial3D.new()
				wmat.albedo_color = Color(0.9, 0.55, 0.75) if side > 0 else Color(0.95, 0.75, 0.4)
				wing.material_override = wmat
				wing.position = Vector3(side * 0.08, 0.02, 0)
				wing.rotation_degrees = Vector3(0, 0, side * -25.0)
				bob.add_child(wing)
				HeadlessGuard.guard_mesh(wing)
	bob.add_child(body)
	HeadlessGuard.guard_mesh(body)
	_ambient_critters.append({
		"node": bob,
		"base": place,
		"phase": phase0,
		"kind": kind,
	})


func _update_ambient_critters(delta: float) -> void:
	if _ambient_critters.is_empty():
		return
	for c in _ambient_critters:
		var n: Node3D = c.get("node")
		if n == null or not is_instance_valid(n):
			continue
		var phase: float = float(c.get("phase", 0.0)) + delta
		c["phase"] = phase
		var base: Vector3 = c.get("base", n.position)
		var kind: String = str(c.get("kind", "butterfly"))
		match kind:
			"sparrow":
				n.position = base + Vector3(
					sin(phase * 0.7) * 0.35,
					0.25 + abs(sin(phase * 1.6)) * 0.35,
					cos(phase * 0.55) * 0.35
				)
				n.rotation.y = phase * 0.4
			"dragonfly":
				n.position = base + Vector3(
					sin(phase * 1.1) * 0.7,
					0.15 + sin(phase * 2.2) * 0.2,
					cos(phase * 0.9) * 0.5
				)
				n.rotation.y = phase * 0.9
			"hen":
				n.position = base + Vector3(
					sin(phase * 0.35) * 0.55,
					0.0,
					cos(phase * 0.28) * 0.45
				)
				n.rotation.y = phase * 0.35
			"lamb":
				n.position = base + Vector3(
					sin(phase * 0.22) * 0.7,
					abs(sin(phase * 1.4)) * 0.03,
					cos(phase * 0.18) * 0.55
				)
				n.rotation.y = phase * 0.22
			_:
				n.position = base + Vector3(
					sin(phase * 0.85) * 0.55,
					0.1 + sin(phase * 2.8) * 0.18,
					cos(phase * 0.7) * 0.45
				)
				n.rotation.y = phase * 0.6
				# Soft wing flutter
				for child in n.get_children():
					if child is MeshInstance3D and child.name != "Body":
						child.rotation.z = sin(phase * 10.0) * 0.35


func _setup_outdoor_navigation() -> void:
	## Lightweight outdoor NavigationRegion3D bake (static colliders + ground).
	## Skips guild-hall interiors (x >= 90). Falls back gracefully if bake is empty.
	var region := NavigationRegion3D.new()
	region.name = "OutdoorNavRegion"
	add_child(region)
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.5
	nm.agent_height = 1.5
	nm.agent_max_climb = 0.5
	nm.agent_max_slope = 45.0
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.filter_baking_aabb = AABB(Vector3(-54, -1, -64), Vector3(108, 5, 118))
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, source, static_world)
	NavigationServer3D.bake_from_source_geometry_data(nm, source)
	region.navigation_mesh = nm
	if player and player.has_method("set_navigation_ready"):
		player.set_navigation_ready(true)

func _setup_indoor_navigation() -> void:
	## Indoor NavigationRegion3D (world-root, global mesh space) for guild-hall click-move.
	if _interior_root == null:
		return
	var region := NavigationRegion3D.new()
	region.name = "IndoorNavRegion"
	add_child(region)
	var nm := NavigationMesh.new()
	# Keep agent_radius a multiple of cell_size to avoid bake precision warnings.
	nm.agent_radius = 0.5
	nm.agent_height = 1.5
	nm.agent_max_climb = 0.5
	nm.agent_max_slope = 45.0
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	# Interiors live near x≈120+; cover all five halls with margin
	nm.filter_baking_aabb = AABB(Vector3(100, -1, -20), Vector3(160, 5, 40))
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, source, _interior_root)
	NavigationServer3D.bake_from_source_geometry_data(nm, source)
	region.navigation_mesh = nm
	if player and player.has_method("set_navigation_ready"):
		player.set_navigation_ready(true)

