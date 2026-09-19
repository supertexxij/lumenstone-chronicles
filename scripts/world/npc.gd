extends StaticBody3D
## Guild NPC — humanoid with distinct outfit colors / labels + idle variety

@export var npc_id: String = ""
@export var npc_name: String = "Guide"
@export var title: String = ""
@export var guild: String = "bible"
@export var quest_ids: PackedStringArray = []
@export var accent: Color = Color.GOLD

signal talk_requested(npc: Node)

@onready var mesh_root: Node3D = $MeshRoot
var label: Label3D

var parts: Dictionary = {}
var _idle_style: int = 0
var _phase: float = 0.0
var _wave_t: float = -1.0
var _talk_near: bool = false  # Wave 31: clearer Talk (F) prompt
var _process_tick: int = 0  # v1.86: stagger idle / talk prompt
var _cached_player: Node = null

func _ready() -> void:
	add_to_group("npcs")
	label = get_node_or_null("Label3D") as Label3D
	if HeadlessGuard.is_headless():
		if label:
			label.queue_free()
			label = null
	elif label:
		label.text = npc_name
	parts = HumanoidBuilder.build(mesh_root)
	_ensure_nav_obstacle()
	var skin_keys := ["fair", "light", "medium", "tan", "deep"]
	var skin_hex: String = str(GameState.SKIN_HEX[skin_keys[abs(npc_id.hash()) % skin_keys.size()]])
	HumanoidBuilder.apply_npc_colors(parts, accent, Color(skin_hex))
	_idle_style = abs(npc_id.hash()) % 6
	_phase = float(abs(npc_id.hash() % 1000)) * 0.01
	# Slight facing toward plaza center
	var to_center := Vector3(0, 0, 8) - global_position
	mesh_root.rotation.y = atan2(to_center.x, to_center.z)

func _process(delta: float) -> void:
	# v1.86: mentors idle on alternate frames — cuts village process cost
	_process_tick = (_process_tick + 1) % 2
	if _process_tick != 0:
		return
	var bob: Node3D = parts.get("bob")
	var l_arm: Node3D = parts.get("l_arm")
	var r_arm: Node3D = parts.get("r_arm")
	if bob == null:
		return
	var t := Time.get_ticks_msec() * 0.001 + _phase
	bob.position.y = sin(t * 2.0) * 0.02
	match _idle_style:
		0:  # Gentle sway
			bob.rotation.y = sin(t * 0.7) * 0.06
			if l_arm:
				l_arm.rotation.x = sin(t * 0.9) * 0.05
			if r_arm:
				r_arm.rotation.x = -sin(t * 0.9) * 0.05
		1:  # Occasional wave
			if _wave_t < 0.0 and randf() < delta * 0.08:
				_wave_t = 0.0
			if _wave_t >= 0.0:
				_wave_t += delta
				if r_arm:
					r_arm.rotation.x = -1.2 + sin(_wave_t * 10.0) * 0.25
					r_arm.rotation.z = deg_to_rad(20)
				if _wave_t > 1.4:
					_wave_t = -1.0
					if r_arm:
						r_arm.rotation.x = 0.0
						r_arm.rotation.z = deg_to_rad(6)
			else:
				if l_arm:
					l_arm.rotation.z = deg_to_rad(-8) + sin(t) * 0.03
		2:  # Look around
			bob.rotation.y = sin(t * 0.45) * 0.35
			if l_arm:
				l_arm.rotation.x = 0.1
			if r_arm:
				r_arm.rotation.x = 0.1
		3:  # Shift weight / nod
			var l_leg: Node3D = parts.get("l_leg")
			var r_leg: Node3D = parts.get("r_leg")
			if l_leg:
				l_leg.rotation.x = sin(t * 0.6) * 0.04
			if r_leg:
				r_leg.rotation.x = -sin(t * 0.6) * 0.04
			var head: MeshInstance3D = parts.get("head")
			if head:
				head.rotation.x = sin(t * 1.1) * 0.05
		4:  # Soft stretch (arms open, gentle lean) — hall-yard variety Wave 26
			if l_arm:
				l_arm.rotation.x = -0.35 + sin(t * 0.5) * 0.08
				l_arm.rotation.z = deg_to_rad(-18)
			if r_arm:
				r_arm.rotation.x = -0.35 + cos(t * 0.5) * 0.08
				r_arm.rotation.z = deg_to_rad(18)
			bob.rotation.z = sin(t * 0.4) * 0.03
		_:  # Soft toe-tap / idle hop
			var l_leg2: Node3D = parts.get("l_leg")
			var r_leg2: Node3D = parts.get("r_leg")
			if l_leg2:
				l_leg2.rotation.x = abs(sin(t * 2.2)) * 0.08
			if r_leg2:
				r_leg2.rotation.x = abs(sin(t * 2.2 + 1.2)) * 0.05
			bob.position.y = sin(t * 2.0) * 0.02 + abs(sin(t * 1.1)) * 0.01

	_update_talk_prompt()

func _update_talk_prompt() -> void:
	## Wave 31: when the player is nearby, show a clearer Talk (F) line (RuneScape-chunky, wholesome).
	if label == null or HeadlessGuard.is_headless():
		return
	if _cached_player == null or not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player")
	var player: Node = _cached_player
	var near := false
	if player != null and not bool(player.get("ui_blocking")):
		near = global_position.distance_to(player.global_position) <= 3.6
	_talk_near = near
	if near:
		label.text = "%s\nTalk (F)" % npc_name
		var pulse: float = 0.82 + 0.18 * abs(sin(Time.get_ticks_msec() * 0.0035))
		label.modulate = Color(1.0, 0.92, 0.55, pulse)
		label.outline_modulate = Color(0.25, 0.18, 0.05, 0.9)
	else:
		label.text = npc_name
		label.modulate = Color.WHITE
		label.outline_modulate = Color(0, 0, 0, 1)

func request_talk() -> void:
	talk_requested.emit(self)
	GameState.ui_open_requested.emit("npc:" + npc_id)
	AudioBus.play_ui()

func _ensure_nav_obstacle() -> void:
	## Soft bubble kept for future path awareness; RVO off while player avoidance is disabled.
	## v1.86: skip creating mentor NavObstacle nodes (avoidance_enabled stays false).
	if get_node_or_null("NavObstacle") != null:
		var existing := get_node_or_null("NavObstacle") as NavigationObstacle3D
		if existing:
			existing.avoidance_enabled = false
		return
	# Intentionally do not add NavigationObstacle3D — avoidance stays off.
