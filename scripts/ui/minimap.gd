extends Control
## Draws village orientation map from data set by HUD.

var map_data: Dictionary = {}

func set_data(data: Dictionary) -> void:
	map_data = data
	queue_redraw()

func _draw() -> void:
	var sz: Vector2 = get_size()
	var center := sz * 0.5
	var radius: float = minf(sz.x, sz.y) * 0.48
	var indoors: bool = str(map_data.get("inside", "")) != ""
	var bg := Color(0.14, 0.14, 0.2, 0.78) if indoors else Color(0.12, 0.18, 0.14, 0.72)
	draw_circle(center, radius, bg)
	draw_arc(center, radius, 0, TAU, 48, Color(0.75, 0.85, 0.65, 0.9), 2.0, true)
	var world_r := 56.0
	var scale: float = (radius * 0.92) / world_r
	var px: float = float(map_data.get("player", {}).get("x", 0))
	var pz: float = float(map_data.get("player", {}).get("z", 0))
	for h in map_data.get("halls", []):
		var pos := center + Vector2((float(h["x"]) - px) * scale, (float(h["z"]) - pz) * scale)
		if pos.distance_to(center) > radius - 4.0:
			continue
		draw_circle(pos, 4.0, Color(h.get("color", "#c9a227")))
	for n in map_data.get("npcs", []):
		var pos := center + Vector2((float(n["x"]) - px) * scale, (float(n["z"]) - pz) * scale)
		if pos.distance_to(center) > radius - 3.0:
			continue
		draw_circle(pos, 2.5, Color(0.35, 0.55, 0.95, 0.95))
	for f in map_data.get("foes", []):
		var pos := center + Vector2((float(f["x"]) - px) * scale, (float(f["z"]) - pz) * scale)
		if pos.distance_to(center) > radius - 3.0:
			continue
		draw_circle(pos, 2.8, Color(0.9, 0.35, 0.25, 0.95))
	var yaw: float = float(map_data.get("player", {}).get("yaw", 0.0))
	var tip := Vector2(0, -7).rotated(-yaw)
	var left := Vector2(-5, 5).rotated(-yaw)
	var right := Vector2(5, 5).rotated(-yaw)
	draw_colored_polygon(PackedVector2Array([center + tip, center + left, center + right]), Color(1, 1, 1, 0.95))
	draw_line(center + Vector2(0, -radius + 2), center + Vector2(0, -radius + 10), Color(1, 0.9, 0.4), 2.0)
