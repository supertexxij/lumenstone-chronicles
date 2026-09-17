extends Control
## Draws village orientation map from data set by HUD.
## Wave 25: chunky landmark icons (shapes by kind) — RuneScape-feel, wholesome.

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
		var col := Color(h.get("color", "#c9a227"))
		var icon := str(h.get("icon", "dot"))
		_draw_landmark_icon(pos, col, icon)
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

func _draw_landmark_icon(pos: Vector2, col: Color, icon: String) -> void:
	## Chunky distinct marks so wilds landmarks read at a glance (no combat labels).
	var outline := Color(0.08, 0.1, 0.12, 0.9)
	match icon:
		"fountain":
			draw_circle(pos, 5.0, outline)
			draw_circle(pos, 3.8, col)
			draw_circle(pos + Vector2(0, -1.2), 1.6, Color(0.75, 0.9, 1.0, 0.95))
		"tree":
			var pts := PackedVector2Array([
				pos + Vector2(0, -5.5),
				pos + Vector2(4.5, 3.5),
				pos + Vector2(-4.5, 3.5),
			])
			draw_colored_polygon(pts, outline)
			var pts2 := PackedVector2Array([
				pos + Vector2(0, -4.2),
				pos + Vector2(3.4, 2.6),
				pos + Vector2(-3.4, 2.6),
			])
			draw_colored_polygon(pts2, col)
		"cross":
			draw_rect(Rect2(pos + Vector2(-1.2, -5), Vector2(2.4, 10)), outline)
			draw_rect(Rect2(pos + Vector2(-4.5, -1.2), Vector2(9, 2.4)), outline)
			draw_rect(Rect2(pos + Vector2(-0.7, -4.2), Vector2(1.4, 8.4)), col)
			draw_rect(Rect2(pos + Vector2(-3.8, -0.7), Vector2(7.6, 1.4)), col)
		"arch":
			draw_arc(pos, 4.5, PI, TAU, 12, outline, 2.4, true)
			draw_arc(pos, 4.5, PI, TAU, 12, col, 1.6, true)
			draw_line(pos + Vector2(-4.5, 0), pos + Vector2(-4.5, 4), col, 2.0)
			draw_line(pos + Vector2(4.5, 0), pos + Vector2(4.5, 4), col, 2.0)
		"water":
			draw_circle(pos, 4.6, outline)
			draw_circle(pos, 3.5, col)
			draw_line(pos + Vector2(-2.2, 0.5), pos + Vector2(2.2, 0.5), Color(1, 1, 1, 0.55), 1.2)
			draw_line(pos + Vector2(-1.6, 1.8), pos + Vector2(1.6, 1.8), Color(1, 1, 1, 0.4), 1.0)
		"rock":
			var rpts := PackedVector2Array([
				pos + Vector2(0, -4.5),
				pos + Vector2(4.2, -1.2),
				pos + Vector2(3.2, 3.8),
				pos + Vector2(-3.5, 3.5),
				pos + Vector2(-4.2, -1.0),
			])
			draw_colored_polygon(rpts, outline)
			var rpts2 := PackedVector2Array([
				pos + Vector2(0, -3.4),
				pos + Vector2(3.1, -0.9),
				pos + Vector2(2.3, 2.8),
				pos + Vector2(-2.6, 2.5),
				pos + Vector2(-3.1, -0.7),
			])
			draw_colored_polygon(rpts2, col)
		"mill":
			draw_rect(Rect2(pos + Vector2(-3.5, -3.5), Vector2(7, 7)), outline)
			draw_rect(Rect2(pos + Vector2(-2.6, -2.6), Vector2(5.2, 5.2)), col)
			draw_circle(pos, 1.4, Color(0.95, 0.9, 0.7, 0.95))
		"knoll":
			# Soft diamond / amber hill
			var kpts := PackedVector2Array([
				pos + Vector2(0, -5.2),
				pos + Vector2(4.8, 0),
				pos + Vector2(0, 5.2),
				pos + Vector2(-4.8, 0),
			])
			draw_colored_polygon(kpts, outline)
			var kpts2 := PackedVector2Array([
				pos + Vector2(0, -3.8),
				pos + Vector2(3.5, 0),
				pos + Vector2(0, 3.8),
				pos + Vector2(-3.5, 0),
			])
			draw_colored_polygon(kpts2, col)
		"birch":
			# Pale vertical trunks mark
			draw_rect(Rect2(pos + Vector2(-3.5, -4.5), Vector2(2.0, 9.0)), outline)
			draw_rect(Rect2(pos + Vector2(1.5, -4.5), Vector2(2.0, 9.0)), outline)
			draw_rect(Rect2(pos + Vector2(-3.0, -4.0), Vector2(1.2, 8.0)), col)
			draw_rect(Rect2(pos + Vector2(2.0, -4.0), Vector2(1.2, 8.0)), col)
			draw_circle(pos + Vector2(-2.4, -4.8), 2.2, col)
			draw_circle(pos + Vector2(2.6, -4.8), 2.2, col)
		"fern":
			# Soft green frond / leaf mark (Wave 27)
			var fpts := PackedVector2Array([
				pos + Vector2(0, -5.0),
				pos + Vector2(4.2, -1.5),
				pos + Vector2(2.2, 1.0),
				pos + Vector2(0, 4.5),
				pos + Vector2(-2.2, 1.0),
				pos + Vector2(-4.2, -1.5),
			])
			draw_colored_polygon(fpts, outline)
			var fpts2 := PackedVector2Array([
				pos + Vector2(0, -3.6),
				pos + Vector2(3.0, -1.0),
				pos + Vector2(1.5, 0.6),
				pos + Vector2(0, 3.2),
				pos + Vector2(-1.5, 0.6),
				pos + Vector2(-3.0, -1.0),
			])
			draw_colored_polygon(fpts2, col)
		"heather":
			# Soft purple heath tuft mark (Wave 28)
			draw_circle(pos + Vector2(0, 1.2), 4.2, outline)
			draw_circle(pos + Vector2(0, 1.2), 3.2, col)
			draw_circle(pos + Vector2(-2.2, -1.5), 2.4, outline)
			draw_circle(pos + Vector2(-2.2, -1.5), 1.7, col)
			draw_circle(pos + Vector2(2.4, -1.2), 2.2, outline)
			draw_circle(pos + Vector2(2.4, -1.2), 1.5, col)
		"hall":
			draw_rect(Rect2(pos + Vector2(-3.2, -3.2), Vector2(6.4, 6.4)), outline)
			draw_rect(Rect2(pos + Vector2(-2.4, -2.4), Vector2(4.8, 4.8)), col)
		_:
			draw_circle(pos, 4.0, outline)
			draw_circle(pos, 3.0, col)
