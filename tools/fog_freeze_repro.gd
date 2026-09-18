extends SceneTree
## Headless repro: clear vs Fog click-to-move / WASD mobility probe.
## Writes NDJSON to /opt/cursor/logs/debug.log and prints FOG_REPRO_* lines.

var _world: Node = null
var _frames: int = 0
var _phase: int = 0
var _player: Node = null
var _pos_a: Vector3 = Vector3.ZERO
var _wait: int = 0

func _agent(hid: String, msg: String, data: Dictionary = {}) -> void:
	var path := "/opt/cursor/logs/debug.log"
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify({"hypothesisId": hid, "location": "fog_freeze_repro.gd", "message": msg, "data": data, "timestamp": Time.get_ticks_msec()}))
	f.close()

func _initialize() -> void:
	print("FOG_REPRO_START")
	_agent("R", "repro_start", {})
	var world_ps = load("res://scenes/world/world.tscn")
	if world_ps == null:
		print("FOG_REPRO_FAIL world null")
		quit(1)
		return
	_world = world_ps.instantiate()
	root.add_child(_world)

func _process(_delta: float) -> bool:
	_frames += 1
	if _phase == 0:
		if _frames < 12:
			return false
		_player = _world.get("player")
		if _player == null:
			print("FOG_REPRO_FAIL no player")
			quit(1)
			return true
		# Ensure outdoors clear weather
		if _world.has_method("set_weather"):
			_world.set_weather(0, false)
		_player.set("ui_blocking", false)
		_pos_a = _player.global_position
		if _player.has_method("_set_move_target"):
			_player._set_move_target(_pos_a + Vector3(6, 0, 0))
		_agent("R", "clear_click_armed", {"pos": [_pos_a.x, _pos_a.z], "weather": str(_world.get_weather_label()) if _world.has_method("get_weather_label") else "?"})
		_wait = 0
		_phase = 1
		return false

	if _phase == 1:
		_wait += 1
		if _wait < 45:
			return false
		var pos_b: Vector3 = _player.global_position
		var moved_clear: float = Vector2(pos_b.x - _pos_a.x, pos_b.z - _pos_a.z).length()
		print("FOG_REPRO_CLEAR_MOVED", moved_clear)
		_agent("R", "clear_moved", {"dist": moved_clear, "pos": [pos_b.x, pos_b.z], "has_click": _player.get("has_click_target"), "vel": [_player.velocity.x, _player.velocity.z], "ui_blocking": _player.get("ui_blocking"), "time_scale": Engine.time_scale})
		# Switch to Fog
		if _world.has_method("set_weather"):
			_world.set_weather(1, true)
		# Force a weather process tick so snowdust/fog follow path runs
		if _world.has_method("_update_weather"):
			_world._update_weather(0.05)
		_pos_a = _player.global_position
		_player.set("ui_blocking", false)
		if _player.has_method("_set_move_target"):
			_player._set_move_target(_pos_a + Vector3(0, 0, 6))
		_agent("R", "fog_click_armed", {"pos": [_pos_a.x, _pos_a.z], "weather": str(_world.get_weather_label()) if _world.has_method("get_weather_label") else "?", "fog_mode": _world.get("_weather_mode")})
		_wait = 0
		_phase = 2
		return false

	if _phase == 2:
		_wait += 1
		if _wait < 45:
			return false
		var pos_c: Vector3 = _player.global_position
		var moved_fog: float = Vector2(pos_c.x - _pos_a.x, pos_c.z - _pos_a.z).length()
		print("FOG_REPRO_FOG_MOVED", moved_fog)
		_agent("R", "fog_moved", {"dist": moved_fog, "pos": [pos_c.x, pos_c.z], "has_click": _player.get("has_click_target"), "vel": [_player.velocity.x, _player.velocity.z], "ui_blocking": _player.get("ui_blocking"), "time_scale": Engine.time_scale, "des": [_player.get("_desired_vel").x if _player.get("_desired_vel") != null else 0, _player.get("_desired_vel").z if _player.get("_desired_vel") != null else 0]})
		# WASD probe under Fog
		_pos_a = _player.global_position
		Input.action_press("move_forward")
		_wait = 0
		_phase = 3
		return false

	if _phase == 3:
		_wait += 1
		if _wait < 40:
			return false
		Input.action_release("move_forward")
		var pos_d: Vector3 = _player.global_position
		var moved_wasd: float = Vector2(pos_d.x - _pos_a.x, pos_d.z - _pos_a.z).length()
		print("FOG_REPRO_FOG_WASD", moved_wasd)
		_agent("R", "fog_wasd", {"dist": moved_wasd, "pos": [pos_d.x, pos_d.z], "vel": [_player.velocity.x, _player.velocity.z], "ui_blocking": _player.get("ui_blocking"), "time_scale": Engine.time_scale})
		# Count active avoidance obstacles
		var obs_on := 0
		var obs_tot := 0
		for n in root.get_tree().get_nodes_in_group("enemies"):
			obs_tot += 1
			var o = n.get_node_or_null("NavObstacle")
			if o != null and bool(o.avoidance_enabled):
				obs_on += 1
		print("FOG_REPRO_OBS", obs_on, "/", obs_tot)
		_agent("B", "obstacle_count", {"avoid_on": obs_on, "enemies": obs_tot})
		print("FOG_REPRO_DONE")
		quit(0)
		return true
	return false
