extends StaticBody3D
## Guild NPC — humanoid with distinct outfit colors / labels

@export var npc_id: String = ""
@export var npc_name: String = "Guide"
@export var title: String = ""
@export var guild: String = "bible"
@export var quest_ids: PackedStringArray = []
@export var accent: Color = Color.GOLD

signal talk_requested(npc: Node)

@onready var mesh_root: Node3D = $MeshRoot
@onready var label: Label3D = $Label3D

var parts: Dictionary = {}

func _ready() -> void:
	add_to_group("npcs")
	label.text = npc_name
	parts = HumanoidBuilder.build(mesh_root)
	# Slight skin variation from accent hash so NPCs aren't identical
	var skin_keys := ["fair", "light", "medium", "tan", "deep"]
	var skin_hex: String = str(GameState.SKIN_HEX[skin_keys[abs(npc_id.hash()) % skin_keys.size()]])
	HumanoidBuilder.apply_npc_colors(parts, accent, Color(skin_hex))
	# Quiet idle bob
	var bob: Node3D = parts.get("bob")
	if bob:
		# Offset so NPCs don't sync
		bob.set_meta("phase", float(abs(npc_id.hash() % 1000)) * 0.01)

func _process(_delta: float) -> void:
	var bob: Node3D = parts.get("bob")
	if bob == null:
		return
	var phase: float = float(bob.get_meta("phase", 0.0))
	bob.position.y = sin(Time.get_ticks_msec() * 0.002 + phase) * 0.02

func request_talk() -> void:
	talk_requested.emit(self)
	GameState.ui_open_requested.emit("npc:" + npc_id)
