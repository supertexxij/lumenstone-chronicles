extends CharacterBody3D
const HitsplatUtil = preload("res://scripts/combat/hitsplat.gd")
## Soft RuneScape-style tick combat foe with limb-aware creature meshes,
## flinch, death dissolve, and soft aggro radius.

@export var kind: String = "dim_wisp"
@export var spawn_id: String = ""

var def: Dictionary = {}
var hp: int = 10
var max_hp: int = 10
var alive: bool = true
var tick_timer: float = 0.0
var respawn_timer: float = 0.0
var spawn_pos: Vector3
var creature_bob: Node3D = null
var wing_phase: float = 0.0
var _flinch_t: float = 0.0
var _kill_flash_t: float = -1.0
var _hit_flash_t: float = -1.0
var _kill_flash_base: Dictionary = {}  # MeshInstance3D -> Color
var _dissolve_t: float = -1.0
var _base_scale: Vector3 = Vector3.ONE
var _aggro_pulse: float = 0.0
var _telegraph: MeshInstance3D = null
var _was_warning: bool = false
var _countdown_nudge: bool = false  # Wave 37: mid-telegraph countdown toast
var _target_reticle: MeshInstance3D = null  # Wave 31: soft cream combat target ring

@onready var mesh_root: Node3D = $MeshRoot
var label: Label3D
@onready var hp_bar: MeshInstance3D = $HpBar

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	def = EnemyDB.get_def(kind)
	max_hp = int(def.get("max_hp", 10))
	hp = max_hp
	label = get_node_or_null("Label3D") as Label3D
	if HeadlessGuard.is_headless():
		if label:
			label.queue_free()
			label = null
	elif label:
		label.text = def.get("name", kind)
	if hp_bar and hp_bar.mesh == null:
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.12, 0.12)
		hp_bar.mesh = box
	if hp_bar:
		HeadlessGuard.guard_mesh(hp_bar)
	creature_bob = CreatureBuilder.build(kind, mesh_root)
	var primary := Color(def.get("color", "#888888"))
	var accent := Color(def.get("accent", "#aaaaaa"))
	CreatureBuilder.colorize(creature_bob, primary, accent)
	_base_scale = mesh_root.scale
	match kind:
		"dust_golem":
			if label: label.position.y = 2.4
			hp_bar.position.y = 2.1
		"briar_boar":
			if label: label.position.y = 1.6
			hp_bar.position.y = 1.35
		"moss_badger":
			if label: label.position.y = 1.55
			hp_bar.position.y = 1.3
		"cedar_stag":
			if label: label.position.y = 2.15
			hp_bar.position.y = 1.9
		"pine_fox":
			if label: label.position.y = 1.5
			hp_bar.position.y = 1.25
		"oak_hare":
			if label: label.position.y = 1.45
			hp_bar.position.y = 1.2
		"birch_squirrel":
			if label: label.position.y = 1.4
			hp_bar.position.y = 1.15
		"aspen_otter":
			if label: label.position.y = 1.35
			hp_bar.position.y = 1.1
		"elm_raccoon":
			if label: label.position.y = 1.4
			hp_bar.position.y = 1.15
		"shadow_moth":
			if label: label.position.y = 1.9
			hp_bar.position.y = 1.6
		"beech_chipmunk":
			if label: label.position.y = 1.35
			hp_bar.position.y = 1.1
		"alder_duck":
			if label: label.position.y = 1.3
			hp_bar.position.y = 1.05
		"fir_frog":
			if label: label.position.y = 1.25
			hp_bar.position.y = 1.0
		"cypress_turtle":
			if label: label.position.y = 1.3
			hp_bar.position.y = 1.05
		"poplar_dove":
			if label: label.position.y = 1.45
			hp_bar.position.y = 1.2
		"rowan_robin":
			if label: label.position.y = 1.4
			hp_bar.position.y = 1.15
		"ash_sparrow":
			if label: label.position.y = 1.35
			hp_bar.position.y = 1.1
		"hickory_quail":
			if label: label.position.y = 1.4
			hp_bar.position.y = 1.15
		"juniper_jay":
			if label: label.position.y = 1.5
			hp_bar.position.y = 1.25
		"sycamore_skink":
			if label: label.position.y = 1.15
			hp_bar.position.y = 0.9
		"chestnut_toad":
			if label: label.position.y = 1.2
			hp_bar.position.y = 0.95
		"cherry_chinchilla":
			if label: label.position.y = 1.45
			hp_bar.position.y = 1.2
		"plum_porcupine":
			if label: label.position.y = 1.5
			hp_bar.position.y = 1.25
		"grape_gecko":
			if label: label.position.y = 1.2
			hp_bar.position.y = 0.95
		"apricot_armadillo":
			if label: label.position.y = 1.25
			hp_bar.position.y = 1.0
		"blueberry_bunny":
			if label: label.position.y = 1.55
			hp_bar.position.y = 1.3
		"cranberry_capybara":
			if label: label.position.y = 1.45
			hp_bar.position.y = 1.2
		"raspberry_ram":
			if label: label.position.y = 1.55
			hp_bar.position.y = 1.3
		"strawberry_stoat":
			if label: label.position.y = 1.35
			hp_bar.position.y = 1.1
		_:
			if label: label.position.y = 1.8
			hp_bar.position.y = 1.5
	_update_hp_bar()
	_ensure_telegraph()
	_ensure_target_reticle()
	_ensure_nav_obstacle()
	if GameState.has_signal("soft_combat_cleared") and not GameState.soft_combat_cleared.is_connected(clear_soft_aggro):
		GameState.soft_combat_cleared.connect(clear_soft_aggro)

func is_alive() -> bool:
	return alive

func clear_soft_aggro() -> void:
	_countdown_nudge = false
	## Called when player rests at the fountain — drop yellow pull / pulse.
	_aggro_pulse = 0.0
	_was_warning = false
	_set_warning(false)

func _ensure_nav_obstacle() -> void:
	if get_node_or_null("NavObstacle") != null:
		return
	var obs := NavigationObstacle3D.new()
	obs.name = "NavObstacle"
	obs.radius = 0.5
	obs.height = 1.5
	obs.avoidance_enabled = true
	add_child(obs)

