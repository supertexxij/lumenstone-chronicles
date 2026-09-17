extends CharacterBody3D
## Soft RuneScape-style tick combat foe with limb-aware creature meshes

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

@onready var mesh_root: Node3D = $MeshRoot
@onready var label: Label3D = $Label3D
@onready var hp_bar: MeshInstance3D = $HpBar

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	def = EnemyDB.get_def(kind)
	max_hp = int(def.get("max_hp", 10))
	hp = max_hp
	label.text = def.get("name", kind)
	# Ensure HP bar has a mesh
	if hp_bar.mesh == null:
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.12, 0.12)
		hp_bar.mesh = box
	creature_bob = CreatureBuilder.build(kind, mesh_root)
	var primary := Color(def.get("color", "#888888"))
	var accent := Color(def.get("accent", "#aaaaaa"))
	CreatureBuilder.colorize(creature_bob, primary, accent)
	# Raise labels for taller creatures
	match kind:
		"dust_golem":
			label.position.y = 2.4
			hp_bar.position.y = 2.1
		"briar_boar":
			label.position.y = 1.6
			hp_bar.position.y = 1.35
		"shadow_moth":
			label.position.y = 1.9
			hp_bar.position.y = 1.6
		_:
			label.position.y = 1.8
			hp_bar.position.y = 1.5
	_update_hp_bar()

func _physics_process(delta: float) -> void:
	if not alive:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn()
		return
	_idle_anim(delta)
	if GameState.combat_target == self:
		tick_timer -= delta
		if tick_timer <= 0:
			tick_timer = float(EnemyDB.base_combat.get("tick_sec", 0.7))
			_combat_tick()

func _idle_anim(delta: float) -> void:
	if creature_bob == null:
		return
	var t := Time.get_ticks_msec() * 0.004 + spawn_pos.x
	match kind:
		"dim_wisp":
			creature_bob.position.y = sin(t) * 0.12
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

func _combat_tick() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist > float(EnemyDB.base_combat.get("attack_range", 3.2)):
		return
	var wstats: Dictionary = GameState.get_weapon_stats()
	if randf() < float(wstats.get("accuracy", 0.7)):
		var dmg: int = int(wstats.get("damage", 2))
		dmg += maxi(0, GameState.combat_level - 1)
		_take_hit(dmg)
		_spawn_hitsplat(dmg, true)
	else:
		_spawn_hitsplat(0, true)
	if not alive:
		return
	if randf() < float(def.get("accuracy", 0.7)):
		var edmg: int = int(def.get("damage", 1))
		GameState.take_damage(edmg)
		_spawn_hitsplat(edmg, false)
		if GameState.hp <= 0:
			GameState.set_combat_target(null)
			if player.has_method("soft_respawn"):
				player.soft_respawn()

func _take_hit(dmg: int) -> void:
	hp = maxi(0, hp - dmg)
	_update_hp_bar()
	if hp <= 0:
		_defeat()

func _defeat() -> void:
	alive = false
	visible = false
	$CollisionShape3D.disabled = true
	GameState.set_combat_target(null)
	var cxp: int = int(def.get("combat_xp", 5))
	GameState.combat_xp += cxp
	GameState.combat_level = GameState.combat_level_for_xp(GameState.combat_xp)
	GameState.toast.emit("%s %s (+%d combat XP)" % [def.get("name", "Foe"), def.get("defeat_verb", "cleared"), cxp])
	GameState.save_game()
	GameState.state_changed.emit()
	respawn_timer = float(def.get("respawn_sec", 12))

func _respawn() -> void:
	alive = true
	visible = true
	$CollisionShape3D.disabled = false
	hp = max_hp
	global_position = spawn_pos
	_update_hp_bar()

func _update_hp_bar() -> void:
	var ratio := float(hp) / float(maxi(1, max_hp))
	hp_bar.scale.x = maxf(0.05, ratio)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.85, 0.3) if ratio > 0.4 else Color(0.9, 0.2, 0.2)
	hp_bar.material_override = mat

func _spawn_hitsplat(dmg: int, on_self: bool) -> void:
	var splat := Label3D.new()
	splat.text = str(dmg) if dmg > 0 else "miss"
	splat.font_size = 48
	splat.modulate = Color(1, 0.85, 0.2) if on_self else Color(1, 0.3, 0.3)
	splat.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	splat.outline_size = 8
	splat.outline_modulate = Color(0, 0, 0)
	var parent_node: Node = self if on_self else get_tree().get_first_node_in_group("player")
	if parent_node:
		parent_node.add_child(splat)
		splat.position = Vector3(randf_range(-0.3, 0.3), 2.2, 0)
		var tw := create_tween()
		tw.tween_property(splat, "position:y", 3.2, 0.7)
		tw.parallel().tween_property(splat, "modulate:a", 0.0, 0.7)
		tw.tween_callback(splat.queue_free)
