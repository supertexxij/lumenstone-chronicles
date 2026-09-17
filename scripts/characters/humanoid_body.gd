extends Node3D
## Reusable humanoid visual — builds MeshInstance3D limbs on ready.
## Used as reference / can be instanced; player & NPC build via HumanoidBuilder directly.

@onready var mesh_root: Node3D = $MeshRoot

var parts: Dictionary = {}

func _ready() -> void:
	parts = HumanoidBuilder.build(mesh_root)
	HumanoidBuilder.apply_human_colors(
		parts,
		Color("#c68642"),
		Color("#5c4033"),
		Color("#f4e4bc"),
		Color("#c1121f")
	)

func get_parts() -> Dictionary:
	return parts