func _physics_process(delta: float) -> void:
	if _dissolve_t >= 0.0:
		_tick_kill_flash(delta)
		_tick_hit_flash(delta)
		_dissolve_t += delta
		var u := clampf(_dissolve_t / 0.7, 0.0, 1.0)
		mesh_root.scale = _base_scale * (1.0 - u)
		modulate_meshes(1.0 - u)
		if u >= 1.0:
			_dissolve_t = -1.0
			visible = false
			mesh_root.scale = _base_scale
			modulate_meshes(1.0)
		return

	if not alive:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn()
		return

	_idle_anim(delta)
	_update_flinch(delta)
	_soft_aggro(delta)
	_update_target_reticle(delta)

	if GameState.combat_target == self:
		tick_timer -= delta
		if tick_timer <= 0:
			tick_timer = float(EnemyDB.base_combat.get("tick_sec", 0.7))
			_combat_tick()

func modulate_meshes(a: float) -> void:
	## Fade meshes during dissolve (alpha via albedo)
	if creature_bob == null:
		return
	_fade_node(creature_bob, a)

func _fade_node(n: Node, a: float) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mi.material_override
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if a < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
			var c: Color = mat.albedo_color
			c.a = a
			mat.albedo_color = c
	for c in n.get_children():
		_fade_node(c, a)


func _ensure_target_reticle() -> void:
	## Wave 31: soft cream combat-target ring under the engaged foe (no combat labels).
	if _target_reticle != null:
		return
	_target_reticle = MeshInstance3D.new()
	_target_reticle.name = "TargetReticle"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.72
	ring.outer_radius = 0.92
	ring.rings = 10
	ring.ring_segments = 20
	_target_reticle.mesh = ring
	HeadlessGuard.guard_mesh(_target_reticle)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.94, 0.82, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.9
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_target_reticle.material_override = mat
	_target_reticle.position = Vector3(0, 0.06, 0)
	_target_reticle.visible = false
	add_child(_target_reticle)


func _update_target_reticle(_delta: float) -> void:
	_ensure_target_reticle()
	var on := alive and GameState.combat_target == self
	_target_reticle.visible = on
	# Wave 48: clearer combat target name plate — chunkier outline + warm cream when engaged
	_update_target_nameplate(on)
	if not on:
		return
	# Soft steady cream breath — distinct from yellow soft-aggro telegraph
	var pulse: float = 0.48 + 0.14 * abs(sin(Time.get_ticks_msec() * 0.003))
	var s: float = 0.96 + 0.06 * abs(sin(Time.get_ticks_msec() * 0.0025))
	if _target_reticle.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = _target_reticle.material_override
		mat.albedo_color = Color(0.98, 0.94, 0.82, pulse)
	_target_reticle.scale = Vector3(s, 1.0, s)


func _update_target_nameplate(engaged: bool) -> void:
	## Wave 48: clearer combat target name plate (RuneScape-chunky, wholesome; no cheesy combat labels).
	if label == null:
		return
	if engaged:
		label.outline_size = 12
		label.font_size = 48
		label.modulate = Color(1.0, 0.97, 0.82, 1.0)
		label.outline_modulate = Color(0.22, 0.18, 0.10, 0.95)
	else:
		label.outline_size = 6
		label.font_size = 40
		if not _was_warning:
			label.modulate = Color.WHITE
		label.outline_modulate = Color(0, 0, 0, 1)

func _ensure_telegraph() -> void:
	## Wave 23: chunkier RuneScape-style soft-aggro ring — bright torus rim + soft fill disc.
	if _telegraph != null:
		return
	_telegraph = MeshInstance3D.new()
	_telegraph.name = "AggroTelegraph"
	# Soft warm fill disc under the rim
	var disc := CylinderMesh.new()
	disc.top_radius = 1.42
	disc.bottom_radius = 1.42
	disc.height = 0.025
	_telegraph.mesh = disc
	HeadlessGuard.guard_mesh(_telegraph)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.9, 0.28, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.95
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph.material_override = mat
	_telegraph.position = Vector3(0, 0.035, 0)
	_telegraph.visible = false
	add_child(_telegraph)
	# Bright outer rim (torus) — clearer at a glance than a flat disc alone
	var rim := MeshInstance3D.new()
	rim.name = "AggroRim"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.28
	torus.outer_radius = 1.52
	torus.rings = 12
	torus.ring_segments = 24
	rim.mesh = torus
	HeadlessGuard.guard_mesh(rim)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(1.0, 0.94, 0.35, 0.55)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.roughness = 0.9
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim.material_override = rmat
	rim.position = Vector3(0, 0.05, 0)
	rim.visible = false
	add_child(rim)

func _set_warning(on: bool) -> void:
	_ensure_telegraph()
	var rim: MeshInstance3D = get_node_or_null("AggroRim") as MeshInstance3D
	if _telegraph:
		_telegraph.visible = on
	if rim:
		rim.visible = on
	if on:
		# Gentle warm tint — not alarm-red
		if label:
			label.modulate = Color(1.0, 0.96, 0.72)
			# Wave 50: clearer soft-aggro name+countdown combo on the floating nameplate
			var foe_n: String = str(def.get("name", kind))
			var remain_lbl: float = maxf(0.1, 1.15 - _aggro_pulse)
			label.text = "%s · ~%.1fs" % [foe_n, remain_lbl]
			label.outline_size = 10
		# Wave 28: slightly stronger soft-pull breath so the yellow ring reads before a pull (no combat labels)
		# Wave 53: soft color shift yellow → warm honey as telegraph nears pull (no cheesy combat labels)
		# Wave 64: clearer soft-aggro ring when armor Def high (RuneScape-chunky, wholesome; no cheesy combat labels)
		var pulse: float = 0.26 + 0.22 * abs(sin(Time.get_ticks_msec() * 0.0042))
		var s: float = 0.92 + 0.14 * abs(sin(Time.get_ticks_msec() * 0.0038))
		var prog: float = clampf(_aggro_pulse / 1.15, 0.0, 1.0)
		var def_n: int = 0
		if GameState.has_method("get_defense"):
			def_n = int(GameState.get_defense())
		var def_boost: float = clampf(float(def_n) / 7.0, 0.0, 1.0)  # soft cap matches armor Def
		if def_boost > 0.0:
			pulse = pulse * (1.0 + 0.38 * def_boost)
			s = s * (1.0 + 0.10 * def_boost)
		var disc_a := Color(0.99, 0.92, 0.32, pulse * 0.78)
		var disc_b := Color(1.0, 0.72, 0.28, pulse * 0.88)
		var rim_a := Color(1.0, 0.96, 0.42, 0.48 + pulse * 0.4)
		var rim_b := Color(1.0, 0.78, 0.32, 0.55 + pulse * 0.42)
		# High Def: cream-bright rim so the safe-step-back ring reads clearer
		if def_boost > 0.15:
			rim_a = rim_a.lerp(Color(1.0, 0.98, 0.78, 0.62 + pulse * 0.45), def_boost)
			rim_b = rim_b.lerp(Color(1.0, 0.88, 0.55, 0.70 + pulse * 0.42), def_boost)
			disc_a = disc_a.lerp(Color(1.0, 0.96, 0.55, pulse * 0.92), def_boost * 0.65)
		if _telegraph and _telegraph.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = _telegraph.material_override
			mat.albedo_color = disc_a.lerp(disc_b, prog)
			_telegraph.scale = Vector3(s, 1.0, s)
		if rim and rim.material_override is StandardMaterial3D:
			var rmat: StandardMaterial3D = rim.material_override
			rmat.albedo_color = rim_a.lerp(rim_b, prog)
			rim.scale = Vector3(s, 1.0, s)
	else:
		if label:
			label.modulate = Color.WHITE
			# Restore plain name when soft-aggro clears (Wave 50 combo)
			var base_n: String = str(def.get("name", kind))
			if GameState.combat_target != self:
				label.text = base_n
				label.outline_size = 6
		if _telegraph:
			_telegraph.scale = Vector3.ONE
		if rim:
			rim.scale = Vector3.ONE

