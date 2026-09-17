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
	_idle_style = abs(npc_id.hash()) % 4
	_phase = float(abs(npc_id.hash() % 1000)) * 0.01
	# Slight facing toward plaza center
	var to_center := Vector3(0, 0, 8) - global_position
	mesh_root.rotation.y = atan2(to_center.x, to_center.z)

func _process(delta: float) -> void:
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
		_:  # Shift weight / nod
			var l_leg: Node3D = parts.get("l_leg")
			var r_leg: Node3D = parts.get("r_leg")
			if l_leg:
				l_leg.rotation.x = sin(t * 0.6) * 0.04
			if r_leg:
				r_leg.rotation.x = -sin(t * 0.6) * 0.04
			var head: MeshInstance3D = parts.get("head")
			if head:
				head.rotation.x = sin(t * 1.1) * 0.05

func request_talk() -> void:
	talk_requested.emit(self)
	GameState.ui_open_requested.emit("npc:" + npc_id)
	AudioBus.play_ui()

func _ensure_nav_obstacle() -> void:
	## Light avoidance bubble so NavigationAgent steers around mentors.
	if get_node_or_null("NavObstacle") != null:
		return
	var obs := NavigationObstacle3D.new()
	obs.name = "NavObstacle"
	obs.radius = 0.55
	obs.height = 1.8
	obs.avoidance_enabled = true
	add_child(obs)