func _soft_aggro(delta: float) -> void:
	## Soft RuneScape-like pull: long yellow telegraph, easy escape, muted toast spam.
	if GameState.combat_target != null:
		_set_warning(false)
		_aggro_pulse = 0.0
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		_set_warning(false)
		return
	if player.get("ui_blocking"):
		_set_warning(false)
		return
	# Skip soft-aggro while player is inside guild halls
	if player.global_position.x >= 90.0:
		_set_warning(false)
		_aggro_pulse = 0.0
		return
	var engage: float = float(EnemyDB.base_combat.get("engage_range", 3.8))
	var warn_range: float = engage + 1.6
	var telegraph_sec: float = 1.15  # longer fair warning
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= warn_range:
		_aggro_pulse += delta
		var warning := _aggro_pulse > 0.08 and _aggro_pulse < telegraph_sec
		_set_warning(warning or (dist <= engage and _aggro_pulse < telegraph_sec))
		if not _was_warning and warning:
			var first_warn := not GameState.seen_aggro_tutorial
			GameState.mark_aggro_tutorial()
			_countdown_nudge = false
			# Wave 29: always name the foe on soft-aggro toast (first tip + later notices)
			# Wave 37: clearer soft-aggro countdown — remaining telegraph seconds
			var foe_name: String = str(def.get("name", "Foe"))
			var remain: float = maxf(0.1, telegraph_sec - _aggro_pulse)
			if first_warn:
				GameState.toast.emit("%s · soft yellow · ~%.1fs to step back (name shows countdown)." % [foe_name, remain])
			else:
				GameState.toast.emit("%s · ~%.1fs to step back…" % [foe_name, remain])
		elif warning and (not _countdown_nudge) and _aggro_pulse >= telegraph_sec * 0.55:
			_countdown_nudge = true
			var foe_mid: String = str(def.get("name", "Foe"))
			var remain_mid: float = maxf(0.1, telegraph_sec - _aggro_pulse)
			# Wave 58: clearer soft-aggro mid-telegraph toast (no cheesy combat labels)
			GameState.toast.emit("%s · soft yellow mid · ~%.1fs — step back now" % [foe_mid, remain_mid])
		_was_warning = warning
		if dist <= engage and _aggro_pulse > telegraph_sec:
			_set_warning(false)
			_was_warning = false
			_countdown_nudge = false
			GameState.set_combat_target(self)
			var first_fight := GameState.mark_combat_tutorial(true)
			if first_fight:
				# Wave 65: clearer first-fight tip with foe name — lead with who, then soft ticks + how to leave (RuneScape-chunky, wholesome)
				var foe_nm := str(def.get("name", "Foe"))
				GameState.toast.emit("First fight · %s: soft ticks (~0.7s). Walk away or click the ground to leave." % foe_nm)
			else:
				GameState.toast.emit("%s approaches — click away to leave." % def.get("name", "Foe"))
			_aggro_pulse = 0.0
	else:
		# Faster decay so stepping back clears warning quickly
		_aggro_pulse = move_toward(_aggro_pulse, 0.0, delta * 2.8)
		_set_warning(false)
		_was_warning = false
		_countdown_nudge = false

func _idle_anim(delta: float) -> void:
	if creature_bob == null or _flinch_t > 0.0:
		return
	var t := Time.get_ticks_msec() * 0.004 + spawn_pos.x
	match kind:
		"dim_wisp":
			creature_bob.position.y = sin(t) * 0.12
			creature_bob.rotation.y = sin(t * 0.5) * 0.15
		"shadow_moth":
			creature_bob.position.y = 0.15 + sin(t) * 0.1
			wing_phase += delta * 14.0
			var lw := creature_bob.get_node_or_null("LWing")
			var rw := creature_bob.get_node_or_null("RWing")
			var flap := sin(wing_phase) * 0.35
			if lw:
				lw.rotation.z = deg_to_rad(25) + flap
			if rw:
				rw.rotation.z = deg_to_rad(-25) - flap
		"briar_boar":
			creature_bob.position.y = abs(sin(t * 0.5)) * 0.02
			creature_bob.rotation.y = sin(t * 0.3) * 0.08
		"moss_badger":
			creature_bob.position.y = abs(sin(t * 0.55)) * 0.025
			creature_bob.rotation.y = sin(t * 0.35) * 0.1
		"cedar_stag":
			creature_bob.position.y = abs(sin(t * 0.4)) * 0.02
			creature_bob.rotation.y = sin(t * 0.22) * 0.12
			var head_n := creature_bob.get_node_or_null("Head")
			if head_n:
				head_n.rotation.x = sin(t * 0.5) * 0.12
			var neck_n := creature_bob.get_node_or_null("Neck")
			if neck_n:
				neck_n.rotation.x = deg_to_rad(28) + sin(t * 0.5) * 0.08
		"pine_fox":
			creature_bob.position.y = abs(sin(t * 0.65)) * 0.03
			creature_bob.rotation.y = sin(t * 0.4) * 0.14
			var tail_n := creature_bob.get_node_or_null("Tail")
			if tail_n:
				tail_n.rotation.y = sin(t * 0.9) * 0.25
				tail_n.rotation.x = deg_to_rad(-35) + sin(t * 0.7) * 0.08
		"oak_hare":
			# Soft hop bob — ears twitch gently
			creature_bob.position.y = abs(sin(t * 0.85)) * 0.04
			creature_bob.rotation.y = sin(t * 0.45) * 0.1
			var el := creature_bob.get_node_or_null("EarL")
			var er := creature_bob.get_node_or_null("EarR")
			if el:
				el.rotation.z = deg_to_rad(-12) + sin(t * 1.1) * 0.08
			if er:
				er.rotation.z = deg_to_rad(12) - sin(t * 1.1) * 0.08
		"birch_squirrel":
			# Quick sit-bob — bushy tail flicks
			creature_bob.position.y = abs(sin(t * 0.95)) * 0.035
			creature_bob.rotation.y = sin(t * 0.55) * 0.12
			var sq_tail := creature_bob.get_node_or_null("Tail")
			if sq_tail:
				sq_tail.rotation.y = sin(t * 1.2) * 0.22
				sq_tail.rotation.x = deg_to_rad(-55) + sin(t * 0.8) * 0.1
		"aspen_otter":
			# Soft glide bob — paddle tail sways
			creature_bob.position.y = abs(sin(t * 0.7)) * 0.03
			creature_bob.rotation.y = sin(t * 0.4) * 0.1
			var ot_tail := creature_bob.get_node_or_null("Tail")
			if ot_tail:
				ot_tail.rotation.y = sin(t * 0.85) * 0.18
				ot_tail.rotation.x = deg_to_rad(-18) + sin(t * 0.6) * 0.06
		"elm_raccoon":
			# Soft trundle bob — ringed tail sways (Wave 35)
			creature_bob.position.y = abs(sin(t * 0.75)) * 0.03
			creature_bob.rotation.y = sin(t * 0.42) * 0.11
			var rc_tail := creature_bob.get_node_or_null("Tail")
			if rc_tail:
				rc_tail.rotation.y = sin(t * 0.9) * 0.2
				rc_tail.rotation.x = deg_to_rad(-28) + sin(t * 0.65) * 0.07
		"willow_wren":
			# Soft hover bob — quick wing flutters (Wave 37)
			creature_bob.position.y = 0.08 + sin(t * 1.1) * 0.06
			creature_bob.rotation.y = sin(t * 0.5) * 0.12
			wing_phase += delta * 16.0
			var wlw := creature_bob.get_node_or_null("LWing")
			var wrw := creature_bob.get_node_or_null("RWing")
			var wflap := sin(wing_phase) * 0.4
			if wlw:
				wlw.rotation.z = deg_to_rad(28) + wflap
			if wrw:
				wrw.rotation.z = deg_to_rad(-28) - wflap
		"maple_mouse":
			# Soft sniff-bob — big ears twitch, thin tail sways (Wave 38)
			creature_bob.position.y = abs(sin(t * 0.9)) * 0.03
			creature_bob.rotation.y = sin(t * 0.48) * 0.12
			var mel := creature_bob.get_node_or_null("EarL")
			var mer := creature_bob.get_node_or_null("EarR")
			if mel:
				mel.rotation.z = deg_to_rad(-8) + sin(t * 1.2) * 0.1
			if mer:
				mer.rotation.z = deg_to_rad(8) - sin(t * 1.2) * 0.1
			var mtail := creature_bob.get_node_or_null("Tail")
			if mtail:
				mtail.rotation.y = sin(t * 1.0) * 0.28
				mtail.rotation.x = deg_to_rad(-20) + sin(t * 0.7) * 0.08
		"spruce_mole":
			# Soft dig-bob — snout dips, stubby body wiggles (Wave 39)
			creature_bob.position.y = abs(sin(t * 0.7)) * 0.02
			creature_bob.rotation.y = sin(t * 0.35) * 0.08
			var sn := creature_bob.get_node_or_null("Snout")
			if sn:
				sn.rotation.x = deg_to_rad(90) + sin(t * 1.1) * 0.08
			var nose := creature_bob.get_node_or_null("Nose")
			if nose:
				nose.position.y = 0.28 + sin(t * 1.1) * 0.01
		"beech_chipmunk":
			# Soft forage-bob — cheeks puff, stripe body wiggles, short tail flicks (Wave 40)
			creature_bob.position.y = abs(sin(t * 1.0)) * 0.035
			creature_bob.rotation.y = sin(t * 0.55) * 0.14
			var cl := creature_bob.get_node_or_null("CheekL")
			var cr := creature_bob.get_node_or_null("CheekR")
			if cl:
				cl.scale = Vector3.ONE * (1.0 + sin(t * 1.4) * 0.06)
			if cr:
				cr.scale = Vector3.ONE * (1.0 + sin(t * 1.4 + 0.4) * 0.06)
			var ctail := creature_bob.get_node_or_null("Tail")
			if ctail:
				ctail.rotation.y = sin(t * 1.3) * 0.22
				ctail.rotation.x = deg_to_rad(-35) + sin(t * 0.9) * 0.1
		"alder_duck":
			# Soft paddle-waddle — bill dips, wings tuck, tail flicks (Wave 41)
			creature_bob.position.y = abs(sin(t * 0.85)) * 0.025
			creature_bob.rotation.y = sin(t * 0.4) * 0.1
			var bill := creature_bob.get_node_or_null("Bill")
			if bill:
				bill.rotation.x = deg_to_rad(8) + sin(t * 1.0) * 0.06
			var dlw := creature_bob.get_node_or_null("LWing")
			var drw := creature_bob.get_node_or_null("RWing")
			if dlw:
				dlw.rotation.z = deg_to_rad(18) + sin(t * 1.2) * 0.05
			if drw:
				drw.rotation.z = deg_to_rad(-18) - sin(t * 1.2) * 0.05
			var dtail := creature_bob.get_node_or_null("Tail")
			if dtail:
				dtail.rotation.y = sin(t * 0.9) * 0.12
				dtail.rotation.x = deg_to_rad(-25) + sin(t * 0.7) * 0.06
		"fir_frog":
			# Soft hop-settle — throat pouch puffs, eyes blink-bob, hind pads flex (Wave 42)
			creature_bob.position.y = abs(sin(t * 0.95)) * 0.04
			creature_bob.rotation.y = sin(t * 0.38) * 0.09
			var throat := creature_bob.get_node_or_null("Throat")
			if throat:
				throat.scale = Vector3.ONE * (1.0 + sin(t * 1.3) * 0.08)
			var el := creature_bob.get_node_or_null("EyeL")
			var er := creature_bob.get_node_or_null("EyeR")
			if el:
				el.position.y = 0.58 + sin(t * 1.5) * 0.008
			if er:
				er.position.y = 0.58 + sin(t * 1.5 + 0.3) * 0.008
			var bl := creature_bob.get_node_or_null("LegBL")
			var br := creature_bob.get_node_or_null("LegBR")
			if bl:
				bl.rotation.x = sin(t * 0.95) * 0.12
			if br:
				br.rotation.x = -sin(t * 0.95) * 0.12
		"cypress_turtle":
			# Soft shell-settle — head peeks, legs paddle slowly, shell bob (Wave 43)
			creature_bob.position.y = abs(sin(t * 0.55)) * 0.02
			creature_bob.rotation.y = sin(t * 0.28) * 0.06
			var head := creature_bob.get_node_or_null("Head")
			if head:
				head.position.z = 0.28 + sin(t * 0.7) * 0.02
			var shell := creature_bob.get_node_or_null("Shell")
			if shell:
				shell.scale = Vector3.ONE * (1.0 + sin(t * 0.9) * 0.015)
			var tleg := creature_bob.get_node_or_null("LegFL")
			if tleg:
				tleg.rotation.x = sin(t * 0.8) * 0.08
			var tleg2 := creature_bob.get_node_or_null("LegBR")
			if tleg2:
				tleg2.rotation.x = -sin(t * 0.8) * 0.08
			var ttail := creature_bob.get_node_or_null("Tail")
			if ttail:
				ttail.rotation.y = sin(t * 0.6) * 0.1
		"poplar_dove":
			# Soft perch-bob — gentle wing tuck flutter, fan tail tip (Wave 44)
			creature_bob.position.y = 0.06 + sin(t * 0.9) * 0.04
			creature_bob.rotation.y = sin(t * 0.42) * 0.1
			wing_phase += delta * 10.0
			var dlw := creature_bob.get_node_or_null("LWing")
			var drw := creature_bob.get_node_or_null("RWing")
			var dflap := sin(wing_phase) * 0.22
			if dlw:
				dlw.rotation.z = deg_to_rad(22) + dflap
			if drw:
				drw.rotation.z = deg_to_rad(-22) - dflap
			var dtail := creature_bob.get_node_or_null("Tail")
			if dtail:
				dtail.rotation.y = sin(t * 0.75) * 0.12
				dtail.rotation.x = deg_to_rad(-28) + sin(t * 0.6) * 0.05
			var fluff := creature_bob.get_node_or_null("Fluff")
			if fluff:
				fluff.scale = Vector3.ONE * (1.0 + sin(t * 1.1) * 0.04)
		"rowan_robin":
			# Soft hop-bob — quick wing flick, perky tail tip, breast puff (Wave 45)
			creature_bob.position.y = 0.04 + abs(sin(t * 1.35)) * 0.05
			creature_bob.rotation.y = sin(t * 0.55) * 0.12
			wing_phase += delta * 12.0
			var rlw := creature_bob.get_node_or_null("LWing")
			var rrw := creature_bob.get_node_or_null("RWing")
			var rflap := sin(wing_phase) * 0.28
			if rlw:
				rlw.rotation.z = deg_to_rad(18) + rflap
			if rrw:
				rrw.rotation.z = deg_to_rad(-18) - rflap
			var rtail := creature_bob.get_node_or_null("Tail")
			if rtail:
				rtail.rotation.y = sin(t * 1.1) * 0.14
				rtail.rotation.x = deg_to_rad(-42) + sin(t * 0.9) * 0.06
			var breast := creature_bob.get_node_or_null("Breast")
			if breast:
				breast.scale = Vector3.ONE * (1.0 + sin(t * 1.4) * 0.05)
		"ash_sparrow":
			# Soft ground-hop — gentle wing tuck, short tail tip, cream bib puff (Wave 46)
			creature_bob.position.y = 0.03 + abs(sin(t * 1.5)) * 0.04
			creature_bob.rotation.y = sin(t * 0.65) * 0.10
			wing_phase += delta * 10.5
			var slw := creature_bob.get_node_or_null("LWing")
			var srw := creature_bob.get_node_or_null("RWing")
			var sflap := sin(wing_phase) * 0.22
			if slw:
				slw.rotation.z = deg_to_rad(14) + sflap
			if srw:
				srw.rotation.z = deg_to_rad(-14) - sflap
			var stail := creature_bob.get_node_or_null("Tail")
			if stail:
				stail.rotation.y = sin(t * 0.95) * 0.10
				stail.rotation.x = deg_to_rad(-22) + sin(t * 0.8) * 0.04
			var bib := creature_bob.get_node_or_null("Bib")
			if bib:
				bib.scale = Vector3.ONE * (1.0 + sin(t * 1.25) * 0.045)
		"hickory_quail":
			# Soft ground-scurry — plump bob, crest tip, warm flank puff (Wave 47)
			creature_bob.position.y = 0.02 + abs(sin(t * 1.25)) * 0.035
			creature_bob.rotation.y = sin(t * 0.5) * 0.08
			wing_phase += delta * 9.0
			var qlw := creature_bob.get_node_or_null("LWing")
			var qrw := creature_bob.get_node_or_null("RWing")
			var qflap := sin(wing_phase) * 0.18
			if qlw:
				qlw.rotation.z = deg_to_rad(12) + qflap
			if qrw:
				qrw.rotation.z = deg_to_rad(-12) - qflap
			var qtail := creature_bob.get_node_or_null("Tail")
			if qtail:
				qtail.rotation.y = sin(t * 0.85) * 0.08
				qtail.rotation.x = deg_to_rad(-18) + sin(t * 0.7) * 0.035
			var crest := creature_bob.get_node_or_null("Crest")
			if crest:
				crest.rotation.x = deg_to_rad(-18) + sin(t * 1.1) * 0.06
			var flank := creature_bob.get_node_or_null("Flank")
			if flank:
				flank.scale = Vector3.ONE * (1.0 + sin(t * 1.15) * 0.04)
		"juniper_jay":
			# Soft perch-hop — tall crest tip, wing tuck, pale bib puff (Wave 48)
			creature_bob.position.y = 0.04 + abs(sin(t * 1.6)) * 0.045
			creature_bob.rotation.y = sin(t * 0.7) * 0.12
			wing_phase += delta * 11.0
			var jlw := creature_bob.get_node_or_null("LWing")
			var jrw := creature_bob.get_node_or_null("RWing")
			var jflap := sin(wing_phase) * 0.24
			if jlw:
				jlw.rotation.z = deg_to_rad(16) + jflap
			if jrw:
				jrw.rotation.z = deg_to_rad(-16) - jflap
			var jtail := creature_bob.get_node_or_null("Tail")
			if jtail:
				jtail.rotation.y = sin(t * 1.05) * 0.12
				jtail.rotation.x = deg_to_rad(-12) + sin(t * 0.85) * 0.05
			var jcrest := creature_bob.get_node_or_null("Crest")
			if jcrest:
				jcrest.rotation.x = deg_to_rad(-28) + sin(t * 1.3) * 0.08
			var jbib := creature_bob.get_node_or_null("Bib")
			if jbib:
				jbib.scale = Vector3.ONE * (1.0 + sin(t * 1.35) * 0.05)
		"sycamore_skink":
			# Soft ground-scurry — low bob, tapering tail sway, belly puff (Wave 49)
			creature_bob.position.y = 0.01 + abs(sin(t * 1.4)) * 0.02
			creature_bob.rotation.y = sin(t * 0.45) * 0.1
			var sktail := creature_bob.get_node_or_null("Tail")
			if sktail:
				sktail.rotation.y = sin(t * 1.2) * 0.18
				sktail.rotation.x = deg_to_rad(78) + sin(t * 0.9) * 0.06
			var belly := creature_bob.get_node_or_null("Belly")
			if belly:
				belly.scale = Vector3.ONE * (1.0 + sin(t * 1.1) * 0.04)
			var head_sk := creature_bob.get_node_or_null("Head")
			if head_sk:
				head_sk.rotation.y = sin(t * 0.85) * 0.08
		"chestnut_toad":
			# Soft squat settle — warty bob, belly puff, hind pad flex (Wave 50)
			creature_bob.position.y = 0.01 + abs(sin(t * 0.85)) * 0.03
			creature_bob.rotation.y = sin(t * 0.35) * 0.08
			var tbelly := creature_bob.get_node_or_null("Belly")
			if tbelly:
				tbelly.scale = Vector3.ONE * (1.0 + sin(t * 1.15) * 0.06)
			var twart := creature_bob.get_node_or_null("WartM")
			if twart:
				var wart_s := 1.0 + sin(t * 1.4) * 0.05
				twart.scale = Vector3.ONE * wart_s
			var tbl := creature_bob.get_node_or_null("LegBL")
			var tbr := creature_bob.get_node_or_null("LegBR")
			if tbl:
				tbl.rotation.x = sin(t * 0.85) * 0.1
			if tbr:
				tbr.rotation.x = sin(t * 0.85 + 0.4) * 0.1
			var thead := creature_bob.get_node_or_null("Head")
			if thead:
				thead.rotation.y = sin(t * 0.7) * 0.06
		"cherry_chinchilla":
			# Soft fluff-bob — big ears twitch, bushy tail sways (Wave 57)
			creature_bob.position.y = abs(sin(t * 0.85)) * 0.03
			creature_bob.rotation.y = sin(t * 0.42) * 0.1
			var cel := creature_bob.get_node_or_null("EarL")
			var cer := creature_bob.get_node_or_null("EarR")
			if cel:
				cel.rotation.z = deg_to_rad(-6) + sin(t * 1.15) * 0.09
			if cer:
				cer.rotation.z = deg_to_rad(6) - sin(t * 1.15) * 0.09
			var ctail := creature_bob.get_node_or_null("Tail")
			if ctail:
				ctail.rotation.y = sin(t * 0.95) * 0.2
				ctail.rotation.x = deg_to_rad(-22) + sin(t * 0.7) * 0.07
		"plum_porcupine":
			# Soft nestle-bob — quills breathe, stubby tail sways (Wave 58)
			creature_bob.position.y = abs(sin(t * 0.8)) * 0.028
			creature_bob.rotation.y = sin(t * 0.38) * 0.09
			var pq := creature_bob.get_node_or_null("Quills")
			if pq:
				pq.rotation.x = sin(t * 0.9) * 0.06
				pq.rotation.z = cos(t * 0.75) * 0.04
			var ptail := creature_bob.get_node_or_null("Tail")
			if ptail:
				ptail.rotation.y = sin(t * 0.85) * 0.15
		"grape_gecko":
			# Soft bask-bob — big eyes blink-scale, plump tail sway, sticky pads flex (Wave 61)
			creature_bob.position.y = 0.01 + abs(sin(t * 1.15)) * 0.022
			creature_bob.rotation.y = sin(t * 0.4) * 0.09
			var gel := creature_bob.get_node_or_null("EyeL")
			var ger := creature_bob.get_node_or_null("EyeR")
			if gel:
				gel.scale = Vector3.ONE * (1.0 + sin(t * 1.6) * 0.05)
			if ger:
				ger.scale = Vector3.ONE * (1.0 + sin(t * 1.6 + 0.3) * 0.05)
			var gtail := creature_bob.get_node_or_null("Tail")
			if gtail:
				gtail.rotation.y = sin(t * 1.05) * 0.16
				gtail.rotation.x = deg_to_rad(70) + sin(t * 0.8) * 0.05
			var ghead := creature_bob.get_node_or_null("Head")
			if ghead:
				ghead.rotation.y = sin(t * 0.75) * 0.07
		"apricot_armadillo":
			# Soft shell-bob — banded plates breathe, stubby tail sway, tiny ears twitch (Wave 62)
			creature_bob.position.y = 0.01 + abs(sin(t * 1.05)) * 0.02
			creature_bob.rotation.y = sin(t * 0.36) * 0.08
			var ash := creature_bob.get_node_or_null("Shell")
			if ash:
				ash.rotation.x = sin(t * 0.85) * 0.04
				ash.position.y = 0.38 + abs(sin(t * 1.2)) * 0.012
			var atail := creature_bob.get_node_or_null("Tail")
			if atail:
				atail.rotation.y = sin(t * 0.95) * 0.14
				atail.rotation.x = deg_to_rad(55) + sin(t * 0.7) * 0.04
			var aear_l := creature_bob.get_node_or_null("EarL")
			var aear_r := creature_bob.get_node_or_null("EarR")
			if aear_l:
				aear_l.rotation.z = sin(t * 1.4) * 0.08
			if aear_r:
				aear_r.rotation.z = -sin(t * 1.4 + 0.2) * 0.08
		"blueberry_bunny":
			# Soft hop-bob — long ears twitch, puff tail wiggle, gentle hop (Wave 63)
			creature_bob.position.y = 0.01 + abs(sin(t * 1.35)) * 0.035
			creature_bob.rotation.y = sin(t * 0.42) * 0.09
			var bear_l := creature_bob.get_node_or_null("EarL")
			var bear_r := creature_bob.get_node_or_null("EarR")
			if bear_l:
				bear_l.rotation.z = deg_to_rad(-12) + sin(t * 1.5) * 0.1
			if bear_r:
				bear_r.rotation.z = deg_to_rad(12) - sin(t * 1.5 + 0.25) * 0.1
			var btail := creature_bob.get_node_or_null("Tail")
			if btail:
				btail.position.y = 0.30 + abs(sin(t * 1.6)) * 0.015
			var bhead := creature_bob.get_node_or_null("Head")
			if bhead:
				bhead.rotation.y = sin(t * 0.8) * 0.06
		"cranberry_capybara":
			# Soft lounge-bob — barrel breathe, tiny ears twitch, blunt tail sway (Wave 64)
			creature_bob.position.y = 0.01 + abs(sin(t * 0.95)) * 0.022
			creature_bob.rotation.y = sin(t * 0.32) * 0.07
			var cear_l := creature_bob.get_node_or_null("EarL")
			var cear_r := creature_bob.get_node_or_null("EarR")
			if cear_l:
				cear_l.rotation.z = sin(t * 1.25) * 0.07
			if cear_r:
				cear_r.rotation.z = -sin(t * 1.25 + 0.2) * 0.07
			var ctail := creature_bob.get_node_or_null("Tail")
			if ctail:
				ctail.rotation.y = sin(t * 0.85) * 0.12
				ctail.rotation.x = deg_to_rad(40) + sin(t * 0.65) * 0.04
			var chead := creature_bob.get_node_or_null("Head")
			if chead:
				chead.rotation.y = sin(t * 0.7) * 0.05
		"raspberry_ram":
			# Soft graze-bob — woolly breathe, curled horns nod, fluff tuft sway (Wave 65)
			creature_bob.position.y = 0.01 + abs(sin(t * 0.9)) * 0.024
			creature_bob.rotation.y = sin(t * 0.3) * 0.08
			var rear_l := creature_bob.get_node_or_null("EarL")
			var rear_r := creature_bob.get_node_or_null("EarR")
			if rear_l:
				rear_l.rotation.z = sin(t * 1.15) * 0.06
			if rear_r:
				rear_r.rotation.z = -sin(t * 1.15 + 0.2) * 0.06
			var horn_l := creature_bob.get_node_or_null("HornL")
			var horn_r := creature_bob.get_node_or_null("HornR")
			if horn_l:
				horn_l.rotation.z = deg_to_rad(-35) + sin(t * 0.75) * 0.05
			if horn_r:
				horn_r.rotation.z = deg_to_rad(35) - sin(t * 0.75 + 0.15) * 0.05
			var rtail := creature_bob.get_node_or_null("Tail")
			if rtail:
				rtail.rotation.y = sin(t * 0.9) * 0.14
			var rhead := creature_bob.get_node_or_null("Head")
			if rhead:
				rhead.rotation.y = sin(t * 0.65) * 0.06
				rhead.rotation.x = sin(t * 0.55) * 0.04
		"strawberry_stoat":
			# Soft snuffle-bob — slender dart, ear twitch, dark tip tail sway (Wave 66)
			creature_bob.position.y = 0.01 + abs(sin(t * 1.15)) * 0.028
			creature_bob.rotation.y = sin(t * 0.38) * 0.09
			var sear_l := creature_bob.get_node_or_null("EarL")
			var sear_r := creature_bob.get_node_or_null("EarR")
			if sear_l:
				sear_l.rotation.z = sin(t * 1.4) * 0.08
			if sear_r:
				sear_r.rotation.z = -sin(t * 1.4 + 0.25) * 0.08
			var stail := creature_bob.get_node_or_null("Tail")
			if stail:
				stail.rotation.y = sin(t * 1.05) * 0.16
				stail.rotation.x = deg_to_rad(48) + sin(t * 0.7) * 0.05
			var tip := creature_bob.get_node_or_null("TailTip")
			if tip:
				tip.rotation.y = sin(t * 1.2) * 0.1
			var shead := creature_bob.get_node_or_null("Head")
			if shead:
				shead.rotation.y = sin(t * 0.8) * 0.07
				shead.rotation.x = sin(t * 0.6) * 0.05
		"dust_golem":
			creature_bob.position.y = sin(t * 0.6) * 0.03
			var la := creature_bob.get_node_or_null("LArm")
			var ra := creature_bob.get_node_or_null("RArm")
			if la:
				la.rotation.x = sin(t * 0.7) * 0.08
			if ra:
				ra.rotation.x = -sin(t * 0.7) * 0.08
		_:
			creature_bob.position.y = sin(t) * 0.06

func _update_flinch(delta: float) -> void:
	if _flinch_t <= 0.0:
		return
	_flinch_t -= delta
	if creature_bob:
		var kick := sin(_flinch_t * 40.0) * 0.08 * clampf(_flinch_t * 3.0, 0.0, 1.0)
		creature_bob.position.x = kick
		creature_bob.rotation.z = kick * 0.5
	if _flinch_t <= 0.0 and creature_bob:
		creature_bob.position.x = 0.0
		creature_bob.rotation.z = 0.0

func _combat_tick() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist > float(EnemyDB.base_combat.get("attack_range", 3.2)):
		return
	# Player swing telegraph
	if player.has_method("play_attack_swing"):
		player.play_attack_swing()
	var wstats: Dictionary = GameState.get_weapon_stats()
	if randf() < float(wstats.get("accuracy", 0.7)):
		var base: int = int(wstats.get("damage", 2)) + maxi(0, GameState.combat_level - 1)
		# Light RuneScape-feel variance (±1) + occasional bright hit (wholesome, no gore)
		var dmg: int = maxi(1, base + randi_range(-1, 1))
		var bright: bool = randf() < 0.15
		if bright:
			dmg = maxi(dmg + 1, int(ceil(float(base) * 1.35)))
		# Soft "strong / bright hit" when damage is high vs foe max HP or absolute threshold
		var strong: bool = bright or dmg >= 8 or dmg >= int(ceil(float(max_hp) * 0.4))
		_take_hit(dmg)
		HitsplatUtil.spawn(self, dmg, true, 2.15, strong)
		AudioBus.play_hit()
	else:
		HitsplatUtil.spawn(self, 0, true)
		AudioBus.play_miss()
	if not alive:
		return
	if randf() < float(def.get("accuracy", 0.7)):
		var base_in: int = int(def.get("damage", 1))
		# Light incoming variance (±1) — wholesome RuneScape-feel numbers
		var edmg: int = maxi(1, base_in + randi_range(-1, 1))
		# Soft player defense from combat level + cape/head gear
		if GameState.has_method("get_defense"):
			edmg = maxi(1, edmg - GameState.get_defense())
		# Occasional slightly firmer poke (~10%)
		if randf() < 0.10:
			edmg += 1
		var strong_in: bool = edmg >= 4 or edmg >= base_in + 1
		GameState.take_damage(edmg)
		HitsplatUtil.spawn(player, edmg, false, 2.15, strong_in)
		AudioBus.play_hit()
		if GameState.hp <= 0:
			GameState.set_combat_target(null)
			if player.has_method("soft_respawn"):
				player.soft_respawn()
	else:
		HitsplatUtil.spawn(player, 0, false)
		AudioBus.play_miss()

func _take_hit(dmg: int) -> void:
	hp = maxi(0, hp - dmg)
	_flinch_t = 0.28
	_update_hp_bar()
	if hp > 0:
		_begin_hit_flash()
	if hp <= 0:
		_defeat()

func _defeat() -> void:
	alive = false
	$CollisionShape3D.disabled = true
	GameState.set_combat_target(null)
	var cxp: int = int(def.get("combat_xp", 5))
	var prev_cl: int = GameState.combat_level
	GameState.combat_xp += cxp
	GameState.combat_level = GameState.combat_level_for_xp(GameState.combat_xp)
	GameState.check_combat_item_unlocks()
	# Wave 40: quiet soft XP float on foe (RuneScape-chunky, no cheesy combat labels)
	HitsplatUtil.spawn_xp(self, cxp, 2.35)
	GameState.toast.emit("%s %s (+%d combat XP)" % [def.get("name", "Foe"), def.get("defeat_verb", "cleared"), cxp])
	if GameState.combat_level > prev_cl:
		GameState.toast.emit("Combat level up! Now Combat Lv %d — well fought." % GameState.combat_level)
	GameState.save_game()
	GameState.state_changed.emit()
	_begin_kill_flash()
	_dissolve_t = 0.0
	respawn_timer = float(def.get("respawn_sec", 12))



func _begin_hit_flash() -> void:
	## Brief soft cream flash on a landed hit (Wave 21). Skips if kill flash running.
	if HeadlessGuard.is_headless():
		return
	if _kill_flash_t >= 0.0:
		return
	if _kill_flash_base.is_empty():
		_capture_mesh_colors(creature_bob)
	_hit_flash_t = 0.12
	_apply_kill_flash_color(Color(1.0, 0.92, 0.82, 1.0))


func _tick_hit_flash(delta: float) -> void:
	if _hit_flash_t < 0.0:
		return
	if _kill_flash_t >= 0.0:
		_hit_flash_t = -1.0
		return
	_hit_flash_t -= delta
	var u: float = clampf(1.0 - (_hit_flash_t / 0.12), 0.0, 1.0)
	var flash := Color(1.0, 0.92, 0.82, 1.0).lerp(Color(1, 1, 1, 1), u)
	# Restore toward base colors
	for mi in _kill_flash_base.keys():
		if not is_instance_valid(mi):
			continue
		if mi.material_override is StandardMaterial3D:
			var mat := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = flash.lerp(_kill_flash_base[mi], u)
			mi.material_override = mat
	if _hit_flash_t <= 0.0:
		_hit_flash_t = -1.0
		_restore_kill_flash_colors()


func _begin_kill_flash() -> void:
	## Brief soft gold wash before dissolve — wholesome clear, not gore.
	if HeadlessGuard.is_headless():
		return
	_kill_flash_t = 0.22
	_kill_flash_base.clear()
	_capture_mesh_colors(creature_bob)
	_apply_kill_flash_color(Color(1.0, 0.95, 0.65, 1.0))

func _capture_mesh_colors(n: Node) -> void:
	if n == null:
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			_kill_flash_base[mi] = (mi.material_override as StandardMaterial3D).albedo_color
	for c in n.get_children():
		_capture_mesh_colors(c)

func _apply_kill_flash_color(c: Color) -> void:
	for mi in _kill_flash_base.keys():
		if not is_instance_valid(mi):
			continue
		if mi.material_override is StandardMaterial3D:
			var mat := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = c
			mi.material_override = mat

func _tick_kill_flash(delta: float) -> void:
	if _kill_flash_t < 0.0:
		return
	_kill_flash_t -= delta
	var u: float = clampf(1.0 - (_kill_flash_t / 0.22), 0.0, 1.0)
	var flash := Color(1.0, 0.95, 0.65, 1.0).lerp(Color(1.0, 1.0, 1.0, 0.85), u)
	_apply_kill_flash_color(flash)
	if _kill_flash_t <= 0.0:
		_kill_flash_t = -1.0

func _respawn() -> void:
	alive = true
	visible = true
	$CollisionShape3D.disabled = false
	hp = max_hp
	global_position = spawn_pos
	mesh_root.scale = _base_scale
	modulate_meshes(1.0)
	_dissolve_t = -1.0
	# Restore original mesh colors after kill-flash wash (v1.14 bug fix)
	_restore_kill_flash_colors()
	_update_hp_bar()

func _restore_kill_flash_colors() -> void:
	for mi in _kill_flash_base.keys():
		if not is_instance_valid(mi):
			continue
		if mi.material_override is StandardMaterial3D:
			var mat := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = _kill_flash_base[mi]
			mi.material_override = mat
	_kill_flash_base.clear()
	_kill_flash_t = -1.0

func _update_hp_bar() -> void:
	var ratio := float(hp) / float(maxi(1, max_hp))
	hp_bar.scale.x = maxf(0.05, ratio)
	var mat := StandardMaterial3D.new()
	# Wave 29: soft 3-tier HP color — healthy green → amber → warm rose at low HP (wholesome, no harsh red)
	if ratio > 0.55:
		mat.albedo_color = Color(0.22, 0.86, 0.34)
	elif ratio > 0.28:
		mat.albedo_color = Color(0.92, 0.72, 0.22)
	else:
		mat.albedo_color = Color(0.88, 0.42, 0.38)
	hp_bar.material_override = mat
